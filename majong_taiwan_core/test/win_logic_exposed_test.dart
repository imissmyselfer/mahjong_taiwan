import 'package:majong_taiwan_core/src/models.dart';
import 'package:majong_taiwan_core/src/win_logic.dart';
import 'package:test/test.dart';

void main() {
  group('WinLogic with exposed melts', () {
    test('1 副露碰：手 14 張可胡', () {
      // 副露：碰 11
      // 手：22,23,24 + 33,33,33 + 41,41,41 + 51,51,51 + 19,19 = 14 張
      final concealed = [22, 23, 24, 33, 33, 33, 41, 41, 41, 51, 51, 51, 19, 19];
      final melts = [
        Melt(tiles: [11, 11, 11], type: MeltType.triplet, isExposed: true),
      ];
      expect(WinLogic.decompose(concealed, melts), isNotNull);
    });

    test('2 副露碰：手 11 張可胡', () {
      final concealed = [33, 34, 35, 41, 41, 41, 53, 53, 53, 19, 19];
      final melts = [
        Melt(tiles: [11, 11, 11], type: MeltType.triplet, isExposed: true),
        Melt(tiles: [22, 22, 22], type: MeltType.triplet, isExposed: true),
      ];
      expect(WinLogic.decompose(concealed, melts), isNotNull);
    });

    test('1 暗槓：手 13 張 + 1 槓（4 張）= 17 張可胡', () {
      // 副露：暗槓 11
      // 手：22,23,24 + 33,33,33 + 41,41,41 + 51,51,51 + 19,19 = 14 張？
      // 注意：槓佔 4 張但算 1 個面子，所以 concealed 應該還是 14 張（因為槓後補嶺上牌）
      final concealed = [22, 23, 24, 33, 33, 33, 41, 41, 41, 51, 51, 51, 19, 19];
      final melts = [
        Melt(tiles: [11, 11, 11, 11], type: MeltType.kong, isExposed: false),
      ];
      expect(WinLogic.decompose(concealed, melts), isNotNull);
    });

    test('1 副露吃：手 14 張可胡', () {
      // 副露：吃 12,13,14
      final concealed = [22, 23, 24, 33, 33, 33, 41, 41, 41, 51, 51, 51, 19, 19];
      final melts = [
        Melt(tiles: [12, 13, 14], type: MeltType.sequence, isExposed: true),
      ];
      expect(WinLogic.decompose(concealed, melts), isNotNull);
    });

    test('全副露 5 melts：手只剩 2 張對子', () {
      final concealed = [19, 19];
      final melts = [
        Melt(tiles: [11, 12, 13], type: MeltType.sequence, isExposed: true),
        Melt(tiles: [22, 22, 22], type: MeltType.triplet, isExposed: true),
        Melt(tiles: [33, 34, 35], type: MeltType.sequence, isExposed: true),
        Melt(tiles: [41, 41, 41], type: MeltType.triplet, isExposed: true),
        Melt(tiles: [51, 51, 51], type: MeltType.triplet, isExposed: true),
      ];
      expect(WinLogic.decompose(concealed, melts), isNotNull);
    });

    test('副露但手牌結構錯誤應失敗', () {
      // 副露 1 碰，手 14 張，但含一張無法成面子的孤立牌
      final concealed = [22, 23, 24, 33, 33, 33, 41, 41, 41, 51, 51, 52, 19, 19];
      final melts = [
        Melt(tiles: [11, 11, 11], type: MeltType.triplet, isExposed: true),
      ];
      expect(WinLogic.decompose(concealed, melts), isNull);
    });

    test('isWinning（純 17 張）對副露玩家會誤判', () {
      // 提醒：isWinning 不接受 melts，副露玩家手 < 17 張會直接失敗
      // 這是已知設計限制，列為文件性 test
      final concealed14 = [22, 23, 24, 33, 33, 33, 41, 41, 41, 51, 51, 51, 19, 19];
      expect(WinLogic.isWinning(concealed14), isFalse);
    });
  });
}
