//
//  FriendsRemoteRepository.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation

// MARK: - Protocol
protocol FriendsRepositoryProtocol {
    func fetchUserProfile() async throws -> Person
    func fetchFriends_noFriends() async throws -> [Friend]
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend]
    func fetchFriends1() async throws -> [Friend]
    func fetchFriends2() async throws -> [Friend]
}

// MARK: - FriendsRemoteRepository Implementation
class FriendsRemoteRepository: FriendsRepositoryProtocol {
    
    // MARK: - Properties
    
    private let baseURL: String
    
    // MARK: - Initialization
    
    init(baseURL: String = "https://dimanyen.github.io") {
        self.baseURL = baseURL
    }
    
    // MARK: - Public Methods
    
    func fetchUserProfile() async throws -> Person {
        return try await fetchRemoteData(
            urlString: "\(baseURL)/man.json"
        )
    }
    
    func fetchFriends_noFriends() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "\(baseURL)/friend4.json"
        )
    }
    
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "\(baseURL)/friend3.json"
        )
    }
    
    func fetchFriends1() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "\(baseURL)/friend1.json"
        )
    }
    
    func fetchFriends2() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "\(baseURL)/friend2.json"
        )
    }
    
    // MARK: - Private Helper Methods
    
    /// 專門用於獲取好友資料的方法
    /// - Parameter urlString: JSON 遠端 URL 字串
    /// - Returns: 好友陣列
    private func fetchFriendsData(urlString: String) async throws -> [Friend] {
        let result: Friend.Response = try await fetchRemoteData(urlString: urlString)
        return result.response
    }
    
    /// 從遠端 API 獲取資料
    /// - Parameter urlString: JSON 遠端 URL 字串
    /// - Returns: 解碼後的資料
    private func fetchRemoteData<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw RepositoryError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData // 避免離線使用快取仍返回舊資料
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           (200...299).contains(httpResponse.statusCode) == false {
            throw RepositoryError.networkFailure(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Error Types
enum RepositoryError: LocalizedError {
    case invalidURL
    case networkFailure(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL 無效"
        case .networkFailure(let statusCode):
            return "網路請求失敗，狀態碼：\(statusCode)"
        }
    }
}

