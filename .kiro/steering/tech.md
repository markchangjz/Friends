# 技術堆疊

## 建置系統與平台
- **Xcode 專案**：標準 iOS 專案，使用 `.xcodeproj` 結構
- **平台**：iOS 17.6+ (僅支援 iPhone，直向模式)
- **程式語言**：Swift 5.9
- **Bundle ID**：`tw.com.markchang.app`

## 框架與函式庫
- **UIKit**：主要 UI 框架 (100% 原生，無第三方 UI 函式庫)
- **Combine**：響應式程式設計，用於資料流與 UI 狀態管理
- **Foundation**：Swift 核心功能
- **XCTest**：單元測試框架

## 架構與模式
- **MVVM (Model-View-ViewModel)**：主要架構模式
- **Repository Pattern**：資料存取層抽象化
- **Protocol-Oriented Programming (POP)**：介面定義以實現解耦
- **Reactive Programming**：使用 Combine 框架進行 UI 狀態訂閱

## 現代 Swift 特性
- **async/await**：API 呼叫的現代並發處理
- **Task Groups**：多個非同步操作的並行執行
- **@Published**：響應式資料綁定的屬性包裝器
- **PassthroughSubject**：UI 更新的事件發布

## 常用指令

### 建置與執行
```bash
# 在 Xcode 中開啟專案
open Friends.xcodeproj

# 從命令列建置
xcodebuild -project Friends.xcodeproj -scheme Friends -destination 'platform=iOS Simulator,name=iPhone 15' build

# 執行測試
xcodebuild test -project Friends.xcodeproj -scheme Friends -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 測試
- **單元測試**：位於 `FriendsTests/` 目錄
- **模擬資料**：`FriendsTests/Repository/Mock API JSON files/` 中的 JSON 檔案
- **測試模式**：使用 async/await、Combine publishers 與模擬 repositories 的 XCTest

## 設計系統
- **DesignConstants.swift**：集中管理顏色、字體與間距定義
- **深色模式**：使用 `UIColor { traitCollection in ... }` 完整支援動態顏色
- **自訂元件**：手動實作的 TabBar、動畫與轉場效果