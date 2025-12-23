# Friends - 好友列表頁面

一個使用 Swift 和 MVVM 架構開發的 iOS 好友列表應用程式，實作了完整的好友管理功能，包含好友列表顯示、邀請管理、搜尋功能等。

## 📋 目錄

- [功能特色](#功能特色)
- [技術架構](#技術架構)
- [專案結構](#專案結構)
- [需求實作](#需求實作)
- [加分項目](#加分項目)
- [API 資料來源](#api-資料來源)
- [設計 Guideline](#設計-guideline)
- [安裝與執行](#安裝與執行)
- [測試](#測試)
- [開發環境](#開發環境)

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
- **Protocol-Oriented Programming**：使用 Protocol 實現依賴注入，便於測試
- **Combine Framework**：響應式程式設計，處理資料流和狀態更新

### 主要技術
- **語言**：Swift 5.0+
- **UI Framework**：UIKit (不使用 SwiftUI)
- **非同步處理**：async/await
- **響應式程式設計**：Combine
- **測試框架**：XCTest

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
│  (Data Models)  │  APIService
└─────────────────┘  - 資料模型定義
                      - API 服務實作
```

## 📁 專案結構

```
Friends/
├── Friends/
│   ├── API Service/
│   │   ├── APIService.swift          # API 服務實作
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
│   ├── FriendsViewModel.swift        # ViewModel
│   └── Mock API JSON files/          # 模擬 API 資料
│       ├── man.json
│       ├── friend1.json
│       ├── friend2.json
│       ├── friend3.json
│       └── friend4.json
└── FriendsTests/
    ├── FriendsViewModelTests.swift   # ViewModel 測試
    ├── FriendModelTests.swift        # Friend Model 測試
    ├── PersonModelTests.swift        # Person Model 測試
    └── MockAPIService.swift          # Mock API Service
```

## 📝 需求實作

### 1. 頁面狀態實作

實作三種頁面狀態，根據資料自動切換：

- **無好友狀態**：當 API 2-(5) 返回空資料時，顯示空狀態畫面
- **只有好友列表**：當有好友資料但無邀請時，顯示好友列表
- **好友列表含邀請**：當同時有好友和邀請資料時，顯示兩個 Section

### 2. 非同步 API 請求

- **啟動時並行請求**：使用 `async/await` 同時載入使用者資料和好友資料
- **情境選擇**：透過 NavigationBar 左側選單選擇不同測試情境
  - 無好友畫面：請求 `friend4.json`
  - 只有好友列表：同時請求 `friend1.json` 和 `friend2.json`
  - 好友列表含邀請：請求 `friend3.json`

### 3. 資料整合邏輯

當選擇「只有好友列表」情境時：
- 同時請求兩個資料來源（`friend1.json` 和 `friend2.json`）
- 自動合併兩個資料源為單一列表
- 若 `fid` 重複，保留 `updateDate` 較新的資料
- 排序規則：
  1. `isTop` (true 優先)
  2. `updateDate` (新到舊)
  3. `fid` (小到大)

### 4. 搜尋功能

- 搜尋框支援對好友姓名進行關鍵字篩選
- 不區分大小寫
- 即時過濾，無需點擊搜尋按鈕
- 同時過濾邀請列表和好友列表

## 🎯 加分項目

### 1. Pull-to-Refresh ✅
- 實作下拉更新功能
- 重新呼叫 API 載入最新資料
- 顯示載入動畫

### 2. 搜尋框 UI 行為 ✅
- 點擊搜尋框時，畫面自動上推
- 搜尋框移動至 NavigationBar 下方
- 流暢的動畫過渡效果
- 取消搜尋時，搜尋框回到原位

### 3. 邀請列表縮合操作 ✅
- 邀請列表 Section Header 支援點擊
- 可展開/收合邀請列表
- 顯示展開/收合狀態的箭頭圖示
- 使用 `performBatchUpdates` 實現流暢動畫

### 4. Unit Test ✅
- **ViewModel 測試**：測試資料載入、過濾、狀態管理
- **Model 測試**：測試資料解析、日期格式處理
- **Mock Service**：使用 Protocol 實現 Mock，便於測試

## 🌐 API 資料來源

### API Endpoints

1. **使用者資料**
   - URL: `https://dimanyen.github.io/man.json`
   - 說明：取得當前使用者資料

2. **好友列表 1**
   - URL: `https://dimanyen.github.io/friend1.json`
   - 說明：第一個好友資料來源

3. **好友列表 2**
   - URL: `https://dimanyen.github.io/friend2.json`
   - 說明：第二個好友資料來源（用於資料整合測試）

4. **好友列表含邀請**
   - URL: `https://dimanyen.github.io/friend3.json`
   - 說明：包含邀請狀態的好友列表

5. **無資料列表**
   - URL: `https://dimanyen.github.io/friend4.json`
   - 說明：空的好友列表（用於測試無好友狀態）

### 資料欄位說明

| 欄位名稱 | 說明 |
|---------|------|
| `name` | 姓名 |
| `status` | 狀態：0=邀請送出, 1=已完成, 2=邀請中 |
| `isTop` | 是否顯示星星（置頂標記） |
| `fid` | 好友 ID |
| `updateDate` | 資料更新時間（格式：yyyy/MM/dd 或 yyyyMMdd） |

## 🎨 設計 Guideline

### Zeplin 設計稿

設計稿位於 Zeplin 專案中，可透過以下方式查看：

- **Zeplin 專案連結**：https://app.zeplin.io/project/5c498614493bf5bf68258c5a/dashboard
- **帳號**：kkinterview2020
- **密碼**：kk123456

### 設計狀態

1. **無好友狀態**
   - 連結：https://app.zeplin.io/project/5c498614493bf5bf68258c5a/screen/5d776380061b64a13531f133

2. **好友列表無邀請**
   - 連結：https://app.zeplin.io/project/5c498614493bf5bf68258c5a/screen/5d77637a8919b56be93718c5

3. **好友列表含邀請好友**
   - 連結：https://app.zeplin.io/project/5c498614493bf5bf68258c5a/screen/5d77637750db6d7380db8c87

## 🚀 安裝與執行

### 系統需求

- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- iOS 15.0 或更高版本（目標裝置）

### 執行步驟

1. **克隆專案**
   ```bash
   git clone <repository-url>
   cd Friends
   ```

2. **開啟專案**
   ```bash
   open Friends.xcodeproj
   ```

3. **選擇目標裝置**
   - 在 Xcode 中選擇模擬器或實體裝置

4. **執行專案**
   - 按 `Cmd + R` 或點擊 Run 按鈕

### 使用說明

1. **啟動應用程式**後，會自動載入預設情境（無好友畫面）

2. **切換情境**：
   - 點擊 NavigationBar 左側的選單按鈕
   - 選擇以下任一情境：
     - 無好友畫面
     - 只有好友列表
     - 好友列表含邀請

3. **搜尋好友**：
   - 點擊搜尋框開始搜尋
   - 輸入好友姓名關鍵字進行過濾

4. **更新資料**：
   - 下拉列表即可重新載入資料

5. **折疊邀請列表**：
   - 點擊 "Requests" Section Header 可展開/收合

## 🧪 測試

### 執行測試

在 Xcode 中：
- 按 `Cmd + U` 執行所有測試
- 或點擊 Product > Test

### 測試覆蓋範圍

- ✅ **FriendsViewModelTests**：ViewModel 業務邏輯測試
  - 初始化狀態測試
  - 資料載入測試
  - 搜尋過濾測試
  - 資料整合測試
  - 狀態管理測試

- ✅ **FriendModelTests**：Friend Model 測試
  - JSON 解析測試
  - 日期格式處理測試
  - Status 轉換測試

- ✅ **PersonModelTests**：Person Model 測試
  - JSON 解析測試

### Mock 服務

使用 `MockAPIService` 實作 Protocol，可在測試中模擬不同的 API 回應，無需實際網路請求。

## 💻 開發環境

- **開發語言**：Swift 5.0+
- **最低 iOS 版本**：iOS 15.0
- **開發工具**：Xcode 14.0+
- **架構模式**：MVVM
- **依賴管理**：無外部依賴（使用系統框架）

## 📄 授權

本專案為面試作品專案。

## 👤 開發者

Created by Mark Chang

---

**注意**：本專案使用本地 JSON 檔案模擬 API 回應，實際部署時需替換為真實的 API 端點。

