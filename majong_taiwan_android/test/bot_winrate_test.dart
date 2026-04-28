import 'package:flutter_test/flutter_test.dart';
import 'package:majong_taiwan_android/mahjong_game.dart';

// 模擬一整局：east 也讓 BOT 邏輯出牌（不需要 UI）
// 統計 N 局內各家勝率
void main() {
  for (final level in BotDifficulty.values) {
    test('1000 局 BOT 自動對戰 — 難度 ${level.name}', () {
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
      final game = MahjongGame(difficulty: level);
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
          // east 用隨機出牌模擬「中等玩家」，方便比較三檔難度的 BOT 勝率
          if (game.currentTurn == PlayerPosition.east) {
            final hand = game.players[PlayerPosition.east]!.hand;
            if (hand.isNotEmpty) {
              game.discard(PlayerPosition.east, hand[hand.length ~/ 2]);
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

    print('=== 統計（${level.name}） ===');
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
}
