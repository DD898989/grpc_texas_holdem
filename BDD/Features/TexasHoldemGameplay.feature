# language: zh-TW
功能: 德州撲克遊戲流程與資料庫下注紀錄驗證

  場景: 兩位玩家建立房間並進行下注對賭與牌面作弊控制
    假設 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD測試房" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD測試房" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAsKdKhAdAh2c"
    並且 遊戲開始進入第一回合發牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                                                | Note                    |
      | status         | PRE_FLOP                                                                                             | 翻牌前狀態              |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAs       | 扣除手牌與燒牌後剩餘牌堆|
      | flop           |                                                                                                      | 尚未發翻牌              |
      | turn           |                                                                                                      | 尚未發轉牌              |
      | river          |                                                                                                      | 尚未發河牌              |
      | game           | <GameId>                                                                                             | 當前遊戲 ID             |
      | action         | Alice                                                                                                | 輪到 Alice              |
      | winning_player | 0                                                                                                    | 尚未結算                |
      | winning_hand   |                                                                                                      | 尚未結算                |
      | winning_score  | 0                                                                                                    | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 990   | 紅心A, 方塊A |
      | Bob    | KhKd  | 980   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
    當 當前輪到的玩家進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                                  | Note                    |
      | status         | FLOP                                                                                   | 跟注後底池打平自動進Flop|
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9s | 扣除翻牌與燒牌後剩餘牌堆|
      | flop           | KsQsJs                                                                                 | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           |                                                                                        | 尚未發轉牌              |
      | river          |                                                                                        | 尚未發河牌              |
      | game           | <GameId>                                                                               | 當前遊戲 ID             |
      | action         | Bob                                                                                    | 輪到 Bob                |
      | winning_player | 0                                                                                      | 尚未結算                |
      | winning_hand   |                                                                                        | 尚未結算                |
      | winning_score  | 0                                                                                      | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 980   | 紅心A, 方塊A |
      | Bob    | KhKd  | 980   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
    當 另一位玩家也進行過牌跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                                  | Note                    |
      | status         | FLOP                                                                                   | 翻牌階段過牌            |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9s | 剩餘牌堆保持不變        |
      | flop           | KsQsJs                                                                                 | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           |                                                                                        | 尚未發轉牌              |
      | river          |                                                                                        | 尚未發河牌              |
      | game           | <GameId>                                                                               | 當前遊戲 ID             |
      | action         | Alice                                                                                  | 輪到 Alice              |
      | winning_player | 0                                                                                      | 尚未結算                |
      | winning_hand   |                                                                                        | 尚未結算                |
      | winning_score  | 0                                                                                      | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 980   | 紅心A, 方塊A |
      | Bob    | KhKd  | 980   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
    當 荷官發出翻牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                                  | Note                    |
      | status         | FLOP                                                                                   | 翻牌階段                |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9s | 翻牌後剩餘牌堆          |
      | flop           | KsQsJs                                                                                 | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           |                                                                                        | 尚未發轉牌              |
      | river          |                                                                                        | 尚未發河牌              |
      | game           | <GameId>                                                                               | 當前遊戲 ID             |
      | action         | Alice                                                                                  | 輪到 Alice              |
      | winning_player | 0                                                                                      | 尚未結算                |
      | winning_hand   |                                                                                        | 尚未結算                |
      | winning_score  | 0                                                                                      | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
    當 當前輪到的玩家進行加碼 20 籌碼
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                                  | Note                    |
      | status         | FLOP                                                                                   | 翻牌階段加碼            |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9s | 剩餘牌堆保持不變        |
      | flop           | KsQsJs                                                                                 | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           |                                                                                        | 尚未發轉牌              |
      | river          |                                                                                        | 尚未發河牌              |
      | game           | <GameId>                                                                               | 當前遊戲 ID             |
      | action         | Bob                                                                                    | 輪到 Bob                |
      | winning_player | 0                                                                                      | 尚未結算                |
      | winning_hand   |                                                                                        | 尚未結算                |
      | winning_score  | 0                                                                                      | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 960   | 紅心A, 方塊A |
      | Bob    | KhKd  | 980   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
    當 另一位玩家也進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                            | Note                    |
      | status         | TURN                                                                             | 下注完成自動進入轉牌階段|
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s | 扣除轉牌與燒牌後剩餘牌堆|
      | flop           | KsQsJs                                                                           | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                               | 黑桃8                   |
      | river          |                                                                                  | 尚未發河牌              |
      | game           | <GameId>                                                                         | 當前遊戲 ID             |
      | action         | Bob                                                                              | 輪到 Bob                |
      | winning_player | 0                                                                                | 尚未結算                |
      | winning_hand   |                                                                                  | 尚未結算                |
      | winning_score  | 0                                                                                | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 960   | 紅心A, 方塊A |
      | Bob    | KhKd  | 960   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
    當 荷官發出轉牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                            | Note                    |
      | status         | TURN                                                                             | 轉牌階段                |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s | 轉牌後剩餘牌堆          |
      | flop           | KsQsJs                                                                           | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                               | 黑桃8                   |
      | river          |                                                                                  | 尚未發河牌              |
      | game           | <GameId>                                                                         | 當前遊戲 ID             |
      | action         | Bob                                                                              | 輪到 Bob                |
      | winning_player | 0                                                                                | 尚未結算                |
      | winning_hand   |                                                                                  | 尚未結算                |
      | winning_score  | 0                                                                                | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
    當 當前輪到的玩家進行加碼 30 籌碼
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                            | Note                    |
      | status         | TURN                                                                             | 轉牌階段加碼            |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s | 剩餘牌堆保持不變        |
      | flop           | KsQsJs                                                                           | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                               | 黑桃8                   |
      | river          |                                                                                  | 尚未發河牌              |
      | game           | <GameId>                                                                         | 當前遊戲 ID             |
      | action         | Alice                                                                            | 輪到 Alice              |
      | winning_player | 0                                                                                | 尚未結算                |
      | winning_hand   |                                                                                  | 尚未結算                |
      | winning_score  | 0                                                                                | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 960   | 紅心A, 方塊A |
      | Bob    | KhKd  | 930   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
      | Bob    | 30    | RAISE | TURN     |
    當 另一位玩家也進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                      | Note                    |
      | status         | RIVER                                                                      | 下注完成自動進入河牌階段|
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc | 扣除河牌與燒牌後剩餘牌堆|
      | flop           | KsQsJs                                                                     | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                         | 黑桃8                   |
      | river          | 6s                                                                         | 黑桃6                   |
      | game           | <GameId>                                                                   | 當前遊戲 ID             |
      | action         | Bob                                                                        | 輪到 Bob                |
      | winning_player | 0                                                                          | 尚未結算                |
      | winning_hand   |                                                                            | 尚未結算                |
      | winning_score  | 0                                                                          | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 930   | 紅心A, 方塊A |
      | Bob    | KhKd  | 930   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
      | Bob    | 30    | RAISE | TURN     |
      | Alice  | 30    | CALL  | TURN     |
    當 荷官發出河牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                      | Note                    |
      | status         | RIVER                                                                      | 河牌階段                |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc | 河牌後剩餘牌堆          |
      | flop           | KsQsJs                                                                     | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                         | 黑桃8                   |
      | river          | 6s                                                                         | 黑桃6                   |
      | game           | <GameId>                                                                   | 當前遊戲 ID             |
      | action         | Bob                                                                        | 輪到 Bob                |
      | winning_player | 0                                                                          | 尚未結算                |
      | winning_hand   |                                                                            | 尚未結算                |
      | winning_score  | 0                                                                          | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
      | Bob    | 30    | RAISE | TURN     |
      | Alice  | 30    | CALL  | TURN     |
    當 當前輪到的玩家進行加碼 40 籌碼
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                      | Note                    |
      | status         | RIVER                                                                      | 河牌階段加碼            |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc | 剩餘牌堆保持不變        |
      | flop           | KsQsJs                                                                     | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                         | 黑桃8                   |
      | river          | 6s                                                                         | 黑桃6                   |
      | game           | <GameId>                                                                   | 當前遊戲 ID             |
      | action         | Alice                                                                      | 輪到 Alice              |
      | winning_player | 0                                                                          | 尚未結算                |
      | winning_hand   |                                                                            | 尚未結算                |
      | winning_score  | 0                                                                          | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 930   | 紅心A, 方塊A |
      | Bob    | KhKd  | 890   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
      | Bob    | 30    | RAISE | TURN     |
      | Alice  | 30    | CALL  | TURN     |
      | Bob    | 40    | RAISE | RIVER    |
    當 另一位玩家也進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                      | Note                    |
      | status         | SHOW                                                                       | 攤牌階段                |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc | 攤牌階段牌堆            |
      | flop           | KsQsJs                                                                     | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                         | 黑桃8                   |
      | river          | 6s                                                                         | 黑桃6                   |
      | game           | <GameId>                                                                   | 當前遊戲 ID             |
      | action         | Bob                                                                        | 輪到 Bob                |
      | winning_player | 0                                                                          | 尚未結算                |
      | winning_hand   |                                                                            | 尚未結算                |
      | winning_score  | 0                                                                          | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AhAd  | 890   | 紅心A, 方塊A |
      | Bob    | KhKd  | 890   | 紅心K, 方塊K |
    並且 透過 MySQL 資料庫驗證 "games" 表格中的遊戲設定應符合：
      | Field | Value |
      | min   | 10    |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
      | Bob    | 30    | RAISE | TURN     |
      | Alice  | 30    | CALL  | TURN     |
      | Bob    | 40    | RAISE | RIVER    |
      | Alice  | 40    | CALL  | RIVER    |
    並且 透過 MySQL 資料庫驗證 "game_players" 表格中的遊戲玩家關聯應符合：
      | Player | Note         |
      | Alice  | 參與遊戲房間 |
      | Bob    | 參與遊戲房間 |
    並且 透過 MySQL 資料庫驗證 "round_players" 表格中的回合玩家關聯應符合：
      | Player | Note         |
      | Alice  | 參與當前回合 |
      | Bob    | 參與當前回合 |
    當 雙方玩家進行攤牌結算派彩
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                      | Note                    |
      | status         | OVER                                                                       | 回合結束                |
      | deck           | 2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc | 回合結束剩餘牌堆        |
      | flop           | KsQsJs                                                                     | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s                                                                         | 黑桃8                   |
      | river          | 6s                                                                         | 黑桃6                   |
      | game           | <GameId>                                                                   | 當前遊戲 ID             |
      | action         | 0                                                                          | 回合結束 Action 為 0    |
      | winning_player | Alice                                                                      | 贏家 Alice              |
      | winning_hand   | AhAdKsQsJs8s6s                                                             | 贏家組合牌              |
      | winning_score  | 831                                                                        | 牌型計分分數            |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                         |
      | Alice  | AhAd  | 1110  | 贏得底池 220 籌碼 (890 + 220)|
      | Bob    | KhKd  | 890   | 輸掉底池，籌碼維持 890       |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 20    | RAISE | FLOP     |
      | Bob    | 20    | CALL  | FLOP     |
      | Bob    | 30    | RAISE | TURN     |
      | Alice  | 30    | CALL  | TURN     |
      | Bob    | 40    | RAISE | RIVER    |
      | Alice  | 40    | CALL  | RIVER    |
      | Bob    | 0     | CALL  | SHOW     |
      | Alice  | 0     | CALL  | SHOW     |
