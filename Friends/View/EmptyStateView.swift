//
//  EmptyStateView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

class EmptyStateView: UIView {
    
    // MARK: - UI Components
    
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Icon ImageView 設定
        iconImageView.image = UIImage(systemName: "person.2.slash")
        iconImageView.tintColor = .systemGray3
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        // Message Label 設定
        messageLabel.text = "尚無好友"
        messageLabel.font = .systemFont(ofSize: 20, weight: .medium)
        messageLabel.textColor = .systemGray
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Message - 使用 centerX 而非 leading/trailing，避免與 backgroundView 的自動 frame 管理衝突
            messageLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        // 設置較低優先級的寬度約束，避免與 backgroundView 的自動管理衝突
        let leadingConstraint = messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20)
        let trailingConstraint = messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        leadingConstraint.priority = .defaultHigh
        trailingConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint
        ])
    }
    
    // MARK: - Configuration
    
    func configure(icon: UIImage?, message: String) {
        iconImageView.image = icon
        messageLabel.text = message
    }
}

