import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:majong_taiwan_core/majong_taiwan_core.dart';
import 'mahjong_game.dart';

// ── Tile asset mapping ─────────────────────────────────────────────────────
// 花牌用手工 SVG，其餘用 PNG（Inkscape SVG 含 filter/marker，flutter_svg 不支援）

String _tileAssetPath(int id) {
  if (id >= 61 && id <= 68) return 'assets/tiles/flower${id - 60}.svg';
  if (id >= 11 && id <= 19) return 'assets/tiles/Man${id - 10}.png';
  if (id >= 21 && id <= 29) return 'assets/tiles/Pin${id - 20}.png';
  if (id >= 31 && id <= 39) return 'assets/tiles/Sou${id - 30}.png';
  switch (id) {
    case 41: return 'assets/tiles/Ton.png';
    case 43: return 'assets/tiles/Nan.png';
    case 45: return 'assets/tiles/Shaa.png';
    case 47: return 'assets/tiles/Pei.png';
    case 51: return 'assets/tiles/Chun.png';
    case 53: return 'assets/tiles/Hatsu.png';
    case 55: return 'assets/tiles/Haku.png';
    default: return 'assets/tiles/Front.png';
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
        scaffoldBackgroundColor: const Color(0xFFDCE7E0),
        fontFamily: 'Iansui',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Iansui'),
          bodySmall: TextStyle(fontFamily: 'Iansui'),
          bodyLarge: TextStyle(fontFamily: 'Iansui'),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A6759),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Iansui',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
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
  final AudioPlayer _audio = AudioPlayer();

  Future<void> _playSound(String name) async {
    await _audio.stop();
    await _audio.play(AssetSource('sounds/$name.mp3'));
  }

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
    _audio.dispose();
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
      _playSound('action');
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
      _playSound('action');
      setState(() => _game.submitDecision(PlayerPosition.east, 'EAT', eatTiles: chosen));
    }
  }

  void _processGameLoop() {
    if (_game.state == GameState.gameOver) return;
    final prevState = _game.state;
    setState(() {
      _game.autoProcessActions();
      if (_game.state == GameState.waitingForDiscard && _game.isBot(_game.currentTurn)) {
        _game.botAutoDiscard();
      }
    });
    // AI 出牌聲
    if (prevState == GameState.waitingForDiscard && _game.state == GameState.waitingForActions) {
      _playSound('discard');
    }
    // AI 碰/槓/吃聲
    if (prevState == GameState.waitingForActions && _game.state == GameState.waitingForDiscard) {
      final acted = _game.lastActionLabels.values.any((v) => v != null);
      if (acted) _playSound('action');
    }
    // 胡牌聲
    if (_game.state == GameState.gameOver && prevState != GameState.gameOver) {
      _playSound('win');
    }
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
            SizedBox(
              height: 120,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _buildOtherPlayerHand(PlayerPosition.north, '北家'),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildSidePlayer(PlayerPosition.west, '西家', 1),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildTableCenter()),
                        if (_game.state != GameState.gameOver &&
                            _game.possibleActions.containsKey(PlayerPosition.east))
                          Positioned(
                            left: 0, right: 0, bottom: 12,
                            child: _buildActionButtons(),
                          ),
                      ],
                    ),
                  ),
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
    return ClipRect(
      child: SizedBox(
        width: 110,
        child: RotatedBox(
          quarterTurns: turns,
          child: Center(child: _buildOtherPlayerHand(pos, name)),
        ),
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
              '當前輪序: ${const {PlayerPosition.east: '東', PlayerPosition.south: '南', PlayerPosition.west: '西', PlayerPosition.north: '北'}[_game.currentTurn]}家',
              style: const TextStyle(fontSize: 16, color: Color(0xFF7A8C83), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                alignment: WrapAlignment.start,
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
    final winner = _game.winner;
    final showHand = winner != null && winner != PlayerPosition.east;

    List<Widget> handWidgets = [];
    if (showHand) {
      final hand = List<int>.from(_game.playerHands[winner] ?? [])..sort();
      final melts = _game.playerMelts[winner] ?? [];
      final flowers = _game.playerFlowers[winner] ?? [];

      handWidgets = [
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...melts.map((melt) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCAD3CD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: melt.tiles.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: 0.8)).toList(),
                ),
              )),
              ...hand.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: 0.8)),
              if (flowers.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EEF8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD7BDE2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: flowers.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: 0.8)).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    }

    final patterns = _game.winningPatterns;
    final totalTai = _game.totalTai;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFE8ECE9),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('遊戲結束', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A6759))),
          const SizedBox(height: 4),
          if (winner != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('獲勝：${winner.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6759),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('✦ $totalTai 台', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (patterns.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFBDCAC5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: patterns.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBDCAC5)),
                  ),
                  child: Text('${p.name}  ${p.tai}台', style: const TextStyle(fontSize: 13, color: Color(0xFF2D4B3E))),
                )).toList(),
              ),
            ],
          ] else
            const Text('流局', style: TextStyle(fontSize: 15)),
          ...handWidgets,
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
          const Text('最後出牌 ', style: TextStyle(fontSize: 13, color: Colors.black38)),
          TileWidget(tileId: _game.lastDiscardedTile!, isSmall: true, sizeScale: 0.8),
        ],
      ),
    );
  }

  Widget _buildOtherPlayerHand(PlayerPosition pos, String name) {
    final handCount = _game.playerHands[pos]?.length ?? 0;
    final melts = _game.playerMelts[pos] ?? [];
    final flowers = _game.playerFlowers[pos] ?? [];

    final actionLabel = _game.lastActionLabels[pos];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(fontSize: 15, color: Color(0xFF5C7A6D), fontWeight: FontWeight.w500)),
            if (actionLabel != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (actionLabel == 'WIN' || actionLabel == 'TSUMO') ? const Color(0xFFC66A6A) : const Color(0xFF5C7A6D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _actionLabels[actionLabel] ?? actionLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: -14,
          children: List.generate(handCount, (_) => const TileWidget(tileId: -1, isBack: true, isSmall: true, sizeScale: 0.65)),
        ),
        if (melts.isNotEmpty || flowers.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...melts.map((melt) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCAD3CD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: melt.tiles.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: 0.65)).toList(),
                ),
              )),
              if (flowers.isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EEF8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD7BDE2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: flowers.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: 0.65)).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMyHand() {
    final hand = List<int>.from(_game.playerHands[PlayerPosition.east] ?? []);
    final flowers = _game.playerFlowers[PlayerPosition.east] ?? [];
    final melts = _game.playerMelts[PlayerPosition.east] ?? [];
    final lastDrawn = _game.lastDrawnTiles[PlayerPosition.east];
    final bool canDiscard = _game.currentTurn == PlayerPosition.east && _game.state == GameState.waitingForDiscard;

    if (lastDrawn != null && hand.contains(lastDrawn)) {
      hand.remove(lastDrawn);
      hand.sort();
    } else {
      hand.sort();
    }

    // landscape 手機 shortestSide < 480 → compact 模式縮小牌和 padding
    final bool compact = MediaQuery.of(context).size.shortestSide < 480;
    final double meltScale = compact ? 0.65 : 0.85;

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(16, 8, 16, 16)
          : const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
                      children: melt.tiles.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: meltScale)).toList(),
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
                          const Text('花 ', style: TextStyle(fontSize: 12, color: Color(0xFF9C6EAA))),
                          ...flowers.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: meltScale)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...hand.map((id) => GestureDetector(
                  onTap: () { if (canDiscard) { _playSound('discard'); setState(() => _game.discard(PlayerPosition.east, id)); } },
                  child: TileWidget(tileId: id, borderOverride: canDiscard ? const Color(0xFF8A9E96) : null, borderWidth: canDiscard ? 2.5 : 1),
                )),
                if (lastDrawn != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () { if (canDiscard) { _playSound('discard'); setState(() => _game.discard(PlayerPosition.east, lastDrawn)); } },
                    child: TileWidget(tileId: lastDrawn, isHighlighted: true),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _actionLabels = {
    'WIN': '胡牌',
    'TSUMO': '自摸',
    'PONG': '碰',
    'KONG': '槓',
    'EAT': '吃',
    'PASS': '過',
  };

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
            onPressed: () {
              if (action == 'EAT') {
                _handleEatButton();
              } else {
                final sound = (action == 'WIN' || action == 'TSUMO') ? 'win' : 'action';
                _playSound(sound);
                setState(() => _game.submitDecision(PlayerPosition.east, action));
              }
            },
            child: Text(_actionLabels[action] ?? action, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final double shortest = MediaQuery.of(context).size.shortestSide;
    final double baseNormal = shortest > 800 ? 64.0 : (shortest > 480 ? 48.0 : 36.0);
    final double baseSmall  = shortest > 800 ? 44.0 : (shortest > 480 ? 32.0 : 24.0);
    final double w = (isSmall ? baseSmall : baseNormal) * sizeScale;
    final double h = w * 1.35;
    final double radius = isSmall ? 4.0 : 6.0;

    final Color? borderColor = isHighlighted
        ? const Color(0xFFD4AF37)
        : borderOverride;
    final double bw = isHighlighted ? 2.5 : (borderWidth ?? 1.0);

    return Container(
      margin: const EdgeInsets.all(1),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: isBack ? const Color(0xFF2D4B3E) : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? const Color(0xFFD1D1D1),
          width: borderColor != null ? bw : 1.0,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(0, 2), blurRadius: 2),
        ],
      ),
      child: isBack ? null : ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _tileAssetPath(tileId).endsWith('.svg')
            ? SvgPicture.asset(_tileAssetPath(tileId), fit: BoxFit.fill)
            : Image.asset(_tileAssetPath(tileId), fit: BoxFit.cover),
      ),
    );
  }
}