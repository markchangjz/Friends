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
        // 使用稍微比背景深/淺一點的顏色作為骨架屏底色
        backgroundColor = DesignConstants.Colors.divider
        
        // 設置漸變層為高亮掃光
        // 在深色模式下用稍微亮的灰色，淺色模式用純白
        let highlightColor = UIColor.white.withAlphaComponent(0.3).cgColor
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            highlightColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        layer.addSublayer(gradientLayer)
        
        // 監聽介面風格變化
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: ShimmerView, _: UITraitCollection) in
            self?.backgroundColor = DesignConstants.Colors.divider
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 漸變層需要比 view 寬，以便隱藏在側邊
        gradientLayer.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
        
        if !isHidden {
            startAnimating()
        }
    }
    
    func startAnimating() {
        stopAnimating()
        guard bounds.width > 0 else { return }
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -bounds.width * 2
        animation.toValue = bounds.width * 2
        animation.duration = 1.2
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        gradientLayer.add(animation, forKey: "shimmer_animation")
    }
    
    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer_animation")
    }
}

