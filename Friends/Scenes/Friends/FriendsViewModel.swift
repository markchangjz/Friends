//
//  FriendsViewModel.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation
import UIKit
import Combine

class FriendsViewModel {
    
    // MARK: - Types
    
    // 定義三種檢視選項
    enum ViewOption: String {
        case noFriends = "無好友畫面"
        case friendsListOnly = "只有好友列表"
        case friendsListWithInvitation = "好友列表含邀請"
    }
    
    // MARK: - Public Properties
    
    // 用戶資料
    private(set) var userName: String = ""
    private(set) var userKokoId: String = ""
    
    // 當前選中的選項 - 使用 @Published 自動發布變更
    @Published private(set) var selectedOption: ViewOption = .noFriends
    
    
    // 使用者資料載入狀態 - 使用 PassthroughSubject 發布事件
    let userProfileDataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 好友資料載入完成 - 使用 PassthroughSubject 發布事件
    let friendsDataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 錯誤處理 - 使用 PassthroughSubject 發布錯誤
    let errorPublisher = PassthroughSubject<Error, Never>()
    
    // 是否有任何好友資料（包含邀請和已確認好友）
    var hasFriends: Bool {
        return !allFriends.isEmpty
    }
    
    var hasFriendRequests: Bool {
        return !displayRequestFriends.isEmpty
    }
    
    var hasConfirmedFriends: Bool {
        return !displayConfirmedFriends.isEmpty
    }
    
    // 未過濾的 pending 好友數量（用於 Badge）
    var pendingFriendCount: Int {
        return allFriends.filter { $0.status == .pending }.count
    }
    
    // 聊天 Badge 數量（固定為 100，顯示為 99+）
    var chatBadgeCount: Int {
        return 100
    }
    
    // Requests section 展開狀態（預設折疊）
    var isRequestsSectionExpanded: Bool = false
    
    // 是否正在使用真實的 searchController (決定是否顯示 placeholder search bar)
    var isUsingRealSearchController: Bool = false
    
    // 是否正在搜尋（用於追蹤搜尋狀態，搜尋時強制展開 cardViews）
    private(set) var isSearching: Bool = false
    
    // 當前選中的 tab（Friends 或 Chat）
    var currentTab: TabSwitchView.Tab = .friends

    // MARK: - Private Properties
    
    // 搜尋前的展開狀態（用於搜尋結束時恢復）
    private var previousExpandedState: Bool = false
    
    // Repository
    private let repository: FriendsRepositoryProtocol
    
    /*
    allFriends: [Friend]              // 所有好友（未分類）- 從 API 載入
        ↓ 分類 + 過濾/搜尋
    ├── displayRequestFriends         // 要顯示的請求好友
    └── displayConfirmedFriends       // 要顯示的已確認好友
    */
    
    // 所有好友資料（未分類）
    private(set) var allFriends: [Friend] = []
    
    // 要顯示的資料（根據搜尋過濾後）
    private(set) var displayRequestFriends: [Friend] = []
    private(set) var displayConfirmedFriends: [Friend] = []
    
    // MARK: - Initialization
    
    init(repository: FriendsRepositoryProtocol = FriendsRemoteRepository()) {
        self.repository = repository
    }
    
    // MARK: - Data Loading
    
    func loadFriendsData(for option: ViewOption) {
        Task {
            do {
                // 取得好友資料
                let friendsData = try await fetchFriendsData(for: option)
                
                // 所有資料都載入完成後，一起更新 UI
                processFriendsData(friendsData)
                friendsDataLoadedPublisher.send()
            } catch {
                errorPublisher.send(error)
                friendsDataLoadedPublisher.send()
            }
        }
    }
    
    /// 同時載入使用者資料和好友資料，等兩者都完成後才一起更新 UI
    func loadAllData(for option: ViewOption) {
        Task {
            do {
                // 並行執行兩個 API 呼叫
                async let userProfileTask = repository.fetchUserProfile()
                async let friendsTask = fetchFriendsData(for: option)
                
                // 等待兩個 API 都完成
                let (userProfile, friendsData) = try await (userProfileTask, friendsTask)
                
                // 所有資料都載入完成後，一起更新 UI
                // 更新使用者資料
                userName = userProfile.name
                userKokoId = userProfile.kokoid
                userProfileDataLoadedPublisher.send()
                
                // 更新好友資料
                processFriendsData(friendsData)
                friendsDataLoadedPublisher.send()
            } catch {
                errorPublisher.send(error)
                friendsDataLoadedPublisher.send()
            }
        }
    }
    
    // MARK: - Option Selection
    
    func selectOption(_ option: ViewOption) {
        selectedOption = option
    }
    
