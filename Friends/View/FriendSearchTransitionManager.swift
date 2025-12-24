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
        let targetY = navBarMaxY + view.safeAreaInsets.top
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
    
    func deactivateSearch(
        placeholderSearchBar: UISearchBar,
        realSearchController: UISearchController,
        tableView: UITableView,
        in viewController: UIViewController,
        friendsSectionIndex: Int
    ) {
        guard isUsingRealSearchController else { return }
        
        // 建立快照
        guard let snapshotView = realSearchController.searchBar.snapshotView(afterScreenUpdates: false) else {
            deactivateRealSearchControllerWithoutAnimation(
                viewController: viewController,
                tableView: tableView
            )
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
            // 尋找目標 Placeholder Cell 位置
            let searchBarIndexPath = IndexPath(row: 0, section: friendsSectionIndex)
            
            if let cell = tableView.cellForRow(at: searchBarIndexPath) {
                let targetFrame = cell.convert(cell.bounds, to: view)
                
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
                        placeholderSearchBar.alpha = 1
                    }
                }
            } else {
                snapshotView.removeFromSuperview()
                placeholderSearchBar.alpha = 1
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
