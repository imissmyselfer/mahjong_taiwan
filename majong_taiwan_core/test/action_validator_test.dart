import 'package:majong_taiwan_core/src/action_validator.dart';
import 'package:test/test.dart';

void main() {
  group('canPong', () {
    test('手上 2 張同牌時可碰', () {
      expect(ActionValidator.canPong([11, 11, 22, 33], 11), isTrue);
    });

    test('手上 3 張同牌時可碰', () {
      expect(ActionValidator.canPong([11, 11, 11, 22], 11), isTrue);
    });

    test('手上 1 張同牌時不可碰', () {
      expect(ActionValidator.canPong([11, 22, 33], 11), isFalse);
    });

    test('手上 0 張同牌時不可碰', () {
      expect(ActionValidator.canPong([22, 33, 44], 11), isFalse);
    });
  });

  group('canKong', () {
    test('手上恰好 3 張時可槓', () {
      expect(ActionValidator.canKong([11, 11, 11, 22], 11), isTrue);
    });

    test('手上只有 2 張時不可槓', () {
      expect(ActionValidator.canKong([11, 11, 22, 33], 11), isFalse);
    });

    test('手上 4 張時不算「碰人棄牌槓」', () {
      // 手上 4 張代表暗槓情境，不在 canKong（吃別人棄牌） 的範圍
      expect(ActionValidator.canKong([11, 11, 11, 11], 11), isFalse);
    });
  });

  group('getEatOptions', () {
    test('字牌（風牌）不能吃', () {
      expect(ActionValidator.getEatOptions([41, 41, 43, 45], 41), isEmpty);
    });

    test('三元牌不能吃', () {
      expect(ActionValidator.getEatOptions([51, 51, 53, 55], 51), isEmpty);
    });

    test('花牌不能吃', () {
      expect(ActionValidator.getEatOptions([61, 62, 63], 61), isEmpty);
    });

    test('棄 14 萬手上 12 13 15 16 → 三種吃法', () {
      final options = ActionValidator.getEatOptions([12, 13, 15, 16], 14);
      expect(options, containsAll([
        equals([12, 13]),
        equals([13, 15]),
        equals([15, 16]),
      ]));
      expect(options.length, 3);
    });

    test('邊張：棄 1 萬時只能 [2萬,3萬]', () {
      final options = ActionValidator.getEatOptions([12, 13, 14], 11);
      expect(options, [
        [12, 13]
      ]);
    });

    test('邊張：棄 9 萬時只能 [7萬,8萬]', () {
      final options = ActionValidator.getEatOptions([17, 18, 19], 19);
      expect(options, [
        [17, 18]
      ]);
    });

    test('嵌張：棄 5 萬，手上有 4萬 6萬', () {
      final options = ActionValidator.getEatOptions([14, 16], 15);
      expect(options, [
        [14, 16]
      ]);
    });

    test('不同花色不能組順子', () {
      // 棄 5 萬（15），手上是 4餅 6餅（24, 26）→ 不能吃
      expect(ActionValidator.getEatOptions([24, 26], 15), isEmpty);
    });

    test('餅牌也適用同樣規則', () {
      final options = ActionValidator.getEatOptions([22, 23, 25, 26], 24);
      expect(options.length, 3);
    });
  });
}
