import 'dart:async';
import 'package:flutter/material.dart';
import 'package:majong_taiwan_core/majong_taiwan_core.dart';
import 'mahjong_game.dart';

// ── Tile Unicode mapping (I.MahjongTW font, U+1F000–U+1F02B) ──────────────

String _tileChar(int id) {
  if (id >= 11 && id <= 19) return String.fromCharCode(0x1F007 + (id - 11)); // 一~九萬
  if (id >= 21 && id <= 29) return String.fromCharCode(0x1F019 + (id - 21)); // 一~九筒
  if (id >= 31 && id <= 39) return String.fromCharCode(0x1F010 + (id - 31)); // 一~九索
  switch (id) {
    case 41: return String.fromCharCode(0x1F000); // 東
    case 43: return String.fromCharCode(0x1F001); // 南
    case 45: return String.fromCharCode(0x1F002); // 西
    case 47: return String.fromCharCode(0x1F003); // 北
    case 51: return String.fromCharCode(0x1F004); // 中
    case 53: return String.fromCharCode(0x1F005); // 發
    case 55: return String.fromCharCode(0x1F006); // 白
    case 61: return String.fromCharCode(0x1F026); // 春
    case 62: return String.fromCharCode(0x1F027); // 夏
    case 63: return String.fromCharCode(0x1F028); // 秋
    case 64: return String.fromCharCode(0x1F029); // 冬
    case 65: return String.fromCharCode(0x1F022); // 梅
    case 66: return String.fromCharCode(0x1F023); // 蘭
    case 67: return String.fromCharCode(0x1F024); // 竹
    case 68: return String.fromCharCode(0x1F025); // 菊
    default: return String.fromCharCode(0x1F02B); // 牌背
  }
}

