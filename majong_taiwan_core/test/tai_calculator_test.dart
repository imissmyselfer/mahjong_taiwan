import 'package:majong_taiwan_core/src/models.dart';
import 'package:majong_taiwan_core/src/tai_calculator.dart';
import 'package:test/test.dart';

// Helper：建立常見 melt
Melt seq(int start, {bool exposed = false}) =>
    Melt(tiles: [start, start + 1, start + 2], type: MeltType.sequence, isExposed: exposed);
Melt pung(int tile, {bool exposed = false}) =>
    Melt(tiles: [tile, tile, tile], type: MeltType.triplet, isExposed: exposed);
Melt kong(int tile, {bool exposed = false}) =>
    Melt(tiles: [tile, tile, tile, tile], type: MeltType.kong, isExposed: exposed);

GameContext ctx({
  int roundWind = 41,
  int seatWind = 41,
  bool isDealer = false,
  bool isTsumo = false,
  bool isSingleWait = false,
  int lianZhuangCount = 0,
}) =>
    GameContext(
      roundWind: roundWind,
      seatWind: seatWind,
      isDealer: isDealer,
      isTsumo: isTsumo,
      isSingleWait: isSingleWait,
      lianZhuangCount: lianZhuangCount,
    );

Set<String> names(List<TaiPattern> patterns) => patterns.map((p) => p.name).toSet();
int totalTai(List<TaiPattern> patterns) => patterns.fold(0, (s, p) => s + p.tai);

