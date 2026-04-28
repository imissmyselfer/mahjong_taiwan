import 'dart:math';
import 'package:majong_taiwan_core/majong_taiwan_core.dart';

enum PlayerPosition { east, south, west, north }

enum GameState {
  waitingForDiscard,
  waitingForActions,
  gameOver
}

class MahjongAction {
  final PlayerPosition player;
  final String type; // 'WIN', 'TSUMO', 'PONG', 'KONG', 'EAT', 'PASS'
  final List<int>? tiles;

  MahjongAction(this.player, this.type, {this.tiles});

  int get priority {
    if (type == 'WIN' || type == 'TSUMO') return 3;
    if (type == 'PONG' || type == 'KONG') return 2;
    if (type == 'EAT') return 1;
    return 0;
  }
}

class PlayerState {
  final List<int> hand = [];
  final List<Melt> melts = [];
  final List<int> flowers = [];
  int? lastDrawn;
  final int seatWind;
  String? actionLabel;

  PlayerState({required this.seatWind});
}

class MahjongGame {
  final List<int> deck = [];
  final List<int> discards = [];

  final Map<PlayerPosition, PlayerState> players = {
    PlayerPosition.east:  PlayerState(seatWind: 41),
    PlayerPosition.south: PlayerState(seatWind: 43),
    PlayerPosition.west:  PlayerState(seatWind: 45),
    PlayerPosition.north: PlayerState(seatWind: 47),
  };

  PlayerPosition currentTurn = PlayerPosition.east;
  GameState state = GameState.waitingForDiscard;
  int? lastDiscardedTile;
  PlayerPosition? lastDiscarder;

  PlayerPosition? winner;
  bool isTsumo = false;
  List<TaiPattern> winningPatterns = [];
  int totalTai = 0;

  int roundWind = 41;
  int lianZhuangCount = 0;

  Map<PlayerPosition, List<String>> possibleActions = {};
  Map<PlayerPosition, MahjongAction> playerDecisions = {};

  int _labelTicks = 0;
  static const int _labelKeepTicks = 3; // 3 × 1500ms = 4.5 秒
  bool get isNewActionLabel => _labelTicks == _labelKeepTicks;

  // BOT 吃牌機率（PONG/KONG 一律接，EAT 偶爾放掉以保留手牌彈性）
  static const double _botEatRate = 0.6;
  final Random _rng = Random();

  MahjongGame() {
    _initializeDeck();
    _shuffleAndDeal();
  }

  PlayerState _p(PlayerPosition pos) => players[pos]!;

  void _initializeDeck() {
    for (var suit in [10, 20, 30]) {
      for (var i = 1; i <= 9; i++) {
        for (var j = 0; j < 4; j++) deck.add(suit + i);
      }
    }
    for (var wind in [41, 43, 45, 47]) {
      for (var j = 0; j < 4; j++) deck.add(wind);
    }
    for (var dragon in [51, 53, 55]) {
      for (var j = 0; j < 4; j++) deck.add(dragon);
    }
    for (var flower = 61; flower <= 68; flower++) {
      deck.add(flower);
    }
  }

  void _shuffleAndDeal() {
    deck.shuffle(Random());
    for (var pos in PlayerPosition.values) {
      final p = _p(pos);
      for (int i = 0; i < 16; i++) {
        p.hand.add(deck.removeAt(0));
      }
      _processFlowers(pos);
    }
    _draw(currentTurn);
  }

  int? _processFlowers(PlayerPosition pos) {
    final p = _p(pos);
    int? lastReplacement;
    while (true) {
      final flowers = p.hand.where((t) => t >= 61).toList();
      if (flowers.isEmpty) break;
      for (var f in flowers) {
        p.hand.remove(f);
        p.flowers.add(f);
        if (deck.isNotEmpty) {
          final replacement = deck.removeLast();
          p.hand.add(replacement);
          lastReplacement = replacement;
        }
      }
    }
    p.hand.sort();
    return lastReplacement;
  }

