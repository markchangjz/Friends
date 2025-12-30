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
    
    // 追蹤鍵盤高度造成的 inset
    private var currentKeyboardInset: CGFloat = 0
    
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
        setupKeyboardHandling()
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
        let safeAreaBottom = view.safeAreaInsets.bottom
        
        // 內容 Inset：必須完整避開鍵盤與 Safe Area
        let contentBottomInset = max(currentKeyboardInset, safeAreaBottom)
        tableView.contentInset = UIEdgeInsets(top: safeAreaTop, left: 0, bottom: contentBottomInset, right: 0)
        
        // 修正初始位移：如果目前的 offset 為 0 或大於 -safeAreaTop（代表內容被 safeArea 遮擋），則調整為 -safeAreaTop
        // 這通常發生在視圖剛載入或 safeArea 變更時，確保 Header 不會被 Navigation Bar 遮住
        if safeAreaTop > 0 && tableView.contentOffset.y > -safeAreaTop {
            tableView.contentOffset = CGPoint(x: 0, y: -safeAreaTop)
        }
        
        // Indicator Inset：
        // 將 Top Inset 設為 view.safeAreaInsets.top，這會讓 Indicator 完美的從 Navigation Bar 下緣開始。
        // 下緣則避開鍵盤。
        let indicatorBottomInset = currentKeyboardInset > 0 ? max(0, currentKeyboardInset - safeAreaBottom) : safeAreaBottom
        
        tableView.scrollIndicatorInsets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: indicatorBottomInset,
            right: 0
        )
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
                // 使用異步更新選單狀態，確保 menu 關閉後再更新
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.navigationItem.leftBarButtonItem?.menu = self.viewModel.createMenu()
                }
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
        
        if viewModel.hasFriends {
            // 有資料時，移除 tableFooterView 以消除空白
            emptyStateView.isHidden = true
            tableView.tableFooterView = nil
        } else {
            // 無資料時，設定 tableFooterView 顯示 EmptyStateView
            emptyStateView.isHidden = false
            
            // 計算 EmptyStateView 實際需要的內容高度
            // 根據約束計算：topOffset(30) + illustration(172) + title(40) + titleHeight + subtitle(8) + subtitleHeight + button(25) + button(40) + help(37) + helpHeight + bottom(20)
            // 使用 systemLayoutSizeFitting 來計算實際高度
            emptyStateView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
            emptyStateView.setNeedsLayout()
            emptyStateView.layoutIfNeeded()
            
            // 計算實際需要的尺寸（根據約束）
            let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
            let fittingSize = emptyStateView.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            
            // 設定 frame 為實際內容高度
            emptyStateView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: fittingSize.height)
            tableView.tableFooterView = emptyStateView
        }
    }
    
    private func showLoading() {
        emptyStateView.isHidden = true
        // 清除 Footer 以避免佔用高度導致與 Header 相加超過螢幕高度而出現 Scroll Bar
        tableView.tableFooterView = nil
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
        
        // 更新 badge 數量（使用未過濾的 pending 數量，確保搜尋時數字不變）
        tabSwitchView.updateBadgeCount(viewModel.pendingFriendCount)
        
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
            let cell = configureSearchBarCell(for: indexPath)
            // 隱藏 Search Bar Cell 的分隔線
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        }
        
        let cell = configureFriendCell(for: indexPath)
        // 設定分隔線 leading 跟 nameLabel leading 一樣 (50 + 40 + 15 = 105)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 105, bottom: 0, right: 0)
        return cell
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
        // 搜尋關鍵字更新時，同步更新 cardViews 過濾結果
        updateRequestsSection()
        updateEmptyState()
        tableView.reloadData()
    }
}

// MARK: - UserProfileHeaderViewDelegate

extension FriendsViewController: UserProfileHeaderViewDelegate {
    func userProfileHeaderViewDidTapRequests(_ headerView: UserProfileHeaderView) {
        // 如果正在搜尋，不允許折疊
        guard !viewModel.isSearching else { return }
        
        // 記錄切換前的狀態
        let wasExpanded = viewModel.isRequestsSectionExpanded
        
        // 確保當前佈局是最新的（起始狀態 - 切換前的狀態）
        userProfileHeaderView.ensureInitialLayout()
        view.layoutIfNeeded()
        
        // 切換狀態
        viewModel.isRequestsSectionExpanded.toggle()
        userProfileHeaderView.setExpandedState(viewModel.isRequestsSectionExpanded)
        
        // 計算目標高度
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
        // 結束搜尋時，恢復原本折疊狀態
        viewModel.stopSearching()
        userProfileHeaderView.cancelForceExpand()
        
        // 立即同步 UserProfileHeaderView 的狀態（但不立即更新佈局）
        userProfileHeaderView.setExpandedState(viewModel.isRequestsSectionExpanded)
        
        // 計算目標 header 高度
        let hasRequests = viewModel.hasFriendRequests
        let requestCount = viewModel.displayRequestFriends.count
        let targetHeaderHeight = userProfileHeaderView.calculateHeight(
            hasRequests: hasRequests,
            isExpanded: viewModel.isRequestsSectionExpanded,
            requestCount: requestCount
        )
        let tabSwitchHeight: CGFloat = 28
        let targetContainerHeight = targetHeaderHeight + tabSwitchHeight
        
        transitionManager.deactivateSearchWithHeaderAnimation(
            placeholderSearchBar: placeholderSearchBar,
            realSearchController: searchController,
            tableView: tableView,
            headerView: userProfileHeaderView,
            headerContainer: tableHeaderContainerView,
            headerHeightConstraint: userProfileHeaderViewHeightConstraint,
            targetHeaderHeight: targetHeaderHeight,
            targetContainerHeight: targetContainerHeight,
            in: self,
            completion: { [weak self] in
                // 動畫完成後更新空白狀態
                self?.updateEmptyState()
            }
        )
    }
    
    private func activateRealSearchController() {
        viewModel.isUsingRealSearchController = true
        // 開始搜尋時，強制展開 cardViews
        viewModel.startSearching()
        if viewModel.hasFriendRequests {
            userProfileHeaderView.forceExpand()
            // 更新 header layout 以反映展開狀態
            updateHeaderLayout(animated: true)
        }
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
        menuButton.tintColor = .label
        menuButton.menu = viewModel.createMenu()
        
        let fixedSpaceButton = UIBarButtonItem(systemItem: .fixedSpace)
        
        let withdrawButton = UIBarButtonItem(
            image: UIImage(named: "icNavPinkWithdraw")?.withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: nil,
            action: nil
        )
        
        let transferButton = UIBarButtonItem(
            image: UIImage(named: "icNavPinkTransfer")?.withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationItem.leftBarButtonItems = [withdrawButton, transferButton, fixedSpaceButton, menuButton]
        
        let scanButton = UIBarButtonItem(
            image: UIImage(named: "icNavPinkScan")?.withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: nil,
            action: nil
        )
        
        navigationItem.rightBarButtonItems = [scanButton]
        
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
            
            // 設定搜尋圖示顏色
            textField.leftView?.tintColor = DesignConstants.Colors.steel
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
        // 設定 frame 但不立即設為 footer，避免初始高度造成 ScrollIndicator 出現
        emptyStateView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 600)
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
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let convertedKeyboardFrame = view.convert(keyboardFrame, from: nil)
        let intersection = convertedKeyboardFrame.intersection(view.bounds)
        let bottomInset = intersection.isNull ? 0 : intersection.height
        
        currentKeyboardInset = bottomInset
        
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.updateTableViewContentInset()
            self.view.layoutIfNeeded()
        }
    }
}
