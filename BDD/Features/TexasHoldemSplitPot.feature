# language: zh-TW
功能: 德州撲克雙方牌力相同和局平分底池流程

  場景: 桌面出現皇家同花順公牌雙方平分底池
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD平分底池測試房1" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD平分底池測試房1" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5s6s7s8s9s5d6d7d8d9dTdJdQdKdAd3c6c7c8c9cTcJcQcKcAc4h5h6h7h8h9hThJhQhKhAhTs2dJs3dQsKsAs4d5c4c3h2h2c"
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
      | Field          | Value | Note                               |
      | status         | OVER  | 攤牌結算結束回合                   |
      | action         | 0     | 結算完成無行動玩家                 |
      | winning_player | 0     | 雙方皆為皇家同花順，無單一獲勝玩家 |
      | winning_score  | 1     | 皇家同花順評分最佳為 1             |
    並且 透過 MySQL 資料庫驗證 "games" 表格中的 "in_round" 欄位應為 "0"
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Chips | Note                               |
      | Alice  | 1000  | Alice 平分底池 20 籌碼 (980 + 20)  |
      | Bob    | 1000  | Bob 平分底池 20 籌碼 (980 + 20)    |

  場景: 雙方同為順子牌型且踢牌無效平分底池
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD平分底池測試房2" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD平分底池測試房2" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "AsKsQsJsTs9s8s7s5s3sAhKhQhJhTh8h7h6h4h3h2hAcKcQcJcTc9c8c6cAdKdQdJdTd9d7d6d5d4d2d4c6s3c7c8d9h2s3d5c4s5h2c"
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
      | Field          | Value | Note                             |
      | status         | OVER  | 攤牌結算結束回合                 |
      | action         | 0     | 結算完成無行動玩家               |
      | winning_player | 0     | 雙方同為9高順子，平分底池        |
      | winning_score  | 1605  | 9高順子評分為 1605               |
    並且 透過 MySQL 資料庫驗證 "games" 表格中的 "in_round" 欄位應為 "0"
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Chips | Note                               |
      | Alice  | 1000  | Alice 平分底池 20 籌碼 (980 + 20)  |
      | Bob    | 1000  | Bob 平分底池 20 籌碼 (980 + 20)    |
