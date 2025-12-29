//
//  TabSwitchView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

class TabSwitchView: UIView {
    
    // MARK: - Properties
    
    private let friendsButton = UIButton(type: .system)
    private let chatButton = UIButton(type: .system)
    private let indicatorView = UIView()
    private let dividerView = UIView()
    
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    
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
        backgroundColor = DesignConstants.Colors.background
        
        // 分隔線
        dividerView.backgroundColor = DesignConstants.Colors.dividerLight
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        
        // 好友按鈕
        friendsButton.setTitle("好友", for: .normal)
        friendsButton.titleLabel?.font = DesignConstants.Typography.tabMediumFont()
        friendsButton.setTitleColor(DesignConstants.Colors.lightGrey, for: .normal)
        friendsButton.translatesAutoresizingMaskIntoConstraints = false
        friendsButton.addTarget(self, action: #selector(friendsButtonTapped), for: .touchUpInside)
        addSubview(friendsButton)
        
        // 聊天按鈕
        chatButton.setTitle("聊天", for: .normal)
        chatButton.titleLabel?.font = DesignConstants.Typography.tabRegularFont()
        chatButton.setTitleColor(DesignConstants.Colors.lightGrey, for: .normal)
        chatButton.translatesAutoresizingMaskIntoConstraints = false
        chatButton.addTarget(self, action: #selector(chatButtonTapped), for: .touchUpInside)
        addSubview(chatButton)
        
        // 選中指示器
        indicatorView.backgroundColor = DesignConstants.Colors.hotPink
        indicatorView.layer.cornerRadius = DesignConstants.Spacing.tabIndicatorCornerRadius
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicatorView)
        
        NSLayoutConstraint.activate([
            // 分隔線（根據設計稿在底部）
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            
            // 好友按鈕（根據設計稿 x: 32, y: 164）
            friendsButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            friendsButton.topAnchor.constraint(equalTo: topAnchor),
            friendsButton.heightAnchor.constraint(equalToConstant: 18),
            
            // 聊天按鈕（根據設計稿 x: 94, y: 164）
            chatButton.leadingAnchor.constraint(equalTo: friendsButton.trailingAnchor, constant: 36),
            chatButton.topAnchor.constraint(equalTo: topAnchor),
            chatButton.heightAnchor.constraint(equalToConstant: 18),
            
            // 選中指示器（bottom, height, width 固定，leading 由 indicatorLeadingConstraint 動態控制）
            indicatorView.bottomAnchor.constraint(equalTo: dividerView.topAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: DesignConstants.Spacing.tabIndicatorHeight),
            indicatorView.widthAnchor.constraint(equalToConstant: 20)
        ])
        
        // 設定指示器初始位置（動態約束，用於切換 Tab 時移動）
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: friendsButton.leadingAnchor, constant: 3)
        indicatorLeadingConstraint?.isActive = true
        
        // 預設選中好友（不執行動畫，避免首次顯示時閃爍）
        selectTab(.friends, animated: false)
    }
    
    // MARK: - Actions
    
    @objc private func friendsButtonTapped() {
        selectTab(.friends)
    }
    
    @objc private func chatButtonTapped() {
        selectTab(.chat)
    }
    
    // MARK: - Public Methods
    
    enum Tab {
        case friends
        case chat
    }
    
    private func selectTab(_ tab: Tab, animated: Bool = true) {
        // 更新按鈕樣式
        switch tab {
        case .friends:
            friendsButton.titleLabel?.font = DesignConstants.Typography.tabMediumFont()
            chatButton.titleLabel?.font = DesignConstants.Typography.tabRegularFont()
        case .chat:
            friendsButton.titleLabel?.font = DesignConstants.Typography.tabRegularFont()
            chatButton.titleLabel?.font = DesignConstants.Typography.tabMediumFont()
        }
        
        // 更新指示器位置
        indicatorLeadingConstraint?.isActive = false
        
        let targetButton = tab == .friends ? friendsButton : chatButton
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: targetButton.leadingAnchor, constant: 3)
        indicatorLeadingConstraint?.isActive = true
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        } else {
            // 不執行動畫，直接更新布局
            layoutIfNeeded()
        }
    }
}

