//
//  TabSwitchView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

protocol TabSwitchViewDelegate: AnyObject {
    func tabSwitchView(_ view: TabSwitchView, didSelectTab tab: TabSwitchView.Tab)
}

class TabSwitchView: UIView {
    
    // MARK: - Constants
    
    static let tabSwitchHeight: CGFloat = 28
    
    // MARK: - Properties
    
    weak var delegate: TabSwitchViewDelegate?
    
    // Tab 按鈕字體大小
    private let tabButtonFontSize: CGFloat = 13
    
    private let friendsButton = UIButton(type: .system)
    private let chatButton = UIButton(type: .system)
    private let indicatorView = UIView()
    private let dividerView = UIView()
    private let friendsBadgeView = UIView()
    private let friendsBadgeLabel = UILabel()
    private let chatBadgeView = UIView()
    private let chatBadgeLabel = UILabel()
    
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var friendsBadgeWidthConstraint: NSLayoutConstraint?
    private var chatBadgeWidthConstraint: NSLayoutConstraint?
    
    private var currentTab: Tab = .friends
    
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
        friendsButton.titleLabel?.font = .systemFont(ofSize: tabButtonFontSize, weight: .medium)
        friendsButton.setTitleColor(DesignConstants.Colors.lightGrey, for: .normal)
        friendsButton.translatesAutoresizingMaskIntoConstraints = false
        friendsButton.addTarget(self, action: #selector(friendsButtonTapped(_:)), for: .touchUpInside)
        addSubview(friendsButton)
        
        // 聊天按鈕
        chatButton.setTitle("聊天", for: .normal)
        chatButton.titleLabel?.font = .systemFont(ofSize: tabButtonFontSize, weight: .regular)
        chatButton.setTitleColor(DesignConstants.Colors.lightGrey, for: .normal)
        chatButton.translatesAutoresizingMaskIntoConstraints = false
        chatButton.addTarget(self, action: #selector(chatButtonTapped(_:)), for: .touchUpInside)
        addSubview(chatButton)
        
        // 選中指示器
        indicatorView.backgroundColor = DesignConstants.Colors.hotPink
        indicatorView.layer.cornerRadius = 2
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicatorView)
        
        // 好友 Badge（顯示待處理邀請數量）
        friendsBadgeView.backgroundColor = DesignConstants.Colors.badgeBackground
        friendsBadgeView.layer.cornerRadius = 9
        friendsBadgeView.translatesAutoresizingMaskIntoConstraints = false
        friendsBadgeView.isHidden = true
        addSubview(friendsBadgeView)
        
        friendsBadgeLabel.text = "0"
        friendsBadgeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        friendsBadgeLabel.textColor = DesignConstants.Colors.badgeTextColor
        friendsBadgeLabel.textAlignment = .center
        friendsBadgeLabel.numberOfLines = 1
        friendsBadgeLabel.lineBreakMode = .byTruncatingTail
        friendsBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        friendsBadgeView.addSubview(friendsBadgeLabel)
        
        // 聊天 Badge
        chatBadgeView.backgroundColor = DesignConstants.Colors.badgeBackground
        chatBadgeView.layer.cornerRadius = 9
        chatBadgeView.translatesAutoresizingMaskIntoConstraints = false
        chatBadgeView.isHidden = true
        addSubview(chatBadgeView)
        
        chatBadgeLabel.text = "0"
        chatBadgeLabel.font = .systemFont(ofSize: 12, weight: .medium)
        chatBadgeLabel.textColor = DesignConstants.Colors.badgeTextColor
        chatBadgeLabel.textAlignment = .center
        chatBadgeLabel.numberOfLines = 1
        chatBadgeLabel.lineBreakMode = .byTruncatingTail
        chatBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        chatBadgeView.addSubview(chatBadgeLabel)
        
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
            
            // 選中指示器（在按鈕文字下方，間距 6pt，height, width 固定，leading 由 indicatorLeadingConstraint 動態控制）
            indicatorView.topAnchor.constraint(equalTo: friendsButton.bottomAnchor, constant: 6),
            indicatorView.heightAnchor.constraint(equalToConstant: 4),
            indicatorView.widthAnchor.constraint(equalToConstant: 20),
            
            // 好友 Badge（在 friendsButton 左上角，根據設計稿 x: 59, y: 262）
            // friendsButton leading 是 32，badge x 是 59，所以 offset = 59 - 32 = 27
            friendsBadgeView.leadingAnchor.constraint(equalTo: friendsButton.leadingAnchor, constant: 27),
            friendsBadgeView.topAnchor.constraint(equalTo: friendsButton.topAnchor, constant: -9), // -9 讓 badge 在按鈕上方
            friendsBadgeView.heightAnchor.constraint(equalToConstant: 18),
            friendsBadgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            
            // 好友 Badge Label
            friendsBadgeLabel.centerXAnchor.constraint(equalTo: friendsBadgeView.centerXAnchor),
            friendsBadgeLabel.centerYAnchor.constraint(equalTo: friendsBadgeView.centerYAnchor),
            friendsBadgeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: friendsBadgeView.leadingAnchor, constant: 4),
            friendsBadgeLabel.trailingAnchor.constraint(lessThanOrEqualTo: friendsBadgeView.trailingAnchor, constant: -4),
            
