# majong_taiwan_core

台灣十六張麻將規則引擎，純 Dart 套件，不依賴 Flutter。

> **此套件為 [mahjong_taiwan](https://github.com/imissmyselfer/mahjong_taiwan) monorepo 的一部分。**

## 功能

- **胡牌判斷** — 驗證手牌是否可胡，並分解出面子 + 眼的結構
- **動作驗證** — 判斷碰 / 槓 / 吃的合法性及所有可吃組合
- **台數計算** — 根據番型與遊戲情境計算總台數

## 使用方式

### 胡牌判斷

```dart
import 'package:majong_taiwan_core/majong_taiwan_core.dart';

// 判斷是否胡牌
final hand = [11, 11, 12, 12, 13, 13, 21, 22, 23, 31, 31, 31, 41, 41, 41, 51, 51];
final melts = <Melt>[];
final result = WinLogic.decompose(hand, melts);
if (result != null) {
  print('胡牌！眼：${result.eye}');
}
```

### 動作驗證

```dart
// 是否可以碰
bool canPong = ActionValidator.canPong(hand, discardedTile);

// 是否可以槓
bool canKong = ActionValidator.canKong(hand, discardedTile);

// 取得所有可吃組合
List<List<int>> eatOptions = ActionValidator.getEatOptions(hand, discardedTile);
```

### 台數計算

```dart
final context = GameContext(
  roundWind: 41,     // 圈風（41=東 43=南 45=西 47=北）
  seatWind: 43,      // 門風
  isDealer: false,
  lianZhuangCount: 0,
  isTsumo: true,
  lastTile: 51,
  isSingleWait: false,
);

final patterns = TaiCalculator.calculate(result, context);
final total = patterns.fold(0, (sum, p) => sum + p.tai);
print('總台數：$total');
for (final p in patterns) {
  print('  ${p.name}：${p.tai} 台');
}
```

## 牌 ID 對照

| 範圍 | 說明 |
|------|------|
| 11–19 | 萬子（1萬–9萬） |
| 21–29 | 餅子（1餅–9餅） |
| 31–39 | 條子（1條–9條） |
| 41, 43, 45, 47 | 東南西北風 |
| 51, 53, 55 | 中發白（三元牌） |
| 61–68 | 花牌（春夏秋冬梅蘭竹菊） |

## 授權

MIT License
