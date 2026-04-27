# majong_taiwan_android

台灣十六張麻將 Flutter App，1 人對 3 個 AI，支援 Android / Web / Linux。

> **此套件為 [mahjong_taiwan](https://github.com/imissmyselfer/mahjong_taiwan) monorepo 的一部分。**  
> 請從頂層目錄 clone，不要單獨 clone 此目錄。

## 快速開始

```bash
git clone https://github.com/imissmyselfer/mahjong_taiwan.git
cd mahjong_taiwan/majong_taiwan_android
flutter pub get
flutter run -d linux   # 或 -d chrome、android
```

### Linux 系統依賴

```bash
sudo apt-get install libgtk-3-dev clang cmake ninja-build pkg-config
```

## 遊戲規則

### 基本動作（優先級由高到低）

| 動作 | 說明 |
|------|------|
| 胡 / 自摸 | 湊齊面子 + 眼，放槍胡或摸牌胡 |
| 碰 | 手中有對，加上他家棄牌組成刻子 |
| 槓 | 手中三張加棄牌，或手中四張自槓（槓後補牌） |
| 吃 | 下家才能吃，用兩張搭配棄牌組成順子 |
| 過 | 放棄所有動作 |

### 花牌

61–68 為花牌（春夏秋冬梅蘭竹菊），摸到自動補牌，每張加 1 台。

### 台數計算

| 番種 | 台數 |
|------|------|
| 自摸 | 1 |
| 門清 | 1（門清自摸 3） |
| 碰碰胡 | 4 |
| 平胡 | 2 |
| 混一色 | 4 |
| 清一色 | 8 |
| 字一色 | 16 |
| 小三元 | 4 |
| 大三元 | 8 |
| 小四喜 | 8 |
| 大四喜 | 16 |
| 紅中 / 青發 / 白板 | 各 1 |
| 圈風 / 門風 | 各 1 |
| 花牌 | 每張 1 |

## 專案結構

```
lib/
  main.dart          — UI 主畫面、TileWidget、遊戲畫面
  mahjong_game.dart  — 遊戲狀態機、AI 決策邏輯

assets/tiles/        — 牌圖（PNG + 花牌 SVG）
```

## 依賴

- [flutter_svg](https://pub.dev/packages/flutter_svg) — SVG 花牌渲染
- [google_fonts](https://pub.dev/packages/google_fonts) — Noto Serif TC 字體
- `majong_taiwan_core` — 本 monorepo 內的規則引擎（`path: ../majong_taiwan_core`）

## 已知限制

- `_isSingleWait`（獨聽判斷）尚未實作，永遠回傳 `false`
- AI 出牌策略為隨機，無策略優化

## 授權

MIT License
