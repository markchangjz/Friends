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
}

// MARK: - APIService Implementation
class APIService: APIServiceProtocol {
    
    func fetchManData() async throws -> Person {
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
