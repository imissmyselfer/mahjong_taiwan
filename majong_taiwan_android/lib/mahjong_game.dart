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

class MahjongGame {
  final List<int> deck = [];
  final Map<PlayerPosition, List<int>> playerHands = {};
  final Map<PlayerPosition, List<Melt>> playerMelts = {};
  final Map<PlayerPosition, List<int>> playerFlowers = {};
  final List<int> discards = [];
  
  PlayerPosition currentTurn = PlayerPosition.east;
  GameState state = GameState.waitingForDiscard;
  int? lastDiscardedTile;
  PlayerPosition? lastDiscarder;

  // UX Improvement: Track last drawn tile
  Map<PlayerPosition, int?> lastDrawnTiles = {};

  PlayerPosition? winner;
  bool isTsumo = false;
  List<TaiPattern> winningPatterns = [];
  int totalTai = 0;

  // Game Context
  int roundWind = 41; // Default to East round
  Map<PlayerPosition, int> seatWinds = {
    PlayerPosition.east: 41,
    PlayerPosition.south: 43,
    PlayerPosition.west: 45,
    PlayerPosition.north: 47,
  };
  int lianZhuangCount = 0;

  Map<PlayerPosition, List<String>> possibleActions = {};
  Map<PlayerPosition, MahjongAction> playerDecisions = {};
  Map<PlayerPosition, String?> lastActionLabels = {};
  int _labelTicks = 0;
  static const int _labelKeepTicks = 3; // 3 × 1500ms = 4.5 秒
  bool get isNewActionLabel => _labelTicks == _labelKeepTicks;

