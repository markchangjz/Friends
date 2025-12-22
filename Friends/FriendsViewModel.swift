//
//  FriendsViewModel.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation
import UIKit

class FriendsViewModel {
    
    // 定義三種檢視選項
    enum ViewOption: String {
        case noFriends = "無好友畫面"
        case friendsListOnly = "只有好友列表"
        case friendsListWithInvitation = "好友列表含邀請"
    }
    
    // 當前選中的選項
    private(set) var selectedOption: ViewOption = .noFriends {
        didSet {
            onOptionChanged?(selectedOption)
        }
    }
    
    // 選項變更回調
    var onOptionChanged: ((ViewOption) -> Void)?
    
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
