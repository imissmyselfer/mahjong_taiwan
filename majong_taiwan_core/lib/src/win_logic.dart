import 'models.dart';

class WinLogic {
  /// Checks if a hand of 17 tiles can win.
  static bool isWinning(List<int> hand) {
    return decompose(hand, []) != null;
  }

  /// Decomposes a hand into its winning structure (Melts and Eye).
  static WinningHand? decompose(List<int> concealedHand, List<Melt> exposedMelts, {List<int> flowers = const []}) {
    // Total tiles (concealed + exposed) must be 17 for a win in Taiwan 16-card Mahjong.
    // Exposed Kongs (4 tiles) count as 3 in terms of "set count" but occupy 4 in hand.
    // However, in our system, we handle Kong as a special Melt.
    int totalSets = exposedMelts.length;
    
    // Each Kong in exposedMelts counts as 1 set.
    // Each Pong/Eat in exposedMelts counts as 1 set.
    
    final Map<int, int> counts = {};
    for (var tile in concealedHand) {
      counts[tile] = (counts[tile] ?? 0) + 1;
    }

    // Iterate through each tile type to see if it can be the "Eye" (pair)
    for (var tile in counts.keys) {
      if (counts[tile]! >= 2) {
        final Map<int, int> remaining = Map.from(counts);
        remaining[tile] = remaining[tile]! - 2;
        if (remaining[tile] == 0) remaining.remove(tile);

        final List<Melt> concealedMelts = [];
        if (_findMelts(remaining, 5 - totalSets, concealedMelts)) {
          return WinningHand(
            eye: tile,
            melts: [...exposedMelts, ...concealedMelts],
            flowers: flowers,
          );
        }
      }
    }

    return null;
  }

  static bool _findMelts(Map<int, int> counts, int n, List<Melt> foundMelts) {
    if (n == 0) return counts.isEmpty;

    final sortedTiles = counts.keys.toList()..sort();
    if (sortedTiles.isEmpty) return n == 0;
    
    final tile = sortedTiles.first;

    // Option 1: Try Triplet
    if (counts[tile]! >= 3) {
      final nextCounts = Map<int, int>.from(counts);
      nextCounts[tile] = nextCounts[tile]! - 3;
      if (nextCounts[tile] == 0) nextCounts.remove(tile);
      
      foundMelts.add(Melt(tiles: [tile, tile, tile], type: MeltType.triplet));
      if (_findMelts(nextCounts, n - 1, foundMelts)) return true;
      foundMelts.removeLast();
    }

    // Option 2: Try Sequence
    if (tile < 40) {
      final rank = tile % 10;
      if (rank <= 7) {
        final t1 = tile + 1;
        final t2 = tile + 2;
        if (counts.containsKey(t1) && counts.containsKey(t2)) {
          final nextCounts = Map<int, int>.from(counts);
          nextCounts[tile] = nextCounts[tile]! - 1;
          nextCounts[t1] = nextCounts[t1]! - 1;
          nextCounts[t2] = nextCounts[t2]! - 1;
          
          [tile, t1, t2].forEach((t) {
            if (nextCounts[t] == 0) nextCounts.remove(t);
          });

          foundMelts.add(Melt(tiles: [tile, t1, t2], type: MeltType.sequence));
          if (_findMelts(nextCounts, n - 1, foundMelts)) return true;
          foundMelts.removeLast();
        }
      }
    }

    return false;
  }
}