  void discard(PlayerPosition pos, int tile) {
    if (state != GameState.waitingForDiscard || pos != currentTurn) return;

    final p = _p(pos);
    p.hand.remove(tile);
    p.lastDrawn = null;
    lastDiscardedTile = tile;
    lastDiscarder = pos;
    discards.add(tile);

    _collectPossibleActions(tile, pos);

    if (possibleActions.isEmpty) {
      _finishDiscardCycle();
    } else {
      state = GameState.waitingForActions;
    }
  }

  void _collectPossibleActions(int tile, PlayerPosition discarder) {
    possibleActions.clear();
    playerDecisions.clear();

    for (var pos in PlayerPosition.values) {
      if (pos == discarder) continue;
      final p = _p(pos);

      final actions = <String>[];
      final handWithTile = List<int>.from(p.hand)..add(tile);
      if (WinLogic.decompose(handWithTile, p.melts, flowers: p.flowers) != null) actions.add('WIN');
      if (ActionValidator.canPong(p.hand, tile)) actions.add('PONG');
      if (ActionValidator.canKong(p.hand, tile)) actions.add('KONG');
      if (pos == _getNextPlayer(discarder)) {
        if (ActionValidator.getEatOptions(p.hand, tile).isNotEmpty) {
          actions.add('EAT');
        }
      }

      if (actions.isNotEmpty) {
        actions.add('PASS');
        possibleActions[pos] = actions;
      }
    }
  }

  void submitDecision(PlayerPosition pos, String actionType, {List<int>? eatTiles}) {
    if (state != GameState.waitingForActions) return;
    if (!possibleActions.containsKey(pos)) return;

    // 自摸槓情境（暗槓/加槓）：無棄牌時的槓/過
    if (lastDiscardedTile == null && (actionType == 'KONG' || actionType == 'PASS')) {
      possibleActions.clear();
      playerDecisions.clear();
      if (actionType == 'KONG') {
        final tiles = _getSelfKongTiles(pos);
        if (tiles.isNotEmpty) _executeSelfKong(pos, tiles.first);
      } else {
        state = GameState.waitingForDiscard;
      }
      return;
    }

    if (actionType == 'EAT' && eatTiles == null && lastDiscardedTile != null) {
      final options = ActionValidator.getEatOptions(_p(pos).hand, lastDiscardedTile!);
      if (options.isNotEmpty) eatTiles = options.first;
    }

    playerDecisions[pos] = MahjongAction(pos, actionType, tiles: eatTiles);

    // WIN/TSUMO 是最高優先級，可以立即結算
    if (actionType == 'WIN' || actionType == 'TSUMO') {
      _resolveActions();
      return;
    }

    if (playerDecisions.length >= possibleActions.length) {
      _resolveActions();
    }
  }

  List<int> _getSelfKongTiles(PlayerPosition pos) {
    final p = _p(pos);
    final result = <int>[];

    // 暗槓：手上四張相同
    final counts = <int, int>{};
    for (var t in p.hand) counts[t] = (counts[t] ?? 0) + 1;
    for (var entry in counts.entries) {
      if (entry.value == 4) result.add(entry.key);
    }

    // 加槓：已碰的三張 + 手上有第四張
    for (var melt in p.melts) {
      if (melt.type == MeltType.triplet && melt.isExposed) {
        final tile = melt.tiles[0];
        if (p.hand.contains(tile) && !result.contains(tile)) result.add(tile);
      }
    }

    return result;
  }

  void _executeSelfKong(PlayerPosition pos, int tile) {
    final p = _p(pos);
    final meltIndex = p.melts.indexWhere(
      (m) => m.type == MeltType.triplet && m.isExposed && m.tiles[0] == tile,
    );

    if (meltIndex >= 0) {
      // 加槓：碰升級為槓
      p.hand.remove(tile);
      p.melts[meltIndex] = Melt(tiles: [tile, tile, tile, tile], type: MeltType.kong, isExposed: true);
    } else {
      // 暗槓：從手牌移除四張
      for (int i = 0; i < 4; i++) p.hand.remove(tile);
      p.melts.add(Melt(tiles: [tile, tile, tile, tile], type: MeltType.kong, isExposed: false));
    }

    _setActionLabel(pos, 'KONG');
    currentTurn = pos;
    _draw(pos); // 補嶺上牌
  }

