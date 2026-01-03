# Friends - 好友列表頁面 iOS 實作

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-lightgrey.svg)](https://apple.com)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-blue.svg)](https://en.wikipedia.org/wiki/Model–view–viewmodel)

這是一個精緻的 iOS 好友列表頁面實作，模擬 KOKO App 的核心功能。專案採用 **MVVM** 架構，結合 **Combine** 進行資料流管理，並在 UI/UX 上追求細膩的動畫效果（如堆疊卡片、搜尋轉場與載入動畫）。

---

## 📸 畫面展示

### 測試狀態切換
支援無好友、好友列表、好友列表含邀請等多種情境。

<img src="https://github.com/user-attachments/assets/8e4ae530-9971-415a-84d1-26736af53e74" width=60%>


### 技術驗證
- **單元測試**：確保核心邏輯穩定。
<img src="https://github.com/user-attachments/assets/3018a281-0c8c-44fd-981d-e73bf0728a65" width=85%>

- **API 追蹤**：使用 Proxy 工具驗證資料流。
<img src="https://github.com/user-attachments/assets/77acaa00-7b0d-4622-8152-30b85ab53a6e" width=85%>

- **AI Code Review**：利用 AI 進行自動化程式碼審查。
<img src="https://github.com/user-attachments/assets/141c61a7-f867-4d4f-836a-6d3d04944cd2" width=85%>

---

## ✨ 功能特色

### 核心功能
- **動態頁面狀態**：自動處理「無好友」、「僅好友列表」、「列表含好友邀請」三種情境。
- **並行資料載入**：使用 `async/await` 並行載入使用者資料與多個好友 API，提升啟動速度。
- **智慧資料整合**：自動合併重複的好友資料，並以最新版本（`updateDate`）為準。
- **即時關鍵字搜尋**：支援快速過濾好友名單。
- **下拉更新 (Pull-to-Refresh)**：隨時重新取得最新資料。

### 進階互動與動畫
- **堆疊卡片式邀請列表**：支援展開/收合效果。多筆邀請時顯示堆疊縮放感，點擊可流暢展開。
- **搜尋轉場動畫**：模擬原生 SearchBar 的流暢轉場，點擊時畫面自動上推。
- **骨架屏載入 (Shimmer)**：在資料載入期間顯示質感的漸層動畫。
- **待辦邀請 Badge**：自動計算待處理的好友邀請數量並顯示於 Tab 上。
- **空狀態視覺**：當無資料時顯示優美的插畫佔位，並處理下拉時的視覺細節。

---

## 🏗 技術架構

### 架構模式
- **MVVM (Model-View-ViewModel)**：徹底分離 UI 與業務邏輯，方便測試。
- **Repository Pattern**：封裝資料存取邏輯，支援測試時更換 Mock Data。
- **Protocol-Oriented Programming (POP)**：透過 Protocol 定義介面，實現高度解耦。
- **Reactive Programming**：利用 **Combine** Framework 處理 UI 狀態的訂閱與更新。

### 技術實作細節
- **現代並發**：使用 `async/await` 與 Task Group 處理複雜的異步邏輯。
- **設計系統管理**：透過 `DesignConstants` 統一管理字體、間距與顏色。
- **Dark Mode 支援**：所有 UI 元件（包含動態生成的背景與邊框）皆完美適配深淺色模式。
- **100% 原生 UI**：未使用任何第三方 UI 庫，所有自訂 TabBar、動畫皆手動實作。

---

## 📁 專案結構

```bash
Friends/
├── Friends/
│   ├── API Service/
│   │   ├── FriendsRemoteRepository.swift    # 資料存取層實作
│   │   ├── Model/
│   │   │   ├── Friend.swift               # 好友資料模型
│   │   │   └── Person.swift               # 使用者資料模型
│   │   └── Utility/
│   │       └── DateParser.swift           # 日期解析工具
│   ├── View/
│   │   ├── FriendTableViewCell.swift      # 好友列表 Cell
│   │   ├── FriendSearchTransitionManager.swift # 搜尋轉場動畫管理
│   │   ├── ShimmerView.swift              # 載入動畫效果
│   │   ├── UserProfileHeaderView.swift    # 使用者 Header（含邀請卡片）
│   │   ├── TabSwitchView.swift            # 好友/聊天切換視圖
│   │   ├── EmptyStateView.swift           # 無好友狀態畫面
│   │   └── PlaceholderSearchBarTableViewCell.swift # 搜尋框佔位 Cell
│   ├── Tab Bar/
│   │   ├── TabBarItem.swift               # Tab 項目定義
│   │   ├── CustomTabBarView.swift         # 自訂 Tab Bar 視圖
│   │   └── CustomTabBarController.swift   # 自訂 Tab Bar 控制器
│   ├── Assets.xcassets/                  # 專案圖示與顏色資產
│   ├── FriendsViewController.swift        # 主畫面控制器
│   ├── FriendsViewModel.swift             # 主畫面邏輯
│   ├── DesignConstants.swift              # 設計規範 (Colors, Fonts)
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
└── FriendsTests/
    ├── FriendsViewModelTests.swift        # ViewModel 單元測試
    ├── Model/
    │   ├── FriendModelTests.swift         # Friend 模型測試
    │   └── PersonModelTests.swift         # Person 模型測試
    └── Repository/
        ├── FriendsRemoteRepositoryTests.swift # Repository 整合測試
        ├── MockFriendsRemoteRepository.swift  # Mock 資料層
        └── Mock API JSON files/           # 測試用 JSON 檔案
```
