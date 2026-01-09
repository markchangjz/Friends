//
//  FriendModelTests.swift
//  FriendsTests
//
//  測試 Friend Model 的資料解析
//

import XCTest
@testable import Friends

final class FriendModelTests: XCTestCase {
    
    // MARK: - 測試基本解析
    
    func testFriendDecoding_ValidData() throws {
        // Given
        let jsonString = """
        {
            "name": "Alice",
            "status": 1,
            "isTop": "1",
            "fid": "001",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertEqual(friend.name, "Alice")
        XCTAssertEqual(friend.status, .accepted)
        XCTAssertTrue(friend.isTop)
        XCTAssertEqual(friend.fid, "001")
    }
    
    func testFriendDecoding_Status_RequestSent() throws {
        // Given
        let jsonString = """
        {
            "name": "Bob",
            "status": 0,
            "isTop": "0",
            "fid": "002",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertEqual(friend.status, .requestSent)
    }
    
    func testFriendDecoding_Status_Accepted() throws {
        // Given
        let jsonString = """
        {
            "name": "Charlie",
            "status": 1,
            "isTop": "0",
            "fid": "003",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertEqual(friend.status, .accepted)
    }
    
    func testFriendDecoding_Status_Pending() throws {
        // Given
        let jsonString = """
        {
            "name": "David",
            "status": 2,
            "isTop": "0",
            "fid": "004",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertEqual(friend.status, .pending)
    }
    
    func testFriendDecoding_InvalidStatus() throws {
        // Given - 無效的 status 值應該使用 .unknown
        let jsonString = """
        {
            "name": "Eve",
            "status": 999,
            "isTop": "0",
            "fid": "005",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertEqual(friend.status, .unknown)
    }
    
    // MARK: - 測試 isTop 解析
    
    func testFriendDecoding_IsTopTrue() throws {
        // Given
        let jsonString = """
        {
            "name": "Frank",
            "status": 1,
            "isTop": "1",
            "fid": "006",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertTrue(friend.isTop)
    }
    
    func testFriendDecoding_IsTopFalse() throws {
        // Given
        let jsonString = """
        {
            "name": "Grace",
            "status": 1,
            "isTop": "0",
            "fid": "007",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertFalse(friend.isTop)
    }
    
    func testFriendDecoding_IsTopInvalid() throws {
        // Given - 無效的 isTop 值應該預設為 false
        let jsonString = """
        {
            "name": "Henry",
            "status": 1,
            "isTop": "invalid",
            "fid": "008",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertFalse(friend.isTop)
    }
    
    // MARK: - 測試日期解析
    
    func testFriendDecoding_DateFormat1() throws {
        // Given - yyyy/MM/dd 格式
        let jsonString = """
        {
            "name": "Ivy",
            "status": 1,
            "isTop": "0",
            "fid": "009",
            "updateDate": "2023/12/25"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: friend.updateDate)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }
    
    func testFriendDecoding_DateFormat2() throws {
        // Given - yyyyMMdd 格式
        let jsonString = """
        {
            "name": "Jack",
            "status": 1,
            "isTop": "0",
            "fid": "010",
            "updateDate": "20231225"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: friend.updateDate)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }
    
    func testFriendDecoding_InvalidDateFormat() throws {
        // Given - 無效的日期格式應該使用今天的日期
        let jsonString = """
        {
            "name": "Kate",
            "status": 1,
            "isTop": "0",
            "fid": "011",
            "updateDate": "invalid-date"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        let calendar = Calendar.current
        let friendDateComponents = calendar.dateComponents([.year, .month, .day], from: friend.updateDate)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        
        XCTAssertEqual(friendDateComponents.year, todayComponents.year)
        XCTAssertEqual(friendDateComponents.month, todayComponents.month)
        XCTAssertEqual(friendDateComponents.day, todayComponents.day)
    }
    
    // MARK: - 測試 Response Wrapper
    
    func testFriendResponseDecoding() throws {
        // Given
        let jsonString = """
        {
            "response": [
                {
                    "name": "Alice",
                    "status": 1,
                    "isTop": "1",
                    "fid": "001",
                    "updateDate": "2023/12/01"
                },
                {
                    "name": "Bob",
                    "status": 0,
                    "isTop": "0",
                    "fid": "002",
                    "updateDate": "2023/12/02"
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let response = try JSONDecoder().decode(Friend.Response.self, from: data)
        
        // Then
        XCTAssertEqual(response.response.count, 2)
        XCTAssertEqual(response.response[0].name, "Alice")
        XCTAssertEqual(response.response[1].name, "Bob")
    }
    
    // MARK: - 測試缺少欄位
    
    func testFriendDecoding_MissingOptionalFields() throws {
        // Given - 缺少 isTop 應該使用預設值 false
        let jsonString = """
        {
            "name": "Liam",
            "status": 1,
            "fid": "012",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let friend = try JSONDecoder().decode(Friend.self, from: data)
        
        // Then
        XCTAssertEqual(friend.name, "Liam")
        XCTAssertFalse(friend.isTop)
    }
    
    func testFriendDecoding_MissingRequiredFields() {
        // Given - 缺少必要欄位應該拋出錯誤
        let jsonString = """
        {
            "status": 1,
            "isTop": "0",
            "fid": "013",
            "updateDate": "2023/12/01"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(Friend.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - 測試 Friend Status Enum
    
    func testFriendStatus_RawValues() {
        XCTAssertEqual(Friend.FriendStatus.unknown.rawValue, -1)
        XCTAssertEqual(Friend.FriendStatus.requestSent.rawValue, 0)
        XCTAssertEqual(Friend.FriendStatus.accepted.rawValue, 1)
        XCTAssertEqual(Friend.FriendStatus.pending.rawValue, 2)
    }
    
    func testFriendStatus_InitFromRawValue() {
        XCTAssertEqual(Friend.FriendStatus(rawValue: -1), .unknown)
        XCTAssertEqual(Friend.FriendStatus(rawValue: 0), .requestSent)
        XCTAssertEqual(Friend.FriendStatus(rawValue: 1), .accepted)
        XCTAssertEqual(Friend.FriendStatus(rawValue: 2), .pending)
        XCTAssertNil(Friend.FriendStatus(rawValue: 999))
    }
}