  void _resolveActions() {
    MahjongAction? bestAction;
    for (var decision in playerDecisions.values) {
      if (decision.type == 'PASS') continue;
      if (bestAction == null || decision.priority > bestAction.priority) {
        bestAction = decision;
      }
    }

    if (bestAction == null) {
      final wasTsumoAttempt = possibleActions.values.any((a) => a.contains('TSUMO'));
      if (wasTsumoAttempt) {
        state = GameState.waitingForDiscard;
        _clearActionState();
      } else {
        _finishDiscardCycle();
      }
    } else {
      _executeAction(bestAction);
    }
  }

  void _executeAction(MahjongAction action) {
    final pos = action.player;
    final p = _p(pos);

    if (action.type == 'WIN' || action.type == 'TSUMO') {
      _setActionLabel(pos, action.type);
      _handleWin(pos, action.type == 'TSUMO');
      return;
    }

    if (lastDiscardedTile == null) {
      _finishDiscardCycle();
      return;
    }

    final tile = lastDiscardedTile!;
    if (discards.isNotEmpty && discards.last == tile) {
      discards.removeLast();
    }

    switch (action.type) {
      case 'PONG':
        p.hand.remove(tile);
        p.hand.remove(tile);
        p.melts.add(Melt(tiles: [tile, tile, tile], type: MeltType.triplet, isExposed: true));
        _setActionLabel(pos, 'PONG');
        currentTurn = pos;
        _clearActionState();
        state = GameState.waitingForDiscard;
        break;
      case 'KONG':
        p.hand.remove(tile);
        p.hand.remove(tile);
        p.hand.remove(tile);
        p.melts.add(Melt(tiles: [tile, tile, tile, tile], type: MeltType.kong, isExposed: true));
        _setActionLabel(pos, 'KONG');
        currentTurn = pos;
        _clearActionState();
        _draw(pos); // 槓後補嶺上牌
        break;
      case 'EAT':
        if (action.tiles == null) {
          _finishDiscardCycle();
          return;
        }
        for (var t in action.tiles!) p.hand.remove(t);
        p.melts.add(Melt(tiles: [...action.tiles!, tile]..sort(), type: MeltType.sequence, isExposed: true));
        _setActionLabel(pos, 'EAT');
        currentTurn = pos;
        _clearActionState();
        state = GameState.waitingForDiscard;
        break;
      default:
        _finishDiscardCycle();
    }
  }

  void _handleWin(PlayerPosition pos, bool tsumo) {
    final p = _p(pos);
    final winningTile = tsumo ? (p.lastDrawn ?? p.hand.last) : lastDiscardedTile!;
    final concealed = List<int>.from(p.hand);
    if (!tsumo) concealed.add(winningTile);

    final result = WinLogic.decompose(concealed, p.melts, flowers: p.flowers);
    if (result == null) return;

    final context = GameContext(
      roundWind: roundWind,
      seatWind: p.seatWind,
      isDealer: pos == PlayerPosition.east,
      lianZhuangCount: lianZhuangCount,
      isTsumo: tsumo,
      lastTile: winningTile,
      isSingleWait: _isSingleWait(pos, winningTile),
    );
    winningPatterns = TaiCalculator.calculate(result, context);
    totalTai = winningPatterns.fold(0, (sum, x) => sum + x.tai);

    _clearActionState();
    winner = pos;
    isTsumo = tsumo;
    state = GameState.gameOver;
  }

  // TODO(方案 B): 實作真實聽牌類型判斷（單騎/邊張/嵌張/兩頭）
  bool _isSingleWait(PlayerPosition pos, int tile) => false;

  void _clearActionState() {
    lastDiscardedTile = null;
    possibleActions.clear();
    playerDecisions.clear();
  }

  void _finishDiscardCycle() {
    _clearActionState();
    _nextTurn();
    _draw(currentTurn);
  }

  PlayerPosition _getNextPlayer(PlayerPosition pos) {
    return PlayerPosition.values[(pos.index + 1) % 4];
  }

  void _nextTurn() {
    currentTurn = _getNextPlayer(currentTurn);
  }

