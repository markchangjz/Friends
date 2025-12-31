//
//  FriendSearchTransitionManager.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/24.
//

import UIKit

class FriendSearchTransitionManager {
    
    // MARK: - Properties
    
    // 追蹤是否正在使用真實的 searchController
    var isUsingRealSearchController = false
    
    // MARK: - Public Methods
    
    func activateSearch(
        placeholderSearchBar: UISearchBar,
        realSearchController: UISearchController,
        tableView: UITableView,
        in viewController: UIViewController,
        friendsSectionIndex: Int
    ) {
        // 防止重複觸發
        guard !isUsingRealSearchController else { return }
        
        // 建立快照
        guard let snapshotView = placeholderSearchBar.snapshotView(afterScreenUpdates: false) else {
            activateRealSearchControllerWithoutAnimation(
                realSearchController: realSearchController,
                tableView: tableView,
                viewController: viewController,
                friendsSectionIndex: friendsSectionIndex
            )
            return
        }
        
        let view = viewController.view!
        
        // 設定快照初始位置
        let searchBarFrame = placeholderSearchBar.convert(placeholderSearchBar.bounds, to: view)
        snapshotView.frame = searchBarFrame
        snapshotView.contentMode = .scaleAspectFit
        snapshotView.clipsToBounds = true
        view.addSubview(snapshotView)
        
        isUsingRealSearchController = true
        
        // 重新整理 TableView 以移除 Placeholder Cell
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        // 滾動到搜尋區塊
        scrollToFriendsSection(tableView: tableView, section: friendsSectionIndex)
        
        // 計算目標位置 (NavigationBar 下方)
        let navBarMaxY = viewController.navigationController?.navigationBar.frame.maxY ?? 0
        let targetY = navBarMaxY  // navBarMaxY 已經包含了 safe area，不需要再加
        let targetFrame = CGRect(
            x: searchBarFrame.origin.x,
            y: targetY,
            width: searchBarFrame.width,
            height: searchBarFrame.height
        )
        
        // 執行位移動畫
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            snapshotView.frame = targetFrame
        }
        
        // 執行淡出動畫並完成轉場
        UIView.animate(withDuration: 0.25, delay: 0.1, options: .curveEaseOut) {
            snapshotView.alpha = 0
        } completion: { _ in            
            snapshotView.removeFromSuperview()
            
            viewController.navigationItem.searchController = realSearchController
            viewController.navigationItem.hidesSearchBarWhenScrolling = false
            
            view.layoutIfNeeded()
            
            // 延遲一點點讓 UI 穩定後再 Focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                realSearchController.searchBar.becomeFirstResponder()
                
                if !realSearchController.searchBar.isFirstResponder {
                    realSearchController.isActive = true
                }
            }
        }
    }
    
    func deactivateSearchWithHeaderAnimation(
        placeholderSearchBar: UISearchBar,
        realSearchController: UISearchController,
        tableView: UITableView,
        headerView: UIView,
        headerContainer: UIView,
        headerHeightConstraint: NSLayoutConstraint,
        targetHeaderHeight: CGFloat,
        targetContainerHeight: CGFloat,
        in viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        guard isUsingRealSearchController else { 
            completion?()
            return 
        }

        // 建立快照
        guard let snapshotView = realSearchController.searchBar.snapshotView(afterScreenUpdates: false) else {
            deactivateRealSearchControllerWithoutAnimation(
                viewController: viewController,
                tableView: tableView
            )
            completion?()
            return
        }

        let view = viewController.view!

        let searchBarFrame = realSearchController.searchBar.convert(realSearchController.searchBar.bounds, to: view)
        snapshotView.frame = searchBarFrame
        snapshotView.contentMode = .scaleAspectFit
        snapshotView.clipsToBounds = true
        view.addSubview(snapshotView)

        // 移除 SearchController
        viewController.navigationItem.searchController = nil
        isUsingRealSearchController = false

        // 準備讓 Placeholder 顯示
        placeholderSearchBar.alpha = 0
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }

        DispatchQueue.main.async {
            // 確保初始佈局正確
            headerView.layoutIfNeeded()
            
            // 計算動畫的起始和結束位置
            let safeAreaTop = view.safeAreaInsets.top
            let currentHeaderHeight = headerContainer.frame.height
            let startY = safeAreaTop + currentHeaderHeight
            let endY = safeAreaTop + targetContainerHeight
            
            let startFrame = CGRect(
                x: searchBarFrame.origin.x,
                y: startY,
                width: searchBarFrame.width,
                height: searchBarFrame.height
            )
            
            let endFrame = CGRect(
                x: searchBarFrame.origin.x,
                y: endY,
                width: searchBarFrame.width,
                height: searchBarFrame.height
            )
            
            // 設定快照的起始位置
            snapshotView.frame = startFrame
            
            // 更新約束
            headerHeightConstraint.constant = targetHeaderHeight
            
            // 同步執行 header 縮小動畫和搜尋列位移動畫
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.5,
                options: [.curveEaseOut, .allowUserInteraction]
            ) {
                // Header 縮小動畫
                headerContainer.frame.size.height = targetContainerHeight
                headerContainer.layoutIfNeeded()
                headerView.layoutIfNeeded()
                
                // 搜尋列跟隨動畫
                snapshotView.frame = endFrame
                
                // 更新 TableView header
                tableView.tableHeaderView = headerContainer
            } completion: { _ in
                snapshotView.removeFromSuperview()

                UIView.animate(withDuration: 0.2) {
                    placeholderSearchBar.alpha = 1
                } completion: { _ in
                    completion?()
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func activateRealSearchControllerWithoutAnimation(
        realSearchController: UISearchController,
        tableView: UITableView,
        viewController: UIViewController,
        friendsSectionIndex: Int
    ) {
        isUsingRealSearchController = true
        
        scrollToFriendsSection(tableView: tableView, section: friendsSectionIndex)
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
        
        viewController.navigationItem.searchController = realSearchController
        viewController.navigationItem.hidesSearchBarWhenScrolling = false
        
        DispatchQueue.main.async { 
            realSearchController.searchBar.becomeFirstResponder()
        }
    }
    
    private func deactivateRealSearchControllerWithoutAnimation(
        viewController: UIViewController,
        tableView: UITableView
    ) {
        viewController.navigationItem.searchController = nil
        isUsingRealSearchController = false
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
    }
    
    private func scrollToFriendsSection(tableView: UITableView, section: Int) {
        guard section < tableView.numberOfSections else { return }
        
        let sectionRect = tableView.rect(forSection: section)
        let targetY = sectionRect.origin.y - tableView.adjustedContentInset.top
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            tableView.contentOffset = CGPoint(x: 0, y: targetY)
        }
    }
}
