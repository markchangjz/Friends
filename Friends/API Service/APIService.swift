//
//  APIService.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation

// MARK: - Protocol
protocol APIServiceProtocol {
    func fetchUserProfile() async throws -> Person
    func fetchFriends_noFriends() async throws -> [Friend]
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend]
    func fetchFriends1() async throws -> [Friend]
    func fetchFriends2() async throws -> [Friend]
}

// MARK: - APIService Implementation
class APIService: APIServiceProtocol {
    
    // 控制是否使用遠端 API；預設 true。如需使用本地 JSON，可在初始化時改為 false。
    private let useRemoteAPI: Bool
    
    init(useRemoteAPI: Bool = true) {
        self.useRemoteAPI = useRemoteAPI
    }
    
    // MARK: - Public Methods
    
    func fetchUserProfile() async throws -> Person {
        return try await fetchData(
            urlString: "https://dimanyen.github.io/man.json",
            localFileName: "man"
        )
    }
    
    func fetchFriends_noFriends() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "https://dimanyen.github.io/friend4.json",
            localFileName: "friend4"
        )
    }
    
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "https://dimanyen.github.io/friend3.json",
            localFileName: "friend3"
        )
    }
    
    func fetchFriends1() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "https://dimanyen.github.io/friend1.json",
            localFileName: "friend1"
        )
    }
    
    func fetchFriends2() async throws -> [Friend] {
        return try await fetchFriendsData(
            urlString: "https://dimanyen.github.io/friend2.json",
            localFileName: "friend2"
        )
    }
    
    // MARK: - Private Helper Methods
    
    /// 通用的資料獲取方法
    /// - Parameters:
    ///   - urlString: JSON 遠端 URL 字串
    ///   - localFileName: 本地 JSON 檔名（不含副檔名）
    /// - Returns: 解碼後的資料
    private func fetchData<T: Decodable>(urlString: String, localFileName: String) async throws -> T {
        if useRemoteAPI {
            return try await fetchRemoteData(urlString: urlString)
        } else {
            return try fetchLocalData(fileName: localFileName)
        }
    }
    
    /// 專門用於獲取好友資料的方法
    /// - Parameters:
    ///   - urlString: JSON 遠端 URL 字串
    ///   - localFileName: 本地 JSON 檔名（不含副檔名）
    /// - Returns: 好友陣列
    private func fetchFriendsData(urlString: String, localFileName: String) async throws -> [Friend] {
        let result: Friend.Response = try await fetchData(
            urlString: urlString,
            localFileName: localFileName
        )
        return result.response
    }
    
    private func fetchRemoteData<T: Decodable>(urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData // 避免離線使用快取仍返回舊資料
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           (200...299).contains(httpResponse.statusCode) == false {
            throw APIError.networkFailure(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func fetchLocalData<T: Decodable>(fileName: String) throws -> T {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw APIError.fileNotFound
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Error Types
enum APIError: LocalizedError {
    case fileNotFound
    case invalidURL
    case networkFailure(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到 JSON 檔案"
        case .invalidURL:
            return "URL 無效"
        case .networkFailure(let statusCode):
            return "網路請求失敗，狀態碼：\(statusCode)"
        }
    }
}
