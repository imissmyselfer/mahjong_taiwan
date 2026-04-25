import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:majong_taiwan_core/majong_taiwan_core.dart';
import 'mahjong_game.dart';

// ── Tile data helpers ──────────────────────────────────────────────────────

const _chineseNums = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];

String _tileMainChar(int id) {
  if (id >= 11 && id <= 39) return _chineseNums[(id % 10) - 1];
  if (id == 41) return '東';
  if (id == 43) return '南';
  if (id == 45) return '西';
  if (id == 47) return '北';
  if (id == 51) return '中';
  if (id == 53) return '發';
  if (id == 55) return '白';
  const flowers = ['春', '夏', '秋', '冬', '梅', '蘭', '竹', '菊'];
  if (id >= 61 && id <= 68) return flowers[id - 61];
  return '?';
}

String? _tileSuitLabel(int id) {
  if (id >= 11 && id <= 19) return '萬';
  if (id >= 21 && id <= 29) return '筒';
  if (id >= 31 && id <= 39) return '條';
  return null;
}

String? _tileFlowerLabel(int id) {
  const labels = ['SPRING', 'SUMMER', 'AUTUMN', 'WINTER', 'PLUM', 'ORCHID', 'BAMBOO', 'CHRYSAN.'];
  if (id >= 61 && id <= 68) return labels[id - 61];
  return null;
}

