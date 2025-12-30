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