  void _draw(PlayerPosition pos) {
    if (deck.isEmpty) {
      state = GameState.gameOver;
      return;
    }
    final p = _p(pos);
    final newTile = deck.removeAt(0);
    p.hand.add(newTile);
    p.lastDrawn = newTile;
    final replacement = _processFlowers(pos);
    if (replacement != null) p.lastDrawn = replacement;

    if (WinLogic.decompose(p.hand, p.melts, flowers: p.flowers) != null) {
      if (isBot(pos)) {
        _handleWin(pos, true);
      } else {
        possibleActions[pos] = ['TSUMO', 'PASS'];
        state = GameState.waitingForActions;
      }
      return;
    }

    // 暗槓 / 加槓
    final selfKongTiles = _getSelfKongTiles(pos);
    if (selfKongTiles.isNotEmpty) {
      if (isBot(pos)) {
        _executeSelfKong(pos, selfKongTiles.first);
      } else {
        possibleActions[pos] = ['KONG', 'PASS'];
        state = GameState.waitingForActions;
      }
      return;
    }

    state = GameState.waitingForDiscard;
  }

  bool isBot(PlayerPosition pos) => pos != PlayerPosition.east;

  void _setActionLabel(PlayerPosition pos, String label) {
    _p(pos).actionLabel = label;
    _labelTicks = _labelKeepTicks;
  }

  void _clearAllActionLabels() {
    for (var p in players.values) {
      p.actionLabel = null;
    }
  }

  void autoProcessActions() {
    if (_labelTicks > 0) {
      _labelTicks--;
      if (_labelTicks == 0) _clearAllActionLabels();
      return;
    }
    if (state != GameState.waitingForActions) return;

    final playersToAct = possibleActions.keys.toList();
    for (var pos in playersToAct) {
      if (state != GameState.waitingForActions) break;
      final actions = possibleActions[pos];
      if (actions == null) continue;
      if (isBot(pos) && !playerDecisions.containsKey(pos)) {
        submitDecision(pos, _decideBotAction(actions));
      }
    }
  }

  // 優先級：WIN/TSUMO/KONG/PONG 一定接，EAT 機率接
  String _decideBotAction(List<String> actions) {
    if (actions.contains('WIN')) return 'WIN';
    if (actions.contains('TSUMO')) return 'TSUMO';
    if (actions.contains('KONG')) return 'KONG';
    if (actions.contains('PONG')) return 'PONG';
    if (actions.contains('EAT') && _rng.nextDouble() < _botEatRate) return 'EAT';
    return 'PASS';
  }

  void botAutoDiscard() {
    if (state != GameState.waitingForDiscard || !isBot(currentTurn)) return;
    final hand = _p(currentTurn).hand;
    if (hand.isEmpty) return;
    discard(currentTurn, _pickDiscardTile(hand));
  }

  // 啟發式選牌：打分數最低（最孤立）的牌
  // - 對子或刻子 → 高分保留
  // - 字牌單張 → 低分優先丟（無法組順子）
  // - 數字單張 → 看左右鄰居數量加分
  int _pickDiscardTile(List<int> hand) {
    final counts = <int, int>{};
    for (var t in hand) counts[t] = (counts[t] ?? 0) + 1;

    int scoreOf(int t) {
      final c = counts[t]!;
      if (c >= 3) return 100;       // 刻子，絕對保留
      if (c == 2) return 50;        // 對子，盡量保留
      if (t >= 40) return 1;         // 字牌單張，最先丟
      // 數字牌單張：看前後 2 格鄰居
      int s = 5;
      if ((counts[t - 2] ?? 0) > 0) s += 2;
      if ((counts[t - 1] ?? 0) > 0) s += 4;
      if ((counts[t + 1] ?? 0) > 0) s += 4;
      if ((counts[t + 2] ?? 0) > 0) s += 2;
      return s;
    }

    int? bestTile;
    int bestScore = 1 << 30;
    for (final t in hand) {
      final s = scoreOf(t);
      if (s < bestScore) {
        bestScore = s;
        bestTile = t;
      }
    }
    return bestTile ?? hand.first;
  }
}
