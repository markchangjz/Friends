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
    
    private let networkService: NetworkServiceProtocol
    
    // MARK: - Initialization
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - Public Methods
    
    func fetchUserProfile() async throws -> Person {
        return try await networkService.request(.userProfile)
    }
    
    func fetchFriends_noFriends() async throws -> [Friend] {
        return try await fetchFriendsList(endpoint: .friendsNoFriends)
    }
    
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend] {
        return try await fetchFriendsList(endpoint: .friendsWithInvitation)
    }
    
    func fetchFriends1() async throws -> [Friend] {
        return try await fetchFriendsList(endpoint: .friendsList1)
    }
    
    func fetchFriends2() async throws -> [Friend] {
        return try await fetchFriendsList(endpoint: .friendsList2)
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchFriendsList(endpoint: APIEndpoint) async throws -> [Friend] {
        let result: Friend.Response = try await networkService.request(endpoint)
        return result.response
    }
}
