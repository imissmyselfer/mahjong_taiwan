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
  final List<int>? tiles;

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
  final Map<PlayerPosition, List<int>> playerFlowers = {}; // 存放亮出的花牌
  final List<int> discards = [];
  
  PlayerPosition currentTurn = PlayerPosition.east;
  GameState state = GameState.waitingForDiscard;
  int? lastDiscardedTile;
  PlayerPosition? lastDiscarder;

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
      playerHands[pos] = [];
      playerFlowers[pos] = [];
      
      // 先發 16 張
      for (int i = 0; i < 16; i++) {
        playerHands[pos]!.add(deck.removeAt(0));
      }
      
      // **重要：處理起手補花**
      _processFlowers(pos);
    }
    
    // 莊家摸第 17 張並處理補花
    _draw(currentTurn);
  }

  /// 處理補花邏輯：將手牌中的花牌移至亮牌區，並從牌堆末尾補牌
  void _processFlowers(PlayerPosition pos) {
    bool hasFlowers = true;
    while (hasFlowers) {
      // 找出所有花牌 (ID >= 61)
      List<int> flowers = playerHands[pos]!.where((t) => t >= 61).toList();
      if (flowers.isEmpty) {
        hasFlowers = false;
      } else {
        for (var f in flowers) {
          playerHands[pos]!.remove(f);
          playerFlowers[pos]!.add(f);
          
          // 台灣麻將規則：從牌堆末尾補牌
          if (deck.isNotEmpty) {
            playerHands[pos]!.add(deck.removeLast());
          }
        }
      }
    }
    playerHands[pos]!.sort();
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

  void _collectPossibleActions(int tile, PlayerPosition discarder) {
    possibleActions.clear();
    playerDecisions.clear();

    for (var pos in PlayerPosition.values) {
      if (pos == discarder) continue;
      
      List<String> actions = [];
      List<int> handWithTile = List.from(playerHands[pos]!)..add(tile);
      if (WinLogic.isWinning(handWithTile)) actions.add('WIN');

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

    playerDecisions[pos] = MahjongAction(pos, actionType, tiles: eatTiles);

    if (playerDecisions.length == possibleActions.length) {
      _resolveActions();
    }
  }

  void _resolveActions() {
    MahjongAction? bestAction;
    for (var decision in playerDecisions.values) {
      if (bestAction == null || decision.priority > bestAction.priority) {
        bestAction = decision;
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
      
      // **重要：摸牌後也需要處理補花**
      _processFlowers(pos);
      
      state = GameState.waitingForDiscard;
    } else {
      state = GameState.gameOver;
    }
  }
}
