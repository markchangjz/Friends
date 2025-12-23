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
    
    // 搜尋控制器（用於實際搜尋）
    private let searchController = UISearchController(searchResultsController: nil)
    
    // 假的搜尋列（顯示在 cell 中）
    private let placeholderSearchBar = UISearchBar()
    
    // 追蹤是否正在使用真實的 searchController
    private var isUsingRealSearchController = false
    
    // 追蹤 Requests section 是否展開
    private var isRequestsSectionExpanded = true
    
    // 計算好友 section 的索引
    private var friendsSection: Int {
        return viewModel.friendRequests.isEmpty ? 0 : 1
    }
    
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
        // 如果是好友請求 section，根據展開狀態決定是否顯示資料
        if viewModel.isRequestSection(section) {
            return isRequestsSectionExpanded ? viewModel.numberOfRows(in: section) : 0
        } else {
            // 如果正在使用真實的 searchController，不顯示假 searchBar cell
            let searchBarCount = isUsingRealSearchController ? 0 : 1
            return viewModel.numberOfRows(in: section) + searchBarCount
        }
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
            if !isUsingRealSearchController && indexPath.row == 0 {
                // 第一個 row 顯示假的搜尋列（只在未使用真實 searchController 時）
                let cell = tableView.dequeueReusableCell(withIdentifier: PlaceholderSearchBarTableViewCell.identifier, for: indexPath) as! PlaceholderSearchBarTableViewCell
                cell.configure(with: placeholderSearchBar)
                return cell
            } else {
                // 顯示好友資料
                // 如果沒有使用真實 searchController，索引需要 -1（因為 row 0 是假 searchBar）
                let friendIndex = isUsingRealSearchController ? indexPath.row : indexPath.row - 1
                
                let cell = tableView.dequeueReusableCell(withIdentifier: FriendTableViewCell.identifier, for: indexPath) as! FriendTableViewCell
                if let friend = viewModel.confirmedFriend(at: friendIndex) {
                    cell.configure(with: friend)
                }
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForHeader(in: section)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // 只為 Requests section 創建自定義 header
        guard viewModel.isRequestSection(section),
              let title = viewModel.titleForHeader(in: section) else {
            return nil
        }
        
        let headerView = RequestsSectionHeaderView()
        headerView.delegate = self
        headerView.configure(title: title, isExpanded: isRequestsSectionExpanded)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // 為 Requests section 設置固定高度
        if viewModel.isRequestSection(section) {
            return 44
        }
        return UITableView.automaticDimension
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
    
    private func setupSearchBarContainer() {
        let placeholder = "想轉一筆給誰呢？"
        
        // 設置真實的搜尋控制器（UISearchController）
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = placeholder
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        
        // 不要一開始就加入導航欄，等點擊假 searchBar 時再加入
        
        // 設置假的搜尋列（顯示在 cell 中）
        placeholderSearchBar.searchBarStyle = .minimal
        placeholderSearchBar.placeholder = placeholder
        placeholderSearchBar.isUserInteractionEnabled = true
        placeholderSearchBar.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        setupTableView()
        setupHeaderView()
        setupSearchBarContainer()
        setupEmptyStateView()
        setupLoadingIndicator()
    }
    
    private func setupHeaderView() {
        // Header View 設定
        headerView.backgroundColor = .systemBackground
        
        // Avatar ImageView 設定
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = .systemGray3
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
        tableView.register(PlaceholderSearchBarTableViewCell.self, forCellReuseIdentifier: PlaceholderSearchBarTableViewCell.identifier)
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

// MARK: - UISearchResultsUpdating

extension FriendsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // 更新 ViewModel 的搜尋文字並立即過濾
        let searchText = searchController.searchBar.text ?? ""
        viewModel.searchText = searchText
        viewModel.filterFriends()
        updateUIState()
        tableView.reloadData()
    }
}

// MARK: - RequestsSectionHeaderViewDelegate

extension FriendsViewController: RequestsSectionHeaderViewDelegate {
    func requestsSectionHeaderViewDidTap(_ headerView: RequestsSectionHeaderView) {
        // 切換展開狀態
        isRequestsSectionExpanded.toggle()
        
        // 更新 header view 的箭頭圖示
        headerView.updateArrowImage(isExpanded: isRequestsSectionExpanded)
        
        // 取得 Requests section 的索引
        let requestsSection = 0
        
        // 使用動畫更新 section
        tableView.performBatchUpdates({
            tableView.reloadSections(IndexSet(integer: requestsSection), with: .automatic)
        }, completion: nil)
    }
}

// MARK: - UISearchBarDelegate

