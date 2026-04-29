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
  bool _soundEnabled = true;
  bool _isEnglish = false;
  BotDifficulty _difficulty = BotDifficulty.normal;

  Map<BotDifficulty, String> get _difficultyLabels => _isEnglish ? {
    BotDifficulty.easy: 'Easy',
    BotDifficulty.normal: 'Normal',
    BotDifficulty.hard: 'Hard',
  } : {
    BotDifficulty.easy: '簡單',
    BotDifficulty.normal: '普通',
    BotDifficulty.hard: '困難',
  };

  Map<String, String> get _actionLabels => _isEnglish ? {
    'WIN': 'Win',
    'TSUMO': 'Self-Draw',
    'PONG': 'Pong',
    'KONG': 'Kong',
    'EAT': 'Eat',
    'PASS': 'Pass',
  } : {
    'WIN': '胡牌',
    'TSUMO': '自摸',
    'PONG': '碰',
    'KONG': '槓',
    'EAT': '吃',
    'PASS': '過',
  };

  static const _posNamesZh = {
    PlayerPosition.east: '東家',
    PlayerPosition.south: '南家',
    PlayerPosition.west: '西家',
    PlayerPosition.north: '北家',
  };
  static const _posNamesEn = {
    PlayerPosition.east: 'East',
    PlayerPosition.south: 'South',
    PlayerPosition.west: 'West',
    PlayerPosition.north: 'North',
  };

  String _t(String zh, String en) => _isEnglish ? en : zh;
  String _posName(PlayerPosition pos) => (_isEnglish ? _posNamesEn : _posNamesZh)[pos]!;

  static const _patternNamesEn = {
    '莊家': 'Dealer',
    '自摸': 'Self-Draw',
    '門清一摸三': 'Concealed+Self-Draw',
    '門清': 'Concealed Hand',
    '紅中': 'Red Dragon',
    '青發': 'Green Dragon',
    '白板': 'White Dragon',
    '圈風': 'Round Wind',
    '門風': 'Seat Wind',
    '小三元': 'Little 3 Dragons',
    '大三元': 'Big 3 Dragons',
    '小四喜': 'Little 4 Winds',
    '大四喜': 'Big 4 Winds',
    '碰碰胡': 'All Triplets',
    '平胡': 'All Sequences',
    '混一色': 'Half Flush',
    '清一色': 'Full Flush',
    '字一色': 'All Honors',
    '獨聽': 'Single Wait',
  };

  String _patternName(String zhName) {
    if (!_isEnglish) return zhName;
    if (zhName.startsWith('花牌')) return 'Flowers ${zhName.replaceAll('花牌 ', '')}';
    if (zhName.startsWith('連')) {
      final match = RegExp(r'連(\d+)').firstMatch(zhName);
      if (match != null) return 'Dealer Streak ×${match.group(1)}';
    }
    return _patternNamesEn[zhName] ?? zhName;
  }

  Future<void> _playSound(String name) async {
    if (!_soundEnabled) return;
    await _audio.stop();
    await _audio.play(AssetSource('sounds/$name.mp3'));
  }

  void _newGame() {
    setState(() => _game = MahjongGame(difficulty: _difficulty));
  }

  @override
  void initState() {
    super.initState();
    _game = MahjongGame(difficulty: _difficulty);
    _gameTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
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
      _game.players[PlayerPosition.east]!.hand,
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
        title: Text(_t('選擇吃法', 'Choose Eat'), style: const TextStyle(color: Color(0xFF2D4B3E), fontWeight: FontWeight.bold)),
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
      // 標籤剛設好時（bot 剛碰/槓/吃），這一 tick 不出牌，讓 UI 顯示標籤
      if (_game.state == GameState.waitingForDiscard &&
          _game.isBot(_game.currentTurn) &&
          _game.players.values.every((p) => p.actionLabel == null)) {
        _game.botAutoDiscard();
      }
    });
    // AI 出牌聲
    if (prevState == GameState.waitingForDiscard && _game.state == GameState.waitingForActions) {
      _playSound('discard');
    }
    // AI 碰/槓/吃聲（只在標籤剛設好的那一 tick 播一次）
    if (_game.isNewActionLabel) {
      _playSound('action');
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
        title: Text(
          '${_t('台灣十六張麻將', 'Taiwan Mahjong')} · ${_difficultyLabels[_difficulty]}',
          style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w400),
        ),
        actions: [
          PopupMenuButton<BotDifficulty>(
            icon: const Icon(Icons.psychology_rounded),
            tooltip: _t('BOT 難度', 'BOT Difficulty'),
            onSelected: (level) {
              setState(() {
                _difficulty = level;
                _game = MahjongGame(difficulty: level);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_t('已切換為「${_difficultyLabels[level]}」，新局開始', 'Switched to "${_difficultyLabels[level]}", new game started')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (ctx) => BotDifficulty.values
                .map((level) => CheckedPopupMenuItem<BotDifficulty>(
                      value: level,
                      checked: _difficulty == level,
                      child: Text(_difficultyLabels[level]!),
                    ))
                .toList(),
          ),
          TextButton(
            onPressed: () => setState(() => _isEnglish = !_isEnglish),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(
              _isEnglish ? '繁中' : 'EN',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(_soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
            tooltip: _t(_soundEnabled ? '關閉音效' : '開啟音效', _soundEnabled ? 'Sound Off' : 'Sound On'),
            onPressed: () {
              setState(() => _soundEnabled = !_soundEnabled);
              if (!_soundEnabled) _audio.stop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: _t('重新開局', 'New Game'),
            onPressed: _newGame,
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double sideW = w < 440 ? (w * 0.14).clamp(50.0, 80.0) : 110.0;
            final double topH = w < 440 ? 80.0 : 120.0;
            return Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: topH,
                  child: ClipRect(
                    child: OverflowBox(
                      maxHeight: double.infinity,
                      alignment: Alignment.topCenter,
                      child: _buildOtherPlayerHand(PlayerPosition.west, _posName(PlayerPosition.west)),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      _buildSidePlayer(PlayerPosition.north, _posName(PlayerPosition.north), 1, width: sideW),
                      Expanded(child: _buildTableCenter()),
                      _buildSidePlayer(PlayerPosition.south, _posName(PlayerPosition.south), 3, width: sideW),
                    ],
                  ),
                ),
                _buildMyHand(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidePlayer(PlayerPosition pos, String name, int turns, {double width = 110}) {
    return ClipRect(
      child: SizedBox(
        width: width,
        child: RotatedBox(
          quarterTurns: turns,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildOtherPlayerHand(pos, name),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCenter() {
    final hasEastActions = _game.state != GameState.gameOver &&
        _game.possibleActions.containsKey(PlayerPosition.east);
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
              _t('當前輪序: ', 'Turn: ') + _posName(_game.currentTurn),
              style: const TextStyle(fontSize: 16, color: Color(0xFF7A8C83), fontWeight: FontWeight.w600),
            ),
          ),
          _buildActionAnnouncement(),
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
          if (hasEastActions) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionAnnouncement() {
    final posKeys = [PlayerPosition.north, PlayerPosition.west, PlayerPosition.south];
    final active = posKeys.where((p) => _game.players[p]!.actionLabel != null).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        children: active.map((pos) {
          final label = _game.players[pos]!.actionLabel!;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_posName(pos), style: const TextStyle(fontSize: 13, color: Color(0xFF7A8C83))),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (label == 'WIN' || label == 'TSUMO') ? const Color(0xFFC66A6A) : const Color(0xFF5C7A6D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _actionLabels[label] ?? label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameOverInfo() {
    final winner = _game.winner;
    final showHand = winner != null && winner != PlayerPosition.east;

    List<Widget> handWidgets = [];
    if (showHand) {
      final p = _game.players[winner]!;
      final hand = List<int>.from(p.hand)..sort();
      final melts = p.melts;
      final flowers = p.flowers;

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
          Text(_t('遊戲結束', 'Game Over'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A6759))),
          const SizedBox(height: 4),
          if (winner != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_t('獲勝：', 'Winner: ')}${_posName(winner)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6759),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('✦ $totalTai ${_t('台', 'pts')}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _game.isTsumo
                  ? _t('自摸', 'Self-Draw')
                  : _t('放槍：', 'Discard by: ') + (_game.firer != null ? _posName(_game.firer!) : '?'),
              style: TextStyle(
                fontSize: 13,
                color: _game.isTsumo ? const Color(0xFF4A6759) : const Color(0xFFC66A6A),
                fontWeight: FontWeight.w500,
              ),
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
                  child: Text('${_patternName(p.name)}  ${p.tai}${_t('台', 'pts')}', style: const TextStyle(fontSize: 13, color: Color(0xFF2D4B3E))),
                )).toList(),
              ),
            ],
          ] else
            Text(_t('流局', 'Draw'), style: const TextStyle(fontSize: 15)),
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
          Text(_t('最後出牌 ', 'Last Discard '), style: const TextStyle(fontSize: 13, color: Colors.black38)),
          TileWidget(tileId: _game.lastDiscardedTile!, isSmall: true, sizeScale: 0.8),
        ],
      ),
    );
  }

  Widget _buildOtherPlayerHand(PlayerPosition pos, String name) {
    final p = _game.players[pos]!;
    final handCount = p.hand.length;
    final melts = p.melts;
    final flowers = p.flowers;
    final actionLabel = p.actionLabel;

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
    final p = _game.players[PlayerPosition.east]!;
    final hand = List<int>.from(p.hand);
    final flowers = p.flowers;
    final melts = p.melts;
    final lastDrawn = p.lastDrawn;
    final bool canDiscard = _game.currentTurn == PlayerPosition.east && _game.state == GameState.waitingForDiscard;

    if (lastDrawn != null && hand.contains(lastDrawn)) {
      hand.remove(lastDrawn);
      hand.sort();
    } else {
      hand.sort();
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool compact = MediaQuery.of(context).size.shortestSide < 480;
    final bool narrow = screenWidth < 440;
    final double meltScale = compact ? 0.65 : 0.85;

    GestureDetector tileTap(int id, {bool highlighted = false}) => GestureDetector(
      onTap: () { if (canDiscard) { _playSound('discard'); setState(() => _game.discard(PlayerPosition.east, id)); } },
      child: highlighted
          ? TileWidget(tileId: id, isHighlighted: true)
          : TileWidget(tileId: id, borderOverride: canDiscard ? const Color(0xFF8A9E96) : null, borderWidth: canDiscard ? 2.5 : 1),
    );

    Widget meltChip(Melt melt) => Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
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
    );

    Widget flowerChip() => Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7BDE2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_t('花 ', 'Flower '), style: const TextStyle(fontSize: 12, color: Color(0xFF9C6EAA))),
          ...flowers.map((id) => TileWidget(tileId: id, isSmall: true, sizeScale: meltScale)),
        ],
      ),
    );

    // 窄螢幕：Wrap 自動換行，全部牌都看得到
    // 寬螢幕：SingleChildScrollView 單排橫向滾動
    Widget meltsWidget = narrow
        ? Wrap(
            spacing: 0,
            runSpacing: 0,
            children: [
              ...melts.map(meltChip),
              if (flowers.isNotEmpty) flowerChip(),
            ],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...melts.map(meltChip),
                if (flowers.isNotEmpty) flowerChip(),
              ],
            ),
          );

    Widget tilesWidget = narrow
        ? Wrap(
            spacing: 2,
            runSpacing: 4,
            children: [
              ...hand.map((id) => tileTap(id)),
              if (lastDrawn != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: tileTap(lastDrawn, highlighted: true),
                ),
            ],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...hand.map((id) => tileTap(id)),
                if (lastDrawn != null) ...[
                  const SizedBox(width: 12),
                  tileTap(lastDrawn, highlighted: true),
                ],
              ],
            ),
          );

    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 8, 12, 12)
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
            meltsWidget,
            const SizedBox(height: 4),
          ],
          tilesWidget,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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