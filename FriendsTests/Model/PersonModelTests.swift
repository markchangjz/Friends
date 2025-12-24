//
//  PersonModelTests.swift
//  FriendsTests
//
//  測試 Person Model 的資料解析
//

import XCTest
@testable import Friends

final class PersonModelTests: XCTestCase {
    
    // MARK: - 測試基本解析
    
    func testPersonDecoding_WithResponse() throws {
        // Given - 有 response 包裝的格式
        let jsonString = """
        {
            "response": [
                {
                    "name": "測試使用者",
                    "kokoid": "test123"
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: data)
        
        // Then
        XCTAssertEqual(person.name, "測試使用者")
        XCTAssertEqual(person.kokoid, "test123")
    }
    
    func testPersonDecoding_WithoutResponse() throws {
        // Given - 沒有 response 包裝的直接格式
        let jsonString = """
        {
            "name": "直接使用者",
            "kokoid": "direct456"
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: data)
        
        // Then
        XCTAssertEqual(person.name, "直接使用者")
        XCTAssertEqual(person.kokoid, "direct456")
    }
    
    // MARK: - 測試特殊字符
    
    func testPersonDecoding_SpecialCharacters() throws {
        // Given
        let jsonString = """
        {
            "response": [
                {
                    "name": "測試🎉使用者",
                    "kokoid": "emoji_123"
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: data)
        
        // Then
        XCTAssertEqual(person.name, "測試🎉使用者")
        XCTAssertEqual(person.kokoid, "emoji_123")
    }
    
    func testPersonDecoding_EmptyStrings() throws {
        // Given - 空字串也應該能正確解析
        let jsonString = """
        {
            "response": [
                {
                    "name": "",
                    "kokoid": ""
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: data)
        
        // Then
        XCTAssertEqual(person.name, "")
        XCTAssertEqual(person.kokoid, "")
    }
    
    // MARK: - 測試長字串
    
    func testPersonDecoding_LongStrings() throws {
        // Given
        let longName = String(repeating: "長名字", count: 100)
        let longKokoId = String(repeating: "1234567890", count: 10)
        
        let jsonString = """
        {
            "response": [
                {
                    "name": "\(longName)",
                    "kokoid": "\(longKokoId)"
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: data)
        
        // Then
        XCTAssertEqual(person.name, longName)
        XCTAssertEqual(person.kokoid, longKokoId)
    }
    
    // MARK: - 測試缺少欄位
    
    func testPersonDecoding_MissingName() {
        // Given - 缺少必要欄位 name
        let jsonString = """
        {
            "response": [
                {
                    "kokoid": "test123"
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(Person.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testPersonDecoding_MissingKokoId() {
        // Given - 缺少必要欄位 kokoid
        let jsonString = """
        {
            "response": [
                {
                    "name": "測試使用者"
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(Person.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testPersonDecoding_EmptyResponse() {
        // Given - response 陣列為空
        let jsonString = """
        {
            "response": []
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try JSONDecoder().decode(Person.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - 測試多種編碼格式
    
    func testPersonDecoding_UTF8() throws {
        // Given - UTF-8 編碼的中文
        let jsonString = """
        {
            "response": [
                {
                    "name": "張三",
                    "kokoid": "zhang_san"
                }
            ]
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: data)
        
        // Then
        XCTAssertEqual(person.name, "張三")
        XCTAssertEqual(person.kokoid, "zhang_san")
    }
}