extension FriendsViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // 如果是假的 searchBar（placeholder），切換到真實的 UISearchController
        if searchBar === placeholderSearchBar {
            activateRealSearchController()
            return false // 不讓假 searchBar 進入編輯狀態
        }
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // 當取消搜尋時，清空搜尋文字並回到假 searchBar
        viewModel.searchText = ""
        viewModel.filterFriends()
        updateUIState()
        deactivateRealSearchController()
    }
    
    private func activateRealSearchController() {
        // 創建假 searchBar 的快照用於動畫
        guard let snapshotView = placeholderSearchBar.snapshotView(afterScreenUpdates: false) else {
            // 如果無法創建快照，直接切換
            activateRealSearchControllerWithoutAnimation()
            return
        }
        
        // 獲取假 searchBar 在螢幕上的位置
        let searchBarFrame = placeholderSearchBar.convert(placeholderSearchBar.bounds, to: view)
        snapshotView.frame = searchBarFrame
        snapshotView.contentMode = .scaleAspectFit  // 防止內容被拉伸
        snapshotView.clipsToBounds = true
        view.addSubview(snapshotView)
        
        // 標記正在使用真實的 searchController
        isUsingRealSearchController = true
        
        // 立即隱藏假 searchBar cell（無動畫）
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        // 先滾動到好友 section 頂部
        scrollToFriendsSection()
        
        // 計算目標位置（導航欄下方）
        // 保持原始高度，只改變 Y 位置
        let navBarMaxY = navigationController?.navigationBar.frame.maxY ?? 0
        let targetY = navBarMaxY + view.safeAreaInsets.top
        let targetFrame = CGRect(
            x: searchBarFrame.origin.x,
            y: targetY,
            width: searchBarFrame.width,
            height: searchBarFrame.height
        )
        
        // 執行位移動畫（使用彈簧動畫）
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            snapshotView.frame = targetFrame
        }
        
        // 同時執行淡出動畫
        UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut) {
            snapshotView.alpha = 0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            // 移除快照
            snapshotView.removeFromSuperview()
            
            // 動畫完成後才設定 UISearchController
            self.navigationItem.searchController = self.searchController
            self.navigationItem.hidesSearchBarWhenScrolling = false
            
            // 強制佈局更新
            self.view.layoutIfNeeded()
            
            // 激活搜尋控制器並開啟鍵盤
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // 方法 1：直接激活 searchBar
                self.searchController.searchBar.becomeFirstResponder()
                
                // 方法 2：如果方法 1 不行，使用 isActive
                if !self.searchController.searchBar.isFirstResponder {
                    self.searchController.isActive = true
                }
            }
        }
    }
    
    private func activateRealSearchControllerWithoutAnimation() {
        // 標記正在使用真實的 searchController
        isUsingRealSearchController = true
        
        // 先滾動到好友 section 頂部
        scrollToFriendsSection()
        
        // Reload tableView 以隱藏假 searchBar cell
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        // 將 UISearchController 加入導航欄
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        // 立即激活搜尋列
        DispatchQueue.main.async { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    private func scrollToFriendsSection() {
        guard friendsSection < viewModel.numberOfSections else { return }
        
        // 滾動到好友 section 的頂部（包含 header）
        let sectionRect = tableView.rect(forSection: friendsSection)
        let targetY = sectionRect.origin.y - tableView.adjustedContentInset.top
        
        // 使用彈簧動畫滾動
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction]
        ) { [weak self] in
            self?.tableView.contentOffset = CGPoint(x: 0, y: targetY)
        }
    }
    
    private func deactivateRealSearchController() {
        // 創建真實 searchBar 的快照用於動畫
        guard let snapshotView = searchController.searchBar.snapshotView(afterScreenUpdates: false) else {
            // 如果無法創建快照，直接切換
            deactivateRealSearchControllerWithoutAnimation()
            return
        }
        
        // 獲取真實 searchBar 在螢幕上的位置
        let searchBarFrame = searchController.searchBar.convert(searchController.searchBar.bounds, to: view)
        snapshotView.frame = searchBarFrame
        snapshotView.contentMode = .scaleAspectFit  // 防止內容被拉伸
        snapshotView.clipsToBounds = true
        view.addSubview(snapshotView)
        
        // 立即移除 UISearchController（無動畫）
        navigationItem.searchController = nil
        
        // 標記不再使用真實的 searchController
        isUsingRealSearchController = false
        
        // Reload tableView 以顯示假 searchBar cell（先隱藏）
        placeholderSearchBar.alpha = 0
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        // 計算目標位置（假 searchBar cell 的位置）
        // 需要等 tableView reload 完成後才能獲取正確位置
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 找到假 searchBar cell 的位置
            let searchBarIndexPath = IndexPath(row: 0, section: self.friendsSection)
            
            // 確保 cell 存在
            if let cell = self.tableView.cellForRow(at: searchBarIndexPath) {
                let targetFrame = cell.convert(cell.bounds, to: self.view)
                
                // 執行位移動畫（使用彈簧動畫）
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.85,
                    initialSpringVelocity: 0.5,
                    options: [.curveEaseOut, .allowUserInteraction]
                ) {
                    snapshotView.frame = targetFrame
                } completion: { _ in
                    // 移除快照
                    snapshotView.removeFromSuperview()
                    
                    // 淡入顯示假 searchBar
                    UIView.animate(withDuration: 0.2) {
                        self.placeholderSearchBar.alpha = 1
                    }
                }
            } else {
                // 如果找不到 cell，直接移除快照並顯示假 searchBar
                snapshotView.removeFromSuperview()
                self.placeholderSearchBar.alpha = 1
            }
        }
    }
    
    private func deactivateRealSearchControllerWithoutAnimation() {
        // 從導航欄移除 UISearchController
        navigationItem.searchController = nil
        
        // 標記不再使用真實的 searchController
        isUsingRealSearchController = false
        
        // Reload tableView 以顯示假 searchBar cell
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
    }
}


