# language: zh-TW
功能: 德州撲克高額盲注設定與大籌碼下注派彩流程

  場景: 設定盲注 50 籌碼的高額對局下注與結算派彩
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 2000 籌碼建立名為 "BDD高額盲注房" 的遊戲
    並且 玩家 "Bob" 擁有 2000 籌碼加入 "BDD高額盲注房" 遊戲
    當 遊戲完成座位分配與設定盲注 50 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAsKdKhAdAh2c"
    並且 遊戲開始進入第一回合發牌
    那麼 透過 MySQL 資料庫驗證 "games" 表格中的遊戲設定應符合：
      | Field | Value | Note       |
      | min   | 50    | 盲注底限 50|
    並且 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note        |
      | status         | PRE_FLOP | 翻牌前狀態  |
      | game           | <GameId> | 當前遊戲 ID |
      | action         | Alice    | 輪到 Alice  |
      | winning_player | 0        | 尚未結算    |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                               |
      | Alice  | AhAd  | 1950  | Alice 扣除小盲 50 籌碼 (2000 - 50) |
      | Bob    | KhKd  | 1900  | Bob 扣除大盲 100 籌碼 (2000 - 100) |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 50    | SMALL | PRE_FLOP |
      | Bob    | 100   | BIG   | PRE_FLOP |
    當 當前輪到的玩家進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                    |
      | status         | FLOP     | 跟注補平大盲進入翻牌階段|
      | flop           | KsQsJs   | 黑桃K, 黑桃Q, 黑桃J     |
      | action         | Bob      | 輪到 Bob                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                         |
      | Alice  | AhAd  | 1900  | Alice 補跟 50 籌碼 (1950 - 50)|
      | Bob    | KhKd  | 1900  | Bob 籌碼維持 1900            |
    當 當前輪到的玩家進行加碼 100 籌碼
    並且 另一位玩家也進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                    |
      | status         | TURN     | 翻牌下注完成進入轉牌階段|
      | flop           | KsQsJs   | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s       | 黑桃8                   |
      | action         | Bob      | 輪到 Bob                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                          |
      | Alice  | AhAd  | 1800  | Alice 跟注 100 (1900 - 100)   |
      | Bob    | KhKd  | 1800  | Bob 加碼投入 100 (1900 - 100) |
    當 當前輪到的玩家進行加碼 150 籌碼
    並且 另一位玩家也進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                    |
      | status         | RIVER    | 轉牌下注完成進入河牌階段|
      | flop           | KsQsJs   | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s       | 黑桃8                   |
      | river          | 6s       | 黑桃6                   |
      | action         | Bob      | 輪到 Bob                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                          |
      | Alice  | AhAd  | 1650  | Alice 跟注 150 (1800 - 150)   |
      | Bob    | KhKd  | 1650  | Bob 加碼投入 150 (1800 - 150) |
    當 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                    |
      | status         | SHOW     | 河牌過牌進入攤牌階段    |
      | action         | Bob      | 輪到 Bob                |
    當 雙方玩家進行攤牌結算派彩
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value          | Note                    |
      | status         | OVER           | 回合結束                |
      | flop           | KsQsJs         | 黑桃K, 黑桃Q, 黑桃J     |
      | turn           | 8s             | 黑桃8                   |
      | river          | 6s             | 黑桃6                   |
      | action         | 0              | 結算完成                |
      | winning_player | Alice          | Alice 同花獲勝          |
      | winning_hand   | AhAdKsQsJs8s6s | 贏家牌面                |
      | winning_score  | 831            | 同花計分 831            |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                 |
      | Alice  | AhAd  | 2350  | 贏得底池 700 籌碼 (1650 + 700 = 2350)|
      | Bob    | KhKd  | 1650  | 輸掉底池，籌碼維持 1650              |
    並且 透過 MySQL 資料庫驗證 "bets" 表格中的下注紀錄應符合：
      | Player | Chips | Type  | Status   |
      | Alice  | 50    | SMALL | PRE_FLOP |
      | Bob    | 100   | BIG   | PRE_FLOP |
      | Alice  | 50    | CALL  | PRE_FLOP |
      | Bob    | 100   | RAISE | FLOP     |
      | Alice  | 100   | CALL  | FLOP     |
      | Bob    | 150   | RAISE | TURN     |
      | Alice  | 150   | CALL  | TURN     |
      | Bob    | 0     | CALL  | RIVER    |
      | Alice  | 0     | CALL  | RIVER    |
      | Bob    | 0     | CALL  | SHOW     |
      | Alice  | 0     | CALL  | SHOW     |
