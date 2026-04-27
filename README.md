# 台灣十六張麻將 (Mahjong Taiwan)

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Linux-brightgreen)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> 一人對三個 AI，體驗道地台灣十六張麻將。

## 專案結構

這是一個 monorepo，包含兩個套件：

| 目錄 | 說明 |
|------|------|
| `majong_taiwan_android/` | Flutter 遊戲 App（UI、遊戲循環、AI 決策） |
| `majong_taiwan_core/` | 純 Dart 規則引擎（胡牌判斷、台數計算） |

## 功能特色

- 台灣十六張麻將完整規則（碰、槓、吃、胡、自摸）
- 花牌自動補牌（春夏秋冬 / 梅蘭竹菊）
- 三家 AI 自動決策（吃 / 碰 / 槓 / 胡優先級排序）
- 台數計算（清一色、碰碰胡、三元、四喜、花牌等）
- 跨平台支援：Android、Web、Linux

## 快速開始

```bash
# 1. Clone 整個 monorepo
git clone https://github.com/imissmyselfer/mahjong_taiwan.git
cd mahjong_taiwan/majong_taiwan_android

# 2. 安裝依賴
flutter pub get

# 3. 執行
flutter run -d linux     # Linux 桌面
flutter run -d chrome    # Web
flutter run              # Android（需連接裝置或啟動模擬器）
```

### Linux 系統依賴（首次需安裝）

```bash
sudo apt-get install libgtk-3-dev clang cmake ninja-build pkg-config
```

## 架構說明

```
mahjong_taiwan/
├── majong_taiwan_android/
│   ├── lib/
│   │   ├── main.dart           # UI、TileWidget、遊戲畫面
│   │   └── mahjong_game.dart   # 遊戲狀態機、AI 決策
│   └── assets/tiles/           # 牌圖 PNG + 花牌 SVG
└── majong_taiwan_core/
    └── lib/src/
        ├── models.dart          # 資料結構（Melt, WinningHand 等）
        ├── win_logic.dart       # 胡牌判斷
        ├── action_validator.dart# 碰 / 槓 / 吃 合法性
        └── tai_calculator.dart  # 台數計算
```

## 圖片來源

牌圖使用 [FluffyStuff/riichi-mahjong-tiles](https://github.com/FluffyStuff/riichi-mahjong-tiles) 開源圖集（經 [SyaoranHinata/I.Mahjong](https://github.com/SyaoranHinata/I.Mahjong) 取用）。

## 授權

MIT License
