//
//  APIService.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation

// MARK: - Protocol
protocol APIServiceProtocol {
    func fetchManData() async throws -> Person
    func fetchFriendsData_noFriends() async throws -> [Friend]
    func fetchFriendsData_hasFriends_hasInvitation() async throws -> [Friend]
    func fetchFriendsData1() async throws -> [Friend]
    func fetchFriendsData2() async throws -> [Friend]
}

// MARK: - APIService Implementation
class APIService: APIServiceProtocol {
    
    // MARK: - Public Methods
    
    func fetchManData() async throws -> Person {
        return try await fetchData(
            fileName: "man",
            delaySeconds: 0.3
        )
    }
    
    func fetchFriendsData_noFriends() async throws -> [Friend] {
        return try await fetchFriendsData(
            fileName: "friend4",
            delaySeconds: 0.5
        )
    }
    
    func fetchFriendsData_hasFriends_hasInvitation() async throws -> [Friend] {
        return try await fetchFriendsData(
            fileName: "friend3",
            delaySeconds: 0.5
        )
    }
    
    func fetchFriendsData1() async throws -> [Friend] {
        return try await fetchFriendsData(
            fileName: "friend1",
            delaySeconds: 0.5
        )
    }
    
    func fetchFriendsData2() async throws -> [Friend] {
        return try await fetchFriendsData(
            fileName: "friend2",
            delaySeconds: 0.5
        )
    }
    
    // MARK: - Private Helper Methods
    
    /// 通用的資料獲取方法
    /// - Parameters:
    ///   - fileName: JSON 檔案名稱（不含副檔名）
    ///   - delaySeconds: 模擬網路延遲的秒數
    /// - Returns: 解碼後的資料
    private func fetchData<T: Decodable>(fileName: String, delaySeconds: TimeInterval) async throws -> T {
        // 模擬網路延遲（將秒轉換為奈秒）
        let nanoseconds = UInt64(delaySeconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
        
        // 取得檔案 URL
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw APIError.fileNotFound
        }
        
        // 讀取並解碼資料
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    /// 專門用於獲取好友資料的方法
    /// - Parameters:
    ///   - fileName: JSON 檔案名稱（不含副檔名）
    ///   - delaySeconds: 模擬網路延遲的秒數
    /// - Returns: 好友陣列
    private func fetchFriendsData(fileName: String, delaySeconds: TimeInterval) async throws -> [Friend] {
        let result: Friend.Response = try await fetchData(
            fileName: fileName,
            delaySeconds: delaySeconds
        )
        return result.response
    }
}

// MARK: - Error Types
enum APIError: LocalizedError {
    case fileNotFound
    case emptyResponse
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "找不到 man.json 檔案"
        case .emptyResponse:
            return "回應資料為空"
        }
    }
}
