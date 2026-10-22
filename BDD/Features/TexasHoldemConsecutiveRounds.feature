# language: zh-TW
功能: 德州撲克同桌連續多回合與莊家按鈕輪替流程

  場景: 第一回合結束後立即在同一遊戲房間進行第二回合對決並輪替莊家按鈕
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD多回合測試房" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD多回合測試房" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAsKdKhAdAh2c"
    並且 遊戲開始進入第一回合發牌
    當 當前輪到的玩家進行跟注
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 雙方玩家進行攤牌結算派彩
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                            |
      | id             | 1        |                                |
      | status         | OVER     | 第一回合順利結束                |
      | winning_player | Alice    | 第一回合 Alice 獲勝             |
      | winning_score  | 831      | 同花計分 831                    |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                      |
      | Alice  | AhAd  | 1020  | Alice 贏得 40 籌碼底池 (980 + 40 = 1020)   |
      | Bob    | KhKd  | 980   | Bob 輸掉底池，籌碼剩餘 980                |
    當 使用作弊機制將牌堆設定為 "2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs8c7c6c5c4s3s2s2dAdAhKdKh2c"
    並且 遊戲開始進入第二回合發牌
    那麼 透過 MySQL 資料庫驗證 "games" 表格中的遊戲設定應符合：
      | Field  | Value | Note                   |
      | dealer | 2     | 莊家按鈕輪替至第 2 號位 Bob |
    並且 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                          |
      | id             | 2        |                                |
      | status         | PRE_FLOP | 第二回合進入翻牌前狀態        |
      | game           | <GameId> | 當前遊戲 ID                   |
      | action         | Bob      | 第二回合輪到小盲位 Bob 先行行動|
      | winning_player | 0        | 尚未結算                      |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                  |
      | Alice  | KhKd  | 1000  | Alice 大盲扣除 20 籌碼 (1020 - 20)    |
      | Bob    | AhAd  | 970   | Bob 莊家小盲扣除 10 籌碼 (980 - 10)   |
    當 當前輪到的玩家進行跟注
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 透過 MySQL 資料庫驗證 "games" 表格中的遊戲設定應符合：
      | Field      | Value |
      | in_round   | 1     |
    並且 雙方玩家進行攤牌結算派彩
    並且 透過 MySQL 資料庫驗證 "games" 表格中的遊戲設定應符合：
      | Field      | Value |
      | in_round   | 0     |
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value    | Note                |
      | status         | OVER     | 第二回合結束        |
      | winning_player | Bob      | 第二回合 Bob A對子獲勝|
      | winning_score  | 3517     | A對子計分           |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                  |
      | Alice  | KhKd  | 1000  | Alice 籌碼為 1000                     |
      | Bob    | AhAd  | 1000  | Bob 贏得 40 籌碼底池 (960 + 40 = 1000)|
