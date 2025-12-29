//
//  FriendRequestTableViewCell.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit

class FriendRequestTableViewCell: UITableViewCell {
    
    static let identifier = "FriendRequestTableViewCell"
    
    // UI 元件
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "imgFriendsFemaleDefault")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = DesignConstants.Typography.friendNameFont()
        label.textColor = DesignConstants.Colors.lightGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let invitationLabel: UILabel = {
        let label = UILabel()
        label.text = "邀請你成為好友：）"
        label.font = DesignConstants.Typography.kokoIdFont()
        label.textColor = DesignConstants.Colors.warmGrey
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var acceptButton: UIButton = {
        let button = UIButton(type: .system)
        // 設定較小的圖示尺寸，避免被邊框切到
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .normal)
        button.tintColor = DesignConstants.Colors.hotPink
        button.backgroundColor = DesignConstants.Colors.background
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 15  // 寬高為 30，設為 15 形成正圓
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var rejectButton: UIButton = {
        let button = UIButton(type: .system)
        // 設定較小的圖示尺寸，避免被邊框切到
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = DesignConstants.Colors.warmGrey
        button.backgroundColor = DesignConstants.Colors.background
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 15  // 寬高為 30，設為 15 形成正圓
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        updateButtonColors()
        setupTraitObservation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        updateButtonColors()
        setupTraitObservation()
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(invitationLabel)
        contentView.addSubview(acceptButton)
        contentView.addSubview(rejectButton)
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            
            // Invitation Label
            invitationLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 15),
            invitationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            invitationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
            
            // Reject Button
            rejectButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            rejectButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rejectButton.widthAnchor.constraint(equalToConstant: 30),
            rejectButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Accept Button
            acceptButton.trailingAnchor.constraint(equalTo: rejectButton.leadingAnchor, constant: -15),
            acceptButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            acceptButton.widthAnchor.constraint(equalToConstant: 30),
            acceptButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with friend: Friend) {
        nameLabel.text = friend.name
        
        // 設定預設頭像
        avatarImageView.image = UIImage(named: "imgFriendsFemaleDefault")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        avatarImageView.image = nil
    }
    
    /// 設定 Trait 變化觀察（iOS 17+ 新 API）
    private func setupTraitObservation() {
        // 使用新的 trait change registration API
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            // 當外觀模式改變時（Light/Dark Mode），更新邊框顏色
            self.updateButtonColors()
        }
    }
    
    /// 更新按鈕邊框顏色（支援 Dark Mode）
    private func updateButtonColors() {
        // 更新 acceptButton 邊框顏色
        acceptButton.layer.borderColor = DesignConstants.Colors.hotPink.resolvedColor(with: traitCollection).cgColor
        
        // 更新 rejectButton 邊框顏色
        rejectButton.layer.borderColor = DesignConstants.Colors.warmGrey.resolvedColor(with: traitCollection).cgColor
    }
}
