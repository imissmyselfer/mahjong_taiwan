enum MeltType { sequence, triplet, kong }

class Melt {
  final List<int> tiles;
  final MeltType type;
  final bool isExposed; // Was it Eat/Pong/Kong'ed?

  Melt({required this.tiles, required this.type, this.isExposed = false});
  
  @override
  String toString() => "Melt(type: $type, tiles: $tiles, exposed: $isExposed)";
}

class WinningHand {
  final int eye;
  final List<Melt> melts;
  final List<int> flowers;

  WinningHand({required this.eye, required this.melts, this.flowers = const []});
}

class GameContext {
  final int roundWind; // 41:East, 43:South, 45:West, 47:North
  final int seatWind;  // 41, 43, 45, 47
  final bool isDealer;
  final int lianZhuangCount;
  final bool isTsumo;
  final int lastTile;
  final bool isSingleWait; 

  GameContext({
    required this.roundWind,
    required this.seatWind,
    this.isDealer = false,
    this.lianZhuangCount = 0,
    this.isTsumo = false,
    this.lastTile = 0,
    this.isSingleWait = false,
  });
}

class TaiPattern {
  final String name;
  final int tai;
  TaiPattern(this.name, this.tai);
}
