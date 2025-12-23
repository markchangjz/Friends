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
    
    // 追蹤是否正在使用真實的 searchController
    private var isUsingRealSearchController = false
    
    // UI 元件
    private lazy var userProfileHeaderView = UserProfileHeaderView(width: view.bounds.width)
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
        updateUserProfileHeaderLayout()
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
        // 如果是好友請求 section，根據展開狀態決定是否顯示資料
        if viewModel.isRequestSection(section) {
            return viewModel.isRequestsSectionExpanded ? viewModel.numberOfRows(in: section) : 0
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = viewModel.titleForHeader(in: section) else {
            return nil
        }
        
        let headerView = SectionHeaderView()
        headerView.delegate = self
        
        // Requests section 可折疊，Friends section 不可折疊
        if viewModel.isRequestSection(section) {
            headerView.configure(title: title, isExpanded: viewModel.isRequestsSectionExpanded)
        } else {
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
        
        tableView.performBatchUpdates({
            tableView.reloadSections(IndexSet(integer: FriendsViewModel.Section.requests), with: .automatic)
        }, completion: nil)
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
        updateEmptyState()
        deactivateRealSearchController()
    }
    
    private func activateRealSearchController() {
        guard let snapshotView = placeholderSearchBar.snapshotView(afterScreenUpdates: false) else {
            activateRealSearchControllerWithoutAnimation()
            return
        }
        
        let searchBarFrame = placeholderSearchBar.convert(placeholderSearchBar.bounds, to: view)
        snapshotView.frame = searchBarFrame
        snapshotView.contentMode = .scaleAspectFit
        snapshotView.clipsToBounds = true
        view.addSubview(snapshotView)
        
        isUsingRealSearchController = true
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        scrollToFriendsSection()
        
        let navBarMaxY = navigationController?.navigationBar.frame.maxY ?? 0
        let targetY = navBarMaxY + view.safeAreaInsets.top
        let targetFrame = CGRect(
            x: searchBarFrame.origin.x,
            y: targetY,
            width: searchBarFrame.width,
            height: searchBarFrame.height
        )
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            snapshotView.frame = targetFrame
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut) {
            snapshotView.alpha = 0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            snapshotView.removeFromSuperview()
            
            self.navigationItem.searchController = self.searchController
            self.navigationItem.hidesSearchBarWhenScrolling = false
            
            self.view.layoutIfNeeded()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.searchController.searchBar.becomeFirstResponder()
                
                if !self.searchController.searchBar.isFirstResponder {
                    self.searchController.isActive = true
                }
            }
        }
    }
    
    private func activateRealSearchControllerWithoutAnimation() {
        isUsingRealSearchController = true
        
        scrollToFriendsSection()
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        DispatchQueue.main.async { [weak self] in
            self?.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    private func scrollToFriendsSection() {
        guard viewModel.friendsSection < viewModel.numberOfSections else { return }
        
        let sectionRect = tableView.rect(forSection: viewModel.friendsSection)
        let targetY = sectionRect.origin.y - tableView.adjustedContentInset.top
        
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
        guard let snapshotView = searchController.searchBar.snapshotView(afterScreenUpdates: false) else {
            deactivateRealSearchControllerWithoutAnimation()
            return
        }
        
        let searchBarFrame = searchController.searchBar.convert(searchController.searchBar.bounds, to: view)
        snapshotView.frame = searchBarFrame
        snapshotView.contentMode = .scaleAspectFit
        snapshotView.clipsToBounds = true
        view.addSubview(snapshotView)
        
        navigationItem.searchController = nil
        
        isUsingRealSearchController = false
        
        placeholderSearchBar.alpha = 0
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let searchBarIndexPath = IndexPath(row: 0, section: self.viewModel.friendsSection)
            
            if let cell = self.tableView.cellForRow(at: searchBarIndexPath) {
                let targetFrame = cell.convert(cell.bounds, to: self.view)
                
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.85,
                    initialSpringVelocity: 0.5,
                    options: [.curveEaseOut, .allowUserInteraction]
                ) {
                    snapshotView.frame = targetFrame
                } completion: { _ in
                    snapshotView.removeFromSuperview()
                    
                    UIView.animate(withDuration: 0.2) {
                        self.placeholderSearchBar.alpha = 1
                    }
                }
            } else {
                snapshotView.removeFromSuperview()
                self.placeholderSearchBar.alpha = 1
            }
        }
    }
    
    private func deactivateRealSearchControllerWithoutAnimation() {
        navigationItem.searchController = nil
        isUsingRealSearchController = false
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
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
    }
    
    private func setupSearchBarContainer() {
        let placeholder = "想轉一筆給誰呢？"
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = placeholder
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        
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
        tableView.tableHeaderView = userProfileHeaderView
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 80
        
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        tableView.register(PlaceholderSearchBarTableViewCell.self, forCellReuseIdentifier: PlaceholderSearchBarTableViewCell.identifier)
        tableView.register(FriendTableViewCell.self, forCellReuseIdentifier: FriendTableViewCell.identifier)
        tableView.register(FriendRequestTableViewCell.self, forCellReuseIdentifier: FriendRequestTableViewCell.identifier)
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateUserProfileHeaderView() {
        userProfileHeaderView.configure(name: viewModel.userName, kokoId: viewModel.userKokoId)
    }
    
    private func updateUserProfileHeaderLayout() {
        guard let headerView = tableView.tableHeaderView as? UserProfileHeaderView else { return }
        
        let headerWidth = view.bounds.width
        
        guard headerView.frame.width != headerWidth else { return }
        
        headerView.updateLayout(for: headerWidth)
        tableView.tableHeaderView = headerView
    }
    
    private func setupEmptyStateView() {
        tableView.backgroundView = emptyStateView
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
