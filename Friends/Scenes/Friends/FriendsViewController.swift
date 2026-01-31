//
//  ViewController.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit
import Combine

class FriendsViewController: UIViewController {
    
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
        updateHeaderLayout()
        updateTableViewContentInset()
    }
    
    // MARK: - Properties
    
    private let viewModel = FriendsViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let transitionManager = FriendSearchTransitionManager()
    
    // 搜尋控制器（用於實際搜尋）
    private let searchController = UISearchController()
    
    // 假的搜尋列（顯示在 cell 中）
    private let placeholderSearchBar = UISearchBar()
    
    // 追蹤鍵盤高度造成的 inset
    private var currentKeyboardInset: CGFloat = 0
    
    // UI 元件
    private lazy var userProfileHeaderView = UserProfileHeaderView(width: view.bounds.width)
    private let tableView = UITableView()
    private let emptyStateView = EmptyStateView()
    private let refreshControl = UIRefreshControl()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let menuButton = UIBarButtonItem(
        image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
        style: .plain,
        target: nil,
        action: nil
    )
    
    // MARK: - ViewModel Setup
    
    private func setupViewModel() {
        // 使用 Combine 訂閱選項變更
        // 使用 dropFirst() 跳過初始值，避免在 setupViewModel 時就觸發載入
        viewModel.$selectedOption
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] option in
                guard let self else { return }
                menuButton.menu = viewModel.createMenu()
                // 顯示 loading 並同時載入使用者資料和好友資料
                viewModel.loadAllData(for: option)
            }
            .store(in: &cancellables)
        
        // 使用 Combine 訂閱狀態變更
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .idle:
                    break
                case .loading:
                    // 如果不是正在下拉更新，則顯示大 loading
                    if !refreshControl.isRefreshing {
                        showLoading()
                    }
                case .loaded:
                    // 資料載入完成，更新 UI
                    updateUserProfileHeaderView()
                    updateRequestsSection()
                    updateChatBadge()
                    updateTableViewForCurrentTab()
                    refreshControl.endRefreshing()
                    loadingIndicator.stopAnimating()
                case .error(let error):
                    refreshControl.endRefreshing()
                    loadingIndicator.stopAnimating()
                    showErrorAlert(message: error.localizedDescription)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        viewModel.loadAllData(for: viewModel.selectedOption)
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh(_ sender: UIRefreshControl) {
        viewModel.loadFriendsData(for: viewModel.selectedOption)
    }
    
    // MARK: - UI Update
    
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
            
            // 計算 EmptyStateView 實際需要的內容高度（根據約束）
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
    
    /// 更新聊天 Badge
    private func updateChatBadge() {
        userProfileHeaderView.updateTabSwitchBadgeCount(viewModel.chatBadgeCount, for: .chat)
    }
    
    /// 更新 Requests Section
    private func updateRequestsSection() {
        userProfileHeaderView.configureRequests(
            viewModel.displayRequestFriends,
            isExpanded: viewModel.isRequestsSectionExpanded
        )
        
        // 更新 badge 數量（使用未過濾的 pending 數量，確保搜尋時數字不變）
        userProfileHeaderView.updateTabSwitchBadgeCount(viewModel.pendingFriendCount, for: .friends)
        
        updateHeaderLayout()
    }
    
    private func updateUserProfileHeaderView() {
        userProfileHeaderView.configure(name: viewModel.userName, kokoId: viewModel.userKokoId)
    }
    
    /// 更新或初始化 TableHeaderView
    private func updateHeaderLayout() {
        let width = view.bounds.width
        guard width > 0 else { return }
        
        let hasRequests = viewModel.hasFriendRequests
        let requestCount = viewModel.displayRequestFriends.count
        let headerHeight = userProfileHeaderView.calculateHeight(
            hasRequests: hasRequests,
            isExpanded: viewModel.isRequestsSectionExpanded,
            requestCount: requestCount
        )
        
        // 更新佈局
        userProfileHeaderView.frame = CGRect(x: 0, y: 0, width: width, height: headerHeight)
        userProfileHeaderView.updateLayout(for: width, safeAreaTop: 64)
        // 確保 view 的佈局已經更新完成，避免 table view 位置跑掉
        view.layoutIfNeeded()
        userProfileHeaderView.layoutIfNeeded()
        
        tableView.tableHeaderView = userProfileHeaderView
        // 更新 scrollIndicatorInsets 以確保底部對齊
        // 但在下拉更新完成後的短時間內跳過，避免干擾回彈動畫
        if !refreshControl.isRefreshing {
            updateTableViewContentInset()
        }
    }
    
    private func updateTableViewContentInset() {
        let safeAreaTop = view.safeAreaInsets.top
        let safeAreaBottom = view.safeAreaInsets.bottom
        
        // 內容 Inset：必須完整避開鍵盤、Safe Area 和自訂 TabBar
        // 鍵盤顯示時會覆蓋 TabBar，所以用 max(鍵盤高度, TabBar高度)
        let tabBarInset = CustomTabBarView.calculateTabBarInset(safeAreaBottom: safeAreaBottom)
        let contentBottomInset = max(currentKeyboardInset, tabBarInset)
        tableView.contentInset = UIEdgeInsets(top: safeAreaTop, left: 0, bottom: contentBottomInset, right: 0)
        
        // 修正初始位移：如果目前的 offset 為 0 或大於 -safeAreaTop（代表內容被 safeArea 遮擋），則調整為 -safeAreaTop
        // 這通常發生在視圖剛載入或 safeArea 變更時，確保 Header 不會被 Navigation Bar 遮住
        if safeAreaTop > 0 && tableView.contentOffset.y > -safeAreaTop {
            tableView.contentOffset = CGPoint(x: 0, y: -safeAreaTop)
        }
        
        // Indicator Inset：
        // 1. 停用自動調整（在 setupTableView 中設定），避免系統重複加入 Safe Area
        // 2. 為了讓滾動條與內容正確對齊，verticalScrollIndicatorInsets 應該與 contentInset 的 top 和 bottom 保持一致
        // 3. 這樣滾動條會在導覽列下方開始，並在 tab bar 頂部結束
        let indicatorInsets = UIEdgeInsets(
            top: safeAreaTop,
            left: 0,
            bottom: contentBottomInset,
            right: 0
        )
        tableView.verticalScrollIndicatorInsets = indicatorInsets
    }
    
    // MARK: - Private
    
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
    
    private func updateTableViewForCurrentTab() {
        switch viewModel.currentTab {
        case .friends:
            // 恢復顯示好友資料
            updateEmptyState()
            tableView.reloadData()
        case .chat:
            // 顯示「無資料」文字
            showChatEmptyState()
        }
    }
    
    private func showChatEmptyState() {
        // 創建一個簡單的「無資料」標籤作為 tableFooterView
        let emptyLabel = UILabel()
        emptyLabel.text = "無資料"
        emptyLabel.font = .systemFont(ofSize: 16, weight: .regular)
        emptyLabel.textColor = .koLightGrey
        emptyLabel.textAlignment = .center
        emptyLabel.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 200)
        
        tableView.tableFooterView = emptyLabel
        tableView.reloadData()
    }
    
    private func activateRealSearchController() {
        viewModel.isUsingRealSearchController = true
        // 開始搜尋時，強制展開 cardViews
        viewModel.startSearching()
        if viewModel.hasFriendRequests {
            userProfileHeaderView.forceExpand()
            // 更新 header layout 以反映展開狀態
            updateHeaderLayout()
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

// MARK: - UITableViewDataSource

extension FriendsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        switch viewModel.currentTab {
        case .chat:
            // 如果當前是聊天 tab，不顯示任何 section
            return 0
        case .friends:
            // 只有 Friends section（Requests 已移到 header）
            return viewModel.hasConfirmedFriends ? 1 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.currentTab {
        case .chat:
            // 如果當前是聊天 tab，不顯示任何 row
            return 0
        case .friends:
            // 好友列表：加上搜尋列 (如果沒有使用真實 SearchController)
            let searchBarCount = viewModel.isUsingRealSearchController ? 0 : 1
            return viewModel.displayConfirmedFriends.count + searchBarCount
        }
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
        cell.separatorInset = UIEdgeInsets(top: 0, left: 105, bottom: 0, right: 20)
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
        viewModel.filterFriends(name: searchText)
        // 搜尋關鍵字更新時，同步更新 cardViews 過濾結果
        updateRequestsSection()
        tableView.reloadData()
    }
}

// MARK: - UserProfileHeaderViewDelegate

extension FriendsViewController: UserProfileHeaderViewDelegate {
    func userProfileHeaderView(_ headerView: UserProfileHeaderView, didSelectTab tab: TabSwitchView.Tab) {
        viewModel.currentTab = tab
        updateTableViewForCurrentTab()
    }
    
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
        let headerHeight = userProfileHeaderView.calculateHeight(
            hasRequests: hasRequests,
            isExpanded: viewModel.isRequestsSectionExpanded,
            requestCount: requestCount
        )
        
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
            // 更新 header 高度
            self.userProfileHeaderView.frame.size.height = headerHeight
            self.userProfileHeaderView.layoutIfNeeded()
            
            // 使用 beginUpdates/endUpdates 強制 TableView 重新計算 Header 高度並動畫
            self.tableView.beginUpdates()
            self.tableView.tableHeaderView = self.userProfileHeaderView
            self.tableView.endUpdates()
        } completion: { _ in
            // 動畫完成後更新 scrollIndicatorInsets 以確保底部對齊
            self.updateTableViewContentInset()
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
        
        // 更新 header view 的卡片以反映清除搜尋後的完整列表
        // 這必須在計算高度之前完成，否則 header 會有不匹配的高度和卡片數量
        userProfileHeaderView.configureRequests(
            viewModel.displayRequestFriends,
            isExpanded: viewModel.isRequestsSectionExpanded
        )
        
        // 計算目標 header 高度（已包含 tabSwitchView）
        let hasRequests = viewModel.hasFriendRequests
        let requestCount = viewModel.displayRequestFriends.count
        let targetHeaderHeight = userProfileHeaderView.calculateHeight(
            hasRequests: hasRequests,
            isExpanded: viewModel.isRequestsSectionExpanded,
            requestCount: requestCount
        )
        
        transitionManager.deactivateSearchWithHeaderAnimation(
            placeholderSearchBar: placeholderSearchBar,
            realSearchController: searchController,
            tableView: tableView,
            headerView: userProfileHeaderView,
            targetHeaderHeight: targetHeaderHeight,
            in: self,
            completion: { [weak self] in
                // 動畫完成後根據當前 tab 顯示正確的狀態
                self?.updateTableViewForCurrentTab()
            }
        )
    }
}

