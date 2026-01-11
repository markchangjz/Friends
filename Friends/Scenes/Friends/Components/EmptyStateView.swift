//
//  EmptyStateView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

class EmptyStateView: UIView {
    
    // MARK: - UI Components
    
    private let illustrationImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let addFriendButton = UIButton(type: .custom)
    private let buttonLabel = UILabel()
    private let addFriendIconView = UIImageView() 
    private let helpButton = UIButton(type: .system)
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .koBackground
        
        // 插圖設定
        illustrationImageView.image = UIImage(named: "imgFriendsEmpty")
        illustrationImageView.contentMode = .scaleAspectFit
        illustrationImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(illustrationImageView)
        
        // 主標題設定
        titleLabel.text = "就從加好友開始吧：）"
        titleLabel.font = .systemFont(ofSize: 21, weight: .medium)
        titleLabel.textColor = .koLightGrey
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // 副標題設定
        subtitleLabel.text = "與好友們一起用 KOKO 聊起來！\n還能互相收付款、發紅包喔：）"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .koWarmGrey
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        // 加好友按鈕設定
        addFriendButton.backgroundColor = .clear
        addFriendButton.layer.cornerRadius = 20
        addFriendButton.layer.masksToBounds = false
        
        // 綠色漸變背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: "56B30B").cgColor,
            UIColor(hex: "A6CC42").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.cornerRadius = 20
        addFriendButton.layer.insertSublayer(gradientLayer, at: 0)
        
        // 陰影
        addFriendButton.layer.shadowColor = UIColor(hex: "79C41B", alpha: 0.4).cgColor
        addFriendButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addFriendButton.layer.shadowRadius = 8
        addFriendButton.layer.shadowOpacity = 1.0
        
        // 點擊高亮效果處理
        addFriendButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        addFriendButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // 加好友按鈕內容設定 - 實現文字置中、圖示固定靠右
        buttonLabel.text = "加好友"
        buttonLabel.font = .systemFont(ofSize: 16, weight: .medium)
        buttonLabel.textColor = .white
        buttonLabel.translatesAutoresizingMaskIntoConstraints = false
        addFriendButton.addSubview(buttonLabel)
        
        if let iconImage = UIImage(named: "icAddFriendWhite") {
            addFriendIconView.image = iconImage
            addFriendIconView.contentMode = .scaleAspectFit
            addFriendIconView.translatesAutoresizingMaskIntoConstraints = false
            addFriendButton.addSubview(addFriendIconView)
        }
        
        addFriendButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addFriendButton)
        
        // 幫助按鈕設定
        let helpText = "幫助好友更快找到你？設定 KOKO ID"
        let attributedString = NSMutableAttributedString(string: helpText)
        let range = (helpText as NSString).range(of: "設定 KOKO ID")
        attributedString.addAttribute(.foregroundColor, value: UIColor.koWarmGrey, range: NSRange(location: 0, length: helpText.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor.koHotPink, range: range)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 13, weight: .regular), range: NSRange(location: 0, length: helpText.count))
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        
        helpButton.setAttributedTitle(attributedString, for: .normal)
        helpButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(helpButton)
        
        setupConstraints()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 更新漸變圖層的 frame，確保填滿整個按鈕
        if let gradientLayer = addFriendButton.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = addFriendButton.bounds
        }
    }
    
    private func setupConstraints() {
        // 作為 tableFooterView 時，頂部對齊 Header 底部，間距設為 30pt
        let topOffset: CGFloat = 30
        
        NSLayoutConstraint.activate([
            // 插圖
            illustrationImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            illustrationImageView.topAnchor.constraint(equalTo: topAnchor, constant: topOffset),
            illustrationImageView.widthAnchor.constraint(equalToConstant: 245),
            illustrationImageView.heightAnchor.constraint(equalToConstant: 172),
            
            titleLabel.topAnchor.constraint(equalTo: illustrationImageView.bottomAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 287),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.widthAnchor.constraint(equalToConstant: 240),
            
            addFriendButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 25),
            addFriendButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            addFriendButton.widthAnchor.constraint(equalToConstant: 192),
            addFriendButton.heightAnchor.constraint(equalToConstant: 40),
            
            buttonLabel.centerXAnchor.constraint(equalTo: addFriendButton.centerXAnchor),
            buttonLabel.centerYAnchor.constraint(equalTo: addFriendButton.centerYAnchor),
            
            addFriendIconView.trailingAnchor.constraint(equalTo: addFriendButton.trailingAnchor, constant: -8),
            addFriendIconView.centerYAnchor.constraint(equalTo: addFriendButton.centerYAnchor),
            addFriendIconView.widthAnchor.constraint(equalToConstant: 24),
            addFriendIconView.heightAnchor.constraint(equalToConstant: 24),
            
            helpButton.topAnchor.constraint(equalTo: addFriendButton.bottomAnchor, constant: 37),
            helpButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            helpButton.widthAnchor.constraint(equalToConstant: 289),
            helpButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) { [weak self] in
            guard let self else { return }
            self.addFriendButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.addFriendButton.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) { [weak self] in
            guard let self else { return }
            self.addFriendButton.transform = .identity
            self.addFriendButton.alpha = 1.0
        }
    }
}
