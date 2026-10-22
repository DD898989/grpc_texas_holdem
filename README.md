# Texas Hold'em (Go & BDD)

此專案 Fork 自：https://github.com/imran31415/grpc_texas_holdem

## 專案改動

- **規則修正**：修正轉牌（Turn）與河牌（River）的發牌順序。
- **加入 BDD 測試**：撰寫完整的 BDD 驗證，讓人可以快速從資料庫狀態理解德州撲克的進行規則。
  - **Feature 連結**：[BDD/Features/](BDD/Features/)
    - [核心對局玩法 (TexasHoldemGameplay.feature)](BDD/Features/TexasHoldemGameplay.feature)
    - [過牌到底 (TexasHoldemCheckThrough.feature)](BDD/Features/TexasHoldemCheckThrough.feature)
    - [棄牌機制 (TexasHoldemFold.feature)](BDD/Features/TexasHoldemFold.feature)
    - [牌型比牌 (TexasHoldemHandRankings.feature)](BDD/Features/TexasHoldemHandRankings.feature)
    - [加注與反加 (TexasHoldemReRaise.feature)](BDD/Features/TexasHoldemReRaise.feature)
    - [平分底池 (TexasHoldemSplitPot.feature)](BDD/Features/TexasHoldemSplitPot.feature)
    - [連續對局與輪替莊家 (TexasHoldemConsecutiveRounds.feature)](BDD/Features/TexasHoldemConsecutiveRounds.feature)
    - [高額盲注 (TexasHoldemHighBlinds.feature)](BDD/Features/TexasHoldemHighBlinds.feature)
    - [多人對局 (TexasHoldemMultiPlayer.feature)](BDD/Features/TexasHoldemMultiPlayer.feature)
    - [離桌與座位管理 (TexasHoldemTableManagement.feature)](BDD/Features/TexasHoldemTableManagement.feature)
    - [逆向與非法操作防護 (TexasHoldemNegativeActions.feature)](BDD/Features/TexasHoldemNegativeActions.feature)
- **移除 gRPC，改為簡化 HTTP API**：
  1. 傳輸層並非效能瓶頸。
  2. 精簡 API Request 參數（原生型別與直覺 payload）。

## 未來方向

- 加上 Database Transaction 交易機制。
- 業務邏輯去冗員與代碼精簡化。
