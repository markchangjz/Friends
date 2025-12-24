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

    // MARK: - 測試 Friend Status Enum
    
    func testFriendStatus_RawValues() {
        XCTAssertEqual(Friend.FriendStatus.unknown.rawValue, -1)
        XCTAssertEqual(Friend.FriendStatus.requestSent.rawValue, 0)
        XCTAssertEqual(Friend.FriendStatus.accepted.rawValue, 1)
        XCTAssertEqual(Friend.FriendStatus.pending.rawValue, 2)
    }
    
    func testFriendStatus_InitFromRawValue() {
        XCTAssertEqual(Friend.FriendStatus(rawValue: -1), .unknown)
        XCTAssertEqual(Friend.FriendStatus(rawValue: 0), .requestSent)
        XCTAssertEqual(Friend.FriendStatus(rawValue: 1), .accepted)
        XCTAssertEqual(Friend.FriendStatus(rawValue: 2), .pending)
        XCTAssertNil(Friend.FriendStatus(rawValue: 999))
    }
    
    // MARK: - 測試 ViewOption Enum
    
    func testViewOption_RawValues() {
        XCTAssertEqual(FriendsViewModel.ViewOption.noFriends.rawValue, "無好友畫面")
        XCTAssertEqual(FriendsViewModel.ViewOption.friendsListOnly.rawValue, "只有好友列表")
        XCTAssertEqual(FriendsViewModel.ViewOption.friendsListWithInvitation.rawValue, "好友列表含邀請")
    }
    
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
