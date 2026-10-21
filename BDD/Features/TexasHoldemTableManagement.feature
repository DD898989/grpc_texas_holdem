# language: zh-TW
功能: 德州撲克房間生命週期與玩家進出管理

  場景: 對局進行中玩家嘗試離桌應被防護機制拒絕
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD房間管理房1" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD房間管理房1" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 遊戲開始進入第一回合發牌
    當 玩家 "Alice" 嘗試離開遊戲房間
    那麼 系統應拒絕離桌請求並回應錯誤訊息 "can not perform operation when game is in round"
    並且 透過 MySQL 資料庫驗證 "game_players" 表格中應包含玩家 "Alice"
    並且 透過 MySQL 資料庫驗證 "games" 表格中的 "in_round" 欄位應為 "1"

  場景: 對局結束後玩家正常離桌成功
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD房間管理房2" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD房間管理房2" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2h3h3d3c4h4d4c5h5d5s6h6d6s7h7d7s8h8d8s9h9d9c9sThTdTcTsJhJdJcJsQhQdQcQsKcKsAcAs8c7c6c5c4s3s2s2dAdAhKdKh2c"
    並且 遊戲開始進入第一回合發牌
    當 當前輪到的玩家進行跟注
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 當前輪到的玩家進行過牌
    並且 另一位玩家也進行過牌
    並且 雙方玩家進行攤牌結算派彩
    並且 透過 MySQL 資料庫驗證 "games" 表格中的 "in_round" 欄位應為 "0"
    當 玩家 "Alice" 離開遊戲房間
    那麼 透過 MySQL 資料庫驗證 "game_players" 表格中不應包含玩家 "Alice"
    並且 透過 MySQL 資料庫驗證 "game_players" 表格中應包含玩家 "Bob"

  場景: 只有 1 位玩家在房間時嘗試分配座位應被拒絕
    假設 資料庫處於乾淨初始狀態
    並且 只有玩家 "Alice" 擁有 1000 籌碼加入名為 "BDD單人測試房" 的遊戲
    當 只有 1 位玩家時嘗試分配遊戲座位
    那麼 系統應拒絕該操作並回應錯誤訊息 "can not create game with supplied count of players"
