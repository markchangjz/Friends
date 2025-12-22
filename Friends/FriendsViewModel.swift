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
    
    // 資料載入狀態 - 使用 PassthroughSubject 發布事件
    let dataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 好友資料載入完成 - 使用 PassthroughSubject 發布事件
    let friendsDataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 錯誤處理 - 使用 PassthroughSubject 發布錯誤
    let errorPublisher = PassthroughSubject<Error, Never>()
    
    // Section 計算
    var numberOfSections: Int {
        if !hasFriendRequests && !hasConfirmedFriends {
            return 0
        } else if hasFriendRequests && hasConfirmedFriends {
            return 2
        } else {
            return 1
        }
    }
    
    // MARK: - Private Properties
    
    // API Service
    private let apiService: APIServiceProtocol
    
    // 好友資料
    private(set) var friends: [Friend] = []
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
    
    func loadFriendsData(for option: ViewOption, updateSelection: Bool = true) {
        if updateSelection && selectedOption != option {
            selectedOption = option
        }
        
        Task {
            do {
                let friendsData: [Friend]
                
                switch option {
                case .noFriends:
                    friendsData = try await apiService.fetchFriendsData_noFriends()
                case .friendsListWithInvitation:
                    friendsData = try await apiService.fetchFriendsData_hasFriends_hasInvitation()
                case .friendsListOnly:
                    // 暫不實作
                    friendsData = []
                }
                
                await MainActor.run {
                    self.processFriendsData(friendsData)
                    self.friendsDataLoadedPublisher.send()
                }
            } catch {
                await MainActor.run {
                    self.errorPublisher.send(error)
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
        self.friendRequests = friendsData.filter { $0.status == .requestSent }
        self.confirmedFriends = friendsData.filter { $0.status == .accepted || $0.status == .pending }
    }
}
