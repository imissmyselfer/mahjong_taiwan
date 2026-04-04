import 'dart:math';
import 'package:majong_taiwan_core/src/win_logic.dart';
import 'package:majong_taiwan_core/src/action_validator.dart';

enum PlayerPosition { east, south, west, north }

enum GameState {
  waitingForDiscard,
  waitingForActions,
  gameOver
}

class MahjongAction {
  final PlayerPosition player;
  final String type; // 'WIN', 'PONG', 'KONG', 'EAT', 'PASS'
  final List<int>? tiles; // 用於吃的組合

  MahjongAction(this.player, this.type, {this.tiles});

  int get priority {
    if (type == 'WIN') return 3;
    if (type == 'PONG' || type == 'KONG') return 2;
    if (type == 'EAT') return 1;
    return 0;
  }
}

class MahjongGame {
  final List<int> deck = [];
  final Map<PlayerPosition, List<int>> playerHands = {};
  final List<int> discards = [];
  
  PlayerPosition currentTurn = PlayerPosition.east;
  GameState state = GameState.waitingForDiscard;
  int? lastDiscardedTile;
  PlayerPosition? lastDiscarder;

  // Phase 2 核心：紀錄目前等待中的動作
  Map<PlayerPosition, List<String>> possibleActions = {};
  Map<PlayerPosition, MahjongAction> playerDecisions = {};

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
  }

  void _shuffleAndDeal() {
    deck.shuffle(Random());
    for (var pos in PlayerPosition.values) {
      playerHands[pos] = deck.sublist(0, 16);
      deck.removeRange(0, 16);
      playerHands[pos]!.sort();
    }
    _draw(currentTurn);
  }

  void discard(PlayerPosition pos, int tile) {
    if (state != GameState.waitingForDiscard || pos != currentTurn) return;

    playerHands[pos]!.remove(tile);
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

  /// 掃描所有玩家，找出誰可以對這張牌做什麼
  void _collectPossibleActions(int tile, PlayerPosition discarder) {
    possibleActions.clear();
    playerDecisions.clear();

    for (var pos in PlayerPosition.values) {
      if (pos == discarder) continue;
      
      List<String> actions = [];
      
      // 1. 胡牌檢查
      List<int> handWithTile = List.from(playerHands[pos]!)..add(tile);
      if (WinLogic.isWinning(handWithTile)) actions.add('WIN');

      // 2. 碰/槓檢查
      if (ActionValidator.canPong(playerHands[pos]!, tile)) actions.add('PONG');
      if (ActionValidator.canKong(playerHands[pos]!, tile)) actions.add('KONG');

      // 3. 吃牌檢查 (僅限下家)
      if (pos == _getNextPlayer(discarder)) {
        if (ActionValidator.getEatOptions(playerHands[pos]!, tile).isNotEmpty) {
          actions.add('EAT');
        }
      }

      if (actions.isNotEmpty) {
        actions.add('PASS'); // 總是可以選擇不動作
        possibleActions[pos] = actions;
      }
    }
  }

  /// 玩家提交他們的決定
  void submitDecision(PlayerPosition pos, String actionType, {List<int>? eatTiles}) {
    if (state != GameState.waitingForActions) return;
    if (!possibleActions.containsKey(pos)) return;

    playerDecisions[pos] = MahjongAction(pos, actionType, tiles: eatTiles);

    // 如果所有有權利動作的玩家都決定好了，就結算
    if (playerDecisions.length == possibleActions.length) {
      _resolveActions();
    }
  }

  void _resolveActions() {
    // 找出優先權最高的動作
    MahjongAction? bestAction;
    
    for (var decision in playerDecisions.values) {
      if (bestAction == null || decision.priority > bestAction.priority) {
        bestAction = decision;
      } else if (decision.priority == bestAction.priority && decision.priority == 3) {
        // 如果兩個人都要胡牌，根據台灣規則通常是「攔胡」（順位優先）
        // 這裡可以根據 discarder 的順序來決定誰贏
      }
    }

    if (bestAction == null || bestAction.type == 'PASS') {
      _finishDiscardCycle();
    } else {
      _executeAction(bestAction);
    }
  }

  void _executeAction(MahjongAction action) {
    final tile = lastDiscardedTile!;
    final pos = action.player;

    if (action.type == 'WIN') {
      playerHands[pos]!.add(tile);
      state = GameState.gameOver;
    } else if (action.type == 'PONG') {
      playerHands[pos]!.remove(tile);
      playerHands[pos]!.remove(tile);
      currentTurn = pos;
      state = GameState.waitingForDiscard;
    } else if (action.type == 'EAT') {
      for (var t in action.tiles!) playerHands[pos]!.remove(t);
      currentTurn = pos;
      state = GameState.waitingForDiscard;
    }
    
    lastDiscardedTile = null;
    possibleActions.clear();
    playerDecisions.clear();
  }

  void _finishDiscardCycle() {
    _nextTurn();
    _draw(currentTurn);
    state = GameState.waitingForDiscard;
  }

  PlayerPosition _getNextPlayer(PlayerPosition pos) {
    return PlayerPosition.values[(pos.index + 1) % 4];
  }

  void _nextTurn() {
    currentTurn = _getNextPlayer(currentTurn);
  }

  void _draw(PlayerPosition pos) {
    if (deck.isNotEmpty) {
      int newTile = deck.removeAt(0);
      playerHands[pos]!.add(newTile);
      playerHands[pos]!.sort();
      state = GameState.waitingForDiscard;
    } else {
      state = GameState.gameOver;
    }
  }
}