Color _tileColor(int id) {
  if (id >= 11 && id <= 19) return const Color(0xFFB01825);
  if (id >= 21 && id <= 29) return const Color(0xFF0A4E8A);
  if (id >= 31 && id <= 39) return const Color(0xFF0A6020);
  if (id == 51) return const Color(0xFFC01010);
  if (id == 53) return const Color(0xFF0A5E18);
  if (id == 55) return const Color(0xFF8090B0);
  if (id >= 61 && id <= 68) return const Color(0xFF7A2A9A);
  return const Color(0xFF2A2418);
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

    showDialog<List<int>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B4D3E),
        title: const Text('選擇吃法', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final sequence = [...opt, discarded]..sort();
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
                    children: sequence
                        .map((t) => TileWidget(tileId: t, isHighlighted: t == discarded))
                        .toList(),
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
      if (chosen != null && mounted) {
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
                  child: RotatedBox(
                      quarterTurns: 1,
                      child: _buildOtherPlayerHand(PlayerPosition.west, '西家')),
                ),
                Expanded(child: _buildTableCenter()),
                SizedBox(
                  width: 100,
                  child: RotatedBox(
                      quarterTurns: 3,
                      child: _buildOtherPlayerHand(PlayerPosition.south, '南家')),
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
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('輪序: ${_game.currentTurn}',
                style: const TextStyle(fontSize: 14, color: Colors.white38)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: _game.discards
                      .map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: 0.85))
                      .toList(),
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
                  const Text('遊戲結束',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 5),
                  Text(
                    _game.winner != null
                        ? '獲勝者: ${_game.winner} ${_game.isTsumo ? "(自摸)" : ""}'
                        : '流局',
                    style: const TextStyle(fontSize: 16, color: Colors.yellowAccent),
                  ),
                  if (_game.winner != null) ...[
                    const SizedBox(height: 10),
                    Text('總計: ${_game.totalTai} 台',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      children: _game.winningPatterns
                          .map((p) => Text('${p.name}(${p.tai})',
                              style: const TextStyle(fontSize: 12, color: Colors.white70)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            )
          else if (_game.lastDiscardedTile != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('最後出牌: ',
                      style: TextStyle(fontSize: 12, color: Colors.white54)),
                  TileWidget(tileId: _game.lastDiscardedTile!),
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
        Text(name,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white30)),
        const SizedBox(height: 5),
        if (flowers.isNotEmpty || melts.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: [
              ...flowers.map((f) => TileWidget(tileId: f, isSmall: true)),
              ...melts.map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: m.tiles
                          .map((t) => TileWidget(tileId: t, isSmall: true))
                          .toList(),
                    ),
                  )),
            ],
          ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 1,
          children: List.generate(
            handCount,
            (_) => Container(
              width: 15,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade400, Colors.white],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyHand() {
    final hand = List<int>.from(_game.playerHands[PlayerPosition.east] ?? []);
    final lastDrawn = _game.lastDrawnTiles[PlayerPosition.east];
    final melts = _game.playerMelts[PlayerPosition.east] ?? [];
    final flowers = _game.playerFlowers[PlayerPosition.east] ?? [];
    final bool canDiscard =
        _game.currentTurn == PlayerPosition.east && _game.state == GameState.waitingForDiscard;
    final bool canAct = _game.possibleActions.containsKey(PlayerPosition.east);

    int? drawnTileToShow;
    if (lastDrawn != null && hand.contains(lastDrawn)) {
      drawnTileToShow = lastDrawn;
      hand.remove(lastDrawn);
      hand.sort();
    } else {
      hand.sort();
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
                    const Text('花: ',
                        style: TextStyle(fontSize: 12, color: Colors.white38)),
                    ...flowers.map((f) => TileWidget(tileId: f, isSmall: true)),
                    const SizedBox(width: 20),
                  ],
                  if (melts.isNotEmpty) ...[
                    const Text('亮: ',
                        style: TextStyle(fontSize: 12, color: Colors.white38)),
                    ...melts.map((m) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: m.tiles
                              .map((t) => TileWidget(tileId: t, isSmall: true))
                              .toList(),
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
                ...hand.map((id) => GestureDetector(
                      onTap: () {
                        if (canDiscard) setState(() => _game.discard(PlayerPosition.east, id));
                      },
                      child: TileWidget(
                        tileId: id,
                        sizeScale: 1.1,
                        borderOverride: canDiscard ? null : Colors.grey.shade700,
                      ),
                    )),
                if (drawnTileToShow != null) ...[
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () {
                      if (canDiscard) {
                        setState(() => _game.discard(PlayerPosition.east, drawnTileToShow!));
                      }
                    },
                    child: TileWidget(
                      tileId: drawnTileToShow,
                      sizeScale: 1.1,
                      isHighlighted: true,
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
                children: _game.possibleActions[PlayerPosition.east]!
                    .map((action) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: action == 'WIN' || action == 'TSUMO'
                                  ? Colors.red.shade900
                                  : Colors.blue.shade900,
                              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              if (action == 'EAT') {
                                _handleEatButton();
                              } else {
                                setState(() =>
                                    _game.submitDecision(PlayerPosition.east, action));
                              }
                            },
                            child: Text(action,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
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

  const TileWidget({
    super.key,
    required this.tileId,
    this.isHighlighted = false,
    this.borderOverride,
    this.isSmall = false,
    this.sizeScale = 1.0,
  });

  static const _ivoryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFEFCF0),
      Color(0xFFF7F0D8),
      Color(0xFFEFE4BC),
      Color(0xFFE6D8A4),
    ],
    stops: [0.0, 0.25, 0.6, 1.0],
  );

  static const _goldDepthShadows = [
    BoxShadow(color: Color(0xFFB89030), offset: Offset(0, 1)),
    BoxShadow(color: Color(0xFFA07820), offset: Offset(0, 2)),
    BoxShadow(color: Color(0xFF886010), offset: Offset(0, 3)),
    BoxShadow(color: Color(0xFF705000), offset: Offset(0, 4)),
    BoxShadow(color: Color(0x6E000000), offset: Offset(0, 6), blurRadius: 8),
    BoxShadow(color: Color(0x2E000000), offset: Offset(2, 2), blurRadius: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final double w = (isSmall ? 34.0 : 52.0) * sizeScale;
    final double h = (isSmall ? 50.0 : 76.0) * sizeScale;
    final double radius = (isSmall ? 4.0 : 6.0);

    final bool isBai = tileId == 55;
    final String mainChar = _tileMainChar(tileId);
    final String? suitLabel = _tileSuitLabel(tileId);
    final String? flowerLabel = _tileFlowerLabel(tileId);
    final Color charColor = _tileColor(tileId);

    final double mainFontSize =
        (isSmall ? (suitLabel != null ? 17.0 : 20.0) : (suitLabel != null ? 27.0 : 30.0)) *
            sizeScale;
    final double suitFontSize = (isSmall ? 9.5 : 12.5) * sizeScale;
    final double flowerLabelSize = (isSmall ? 6.0 : 8.0) * sizeScale;

    // State-based visuals
    final Gradient bgGradient;
    final Color borderColor;
    final List<BoxShadow> shadows;
    final double yShift;

    if (isHighlighted && borderOverride == null) {
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFEF5), Color(0xFFFFFAD8), Color(0xFFFFE890), Color(0xFFFFD840)],
        stops: [0.0, 0.25, 0.6, 1.0],
      );
      borderColor = const Color(0xFFE8A000);
      shadows = [
        BoxShadow(
            color: const Color(0xFFFFB800).withValues(alpha: 0.65), blurRadius: 14, spreadRadius: 3),
        const BoxShadow(color: Color(0xFFC88000), offset: Offset(0, 1)),
        const BoxShadow(color: Color(0xFFA86800), offset: Offset(0, 2)),
        const BoxShadow(color: Color(0xFF885000), offset: Offset(0, 3)),
        const BoxShadow(color: Color(0xFF683800), offset: Offset(0, 4)),
        const BoxShadow(
            color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 14),
      ];
      yShift = -6.0 * sizeScale;
    } else {
      bgGradient = _ivoryGradient;
      borderColor = borderOverride ?? const Color(0xFFC8A848);
      shadows = _goldDepthShadows;
      yShift = 0;
    }

    // Tile face content
    final Widget tileContent = isBai
        ? Container(
            width: (isSmall ? 18.0 : 28.0) * sizeScale,
            height: (isSmall ? 24.0 : 36.0) * sizeScale,
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFF8090B0), width: 2.5 * sizeScale),
              borderRadius: BorderRadius.circular(3),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mainChar,
                style: GoogleFonts.notoSerifTc(
                  fontSize: mainFontSize,
                  fontWeight: FontWeight.w900,
                  color: charColor,
                  height: 1.0,
                ),
              ),
              if (suitLabel != null) ...[
                SizedBox(height: 2 * sizeScale),
                Text(
                  suitLabel,
                  style: GoogleFonts.notoSerifTc(
                    fontSize: suitFontSize,
                    fontWeight: FontWeight.w700,
                    color: charColor.withValues(alpha: 0.72),
                    height: 1.0,
                  ),
                ),
              ],
              if (flowerLabel != null) ...[
                SizedBox(height: 1 * sizeScale),
                Text(
                  flowerLabel,
                  style: TextStyle(
                    fontSize: flowerLabelSize,
                    fontWeight: FontWeight.w700,
                    color: charColor.withValues(alpha: 0.52),
                    letterSpacing: 0.2,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          );

    return Transform.translate(
      offset: Offset(0, yShift),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5),
            width: w,
            height: h,
            decoration: BoxDecoration(
              gradient: bgGradient,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: shadows,
            ),
            child: Center(child: tileContent),
          ),
          // Inner decorative frame
          Positioned(
            left: 4.5,
            top: 4.5,
            right: 4.5,
            bottom: 4.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.22),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(radius - 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
