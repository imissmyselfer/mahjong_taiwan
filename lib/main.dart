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
        scaffoldBackgroundColor: const Color(0xFF1B4D3E), // 麻將桌經典深綠色
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

  @override
  void initState() {
    super.initState();
    _game = MahjongGame();
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
    if (tileId >= 11 && tileId <= 19) return Colors.red; // 萬子
    if (tileId >= 21 && tileId <= 29) return Colors.blue; // 筒子
    if (tileId >= 31 && tileId <= 39) return Colors.green; // 條子
    
    // 風牌與白板使用深藍或黑色
    if (tileId >= 41 && tileId <= 47) return Colors.black87;
    if (tileId == 55) return Colors.blueAccent; 
    
    // 中、發、花牌
    if (tileId == 51) return Colors.red; // 中
    if (tileId == 53) return Colors.green; // 發
    if (tileId >= 61) return Colors.deepOrange; // 花牌
    
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final myHand = _game.playerHands[PlayerPosition.east] ?? [];
    final currentTurn = _game.currentTurn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('台灣十六張麻將'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _game = MahjongGame()),
          )
        ],
      ),
      body: Column(
        children: [
          // 頂部 (北家 - 對家)
          _buildOtherPlayerHand(PlayerPosition.north),
          
          Expanded(
            child: Row(
              children: [
                // 左側 (西家)
                RotatedBox(quarterTurns: 1, child: _buildOtherPlayerHand(PlayerPosition.west)),
                
                // 中間 (棄牌區)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('當前輪序: $currentTurn', style: const TextStyle(fontSize: 18)),
                          if (_game.lastDiscardedTile != null)
                            Column(
                              children: [
                                const SizedBox(height: 10),
                                const Text('打出牌:', style: TextStyle(color: Colors.white70)),
                                TileWidget(
                                  name: _getTileName(_game.lastDiscardedTile!),
                                  color: _getTileColor(_game.lastDiscardedTile!),
                                  isSmall: false,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 右側 (南家)
                RotatedBox(quarterTurns: 3, child: _buildOtherPlayerHand(PlayerPosition.south)),
              ],
            ),
          ),
          
          // 底部 (玩家 - 東家)
          _buildMyHand(myHand),
        ],
      ),
    );
  }

  Widget _buildOtherPlayerHand(PlayerPosition pos) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 2,
        children: List.generate(16, (index) => Container(
          width: 20, height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade300, Colors.white],
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildMyHand(List<int> hand) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      color: Colors.black26,
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
                  if (_game.currentTurn == PlayerPosition.east && 
                      _game.state == GameState.waitingForDiscard) {
                    setState(() {
                      _game.discard(PlayerPosition.east, tileId);
                    });
                  }
                },
                child: TileWidget(
                  name: _getTileName(tileId),
                  color: _getTileColor(tileId),
                ),
              )).toList(),
            ),
          ),
          
          // 動作按鈕 (僅當有動作可做時顯示)
          if (_game.possibleActions.containsKey(PlayerPosition.east))
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _game.possibleActions[PlayerPosition.east]!.map((action) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
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
    );
  }
}

class TileWidget extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSmall;

  const TileWidget({
    super.key,
    required this.name,
    required this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: isSmall ? 30 : 40,
      height: isSmall ? 45 : 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade400, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 14 : 18,
          ),
        ),
      ),
    );
  }
}
