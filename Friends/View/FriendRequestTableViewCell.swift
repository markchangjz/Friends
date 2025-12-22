//
//  FriendRequestTableViewCell.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import UIKit

class FriendRequestTableViewCell: UITableViewCell {
    
    static let identifier = "FriendRequestTableViewCell"
    
    // UI 元件
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let invitationLabel: UILabel = {
        let label = UILabel()
        label.text = "邀請你成為好友：）"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 236/255, green: 0/255, blue: 140/255, alpha: 1.0)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let rejectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemGray3
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(invitationLabel)
        contentView.addSubview(acceptButton)
        contentView.addSubview(rejectButton)
        
        NSLayoutConstraint.activate([
            // Avatar
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 15),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            
            // Invitation Label
            invitationLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 15),
            invitationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            invitationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
            
            // Reject Button
            rejectButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            rejectButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rejectButton.widthAnchor.constraint(equalToConstant: 40),
            rejectButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Accept Button
            acceptButton.trailingAnchor.constraint(equalTo: rejectButton.leadingAnchor, constant: -15),
            acceptButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            acceptButton.widthAnchor.constraint(equalToConstant: 40),
            acceptButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with friend: Friend) {
        nameLabel.text = friend.name
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        avatarImageView.image = nil
    }
}
