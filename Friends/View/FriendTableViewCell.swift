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
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star.fill")
        imageView.tintColor = DesignConstants.Colors.starBackground
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private let transferButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("轉帳", for: .normal)
        button.titleLabel?.font = DesignConstants.Typography.buttonFont()
        button.setTitleColor(DesignConstants.Colors.hotPink, for: .normal)
        button.layer.borderWidth = 1.2
        button.layer.borderColor = DesignConstants.Colors.hotPink.cgColor
        button.layer.cornerRadius = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        // 使用較粗的圖標配置，根據設計稿 ic_friends_more 的粗度
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = DesignConstants.Colors.buttonBorderGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let invitationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("邀請中", for: .normal)
        button.titleLabel?.font = DesignConstants.Typography.invitationButtonFont()
        button.setTitleColor(DesignConstants.Colors.warmGrey, for: .normal)
        button.layer.borderWidth = 1.2
        button.layer.borderColor = DesignConstants.Colors.buttonBorderGray.cgColor
        button.layer.cornerRadius = 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    // 動態約束：轉帳按鈕的 trailingAnchor
    private var transferToMoreConstraint: NSLayoutConstraint?
    private var transferToInvitationConstraint: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        updateBorderColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: FriendTableViewCell, _: UITraitCollection) in
            self?.updateBorderColors()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        updateBorderColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: FriendTableViewCell, _: UITraitCollection) in
            self?.updateBorderColors()
        }
    }
    
    private func setupUI() {
        // 設定 Cell 背景色（支援 Dark Mode）
        backgroundColor = DesignConstants.Colors.cellBackground
        contentView.backgroundColor = DesignConstants.Colors.cellBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = DesignConstants.Colors.cellBackground
        
        contentView.addSubview(starImageView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(transferButton)
        contentView.addSubview(moreButton)
        contentView.addSubview(invitationButton)
        
        NSLayoutConstraint.activate([
            // Star (靠左，有星號時顯示，根據設計稿位置在 x: 30)
            starImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            starImageView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: DesignConstants.Spacing.starSize),
            starImageView.heightAnchor.constraint(equalToConstant: DesignConstants.Spacing.starSize),
            
            // Avatar (根據設計稿 x: 50)
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 50),
            avatarImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: DesignConstants.Spacing.friendAvatarSize),
            avatarImageView.heightAnchor.constraint(equalToConstant: DesignConstants.Spacing.friendAvatarSize),
            
            // Name label (根據設計稿 x: 105)
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 15),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: transferButton.leadingAnchor, constant: -12),
            
            // Transfer button (根據設計稿 47x24)
            transferButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            transferButton.widthAnchor.constraint(equalToConstant: 47),
            transferButton.heightAnchor.constraint(equalToConstant: 24),
            
            // More button
            moreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            moreButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            moreButton.widthAnchor.constraint(equalToConstant: 18),
            moreButton.heightAnchor.constraint(equalToConstant: 4),
            
            // Invitation button (根據設計稿 60x24)
            invitationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            invitationButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            invitationButton.widthAnchor.constraint(equalToConstant: 60),
            invitationButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // 設置動態約束（初始狀態：轉帳按鈕 -> 更多按鈕）
        transferToMoreConstraint = transferButton.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -15)
        transferToInvitationConstraint = transferButton.trailingAnchor.constraint(equalTo: invitationButton.leadingAnchor, constant: -15)
        transferToMoreConstraint?.isActive = true
    }
    
    func configure(with friend: Friend) {
        nameLabel.text = friend.name
        
        // 設定預設頭像
        avatarImageView.image = UIImage(named: "imgFriendsFemaleDefault")
        
        // 根據 isTop 決定是否顯示星星
        starImageView.isHidden = !friend.isTop
        
        // status = .pending 顯示轉帳按鈕和邀請中按鈕，否則顯示轉帳按鈕和更多按鈕
        let isPending = friend.status == .pending
        invitationButton.isHidden = !isPending
        moreButton.isHidden = isPending
        transferButton.isHidden = false  // 轉帳按鈕始終顯示
        
        // 切換約束：邀請中狀態時轉帳按鈕對齊邀請中按鈕，否則對齊更多按鈕
        // 切換約束：必須先解除目前的約束，避免同時啟用導致衝突
        transferToMoreConstraint?.isActive = false
        transferToInvitationConstraint?.isActive = false
        
        // 再根據狀態啟用正確的約束
        if isPending {
            transferToInvitationConstraint?.isActive = true
        } else {
            transferToMoreConstraint?.isActive = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        avatarImageView.image = nil
        starImageView.isHidden = true
        invitationButton.isHidden = true
        transferButton.isHidden = false
        moreButton.isHidden = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 確保邊框顏色在 layout 時也是正確的
        updateBorderColors()
    }
    
    // MARK: - Private Methods
    
    /// 更新按鈕邊框顏色（處理 Dark Mode 切換）
    private func updateBorderColors() {
        invitationButton.layer.borderColor = DesignConstants.Colors.buttonBorderGray.resolvedColor(with: traitCollection).cgColor
    }
}
