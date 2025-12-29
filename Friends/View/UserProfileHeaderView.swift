//
//  UserProfileHeaderView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

class UserProfileHeaderView: UIView {
    
    // MARK: - Constants
    
    private let avatarSize: CGFloat = 52
    private let horizontalPadding: CGFloat = 30
    // 設計稿中的絕對位置（相對於整個畫面，包含 safe area 64pt）
    private let designAvatarTop: CGFloat = 82  // 根據設計稿 y: 82
    private let designNameTop: CGFloat = 90    // 根據設計稿 y: 90
    private let designKokoIdTop: CGFloat = 116 // 根據設計稿 y: 116
    
    // MARK: - UI Components
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let kokoIdLabel = UILabel()
    private let chevronImageView = UIImageView()  // ">" 符號
    
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
    
    // 儲存 safe area 高度，用於計算相對位置
    private var safeAreaTop: CGFloat = 64  // 預設 44 (navigation bar) + 20 (狀態列)
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = DesignConstants.Colors.background
        
        // Avatar ImageView 設定
        avatarImageView.image = UIImage(named: "imgFriendsFemaleDefault")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 26
        addSubview(avatarImageView)
        
        // Name Label 設定
        nameLabel.font = DesignConstants.Typography.nameFont()
        nameLabel.textColor = DesignConstants.Colors.lightGrey
        addSubview(nameLabel)
        
        // KOKO ID Label 設定
        kokoIdLabel.font = DesignConstants.Typography.kokoIdFont()
        kokoIdLabel.textColor = DesignConstants.Colors.lightGrey
        addSubview(kokoIdLabel)
        
        // Chevron ">" 圖標設定
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = DesignConstants.Colors.lightGrey
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.isHidden = true  // 初始隱藏，載入完成後顯示
        addSubview(chevronImageView)
        
        updateLayout()
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    private func updateLayout() {
        let width = bounds.width
        
        // 計算相對位置：設計稿中的絕對位置扣除 safe area (64pt)
        // 頭像：82 - 64 = 18
        // 姓名：90 - 64 = 26
        // KOKO ID：116 - 64 = 52
        let nameRelativeY = designNameTop - safeAreaTop      // 26
        let kokoIdRelativeY = designKokoIdTop - safeAreaTop  // 52
        
        // Avatar 位置（右側，對齊姓名標籤）
        avatarImageView.frame = CGRect(
            x: width - horizontalPadding - avatarSize,
            y: nameRelativeY,  // 對齊姓名標籤
            width: avatarSize,
            height: avatarSize
        )
        
        // Name Label 位置（左側）
        let labelMaxWidth = width - horizontalPadding * 2 - avatarSize - 15
        nameLabel.frame = CGRect(
            x: horizontalPadding,
            y: nameRelativeY,
            width: labelMaxWidth,
            height: 18
        )
        
        // KOKO ID Label 位置（左側，在姓名下方）
        kokoIdLabel.frame = CGRect(
            x: horizontalPadding,
            y: kokoIdRelativeY,
            width: labelMaxWidth,
            height: 18
        )
        
        // Chevron ">" 圖標位置（跟隨 KOKO ID 文字末尾）
        let chevronSize: CGFloat = 16
        let chevronSpacing: CGFloat = 8  // 文字和圖標之間的間距
        
        // 計算 KOKO ID 文字的實際寬度
        let kokoIdText = kokoIdLabel.text ?? ""
        let textSize = (kokoIdText as NSString).boundingRect(
            with: CGSize(width: labelMaxWidth, height: 18),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: DesignConstants.Typography.kokoIdFont()],
            context: nil
        )
        let chevronX = horizontalPadding + textSize.width + chevronSpacing
        let chevronY = kokoIdRelativeY + (18 - chevronSize) / 2  // 垂直居中對齊
        
        chevronImageView.frame = CGRect(
            x: chevronX,
            y: chevronY,
            width: chevronSize,
            height: chevronSize
        )
    }
    
    func updateLayout(for width: CGFloat, safeAreaTop: CGFloat = 0) {
        self.safeAreaTop = safeAreaTop
        frame.size.width = width
        updateLayout()
    }
    
    // MARK: - Configuration
    
    func configure(name: String, kokoId: String) {
        nameLabel.text = name
        kokoIdLabel.text = "KOKO ID：\(kokoId)"
        
        // 資料載入完成後顯示 chevron
        chevronImageView.isHidden = false
        
        // 更新布局以重新計算 chevron 位置
        updateLayout()
    }
}

