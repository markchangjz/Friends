//
//  MockAPIService.swift
//  FriendsTests
//
//  Created for unit testing
//

import Foundation
@testable import Friends

class MockAPIService: APIServiceProtocol {
    
    // MARK: - Properties for Testing
    var shouldThrowError = false
    var errorToThrow: Error = APIError.fileNotFound
    
    // Mock data to return
    var mockUserProfile: Person?
    var mockFriends_noFriends: [Friend] = []
    var mockFriends_hasFriends_hasInvitation: [Friend] = []
    var mockFriends1: [Friend] = []
    var mockFriends2: [Friend] = []
    
    // Call tracking
    var fetchUserProfileCallCount = 0
    var fetchFriends_noFriendsCallCount = 0
    var fetchFriends_hasFriends_hasInvitationCallCount = 0
    var fetchFriends1CallCount = 0
    var fetchFriends2CallCount = 0
    
    // MARK: - APIServiceProtocol Implementation
    
    func fetchUserProfile() async throws -> Person {
        fetchUserProfileCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let profile = mockUserProfile else {
            throw APIError.fileNotFound
        }
        
        return profile
    }
    
    func fetchFriends_noFriends() async throws -> [Friend] {
        fetchFriends_noFriendsCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockFriends_noFriends
    }
    
    func fetchFriends_hasFriends_hasInvitation() async throws -> [Friend] {
        fetchFriends_hasFriends_hasInvitationCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockFriends_hasFriends_hasInvitation
    }
    
    func fetchFriends1() async throws -> [Friend] {
        fetchFriends1CallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockFriends1
    }
    
    func fetchFriends2() async throws -> [Friend] {
        fetchFriends2CallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockFriends2
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        shouldThrowError = false
        errorToThrow = APIError.fileNotFound
        mockUserProfile = nil
        mockFriends_noFriends = []
        mockFriends_hasFriends_hasInvitation = []
        mockFriends1 = []
        mockFriends2 = []
        fetchUserProfileCallCount = 0
        fetchFriends_noFriendsCallCount = 0
        fetchFriends_hasFriends_hasInvitationCallCount = 0
        fetchFriends1CallCount = 0
        fetchFriends2CallCount = 0
    }
}

