//
//  CustomTabBar.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/30.
//

import UIKit

enum TabBarItem: Int {
    case products
    case friends
    case home
    case manage
    case settings
    
    var imageName: String {
        switch self {
        case .products: return "wallet.bifold"
        case .friends: return "person.2"
        case .home: return "location.circle.fill"
        case .manage: return "book"
        case .settings: return "gearshape"
        }
    }
    
    var title: String {
        switch self {
        case .products: return "錢錢"
        case .friends: return "朋友"
        case .home: return "首頁"
        case .manage: return "記帳"
        case .settings: return "設定"
        }
    }
}

class CustomTabBar: UITabBar {
    
    private var centerButton: UIButton!
    private var centerButtonContainer: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCenterButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCenterButton()
    }
    
    private func setupCenterButton() {
        // Create container view for the elevated button
        centerButtonContainer = UIView()
        centerButtonContainer.backgroundColor = .clear
        centerButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerButtonContainer)
        
        // Create the center button with elevated design
        centerButton = UIButton(type: .custom)
        centerButton.backgroundColor = DesignConstants.Colors.background
        centerButton.layer.cornerRadius = 30 // Half of 60x60 size
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 12)
        centerButton.layer.shadowRadius = 12
        centerButton.layer.shadowOpacity = 0.1
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 更新陰影顏色以支援 Dark Mode
        updateShadowColor()
        
        // Set the home icon with larger font size
        if let homeImage = UIImage(systemName: TabBarItem.home.imageName) {
            let config = UIImage.SymbolConfiguration(pointSize: 46, weight: .medium)
            let resizedImage = homeImage.withConfiguration(config)
            centerButton.setImage(resizedImage.withRenderingMode(.alwaysTemplate), for: .normal)
            centerButton.tintColor = DesignConstants.Colors.warmGrey
        }
        
        centerButtonContainer.addSubview(centerButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container constraints
            centerButtonContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerButtonContainer.topAnchor.constraint(equalTo: topAnchor, constant: -25), // Elevated above tab bar
            centerButtonContainer.widthAnchor.constraint(equalToConstant: 85),
            centerButtonContainer.heightAnchor.constraint(equalToConstant: 65),
            
            // Button constraints
            centerButton.centerXAnchor.constraint(equalTo: centerButtonContainer.centerXAnchor),
            centerButton.centerYAnchor.constraint(equalTo: centerButtonContainer.centerYAnchor, constant: 5),
            centerButton.widthAnchor.constraint(equalToConstant: 60),
            centerButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Add target for button tap
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        
        // Register for trait changes using the new iOS 17+ API
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                // 當 Dark Mode 切換時更新陰影顏色
                self.updateShadowColor()
            }
        }
    }
    
    @objc private func centerButtonTapped() {
        // Notify the tab bar controller to switch to the center tab (index 2)
        if let tabBarController = self.delegate as? UITabBarController {
            tabBarController.selectedIndex = 2
            updateCenterButtonAppearance(selected: true)
        }
    }
    
    func updateCenterButtonAppearance(selected: Bool) {
        centerButton.tintColor = selected ? DesignConstants.Colors.hotPink : DesignConstants.Colors.warmGrey
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Extend hit test area to include the elevated center button
        if centerButtonContainer.frame.contains(point) {
            let convertedPoint = convert(point, to: centerButtonContainer)
            if centerButton.frame.contains(convertedPoint) {
                return centerButton
            }
        }
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Ensure center button stays on top
        bringSubviewToFront(centerButtonContainer)
    }
    
    private func updateShadowColor() {
        switch traitCollection.userInterfaceStyle {
        case .dark:
            centerButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor // 深色模式使用更明顯的陰影
        default:
            centerButton.layer.shadowColor = UIColor.black.cgColor // 淺色模式
        }
    }
}
