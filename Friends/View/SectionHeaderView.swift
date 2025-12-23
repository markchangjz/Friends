//
//  SectionHeaderView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

protocol SectionHeaderViewDelegate: AnyObject {
    func sectionHeaderViewDidTap(_ headerView: SectionHeaderView)
}

class SectionHeaderView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: SectionHeaderViewDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
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
        backgroundColor = .systemBackground
        
        addSubview(titleLabel)
        addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            arrowImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    // MARK: - Public Methods
    
    /// 配置 header view
    /// - Parameters:
    ///   - title: 標題文字
    ///   - isExpanded: 展開狀態，nil 表示不可折疊，true/false 表示可折疊且當前的展開狀態（預設為 true）
    func configure(title: String, isExpanded: Bool? = true) {
        titleLabel.text = title
        
        if let isExpanded = isExpanded {
            // 可折疊：顯示箭頭並添加點擊手勢
            arrowImageView.isHidden = false
            updateArrowImage(isExpanded: isExpanded)
            
            // 確保有點擊手勢（如果還沒添加）
            if gestureRecognizers?.isEmpty ?? true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
                addGestureRecognizer(tapGesture)
            }
            isUserInteractionEnabled = true
        } else {
            // 不可折疊：隱藏箭頭，移除點擊手勢
            arrowImageView.isHidden = true
            gestureRecognizers?.forEach { removeGestureRecognizer($0) }
            isUserInteractionEnabled = false
        }
    }
    
    /// 更新箭頭圖示
    /// - Parameter isExpanded: 是否展開狀態
    func updateArrowImage(isExpanded: Bool) {
        let arrowImage = UIImage(systemName: isExpanded ? "chevron.down" : "chevron.right")
        arrowImageView.image = arrowImage
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        delegate?.sectionHeaderViewDidTap(self)
    }
}

