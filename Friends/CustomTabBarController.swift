//
//  CustomTabBarController.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/30.
//

import UIKit

class CustomTabBarController: UITabBarController {
    
    private var customTabBar: CustomTabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
        setupTabBar()
        setupViewControllers()
        
        // Register for trait changes using the new iOS 17+ API
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                // 當 Dark Mode 切換時更新 Tab Bar 外觀
                self.setupTabBar()
            }
        }
    }
    
    private func setupCustomTabBar() {
        // Replace the default tab bar with our custom one
        customTabBar = CustomTabBar()
        setValue(customTabBar, forKey: "tabBar")
    }
    
    private func setupTabBar() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // 支援 Dark Mode 的背景色，與 TabView 背景色有輕微差異
        appearance.backgroundColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                // 深色模式：稍微深一點以區分層次
                return UIColor(red: 22/255, green: 22/255, blue: 24/255, alpha: 1.0)
            default:
                // 淺色模式：稍微深一點以區分層次
                return UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0)
            }
        }
        
        // Remove the top border line
        appearance.shadowColor = .clear
        
        // Configure normal state - only icon color since we're not showing text
        appearance.stackedLayoutAppearance.normal.iconColor = DesignConstants.Colors.warmGrey
        
        // Configure selected state - only icon color since we're not showing text
        appearance.stackedLayoutAppearance.selected.iconColor = DesignConstants.Colors.hotPink
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        // Set tint colors
        tabBar.tintColor = DesignConstants.Colors.hotPink
        tabBar.unselectedItemTintColor = DesignConstants.Colors.warmGrey
    }
    
    private func setupViewControllers() {
        var controllers: [UIViewController] = []
        
        // 1. Products Tab (錢錢)
        let productsVC = createPlaceholderViewController(title: TabBarItem.products.title, backgroundColor: DesignConstants.Colors.background)
        let productsNavController = UINavigationController(rootViewController: productsVC)
        productsNavController.tabBarItem = UITabBarItem(
            title: TabBarItem.products.title,
            image: UIImage(systemName: TabBarItem.products.imageName),
            tag: TabBarItem.products.rawValue
        )
        controllers.append(productsNavController)
        
        // 2. Friends Tab (朋友) - Use existing FriendsViewController
        let friendsVC = FriendsViewController()
        let friendsNavController = UINavigationController(rootViewController: friendsVC)
        friendsNavController.tabBarItem = UITabBarItem(
            title: TabBarItem.friends.title,
            image: UIImage(systemName: TabBarItem.friends.imageName),
            tag: TabBarItem.friends.rawValue
        )
        controllers.append(friendsNavController)
        
        // 3. Home Tab (首頁) - Center tab with special design (invisible tab item)
        let homeVC = createPlaceholderViewController(title: TabBarItem.home.title, backgroundColor: DesignConstants.Colors.background)
        let homeNavController = UINavigationController(rootViewController: homeVC)
        // Create an invisible tab item since we're using a custom center button
        homeNavController.tabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil)
        homeNavController.tabBarItem.isEnabled = false
        controllers.append(homeNavController)
        
        // 4. Manage Tab (記帳)
        let manageVC = createPlaceholderViewController(title: TabBarItem.manage.title, backgroundColor: DesignConstants.Colors.background)
        let manageNavController = UINavigationController(rootViewController: manageVC)
        manageNavController.tabBarItem = UITabBarItem(
            title: TabBarItem.manage.title,
            image: UIImage(systemName: TabBarItem.manage.imageName),
            tag: TabBarItem.manage.rawValue
        )
        controllers.append(manageNavController)
        
        // 5. Setting Tab (設定)
        let settingVC = createPlaceholderViewController(title: TabBarItem.settings.title, backgroundColor: DesignConstants.Colors.background)
        let settingNavController = UINavigationController(rootViewController: settingVC)
        settingNavController.tabBarItem = UITabBarItem(
            title: TabBarItem.settings.title,
            image: UIImage(systemName: TabBarItem.settings.imageName),
            tag: TabBarItem.settings.rawValue
        )
        controllers.append(settingNavController)
        
        viewControllers = controllers
        
        // Set default selected tab to Friends (index 1) as specified
        selectedIndex = 1
        
        // Set delegate to handle tab selection
        delegate = self
    }
    
    private func createPlaceholderViewController(title: String, backgroundColor: UIColor) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = backgroundColor
        vc.title = title
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textColor = DesignConstants.Colors.lightGrey
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])
        
        return vc
    }
}

// MARK: - UITabBarControllerDelegate

extension CustomTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // Update center button appearance based on selection
        customTabBar.updateCenterButtonAppearance(selected: selectedIndex == 2)
    }
}
