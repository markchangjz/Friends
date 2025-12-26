//
//  PlaceholderSearchBarTableViewCell.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

class PlaceholderSearchBarTableViewCell: UITableViewCell {
    
    static let identifier = "PlaceholderSearchBarTableViewCell"
    
    // MARK: - Properties
    
    private var searchBar: UISearchBar?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground
    }
    
    // MARK: - Configuration
    
    func configure(with searchBar: UISearchBar) {
        // 如果已經是同一個 searchBar，不需要重新配置
        if self.searchBar === searchBar {
            return
        }
        
        // 移除舊的 searchBar（如果有）
        self.searchBar?.removeFromSuperview()
        
        // 設定新的 searchBar
        self.searchBar = searchBar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

