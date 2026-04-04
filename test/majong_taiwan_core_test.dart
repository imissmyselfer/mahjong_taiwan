import 'package:majong_taiwan_core/src/win_logic.dart';
import 'package:test/test.dart';

void main() {
  group('WinLogic Test', () {
    test('Verify Basic Winning Hand (Wan, Pin, Tiao)', () {
      // 5 Melts: 11,11,11 (Wan Triplet), 22,23,24 (Pin Sequence), 33,34,35 (Tiao Sequence), 41,41,41 (Wind Triplet), 51,51,51 (Dragon Triplet)
      // 1 Eye: 19,19 (Wan Pair)
      final hand = [
        11, 11, 11, 
        22, 23, 24, 
        33, 34, 35, 
        41, 41, 41, 
        51, 51, 51, 
        19, 19
      ];
      expect(WinLogic.isWinning(hand), isTrue);
    });

    test('Verify Invalid Hand (Missing one tile)', () {
      final hand = [
        11, 11, 11, 
        22, 23, 24, 
        33, 34, 35, 
        41, 41, 41, 
        51, 51, 51, 
        19
      ];
      expect(WinLogic.isWinning(hand), isFalse);
    });

    test('Verify Seven Pairs (Common in Mahjong but not 16-card)', () {
      // Seven pairs is usually for 13-card mahjong. 
      // In 16-card mahjong, 8 pairs might be a thing in some variants, 
      // but standard is 5x3+2 = 17. 
      // Let's test a simple failing hand.
      final hand = [11, 11, 12, 12, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19];
      expect(WinLogic.isWinning(hand), isFalse);
    });
  });
}
