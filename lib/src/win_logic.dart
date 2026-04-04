class WinLogic {
  /// Checks if a hand of 17 tiles can win.
  /// A winning hand consists of 5 triplets/sequences (Melts) and 1 pair (Eye).
  static bool isWinning(List<int> hand) {
    if (hand.length != 17) return false;

    // Create a frequency map
    final Map<int, int> counts = {};
    for (var tile in hand) {
      counts[tile] = (counts[tile] ?? 0) + 1;
    }

    // Iterate through each tile type to see if it can be the "Eye" (pair)
    for (var tile in counts.keys) {
      if (counts[tile]! >= 2) {
        // Potential Eye
        final Map<int, int> remaining = Map.from(counts);
        remaining[tile] = remaining[tile]! - 2;
        if (remaining[tile] == 0) remaining.remove(tile);

        // Try to decompose the remaining 15 tiles into 5 Melts
        if (_canDecompose(remaining, 5)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Recursively tries to decompose the remaining tiles into [n] melts (triplets or sequences).
  static bool _canDecompose(Map<int, int> counts, int n) {
    if (n == 0) return counts.isEmpty;

    // Pick the smallest tile index to start decomposition
    final sortedTiles = counts.keys.toList()..sort();
    if (sortedTiles.isEmpty) return n == 0;
    
    final tile = sortedTiles.first;

    // Option 1: Try to remove a Triplet (3 of a kind)
    if (counts[tile]! >= 3) {
      final nextCounts = Map<int, int>.from(counts);
      nextCounts[tile] = nextCounts[tile]! - 3;
      if (nextCounts[tile] == 0) nextCounts.remove(tile);
      if (_canDecompose(nextCounts, n - 1)) return true;
    }

    // Option 2: Try to remove a Sequence (n, n+1, n+2)
    // Only available for Wan (1x), Pin (2x), and Tiao (3x)
    if (tile < 40) {
      // Check if it's within the valid range for a sequence start (1-7)
      final rank = tile % 10;
      if (rank <= 7) {
        final t1 = tile + 1;
        final t2 = tile + 2;
        if (counts.containsKey(t1) && counts.containsKey(t2)) {
          final nextCounts = Map<int, int>.from(counts);
          nextCounts[tile] = nextCounts[tile]! - 1;
          nextCounts[t1] = nextCounts[t1]! - 1;
          nextCounts[t2] = nextCounts[t2]! - 1;
          
          // Remove keys with zero count
          [tile, t1, t2].forEach((t) {
            if (nextCounts[t] == 0) nextCounts.remove(t);
          });

          if (_canDecompose(nextCounts, n - 1)) return true;
        }
      }
    }

    return false;
  }
}