// MARK: - UI Setup

extension FriendsViewController {
    
    private func setupNavigationBar() {
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
    }
    
    private func setupSearchBarContainer() {
        let placeholder = "想轉一筆給誰呢？"
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = placeholder
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        
        // 使用 Appearance API 設定搜尋列樣式（避免使用 KVC）
        configureSearchBarAppearance(searchController.searchBar)
        
        placeholderSearchBar.searchBarStyle = .minimal
        placeholderSearchBar.placeholder = placeholder
        placeholderSearchBar.isUserInteractionEnabled = true
        placeholderSearchBar.delegate = self
        
        // 使用 Appearance API 設定 placeholder search bar 樣式
        configureSearchBarAppearance(placeholderSearchBar)
    }
    
    /// 使用公開 API 設定搜尋列樣式（使用 searchTextField，iOS 13+ 公開 API）
    private func configureSearchBarAppearance(_ searchBar: UISearchBar) {
        let placeholder = searchBar.placeholder ?? "想轉一筆給誰呢？"
        
        // 使用 searchTextField（公開 API，iOS 13+）
        let textField = searchBar.searchTextField
        textField.font = .systemFont(ofSize: 14, weight: .regular)
        textField.textColor = .koLightGrey
        textField.backgroundColor = .koSearchBarBackground
        textField.layer.cornerRadius = 10
        textField.clipsToBounds = true
        textField.leftView?.tintColor = .koSteel
        
        // 設定 placeholder 樣式
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.koSteel,
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ]
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: placeholderAttributes
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .koBackground
        