void main() {
  group('Basic / Contextual', () {
    test('莊家 +1 台', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx(isDealer: true));
      expect(names(patterns), contains('莊家'));
    });

    test('閒家自摸（有吃碰槓）只算自摸 1 台', () {
      // 有吃碰槓才不會升級為「門清一摸三」
      final hand = WinningHand(eye: 22, melts: [
        seq(11, exposed: true), seq(12), seq(13), seq(14), seq(15)
      ]);
      final patterns = TaiCalculator.calculate(hand, ctx(isTsumo: true));
      expect(names(patterns), contains('自摸'));
      expect(names(patterns), isNot(contains('門清一摸三')));
    });

    test('門清（完全未吃碰槓）+1 台', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('門清'));
    });

    test('門清自摸 → 門清一摸三 取代 自摸', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx(isTsumo: true));
      expect(names(patterns), contains('門清一摸三'));
      expect(names(patterns), isNot(contains('自摸')));
    });

    test('有吃碰槓的自摸只算自摸，不算門清', () {
      final hand = WinningHand(eye: 22, melts: [
        seq(11, exposed: true), seq(12), seq(13), seq(14), seq(15)
      ]);
      final patterns = TaiCalculator.calculate(hand, ctx(isTsumo: true));
      expect(names(patterns), contains('自摸'));
      expect(names(patterns), isNot(contains('門清')));
      expect(names(patterns), isNot(contains('門清一摸三')));
    });
  });

  group('Honor Tiles (字牌)', () {
    test('紅中刻子 +1 台', () {
      final hand = WinningHand(eye: 22, melts: [pung(51), seq(11), seq(12), seq(13), seq(14)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('紅中'));
    });

    test('圈風（東圈打東風刻）+1 台', () {
      final hand = WinningHand(eye: 22, melts: [pung(41), seq(11), seq(12), seq(13), seq(14)]);
      final patterns = TaiCalculator.calculate(hand, ctx(roundWind: 41, seatWind: 43));
      expect(names(patterns), contains('圈風'));
      expect(names(patterns), isNot(contains('門風')));
    });

    test('莊家自己的東風（圈=門）兩台都算', () {
      final hand = WinningHand(eye: 22, melts: [pung(41), seq(11), seq(12), seq(13), seq(14)]);
      final patterns = TaiCalculator.calculate(hand, ctx(roundWind: 41, seatWind: 41));
      expect(names(patterns), contains('圈風'));
      expect(names(patterns), contains('門風'));
    });
  });

  group('三元（Dragon Patterns）', () {
    test('小三元（中發刻 + 白板對子）= 4 台，但不重複算紅中青發', () {
      final hand = WinningHand(eye: 55, melts: [pung(51), pung(53), seq(11), seq(12), seq(13)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('小三元'));
      expect(names(patterns), isNot(contains('紅中')));
      expect(names(patterns), isNot(contains('青發')));
    });

    test('大三元 = 8 台，三隻三元牌不單獨算', () {
      final hand = WinningHand(eye: 22, melts: [pung(51), pung(53), pung(55), seq(11), seq(12)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('大三元'));
      expect(names(patterns), isNot(contains('紅中')));
      expect(names(patterns), isNot(contains('青發')));
      expect(names(patterns), isNot(contains('白板')));
    });
  });

  group('四喜（Wind Patterns）', () {
    test('小四喜：3 風刻 + 1 風對子', () {
      final hand = WinningHand(eye: 47, melts: [pung(41), pung(43), pung(45), seq(11), seq(12)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('小四喜'));
    });

    test('大四喜：4 風刻', () {
      final hand = WinningHand(eye: 22, melts: [pung(41), pung(43), pung(45), pung(47), seq(11)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('大四喜'));
    });
  });

  group('Hand Structure', () {
    test('碰碰胡（全部刻子或槓）', () {
      final hand = WinningHand(eye: 22, melts: [pung(11), pung(13), pung(15), pung(17), pung(19)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('碰碰胡'));
    });

    test('平胡（全順子、無字、非自摸、非單聽、無花）', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('平胡'));
    });

    test('平胡：有字牌就不算平胡', () {
      final hand = WinningHand(eye: 51, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), isNot(contains('平胡')));
    });

    test('平胡：自摸不算平胡', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx(isTsumo: true));
      expect(names(patterns), isNot(contains('平胡')));
    });
  });

  group('Suit Patterns（一色）', () {
    test('清一色（單一花色，無字）', () {
      final hand = WinningHand(eye: 19, melts: [seq(11), seq(12), seq(13), seq(14), pung(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('清一色'));
      expect(names(patterns), isNot(contains('混一色')));
    });

    test('混一色（單一花色 + 字）', () {
      final hand = WinningHand(eye: 51, melts: [seq(11), seq(12), seq(13), seq(14), pung(53)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('混一色'));
      expect(names(patterns), isNot(contains('清一色')));
    });

    test('字一色（全字牌）', () {
      final hand = WinningHand(eye: 51, melts: [pung(41), pung(43), pung(45), pung(47), pung(53)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), contains('字一色'));
    });

    test('混合花色不算一色', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(31), seq(32), pung(33)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(names(patterns), isNot(contains('清一色')));
      expect(names(patterns), isNot(contains('混一色')));
      expect(names(patterns), isNot(contains('字一色')));
    });
  });

  group('Special Conditions', () {
    test('獨聽 +1 台', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx(isSingleWait: true));
      expect(names(patterns), contains('獨聽'));
    });

    test('花牌每張 +1 台', () {
      final hand = WinningHand(
        eye: 22,
        melts: [seq(11), seq(12), seq(13), seq(14), seq(15)],
        flowers: [61, 62, 63],
      );
      final patterns = TaiCalculator.calculate(hand, ctx());
      final flowerPattern = patterns.firstWhere((p) => p.name.startsWith('花牌'));
      expect(flowerPattern.tai, 3);
    });

    test('無花牌不加台', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx());
      expect(patterns.where((p) => p.name.startsWith('花牌')), isEmpty);
    });
  });

  group('組合情境', () {
    test('莊家門清自摸：莊家 1 + 門清一摸三 3 = 4 台', () {
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx(isDealer: true, isTsumo: true));
      expect(totalTai(patterns), 4);
    });

    test('連 2 拉 2：莊家 1 + 門清 1 + 連 4 + 平胡 2 = 8 台', () {
      // 全順子無字、未吃碰槓、非自摸 → 同時觸發 平胡 + 門清
      final hand = WinningHand(eye: 22, melts: [seq(11), seq(12), seq(13), seq(14), seq(15)]);
      final patterns = TaiCalculator.calculate(hand, ctx(isDealer: true, lianZhuangCount: 2));
      expect(names(patterns), containsAll(['莊家', '連2拉2', '門清', '平胡']));
      expect(totalTai(patterns), 8);
    });
  });
}