// ── App ───────────────────────────────────────────────────────────────────

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
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFDCE7E0), // 雅緻青磁色，視覺更舒適
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A6759), // 深沈草本綠
          foregroundColor: Colors.white,
          elevation: 0,
        ),
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

  Future<void> _handleEatButton() async {
    if (_game.lastDiscardedTile == null) return;
    final discarded = _game.lastDiscardedTile!;
    final options = ActionValidator.getEatOptions(
      _game.playerHands[PlayerPosition.east]!,
      discarded,
    );
    if (options.isEmpty) return;

    if (options.length == 1) {
      setState(() => _game.submitDecision(PlayerPosition.east, 'EAT', eatTiles: options.first));
      return;
    }

    final chosen = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('選擇吃法', style: TextStyle(color: Color(0xFF2D4B3E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final sequence = [...opt, discarded]..sort();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(opt),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: sequence.map((t) => TileWidget(tileId: t, isHighlighted: t == discarded)).toList(),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _game.submitDecision(PlayerPosition.east, 'EAT', eatTiles: chosen));
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('台灣十六張麻將', style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w400)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _game = MahjongGame()),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildOtherPlayerHand(PlayerPosition.north, '北家'),
            Expanded(
              child: Row(
                children: [
                  _buildSidePlayer(PlayerPosition.west, '西家', 1),
                  Expanded(child: _buildTableCenter()),
                  _buildSidePlayer(PlayerPosition.south, '南家', 3),
                ],
              ),
            ),
            _buildMyHand(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePlayer(PlayerPosition pos, String name, int turns) {
    return SizedBox(
      width: 90,
      child: RotatedBox(
        quarterTurns: turns,
        child: Center(child: _buildOtherPlayerHand(pos, name)),
      ),
    );
  }

  Widget _buildTableCenter() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCAD3CD), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '當前輪序: ${_game.currentTurn.name.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8C83), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 2,
                children: _game.discards.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: 0.75)).toList(),
              ),
            ),
          ),
          if (_game.state == GameState.gameOver) _buildGameOverInfo()
          else if (_game.lastDiscardedTile != null) _buildLastDiscard(),
        ],
      ),
    );
  }

  Widget _buildGameOverInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE8ECE9),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const Text('遊戲結束', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A6759))),
          Text(_game.winner != null ? '獲勝: ${_game.winner!.name}' : '流局', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLastDiscard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('最後出牌 ', style: TextStyle(fontSize: 11, color: Colors.black38)),
          TileWidget(tileId: _game.lastDiscardedTile!, isSmall: true, sizeScale: 0.8),
        ],
      ),
    );
  }

  Widget _buildOtherPlayerHand(PlayerPosition pos, String name) {
    final handCount = _game.playerHands[pos]?.length ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF5C7A6D))),
        const SizedBox(height: 4),
        Wrap(
          spacing: -14,
          children: List.generate(handCount, (_) => const TileWidget(tileId: -1, isBack: true, isSmall: true, sizeScale: 0.65)),
        ),
      ],
    );
  }

  Widget _buildMyHand() {
    final hand = List<int>.from(_game.playerHands[PlayerPosition.east] ?? []);
    final flowers = _game.playerFlowers[PlayerPosition.east] ?? [];
    final melts = _game.playerMelts[PlayerPosition.east] ?? [];
    final lastDrawn = _game.lastDrawnTiles[PlayerPosition.east];
    final bool canDiscard = _game.currentTurn == PlayerPosition.east && _game.state == GameState.waitingForDiscard;
    final bool canAct = _game.state != GameState.gameOver && _game.possibleActions.containsKey(PlayerPosition.east);

    if (lastDrawn != null && hand.contains(lastDrawn)) {
      hand.remove(lastDrawn);
      hand.sort();
    } else {
      hand.sort();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0E8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (melts.isNotEmpty || flowers.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ...melts.map((melt) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCAD3CD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: melt.tiles.map((id) => TileWidget(tileId: id, sizeScale: 0.65, isSmall: true)).toList(),
                    ),
                  )),
                  if (flowers.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EEF8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD7BDE2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('花 ', style: TextStyle(fontSize: 10, color: Color(0xFF9C6EAA))),
                          ...flowers.map((id) => TileWidget(tileId: id, sizeScale: 0.65, isSmall: true)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...hand.map((id) => GestureDetector(
                  onTap: () => canDiscard ? setState(() => _game.discard(PlayerPosition.east, id)) : null,
                  child: TileWidget(tileId: id, borderOverride: canDiscard ? const Color(0xFF8A9E96) : Colors.black12, borderWidth: canDiscard ? 2.5 : 1),
                )),
                if (lastDrawn != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => canDiscard ? setState(() => _game.discard(PlayerPosition.east, lastDrawn)) : null,
                    child: TileWidget(tileId: lastDrawn, isHighlighted: true),
                  ),
                ],
              ],
            ),
          ),
          if (canAct) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _game.possibleActions[PlayerPosition.east]!.map((action) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'WIN' || action == 'TSUMO' ? const Color(0xFFC66A6A) : const Color(0xFF5C7A6D),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () => action == 'EAT' ? _handleEatButton() : setState(() => _game.submitDecision(PlayerPosition.east, action)),
            child: Text(action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )).toList(),
      ),
    );
  }
}

// ── TileWidget ────────────────────────────────────────────────────────────

class TileWidget extends StatelessWidget {
  final int tileId;
  final bool isHighlighted;
  final Color? borderOverride;
  final bool isSmall;
  final double sizeScale;
  final bool isBack;
  final double? borderWidth;

  const TileWidget({
    super.key,
    required this.tileId,
    this.isHighlighted = false,
    this.borderOverride,
    this.isSmall = false,
    this.sizeScale = 1.0,
    this.isBack = false,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = (isSmall ? 28.0 : 44.0) * sizeScale;
    final String char = isBack
        ? String.fromCharCode(0x1F02B)
        : _tileChar(tileId);

    Widget tile = Text(
      char,
      style: TextStyle(
        fontFamily: 'MahjongTW',
        fontSize: fontSize,
        height: 1.0,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );

    final Color? borderColor = isHighlighted
        ? const Color(0xFFD4AF37)
        : borderOverride;
    final double bw = isHighlighted ? 2.5 : (borderWidth ?? 1.5);

    if (borderColor != null) {
      tile = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: bw),
        ),
        child: tile,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(1),
      child: tile,
    );
  }
}