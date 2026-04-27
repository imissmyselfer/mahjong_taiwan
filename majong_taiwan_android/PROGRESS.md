# PROGRESS.md — 麻將台灣 Android

最後更新：2026-04-26（Session 4）

---

## 專案概覽

Flutter 台灣十六張麻將遊戲，1 人 vs 3 AI，跨平台（Android / Web / Linux）。
分為兩個 repo：`majong_taiwan_android`（UI + 遊戲邏輯）與 `majong_taiwan_core`（規則引擎）。

路徑：`/home/erin/Working/code/majong_taiwan_android`

---

## 已完成

- [x] Phase 1：基礎遊戲引擎（牌堆、發牌、出牌、補花）
- [x] Phase 2：AI 對手系統（碰杠吃胡自動決策、隨機出牌）
- [x] Phase 3：UI 優化（新摸牌金色邊框高亮、棄牌海顯示）
- [x] 吃牌選擇 UI（多選項時顯示 AlertDialog，單選項直接送出）
- [x] README.md 完整文件更新
- [x] 花牌規則（61-68，自動補花）
- [x] 勝負判定 + 番數顯示（呼叫 `majong_taiwan_core`）
- [x] 跨平台支援（Android / Linux / Web）
- [x] 暖象牙色 UI 主題（背景 #DCE7E0 / 桌面 #F5F0E8）
- [x] 手牌粗框顯示（可出牌時加粗邊框提示）
- [x] 吃/碰/槓牌組顯示於玩家手牌區
- [x] 槓牌後補嶺上牌
- [x] WIN 判斷邏輯修復（`WinLogic.decompose` 正確觸發）
- [x] 牌圖改回 SVG/PNG 混合渲染
  - 萬/筒/索/字牌/牌背：原有 PNG（FluffyStuff）
  - 花牌（春夏秋冬梅蘭竹菊）：新生成 flower1–8.svg（彩色 SVG）
  - 移除 I.MahjongTW 字型依賴（Inkscape SVG 含 filter/marker，flutter_svg 不支援）

---

## 目前狀態

**主分支：master**
最近 commit：`5674a47 feat: 改回 SVG/PNG 牌圖渲染，花牌改用新 SVG`

**UI 色彩系統：**
- 背景：`#DCE7E0`（雅緻青磁色）
- 牌面：`#FDF8EE`（暖象牙白）
- 桌面區：`#F5F0E8`
- AppBar：`#4A6759`（深草本綠）
- 新摸牌高亮：`#D4AF37`（金色邊框）

**遊戲循環：** 1500ms Timer，AI 自動決策與出牌

**已知問題：**
- `_isSingleWait` 永遠回傳 `false`，單牌聽牌番數判定未實作
- `botAutoDiscard` 完全隨機，無策略優化
- `_shuffleAndDeal` 每人發 16 張再補花，初始手牌張數未嚴格驗證

**Linux 執行環境：**
- 需安裝：`sudo apt-get install libgtk-3-dev clang cmake ninja-build pkg-config`

---

## 下一步 / 待辦

- [ ] Phase 4：進階 AI 出牌策略（保留面子、棄孤立牌）
- [ ] Phase 5：單牌聽牌（`_isSingleWait`）實作
- [ ] Phase 6：蓮莊計數在 UI 顯示
- [ ] Phase 7：離線模式 / 遊戲統計 / 設定頁面
- [ ] README 更新：UI 描述改為暖色調（目前 README 仍寫暗色主題）

---

## 架構速查

```
lib/
  main.dart           — Flutter UI、TileWidget、遊戲 loop（1500ms Timer）
  mahjong_game.dart   — 遊戲引擎、狀態機（waitingForDiscard/waitingForActions/gameOver）

../majong_taiwan_core/lib/src/
  win_logic.dart        — WinLogic.isWinning / decompose
  action_validator.dart — ActionValidator.canPong / canKong / getEatOptions
  tai_calculator.dart   — TaiCalculator.calculate
  models.dart           — Melt, MeltType, GameContext, TaiPattern
```

## 關鍵常數

| 牌 ID 範圍 | 說明 |
|---|---|
| 11–19 | 萬字（Man1–Man9） |
| 21–29 | 餅字（Pin1–Pin9） |
| 31–39 | 條字（Sou1–Sou9） |
| 41, 43, 45, 47 | 東南西北風 |
| 51, 53, 55 | 中發白（三元牌） |
| 61–68 | 花牌（春夏秋冬梅蘭竹菊） |
