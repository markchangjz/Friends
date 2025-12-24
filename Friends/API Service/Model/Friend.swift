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
    let updateDate: Date
    
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
        
        // 解析 updateDate：支援 "yyyy/MM/dd" 或 "yyyyMMdd" 格式
        if let updateDateString = try? container.decode(String.self, forKey: .updateDate) {
            updateDate = Self.parseDate(from: updateDateString)
        } else {
            updateDate = Date() // 如果無法解碼字串，使用今天日期
        }
        
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
    
    // MARK: - Date Parsing Helper
    
    private static let slashDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    private static let plainDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
    
    private static func parseDate(from dateString: String) -> Date {
        if let date = slashDateFormatter.date(from: dateString) {
            return date
        }
        
        if let date = plainDateFormatter.date(from: dateString) {
            return date
        }
        
        // 如果都解析失敗，返回今天日期
        return Date()
    }
    
    // MARK: - API Response Wrapper
    struct Response: Decodable {
        let response: [Friend]
    }
}
