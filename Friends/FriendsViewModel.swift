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
    
    // Section 索引常數
    enum Section {
        static let requests = 0
        static let friends = 1
    }
    
    // MARK: - Public Properties
    
    // 用戶資料
    private(set) var userName: String = ""
    private(set) var userKokoId: String = ""
    
    // 當前選中的選項 - 使用 @Published 自動發布變更
    @Published private(set) var selectedOption: ViewOption = .noFriends
    
    // 搜尋文字 - 使用 @Published 自動發布變更
    @Published var searchText: String = ""
    
    // 使用者資料載入狀態 - 使用 PassthroughSubject 發布事件
    let userProfileDataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 好友資料載入完成 - 使用 PassthroughSubject 發布事件
    let friendsDataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 錯誤處理 - 使用 PassthroughSubject 發布錯誤
    let errorPublisher = PassthroughSubject<Error, Never>()
    
    // Section 計算
    var numberOfSections: Int {
        // 如果原始資料就是空的（沒有載入過資料），返回 0
        if allRequestFriends.isEmpty && allConfirmedFriends.isEmpty {
            return 0
        }
        
        // 如果有原始資料，至少顯示一個 section（用於顯示搜尋列）
        if hasFriendRequests && hasConfirmedFriends {
            return 2
        } else {
            return 1
        }
    }
    
    // 是否有任何好友資料（包含邀請和已確認好友）
    var hasFriends: Bool {
        return !allFriends.isEmpty
    }
    
    var hasFilteredFriends: Bool {
        return hasFriendRequests || hasConfirmedFriends
    }
    
    var hasFriendRequests: Bool {
        return !displayRequestFriends.isEmpty
    }
    
    var hasConfirmedFriends: Bool {
        return !displayConfirmedFriends.isEmpty
    }
    
    // Requests section 展開狀態
    var isRequestsSectionExpanded: Bool = true
    
    // 好友 section 的索引
    var friendsSection: Int {
        return hasFriendRequests ? Section.friends : Section.requests
    }

    // MARK: - Private Properties
    
    // Repository
    private let repository: FriendsRepositoryProtocol
    
    /*
    allFriends: [Friend]              // 所有好友（未分類）- 從 API 載入
        ↓ 分類
    ├── allRequestFriends: [Friend]   // 所有請求狀態的好友
    │   ↓ 過濾/搜尋
    │   └── displayRequestFriends     // 要顯示的請求好友
    │
    └── allConfirmedFriends: [Friend] // 所有已確認的好友
        ↓ 過濾/搜尋
        └── displayConfirmedFriends   // 要顯示的已確認好友
    */
    
    // 所有好友資料（未分類）
    private(set) var allFriends: [Friend] = []
    
    // 原始未過濾的資料（已分類）
    private var allRequestFriends: [Friend] = []
    private var allConfirmedFriends: [Friend] = []
    
    // 要顯示的資料（根據搜尋過濾後）
    private(set) var displayRequestFriends: [Friend] = []
    private(set) var displayConfirmedFriends: [Friend] = []
    
    // MARK: - Initialization
    
    init(repository: FriendsRepositoryProtocol = FriendsRemoteRepository()) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    func loadUserData() {
        Task {
            do {
                let userProfile = try await repository.fetchUserProfile()
                await MainActor.run {
                    self.userName = userProfile.name
                    self.userKokoId = userProfile.kokoid
                    self.userProfileDataLoadedPublisher.send()
                }
            } catch {
                await MainActor.run {
                    self.errorPublisher.send(error)
                }
            }
        }
    }
    
    func loadFriendsData(for option: ViewOption) {
        Task {
            do {
                // 取得好友資料
                let friendsData = try await fetchFriendsData(for: option)
                
                // 所有資料都載入完成後，一起更新 UI
                await MainActor.run {
                    self.processFriendsData(friendsData)
                    self.friendsDataLoadedPublisher.send()
                }
            } catch {
                await MainActor.run {
                    self.errorPublisher.send(error)
                    self.friendsDataLoadedPublisher.send()
                }
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
                await MainActor.run {
                    // 更新使用者資料
                    self.userName = userProfile.name
                    self.userKokoId = userProfile.kokoid
                    self.userProfileDataLoadedPublisher.send()
                    
                    // 更新好友資料
                    self.processFriendsData(friendsData)
                    self.friendsDataLoadedPublisher.send()
                }
            } catch {
                await MainActor.run {
                    self.errorPublisher.send(error)
                    self.friendsDataLoadedPublisher.send()
                }
            }
        }
    }
    
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
        
        return UIMenu(
            title: "",
            children: [
                noFriendsAction,
                friendsListOnlyAction,
                friendsListWithInvitationAction
            ]
        )
    }
    
    // MARK: - TableView Data Source Helpers
    
    func numberOfRows(in section: Int) -> Int {
        guard section < numberOfSections else { return 0 }
        
        if hasFriendRequests {
            return section == Section.requests ? displayRequestFriends.count : displayConfirmedFriends.count
        } else {
            return displayConfirmedFriends.count
        }
    }
    
    func isRequestSection(_ section: Int) -> Bool {
        return hasFriendRequests && section == Section.requests
    }
    
    func friendRequest(at index: Int) -> Friend? {
        guard displayRequestFriends.indices.contains(index) else { return nil }
        return displayRequestFriends[index]
    }
    
    func confirmedFriend(at index: Int) -> Friend? {
        guard displayConfirmedFriends.indices.contains(index) else { return nil }
        return displayConfirmedFriends[index]
    }
    
    func titleForHeader(in section: Int) -> String? {
        guard section < numberOfSections else { return nil }
        
        if hasFriendRequests {
            return section == Section.requests ? "Requests" : "Friends"
        } else if hasConfirmedFriends {
            return "Friends"
        } else {
            return nil
        }
    }
    
    /// 根據搜尋文字過濾好友資料
    func filterFriends() {
        if searchText.isEmpty {
            // 沒有搜尋文字，顯示所有資料
            displayRequestFriends = allRequestFriends
            displayConfirmedFriends = allConfirmedFriends
        } else {
            // 有搜尋文字，根據 name 進行過濾（不區分大小寫）
            let lowercasedSearch = searchText.lowercased()
            displayRequestFriends = allRequestFriends.filter { 
                $0.name.lowercased().contains(lowercasedSearch) 
            }
            displayConfirmedFriends = allConfirmedFriends.filter { 
                $0.name.lowercased().contains(lowercasedSearch) 
            }
        }
    }
    
    /// 清除搜尋文字並重置過濾
    func clearSearch() {
        searchText = ""
        filterFriends()
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
        
        // 分類：status = .requestSent 為邀請，status = .accepted 或 .pending 為已確認好友
        self.allRequestFriends = friendsData.filter { $0.status == .requestSent }
        self.allConfirmedFriends = friendsData.filter { $0.status == .accepted || $0.status == .pending }
        
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
