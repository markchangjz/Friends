//
//  DesignConstants.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

struct DesignConstants {
    
    // MARK: - Colors
    
    struct Colors {
        // 背景顏色（支援 Dark Mode）
        static let background = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0) // 深色模式背景
            default:
                return UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1.0) // 淺色模式背景
            }
        }
        
        // 文字顏色（支援 Dark Mode）
        static let lightGrey = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1.0) // 深色模式文字
            default:
                return UIColor(red: 71/255, green: 71/255, blue: 71/255, alpha: 1.0) // 淺色模式文字
            }
        }
        
        static let warmGrey = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 174/255, green: 174/255, blue: 178/255, alpha: 1.0) // 深色模式
            default:
                return UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0) // 淺色模式
            }
        }
        
        static let steel = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 174/255, green: 174/255, blue: 178/255, alpha: 1.0) // 深色模式
            default:
                return UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1.0) // 淺色模式
            }
        }
        
        // 主色調（不變）
        static let hotPink = UIColor(red: 236/255, green: 0/255, blue: 140/255, alpha: 1.0) // rgb(236, 0, 140)
        
        // 分隔線（支援 Dark Mode）
        static let divider = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 58/255, green: 58/255, blue: 60/255, alpha: 1.0) // 深色模式
            default:
                return UIColor(red: 228/255, green: 228/255, blue: 228/255, alpha: 1.0) // 淺色模式
            }
        }
        
        static let dividerLight = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 58/255, green: 58/255, blue: 60/255, alpha: 1.0) // 深色模式
            default:
                return UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1.0) // 淺色模式
            }
        }
        
        // 按鈕邊框（支援 Dark Mode）
        static let buttonBorderGray = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // 深色模式
            default:
                return UIColor(red: 201/255, green: 201/255, blue: 201/255, alpha: 1.0) // 淺色模式
            }
        }
        
        // 星號背景（不變）
        static let starBackground = UIColor(red: 244/255, green: 180/255, blue: 0/255, alpha: 1.0) // rgb(244, 180, 0)
        
        // 搜尋列背景（支援 Dark Mode）
        static let searchBarBackground = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 0.24) // 深色模式，提高不透明度
            default:
                return UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 0.12) // 淺色模式
            }
        }
        
        // Cell 背景色（支援 Dark Mode）
        static let cellBackground = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0) // 深色模式：與背景色相同
            default:
                return UIColor(red: 252/255, green: 252/255, blue: 252/255, alpha: 1.0) // 淺色模式：與背景色相同
            }
        }
        
        // Tab Bar 背景色（支援 Dark Mode）
        static let tabBarBackground = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 22/255, green: 22/255, blue: 24/255, alpha: 1.0) // 深色模式：稍微深一點
            default:
                return UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0) // 淺色模式：稍微深一點
            }
        }
        
        // Tab Bar 上邊框線（支援 Dark Mode）
        static let tabBarTopBorder = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 99/255, green: 99/255, blue: 102/255, alpha: 1.0) // 深色模式：較淺的灰色
            default:
                return UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1.0) // 淺色模式：較深的灰色
            }
        }
    }
    
    // MARK: - Typography
    
    struct Typography {
        // 姓名（大標題）
        static func nameFont() -> UIFont {
            return UIFont(name: "PingFangTC-Medium", size: 17) ?? .systemFont(ofSize: 17, weight: .medium)
        }
        
        // KOKO ID
        static func kokoIdFont() -> UIFont {
            return UIFont(name: "PingFangTC-Regular", size: 13) ?? .systemFont(ofSize: 13, weight: .regular)
        }
        
        // Tab 文字（Medium）
        static func tabMediumFont() -> UIFont {
            return UIFont(name: "PingFangTC-Medium", size: 13) ?? .systemFont(ofSize: 13, weight: .medium)
        }
        
        // Tab 文字（Regular）
        static func tabRegularFont() -> UIFont {
            return UIFont(name: "PingFangTC-Regular", size: 13) ?? .systemFont(ofSize: 13, weight: .regular)
        }
        
        // 搜尋列佔位符
        static func searchPlaceholderFont() -> UIFont {
            return UIFont(name: "PingFangTC-Regular", size: 14) ?? .systemFont(ofSize: 14, weight: .regular)
        }
        
        // 好友姓名
        static func friendNameFont() -> UIFont {
            return UIFont(name: "PingFangTC-Regular", size: 16) ?? .systemFont(ofSize: 16, weight: .regular)
        }
        
        // 按鈕文字
        static func buttonFont() -> UIFont {
            return UIFont(name: "PingFangTC-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        }
        
        // 邀請中按鈕文字
        static func invitationButtonFont() -> UIFont {
            return UIFont(name: "PingFangTC-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        }
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let horizontalPadding: CGFloat = 30
        static let avatarSize: CGFloat = 52
        static let friendAvatarSize: CGFloat = 40
        static let starSize: CGFloat = 14
        static let tabIndicatorHeight: CGFloat = 4
        static let tabIndicatorCornerRadius: CGFloat = 2
    }
}

