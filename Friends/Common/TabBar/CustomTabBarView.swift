//
//  CustomTabBarView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/30.
//

import UIKit

protocol CustomTabBarViewDelegate: AnyObject {
    func tabBarView(_ tabBarView: CustomTabBarView, didSelectTabAt index: Int)
}

class CustomTabBarView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: CustomTabBarViewDelegate?
    private var selectedIndex: Int = 1
    
    private var tabContainers: [UIView] = [] // Tab 容器陣列（包含 icon 和 label）
    private var centerButton: UIButton?
    private var centerButtonContainer: UIView?
    private var topBorderLine: UIView?
    
    private let tabItems: [TabBarItem] = [.products, .friends, .home, .manage, .settings]
    
    // Home tab 的索引（center button）
    private let homeTabIndex = 2
    
    // Tab bar 高度
    static let tabBarHeight: CGFloat = 55
    
    /// 計算 TabBar 的總 inset（包含 safe area bottom）
    /// - Parameter safeAreaBottom: Safe area 底部高度
    /// - Returns: TabBar 的總 inset
    static func calculateTabBarInset(safeAreaBottom: CGFloat) -> CGFloat {
        return safeAreaBottom + tabBarHeight
    }
    
    // MARK: - Layout Constants
    
    // 一般 Tab 按鈕
    private let tabIconSize: CGFloat = 32
    private let tabIconPointSize: CGFloat = 32
    private let tabLabelFontSize: CGFloat = 12
    
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
        setupBackground()
        setupTopBorder()
        setupTabButtons()
        setupCenterButton()
        updateAppearance()
        
        // Register for trait changes
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.updateAppearance()
        }
    }
    
    private func setupBackground() {
        // Background view with custom color
        let backgroundView = UIView()
        backgroundView.backgroundColor = .koTabBarBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupTopBorder() {
        let borderLine = UIView()
        borderLine.backgroundColor = .clear
        borderLine.isUserInteractionEnabled = false
        borderLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(borderLine)
        topBorderLine = borderLine
        
        NSLayoutConstraint.activate([
            borderLine.topAnchor.constraint(equalTo: topAnchor),
            borderLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 確保 centerButton 和 container 的 frame 已準備好
        // 如果 frame 還沒準備好，延遲到下一個 run loop 再試一次
        // 因為 Auto Layout 的計算可能還沒完成，需要等待 layout pass 完成
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            createBorderWithCutout()
            if let topBorderLine = topBorderLine {
                bringSubviewToFront(topBorderLine)
            }
            if let centerButtonContainer = centerButtonContainer {
                bringSubviewToFront(centerButtonContainer)
            }
        }
    }
    
    /// 取得有效的 frame，如果無效則返回 nil
    private func getValidFrames() -> (centerButton: CGRect, container: CGRect)? {
        guard let centerButtonFrame = centerButton?.frame,
              let containerFrame = centerButtonContainer?.frame,
              centerButtonFrame.width > 0 && centerButtonFrame.height > 0,
              containerFrame.width > 0 && containerFrame.height > 0 else {
            return nil
        }
        return (centerButtonFrame, containerFrame)
    }
    
    private func createBorderWithCutout() {
        guard let topBorderLine = topBorderLine else { return }
        topBorderLine.layer.sublayers?.removeAll()
        
        // 確保 centerButton 和 container 的 frame 已準備好，才能計算正確的邊框位置
        guard let frames = getValidFrames() else {
            return
        }
        
        let centerButtonFrame = frames.centerButton
        
        let borderWidth = bounds.width
        let centerX = bounds.width / 2
        let borderY: CGFloat = 0.25 // Border at TabBar top (center of 0.5pt line)
        
        // Get center button's position in our coordinate system
        // Convert from container's coordinate system to view's coordinate system
        guard let centerButtonContainer = centerButtonContainer else { return }
        let buttonGlobalFrame = centerButtonContainer.convert(centerButtonFrame, to: self)
        let buttonCenterY = buttonGlobalFrame.midY
        
        // Calculate cutout radius and arc center based on button position
        // The arc should be on the upper edge, with its top well above the border
        // Arc top should be significantly above borderY to create upward curve
        let arcTopOffset: CGFloat = 15.0 // Arc top should be 15pt above border
        let arcTopY = borderY - arcTopOffset
        
        // Arc center should be positioned so arc wraps around button's lower half
        // If arc center = buttonCenterY, then arc top = buttonCenterY - cutoutRadius
        // We want arc top = arcTopY, so: buttonCenterY - cutoutRadius = arcTopY
        // Therefore: cutoutRadius = buttonCenterY - arcTopY
        // But we also want a minimum radius for visual appeal
        let minCutoutRadius: CGFloat = 30
        let calculatedCutoutRadius = max(buttonCenterY - arcTopY, minCutoutRadius)
        let cutoutRadius = calculatedCutoutRadius
        
        // Arc center at button center to wrap around it
        let arcCenterY = buttonCenterY
        
        // Arc should be above the border line
        // Calculate connection points where the circle intersects borderY
        // For a circle: (x - centerX)^2 + (y - arcCenterY)^2 = cutoutRadius^2
        // At y = borderY: (x - centerX)^2 = cutoutRadius^2 - (arcCenterY - borderY)^2
        let verticalDistance = arcCenterY - borderY
        let horizontalDistance = sqrt(max(cutoutRadius * cutoutRadius - verticalDistance * verticalDistance, 0))
        
        let leftConnectionX = centerX - horizontalDistance
        let rightConnectionX = centerX + horizontalDistance
        let leftConnectionPoint = CGPoint(x: leftConnectionX, y: borderY)
        let rightConnectionPoint = CGPoint(x: rightConnectionX, y: borderY)
        
        // Calculate angles for connection points
        // Angle from center to connection point: atan2(dy, dx)
        // For left point: dx = -horizontalDistance, dy = borderY - arcCenterY = -verticalDistance
        // For right point: dx = horizontalDistance, dy = borderY - arcCenterY = -verticalDistance
        let leftAngle = atan2(-verticalDistance, -horizontalDistance)
        let rightAngle = atan2(-verticalDistance, horizontalDistance)
        
        // Create separate layers for straight lines and arc to handle shadow occlusion
        // Arc part may appear thinner due to button shadow, so we'll render it separately
        let borderLineWidth: CGFloat = 0.5
        
        // Create path for straight lines only
        let straightPath = UIBezierPath()
        straightPath.move(to: CGPoint(x: 0, y: borderY))
        straightPath.addLine(to: leftConnectionPoint)
        straightPath.move(to: rightConnectionPoint)
        straightPath.addLine(to: CGPoint(x: borderWidth, y: borderY))
        
        // Create path for arc only
        let arcPath = UIBezierPath()
        arcPath.addArc(
            withCenter: CGPoint(x: centerX, y: arcCenterY),
            radius: cutoutRadius,
            startAngle: leftAngle,
            endAngle: rightAngle,
            clockwise: true
        )
        
        // Determine shadow style based on interface style
        let isDark = traitCollection.userInterfaceStyle == .dark
        let shadowColor = isDark ? UIColor.white.cgColor : UIColor.black.cgColor
        let shadowOpacity: Float = isDark ? 0.25 : 0.3
        
        // Create layers with helper method
        let straightLayer = createBorderLayer(path: straightPath, lineWidth: borderLineWidth, shadowColor: shadowColor, shadowOpacity: shadowOpacity)
        let arcLayer = createBorderLayer(path: arcPath, lineWidth: borderLineWidth + 0.2, shadowColor: shadowColor, shadowOpacity: shadowOpacity)
        
        topBorderLine.layer.addSublayer(straightLayer)
        topBorderLine.layer.addSublayer(arcLayer)
    }
    
    private func createBorderLayer(path: UIBezierPath, lineWidth: CGFloat, shadowColor: CGColor, shadowOpacity: Float) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = UIColor.koTabBarTopBorder.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = lineWidth
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.shadowColor = shadowColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 2
        layer.shadowOpacity = shadowOpacity
        return layer
    }
    
    private func setupTabButtons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Create tab containers with proper indexing
        for (index, item) in tabItems.enumerated() {
            if index == homeTabIndex { // Home tab - center button placeholder
                let spacerView = UIView()
                stackView.addArrangedSubview(spacerView)
                tabContainers.append(spacerView)
            } else {
                let tabContainer = createTabContainer(for: item, at: index)
                tabContainers.append(tabContainer)
                stackView.addArrangedSubview(tabContainer)
            }
        }
        
        // Position stack view considering safe area
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 3),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func createTabContainer(for item: TabBarItem, at index: Int) -> UIView {
        let container = UIView()
        container.tag = index
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Create vertical stack view for icon and text
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.spacing = 0 // No spacing between icon and text
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create image view for the icon
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .koWarmGrey
        
        // Configure image
        if let image = UIImage(systemName: item.imageName) {
            let config = UIImage.SymbolConfiguration(pointSize: tabIconPointSize, weight: .medium)
            let resizedImage = image.withConfiguration(config)
            iconImageView.image = resizedImage
        }
        
        // Create label for the text
        let label = UILabel()
        label.text = item.title
        label.font = UIFont.systemFont(ofSize: tabLabelFontSize, weight: .regular)
        label.textColor = .koWarmGrey
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to vertical stack
        verticalStack.addArrangedSubview(iconImageView)
        verticalStack.addArrangedSubview(label)
        
        // Add stack to container
        container.addSubview(verticalStack)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Icon image view size
            iconImageView.widthAnchor.constraint(equalToConstant: tabIconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: tabIconSize),
            
            // Vertical stack constraints
            verticalStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            verticalStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            verticalStack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -2)
        ])
        
        // Add tap gesture to the entire container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTabSelection(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        // Store references for later updates
        iconImageView.accessibilityIdentifier = "icon_\(index)"
        label.accessibilityIdentifier = "label_\(index)"
        
        return container
    }
    
    private func setupCenterButton() {
        // Container for elevated button
        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        centerButtonContainer = container
        
        // Center button
        let button = UIButton(type: .custom)
        button.backgroundColor = .koBackground
        button.layer.cornerRadius = 30
        button.layer.shadowOffset = CGSize(width: 0, height: 12)
        button.layer.shadowRadius = 12
        button.layer.shadowOpacity = 0.1
        button.tag = homeTabIndex
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set home icon
        if let homeImage = UIImage(systemName: TabBarItem.home.imageName) {
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .medium)
            let resizedImage = homeImage.withConfiguration(config)
            button.setImage(resizedImage, for: .normal)
        }
        button.tintColor = .koWarmGrey
        
        container.addSubview(button)
        centerButton = button
        
        // Add target
        button.addTarget(self, action: #selector(handleTabSelection(_:)), for: .touchUpInside)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container constraints
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: -25),
            container.widthAnchor.constraint(equalToConstant: 85),
            container.heightAnchor.constraint(equalToConstant: 65),
            
            // Button constraints
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 5),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Actions
    
    /// 處理 Tab 選擇
    /// - UITapGestureRecognizer: tab 容器的點擊手勢（tab 按鈕已改為 UIImageView）
    /// - UIButton: centerButton 的點擊事件
    @objc private func handleTabSelection(_ sender: Any) {
        let index: Int
        switch sender {
        case let gesture as UITapGestureRecognizer:
            guard let container = gesture.view else { return }
            index = container.tag
        case let button as UIButton:
            index = button.tag
        default:
            return
        }
        
        selectedIndex = index
        updateAppearance()
        delegate?.tabBarView(self, didSelectTabAt: index)
    }
    
    // MARK: - Public Methods
    
    func updateSelectedIndex(_ index: Int) {
        selectedIndex = index
        updateAppearance()
    }
    
    // MARK: - Private Methods
    
    private func updateAppearance() {
        // Update shadow color for center button
        updateCenterButtonShadow()
        
        // Update border with cutout (this will refresh the color)
        createBorderWithCutout()
        
        // Update all tab containers
        for (arrayIndex, container) in tabContainers.enumerated() {
            if arrayIndex == homeTabIndex { continue } // Skip center button (handled separately)
            
            let isSelected = arrayIndex == selectedIndex
            let selectedColor = isSelected ? UIColor.koHotPink : UIColor.koWarmGrey
            
            // Find icon and label in container using recursive search
            updateContainerAppearance(container, isSelected: isSelected, color: selectedColor, index: arrayIndex)
        }
        
        // Update center button
        let isCenterSelected = selectedIndex == homeTabIndex
        centerButton?.tintColor = isCenterSelected ? UIColor.koHotPink : UIColor.koWarmGrey
    }
    
    private func updateContainerAppearance(_ view: UIView, isSelected: Bool, color: UIColor, index: Int) {
        guard let stackView = view.subviews.first as? UIStackView else { return }
        
        stackView.arrangedSubviews.forEach { subview in
            if let iconView = subview as? UIImageView, iconView.accessibilityIdentifier == "icon_\(index)" {
                iconView.tintColor = color
            } else if let label = subview as? UILabel, label.accessibilityIdentifier == "label_\(index)" {
                label.textColor = color
                label.font = UIFont.systemFont(ofSize: tabLabelFontSize, weight: isSelected ? .medium : .regular)
            }
        }
    }
    
    private func updateCenterButtonShadow() {
        guard let centerButton = centerButton else { return }
        centerButton.layer.shadowColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.5).cgColor
            : UIColor.black.cgColor
    }
}
