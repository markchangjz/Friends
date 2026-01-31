//
//  NetworkService.swift
//  Friends
//
//  Created by Jules on 2025/12/22.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case networkFailure(statusCode: Int)
    case invalidData
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL 無效"
        case .networkFailure(let statusCode):
            return "網路請求失敗，狀態碼：\(statusCode)"
        case .invalidData:
            return "無效的資料"
        case .decodingError(let error):
            return "解析錯誤: \(error.localizedDescription)"
        case .unknown(let error):
            return "未知錯誤: \(error.localizedDescription)"
        }
    }
}

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

class NetworkService: NetworkServiceProtocol {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.networkFailure(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as NetworkError {
            throw error
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