        // 設定 delegate
        userProfileHeaderView.delegate = self
        // 同步 TabSwitchView 的初始狀態與 ViewModel
        userProfileHeaderView.setInitialTab(viewModel.currentTab)
        
        setupTableView()
        setupSearchBarContainer()
        setupEmptyStateView()
        setupLoadingIndicator()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .koBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 80
        tableView.separatorColor = .koDivider
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.automaticallyAdjustsScrollIndicatorInsets = false
        
        if #available(iOS 26.0, *) {
            tableView.topEdgeEffect.style = .soft
            tableView.bottomEdgeEffect.style = .automatic
        }
        
        // 設置 refreshControl 的背景色（透過 tintColor 和背景視圖）
        refreshControl.tintColor = .koLightGrey
        refreshControl.backgroundColor = .koBackground
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
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
    }
    
    private func setupEmptyStateView() {
        // 初始設定，避免初始高度造成 ScrollIndicator 出現
        emptyStateView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0)
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

// MARK: - Keyboard Handling

extension FriendsViewController {
    
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
        
        // UIView.AnimationOptions 使用位元遮罩，動畫曲線值需要放在第 16-19 位
        // curveValue 是 0-3 的整數（對應 easeInOut, easeIn, easeOut, linear）
        // 左移 16 位才能正確轉換為 UIView.AnimationOptions 格式
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        
        UIView.animate(withDuration: duration, delay: 0, options: options) { [weak self] in
            guard let self else { return }
            self.updateTableViewContentInset()
            self.view.layoutIfNeeded()
        }
    }
}
