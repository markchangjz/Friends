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
    
    // UI 元件
    private lazy var userProfileHeaderView = UserProfileHeaderView(width: view.bounds.width)
    private let tabSwitchView = TabSwitchView()
    private let tableView = UITableView()
    private let emptyStateView = EmptyStateView()
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
        setupTableHeaderView()
        updateTableViewContentInset()
    }
    
    private func setupTableHeaderView() {
        // 如果已經設定過且寬度相同，就不需要重新設定
        if let existingHeader = tableView.tableHeaderView,
           existingHeader.frame.width == view.bounds.width {
            return
        }
        
        // 根據設計稿：總高度 192，扣除 safe area (44 navigation bar + 20 狀態列 = 64) = 128
        let containerHeight: CGFloat = 128  // 192 - 64
        
        // 建立容器 View 包含 header 和 tab switch
        let containerView = UIView()
        containerView.backgroundColor = DesignConstants.Colors.background
        
        containerView.addSubview(userProfileHeaderView)
        containerView.addSubview(tabSwitchView)
        
        userProfileHeaderView.translatesAutoresizingMaskIntoConstraints = false
        tabSwitchView.translatesAutoresizingMaskIntoConstraints = false
        
        // UserProfileHeaderView 高度：設計稿中 Tab 切換在 y: 164，扣除 safe area 64 = 100
        // TabSwitchView 高度 = 28
        let userProfileHeaderHeight: CGFloat = 100  // 164 - 64 = 100
        
        NSLayoutConstraint.activate([
            userProfileHeaderView.topAnchor.constraint(equalTo: containerView.topAnchor),
            userProfileHeaderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            userProfileHeaderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            userProfileHeaderView.heightAnchor.constraint(equalToConstant: userProfileHeaderHeight),
            
            tabSwitchView.topAnchor.constraint(equalTo: userProfileHeaderView.bottomAnchor),
            tabSwitchView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tabSwitchView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tabSwitchView.heightAnchor.constraint(equalToConstant: 28),
            tabSwitchView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // 設定初始 frame
        containerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: containerHeight)
        
        // 強制布局計算
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
        
        // 更新 header view 的 layout，傳入 safe area 資訊以調整內容位置
        userProfileHeaderView.updateLayout(for: view.bounds.width, safeAreaTop: 64)
        
        // 重新設定 frame 確保正確
        containerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: containerHeight)
        tableView.tableHeaderView = containerView
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
            return configureRequestCell(for: indexPath)
        }
        
        if viewModel.isSearchBarRow(at: indexPath) {
            return configureSearchBarCell(for: indexPath)
        }
        
        return configureFriendCell(for: indexPath)
    }
    
    private func configureRequestCell(for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FriendRequestTableViewCell.identifier, for: indexPath) as? FriendRequestTableViewCell else {
            return UITableViewCell()
        }
        let friend = viewModel.friendRequest(at: indexPath.row)
        cell.configure(with: friend)
        return cell
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
        
        let friend = viewModel.confirmedFriend(at: indexPath.row)
        cell.configure(with: friend)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = viewModel.titleForHeader(in: section)
        
        let headerView = SectionHeaderView()
        headerView.delegate = self
        
        // Requests section 可折疊，Friends section 不可折疊
        if viewModel.isRequestSection(section) {
            headerView.configure(title: title, isExpanded: viewModel.isRequestsSectionExpanded)
        } else {
            // Friends section 不可折疊，傳入 nil
            headerView.configure(title: title, isExpanded: nil)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
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

// MARK: - SectionHeaderViewDelegate

extension FriendsViewController: SectionHeaderViewDelegate {
    func sectionHeaderViewDidTap(_ headerView: SectionHeaderView) {
        viewModel.isRequestsSectionExpanded.toggle()
        headerView.updateArrowImage(isExpanded: viewModel.isRequestsSectionExpanded)
        
        tableView.reloadSections(IndexSet(integer: FriendsViewModel.Section.requests), with: .automatic)
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
            friendsSectionIndex: viewModel.friendsSection
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
            friendsSectionIndex: viewModel.friendsSection
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
        tableView.register(FriendRequestTableViewCell.self, forCellReuseIdentifier: FriendRequestTableViewCell.identifier)
        
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
