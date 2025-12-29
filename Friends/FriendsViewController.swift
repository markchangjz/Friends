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
    
    // 搜尋控制器（用於實際搜尋）
    private let searchController = UISearchController()
    
    // 假的搜尋列（顯示在 cell 中）
    private let placeholderSearchBar = UISearchBar()
    
    // Transition Manager
    private let transitionManager = FriendSearchTransitionManager()
    
    // 追蹤是否為首次載入 Requests
    private var isFirstRequestsLoad = true
    
    // UI 元件
    private lazy var userProfileHeaderView = UserProfileHeaderView(width: view.bounds.width)
    private let tabSwitchView = TabSwitchView()
    private let tableView = UITableView()
    private let emptyStateView = EmptyStateView()
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Header Container (保持持久引用以避免重複重建)
    private lazy var tableHeaderContainerView: UIView = {
        let container = UIView()
        container.backgroundColor = DesignConstants.Colors.background
        container.addSubview(userProfileHeaderView)
        container.addSubview(tabSwitchView)
        
        userProfileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        tabSwitchView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            userProfileHeaderView.topAnchor.constraint(equalTo: container.topAnchor),
            userProfileHeaderView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            userProfileHeaderView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            userProfileHeaderViewHeightConstraint,
            
            tabSwitchView.topAnchor.constraint(equalTo: userProfileHeaderView.bottomAnchor),
            tabSwitchView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tabSwitchView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tabSwitchView.heightAnchor.constraint(equalToConstant: 28),
            tabSwitchView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }()
    
    private lazy var userProfileHeaderViewHeightConstraint: NSLayoutConstraint = {
        userProfileHeaderView.heightAnchor.constraint(equalToConstant: 100)
    }()

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
        setupTableHeaderView()
        updateTableViewContentInset()
    }
    
    private func setupTableHeaderView() {
        updateHeaderLayout(animated: false)
    }
    
    /// 更新或初始化 TableHeaderView
    private func updateHeaderLayout(animated: Bool = false) {
        let width = view.bounds.width
        guard width > 0 else { return }
        
        let hasRequests = viewModel.hasFriendRequests
        let requestCount = viewModel.displayRequestFriends.count
        let userProfileHeight = userProfileHeaderView.calculateHeight(
            hasRequests: hasRequests,
            isExpanded: viewModel.isRequestsSectionExpanded,
            requestCount: requestCount
        )
        
        let tabSwitchHeight: CGFloat = 28
        let containerHeight = userProfileHeight + tabSwitchHeight
        
        // 更新高度約束
        userProfileHeaderViewHeightConstraint.constant = userProfileHeight
        
        if animated {
            // 在動畫開始前，先確保卡片有正確的初始位置（無動畫）
            userProfileHeaderView.ensureInitialLayout()
            view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                // 在動畫塊內觸發佈局更新
                self.tableHeaderContainerView.frame = CGRect(x: 0, y: 0, width: width, height: containerHeight)
                self.tableHeaderContainerView.layoutIfNeeded()
                self.userProfileHeaderView.layoutIfNeeded()
            } completion: { _ in
                // 動畫完成後重新設定 tableHeaderView 以確保正確
                self.tableView.tableHeaderView = self.tableHeaderContainerView
            }
        } else {
            tableHeaderContainerView.frame = CGRect(x: 0, y: 0, width: width, height: containerHeight)
            userProfileHeaderView.updateLayout(for: width, safeAreaTop: 64)
            tableHeaderContainerView.layoutIfNeeded()
            tableView.tableHeaderView = tableHeaderContainerView
        }
    }
    
    /// 重新建立 TableHeaderView（保留相容性，但內部改用 updateHeaderLayout）
    private func rebuildTableHeaderView() {
        updateHeaderLayout(animated: true)
    }
    
    private func updateTableViewContentInset() {
        let safeAreaTop = view.safeAreaInsets.top
        tableView.contentInset = UIEdgeInsets(top: safeAreaTop, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
    
    // MARK: - Private Methods
    
    private func setupViewModel() {
        // 使用 Combine 訂閱選項變更
        // 使用 dropFirst() 跳過初始值，避免在 setupViewModel 時就觸發載入
        viewModel.$selectedOption
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] option in
                guard let self else { return }
                // 更新選單狀態
                navigationItem.leftBarButtonItem?.menu = viewModel.createMenu()
                // 重置首次載入標記（因為切換選項時會重新載入資料）
                isFirstRequestsLoad = true
                // 顯示 loading 並同時載入使用者資料和好友資料
                showLoading()
                viewModel.loadAllData(for: option)
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱使用者資料載入完成
        viewModel.userProfileDataLoadedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                updateUserProfileHeaderView()
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱好友資料載入完成
        viewModel.friendsDataLoadedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                updateRequestsSection()
                updateEmptyState()
                tableView.reloadData()
                refreshControl.endRefreshing()
                loadingIndicator.stopAnimating()
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱錯誤
        viewModel.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self else { return }
                showErrorAlert(message: error.localizedDescription)
            }
            .store(in: &cancellables)
    }
    
    private func loadData() {
        showLoading()
        viewModel.loadAllData(for: viewModel.selectedOption)
    }
    
    private func updateEmptyState() {
        // 只有在沒有原始資料時才顯示「尚無好友」
        // 如果有原始資料但搜尋結果為空，只顯示空白 TableView
        tableView.isHidden = false
        emptyStateView.isHidden = viewModel.hasFriends
    }
    
    private func showLoading() {
        emptyStateView.isHidden = true
        tableView.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "錯誤", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func handleRefresh() {
        viewModel.loadFriendsData(for: viewModel.selectedOption)
    }
    
    /// 更新 Requests Section
    private func updateRequestsSection() {
        userProfileHeaderView.configureRequests(
            viewModel.displayRequestFriends,
            isExpanded: viewModel.isRequestsSectionExpanded
        )
        
        // 首次載入時不使用動畫，避免出現由左往右的動畫
        if isFirstRequestsLoad {
            isFirstRequestsLoad = false
            updateHeaderLayout(animated: false)
        } else {
            rebuildTableHeaderView()
        }
    }
}

