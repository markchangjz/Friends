//
//  FullyCustomTabBarController.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/30.
//

import UIKit

class FullyCustomTabBarController: UITabBarController {
    
    // MARK: - Properties
    
    private var customTabBarView: FullyCustomTabBarView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupUI()
        // Set default selected index after UI is set up
        // The didSet of selectedIndex will automatically update customTabBarView
        selectedIndex = 1 // Default to Friends tab
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Hide the default tab bar
        tabBar.isHidden = true
        
        // Create custom tab bar
        customTabBarView = FullyCustomTabBarView()
        customTabBarView.delegate = self
        customTabBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBarView)
        
        // Setup constraints with proper safe area handling
        NSLayoutConstraint.activate([
            // Custom tab bar constraints - extend to bottom of screen
            customTabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -55)
        ])
    }
    
    private func setupViewControllers() {
        var controllers: [UIViewController] = []
        
        // 1. Products Tab (錢錢)
        let productsVC = createPlaceholderViewController(title: TabBarItem.products.title, backgroundColor: DesignConstants.Colors.background)
        let productsNavController = UINavigationController(rootViewController: productsVC)
        controllers.append(productsNavController)
        
        // 2. Friends Tab (朋友)
        let friendsVC = FriendsViewController()
        let friendsNavController = UINavigationController(rootViewController: friendsVC)
        controllers.append(friendsNavController)
        
        // 3. Home Tab (首頁)
        let homeVC = createPlaceholderViewController(title: TabBarItem.home.title, backgroundColor: DesignConstants.Colors.background)
        let homeNavController = UINavigationController(rootViewController: homeVC)
        controllers.append(homeNavController)
        
        // 4. Manage Tab (記帳)
        let manageVC = createPlaceholderViewController(title: TabBarItem.manage.title, backgroundColor: DesignConstants.Colors.background)
        let manageNavController = UINavigationController(rootViewController: manageVC)
        controllers.append(manageNavController)
        
        // 5. Settings Tab (設定)
        let settingsVC = createPlaceholderViewController(title: TabBarItem.settings.title, backgroundColor: DesignConstants.Colors.background)
        let settingsNavController = UINavigationController(rootViewController: settingsVC)
        controllers.append(settingsNavController)
        
        // Set view controllers to UITabBarController
        viewControllers = controllers
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
    
    // MARK: - Override UITabBarController Methods
    
    override var selectedIndex: Int {
        didSet {
            // Update custom tab bar appearance when selectedIndex changes
            customTabBarView?.updateSelectedIndex(selectedIndex)
        }
    }
    
    override var selectedViewController: UIViewController? {
        didSet {
            // Update custom tab bar appearance when selectedViewController changes
            if let index = viewControllers?.firstIndex(where: { $0 == selectedViewController }) {
                customTabBarView?.updateSelectedIndex(index)
            }
        }
    }
}

// MARK: - FullyCustomTabBarViewDelegate

extension FullyCustomTabBarController: FullyCustomTabBarViewDelegate {
    func tabBarView(_ tabBarView: FullyCustomTabBarView, didSelectTabAt index: Int) {
        // Use UITabBarController's selectedIndex to switch tabs
        selectedIndex = index
    }
}
