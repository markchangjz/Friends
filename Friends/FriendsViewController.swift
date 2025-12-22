//
//  ViewController.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit
import Combine

class FriendsViewController: UIViewController {
    
    // ViewModel
    private let viewModel = FriendsViewModel()
    
    // Combine 訂閱管理
    private var cancellables = Set<AnyCancellable>()
    
    // 選單按鈕引用
    private var menuButton: UIBarButtonItem?
    
    // UI 元件
    private let headerView = UIView()
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let kokoIdLabel = UILabel()
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupViewModel() {
        // 使用 Combine 訂閱選項變更
        viewModel.$selectedOption
            .sink { [weak self] option in
                self?.updateMenu()
                self?.updateView(for: option)
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱資料載入完成
        viewModel.dataLoadedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateHeaderView()
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱錯誤
        viewModel.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("載入資料失敗：\(error.localizedDescription)")
            }
            .store(in: &cancellables)
    }
    
    private func loadData() {
        viewModel.loadUserData()
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
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        setupTableView()
        setupHeaderView()
    }
    
    private func setupHeaderView() {
        // Header View 設定
        headerView.backgroundColor = .white
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 100)
        
        // Avatar ImageView 設定
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.backgroundColor = .systemGray5
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(avatarImageView)
        
        // Name Label 設定
        nameLabel.font = .systemFont(ofSize: 24, weight: .medium)
        nameLabel.textColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(nameLabel)
        
        // KOKO ID Label 設定
        kokoIdLabel.font = .systemFont(ofSize: 16, weight: .regular)
        kokoIdLabel.textColor = .darkGray
        kokoIdLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(kokoIdLabel)
        
        // Header 內部元件的 AutoLayout
        NSLayoutConstraint.activate([
            // Avatar ImageView Constraints (右側)
            avatarImageView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -30),
            avatarImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Name Label Constraints (左側)
            nameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 30),
            nameLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 25),
            nameLabel.trailingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: -15),
            
            // KOKO ID Label Constraints (左側)
            kokoIdLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            kokoIdLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            kokoIdLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
        ])
        
        // 設定為 TableView 的 Header
        tableView.tableHeaderView = headerView
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .white
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FriendCell")
        view.addSubview(tableView)
        
        // TableView Constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateHeaderView() {
        nameLabel.text = viewModel.userName
        kokoIdLabel.text = "KOKO ID：\(viewModel.userKokoId)"
    }
}

// MARK: - UITableViewDataSource

extension FriendsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0 // 暫時返回 0，之後會加入好友列表資料
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

