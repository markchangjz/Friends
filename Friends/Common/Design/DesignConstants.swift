//
//  DesignConstants.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

// MARK: - UIColor Extension

extension UIColor {
    /// 從 hex 字串建立 UIColor
    /// - Parameters:
    ///   - hex: hex 字串，格式為 "RRGGBB" 或 "#RRGGBB"
    ///   - alpha: 透明度，預設為 1.0
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // MARK: - Koko App 自訂顏色
    
    /// 背景色（支援 Dark Mode）
    static var koBackground: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "1C1C1E")
            default:
                return UIColor(hex: "FCFCFC")
            }
        }
    }
    
    /// 淺灰色文字（支援 Dark Mode）
    static var koLightGrey: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "E5E5EA")
            default:
                return UIColor(hex: "474747")
            }
        }
    }
    
    /// 暖灰色（支援 Dark Mode）
    static var koWarmGrey: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "AEAEB2")
            default:
                return UIColor(hex: "999999")
            }
        }
    }
    
    /// 鋼鐵灰（支援 Dark Mode）
    static var koSteel: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "AEAEB2")
            default:
                return UIColor(hex: "8E8E93")
            }
        }
    }
    
    /// 主色調（熱粉紅）
    static var koHotPink: UIColor {
        UIColor(hex: "EC008C")
    }
    
    /// 分隔線顏色（支援 Dark Mode）
    static var koDivider: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "3A3A3C")
            default:
                return UIColor(hex: "E4E4E4")
            }
        }
    }
    
    /// 淺色分隔線（支援 Dark Mode）
    static var koDividerLight: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "3A3A3C")
            default:
                return UIColor(hex: "EFEFEF")
            }
        }
    }
    
    /// 按鈕邊框灰色（支援 Dark Mode）
    static var koButtonBorderGray: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "636366")
            default:
                return UIColor(hex: "C9C9C9")
            }
        }
    }
    
    /// 星號背景色（不變）
    static var koStarBackground: UIColor {
        UIColor(hex: "F4B400")
    }
    
    /// 搜尋列背景（支援 Dark Mode）
    static var koSearchBarBackground: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "8E8E93", alpha: 0.24)
            default:
                return UIColor(hex: "8E8E93", alpha: 0.12)
            }
        }
    }
    
    /// Cell 背景色（支援 Dark Mode）
    static var koCellBackground: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "1C1C1E")
            default:
                return UIColor(hex: "FCFCFC")
            }
        }
    }
    
    /// Tab Bar 背景色（支援 Dark Mode）
    static var koTabBarBackground: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "161618")
            default:
                return UIColor(hex: "F8F8F8")
            }
        }
    }
    
    /// Tab Bar 上邊框線（支援 Dark Mode）
    static var koTabBarTopBorder: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: "636366")
            default:
                return UIColor(hex: "C8C8C8")
            }
        }
    }
    
    /// Badge 背景色
    static var koBadgeBackground: UIColor {
        UIColor(hex: "F9B2DC")
    }
    
    /// Badge 文字顏色（支援 Dark Mode）
    static var koBadgeTextColor: UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return .darkGray
            default:
                return .white
            }
        }
    }
}
