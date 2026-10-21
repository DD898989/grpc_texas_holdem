# language: zh-TW
功能: 德州撲克翻牌階段激進反加與下注對決流程

  場景: 玩家在翻牌階段進行多次反加對決與大順子勝出
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD反加測試房" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD反加測試房" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2h2d2s3h3d3s4h4d4s5h5d5s6h6d6s7h7d7s8d8c8s9d9c9sThTdTcJdJcJsQhQcQsKhKdKsAdAcAs3c7c2c6cQdJhTs5cKcAh9h8h4c"
    並且 遊戲開始進入第一回合發牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note        |
      | status         | PRE_FLOP | 翻牌前狀態  |
      | game           | <GameId> | 當前遊戲 ID |
      | action         | Alice    | 輪到 Alice  |
      | winning_player | 0        | 尚未結算    |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                  |
      | Alice  | 8h9h  | 990   | Alice 拿到紅心8與紅心9|
      | Bob    | AhKc  | 980   | Bob 拿到紅心A與梅花K  |
    當 當前輪到的玩家進行跟注
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips |
      | Alice  | 8h9h  | 980   |
      | Bob    | AhKc  | 980   |
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note        |
      | status         | FLOP     | 進入翻牌階段|
      | flop           | TsJhQd   | 翻牌 10, J, Q|
      | action         | Bob      | 輪到 Bob    |
    當 當前輪到的玩家進行加碼 20 籌碼
    並且 另一位玩家進行反加 50 籌碼
    並且 當前輪到的玩家進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                    |
      | status         | TURN     | 雙方反加跟注打平自動進入轉牌|
      | flop           | TsJhQd   | 翻牌面保持              |
      | turn           | 2c       | 轉牌 2c                 |
      | action         | Bob      | 輪到 Bob                |
      | winning_player | 0        | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                     |
      | Alice  | 8h9h  | 930   | Alice 翻牌加碼投入 50 籌碼 (980 - 50 = 930)|
      | Bob    | AhKc  | 930   | Bob 翻牌下注 20 後補跟 30 (980 - 50 = 930)|
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 20    | RAISE | FLOP     |
      | Alice  | 50    | RAISE | FLOP     |
      | Bob    | 30    | CALL  | FLOP     |
    當 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                    |
      | status         | RIVER    | 轉牌過牌自動進入河牌階段|
      | turn           | 2c       | 轉牌 2c                 |
      | river          | 3c       | 河牌 3c                 |
      | action         | Bob      | 輪到 Bob                |
    當 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                    |
      | status         | SHOW     | 河牌過牌進入攤牌階段    |
      | action         | Bob      | 輪到 Bob                |
    當 雙方玩家進行攤牌結算派彩
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value          | Note                                        |
      | status         | OVER           | 回合結束                                    |
      | flop           | TsJhQd         | 黑桃10, 紅心J, 方塊Q                        |
      | turn           | 2c             | 梅花2                                       |
      | river          | 3c             | 梅花3                                       |
      | action         | 0              | 結算完成                                    |
      | winning_player | Bob            | Bob 皇家大順 (10-J-Q-K-A) 勝過 Alice 9高順獲勝|
      | winning_hand   | AhKcTsJhQd2c3c | Bob 贏家牌面組合                            |
      | winning_score  | 1600           | 大順子評分 1600 勝過 1602                   |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                     |
      | Alice  | 8h9h  | 930   | 輸掉底池，籌碼維持 930                   |
      | Bob    | AhKc  | 1070  | 贏得底池 140 籌碼 (930 + 140 = 1070)      |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 10    | SMALL | PRE_FLOP |
      | Bob    | 20    | BIG   | PRE_FLOP |
      | Alice  | 10    | CALL  | PRE_FLOP |
      | Bob    | 20    | RAISE | FLOP     |
      | Alice  | 50    | RAISE | FLOP     |
      | Bob    | 30    | CALL  | FLOP     |
      | Bob    | 0     | CALL  | TURN     |
      | Alice  | 0     | CALL  | TURN     |
      | Bob    | 0     | CALL  | RIVER    |
      | Alice  | 0     | CALL  | RIVER    |
      | Bob    | 0     | CALL  | SHOW     |
      | Alice  | 0     | CALL  | SHOW     |
