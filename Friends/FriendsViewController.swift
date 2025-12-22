//
//  ViewController.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit

class FriendsViewController: UIViewController {
    
    // ViewModel
    private let viewModel = FriendsViewModel()
    
    // 選單按鈕引用
    private var menuButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupNavigationBar()
    }
    
    private func setupViewModel() {
        // 監聽選項變更
        viewModel.onOptionChanged = { [weak self] option in
            self?.updateMenu()
            self?.updateView(for: option)
        }
    }
    
    private func setupNavigationBar() {
        // 創建選單按鈕
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: nil,
            action: nil
        )
        
        // 設置選單
        menuButton.menu = viewModel.createMenu()
        
        // 保存引用以便後續更新
        self.menuButton = menuButton
        
        // 設置為左側導航欄按鈕
        navigationItem.leftBarButtonItem = menuButton
    }
    
    private func updateMenu() {
        // 更新選單狀態
        menuButton?.menu = viewModel.createMenu()
    }
    
    private func updateView(for option: FriendsViewModel.ViewOption) {
        // 根據選項更新畫面內容
        switch option {
        case .noFriends:
            // 顯示無好友畫面
            print("切換到：無好友畫面")
        case .friendsListOnly:
            // 顯示只有好友列表
            print("切換到：只有好友列表")
        case .friendsListWithInvitation:
            // 顯示好友列表含邀請
            print("切換到：好友列表含邀請")
        }
    }
}

