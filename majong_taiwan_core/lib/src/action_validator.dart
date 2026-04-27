class ActionValidator {
  /// Checks if a player can "Pong" (Triplet) the discarded tile.
  static bool canPong(List<int> hand, int discardedTile) {
    int count = hand.where((t) => t == discardedTile).length;
    return count >= 2;
  }

  /// Checks if a player can "Kong" (Quad) the discarded tile.
  static bool canKong(List<int> hand, int discardedTile) {
    int count = hand.where((t) => t == discardedTile).length;
    return count == 3;
  }

  /// Checks if a player can "Eat" (Sequence) the discarded tile.
  /// In Taiwan Mahjong, only the player to the right (next turn) can "Eat".
  static List<List<int>> getEatOptions(List<int> hand, int discardedTile) {
    if (discardedTile >= 40) return []; // Cannot eat Winds, Dragons, or Flowers

    List<List<int>> options = [];
    Set<int> handSet = hand.toSet();

    // Case 1: [tile-2, tile-1, tile]
    if (discardedTile % 10 >= 3 &&
        handSet.contains(discardedTile - 2) &&
        handSet.contains(discardedTile - 1)) {
      options.add([discardedTile - 2, discardedTile - 1]);
    }

    // Case 2: [tile-1, tile, tile+1]
    if (discardedTile % 10 >= 2 &&
        discardedTile % 10 <= 8 &&
        handSet.contains(discardedTile - 1) &&
        handSet.contains(discardedTile + 1)) {
      options.add([discardedTile - 1, discardedTile + 1]);
    }

    // Case 3: [tile, tile+1, tile+2]
    if (discardedTile % 10 <= 7 &&
        handSet.contains(discardedTile + 1) &&
        handSet.contains(discardedTile + 2)) {
      options.add([discardedTile + 1, discardedTile + 2]);
    }

    return options;
  }
}