            // 聊天 Badge（在 chatButton 左上角）
            chatBadgeView.leadingAnchor.constraint(equalTo: chatButton.leadingAnchor, constant: 27),
            chatBadgeView.topAnchor.constraint(equalTo: chatButton.topAnchor, constant: -9), // -9 讓 badge 在按鈕上方
            chatBadgeView.heightAnchor.constraint(equalToConstant: 18),
            chatBadgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            
            // 聊天 Badge Label
            chatBadgeLabel.centerXAnchor.constraint(equalTo: chatBadgeView.centerXAnchor),
            chatBadgeLabel.centerYAnchor.constraint(equalTo: chatBadgeView.centerYAnchor),
            chatBadgeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: chatBadgeView.leadingAnchor, constant: 4),
            chatBadgeLabel.trailingAnchor.constraint(lessThanOrEqualTo: chatBadgeView.trailingAnchor, constant: -4)
        ])
        
        // 好友 Badge 寬度約束（動態調整）
        friendsBadgeWidthConstraint = friendsBadgeView.widthAnchor.constraint(equalToConstant: 18)
        friendsBadgeWidthConstraint?.isActive = true
        
        // 聊天 Badge 寬度約束（動態調整）
        chatBadgeWidthConstraint = chatBadgeView.widthAnchor.constraint(equalToConstant: 18)
        chatBadgeWidthConstraint?.isActive = true
        
        // 設定指示器初始位置（動態約束，用於切換 Tab 時移動）
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: friendsButton.leadingAnchor, constant: 3)
        indicatorLeadingConstraint?.isActive = true
        
        // 注意：初始 tab 應該由外部通過 updateTabState 設定，這裡不設定預設值
    }
    
    // MARK: - Actions
    
    @objc private func friendsButtonTapped(_ sender: UIButton) {
        selectTab(.friends)
    }
    
    @objc private func chatButtonTapped(_ sender: UIButton) {
        selectTab(.chat)
    }
    
    // MARK: - Public Methods
    
    enum Tab {
        case friends
        case chat
    }
    
    
    /// 更新指定 Tab 的 badge 數量
    /// - Parameters:
    ///   - count: badge 數量，0 時隱藏 badge
    ///   - tab: 要更新的 Tab（.friends 或 .chat）
    func updateBadgeCount(_ count: Int, for tab: Tab) {
        let badgeView: UIView
        let badgeLabel: UILabel
        var badgeWidthConstraint: NSLayoutConstraint?
        
        switch tab {
        case .friends:
            badgeView = friendsBadgeView
            badgeLabel = friendsBadgeLabel
            badgeWidthConstraint = friendsBadgeWidthConstraint
        case .chat:
            badgeView = chatBadgeView
            badgeLabel = chatBadgeLabel
            badgeWidthConstraint = chatBadgeWidthConstraint
        }
        
        guard count > 0 else {
            badgeView.isHidden = true
            return
        }
        
        // 根據數字決定顯示文字
        let text: String
        if count > 99 {
            text = "99+"
        } else {
            text = "\(count)"
        }
        
        // 只在需要時設置顯示狀態
        if badgeView.isHidden {
            badgeView.isHidden = false
        }
        
        badgeLabel.text = text
        
        // 動態計算寬度：使用 boundingRect 獲得更精確的文字寬度
        let font = badgeLabel.font ?? UIFont.systemFont(ofSize: 12, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 18),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: textAttributes,
            context: nil
        )
        let horizontalPadding: CGFloat = 8  // 左右各 4pt
        let minWidth: CGFloat = 18  // 最小寬度（圓形 badge）
        let calculatedWidth = max(ceil(textSize.width) + horizontalPadding, minWidth)
        
        // 更新寬度約束
        badgeWidthConstraint?.isActive = false
        
        switch tab {
        case .friends:
            friendsBadgeWidthConstraint = badgeView.widthAnchor.constraint(equalToConstant: calculatedWidth)
            friendsBadgeWidthConstraint?.isActive = true
        case .chat:
            chatBadgeWidthConstraint = badgeView.widthAnchor.constraint(equalToConstant: calculatedWidth)
            chatBadgeWidthConstraint?.isActive = true
        }
    }
    
    private func selectTab(_ tab: Tab, animated: Bool = true) {
        guard currentTab != tab else { return }
        updateTabState(to: tab, animated: animated)
        delegate?.tabSwitchView(self, didSelectTab: tab)
    }
    
    /// 更新 Tab 狀態
    /// - Parameters:
    ///   - tab: 要切換到的 Tab
    ///   - animated: 是否執行動畫
    func updateTabState(to tab: Tab, animated: Bool = false) {
        currentTab = tab
        
        // 更新按鈕樣式
        switch tab {
        case .friends:
            friendsButton.titleLabel?.font = .systemFont(ofSize: tabButtonFontSize, weight: .medium)
            chatButton.titleLabel?.font = .systemFont(ofSize: tabButtonFontSize, weight: .regular)
        case .chat:
            friendsButton.titleLabel?.font = .systemFont(ofSize: tabButtonFontSize, weight: .regular)
            chatButton.titleLabel?.font = .systemFont(ofSize: tabButtonFontSize, weight: .medium)
            chatButton.setTitle("聊天", for: .normal)
        }
        
        // 更新指示器位置
        indicatorLeadingConstraint?.isActive = false
        
        let targetButton = tab == .friends ? friendsButton : chatButton
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: targetButton.leadingAnchor, constant: 3)
        indicatorLeadingConstraint?.isActive = true
        
        if animated {
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.layoutIfNeeded()
            }
        } else {
            // 不執行動畫，直接更新布局
            layoutIfNeeded()
        }
    }
}

