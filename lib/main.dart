import 'dart:async';
import 'package:flutter/material.dart';
import 'package:majong_taiwan_core/majong_taiwan_core.dart';
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
    _gameTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _processGameLoop();
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _handleEatButton() {
    if (_game.lastDiscardedTile == null) return;
    final options = ActionValidator.getEatOptions(
      _game.playerHands[PlayerPosition.east]!,
      _game.lastDiscardedTile!,
    );
    if (options.isEmpty) return;

    if (options.length == 1) {
      setState(() => _game.submitDecision(PlayerPosition.east, 'EAT', eatTiles: options.first));
      return;
    }

    showDialog<List<int>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B4D3E),
        title: const Text('選擇吃法', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final sequence = [...opt, _game.lastDiscardedTile!]..sort();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(ctx).pop(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: sequence.map((t) => TileWidget(
                      name: _getTileName(t),
                      color: _getTileColor(t),
                      isHighlighted: t == _game.lastDiscardedTile,
                    )).toList(),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('取消', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    ).then((chosen) {
      if (chosen != null) {
        setState(() => _game.submitDecision(PlayerPosition.east, 'EAT', eatTiles: chosen));
      }
    });
  }

  void _processGameLoop() {
    if (_game.state == GameState.gameOver) return;
    setState(() {
      _game.autoProcessActions();
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
    if (tileId >= 61 && tileId <= 64) return '春${tileId - 60}';
    if (tileId >= 65 && tileId <= 68) return '梅${tileId - 64}';
    return '花';
  }

  Color _getTileColor(int tileId) {
    if (tileId >= 11 && tileId <= 19) return Colors.red;
    if (tileId >= 21 && tileId <= 29) return Colors.blue;
    if (tileId >= 31 && tileId <= 39) return Colors.green;
    if (tileId >= 41 && tileId <= 47) return Colors.black87;
    if (tileId == 51) return Colors.red;
    if (tileId == 53) return Colors.green;
    if (tileId == 55) return Colors.blueAccent;
    return Colors.deepOrange;
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _buildOtherPlayerHand(PlayerPosition.north, '北家'),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: RotatedBox(quarterTurns: 1, child: _buildOtherPlayerHand(PlayerPosition.west, '西家')),
                ),
                Expanded(child: _buildTableCenter()),
                SizedBox(
                  width: 100,
                  child: RotatedBox(quarterTurns: 3, child: _buildOtherPlayerHand(PlayerPosition.south, '南家')),
                ),
              ],
            ),
          ),
          _buildMyHand(),
        ],
      ),
    );
  }

  Widget _buildTableCenter() {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: Colors.white10), 
        borderRadius: BorderRadius.circular(15)
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('輪序: ${_game.currentTurn}', style: const TextStyle(fontSize: 14, color: Colors.white38)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: _game.discards.map((tileId) => TileWidget(
                    name: _getTileName(tileId),
                    color: _getTileColor(tileId),
                    isSmall: true,
                    sizeScale: 0.8, 
                  )).toList(),
                ),
              ),
            ),
          ),
          if (_game.state == GameState.gameOver)
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              color: Colors.black87,
              child: Column(
                children: [
                  const Text('遊戲結束', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 5),
                  Text(_game.winner != null ? '獲勝者: ${_game.winner} ${_game.isTsumo ? "(自摸)" : ""}' : '流局', 
                       style: const TextStyle(fontSize: 16, color: Colors.yellowAccent)),
                  if (_game.winner != null) ...[
                    const SizedBox(height: 10),
                    Text('總計: ${_game.totalTai} 台', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      children: _game.winningPatterns.map((p) => Text('${p.name}(${p.tai})', style: const TextStyle(fontSize: 12, color: Colors.white70))).toList(),
                    ),
                  ]
                ],
              ),
            )
          else if (_game.lastDiscardedTile != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('最後出牌: ', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  TileWidget(
                    name: _getTileName(_game.lastDiscardedTile!), 
                    color: _getTileColor(_game.lastDiscardedTile!),
                    sizeScale: 1.0,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtherPlayerHand(PlayerPosition pos, String name) {
    final handCount = _game.playerHands[pos]?.length ?? 0;
    final melts = _game.playerMelts[pos] ?? [];
    final flowers = _game.playerFlowers[pos] ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white30)),
        const SizedBox(height: 5),
        if (flowers.isNotEmpty || melts.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              ...flowers.map((f) => TileWidget(name: _getTileName(f), color: _getTileColor(f), isSmall: true)),
              ...melts.map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: m.tiles.map((t) => TileWidget(name: _getTileName(t), color: _getTileColor(t), isSmall: true)).toList(),
                ),
              )),
            ],
          ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 1,
          children: List.generate(handCount, (index) => Container(
            width: 15, height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.grey.shade400, Colors.white]),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildMyHand() {
    final hand = List<int>.from(_game.playerHands[PlayerPosition.east] ?? []);
    final lastDrawn = _game.lastDrawnTiles[PlayerPosition.east];
    final melts = _game.playerMelts[PlayerPosition.east] ?? [];
    final flowers = _game.playerFlowers[PlayerPosition.east] ?? [];
    final bool canDiscard = _game.currentTurn == PlayerPosition.east && _game.state == GameState.waitingForDiscard;
    final bool canAct = _game.possibleActions.containsKey(PlayerPosition.east);

    // 如果有最新摸到的牌，將它從一般手牌中分離出來
    int? drawnTileToShow;
    if (lastDrawn != null && hand.contains(lastDrawn)) {
      drawnTileToShow = lastDrawn;
      hand.remove(lastDrawn);
      hand.sort(); // 確保其餘手牌順序正確
    } else {
      hand.sort(); // 如果沒有剛摸的牌，也保持排序
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
      color: Colors.black45,
      child: Column(
        children: [
          if (flowers.isNotEmpty || melts.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (flowers.isNotEmpty) ...[
                    const Text('花: ', style: TextStyle(fontSize: 12, color: Colors.white38)),
                    ...flowers.map((f) => TileWidget(name: _getTileName(f), color: _getTileColor(f), isSmall: true)),
                    const SizedBox(width: 20),
                  ],
                  if (melts.isNotEmpty) ...[
                    const Text('亮: ', style: TextStyle(fontSize: 12, color: Colors.white38)),
                    ...melts.map((m) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: m.tiles.map((t) => TileWidget(name: _getTileName(t), color: _getTileColor(t), isSmall: true)).toList(),
                    )),
                  ],
                ],
              ),
            ),
          const Divider(color: Colors.white10, height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 16張一般手牌
                ...hand.map((tileId) => GestureDetector(
                  onTap: () {
                    // 只有在等待出牌狀態才能點擊普通手牌
                    if (canDiscard) setState(() => _game.discard(PlayerPosition.east, tileId));
                  },
                  child: TileWidget(
                    name: _getTileName(tileId), 
                    color: _getTileColor(tileId), 
                    sizeScale: 1.1,
                    // 當前不是等待出牌狀態時，外框變暗
                    borderOverride: canDiscard ? Colors.white24 : Colors.grey.shade600,
                  ),
                )),
                
                // 最新摸到的牌 (拉開間距並使用亮黃色外框)
                if (drawnTileToShow != null) ...[
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      // 只有在等待出牌狀態才能點擊剛摸到的牌
                      if (canDiscard) setState(() => _game.discard(PlayerPosition.east, drawnTileToShow!));
                    },
                    child: TileWidget(
                      name: _getTileName(drawnTileToShow), 
                      color: _getTileColor(drawnTileToShow), 
                      sizeScale: 1.1,
                      isHighlighted: true, // 只有最新這張是亮黃色外框
                      // 如果處於等待動作狀態 (例如自摸決策)，讓它看起來依然可點擊但不是打牌
                      borderOverride: canAct && !canDiscard ? Colors.blueAccent.shade100 : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canAct)
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _game.possibleActions[PlayerPosition.east]!.map((action) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: action == 'WIN' || action == 'TSUMO' ? Colors.red.shade900 : Colors.blue.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (action == 'EAT') {
                          _handleEatButton();
                        } else {
                          setState(() => _game.submitDecision(PlayerPosition.east, action));
                        }
                      },
                      child: Text(action, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  final bool isHighlighted; // 是否是剛摸到的牌
  final Color? borderOverride; // 覆蓋預設邊框顏色 (例如互動提示)
  final bool isSmall;
  final double sizeScale;

  const TileWidget({
    super.key,
    required this.name,
    required this.color,
    this.isHighlighted = false,
    this.borderOverride,
    this.isSmall = false,
    this.sizeScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    double width = isSmall ? 32.0 : 48.0;
    double height = isSmall ? 48.0 : 72.0;
    double fontSize = isSmall ? 13.0 : 22.0;

    width *= sizeScale;
    height *= sizeScale;
    fontSize *= sizeScale;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 3 : 6),
        border: Border.all(
          // 如果是 isHighlighted (剛摸到的牌)，使用亮黃色
          // 否則，使用 borderOverride (例如可點擊提示) 或預設灰色
          color: isHighlighted 
              ? Colors.orangeAccent // 剛摸到的牌使用亮橘黃色
              : (borderOverride ?? Colors.grey.shade400), 
          width: isHighlighted ? 3 : 2
        ),
        boxShadow: [
          if (isHighlighted) 
            // 剛摸到的牌加強陰影效果
            const BoxShadow(color: Colors.orangeAccent, blurRadius: 8, spreadRadius: 1),
          const BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))
        ],
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}
