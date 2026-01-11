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
    
    private let addFriendButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "icBtnAddFriends"), for: .normal)
        return button
    }()
    
    // MARK: - Setup
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .koCellBackground
        contentView.backgroundColor = .koCellBackground
        
        contentView.addSubview(addFriendButton)
        addFriendButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addFriendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            addFriendButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addFriendButton.widthAnchor.constraint(equalToConstant: 24),
            addFriendButton.heightAnchor.constraint(equalToConstant: 24)
        ])
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
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20), // 增加左側間距以匹配整體設計
            searchBar.trailingAnchor.constraint(equalTo: addFriendButton.leadingAnchor, constant: -10),
            searchBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

