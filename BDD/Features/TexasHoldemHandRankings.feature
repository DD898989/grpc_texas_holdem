# language: zh-TW
功能: 德州撲克牌型大小與勝負判定驗證

  場景: 皇家同花順勝過四條鐵支的牌型對決
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD牌型測試房1" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD牌型測試房1" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2h2s3h3s4h4d4c4s5h5d5c5s6h6d6c6s8h8d8c8s9h9d9c9sThTdTcJhJdJcQhQdQcKhKdKcAhAdAc7s3d7d3cTsJsQs2d7h7cKsAs2c"
    並且 遊戲開始進入第一回合發牌
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value                                                                                            | Note                    |
      | status         | PRE_FLOP                                                                                         | 翻牌前狀態              |
      | game           | <GameId>                                                                                         | 當前遊戲 ID             |
      | action         | Alice                                                                                            | 輪到 Alice              |
      | winning_player | 0                                                                                                | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                  |
      | Alice  | AsKs  | 990   | Alice 拿到黑桃A與黑桃K|
      | Bob    | 7c7h  | 980   | Bob 拿到梅花7與紅心7  |
    當 當前輪到的玩家進行跟注
    並且 荷官發出翻牌
    並且 當前輪到的玩家進行加碼 20 籌碼
    並且 另一位玩家也進行跟注
    並且 荷官發出轉牌
    並且 當前輪到的玩家進行加碼 30 籌碼
    並且 另一位玩家也進行跟注
    並且 荷官發出河牌
    並且 當前輪到的玩家進行加碼 50 籌碼
    並且 另一位玩家也進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value          | Note                    |
      | status         | SHOW           | 進入攤牌階段            |
      | flop           | QsJsTs         | 翻牌同花順面            |
      | turn           | 7d             | 轉牌 7d (Bob三條7)      |
      | river          | 7s             | 河牌 7s (Bob組成四條鐵支)|
      | game           | <GameId>       | 當前遊戲 ID             |
      | action         | Bob            | 輪到 Bob                |
      | winning_player | 0              | 尚未結算                |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note         |
      | Alice  | AsKs  | 880   | 手牌維持     |
      | Bob    | 7c7h  | 880   | 手牌維持     |
    當 雙方玩家進行攤牌結算派彩
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value          | Note                            |
      | status         | OVER           | 回合結束                        |
      | flop           | QsJsTs         | 黑桃Q, 黑桃J, 黑桃10            |
      | turn           | 7d             | 方塊7                           |
      | river          | 7s             | 黑桃7                           |
      | action         | 0              | 結算完成                        |
      | winning_player | Alice          | Alice 皇家同花順勝過四條獲勝    |
      | winning_hand   | AsKsQsJsTs7d7s | 皇家同花順牌面組合              |
      | winning_score  | 1              | 牌型最高評分 1 (Royal Flush)    |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                |
      | Alice  | AsKs  | 1120  | 贏得底池 240 籌碼 (880 + 240 = 1120)|
      | Bob    | 7c7h  | 880   | 輸掉底池，籌碼維持 880              |

  場景: 葫蘆勝過同花的牌型對決
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD牌型測試房2" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD牌型測試房2" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2h3h3s4h4d4c5h5d5c5s6d6c7h7d7c7s8h8d8c9h9d9c9sThTdTcJhJdJcJsQhQdQcQsKcAhAdAcAsKd3dKh3cTs6s4s2d8s2s6hKs2c"
    並且 遊戲開始進入第一回合發牌
    那麼 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                 |
      | Alice  | Ks6h  | 990   | Alice 拿到老K與紅心6 |
      | Bob    | 2s8s  | 980   | Bob 拿到黑桃2與黑桃8 |
    當 當前輪到的玩家進行跟注
    並且 荷官發出翻牌
    並且 當前輪到的玩家進行加碼 20 籌碼
    並且 另一位玩家也進行跟注
    並且 荷官發出轉牌
    並且 當前輪到的玩家進行加碼 30 籌碼
    並且 另一位玩家也進行跟注
    並且 荷官發出河牌
    並且 當前輪到的玩家進行加碼 40 籌碼
    並且 另一位玩家也進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value          | Note                    |
      | status         | SHOW           | 進入攤牌階段            |
      | flop           | 4s6sTs         | 翻牌三張黑桃            |
      | turn           | Kh             | 轉牌紅心K               |
      | river          | Kd             | 河牌方塊K               |
      | game           | <GameId>       | 當前遊戲 ID             |
      | action         | Bob            | 輪到 Bob                |
      | winning_player | 0              | 尚未結算                |
    當 雙方玩家進行攤牌結算派彩
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field          | Value          | Note                                    |
      | status         | OVER           | 回合結束                                |
      | flop           | 4s6sTs         | 黑桃4, 黑桃6, 黑桃10                    |
      | turn           | Kh             | 紅心K                                   |
      | river          | Kd             | 方塊K                                   |
      | action         | 0              | 結算完成                                |
      | winning_player | Alice          | Alice 葫蘆勝過 Bob 黑桃同花獲勝         |
      | winning_hand   | Ks6h4s6sTsKhKd | 三張老K帶兩張6之葫蘆牌型 (Full House)   |
      | winning_score  | 186            | 葫蘆計分 186 勝過同花計分 1527          |
    並且 透過 MySQL 資料庫驗證 "players" 表格中的玩家紀錄應符合：
      | Player | Cards | Chips | Note                                |
      | Alice  | Ks6h  | 1110  | 贏得底池 220 籌碼 (890 + 220 = 1110)|
      | Bob    | 2s8s  | 890   | 輸掉底池，籌碼維持 890              |
