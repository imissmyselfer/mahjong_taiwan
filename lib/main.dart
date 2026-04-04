import 'dart:async';
import 'package:flutter/material.dart';
import 'mahjong_game.dart';

void main() {
  runApp(const MahjongApp());
}

class MahjongApp extends StatelessWidget {
  const MahjongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1B4D3E),
      ),
      home: const MahjongScreen(),
    );
  }
}

class MahjongScreen extends StatefulWidget {
  const MahjongScreen({super.key});

  @override
  State<MahjongScreen> createState() => _MahjongScreenState();
}

class _MahjongScreenState extends State<MahjongScreen> {
  late MahjongGame _game;
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _game = MahjongGame();
    // 啟動遊戲循環：每 1.5 秒執行一次電腦動作
    _gameTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _processGameLoop();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _processGameLoop() {
    if (_game.state == GameState.gameOver) return;

    setState(() {
      // 1. 如果有人打了牌，處理電腦的決策 (PASS / 胡)
      _game.autoProcessActions();

      // 2. 如果輪到電腦出牌，自動出一張
      if (_game.state == GameState.waitingForDiscard && _game.isBot(_game.currentTurn)) {
        _game.botAutoDiscard();
      }
    });
  }

  String _getTileName(int tileId) {
    if (tileId >= 11 && tileId <= 19) return '${tileId % 10}萬';
    if (tileId >= 21 && tileId <= 29) return '${tileId % 10}筒';
    if (tileId >= 31 && tileId <= 39) return '${tileId % 10}條';
    if (tileId == 41) return '東';
    if (tileId == 43) return '南';
    if (tileId == 45) return '西';
    if (tileId == 47) return '北';
    if (tileId == 51) return '中';
    if (tileId == 53) return '發';
    if (tileId == 55) return '白';
    return '花';
  }

  Color _getTileColor(int tileId) {
    if (tileId >= 11 && tileId <= 19) return Colors.red;
    if (tileId >= 21 && tileId <= 29) return Colors.blue;
    if (tileId >= 31 && tileId <= 39) return Colors.green;
    if (tileId >= 41 && tileId <= 47) return Colors.black87;
    if (tileId == 55) return Colors.blueAccent;
    if (tileId == 51) return Colors.red;
    if (tileId == 53) return Colors.green;
    return Colors.deepOrange;
  }

  @override
  Widget build(BuildContext context) {
    final myHand = _game.playerHands[PlayerPosition.east] ?? [];
    final currentTurn = _game.currentTurn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('台灣十六張麻將 (與電腦對戰)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _game = MahjongGame()),
          )
        ],
      ),
      body: Column(
        children: [
          _buildOtherPlayerHand(PlayerPosition.north, '北家'),
          Expanded(
            child: Row(
              children: [
                RotatedBox(quarterTurns: 1, child: _buildOtherPlayerHand(PlayerPosition.west, '西家')),
                Expanded(
                  child: _buildTableCenter(),
                ),
                RotatedBox(quarterTurns: 3, child: _buildOtherPlayerHand(PlayerPosition.south, '南家')),
              ],
            ),
          ),
          _buildMyHand(myHand),
        ],
      ),
    );
  }

  Widget _buildTableCenter() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_game.state == GameState.gameOver)
              Column(
                children: [
                  const Text('遊戲結束', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_game.winner != null ? '獲勝者: ${_game.winner}' : '流局', style: const TextStyle(fontSize: 18)),
                ],
              )
            else
              Column(
                children: [
                  Text('當前輪序: ${_game.currentTurn}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  if (_game.lastDiscardedTile != null)
                    Column(
                      children: [
                        const Text('打出牌:', style: TextStyle(color: Colors.white70)),
                        TileWidget(
                          name: _getTileName(_game.lastDiscardedTile!),
                          color: _getTileColor(_game.lastDiscardedTile!),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherPlayerHand(PlayerPosition pos, String name) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(name, style: const TextStyle(fontSize: 12, color: Colors.white30)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 1,
            children: List.generate(_game.playerHands[pos]?.length ?? 0, (index) => Container(
              width: 15, height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade400, Colors.white],
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMyHand(List<int> hand) {
    final bool canDiscard = _game.currentTurn == PlayerPosition.east && _game.state == GameState.waitingForDiscard;
    final bool canAct = _game.possibleActions.containsKey(PlayerPosition.east);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      color: Colors.black45,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const Text('你的手牌 (東家)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: hand.map((tileId) => GestureDetector(
                  onTap: () {
                    if (canDiscard) {
                      setState(() {
                        _game.discard(PlayerPosition.east, tileId);
                      });
                    }
                  },
                  child: TileWidget(
                    name: _getTileName(tileId),
                    color: _getTileColor(tileId),
                    isHighlighted: canDiscard,
                  ),
                )).toList(),
              ),
            ),
            if (canAct)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _game.possibleActions[PlayerPosition.east]!.map((action) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: action == 'WIN' ? Colors.red : Colors.blue),
                        onPressed: () {
                          setState(() {
                            _game.submitDecision(PlayerPosition.east, action);
                          });
                        },
                        child: Text(action),
                      ),
                    )
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TileWidget extends StatelessWidget {
  final String name;
  final Color color;
  final bool isHighlighted;

  const TileWidget({
    super.key,
    required this.name,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 40, height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isHighlighted ? Colors.yellowAccent : Colors.grey.shade400, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
