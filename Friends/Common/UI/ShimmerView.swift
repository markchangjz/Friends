//
//  ShimmerView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

class ShimmerView: UIView {
    
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShimmer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupShimmer()
    }
    
    private func setupShimmer() {
        backgroundColor = DesignConstants.Colors.divider
        
        let light = UIColor.clear.cgColor
        let alpha = UIColor.white.withAlphaComponent(0.3).cgColor
        
        gradientLayer.colors = [alpha, light, alpha]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.525)
        gradientLayer.locations = [0.4, 0.5, 0.6]
        
        layer.mask = gradientLayer
        
        // 監聽介面風格變化
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: ShimmerView, _: UITraitCollection) in
            self?.backgroundColor = DesignConstants.Colors.divider
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 設定 gradientLayer 覆蓋整個 view 並延伸
        gradientLayer.frame = CGRect(
            x: -bounds.width,
            y: 0,
            width: bounds.width * 3,
            height: bounds.height
        )
        
        // 如果 bounds 有效且 view 不是隱藏的，在下一個 run loop 中重新啟動動畫
        if bounds.width > 0 && bounds.height > 0 && !isHidden {
            DispatchQueue.main.async { [weak self] in
                self?.restartAnimationIfNeeded()
            }
        }
    }
    
    private func restartAnimationIfNeeded() {
        // 檢查是否已經有動畫在執行
        if gradientLayer.animation(forKey: "shimmer") == nil {
            startAnimating()
        }
    }
    
    func startAnimating() {
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        gradientLayer.removeAnimation(forKey: "shimmer")
        
        // 設定 gradientLayer 的 frame
        gradientLayer.frame = CGRect(
            x: -bounds.width,
            y: 0,
            width: bounds.width * 3,
            height: bounds.height
        )
        
        // 關鍵：動畫 locations 屬性而不是 transform
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(animation, forKey: "shimmer")
    }
    
    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer")
        layer.mask = nil
    }
}

