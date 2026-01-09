//
//  FriendRequestCardView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

/// 堆疊卡片樣式
class FriendRequestCardView: UIView {
    
    // UI 元件
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "imgFriendsFemaleDefault")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = DesignConstants.Colors.lightGrey
        return label
    }()
    
    private let invitationLabel: UILabel = {
        let label = UILabel()
        label.text = "邀請你成為好友：）"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = DesignConstants.Colors.warmGrey
        return label
    }()
    
    private lazy var acceptButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .normal)
        button.tintColor = DesignConstants.Colors.hotPink
        button.backgroundColor = DesignConstants.Colors.background
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    private lazy var rejectButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = DesignConstants.Colors.warmGrey
        button.backgroundColor = DesignConstants.Colors.background
        button.layer.borderWidth = 2
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupUI()
        updateButtonColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: FriendRequestCardView, _: UITraitCollection) in
            self?.updateButtonColors()
            self?.layer.borderColor = DesignConstants.Colors.divider.cgColor
        }
    }
    
    private func setupUI() {
        backgroundColor = DesignConstants.Colors.background
        layer.borderWidth = 0.5
        layer.borderColor = DesignConstants.Colors.divider.cgColor
        
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(invitationLabel)
        addSubview(acceptButton)
        addSubview(rejectButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let horizontalPadding: CGFloat = 15
        let avatarSize: CGFloat = 40
        let buttonSize: CGFloat = 30
        
        // Avatar
        avatarImageView.frame = CGRect(
            x: horizontalPadding,
            y: (bounds.height - avatarSize) / 2,
            width: avatarSize,
            height: avatarSize
        )
        
        // Buttons (右側)
        rejectButton.frame = CGRect(
            x: bounds.width - horizontalPadding - buttonSize,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )
        
        acceptButton.frame = CGRect(
            x: rejectButton.frame.minX - 15 - buttonSize,
            y: (bounds.height - buttonSize) / 2,
            width: buttonSize,
            height: buttonSize
        )
        
        // Labels
        let labelX = avatarImageView.frame.maxX + 15
        let labelMaxWidth = acceptButton.frame.minX - labelX - 15
        
        nameLabel.frame = CGRect(
            x: labelX,
            y: 15,
            width: labelMaxWidth,
            height: 18
        )
        
        invitationLabel.frame = CGRect(
            x: labelX,
            y: nameLabel.frame.maxY + 3,
            width: labelMaxWidth,
            height: 15
        )
        
        updateButtonColors()
        layer.borderColor = DesignConstants.Colors.divider.cgColor
    }
    
    func configure(with friend: Friend) {
        nameLabel.text = friend.name
        avatarImageView.image = UIImage(named: "imgFriendsFemaleDefault")
    }
    
    private func updateButtonColors() {
        acceptButton.layer.borderColor = DesignConstants.Colors.hotPink.resolvedColor(with: traitCollection).cgColor
        rejectButton.layer.borderColor = DesignConstants.Colors.warmGrey.resolvedColor(with: traitCollection).cgColor
    }
}