// MARK: - UITableViewDataSource

extension FriendsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // 只有 Friends section（Requests 已移到 header）
        return viewModel.hasConfirmedFriends ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 好友列表：加上搜尋列 (如果沒有使用真實 SearchController)
        let searchBarCount = viewModel.isUsingRealSearchController ? 0 : 1
        return viewModel.displayConfirmedFriends.count + searchBarCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearchBarRow(at: indexPath) {
            return configureSearchBarCell(for: indexPath)
        }
        
        return configureFriendCell(for: indexPath)
    }
    
    private func isSearchBarRow(at indexPath: IndexPath) -> Bool {
        return !viewModel.isUsingRealSearchController && indexPath.row == 0
    }
    
    private func configureSearchBarCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlaceholderSearchBarTableViewCell.identifier, for: indexPath) as? PlaceholderSearchBarTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: placeholderSearchBar)
        return cell
    }
    
    private func configureFriendCell(for indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FriendTableViewCell.identifier, for: indexPath) as? FriendTableViewCell else {
            return UITableViewCell()
        }
        
        // 如果有 placeholder search bar，索引需要減 1
        let friendIndex = viewModel.isUsingRealSearchController ? indexPath.row : indexPath.row - 1
        let friend = viewModel.displayConfirmedFriends[friendIndex]
        cell.configure(with: friend)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension FriendsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        viewModel.searchText = searchText
        viewModel.filterFriends()
        updateEmptyState()
        tableView.reloadData()
    }
}

// MARK: - UserProfileHeaderViewDelegate

extension FriendsViewController: UserProfileHeaderViewDelegate {
    func userProfileHeaderViewDidTapRequests(_ headerView: UserProfileHeaderView) {
        // 記錄切換前的狀態
        let wasExpanded = viewModel.isRequestsSectionExpanded
        
        // 確保當前佈局是最新的（起始狀態 - 切換前的狀態）
        userProfileHeaderView.ensureInitialLayout()
        view.layoutIfNeeded()
        
        // 切換狀態
        viewModel.isRequestsSectionExpanded.toggle()
        userProfileHeaderView.setExpandedState(viewModel.isRequestsSectionExpanded)
        
        // 計算目標高度
        let width = view.bounds.width
        let hasRequests = viewModel.hasFriendRequests
        let requestCount = viewModel.displayRequestFriends.count
        let userProfileHeight = userProfileHeaderView.calculateHeight(
            hasRequests: hasRequests,
            isExpanded: viewModel.isRequestsSectionExpanded,
            requestCount: requestCount
        )
        let tabSwitchHeight: CGFloat = 28
        let containerHeight = userProfileHeight + tabSwitchHeight
        
        // 更新約束常數
        userProfileHeaderViewHeightConstraint.constant = userProfileHeight
        
        // 在動畫開始前，先暫時恢復到切換前的狀態來布局起始位置
        // 這很重要，因為卡片從折疊狀態（有 horizontalInset）到展開狀態（無 horizontalInset）時，
        // 如果起始位置不正確，會出現由右到左的動畫
        userProfileHeaderView.setExpandedState(wasExpanded)
        userProfileHeaderView.ensureInitialLayout()
        view.layoutIfNeeded()
        
        // 再設定回目標狀態（但不立即布局，讓動畫來處理）
        userProfileHeaderView.setExpandedState(viewModel.isRequestsSectionExpanded)
        
        // 動畫到目標狀態
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            // 更新容器高度
            self.tableHeaderContainerView.frame.size.height = containerHeight
            self.tableHeaderContainerView.layoutIfNeeded()
            
            // 使用 beginUpdates/endUpdates 強制 TableView 重新計算 Header 高度並動畫
            self.tableView.beginUpdates()
            self.tableView.tableHeaderView = self.tableHeaderContainerView
            self.tableView.endUpdates()
        }
    }
}

