# language: zh-TW
功能: 德州撲克違規下注防禦與錯誤處理驗證

  場景: 非當前輪到的玩家嘗試進行下注被系統拒絕
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD違規下注房1" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD違規下注房1" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 使用作弊機制將牌堆設定為 "2s3s4s5sTs2h3h4h5h6h7h8h9hThJhQh2d3d4d5d6d7d8d9dTdJdQd3c4c5c6c7c8c9cTcJcQcKcAc6s7s8s9sJsQsKsAsKdKhAdAh2c"
    並且 遊戲開始進入第一回合發牌
    當 非當前輪到的玩家嘗試進行跟注
    那麼 系統應拒絕該操作並回應錯誤訊息 "player not on action, can not bet"
    並且 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field  | Value    | Note             |
      | status | PRE_FLOP | 狀態維持 PRE_FLOP |
      | action | Alice    | 仍等待 Alice 行動 |
    當 當前輪到的玩家進行跟注
    那麼 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field  | Value | Note                    |
      | status | FLOP  | Alice 跟注後正常進入翻牌 |

  場景: 玩家嘗試加碼超過所持有的籌碼被系統拒絕
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD違規下注房2" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD違規下注房2" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 遊戲開始進入第一回合發牌
    當 當前輪到的玩家嘗試加碼 1500 籌碼
    那麼 系統應拒絕該操作並回應錯誤訊息 "player doesn't have enough chips"
    並且 透過 MySQL 資料庫驗證 "players" 表格中 "Alice" 的 "chips" 欄位應為 "990"
    並且 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field  | Value    | Note             |
      | status | PRE_FLOP | 狀態維持 PRE_FLOP |
      | action | Alice    | 仍等待 Alice 行動 |

  場景: 玩家加碼金額未達最低標準被系統拒絕
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD違規下注房3" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD違規下注房3" 遊戲
    當 遊戲完成座位分配與設定盲注 10 籌碼
    並且 遊戲開始進入第一回合發牌
    當 當前輪到的玩家嘗試進行無效加碼 10 籌碼
    那麼 系統應拒絕該操作並回應錯誤訊息 "wrong bet type"
    並且 透過 MySQL 資料庫驗證 "rounds" 表格中的桌面牌面與狀態紀錄應符合：
      | Field  | Value    | Note             |
      | status | PRE_FLOP | 狀態維持 PRE_FLOP |
      | action | Alice    | 仍等待 Alice 行動 |

  場景: 遊戲回合結束後玩家嘗試進行下注被系統拒絕
    假設 資料庫處於乾淨初始狀態
    並且 玩家 "Alice" 擁有 1000 籌碼建立名為 "BDD違規下注房4" 的遊戲
    並且 玩家 "Bob" 擁有 1000 籌碼加入 "BDD違規下注房4" 遊戲
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
    當 遊戲回合結束後玩家嘗試進行下注
    那麼 系統應拒絕該操作並回應錯誤訊息 "game is not in round"
    並且 透過 MySQL 資料庫驗證 "rounds" 表格中的 "status" 欄位應為 "OVER"
