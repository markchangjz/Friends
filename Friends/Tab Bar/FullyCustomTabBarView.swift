//
//  FullyCustomTabBarView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/30.
//

import UIKit

protocol FullyCustomTabBarViewDelegate: AnyObject {
    func tabBarView(_ tabBarView: FullyCustomTabBarView, didSelectTabAt index: Int)
}

class FullyCustomTabBarView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: FullyCustomTabBarViewDelegate?
    private var selectedIndex: Int = 1
    
    private var backgroundView: UIView!
    private var stackView: UIStackView!
    private var tabButtons: [UIView] = [] // Changed to UIView to contain button + label
    private var centerButton: UIButton!
    private var centerButtonContainer: UIView!
    private var topBorderLine: UIView! // Add top border line
    
    private let tabItems: [TabBarItem] = [.products, .friends, .home, .manage, .settings]
    
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
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.updateAppearance()
            }
        }
    }
    
    private func setupBackground() {
        // Background view with custom color
        backgroundView = UIView()
        backgroundView.backgroundColor = DesignConstants.Colors.tabBarBackground
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
        // Create a custom view that will contain the border with cutout
        topBorderLine = UIView()
        topBorderLine.backgroundColor = UIColor.clear // Make container transparent
        topBorderLine.isUserInteractionEnabled = false // Allow touches to pass through
        topBorderLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topBorderLine)
        
        NSLayoutConstraint.activate([
            topBorderLine.topAnchor.constraint(equalTo: topAnchor),
            topBorderLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorderLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorderLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure layout is complete before creating border
        // Check if center button has valid frame
        if let centerButtonFrame = centerButton?.frame,
           let containerFrame = centerButtonContainer?.frame,
           centerButtonFrame.width > 0 && centerButtonFrame.height > 0,
           containerFrame.width > 0 && containerFrame.height > 0 {
            // Create the border path with cutout for center button
            createBorderWithCutout()
        } else {
            // If frames are not ready, delay to next run loop
            DispatchQueue.main.async { [weak self] in
                self?.createBorderWithCutout()
            }
        }
        
        // Ensure border is above button and its shadow so it's not obscured
        // topBorderLine has isUserInteractionEnabled = false, so touches pass through
        // Bring button first, then border on top to ensure border is visible above shadow
        bringSubviewToFront(centerButtonContainer)
        bringSubviewToFront(topBorderLine)
    }
    
    private func createBorderWithCutout() {
        // Remove existing border layers
        topBorderLine.layer.sublayers?.removeAll()
        
        // Get center button's actual position and size
        guard let centerButtonFrame = centerButton?.frame,
              let containerFrame = centerButtonContainer?.frame,
              centerButtonFrame.width > 0 && centerButtonFrame.height > 0,
              containerFrame.width > 0 && containerFrame.height > 0 else {
            return
        }
        
        let borderWidth = bounds.width
        let centerX = bounds.width / 2
        let borderY: CGFloat = 0.25 // Border at TabBar top (center of 0.5pt line)
        
        // Get center button's position in our coordinate system
        // Convert from container's coordinate system to view's coordinate system
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
        
        // Create a single combined path to ensure seamless connection
        let combinedPath = UIBezierPath()
        
        // Left border line
        combinedPath.move(to: CGPoint(x: 0, y: borderY))
        combinedPath.addLine(to: leftConnectionPoint)
        
        // Arc (semicircle going upward from left to right, above the border)
        combinedPath.addArc(
            withCenter: CGPoint(x: centerX, y: arcCenterY),
            radius: cutoutRadius,
            startAngle: leftAngle,   // Start from left connection point
            endAngle: rightAngle,    // End at right connection point
            clockwise: true        // clockwise to go upward
        )
        
        // Right border line
        combinedPath.addLine(to: CGPoint(x: borderWidth, y: borderY))
        
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
        
        // Create layer for straight lines
        let straightLayer = CAShapeLayer()
        straightLayer.path = straightPath.cgPath
        straightLayer.strokeColor = DesignConstants.Colors.tabBarTopBorder.cgColor
        straightLayer.fillColor = UIColor.clear.cgColor
        straightLayer.lineWidth = borderLineWidth
        straightLayer.lineCap = .round
        straightLayer.lineJoin = .round
        
        // Create layer for arc with slightly thicker line to compensate for shadow
        let arcLayer = CAShapeLayer()
        arcLayer.path = arcPath.cgPath
        arcLayer.strokeColor = DesignConstants.Colors.tabBarTopBorder.cgColor
        arcLayer.fillColor = UIColor.clear.cgColor
        arcLayer.lineWidth = borderLineWidth + 0.2 // Slightly thicker to compensate for shadow
        arcLayer.lineCap = .round
        arcLayer.lineJoin = .round
        
        // Add both layers
        topBorderLine.layer.addSublayer(straightLayer)
        topBorderLine.layer.addSublayer(arcLayer)
    }
    
    private func setupTabButtons() {
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Create tab buttons with proper indexing
        for (index, item) in tabItems.enumerated() {
            if index == 2 { // Home tab - center button placeholder
                let spacerView = UIView()
                stackView.addArrangedSubview(spacerView)
                tabButtons.append(spacerView)
            } else {
                let tabContainer = createTabContainer(for: item, at: index)
                tabButtons.append(tabContainer)
                stackView.addArrangedSubview(tabContainer)
            }
        }
        
        // Position stack view considering safe area
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 3),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 48) // Further reduced height for no spacing
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
        
        // Create button for the icon
        let button = UIButton(type: .custom)
        button.tag = index
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure image
        if let image = UIImage(systemName: item.imageName) {
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium) // Increased icon size
            let resizedImage = image.withConfiguration(config)
            button.setImage(resizedImage, for: .normal)
        }
        
        button.tintColor = DesignConstants.Colors.warmGrey
        button.imageView?.contentMode = .scaleAspectFit
        
        // Create label for the text
        let label = UILabel()
        label.text = item.title
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular) // Reduced font size to 14pt
        label.textColor = DesignConstants.Colors.warmGrey
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to vertical stack
        verticalStack.addArrangedSubview(button)
        verticalStack.addArrangedSubview(label)
        
        // Add stack to container
        container.addSubview(verticalStack)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Button size
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28),
            
            // Vertical stack constraints
            verticalStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            verticalStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 2),
            verticalStack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -2)
        ])
        
        // Add tap gesture to the entire container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tabContainerTapped(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        // Also add target to button as backup
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        // Store references for later updates
        button.accessibilityIdentifier = "button_\(index)"
        label.accessibilityIdentifier = "label_\(index)"
        
        return container
    }
    
    private func setupCenterButton() {
        // Container for elevated button
        centerButtonContainer = UIView()
        centerButtonContainer.backgroundColor = .clear
        centerButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerButtonContainer)
        
        // Center button
        centerButton = UIButton(type: .custom)
        centerButton.backgroundColor = DesignConstants.Colors.background
        centerButton.layer.cornerRadius = 30
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 12)
        centerButton.layer.shadowRadius = 12
        centerButton.layer.shadowOpacity = 0.1
        centerButton.tag = 2 // Home tab index
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Set home icon
        if let homeImage = UIImage(systemName: TabBarItem.home.imageName) {
            let config = UIImage.SymbolConfiguration(pointSize: 46, weight: .medium)
            let resizedImage = homeImage.withConfiguration(config)
            centerButton.setImage(resizedImage, for: .normal)
        }
        centerButton.tintColor = DesignConstants.Colors.warmGrey
        
        centerButtonContainer.addSubview(centerButton)
        
        // Add target
        centerButton.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container constraints
            centerButtonContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerButtonContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: -25),
            centerButtonContainer.widthAnchor.constraint(equalToConstant: 85),
            centerButtonContainer.heightAnchor.constraint(equalToConstant: 65),
            
            // Button constraints
            centerButton.centerXAnchor.constraint(equalTo: centerButtonContainer.centerXAnchor),
            centerButton.centerYAnchor.constraint(equalTo: centerButtonContainer.centerYAnchor, constant: 5),
            centerButton.widthAnchor.constraint(equalToConstant: 60),
            centerButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func tabContainerTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = gesture.view else { return }
        let index = container.tag
        selectedIndex = index
        updateAppearance()
        delegate?.tabBarView(self, didSelectTabAt: index)
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        let index = sender.tag
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
        for (arrayIndex, container) in tabButtons.enumerated() {
            if arrayIndex == 2 { continue } // Skip center button (handled separately)
            
            let isSelected = arrayIndex == selectedIndex
            let selectedColor = isSelected ? DesignConstants.Colors.hotPink : DesignConstants.Colors.warmGrey
            
            // Find button and label in container using recursive search
            updateContainerAppearance(container, isSelected: isSelected, color: selectedColor, index: arrayIndex)
        }
        
        // Update center button
        let isCenterSelected = selectedIndex == 2
        centerButton.tintColor = isCenterSelected ? DesignConstants.Colors.hotPink : DesignConstants.Colors.warmGrey
    }
    
    private func updateContainerAppearance(_ view: UIView, isSelected: Bool, color: UIColor, index: Int) {
        for subview in view.subviews {
            if let button = subview as? UIButton, button.accessibilityIdentifier == "button_\(index)" {
                button.tintColor = color
            } else if let label = subview as? UILabel, label.accessibilityIdentifier == "label_\(index)" {
                label.textColor = color
                // Use system font with appropriate weight
                label.font = UIFont.systemFont(ofSize: 14, weight: isSelected ? .medium : .regular)
            } else if let stackView = subview as? UIStackView {
                // Handle UIStackView case
                for arrangedSubview in stackView.arrangedSubviews {
                    if let button = arrangedSubview as? UIButton, button.accessibilityIdentifier == "button_\(index)" {
                        button.tintColor = color
                    } else if let label = arrangedSubview as? UILabel, label.accessibilityIdentifier == "label_\(index)" {
                        label.textColor = color
                        // Use system font with appropriate weight
                        label.font = UIFont.systemFont(ofSize: 14, weight: isSelected ? .medium : .regular)
                    }
                }
            }
        }
    }
    
    private func updateCenterButtonShadow() {
        switch traitCollection.userInterfaceStyle {
        case .dark:
            centerButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        default:
            centerButton.layer.shadowColor = UIColor.black.cgColor
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Extend hit test area for center button
        if centerButtonContainer.frame.contains(point) {
            let convertedPoint = convert(point, to: centerButtonContainer)
            if centerButton.frame.contains(convertedPoint) {
                return centerButton
            }
        }
        return super.hitTest(point, with: event)
    }
}
