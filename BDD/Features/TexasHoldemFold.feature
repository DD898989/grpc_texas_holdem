# language: zh-TW
功能: 德州撲克玩家棄牌提前結束與收池流程

  場景: 翻牌前小盲玩家棄牌由大盲玩家直接收池獲勝
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD棄牌測試房1" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD棄牌測試房1" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAsKdKhAdAh2c"
    並且 遊戲開始進入第一回合發牌
    當 當前輪到的玩家進行棄牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value | Note                   |
      | status         | OVER  | 棄牌後直接結束回合     |
      | action         | 0     | 結算完成無行動玩家     |
      | winning_player | Bob   | 剩餘活躍玩家 Bob 獲勝  |
      | flop           |       | 未發翻牌               |
      | turn           |       | 未發轉牌               |
      | river          |       | 未發河牌               |
    並且 透過 MySQL 資料庫驗證 "games" 表格中的 "in_round" 欄位應為 "0"
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Chips | Note                                             |
      | Alice  | 990   | Alice 扣除小盲 10 籌碼 (1000 - 10)               |
      | Bob    | 1010  | Bob 贏得小盲 10 籌碼底池 (980 原剩餘 + 30 總底池) |

  場景: 翻牌圈面對加注玩家選擇棄牌由加注者收池獲勝
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD棄牌測試房2" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD棄牌測試房2" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs8c7c6c5c4s3s2s2dAdAhKdKh2c"
    並且 遊戲開始進入第一回合發牌
    當 當前輪到的玩家進行跟注
    並且 當前輪到的玩家進行過牌
    並且 當前輪到的玩家進行加碼 20 籌碼
    並且 當前輪到的玩家進行棄牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value | Note                  |
      | status         | OVER  | 棄牌後直接結束回合    |
      | action         | 0     | 結算完成無行動玩家    |
      | winning_player | Alice | 剩餘活躍玩家 Alice 獲勝|
      | turn           |       | 未發轉牌              |
      | river          |       | 未發河牌              |
    並且 透過 MySQL 資料庫驗證 "games" 表格中的 "in_round" 欄位應為 "0"
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Chips | Note                                              |
      | Bob    | 980   | Bob 投入大盲 20 後棄牌                            |
      | Alice  | 1020  | Alice 贏得底池 (960 原剩餘 + 60 總底池 = 1020)    |
