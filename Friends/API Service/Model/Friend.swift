//
//  Friend.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation

struct Friend: Decodable {
    
    let name: String
    let status: FriendStatus
    let isTop: Bool
    let fid: String
    let updateDate: String
    
    enum FriendStatus: Int {
        case unknown = -1       // 未知狀態
        case requestSent = 0    // 邀請送出
        case accepted = 1       // 已完成
        case pending = 2        // 邀請中
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case name
        case status
        case isTop
        case fid
        case updateDate
    }
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        fid = try container.decode(String.self, forKey: .fid)
        updateDate = try container.decode(String.self, forKey: .updateDate)
        
        // 將 status Int 轉換成 FriendStatus，預設 .unknown
        if let statusInt = try? container.decode(Int.self, forKey: .status),
           let friendStatus = FriendStatus(rawValue: statusInt) {
            status = friendStatus
        } else {
            status = .unknown
        }
        
        // 將 "1" 轉成 true，"0" 轉成 false，預設 false
        if let isTopString = try? container.decode(String.self, forKey: .isTop) {
            isTop = isTopString == "1"
        } else {
            isTop = false
        }
    }
    
    // MARK: - API Response Wrapper
    struct Response: Decodable {
        let response: [Friend]
    }
}
