# Friends - 好友列表頁面

一個使用 Swift 和 MVVM 架構開發的 iOS 好友列表應用程式，實作了完整的好友管理功能，包含好友列表顯示、邀請管理、搜尋功能等。

## ✨ 功能特色

### 核心功能
- ✅ **三種頁面狀態**：無好友、只有好友列表、好友列表含邀請
- ✅ **非同步 API 請求**：啟動時並行載入使用者資料和好友資料
- ✅ **資料整合**：同時請求多個資料來源並自動合併，重複資料取最新版本
- ✅ **搜尋功能**：支援對好友姓名進行關鍵字篩選
- ✅ **下拉更新**：支援 Pull-to-Refresh 重新載入資料

### 進階功能
- ✅ **搜尋框動畫**：點擊搜尋框時，畫面自動上推至 NavigationBar 下方
- ✅ **邀請列表折疊**：邀請列表支援展開/收合操作
- ✅ **單元測試**：完整的 ViewModel 和 Model 測試覆蓋

## 🏗 技術架構

### 架構模式
- **MVVM (Model-View-ViewModel)**：清晰的職責分離
- **Repository Pattern**：資料存取層抽象化，便於測試與維護
- **Protocol-Oriented Programming**：使用 Protocol 實現依賴注入，便於測試
- **Combine Framework**：響應式程式設計，處理資料流和狀態更新

### 架構說明

```
┌─────────────────┐
│   View Layer    │  FriendsViewController
│  (UI Components)│  - 處理 UI 顯示與使用者互動
└────────┬────────┘  - 訂閱 ViewModel 的資料更新
         │
         │ Combine Publishers
         │
┌────────▼────────┐
│  ViewModel      │  FriendsViewModel
│  (Business      │  - 處理業務邏輯
│   Logic)        │  - 資料轉換與過濾
└────────┬────────┘  - 管理狀態
         │
         │ Protocol
         │
┌────────▼────────┐
│  Model Layer    │  Friend, Person
│  (Data Models)  │  FriendsRemoteRepository
└─────────────────┘  - 資料模型定義
                      - Repository Pattern 實作
```

## 📁 專案結構

```
Friends/
├── Friends/
│   ├── API Service/
│   │   ├── FriendsRemoteRepository.swift  # Repository Pattern 實作
│   │   └── Model/
│   │       ├── Friend.swift          # 好友資料模型
│   │       └── Person.swift          # 使用者資料模型
│   ├── View/
│   │   ├── FriendTableViewCell.swift           # 好友列表 Cell
│   │   ├── FriendRequestTableViewCell.swift    # 邀請列表 Cell
│   │   ├── PlaceholderSearchBarTableViewCell.swift  # 搜尋框 Cell
│   │   ├── SectionHeaderView.swift             # Section 標題
│   │   ├── UserProfileHeaderView.swift         # 使用者資料 Header
│   │   └── EmptyStateView.swift                # 空狀態畫面
│   ├── FriendsViewController.swift   # 主畫面 ViewController
│   └── FriendsViewModel.swift        # ViewModel
└── FriendsTests/
    ├── FriendsViewModelTests.swift   # ViewModel 測試
    ├── Model/
    │   ├── FriendModelTests.swift        # Friend Model 測試
    │   └── PersonModelTests.swift        # Person Model 測試
    └── Repository/
        ├── FriendsRemoteRepositoryTests.swift    # Repository 整合測試
        ├── MockFriendsRemoteRepository.swift   # Mock Repository（從本地 JSON 讀取）
        └── Mock API JSON files/          # 測試用 JSON 資料
            ├── man.json
            ├── friend1.json
            ├── friend2.json
            ├── friend3.json
            └── friend4.json
```



