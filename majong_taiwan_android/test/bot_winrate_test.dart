import 'package:flutter_test/flutter_test.dart';
import 'package:majong_taiwan_android/mahjong_game.dart';

// 模擬一整局：east 也讓 BOT 邏輯出牌（不需要 UI）
// 統計 N 局內各家勝率
void main() {
  test('1000 局 BOT 自動對戰 — 看誰會胡', () {
    final stats = <PlayerPosition, int>{
      PlayerPosition.east: 0,
      PlayerPosition.south: 0,
      PlayerPosition.west: 0,
      PlayerPosition.north: 0,
    };
    int draws = 0;

    const totalGames = 1000;
    const maxTicksPerGame = 1000; // 防無窮迴圈

    for (var i = 0; i < totalGames; i++) {
      final game = MahjongGame();
      var ticks = 0;
      while (game.state != GameState.gameOver && ticks < maxTicksPerGame) {
        ticks++;
        // 跳過動作標籤計時（測試不需要 UX 延遲）
        if (game.state == GameState.waitingForActions) {
          // east 也走 BOT 邏輯（autoProcessActions 只處理 isBot，east 要手動）
          if (game.possibleActions.containsKey(PlayerPosition.east)) {
            final actions = game.possibleActions[PlayerPosition.east]!;
            String decision = 'PASS';
            if (actions.contains('WIN')) decision = 'WIN';
            else if (actions.contains('TSUMO')) decision = 'TSUMO';
            else if (actions.contains('KONG')) decision = 'KONG';
            else if (actions.contains('PONG')) decision = 'PONG';
            else if (actions.contains('EAT')) decision = 'EAT';
            game.submitDecision(PlayerPosition.east, decision);
          }
          game.autoProcessActions();
        } else if (game.state == GameState.waitingForDiscard) {
          // 為了公平比較：暫時把 east 也當 BOT 出牌
          // （透過 botAutoDiscard 的 isBot 限制，所以這邊不能直接呼叫）
          if (game.currentTurn == PlayerPosition.east) {
            final hand = game.players[PlayerPosition.east]!.hand;
            if (hand.isNotEmpty) {
              // 用相同的孤立牌啟發法（複製 _pickDiscardTile 邏輯）
              final counts = <int, int>{};
              for (var t in hand) counts[t] = (counts[t] ?? 0) + 1;
              int scoreOf(int t) {
                final c = counts[t]!;
                if (c >= 3) return 100;
                if (c == 2) return 50;
                if (t >= 40) return 1;
                int s = 5;
                if ((counts[t - 2] ?? 0) > 0) s += 2;
                if ((counts[t - 1] ?? 0) > 0) s += 4;
                if ((counts[t + 1] ?? 0) > 0) s += 4;
                if ((counts[t + 2] ?? 0) > 0) s += 2;
                return s;
              }
              int best = hand.first;
              int bestScore = 1 << 30;
              for (final t in hand) {
                final s = scoreOf(t);
                if (s < bestScore) { bestScore = s; best = t; }
              }
              game.discard(PlayerPosition.east, best);
            }
          } else {
            game.botAutoDiscard();
          }
        }
      }

      if (game.winner != null) {
        stats[game.winner!] = stats[game.winner!]! + 1;
      } else {
        draws++;
      }
    }

    print('=== 統計 ===');
    print('east  : ${stats[PlayerPosition.east]}');
    print('south : ${stats[PlayerPosition.south]}');
    print('west  : ${stats[PlayerPosition.west]}');
    print('north : ${stats[PlayerPosition.north]}');
    print('流局  : $draws');

    final totalWins = stats.values.fold(0, (s, n) => s + n);
    expect(totalWins + draws, totalGames);
    // 至少要有 BOT（south/west/north 任一）胡過
    final botWins = stats[PlayerPosition.south]! +
        stats[PlayerPosition.west]! +
        stats[PlayerPosition.north]!;
    expect(botWins, greaterThan(0), reason: 'BOT 從未獲勝 — 引擎或 BOT 邏輯有 bug');
  });
}