  MahjongGame() {
    _initializeDeck();
    _shuffleAndDeal();
  }

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
    print("Deck initialized: ${deck.length} tiles.");
  }

  void _shuffleAndDeal() {
    deck.shuffle(Random());
    for (var pos in PlayerPosition.values) {
      playerHands[pos] = [];
      playerMelts[pos] = [];
      playerFlowers[pos] = [];
      lastDrawnTiles[pos] = null;
      for (int i = 0; i < 16; i++) {
        playerHands[pos]!.add(deck.removeAt(0));
      }
      _processFlowers(pos);
    }
    _draw(currentTurn);
  }

  int? _processFlowers(PlayerPosition pos) {
    int? lastReplacement;
    bool hasFlowers = true;
    while (hasFlowers) {
      List<int> flowers = playerHands[pos]!.where((t) => t >= 61).toList();
      if (flowers.isEmpty) {
        hasFlowers = false;
      } else {
        for (var f in flowers) {
          playerHands[pos]!.remove(f);
          playerFlowers[pos]!.add(f);
          if (deck.isNotEmpty) {
            final replacement = deck.removeLast();
            playerHands[pos]!.add(replacement);
            lastReplacement = replacement;
          }
        }
      }
    }
    playerHands[pos]!.sort();
    return lastReplacement;
  }

  List<int> _getConcealedTiles(PlayerPosition pos) {
    return List.from(playerHands[pos]!);
  }

  List<int> _getAllTiles(PlayerPosition pos) {
    List<int> all = List.from(playerHands[pos]!);
    for (var melt in playerMelts[pos]!) {
      all.addAll(melt.tiles);
    }
    return all;
  }

  void discard(PlayerPosition pos, int tile) {
    if (state != GameState.waitingForDiscard || pos != currentTurn) return;

    print("Player $pos discards $tile");
    playerHands[pos]!.remove(tile);
    lastDrawnTiles[pos] = null; // Clear drawn tile on discard
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
      
      List<String> actions = [];
      final handWithTile = List<int>.from(playerHands[pos]!)..add(tile);
      if (WinLogic.decompose(handWithTile, playerMelts[pos]!, flowers: playerFlowers[pos]!) != null) actions.add('WIN');
      if (ActionValidator.canPong(playerHands[pos]!, tile)) actions.add('PONG');
      if (ActionValidator.canKong(playerHands[pos]!, tile)) actions.add('KONG');
      if (pos == _getNextPlayer(discarder)) {
        if (ActionValidator.getEatOptions(playerHands[pos]!, tile).isNotEmpty) {
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
      var options = ActionValidator.getEatOptions(playerHands[pos]!, lastDiscardedTile!);
      if (options.isNotEmpty) eatTiles = options.first;
    }

    print("Player $pos submits $actionType");
    playerDecisions[pos] = MahjongAction(pos, actionType, tiles: eatTiles);

    // WIN/TSUMO 是最高優先級，可以立即結算，不必等其他玩家決定
    if (actionType == 'WIN' || actionType == 'TSUMO') {
      _resolveActions();
      return;
    }

    if (playerDecisions.length >= possibleActions.length) {
      _resolveActions();
    }
  }

  List<int> _getSelfKongTiles(PlayerPosition pos) {
    final hand = playerHands[pos]!;
    final result = <int>[];

    // 暗槓：手上四張相同
    final counts = <int, int>{};
    for (var t in hand) counts[t] = (counts[t] ?? 0) + 1;
    for (var entry in counts.entries) {
      if (entry.value == 4) result.add(entry.key);
    }

    // 加槓：已碰的三張 + 手上有第四張
    for (var melt in playerMelts[pos]!) {
      if (melt.type == MeltType.triplet && melt.isExposed) {
        final tile = melt.tiles[0];
        if (hand.contains(tile) && !result.contains(tile)) result.add(tile);
      }
    }

    return result;
  }

  void _executeSelfKong(PlayerPosition pos, int tile) {
    final meltIndex = playerMelts[pos]!.indexWhere(
      (m) => m.type == MeltType.triplet && m.isExposed && m.tiles[0] == tile,
    );

    if (meltIndex >= 0) {
      // 加槓：把碰牌組升級為槓
      playerHands[pos]!.remove(tile);
      playerMelts[pos]![meltIndex] = Melt(tiles: [tile, tile, tile, tile], type: MeltType.kong, isExposed: true);
    } else {
      // 暗槓：從手牌移除四張
      for (int i = 0; i < 4; i++) playerHands[pos]!.remove(tile);
      playerMelts[pos]!.add(Melt(tiles: [tile, tile, tile, tile], type: MeltType.kong, isExposed: false));
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
      bool wasTsumoAttempt = false;
      possibleActions.forEach((p, a) { if (a.contains('TSUMO')) wasTsumoAttempt = true; });

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
    print("Executing ${action.type} for $pos");

    if (action.type == 'WIN' || action.type == 'TSUMO') {
      _setActionLabel(pos, action.type);
      _handleWin(pos, action.type == 'TSUMO');
    } else if (lastDiscardedTile != null) {
      final tile = lastDiscardedTile!;
      if (discards.isNotEmpty && discards.last == tile) {
        discards.removeLast();
      }

      if (action.type == 'PONG') {
        playerHands[pos]!.remove(tile);
        playerHands[pos]!.remove(tile);
        playerMelts[pos]!.add(Melt(tiles: [tile, tile, tile], type: MeltType.triplet, isExposed: true));
        _setActionLabel(pos, 'PONG');
        currentTurn = pos;
        _clearActionState();
        state = GameState.waitingForDiscard;
      } else if (action.type == 'KONG') {
        playerHands[pos]!.remove(tile);
        playerHands[pos]!.remove(tile);
        playerHands[pos]!.remove(tile);
        playerMelts[pos]!.add(Melt(tiles: [tile, tile, tile, tile], type: MeltType.kong, isExposed: true));
        _setActionLabel(pos, 'KONG');
        currentTurn = pos;
        _clearActionState();
        _draw(pos); // 槓後補牌（嶺上牌）
        return;
      } else if (action.type == 'EAT' && action.tiles != null) {
        for (var t in action.tiles!) playerHands[pos]!.remove(t);
        playerMelts[pos]!.add(Melt(tiles: [...action.tiles!, tile]..sort(), type: MeltType.sequence, isExposed: true));
        _setActionLabel(pos, 'EAT');
        currentTurn = pos;
        _clearActionState();
        state = GameState.waitingForDiscard;
      } else {
        _finishDiscardCycle();
        return;
      }
    } else {
      _finishDiscardCycle();
      return;
    }
  }

  void _handleWin(PlayerPosition pos, bool tsumo) {
    final winningTile = tsumo ? (lastDrawnTiles[pos] ?? playerHands[pos]!.last) : lastDiscardedTile!;
    final concealed = List<int>.from(playerHands[pos]!);
    if (!tsumo) concealed.add(winningTile);

    final result = WinLogic.decompose(concealed, playerMelts[pos]!, flowers: playerFlowers[pos]!);
    if (result != null) {
      final context = GameContext(
        roundWind: roundWind,
        seatWind: seatWinds[pos]!,
        isDealer: pos == PlayerPosition.east,
        lianZhuangCount: lianZhuangCount,
        isTsumo: tsumo,
        lastTile: winningTile,
        isSingleWait: _isSingleWait(pos, winningTile),
      );
      winningPatterns = TaiCalculator.calculate(result, context);
      totalTai = winningPatterns.fold(0, (sum, p) => sum + p.tai);

      _clearActionState();
      winner = pos;
      isTsumo = tsumo;
      state = GameState.gameOver;
    } else {
      print("WIN decompose failed for $pos — hand: $concealed, melts: ${playerMelts[pos]}");
    }
  }

  bool _isSingleWait(PlayerPosition pos, int tile) {
    return false; 
  }

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
    print("Turn -> $currentTurn");
  }

  void _draw(PlayerPosition pos) {
    if (deck.isEmpty) {
      state = GameState.gameOver;
      return;
    }
    int newTile = deck.removeAt(0);
    playerHands[pos]!.add(newTile);
    lastDrawnTiles[pos] = newTile;
    final replacement = _processFlowers(pos);
    if (replacement != null) lastDrawnTiles[pos] = replacement;
    
    if (WinLogic.decompose(playerHands[pos]!, playerMelts[pos]!, flowers: playerFlowers[pos]!) != null) {
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
    lastActionLabels[pos] = label;
    _labelTicks = _labelKeepTicks;
  }

  void autoProcessActions() {
    if (_labelTicks > 0) {
      _labelTicks--;
      if (_labelTicks == 0) lastActionLabels.clear();
      return;
    }
    if (state != GameState.waitingForActions) return;
    
    final playersToAct = possibleActions.keys.toList();
    for (var pos in playersToAct) {
      if (isBot(pos) && !playerDecisions.containsKey(pos)) {
        final actions = possibleActions[pos]!;
        String decision = 'PASS';
        if (actions.contains('WIN')) decision = 'WIN';
        else if (actions.contains('TSUMO')) decision = 'TSUMO';
        else if (actions.contains('PONG')) decision = 'PONG';
        else if (actions.contains('KONG')) decision = 'KONG';
        else if (actions.contains('EAT')) decision = 'EAT';
        submitDecision(pos, decision);
      }
    }
  }

  void botAutoDiscard() {
    if (state != GameState.waitingForDiscard || !isBot(currentTurn)) return;
    final hand = playerHands[currentTurn]!;
    if (hand.isNotEmpty) {
      discard(currentTurn, hand[Random().nextInt(hand.length)]);
    }
  }
}
