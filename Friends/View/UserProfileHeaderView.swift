//
//  UserProfileHeaderView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

class UserProfileHeaderView: UIView {
    
    // MARK: - Constants
    
    private let headerHeight: CGFloat = 100
    private let avatarSize: CGFloat = 60
    private let horizontalPadding: CGFloat = 30
    private let topPadding: CGFloat = 25
    
    // MARK: - UI Components
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let kokoIdLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init(width: CGFloat) {
        self.init(frame: CGRect(x: 0, y: 0, width: width, height: 100))
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Avatar ImageView 設定
        avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
        avatarImageView.tintColor = .systemGray3
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarSize / 2
        avatarImageView.backgroundColor = .systemGray5
        addSubview(avatarImageView)
        
        // Name Label 設定
        nameLabel.font = .systemFont(ofSize: 24, weight: .medium)
        nameLabel.textColor = .label
        addSubview(nameLabel)
        
        // KOKO ID Label 設定
        kokoIdLabel.font = .systemFont(ofSize: 16, weight: .regular)
        kokoIdLabel.textColor = .secondaryLabel
        addSubview(kokoIdLabel)
        
        updateLayout()
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    private func updateLayout() {
        let width = bounds.width
        
        // Avatar 位置（右側）
        avatarImageView.frame = CGRect(
            x: width - horizontalPadding - avatarSize,
            y: (headerHeight - avatarSize) / 2,
            width: avatarSize,
            height: avatarSize
        )
        
        // Name Label 位置（左側）
        let labelMaxWidth = width - horizontalPadding * 2 - avatarSize - 15
        nameLabel.frame = CGRect(
            x: horizontalPadding,
            y: topPadding,
            width: labelMaxWidth,
            height: 30
        )
        
        // KOKO ID Label 位置（左側）
        kokoIdLabel.frame = CGRect(
            x: horizontalPadding,
            y: nameLabel.frame.maxY + 5,
            width: labelMaxWidth,
            height: 20
        )
    }
    
    func updateLayout(for width: CGFloat) {
        frame.size.width = width
        updateLayout()
    }
    
    // MARK: - Configuration
    
    func configure(name: String, kokoId: String) {
        nameLabel.text = name
        kokoIdLabel.text = "KOKO ID：\(kokoId)"
    }
}

