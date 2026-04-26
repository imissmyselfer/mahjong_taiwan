# PROGRESS.md — 麻將台灣 Android

最後更新：2026-04-25（Session 2）

---

## 專案概覽

Flutter 台灣十六張麻將遊戲，1 人 vs 3 AI，跨平台（Android / Web / Linux）。
分為兩個 repo：`majong_taiwan_android`（UI + 遊戲邏輯）與 `majong_taiwan_core`（規則引擎）。

---

## 已完成

- [x] Phase 1：基礎遊戲引擎（牌堆、發牌、出牌、補花）
- [x] Phase 2：AI 對手系統（碰杠吃胡自動決策、隨機出牌）
- [x] Phase 3：UI 優化（新摸牌高亮橘色邊框、棄牌海顯示、深綠暗色主題）
- [x] 吃牌選擇 UI（多選項時顯示 AlertDialog，單選項直接送出）
- [x] README.md 完整文件更新
- [x] 花牌規則（61-68，自動補花）
- [x] 勝負判定 + 番數顯示（呼叫 `majong_taiwan_core`）
- [x] 跨平台支援（Android / Linux / Web）

---

## 目前狀態

**主分支：master**  
最近 commit：`feat: enhance UI to highlight newly drawn tile and provide clearer interaction feedback`

**已知問題：**
- AI 出牌策略為隨機（`botAutoDiscard` 完全隨機），無策略優化
- `_isSingleWait` 永遠回傳 `false`，單牌聽牌番數判定未實作
- `_shuffleAndDeal` 每人發 16 張再補花，可能導致手牌多於正確數量

---

## 下一步 / 待辦

- [ ] Phase 4：進階 AI 出牌策略（保留面子、棄孤立牌）
- [ ] Phase 5：吃牌選擇 UI（玩家選擇哪組順子）
- [ ] Phase 6：單牌聽牌（_isSingleWait）實作
- [ ] 離線模式 / 遊戲統計 / 設定頁面

---

## 架構速查

```
lib/
  main.dart         — Flutter UI、TileWidget、遊戲 loop（1500ms Timer）
  mahjong_game.dart — 遊戲引擎、狀態機（waitingForDiscard/waitingForActions/gameOver）

../majong_taiwan_core/lib/src/
  win_logic.dart        — WinLogic.isWinning / decompose
  action_validator.dart — ActionValidator.canPong / canKong / getEatOptions
  tai_calculator.dart   — TaiCalculator.calculate
  models.dart           — Melt, MeltType, GameContext, TaiPattern
```
