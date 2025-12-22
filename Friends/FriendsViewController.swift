//
//  ViewController.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit
import Combine

class FriendsViewController: UIViewController {
    
    // MARK: - Properties
    
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
    private let emptyStateView = UIView()
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 當螢幕尺寸改變時，重新調整 header 佈局
        updateHeaderLayout()
    }
    
    // MARK: - Setup
    
    private func setupViewModel() {
        // 使用 Combine 訂閱選項變更
        viewModel.$selectedOption
            .receive(on: DispatchQueue.main)
            .sink { [weak self] option in
                // 更新選單狀態
                self?.menuButton?.menu = self?.viewModel.createMenu()
                // 顯示 loading 並載入資料
                self?.showLoading()
                self?.viewModel.loadFriendsData(for: option)
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱資料載入完成
        viewModel.dataLoadedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateHeaderView()
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱好友資料載入完成
        viewModel.friendsDataLoadedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateUIState()
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
                self?.loadingIndicator.stopAnimating()
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
        viewModel.selectOption(viewModel.selectedOption)
    }
    
    private func updateUIState() {
        // 根據實際載入的好友資料數量決定 UI 顯示狀態
        tableView.isHidden = false
        
        if viewModel.hasFriends {
            // 有好友資料，隱藏空狀態
            emptyStateView.isHidden = true
        } else {
            // 無好友資料，在 TableView 上顯示空狀態畫面
            emptyStateView.isHidden = false
        }
    }
    
    private func showLoading() {
        // 統一使用 loadingIndicator 顯示載入狀態
        emptyStateView.isHidden = true
        tableView.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    @objc private func handleRefresh() {
        // 下拉刷新：不調用 showLoading，refreshControl 會自動顯示
        viewModel.loadFriendsData(for: viewModel.selectedOption)
    }
}

// MARK: - UITableViewDataSource

extension FriendsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.isRequestSection(indexPath.section) {
            // Requests section
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendRequestTableViewCell.identifier, for: indexPath) as! FriendRequestTableViewCell
            if let friend = viewModel.friendRequest(at: indexPath.row) {
                cell.configure(with: friend)
            }
            return cell
        } else {
            // Friends section
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendTableViewCell.identifier, for: indexPath) as! FriendTableViewCell
            if let friend = viewModel.confirmedFriend(at: indexPath.row) {
                cell.configure(with: friend)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeader(in: section)
    }
}

// MARK: - UITableViewDelegate

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UI Layout

extension FriendsViewController {
    
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
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        setupTableView()
        setupHeaderView()
        setupEmptyStateView()
        setupLoadingIndicator()
    }
    
    private func setupHeaderView() {
        // Header View 設定
        headerView.backgroundColor = .systemBackground
        
        // Avatar ImageView 設定
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 30
        avatarImageView.backgroundColor = .systemGray5
        headerView.addSubview(avatarImageView)
        
        // Name Label 設定
        nameLabel.font = .systemFont(ofSize: 24, weight: .medium)
        nameLabel.textColor = .label
        headerView.addSubview(nameLabel)
        
        // KOKO ID Label 設定
        kokoIdLabel.font = .systemFont(ofSize: 16, weight: .regular)
        kokoIdLabel.textColor = .secondaryLabel
        headerView.addSubview(kokoIdLabel)
        
        // 先設定 headerView 的 frame（tableHeaderView 需要明確的尺寸）
        let headerHeight: CGFloat = 100
        let headerWidth = view.bounds.width
        headerView.frame = CGRect(x: 0, y: 0, width: headerWidth, height: headerHeight)
        
        // 使用 frame-based layout 設定子視圖位置
        let avatarSize: CGFloat = 60
        let horizontalPadding: CGFloat = 30
        let topPadding: CGFloat = 25
        
        // Avatar 位置（右側）
        avatarImageView.frame = CGRect(
            x: headerWidth - horizontalPadding - avatarSize,
            y: (headerHeight - avatarSize) / 2,
            width: avatarSize,
            height: avatarSize
        )
        
        // Name Label 位置（左側）
        let labelMaxWidth = headerWidth - horizontalPadding * 2 - avatarSize - 15
        nameLabel.frame = CGRect(
            x: horizontalPadding,
            y: topPadding,
            width: labelMaxWidth,
            height: 30
        )
        
        // KOKO ID Label 位置（左側）
        kokoIdLabel.frame = CGRect(
            x: horizontalPadding,
            y: nameLabel.frame.maxY + 5,
            width: labelMaxWidth,
            height: 20
        )
        
        // 設定為 TableView 的 Header
        tableView.tableHeaderView = headerView
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        
        // 設定 Cell 高度
        tableView.estimatedRowHeight = 80
        
        // 設定下拉更新
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // 註冊自訂 Cells
        tableView.register(FriendTableViewCell.self, forCellReuseIdentifier: FriendTableViewCell.identifier)
        tableView.register(FriendRequestTableViewCell.self, forCellReuseIdentifier: FriendRequestTableViewCell.identifier)
        
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
    
    private func updateHeaderLayout() {
        guard let headerView = tableView.tableHeaderView else { return }
        
        let headerHeight: CGFloat = 100
        let headerWidth = view.bounds.width
        
        // 只有當寬度改變時才更新
        guard headerView.frame.width != headerWidth else { return }
        
        headerView.frame.size.width = headerWidth
        
        let avatarSize: CGFloat = 60
        let horizontalPadding: CGFloat = 30
        
        // 更新 Avatar 位置（右側）
        avatarImageView.frame = CGRect(
            x: headerWidth - horizontalPadding - avatarSize,
            y: (headerHeight - avatarSize) / 2,
            width: avatarSize,
            height: avatarSize
        )
        
        // 更新 Label 位置（左側）
        let labelMaxWidth = headerWidth - horizontalPadding * 2 - avatarSize - 15
        nameLabel.frame.size.width = labelMaxWidth
        kokoIdLabel.frame.size.width = labelMaxWidth
        
        // 重新設定 tableHeaderView 以觸發更新
        tableView.tableHeaderView = headerView
    }
    
    private func setupEmptyStateView() {
        emptyStateView.backgroundColor = .systemBackground
        
        // 圖示
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "person.2.slash")
        iconImageView.tintColor = .systemGray3
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(iconImageView)
        
        // 文字標籤
        let messageLabel = UILabel()
        messageLabel.text = "尚無好友"
        messageLabel.font = .systemFont(ofSize: 20, weight: .medium)
        messageLabel.textColor = .systemGray
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(messageLabel)
        
        // 設置為 tableView 的 backgroundView
        tableView.backgroundView = emptyStateView
        emptyStateView.isHidden = true
        
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -30),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Message
            messageLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemGray
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}


