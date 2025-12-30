//
//  UserProfileHeaderView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

// MARK: - Delegate Protocol

protocol UserProfileHeaderViewDelegate: AnyObject {
    func userProfileHeaderViewDidTapRequests(_ headerView: UserProfileHeaderView)
}

class UserProfileHeaderView: UIView {
    
    // MARK: - Constants
    
    private let avatarSize: CGFloat = 52
    private let horizontalPadding: CGFloat = 30
    // 設計稿中的絕對位置（相對於整個畫面，包含 safe area 64pt）
    private let designAvatarTop: CGFloat = 82  // 根據設計稿 y: 82
    private let designNameTop: CGFloat = 90    // 根據設計稿 y: 90
    private let designKokoIdTop: CGFloat = 116 // 根據設計稿 y: 116
    
    // Requests Section 常數
    private let requestCardHeight: CGFloat = 70
    private let cardSpacing: CGFloat = 10  // 展開時卡片間距
    private let stackedCardOffset: CGFloat = 10  // 堆疊卡片的垂直偏移量
    private let bottomPadding: CGFloat = 22  // 卡片區塊與底部 TabSwitchView 的間距
    private let animationDuration: TimeInterval = 0.3
    
    // MARK: - Properties
    
    weak var delegate: UserProfileHeaderViewDelegate?
    
    /// 是否展開 Requests Section（預設為折疊）
    private(set) var isRequestsExpanded: Bool = false
    
    /// 是否強制展開（搜尋時無法折疊）
    private var isForcedExpanded: Bool = false
    
    /// 好友邀請資料
    private var requests: [Friend] = []
    
    // MARK: - UI Components (User Profile)
    
    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let kokoIdLabel = UILabel()
    private let chevronImageView = UIImageView()  // ">" 符號
    
    // Shimmer views
    private let avatarShimmerView = ShimmerView()
    private let nameShimmerView = ShimmerView()
    private let kokoIdShimmerView = ShimmerView()
    
    // MARK: - UI Components (Requests Section - 堆疊卡片樣式)
    
    /// 好友邀請區塊容器
    private let requestsContainer = UIView()
    
    /// 堆疊卡片 Views
    private var cardViews: [FriendRequestCardView] = []
    
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
        
