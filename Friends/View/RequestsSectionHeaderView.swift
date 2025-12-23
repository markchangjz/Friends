//
//  RequestsSectionHeaderView.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/23.
//

import UIKit

protocol RequestsSectionHeaderViewDelegate: AnyObject {
    func requestsSectionHeaderViewDidTap(_ headerView: RequestsSectionHeaderView)
}

class RequestsSectionHeaderView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: RequestsSectionHeaderViewDelegate?
    
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
        
        // 添加點擊手勢
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Public Methods
    
    /// 配置 header view
    /// - Parameters:
    ///   - title: 標題文字
    ///   - isExpanded: 是否展開狀態
    func configure(title: String, isExpanded: Bool) {
        titleLabel.text = title
        updateArrowImage(isExpanded: isExpanded)
    }
    
    /// 更新箭頭圖示
    /// - Parameter isExpanded: 是否展開狀態
    func updateArrowImage(isExpanded: Bool) {
        let arrowImage = UIImage(systemName: isExpanded ? "chevron.down" : "chevron.right")
        arrowImageView.image = arrowImage
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        delegate?.requestsSectionHeaderViewDidTap(self)
    }
}

