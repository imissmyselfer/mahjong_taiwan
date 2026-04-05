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
  final Map<PlayerPosition, List<List<int>>> playerMelts = {};
  final Map<PlayerPosition, List<int>> playerFlowers = {};
  final List<int> discards = [];
  
  PlayerPosition currentTurn = PlayerPosition.east;
  GameState state = GameState.waitingForDiscard;
  int? lastDiscardedTile;
  PlayerPosition? lastDiscarder;

  PlayerPosition? winner;
  bool isTsumo = false;

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
    print("Deck initialized: ${deck.length} tiles.");
  }

  void _shuffleAndDeal() {
    deck.shuffle(Random());
    for (var pos in PlayerPosition.values) {
      playerHands[pos] = [];
      playerMelts[pos] = [];
      playerFlowers[pos] = [];
      for (int i = 0; i < 16; i++) {
        playerHands[pos]!.add(deck.removeAt(0));
      }
      _processFlowers(pos);
    }
    _draw(currentTurn);
  }

  void _processFlowers(PlayerPosition pos) {
    bool hasFlowers = true;
    while (hasFlowers) {
      List<int> flowers = playerHands[pos]!.where((t) => t >= 61).toList();
      if (flowers.isEmpty) {
        hasFlowers = false;
      } else {
        for (var f in flowers) {
          playerHands[pos]!.remove(f);
          playerFlowers[pos]!.add(f);
          if (deck.isNotEmpty) playerHands[pos]!.add(deck.removeLast());
        }
      }
    }
    playerHands[pos]!.sort();
  }

  List<int> _getAllTiles(PlayerPosition pos) {
    List<int> all = List.from(playerHands[pos]!);
    for (var melt in playerMelts[pos]!) {
      all.addAll(melt);
    }
    return all;
  }

  void discard(PlayerPosition pos, int tile) {
    if (state != GameState.waitingForDiscard || pos != currentTurn) return;

    print("Player $pos discards $tile");
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
      List<int> allTiles = _getAllTiles(pos)..add(tile);
      if (WinLogic.isWinning(allTiles)) actions.add('WIN');
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

    // **修正關鍵：如果點擊吃牌但沒給組合，自動抓第一個**
    if (actionType == 'EAT' && eatTiles == null && lastDiscardedTile != null) {
      var options = ActionValidator.getEatOptions(playerHands[pos]!, lastDiscardedTile!);
      if (options.isNotEmpty) eatTiles = options.first;
    }

    print("Player $pos submits $actionType");
    playerDecisions[pos] = MahjongAction(pos, actionType, tiles: eatTiles);

    if (playerDecisions.length >= possibleActions.length) {
      _resolveActions();
    }
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
        print("Tsumo passed. Waiting for discard.");
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
      if (action.type == 'WIN' && lastDiscardedTile != null) {
        playerHands[pos]!.add(lastDiscardedTile!);
      }
      winner = pos;
      isTsumo = (action.type == 'TSUMO');
      state = GameState.gameOver;
    } else if (lastDiscardedTile != null) {
      final tile = lastDiscardedTile!;
      // 牌被拿走了，從棄牌區移除
      if (discards.isNotEmpty && discards.last == tile) {
        discards.removeLast();
      }

      if (action.type == 'PONG') {
        playerHands[pos]!.remove(tile);
        playerHands[pos]!.remove(tile);
        playerMelts[pos]!.add([tile, tile, tile]);
        currentTurn = pos;
        state = GameState.waitingForDiscard;
      } else if (action.type == 'EAT' && action.tiles != null) {
        for (var t in action.tiles!) playerHands[pos]!.remove(t);
        playerMelts[pos]!.add([...action.tiles!, tile]..sort());
        currentTurn = pos;
        state = GameState.waitingForDiscard;
      } else {
        // 防呆：如果動作沒執行，也得進下一個循環
        _finishDiscardCycle();
        return;
      }
    } else {
      _finishDiscardCycle();
      return;
    }
    
    _clearActionState();
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
    _processFlowers(pos);
    
    if (WinLogic.isWinning(_getAllTiles(pos))) {
      if (isBot(pos)) {
        winner = pos;
        isTsumo = true;
        state = GameState.gameOver;
      } else {
        possibleActions[pos] = ['TSUMO', 'PASS'];
        state = GameState.waitingForActions;
      }
    } else {
      state = GameState.waitingForDiscard;
    }
  }

  bool isBot(PlayerPosition pos) => pos != PlayerPosition.east;

  void autoProcessActions() {
    if (state != GameState.waitingForActions) return;
    
    final playersToAct = possibleActions.keys.toList();
    for (var pos in playersToAct) {
      if (isBot(pos) && !playerDecisions.containsKey(pos)) {
        final actions = possibleActions[pos]!;
        String decision = 'PASS';
        if (actions.contains('WIN')) decision = 'WIN';
        else if (actions.contains('TSUMO')) decision = 'TSUMO';
        else if (actions.contains('PONG')) decision = 'PONG'; // 讓電腦也會碰牌
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
