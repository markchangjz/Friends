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
    
    // 搜尋文字 - 使用 @Published 自動發布變更
    @Published var searchText: String = ""
    
    // 資料載入狀態 - 使用 PassthroughSubject 發布事件
    let dataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 好友資料載入完成 - 使用 PassthroughSubject 發布事件
    let friendsDataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 錯誤處理 - 使用 PassthroughSubject 發布錯誤
    let errorPublisher = PassthroughSubject<Error, Never>()
    
    // Section 計算
    var numberOfSections: Int {
        // 如果原始資料就是空的（沒有載入過資料），返回 0
        if allFriendRequests.isEmpty && allConfirmedFriends.isEmpty {
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
        return !friends.isEmpty
    }
    
    // MARK: - Private Properties
    
    // API Service
    private let apiService: APIServiceProtocol
    
    // 好友資料
    private(set) var friends: [Friend] = []
    
    // 原始未過濾的資料
    private var allFriendRequests: [Friend] = []
    private var allConfirmedFriends: [Friend] = []
    
    // 根據搜尋過濾後的資料
    private(set) var friendRequests: [Friend] = []
    private(set) var confirmedFriends: [Friend] = []
    
    private var hasFriendRequests: Bool {
        return !friendRequests.isEmpty
    }
    
    private var hasConfirmedFriends: Bool {
        return !confirmedFriends.isEmpty
    }
    
    // MARK: - Initialization
    
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    // MARK: - Public Methods
    
    func loadUserData() {
        Task {
            do {
                let person = try await apiService.fetchManData()
                await MainActor.run {
                    self.userName = person.name
                    self.userKokoId = person.kokoid
                    self.dataLoadedPublisher.send()
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
                var friendsData: [Friend]
                
                switch option {
                case .noFriends:
                    friendsData = try await apiService.fetchFriendsData_noFriends()
                case .friendsListWithInvitation:
                    friendsData = try await apiService.fetchFriendsData_hasFriends_hasInvitation()
                case .friendsListOnly:
                    // 並行取得兩個資料來源
                    async let friendsData1 = apiService.fetchFriendsData1()
                    async let friendsData2 = apiService.fetchFriendsData2()
                    let (data1, data2) = try await (friendsData1, friendsData2)
                    friendsData = mergeFriends(data1, data2)
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
            return section == 0 ? friendRequests.count : confirmedFriends.count
        } else {
            return confirmedFriends.count
        }
    }
    
    func isRequestSection(_ section: Int) -> Bool {
        return hasFriendRequests && section == 0
    }
    
    func friendRequest(at index: Int) -> Friend? {
        guard friendRequests.indices.contains(index) else { return nil }
        return friendRequests[index]
    }
    
    func confirmedFriend(at index: Int) -> Friend? {
        guard confirmedFriends.indices.contains(index) else { return nil }
        return confirmedFriends[index]
    }
    
    func titleForHeader(in section: Int) -> String? {
        guard section < numberOfSections else { return nil }
        
        if hasFriendRequests {
            return section == 0 ? "Requests" : "Friends"
        } else if hasConfirmedFriends {
            return "Friends"
        } else {
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func processFriendsData(_ friendsData: [Friend]) {
        self.friends = friendsData
        
        // 分類：status = .requestSent 為邀請，status = .accepted 或 .pending 為已確認好友
        self.allFriendRequests = friendsData.filter { $0.status == .requestSent }
        self.allConfirmedFriends = friendsData.filter { $0.status == .accepted || $0.status == .pending }
        
        // 初始化時套用當前的搜尋條件
        filterFriends()
    }
    
    /// 根據搜尋文字過濾好友資料
    func filterFriends() {
        if searchText.isEmpty {
            // 沒有搜尋文字，顯示所有資料
            friendRequests = allFriendRequests
            confirmedFriends = allConfirmedFriends
        } else {
            // 有搜尋文字，根據 name 進行過濾（不區分大小寫）
            let lowercasedSearch = searchText.lowercased()
            friendRequests = allFriendRequests.filter { 
                $0.name.lowercased().contains(lowercasedSearch) 
            }
            confirmedFriends = allConfirmedFriends.filter { 
                $0.name.lowercased().contains(lowercasedSearch) 
            }
        }
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
