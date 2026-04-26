# 🀄 麻將台灣 Android (Mahjong Taiwan Android)

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Linux-brightgreen)](https://flutter.dev/docs/deployment)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **「一人對三個 AI，體驗道地台灣麻將。快速、聰慧、容易上手。」**

**麻將台灣 Android** 是一個用 Flutter 打造的全功能麻將遊戲應用，採用台灣麻將規則，內建強大的 AI 對手系統。無論你是麻將新手還是高手，都能在這裡找到挑戰。

🌐 **支援平台：** Android | Web | Linux

---

## ✨ 核心特色

### 🎮 完整的麻將玩法
- **4 人麻將局** — 東、南、西、北四個位置，模擬真實遊戲氛圍
- **標準台灣規則** — 支援碰、杠、吃、胡、自摸等所有基礎動作
- **花牌系統** — 實現春、夏、秋、冬與梅、蘭、竹、菊花牌規則
- **番數計算** — 精確的得分系統，支援台灣麻將的各種翻倍規則
- **蓮莊機制** — 莊家連贏時自動計算蓮莊次數

### 🤖 智慧 AI 對手
- **優先級決策系統** — 根據自摸 / 胡 > 碰 / 杠 > 吃的優先級智慧決策
- **動態出牌策略** — AI 能夠根據牌局狀況自動出牌，無需人工介入
- **實時手牌管理** — 自動識別並優化手牌組合

### 🎨 優化的用戶界面
- **暖象牙色主題** — 牌面 #FDF8EE、桌面 #F5F0E8，舒適自然的視覺風格
- **即時手牌反饋** — 新摸牌金色邊框高亮，可出牌時加粗灰框提示
- **互動式牌池展示** — 實時顯示所有棄牌（海），便於分析
- **吃牌選擇 Dialog** — 多種吃法時彈出選牌介面，操作清晰
- **跨平台響應式設計** — 在 Android、Web、Linux 上保持一致體驗

### 📱 跨平台支援
- **Android** — 原生 APK 編譯，直接在手機運行
- **Web** — 瀏覽器即玩，無需下載安裝
- **Linux** — 桌面應用，完整功能體驗

---

## 🛠️ 技術棧

| 層級 | 技術 | 說明 |
|------|------|------|
| **框架** | Flutter 3.11+ | 跨平台 UI 框架 |
| **語言** | Dart 3.11+ | Flutter 主要開發語言 |
| **核心邏輯** | majong_taiwan_core | 獨立的麻將規則引擎 |
| **遊戲架構** | Custom Game Loop | 1500ms 刷新率的遊戲循環 |
| **UI 設計** | Material Design | Material 3 設計語言 |
| **狀態管理** | setState() | 簡化的狀態管理 |

### 技術 Tag
`#Flutter` `#Dart` `#Mahjong` `#GameDevelopment` `#AI` `#CrossPlatform` `#Android` `#Web` `#Linux`

---

## 🚀 快速開始

### 前置條件
- **Flutter SDK** 3.11.4 或更高版本
- **Dart SDK** 3.11.4 或更高版本（包含在 Flutter 中）
- **Android Studio** 或 **VS Code**（選擇其一）
- **Git**

### 1. 克隆專案
```bash
git clone https://github.com/yourusername/majong_taiwan_android.git
cd majong_taiwan_android
```

### 2. 安裝依賴
```bash
# 取得所有依賴（包含 majong_taiwan_core）
flutter pub get

# 確保 majong_taiwan_core 已正確連結
# （應自動從 pubspec.yaml 中的 path: ../majong_taiwan_core 載入）
```

### 3. 檢查環境
```bash
flutter doctor
```

確保所有必需項目都被勾選 ✓。

### 4. 運行應用

#### 🤖 Android
```bash
# 確保 Android 設備已連接或模擬器運行
flutter run

# 或編譯 APK
flutter build apk --release
# APK 位置：build/app/outputs/flutter-app.apk
```

#### 🌐 Web
```bash
flutter run -d chrome

# 或編譯 Web 版本
flutter build web --release
# 部署 build/web/ 目錄到任何靜態服務器
```

#### 🖥️ Linux
```bash
# 先安裝系統依賴（Ubuntu / Debian）
sudo apt-get install libgtk-3-dev clang cmake ninja-build pkg-config

flutter run -d linux

# 或編譯可執行檔
flutter build linux --release
# 可執行檔位置：build/linux/x64/release/bundle/
```

---

## 📂 專案結構

```
majong_taiwan_android/
├── lib/
│   ├── main.dart                 # 應用入口、主題設定、遊戲屏幕
│   └── mahjong_game.dart         # 遊戲邏輯、AI 決策、狀態管理
├── pubspec.yaml                  # Flutter 項目配置、依賴聲明
├── pubspec.lock                  # 依賴版本鎖定
├── analysis_options.yaml         # Dart 分析選項
├── android/                      # Android 特定配置
├── ios/                          # iOS 特定配置（未啟用）
├── web/                          # Web 特定配置
├── linux/                        # Linux 特定配置
└── test/                         # 單元測試目錄
```

### 核心文件說明

#### **lib/main.dart**
- `MahjongApp` — 應用根組件，配置暖象牙色主題
- `MahjongScreen` — 遊戲主屏幕，處理 UI 渲染和玩家交互
- `_processGameLoop()` — 1500ms 定時遊戲循環，驅動 AI 自動操作
- `TileWidget` — 牌面 Widget，使用 PNG 圖檔 + 花牌漢字渲染
- `_tileAssetPath()` — 牌 ID 轉 assets/tiles/ 路徑

#### **lib/mahjong_game.dart**
- `MahjongGame` — 核心遊戲引擎，管理：
  - 牌堆初始化與洗牌發牌
  - 玩家手牌、碰杠、棄牌狀態
  - 遊戲狀態轉換（待出牌 → 待操作 → 遊戲結束）
  - 勝負判定與番數計算
- `MahjongAction` — 玩家動作（碰、杠、吃、胡、自摸、過）
- `GameState` 枚舉 — 三個遊戲狀態的定義
- `PlayerPosition` 枚舉 — 四個位置定義（東、南、西、北）

---

## 🎮 遊戲規則速覽

### 基礎動作（按優先級排序）
1. **胡 (WIN)** — 集齊一對眼和多個面子（順 / 刻）
2. **自摸 (TSUMO)** — 從牌堆抽取最後一張成胡
3. **碰 (PONG)** — 用手中的一對與棄牌組成刻子
4. **杠 (KONG)** — 用手中三張與棄牌組成杠子，或手中四張自杠
5. **吃 (EAT)** — 用手中兩張與棄牌組成順子（需為莊家下家）

### 花牌規則
- **春、夏、秋、冬** (61-64) 與 **梅、蘭、竹、菊** (65-68) — 自動補花，每張加 1 番
- 抽到花牌時，玩家自動補牌，并立即顯示

### 番數系統
- 遊戲支援台灣麻將的番數計算（藏在 `majong_taiwan_core` 中）
- 勝負時會計算贏家的總番數 `totalTai`

---

## 🔄 遊戲流程

```
1. 遊戲初始化
   └─ 初始化牌堆（136 張牌：108 數牌 + 16 字牌 + 12 三元 / 含 8 張花牌）
   └─ 洗牌並發牌（每人 16 張，自動補花後東家額外摸 1 張）

2. 主遊戲循環（每 1500ms 執行一次）
   ├─ 自動處理所有待定動作（碰、杠、吃）
   ├─ 如果輪到 AI，AI 自動出牌
   └─ 更新遊戲狀態

3. 玩家操作
   ├─ 點擊牌匹進行交互（點擊棄牌堆中的牌可碰 / 吃）
   └─ 系統根據合法性判定是否允許

4. 遊戲結束
   ├─ 某人胡牌或自摸
   └─ 計算番數，顯示結果

5. 重新開始
   └─ 重置遊戲狀態，開始新局
```

---

## 🐛 故障排查

### 問題：`majong_taiwan_core` 找不到
```bash
# 解決方案：檢查 pubspec.yaml 中的路徑是否正確
# majong_taiwan_core 應該在上一級目錄 (../majong_taiwan_core)

flutter pub get
flutter pub upgrade
```

### 問題：Android 編譯失敗
```bash
# 檢查 Android 環境設定
flutter doctor -v

# 同步 Gradle
cd android
./gradlew clean
cd ..

flutter clean
flutter pub get
flutter run
```

### 問題：Web 版本運行緩慢
```bash
# 編譯優化版本
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true
```

### 問題：遊戲卡在某個狀態
- 檢查 `_processGameLoop()` 中的邏輯是否有無限迴圈
- 確認 AI 決策函數能正確返回結果
- 查看控制台日誌（`print()` 語句）

---

## 📝 開發指南

### 添加新功能

#### 步驟 1：在 `majong_taiwan_core` 中實現規則
所有遊戲規則邏輯都應該在 `majong_taiwan_core` 中，保持 UI 層與規則層的分離。

#### 步驟 2：在 `main.dart` 中添加 UI
```dart
// 範例：添加新的按鈕
ElevatedButton(
  onPressed: () {
    setState(() {
      _game.someNewLogic();
    });
  },
  child: const Text('新功能'),
),
```

#### 步驟 3：更新遊戲循環
如果新功能需要在每幀執行，在 `_processGameLoop()` 中添加邏輯。

### 執行測試
```bash
flutter test
```

### 代碼分析
```bash
flutter analyze
```

---

## 🔐 隱私與安全

- ✓ 離線運行，不收集任何用戶數據
- ✓ 開源代碼，完全透明
- ✓ 無廣告、無追蹤

---

## 📄 許可證

本專案採用 **MIT 許可證**。詳見 [LICENSE](LICENSE) 文件。

---

## 🤝 貢獻指南

歡迎提交 Issue 和 Pull Request！

### 流程
1. Fork 本倉庫
2. 創建功能分支（`git checkout -b feature/AmazingFeature`）
3. 提交更改（`git commit -m 'Add some AmazingFeature'`）
4. 推送至分支（`git push origin feature/AmazingFeature`）
5. 打開 Pull Request

### 代碼風格
- 使用 Dart 官方的代碼風格指南
- 運行 `dart format` 格式化代碼
- 確保通過 `flutter analyze`

---

## 📞 聯絡與支援

- 📧 Email：（如有聯絡方式）
- 🐛 Bug 報告：GitHub Issues
- 💬 功能請求：GitHub Discussions

---

## 🎯 開發路線圖

- [x] Phase 1：基礎遊戲引擎
- [x] Phase 2：AI 對手系統
- [x] Phase 3：UI 優化與花牌規則
- [ ] Phase 4：多人遊戲聯網模式
- [ ] Phase 5：遊戲錄像與回放功能
- [ ] Phase 6：國際化（英文、日文等）

---

## 🙏 致謝

感謝所有貢獻者和使用者的支持！

特別感謝 **majong_taiwan_core** 團隊提供的強大規則引擎。

---

## 🤝 貢獻指南

歡迎貢獻代碼、報告 bug、提出功能需求！

### 貢獻流程
1. Fork 本倉庫
2. 創建功能分支（`git checkout -b feature/AddGameMode`）
3. 提交更改（`git commit -m 'feat: Add tournament mode'`）
4. 推送至分支（`git push origin feature/AddGameMode`）
5. 打開 Pull Request

### 代碼風格
- Dart 3.11+
- Flutter Lints
- 運行 `flutter analyze`
- 為新功能添加測試

---

## 🎯 開發路線圖

### Phase 1：核心功能 ✅ 完成
- [x] 4 人麻將
- [x] AI 對手
- [x] UI 優化
- [x] 花牌系統

### Phase 2：進階功能 🟡 進行中
- [ ] 離線模式
- [ ] 遊戲統計
- [ ] 設置選項

### Phase 3：多人遊戲 📅 計畫中
- [ ] 網絡對戰
- [ ] 排行榜
- [ ] 房間系統

### Phase 4：社交功能 📅 計畫中
- [ ] 遊戲分享
- [ ] 錄像回放
- [ ] 成就系統

---

*Made with ❤️ for Mahjong lovers worldwide.*
