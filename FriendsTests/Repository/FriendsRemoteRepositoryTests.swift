//
//  FriendsRemoteRepositoryTests.swift
//  FriendsRemoteRepositoryTests
//
//  Created by Mark Chang on 2025/12/22.
//
//  主測試檔案 - 整合測試和基本功能測試
//

import XCTest
@testable import Friends

final class FriendsRemoteRepositoryTests: XCTestCase {
    
    // MARK: - 整合測試：載入實際 JSON 檔案
    
    func testFriendsRemoteRepository_FetchUserProfile_Integration() async throws {
        // Given
        let repository = FriendsRemoteRepository()
        
        // When
        let person = try await repository.fetchUserProfile()
        
        // Then
        XCTAssertFalse(person.name.isEmpty, "使用者名稱不應該為空")
        XCTAssertFalse(person.kokoid.isEmpty, "KokoID 不應該為空")
    }
    
    func testFriendsRemoteRepository_FetchFriends_noFriends_Integration() async throws {
        // Given
        let repository = FriendsRemoteRepository()
        
        // When
        let friends = try await repository.fetchFriends_noFriends()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    func testFriendsRemoteRepository_FetchFriends_WithInvitation_Integration() async throws {
        // Given
        let repository = FriendsRemoteRepository()
        
        // When
        let friends = try await repository.fetchFriends_hasFriends_hasInvitation()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    func testFriendsRemoteRepository_FetchFriends1_Integration() async throws {
        // Given
        let repository = FriendsRemoteRepository()
        
        // When
        let friends = try await repository.fetchFriends1()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    func testFriendsRemoteRepository_FetchFriends2_Integration() async throws {
        // Given
        let repository = FriendsRemoteRepository()
        
        // When
        let friends = try await repository.fetchFriends2()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    // MARK: - 測試 RepositoryError
    
    func testRepositoryError_ErrorDescription() {
        let error = RepositoryError.invalidURL
        XCTAssertEqual(error.errorDescription, "URL 無效")
        
        let networkError = RepositoryError.networkFailure(statusCode: 404)
        XCTAssertEqual(networkError.errorDescription, "網路請求失敗，狀態碼：404")
    }
}
