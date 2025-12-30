//
//  FullyCustomTabBarController.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/30.
//

import UIKit

class FullyCustomTabBarController: UIViewController {
    
    // MARK: - Properties
    
    private var viewControllers: [UIViewController] = []
    private var selectedIndex: Int = 1 {
        didSet {
            updateSelectedViewController()
            updateTabBarAppearance()
        }
    }
    
    private var containerView: UIView!
    private var customTabBarView: FullyCustomTabBarView!
    private var currentViewController: UIViewController?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewControllers()
        selectedIndex = 1 // Default to Friends tab
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = DesignConstants.Colors.background
        
        // Create container for view controllers
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Create custom tab bar
        customTabBarView = FullyCustomTabBarView()
        customTabBarView.delegate = self
        customTabBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTabBarView)
        
        // Setup constraints with proper safe area handling
        NSLayoutConstraint.activate([
            // Container view constraints
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: customTabBarView.topAnchor),
            
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
    
    // MARK: - View Controller Management
    
    private func updateSelectedViewController() {
        // Remove current view controller
        if let currentVC = currentViewController {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        // Add new view controller
        guard selectedIndex < viewControllers.count else { return }
        
        let newViewController = viewControllers[selectedIndex]
        addChild(newViewController)
        containerView.addSubview(newViewController.view)
        
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            newViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            newViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            newViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        newViewController.didMove(toParent: self)
        currentViewController = newViewController
    }
    
    private func updateTabBarAppearance() {
        customTabBarView.updateSelectedIndex(selectedIndex)
    }
}

// MARK: - FullyCustomTabBarViewDelegate

extension FullyCustomTabBarController: FullyCustomTabBarViewDelegate {
    func tabBarView(_ tabBarView: FullyCustomTabBarView, didSelectTabAt index: Int) {
        selectedIndex = index
    }
}