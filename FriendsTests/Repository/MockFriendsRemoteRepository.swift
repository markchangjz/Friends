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
    
    // MARK: - FriendsRepositoryProtocol Implementation
    
    func fetchUserProfile() async throws -> Person {
        if shouldThrowError {
            throw NetworkError.invalidURL
        }
        
        return try loadJSONFile(fileName: "man", type: Person.self)
    }
    
    func fetchFriends_noFriends() async throws -> [Friend] {
        if shouldThrowError {
            throw NetworkError.invalidURL
        }
        
        return try loadJSONFile(fileName: "friend4", type: Friend.Response.self).response
    }
    
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend] {
        if shouldThrowError {
            throw NetworkError.invalidURL
        }
        
        return try loadJSONFile(fileName: "friend3", type: Friend.Response.self).response
    }
    
    func fetchFriends1() async throws -> [Friend] {
        if shouldThrowError {
            throw NetworkError.invalidURL
        }
        
        return try loadJSONFile(fileName: "friend1", type: Friend.Response.self).response
    }
    
    func fetchFriends2() async throws -> [Friend] {
        if shouldThrowError {
            throw NetworkError.invalidURL
        }
        
        return try loadJSONFile(fileName: "friend2", type: Friend.Response.self).response
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
            throw NetworkError.invalidURL
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

