# 台灣十六張麻將 (Mahjong Taiwan)

Flutter 打造的台灣麻將遊戲，1 人對 3 個 AI，支援 Android / Web / Linux。

## 專案結構

```
mahjong_taiwan/
├── majong_taiwan_android/   # Flutter UI 與遊戲邏輯
└── majong_taiwan_core/      # 麻將規則引擎（Dart package）
```

## 快速開始

```bash
git clone https://github.com/<your-username>/mahjong_taiwan.git
cd mahjong_taiwan/majong_taiwan_android
flutter pub get
flutter run -d linux   # 或 -d chrome / android
```

## 功能

- 台灣十六張麻將規則（碰、槓、吃、胡、自摸）
- 花牌自動補牌（春夏秋冬梅蘭竹菊）
- 台數計算（清一色、碰碰胡、三元、四喜等）
- 三家 AI 自動決策
- 跨平台：Android、Web、Linux

## 平台需求

| 平台 | 需求 |
|------|------|
| Linux | `sudo apt-get install libgtk-3-dev clang cmake ninja-build pkg-config` |
| Android | Android Studio + SDK |
| Web | Chrome |
