//
//  FriendTableViewCell.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit

class FriendTableViewCell: UITableViewCell {
    
    static let identifier = "FriendTableViewCell"
    
    // UI 元件
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.crop.circle")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = .systemYellow
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemOrange
        label.text = "邀請中"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(starImageView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            // Star (靠左，有星號時顯示)
            starImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            starImageView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 14),
            starImageView.heightAnchor.constraint(equalToConstant: 14),
            
            // Avatar (對齊 FriendRequestTableViewCell 的位置)
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 14),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name label
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 15),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -12),
            
            // Status label
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with friend: Friend) {
        nameLabel.text = friend.name
        
        // 設定預設頭像
        avatarImageView.image = UIImage(systemName: "person.crop.circle")
        avatarImageView.tintColor = .systemGray3
        
        // 根據 isTop 決定是否顯示星星
        starImageView.isHidden = !friend.isTop
        
        // status = .pending 顯示邀請中
        let isPending = friend.status == .pending
        statusLabel.isHidden = !isPending
        statusLabel.text = isPending ? "邀請中" : nil
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        avatarImageView.image = nil
        starImageView.isHidden = true
        statusLabel.isHidden = true
        statusLabel.text = "邀請中"
    }
}