    func createMenu() -> UIMenu {
        let noFriendsAction = UIAction(
            title: ViewOption.noFriends.rawValue,
            image: nil,
            state: selectedOption == .noFriends ? .on : .off
        ) { [weak self] _ in
            self?.selectOption(.noFriends)
        }
        
        let friendsListOnlyAction = UIAction(
            title: ViewOption.friendsListOnly.rawValue,
            image: nil,
            state: selectedOption == .friendsListOnly ? .on : .off
        ) { [weak self] _ in
            self?.selectOption(.friendsListOnly)
        }
        
        let friendsListWithInvitationAction = UIAction(
            title: ViewOption.friendsListWithInvitation.rawValue,
            image: nil,
            state: selectedOption == .friendsListWithInvitation ? .on : .off
        ) { [weak self] _ in
            self?.selectOption(.friendsListWithInvitation)
        }
        
        // 使用 .singleSelection 選項讓系統自動管理勾選狀態
        return UIMenu(
            title: "",
            options: .singleSelection,
            children: [
                noFriendsAction,
                friendsListOnlyAction,
                friendsListWithInvitationAction
            ]
        )
    }
    
    // MARK: - Data Access
    
    /// 根據搜尋文字過濾好友資料
    /// - Parameter searchText: 搜尋關鍵字，空字串表示不過濾
    func filterFriends(name searchText: String = "") {
        // 先從 allFriends 分類
        let requestFriends = allFriends.filter { $0.status == .requestSent }
        let confirmedFriends = allFriends.filter { $0.status == .accepted || $0.status == .pending }
        
        if searchText.isEmpty {
            // 沒有搜尋文字，顯示所有資料
            displayRequestFriends = requestFriends
            displayConfirmedFriends = confirmedFriends
        } else {
            // 有搜尋文字，根據 name 進行過濾（不區分大小寫）
            let lowercasedSearch = searchText.lowercased()
            displayRequestFriends = requestFriends.filter { 
                $0.name.lowercased().contains(lowercasedSearch) 
            }
            displayConfirmedFriends = confirmedFriends.filter { 
                $0.name.lowercased().contains(lowercasedSearch) 
            }
        }
    }
    
    /// 清除搜尋文字並重置過濾
    func clearSearch() {
        filterFriends(name: "")
    }
    
    /// 開始搜尋（強制展開 cardViews）
    func startSearching() {
        previousExpandedState = isRequestsSectionExpanded
        isSearching = true
        // 如果有邀請，強制展開
        if hasFriendRequests {
            isRequestsSectionExpanded = true
        }
    }
    
    /// 結束搜尋（恢復原本折疊狀態）
    func stopSearching() {
        isSearching = false
        // 恢復搜尋前的狀態
        isRequestsSectionExpanded = previousExpandedState
    }
    
    // MARK: - Private Methods
    
    /// 非同步取得好友資料（內部方法）
    private func fetchFriendsData(for option: ViewOption) async throws -> [Friend] {
        var friendsData: [Friend]
        
        switch option {
        case .noFriends:
            friendsData = try await repository.fetchFriends_noFriends()
        case .friendsListWithInvitation:
            friendsData = try await repository.fetchFriends_hasFriends_hasInvitation()
        case .friendsListOnly:
            // 並行取得兩個資料來源
            async let friends1 = repository.fetchFriends1()
            async let friends2 = repository.fetchFriends2()
            let (list1, list2) = try await (friends1, friends2)
            friendsData = mergeFriends(list1, list2)
        }
        
        friendsData.sort { lhs, rhs in
            // 優先級 1: isTop (true 在前)
            if lhs.isTop != rhs.isTop {
                return lhs.isTop
            }
            // 優先級 2: updateDate (新到舊)
            if lhs.updateDate != rhs.updateDate {
                return lhs.updateDate > rhs.updateDate
            }
            // 優先級 3: fid (小到大)
            return lhs.fid < rhs.fid
        }
        
        return friendsData
    }
    
    private func processFriendsData(_ friendsData: [Friend]) {
        self.allFriends = friendsData
        
        // 初始化時套用當前的搜尋條件
        filterFriends()
    }
    
    /// 合併多個好友資料來源，當 fid 相同時保留 updateDate 最新的
    private func mergeFriends(_ friends1: [Friend], _ friends2: [Friend]) -> [Friend] {
        var friendsDict: [String: Friend] = [:] // key: fid, value: Friend
        
        // 將兩個陣列合併處理
        let allFriends = friends1 + friends2
        
        for friend in allFriends {
            // 如果 fid 不存在，直接加入
            guard let existingFriend = friendsDict[friend.fid] else {
                friendsDict[friend.fid] = friend
                continue
            }
            
            // 如果 fid 已存在，比較 updateDate，保留較新的
            if friend.updateDate > existingFriend.updateDate {
                friendsDict[friend.fid] = friend
            }
        }
        
        // 回傳字典的所有值（已去重且保留最新的）
        return Array(friendsDict.values)
    }
}
