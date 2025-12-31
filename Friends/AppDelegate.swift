//
//  AppDelegate.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setupNavigationBarAppearance()
        return true
    }
    
    private func setupNavigationBarAppearance() {
        // 設定全域 Navigation Bar 外觀
        let appearance = UINavigationBarAppearance()
        if #available(iOS 26.0, *) {
            // iOS 26+ 使用預設背景設置即可獲得最佳的液態玻璃效果
            appearance.configureWithDefaultBackground()
        } else {
            appearance.configureWithDefaultBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .regular)
        }
        appearance.shadowColor = .clear // 移除底部陰影線
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

