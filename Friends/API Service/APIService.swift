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
    
    func fetchManData() async throws -> Person {
        // 模擬網路延遲 0.3 秒
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        let url = Bundle.main.url(forResource: "man", withExtension: "json")
        
        guard let fileURL = url else {
            throw APIError.fileNotFound
        }
              
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let person = try decoder.decode(Person.self, from: data)
        return person
    }
    
    func fetchFriendsData_noFriends() async throws -> [Friend] {
        // 模擬網路延遲 0.5 秒
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let url = Bundle.main.url(forResource: "friend4", withExtension: "json")
        
        guard let fileURL = url else {
            throw APIError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        
        // 提取 response 陣列後再解碼
        let decoder = JSONDecoder()
        let result = try decoder.decode(Friend.Response.self, from: data)
        return result.response
    }
    
    func fetchFriendsData_hasFriends_hasInvitation() async throws -> [Friend] {
        // 模擬網路延遲 0.5 秒
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let url = Bundle.main.url(forResource: "friend3", withExtension: "json")
        
        guard let fileURL = url else {
            throw APIError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        
        // 提取 response 陣列後再解碼
        let decoder = JSONDecoder()
        let result = try decoder.decode(Friend.Response.self, from: data)
        return result.response
    }
    
    func fetchFriendsData1() async throws -> [Friend] {
        // 模擬網路延遲 0.5 秒
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let url = Bundle.main.url(forResource: "friend1", withExtension: "json")
        
        guard let fileURL = url else {
            throw APIError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        
        // 提取 response 陣列後再解碼
        let decoder = JSONDecoder()
        let result = try decoder.decode(Friend.Response.self, from: data)
        return result.response
    }
    
    func fetchFriendsData2() async throws -> [Friend] {
        // 模擬網路延遲 0.5 秒
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let url = Bundle.main.url(forResource: "friend2", withExtension: "json")
        
        guard let fileURL = url else {
            throw APIError.fileNotFound
        }
        
        let data = try Data(contentsOf: fileURL)
        
        // 提取 response 陣列後再解碼
        let decoder = JSONDecoder()
        let result = try decoder.decode(Friend.Response.self, from: data)
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