        setupUserProfileSection()
        setupRequestsSection()
        updateLayout()
    }
    
    private func setupUserProfileSection() {
        // Avatar ImageView 設定
        avatarImageView.image = UIImage(named: "imgFriendsFemaleDefault")
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 26
        addSubview(avatarImageView)
        
        // Name Label 設定
        nameLabel.font = DesignConstants.Typography.nameFont()
        nameLabel.textColor = DesignConstants.Colors.lightGrey
        // 設置固定高度，確保即使沒有文字也會佔據空間
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        addSubview(nameLabel)
        
        // KOKO ID Label 設定
        kokoIdLabel.font = DesignConstants.Typography.kokoIdFont()
        kokoIdLabel.textColor = DesignConstants.Colors.lightGrey
        // 設置固定高度，確保即使沒有文字也會佔據空間
        kokoIdLabel.numberOfLines = 1
        kokoIdLabel.lineBreakMode = .byTruncatingTail
        addSubview(kokoIdLabel)
        
        // Chevron ">" 圖標設定
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = DesignConstants.Colors.lightGrey
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.isHidden = true  // 初始隱藏，載入完成後顯示
        addSubview(chevronImageView)
        
        // Shimmer views 設定
        avatarShimmerView.layer.cornerRadius = 26
        avatarShimmerView.clipsToBounds = true
        addSubview(avatarShimmerView)
        
        nameShimmerView.layer.cornerRadius = 4
        nameShimmerView.clipsToBounds = true
        addSubview(nameShimmerView)
        
        kokoIdShimmerView.layer.cornerRadius = 4
        kokoIdShimmerView.clipsToBounds = true
        addSubview(kokoIdShimmerView)
        
        // 初始顯示 Shimmer
        startShimmer()
    }
    
    private func setupRequestsSection() {
        // Requests 容器
        requestsContainer.backgroundColor = .clear
        requestsContainer.isHidden = true  // 初始隱藏，有資料時才顯示
        requestsContainer.clipsToBounds = false
        addSubview(requestsContainer)
        
        // 點擊手勢
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRequestsTap))
        requestsContainer.addGestureRecognizer(tapGesture)
        requestsContainer.isUserInteractionEnabled = true
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    private func updateLayout() {
        let width = bounds.width
        
        layoutUserProfileSection(width: width)
        layoutRequestsSection(width: width, animated: false)
    }
    
    private func layoutUserProfileSection(width: CGFloat) {
        // 如果寬度為 0，跳過布局（會在 layoutSubviews 中再次調用）
        guard width > 0 else { return }
        
        // 計算相對位置：設計稿中的絕對位置扣除 safe area (64pt)
        let nameRelativeY = designNameTop - safeAreaTop      // 26
        let kokoIdRelativeY = designKokoIdTop - safeAreaTop  // 52
        
        // Avatar 位置（右側，對齊姓名標籤）
        avatarImageView.frame = CGRect(
            x: width - horizontalPadding - avatarSize,
            y: nameRelativeY,
            width: avatarSize,
            height: avatarSize
        )
        
        // Name Label 位置（左側）
        let labelMaxWidth = max(0, width - horizontalPadding * 2 - avatarSize - 15)
        // 確保在 Loading (文字為空) 時，Label 仍有佔位寬度供 Shimmer 顯示
        let nameWidth = (nameLabel.text?.isEmpty ?? true) ? 120 : labelMaxWidth
        nameLabel.frame = CGRect(
            x: horizontalPadding,
            y: nameRelativeY,
            width: nameWidth,
            height: 18
        )
        
        // KOKO ID Label 位置（左側，在姓名下方）
        let kokoIdWidth = (kokoIdLabel.text?.isEmpty ?? true) ? 160 : labelMaxWidth
        kokoIdLabel.frame = CGRect(
            x: horizontalPadding,
            y: kokoIdRelativeY,
            width: kokoIdWidth,
            height: 18
        )
        
        // Chevron ">" 圖標位置（跟隨 KOKO ID 文字末尾）
        let chevronSize: CGFloat = 16
        let chevronSpacing: CGFloat = 8
        
        let kokoIdText = kokoIdLabel.text ?? ""
        let textSize = (kokoIdText as NSString).boundingRect(
            with: CGSize(width: labelMaxWidth, height: 18),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: DesignConstants.Typography.kokoIdFont()],
            context: nil
        )
        let chevronX = horizontalPadding + textSize.width + chevronSpacing
        let chevronY = kokoIdRelativeY + (18 - chevronSize) / 2
        
        chevronImageView.frame = CGRect(
            x: chevronX,
            y: chevronY,
            width: chevronSize,
            height: chevronSize
        )
        
        // Shimmer views 布局（與對應的元件相同位置和大小）
        // 確保 ShimmerView 有固定高度，避免 Header View 被壓扁
        avatarShimmerView.frame = avatarImageView.frame
        
        // 即使 label 因為沒有文字而高度為 0，Shimmer 仍需顯示佔位高度
        var nameFrame = nameLabel.frame
        if nameFrame.height == 0 {
            nameFrame.size.height = 18
        }
        nameShimmerView.frame = nameFrame
        
        var kokoIdFrame = kokoIdLabel.frame
        if kokoIdFrame.height == 0 {
            kokoIdFrame.size.height = 18
        }
        kokoIdShimmerView.frame = kokoIdFrame
    }
    
    private func layoutRequestsSection(width: CGFloat, animated: Bool = false) {
        guard !requests.isEmpty else {
            requestsContainer.isHidden = true
            return
        }
        
        requestsContainer.isHidden = false
        
        // Requests 容器位置（在用戶資料下方）
        let userProfileHeight: CGFloat = 100
        let containerHeight = calculateRequestsSectionHeight()
        
        requestsContainer.frame = CGRect(
            x: 0,
            y: userProfileHeight,
            width: width,
            height: containerHeight
        )
        
        // 直接佈局卡片（動畫由外部 UIView.animate 控制）
        layoutCardViews(width: width)
    }
    
    private func layoutCardViews(width: CGFloat) {
        let cardWidth = width - horizontalPadding * 2
        let requestCount = cardViews.count
        
        if isRequestsExpanded && requestCount > 1 {
            // 展開狀態：卡片垂直排列
            for (index, cardView) in cardViews.enumerated() {
                let yOffset = CGFloat(index) * (requestCardHeight + cardSpacing)
                cardView.frame = CGRect(
                    x: horizontalPadding,
                    y: yOffset,
                    width: cardWidth,
                    height: requestCardHeight
                )
                cardView.alpha = 1
                cardView.layer.zPosition = CGFloat(cardViews.count - index)
                cardView.isHidden = false
            }
        } else {
            // 折疊狀態或單一邀請：從底部堆疊露出效果
            let maxVisibleCards = min(requestCount, 2)  // 最多顯示 2 張卡片堆疊
            
            for (index, cardView) in cardViews.enumerated() {
                if index < maxVisibleCards {
                    // 計算堆疊效果：後面的卡片稍微縮小並從底部露出
                    // 如果只有一張邀請，則 yOffset 為 0 且不縮放
                    let stackIndex = CGFloat(index)
                    let yOffset = requestCount > 1 ? stackIndex * stackedCardOffset : 0
                    let horizontalInset = requestCount > 1 ? stackIndex * 6 : 0 // 每層往內縮 6pt
                    let currentCardWidth = cardWidth - (horizontalInset * 2)
                    
                    cardView.frame = CGRect(
                        x: horizontalPadding + horizontalInset,
                        y: yOffset,
                        width: currentCardWidth,
                        height: requestCardHeight
                    )
                    // 最上面的卡片 zPosition 最高
                    cardView.layer.zPosition = CGFloat(maxVisibleCards - index)
                    cardView.alpha = 1.0
                    cardView.isHidden = false
                } else {
                    // 隱藏其他卡片，但仍需設定正確的 frame，以便展開時從正確位置動畫
                    // 設定為與第二張卡片相同的位置（堆疊在下方）
                    let stackIndex = CGFloat(1)
                    let yOffset = stackIndex * stackedCardOffset
                    let horizontalInset = stackIndex * 6
                    let currentCardWidth = cardWidth - (horizontalInset * 2)
                    
                    cardView.frame = CGRect(
                        x: horizontalPadding + horizontalInset,
                        y: yOffset,
                        width: currentCardWidth,
                        height: requestCardHeight
                    )
                    cardView.isHidden = true
                }
            }
        }
    }
    
    private func calculateRequestsSectionHeight() -> CGFloat {
        guard !requests.isEmpty else { return 0 }
        
        let requestCount = requests.count
        
        if isRequestsExpanded && requestCount > 1 {
            // 展開：所有卡片的高度 + 間距 + 底部間距
            return CGFloat(requestCount) * requestCardHeight + CGFloat(max(0, requestCount - 1)) * cardSpacing + bottomPadding
        } else {
            // 折疊：第一張卡片完整高度 + 第二張卡片露出的部分 + 底部間距
            let maxVisibleCards = min(requestCount, 2)
            if maxVisibleCards > 1 {
                return requestCardHeight + stackedCardOffset + bottomPadding
            } else {
                return requestCardHeight + bottomPadding
            }
        }
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
        
        // 資料載入完成後停止 Shimmer 並顯示 chevron
        stopShimmer()
        chevronImageView.isHidden = false
        
        updateLayout()
    }
    
    /// 配置 Requests Section（堆疊卡片樣式）
    /// - Parameters:
    ///   - requests: 好友邀請列表
    ///   - isExpanded: 是否展開
    func configureRequests(_ requests: [Friend], isExpanded: Bool) {
        self.requests = requests
        
        // 根據新規則：數量為 1 時視為展開，多於 1 時預設為折疊
        if requests.count == 1 {
            self.isRequestsExpanded = true
        } else {
            self.isRequestsExpanded = isExpanded // 由外部傳入（預設為 VM 的 false）
        }
        
        // 清除舊的卡片
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()
        
        // 建立新的卡片
        for request in requests {
            let cardView = FriendRequestCardView()
            cardView.configure(with: request)
            cardView.layer.cornerRadius = 6
            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
            cardView.layer.shadowRadius = 4
            cardView.layer.shadowOpacity = 0.1
            requestsContainer.addSubview(cardView)
            cardViews.append(cardView)
        }
        
        // 如果當前已經有寬度，立即佈局以確保初始狀態正確
        if bounds.width > 0 {
            layoutRequestsSection(width: bounds.width, animated: false)
        } else {
            setNeedsLayout()
        }
    }
    
    /// 確保卡片有正確的初始位置（在動畫開始前呼叫）
    func ensureInitialLayout() {
        guard bounds.width > 0 else { return }
        // 必須調用 layoutRequestsSection 而不僅是 layoutCardViews
        // 以確保 requestsContainer 的 frame 也被正確設定
        layoutRequestsSection(width: bounds.width, animated: false)
    }
    
    /// 計算並回傳 view 的合適高度
    func calculateHeight(hasRequests: Bool, isExpanded: Bool, requestCount: Int) -> CGFloat {
        let userProfileHeight: CGFloat = 100
        
        guard hasRequests && requestCount > 0 else {
            return userProfileHeight
        }
        
        // 如果只有一個邀請，不論傳入什麼狀態，高度都是單卡高度
        if requestCount == 1 {
            return userProfileHeight + requestCardHeight + bottomPadding
        }
        
        if isExpanded {
            return userProfileHeight + CGFloat(requestCount) * requestCardHeight + CGFloat(max(0, requestCount - 1)) * cardSpacing + bottomPadding
        } else {
            // 折疊：第一張卡片完整高度 + 第二張卡片露出的部分 + 底部間距
            let maxVisibleCards = min(requestCount, 2)
            let stackOffset = maxVisibleCards > 1 ? stackedCardOffset : 0
            return userProfileHeight + requestCardHeight + stackOffset + bottomPadding
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleRequestsTap() {
        // 如果強制展開（搜尋中），不允許折疊
        guard !isForcedExpanded else { return }
        // 只有當邀請數量大於 1 時才允許展開/收合
        guard requests.count > 1 else { return }
        delegate?.userProfileHeaderViewDidTapRequests(self)
    }
    
    /// 切換展開/折疊狀態（帶動畫）
    /// - Parameter animated: 是否帶動畫
    func toggleRequestsExpanded(animated: Bool = true) {
        // 只有多於 1 個邀請才允許進入切換狀態
        guard requests.count > 1 else { return }
        
        // 注意：isRequestsExpanded 應該在呼叫此方法前由外部設定
        // 這裡只負責更新布局
        layoutRequestsSection(width: bounds.width, animated: animated)
    }
    
    /// 設定展開狀態（不帶動畫，用於同步 ViewModel 狀態）
    func setExpandedState(_ expanded: Bool) {
        guard requests.count > 1 else { return }
        isRequestsExpanded = expanded
    }
    
    /// 強制展開 cardViews（搜尋時使用，此時無法折疊）
    func forceExpand() {
        isForcedExpanded = true
        if requests.count > 1 {
            isRequestsExpanded = true
        }
        if bounds.width > 0 {
            layoutRequestsSection(width: bounds.width, animated: true)
        }
    }
    
    /// 取消強制展開（搜尋結束時使用）
    func cancelForceExpand() {
        isForcedExpanded = false
        // 注意：不在這裡修改 isRequestsExpanded，因為它應該由 ViewModel 管理
        // 這個方法只是取消強制展開的限制
    }
    
    // MARK: - Shimmer
    
    private func startShimmer() {
        avatarShimmerView.isHidden = false
        nameShimmerView.isHidden = false
        kokoIdShimmerView.isHidden = false
        avatarShimmerView.startAnimating()
        nameShimmerView.startAnimating()
        kokoIdShimmerView.startAnimating()
    }
    
    private func stopShimmer() {
        avatarShimmerView.stopAnimating()
        nameShimmerView.stopAnimating()
        kokoIdShimmerView.stopAnimating()
        avatarShimmerView.isHidden = true
        nameShimmerView.isHidden = true
        kokoIdShimmerView.isHidden = true
    }
}

// MARK: - FriendRequestCardView (堆疊卡片樣式)

private class FriendRequestCardView: UIView {
    
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
        label.font = DesignConstants.Typography.friendNameFont()
        label.textColor = DesignConstants.Colors.lightGrey
        return label
    }()
    
    private let invitationLabel: UILabel = {
        let label = UILabel()
        label.text = "邀請你成為好友：）"
        label.font = DesignConstants.Typography.kokoIdFont()
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
        setupUI()
        updateButtonColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: FriendRequestCardView, _: UITraitCollection) in
            self?.updateButtonColors()
            self?.layer.borderColor = DesignConstants.Colors.divider.cgColor
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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

