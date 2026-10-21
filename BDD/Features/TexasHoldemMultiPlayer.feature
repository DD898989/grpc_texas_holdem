# language: zh-TW
功能: 德州撲克多人桌輪轉與盲注分配流程

  場景: 3位玩家加入房間並完成盲注分配與下注進入翻牌圈
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD三人測試房1" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD三人測試房1" 遊戲
    並且 玩家 "Charlie" 擁有 1000 籌碼加入 "BDD三人測試房1" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAsKdKhAdAh2c"
    並且 遊戲開始進入第一回合發牌
    那麼 透過 MySQL 資料庫驗證 "game_players" 表格中應包含玩家 "Alice"
    並且 透過 MySQL 資料庫驗證 "game_players" 表格中應包含玩家 "Bob"
    並且 透過 MySQL 資料庫驗證 "game_players" 表格中應包含玩家 "Charlie"
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player  | Chips | Note                               |
      | Alice   | 1000  | Alice 為 Dealer (Button) 不扣盲注  |
      | Bob     | 990   | Bob 為 Small Blind 扣除 10 籌碼    |
      | Charlie | 980   | Charlie 為 Big Blind 扣除 20 籌碼  |
    當 當前輪到的玩家進行跟注
    並且 當前輪到的玩家進行跟注
    並且 當前輪到的玩家進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field  | Value | Note                   |
      | status | FLOP  | 三方補平大盲後進入翻牌 |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player  | Chips | Note                     |
      | Alice   | 980   | Alice 補跟 20 籌碼至 980 |
      | Bob     | 980   | Bob 補跟 10 籌碼至 980   |
      | Charlie | 980   | Charlie 大盲 20 過牌     |

  場景: 3位玩家對局中一人翻牌前棄牌另兩人繼續對決
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD三人測試房2" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD三人測試房2" 遊戲
    並且 玩家 "Charlie" 擁有 1000 籌碼加入 "BDD三人測試房2" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAsKdKhAdAh2c"
    並且 遊戲開始進入第一回合發牌
    當 當前輪到的玩家進行跟注
    並且 當前輪到的玩家進行棄牌
    並且 當前輪到的玩家進行過牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field  | Value | Note                               |
      | status | FLOP  | 一人棄牌後其餘兩人跟注打平進入翻牌 |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player  | Chips | Note                             |
      | Alice   | 980   | Alice 投入 20 籌碼跟注在手牌中   |
      | Bob     | 990   | Bob 扣除小盲 10 籌碼後棄牌       |
      | Charlie | 980   | Charlie 大盲 20 籌碼在手牌中     |
