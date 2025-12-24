//
//  DateParser.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/24.
//

import Foundation

enum DateParser {
    
    // MARK: - Formatters
    
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
    
    // MARK: - Public Methods
    
    /// 嘗試解析多種格式的日期字串
    /// - Parameter dateString: 日期字串
    /// - Returns: 解析成功的 Date，若失敗則回傳 nil
    static func parse(dateString: String) -> Date? {
        if let date = slashDateFormatter.date(from: dateString) {
            return date
        }
        
        if let date = plainDateFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
}
