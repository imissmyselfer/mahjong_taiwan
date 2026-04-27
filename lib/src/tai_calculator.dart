import 'models.dart';

class TaiCalculator {
  static List<TaiPattern> calculate(WinningHand hand, GameContext context) {
    List<TaiPattern> patterns = [];

    // 1. Basic / Contextual
    if (context.isDealer) {
      patterns.add(TaiPattern("莊家", 1));
      if (context.lianZhuangCount > 0) {
        patterns.add(TaiPattern("連${context.lianZhuangCount}拉${context.lianZhuangCount}", context.lianZhuangCount * 2));
      }
    }
    
    if (context.isTsumo) {
      patterns.add(TaiPattern("自摸", 1));
    }

    // 門清 (Concealed Hand)
    bool isConcealed = hand.melts.every((m) => !m.isExposed);
    if (isConcealed) {
      if (context.isTsumo) {
        patterns.add(TaiPattern("門清一摸三", 3)); // Usually Concealed(1) + Tsumo(1) + Bonus(1) = 3
        patterns.removeWhere((p) => p.name == "自摸");
      } else {
        patterns.add(TaiPattern("門清", 1));
      }
    }

    // 2. Honor Tiles (Pungs of Dragons and Winds)
    int dragonPungs = 0;
    for (var melt in hand.melts) {
      if (melt.type == MeltType.triplet || melt.type == MeltType.kong) {
        final tile = melt.tiles[0];
        // Dragons: 51:中, 53:發, 55:白
        if (tile == 51) { patterns.add(TaiPattern("紅中", 1)); dragonPungs++; }
        if (tile == 53) { patterns.add(TaiPattern("青發", 1)); dragonPungs++; }
        if (tile == 55) { patterns.add(TaiPattern("白板", 1)); dragonPungs++; }
        
        // Winds: 41:東, 43:南, 45:西, 47:北
        if (tile == context.roundWind) patterns.add(TaiPattern("圈風", 1));
        if (tile == context.seatWind) patterns.add(TaiPattern("門風", 1));
      }
    }

    // 3. Dragon Patterns (Big/Small Three Dragons)
    // Little Three Dragons: 2 triplets + 1 pair of dragons
    if (dragonPungs == 2 && (hand.eye == 51 || hand.eye == 53 || hand.eye == 55)) {
      patterns.add(TaiPattern("小三元", 4));
      patterns.removeWhere((p) => ["紅中", "青發", "白板"].contains(p.name));
    } else if (dragonPungs == 3) {
      patterns.add(TaiPattern("大三元", 8));
      patterns.removeWhere((p) => ["紅中", "青發", "白板"].contains(p.name));
    }

    // 4. Wind Patterns (Big/Small Four Happiness)
    int windPungs = 0;
    for (var melt in hand.melts) {
      if ((melt.type == MeltType.triplet || melt.type == MeltType.kong) && (melt.tiles[0] >= 41 && melt.tiles[0] <= 47)) {
        windPungs++;
      }
    }
    if (windPungs == 3 && (hand.eye >= 41 && hand.eye <= 47)) {
      patterns.add(TaiPattern("小四喜", 8));
    } else if (windPungs == 4) {
      patterns.add(TaiPattern("大四喜", 16));
    }

    // 5. Hand Structure Patterns
    // Pong-Pong Hu (All Pungs)
    bool allPungs = hand.melts.every((m) => m.type == MeltType.triplet || m.type == MeltType.kong);
    if (allPungs) {
      patterns.add(TaiPattern("碰碰胡", 4));
    }

    // Ping-Hu (All Sequences, no flowers, no honors, not tsumo, not single wait)
    bool allSequences = hand.melts.every((m) => m.type == MeltType.sequence);
    bool noHonorsInHand = (hand.eye < 40) && hand.melts.every((m) => m.tiles.every((t) => t < 40));
    if (allSequences && noHonorsInHand && hand.flowers.isEmpty && !context.isTsumo && !context.isSingleWait) {
      patterns.add(TaiPattern("平胡", 2));
    }

    // 6. Suit Patterns
    bool hasWan = false, hasPin = false, hasTiao = false, hasHonors = false;
    List<int> allTiles = [hand.eye, ...hand.melts.expand((m) => m.tiles)];
    for (var tile in allTiles) {
      if (tile >= 11 && tile <= 19) hasWan = true;
      else if (tile >= 21 && tile <= 29) hasPin = true;
      else if (tile >= 31 && tile <= 39) hasTiao = true;
      else if (tile >= 41 && tile <= 55) hasHonors = true;
    }

    int suitCount = (hasWan ? 1 : 0) + (hasPin ? 1 : 0) + (hasTiao ? 1 : 0);
    if (suitCount == 1) {
      if (hasHonors) {
        patterns.add(TaiPattern("混一色", 4));
      } else {
        patterns.add(TaiPattern("清一色", 8));
      }
    } else if (suitCount == 0 && hasHonors) {
      patterns.add(TaiPattern("字一色", 16));
    }

    // 7. Special Waits / Conditions
    if (context.isSingleWait) {
      patterns.add(TaiPattern("獨聽", 1));
    }

    // 8. Flowers
    // Each flower is 1 Tai (Standard simplified Taiwan rules often use 1 Tai per flower)
    if (hand.flowers.isNotEmpty) {
      patterns.add(TaiPattern("花牌 x${hand.flowers.length}", hand.flowers.length));
    }

    return patterns;
  }
}
