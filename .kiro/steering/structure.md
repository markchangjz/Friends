# 專案結構

## 目錄組織

專案遵循 MVVM 架構，具有清晰的關注點分離：

```
Friends/
├── App/                              # 應用程式生命週期
│   ├── AppDelegate.swift            # App 生命週期管理
│   ├── SceneDelegate.swift          # Scene 生命週期管理
│   └── Info.plist                   # App 設定檔
│
├── Scenes/                          # 功能模組 (MVVM)
│   └── Friends/                     # 好友功能模組
│       ├── FriendsViewController.swift    # View 層
│       ├── FriendsViewModel.swift         # ViewModel 層
│       └── Components/                    # 功能專屬 UI 元件
│           ├── UserProfileHeaderView.swift
│           ├── FriendRequestCardView.swift
│           ├── FriendTableViewCell.swift
│           ├── PlaceholderSearchBarTableViewCell.swift
│           ├── TabSwitchView.swift
│           ├── EmptyStateView.swift
│           └── FriendSearchTransitionManager.swift
│
├── Data/                            # 資料層 (Repository 模式)
│   ├── Repository/
│   │   └── FriendsRemoteRepository.swift    # 資料存取實作
│   ├── Model/                              # 資料模型
│   │   ├── Friend.swift
│   │   └── Person.swift
│   └── Utility/
│       └── DateParser.swift               # 資料解析工具
│
├── Common/                          # 共用元件
│   ├── UI/                         # 可重複使用的 UI 元件
│   │   └── ShimmerView.swift
│   ├── TabBar/                     # 自訂 TabBar 實作
│   │   ├── CustomTabBarController.swift
│   │   ├── CustomTabBarView.swift
│   │   └── TabBarItem.swift
│   └── Design/                     # 設計系統
│       └── DesignConstants.swift   # 顏色、字體、間距
│
└── Resources/                       # 資源與素材
    ├── Assets.xcassets/            # 圖片、顏色、圖示
    └── Base.lproj/                 # 本地化資源
        └── LaunchScreen.storyboard
```

## 命名慣例

### 檔案與類別
- **ViewControllers**：`[功能]ViewController.swift` (例如：`FriendsViewController.swift`)
- **ViewModels**：`[功能]ViewModel.swift` (例如：`FriendsViewModel.swift`)
- **Models**：單數名詞 (例如：`Friend.swift`、`Person.swift`)
- **Views**：描述性名稱以 `View` 結尾 (例如：`EmptyStateView.swift`)
- **Cells**：描述性名稱以 `Cell` 結尾 (例如：`FriendTableViewCell.swift`)

### 程式碼結構
- **MARK 註解**：使用 `// MARK: - 區段名稱` 進行程式碼組織
- **屬性**：依存取層級 (public、private) 與類型分組
- **方法**：依功能性使用 MARK 區段分組
- **擴充**：實質的協定遵循使用獨立檔案

## 架構指導原則

### MVVM 實作
- **View**：UIViewController + UI 元件，無商業邏輯
- **ViewModel**：商業邏輯、資料轉換、狀態管理
- **Model**：資料結構、解析、驗證

### 資料流
- **Repository Protocol**：抽象資料存取介面
- **Combine Publishers**：ViewModel 與 View 間的響應式資料綁定
- **async/await**：API 呼叫的現代並發處理

### 測試結構
```
FriendsTests/
├── FriendsViewModelTests.swift      # ViewModel 單元測試
├── Model/                           # Model 測試
│   ├── FriendModelTests.swift
│   └── PersonModelTests.swift
└── Repository/                      # Repository 測試
    ├── FriendsRemoteRepositoryTests.swift
    ├── MockFriendsRemoteRepository.swift
    └── Mock API JSON files/         # 測試資料
```

## 關鍵模式

### 依賴注入
- ViewModels 在初始化器中接受 repository protocols
- 測試用的 Mock 實作

### Protocol-Oriented 設計
- Repository protocols 用於資料存取抽象化
- Delegate protocols 用於元件間通訊

### 響應式程式設計
- `@Published` 屬性用於自動 UI 更新
- `PassthroughSubject` 用於事件驅動更新
- 適當記憶體管理的 Combine 訂閱