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
    
    // 定義三種檢視選項
    enum ViewOption: String {
        case noFriends = "無好友畫面"
        case friendsListOnly = "只有好友列表"
        case friendsListWithInvitation = "好友列表含邀請"
    }
    
    // API Service
    private let apiService: APIServiceProtocol
    
    // 用戶資料
    private(set) var userName: String = ""
    private(set) var userKokoId: String = ""
    
    // 當前選中的選項 - 使用 @Published 自動發布變更
    @Published private(set) var selectedOption: ViewOption = .noFriends
    
    // 資料載入狀態 - 使用 PassthroughSubject 發布事件
    let dataLoadedPublisher = PassthroughSubject<Void, Never>()
    
    // 錯誤處理 - 使用 PassthroughSubject 發布錯誤
    let errorPublisher = PassthroughSubject<Error, Never>()
    
    // 初始化
    init(apiService: APIServiceProtocol = APIService()) {
        self.apiService = apiService
    }
    
    // 載入用戶資料
    func loadUserData() {
        apiService.fetchManData { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let person):
                self.userName = person.name
                self.userKokoId = person.kokoid
                self.dataLoadedPublisher.send()
            case .failure(let error):
                self.errorPublisher.send(error)
            }
        }
    }
    
    // 創建選單
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
    
    // 選擇選項
    func selectOption(_ option: ViewOption) {
        selectedOption = option
    }
}
