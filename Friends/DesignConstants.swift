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
        
        /// 從 hex 字串建立 UIColor
        /// - Parameters:
        ///   - hex: hex 字串，格式為 "RRGGBB" 或 "#RRGGBB"
        ///   - alpha: 透明度，預設為 1.0
        /// - Returns: UIColor 物件
        static func color(hex: String, alpha: CGFloat = 1.0) -> UIColor {
            var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
            
            var rgb: UInt64 = 0
            
            Scanner(string: hexSanitized).scanHexInt64(&rgb)
            
            let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(rgb & 0x0000FF) / 255.0
            
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        
        static let background = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "1C1C1E")
            default:
                return color(hex: "FCFCFC")
            }
        }
        
        static let lightGrey = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "E5E5EA")
            default:
                return color(hex: "474747")
            }
        }
        
        static let warmGrey = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "AEAEB2")
            default:
                return color(hex: "999999")
            }
        }
        
        static let steel = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "AEAEB2")
            default:
                return color(hex: "8E8E93")
            }
        }
        
        // 主色調
        static let hotPink = color(hex: "EC008C")
        
        static let divider = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "3A3A3C")
            default:
                return color(hex: "E4E4E4")
            }
        }
        
        static let dividerLight = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "3A3A3C")
            default:
                return color(hex: "EFEFEF")
            }
        }
        
        // 按鈕邊框
        static let buttonBorderGray = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "636366")
            default:
                return color(hex: "C9C9C9")
            }
        }
        
        // 星號背景（不變）
        static let starBackground = color(hex: "F4B400")
        
        // 搜尋列背景（支援 Dark Mode）
        static let searchBarBackground = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "8E8E93", alpha: 0.24)
            default:
                return color(hex: "8E8E93", alpha: 0.12)
            }
        }
        
        // Cell 背景色（支援 Dark Mode）
        static let cellBackground = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "1C1C1E")
            default:
                return color(hex: "FCFCFC")
            }
        }
        
        // Tab Bar 背景色
        static let tabBarBackground = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "161618")
            default:
                return color(hex: "F8F8F8")
            }
        }
        
        // Tab Bar 上邊框線
        static let tabBarTopBorder = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return color(hex: "636366")
            default:
                return color(hex: "C8C8C8")
            }
        }
        
        // Badge 背景色
        static let badgeBackground = color(hex: "F9B2DC")
        
        // Badge 文字顏色（支援 Dark Mode）
        static let badgeTextColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return .darkGray
            default:
                return .white
            }
        }
    }
}

