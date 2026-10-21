# language: zh-TW
功能: 德州撲克全程過牌至攤牌結算流程

  場景: 兩位玩家翻牌前補平大盲後全程過牌至攤牌並由較大對子獲勝
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD過牌測試房" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD過牌測試房" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs8c7c6c5c4s3s2s2dAdAhKdKh2c"
    並且 遊戲開始進入第一回合發牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                                            | Note                    |
      | status         | PRE_FLOP                                                                                         | 翻牌前狀態              |
      | deck           | 2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs8c7c6c5c4s3s2s2d       | 扣除手牌與燒牌後剩餘牌堆|
      | flop           |                                                                                                  | 尚未發翻牌              |
      | turn           |                                                                                                  | 尚未發轉牌              |
      | river          |                                                                                                  | 尚未發河牌              |
      | game           | <GameId>                                                                                         | 當前遊戲 ID             |
      | action         | Alice                                                                                            | 輪到 Alice              |
      | winning_player | 0                                                                                                | 尚未結算                |
      | winning_hand   |                                                                                                  | 尚未結算                |
      | winning_score  | 0                                                                                                | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note           |
      | Alice  | KhKd  | 990   | Alice 拿老K對子|
      | Bob    | AhAd  | 980   | Bob 拿A對子    |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
    當 當前輪到的玩家進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                            | Note                    |
      | status         | FLOP                                                                             | 跟注後底池打平進入翻牌  |
      | deck           | 2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs8c7c6c5c | 扣除翻牌與燒牌後剩餘牌堆|
      | flop           | 2s3s4s                                                                           | 翻牌 2s, 3s, 4s         |
      | turn           |                                                                                  | 尚未發轉牌              |
      | river          |                                                                                  | 尚未發河牌              |
      | game           | <GameId>                                                                         | 當前遊戲 ID             |
      | action         | Bob                                                                              | 輪到 Bob                |
      | winning_player | 0                                                                                | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | KhKd  | 980   | 紅心K, 方塊K |
      | Bob    | AhAd  | 980   | 紅心A, 方塊A |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
    當 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                      | Note                    |
      | status         | TURN                                                                       | 雙方過牌自動進入轉牌階段|
      | deck           | 2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs8c7c | 扣除轉牌與燒牌後剩餘牌堆|
      | flop           | 2s3s4s                                                                     | 翻牌 2s, 3s, 4s         |
      | turn           | 6c                                                                         | 轉牌 6c                 |
      | river          |                                                                            | 尚未發河牌              |
      | game           | <GameId>                                                                   | 當前遊戲 ID             |
      | action         | Bob                                                                        | 輪到 Bob                |
      | winning_player | 0                                                                          | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 0     | CALL  | FLOP     |
    當 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                | Note                    |
      | status         | RIVER                                                                | 雙方過牌自動進入河牌階段|
      | deck           | 2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs | 扣除河牌與燒牌後剩餘牌堆|
      | flop           | 2s3s4s                                                               | 翻牌 2s, 3s, 4s         |
      | turn           | 6c                                                                   | 轉牌 6c                 |
      | river          | 8c                                                                   | 河牌 8c                 |
      | game           | <GameId>                                                             | 當前遊戲 ID             |
      | action         | Bob                                                                  | 輪到 Bob                |
      | winning_player | 0                                                                    | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 0     | CALL  | FLOP     |
      | Bob    | 0     | CALL  | TURN     |
      | Alice  | 0     | CALL  | TURN     |
    當 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                | Note                    |
      | status         | SHOW                                                                 | 河牌過牌後進入攤牌階段  |
      | deck           | 2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs | 攤牌階段牌堆            |
      | flop           | 2s3s4s                                                               | 翻牌 2s, 3s, 4s         |
      | turn           | 6c                                                                   | 轉牌 6c                 |
      | river          | 8c                                                                   | 河牌 8c                 |
      | game           | <GameId>                                                             | 當前遊戲 ID             |
      | action         | Bob                                                                  | 輪到 Bob                |
      | winning_player | 0                                                                    | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 0     | CALL  | FLOP     |
      | Bob    | 0     | CALL  | TURN     |
      | Alice  | 0     | CALL  | TURN     |
      | Bob    | 0     | CALL  | RIVER    |
      | Alice  | 0     | CALL  | RIVER    |
    當 雙方玩家進行攤牌結算派彩
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                | Note                    |
      | status         | OVER                                                                 | 回合結束                |
      | deck           | 2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs | 牌堆保持一致            |
      | flop           | 2s3s4s                                                               | 翻牌 2s, 3s, 4s         |
      | turn           | 6c                                                                   | 轉牌 6c                 |
      | river          | 8c                                                                   | 河牌 8c                 |
      | game           | <GameId>                                                             | 當前遊戲 ID             |
      | action         | 0                                                                    | 結算完成 Action 為 0    |
      | winning_player | Bob                                                                  | 贏家 Bob                |
      | winning_hand   | AhAd2s3s4s6c8c                                                       | 贏家牌面 (A對子勝出)    |
      | winning_score  | 3517                                                                 | A對子計分               |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                |
      | Alice  | KhKd  | 980   | 輸掉底池，籌碼維持 980              |
      | Bob    | AhAd  | 1020  | 贏得底池 40 籌碼 (980 + 40 = 1020)  |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 0     | CALL  | FLOP     |
      | Alice  | 0     | CALL  | FLOP     |
      | Bob    | 0     | CALL  | TURN     |
      | Alice  | 0     | CALL  | TURN     |
      | Bob    | 0     | CALL  | RIVER    |
      | Alice  | 0     | CALL  | RIVER    |
      | Bob    | 0     | CALL  | SHOW     |
      | Alice  | 0     | CALL  | SHOW     |
