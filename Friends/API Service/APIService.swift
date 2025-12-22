//
//  APIService.swift
//  Friends
//
//  Created by Mark Chang on 2025/12/22.
//

import Foundation

// MARK: - Protocol
protocol APIServiceProtocol {
    func fetchManData(completion: @escaping (Result<Person, Error>) -> Void)
}

// MARK: - APIService Implementation
class APIService: APIServiceProtocol {
    
    func fetchManData(completion: @escaping (Result<Person, Error>) -> Void) {
        let url = Bundle.main.url(forResource: "man", withExtension: "json")
        
        guard let fileURL = url else {
            completion(.failure(APIError.fileNotFound))
            return
        }
              
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let person = try decoder.decode(Person.self, from: data)
            completion(.success(person))
        } catch {
            completion(.failure(error))
        }
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