// MARK: - UISearchBarDelegate

extension FriendsViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar === placeholderSearchBar {
            activateRealSearchController()
            return false
        }
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.clearSearch()
        viewModel.isUsingRealSearchController = false
        updateEmptyState()
        
        transitionManager.deactivateSearch(
            placeholderSearchBar: placeholderSearchBar,
            realSearchController: searchController,
            tableView: tableView,
            in: self,
            friendsSectionIndex: 0  // 現在只有一個 section
        )
        
        // 重新載入 TableView 以顯示 Search Bar
        tableView.reloadData()
    }
    
    private func activateRealSearchController() {
        viewModel.isUsingRealSearchController = true
        transitionManager.activateSearch(
            placeholderSearchBar: placeholderSearchBar,
            realSearchController: searchController,
            tableView: tableView,
            in: self,
            friendsSectionIndex: 0  // 現在只有一個 section
        )
    }
}

// MARK: - UI Setup

extension FriendsViewController {
    
    private func setupNavigationBar() {
        let menuButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: nil,
            action: nil
        )
        
        menuButton.menu = viewModel.createMenu()
        navigationItem.leftBarButtonItem = menuButton
        
        // 設定 Navigation Bar 背景色與 Header View 一致（支援 Dark Mode）
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = DesignConstants.Colors.background
        appearance.shadowColor = .clear // 移除底部陰影線
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        }
    }
    
    private func setupSearchBarContainer() {
        let placeholder = "想轉一筆給誰呢？"
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = placeholder
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        
        // 設定搜尋列樣式
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = DesignConstants.Typography.searchPlaceholderFont()
            textField.textColor = DesignConstants.Colors.lightGrey
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: DesignConstants.Colors.steel,
                    .font: DesignConstants.Typography.searchPlaceholderFont(),
                    .kern: -0.3376471
                ]
            )
            textField.backgroundColor = DesignConstants.Colors.searchBarBackground
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
        
        placeholderSearchBar.searchBarStyle = .minimal
        placeholderSearchBar.placeholder = placeholder
        placeholderSearchBar.isUserInteractionEnabled = true
        placeholderSearchBar.delegate = self
        
        // 設定 placeholder search bar 樣式
        if let textField = placeholderSearchBar.value(forKey: "searchField") as? UITextField {
            textField.font = DesignConstants.Typography.searchPlaceholderFont()
            textField.textColor = DesignConstants.Colors.lightGrey
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: DesignConstants.Colors.steel,
                    .font: DesignConstants.Typography.searchPlaceholderFont(),
                    .kern: -0.3376471
                ]
            )
            textField.backgroundColor = DesignConstants.Colors.searchBarBackground
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
    }
    
    private func setupUI() {
        view.backgroundColor = DesignConstants.Colors.background
        
        // 設定 delegate
        userProfileHeaderView.delegate = self
        
        setupTableView()
        setupSearchBarContainer()
        setupEmptyStateView()
        setupLoadingIndicator()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = DesignConstants.Colors.background
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 80
        tableView.separatorColor = DesignConstants.Colors.divider
        tableView.contentInsetAdjustmentBehavior = .never
        
        // 設置 refreshControl 的背景色（透過 tintColor 和背景視圖）
        refreshControl.tintColor = DesignConstants.Colors.lightGrey
        refreshControl.backgroundColor = DesignConstants.Colors.background
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.register(PlaceholderSearchBarTableViewCell.self, forCellReuseIdentifier: PlaceholderSearchBarTableViewCell.identifier)
        tableView.register(FriendTableViewCell.self, forCellReuseIdentifier: FriendTableViewCell.identifier)
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 設定初始 contentInset
        updateTableViewContentInset()
        
        // Header 會在 viewDidLayoutSubviews 中設定
    }
    
    private func updateUserProfileHeaderView() {
        userProfileHeaderView.configure(name: viewModel.userName, kokoId: viewModel.userKokoId)
    }
    
    private func setupEmptyStateView() {
        // 設定為 tableFooterView 以便與 Header 同步滾動
        emptyStateView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 600)
        tableView.tableFooterView = emptyStateView
        emptyStateView.isHidden = true
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
