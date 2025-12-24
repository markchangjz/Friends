//
//  MockFriendsRemoteRepository.swift
//  FriendsTests
//
//  Created for unit testing
//

import Foundation
@testable import Friends

class MockFriendsRemoteRepository: FriendsRepositoryProtocol {
    
    // MARK: - Properties for Testing
    var shouldThrowError = false
    var errorToThrow: Error = RepositoryError.invalidURL
    
    // MARK: - FriendsRepositoryProtocol Implementation
    
    func fetchUserProfile() async throws -> Person {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return try loadJSONFile(fileName: "man", type: Person.self)
    }
    
    func fetchFriends_noFriends() async throws -> [Friend] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return try loadFriendsJSONFile(fileName: "friend4")
    }
    
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return try loadFriendsJSONFile(fileName: "friend3")
    }
    
    func fetchFriends1() async throws -> [Friend] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return try loadFriendsJSONFile(fileName: "friend1")
    }
    
    func fetchFriends2() async throws -> [Friend] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        return try loadFriendsJSONFile(fileName: "friend2")
    }
    
    // MARK: - Private Helper Methods
    
    /// 從 Bundle 讀取 JSON 檔案並解析為指定型別
    /// - Parameters:
    ///   - fileName: JSON 檔名（不含副檔名）
    ///   - type: 要解析的型別
    /// - Returns: 解析後的資料
    private func loadJSONFile<T: Decodable>(fileName: String, type: T.Type) throws -> T {
        // 從測試 bundle 讀取 JSON 檔案
        // JSON 檔案位於測試 bundle 的 "Mock API JSON files" 目錄下
        let bundle = Bundle(for: MockFriendsRemoteRepository.self)
        guard let fileURL = bundle.url(forResource: fileName, withExtension: "json") else {
            throw RepositoryError.invalidURL
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    /// 從 Bundle 讀取好友資料 JSON 檔案
    /// - Parameter fileName: JSON 檔名（不含副檔名）
    /// - Returns: 好友陣列
    private func loadFriendsJSONFile(fileName: String) throws -> [Friend] {
        let result: Friend.Response = try loadJSONFile(fileName: fileName, type: Friend.Response.self)
        return result.response
    }
}

