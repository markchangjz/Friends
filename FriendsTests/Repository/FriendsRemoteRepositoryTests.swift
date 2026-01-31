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
    
    // MARK: - Properties
    
    var repository: FriendsRemoteRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        repository = FriendsRemoteRepository()
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    // MARK: - 整合測試：載入實際 JSON 檔案
    
    func testFriendsRemoteRepository_FetchUserProfile_Integration() async throws {
        // Given
        
        // When
        let person = try await repository.fetchUserProfile()
        
        // Then
        XCTAssertFalse(person.name.isEmpty, "使用者名稱不應該為空")
        XCTAssertFalse(person.kokoid.isEmpty, "KokoID 不應該為空")
    }
    
    func testFriendsRemoteRepository_FetchFriends_noFriends_Integration() async throws {
        // Given
        
        // When
        let friends = try await repository.fetchFriends_noFriends()
        
        // Then - friend4.json 是空陣列
        XCTAssertTrue(friends.isEmpty, "應該返回空陣列")
    }
    
    func testFriendsRemoteRepository_FetchFriends_WithInvitation_Integration() async throws {
        // Given
        
        // When
        let friends = try await repository.fetchFriends_hasFriends_hasInvitation()
        
        // Then - friend3.json 包含多個好友
        XCTAssertFalse(friends.isEmpty, "應該返回非空陣列")
        XCTAssertTrue(friends.count > 0, "應該包含至少一個好友")
        // 驗證資料結構正確
        XCTAssertFalse(friends.first?.name.isEmpty ?? true, "好友名稱不應該為空")
        XCTAssertFalse(friends.first?.fid.isEmpty ?? true, "好友 ID 不應該為空")
    }
    
    func testFriendsRemoteRepository_FetchFriends1_Integration() async throws {
        // Given
        
        // When
        let friends = try await repository.fetchFriends1()
        
        // Then - friend1.json 包含多個好友
        XCTAssertFalse(friends.isEmpty, "應該返回非空陣列")
        XCTAssertTrue(friends.count > 0, "應該包含至少一個好友")
        // 驗證資料結構正確
        XCTAssertFalse(friends.first?.name.isEmpty ?? true, "好友名稱不應該為空")
        XCTAssertFalse(friends.first?.fid.isEmpty ?? true, "好友 ID 不應該為空")
    }
    
    func testFriendsRemoteRepository_FetchFriends2_Integration() async throws {
        // Given
        
        // When
        let friends = try await repository.fetchFriends2()
        
        // Then - friend2.json 包含多個好友
        XCTAssertFalse(friends.isEmpty, "應該返回非空陣列")
        XCTAssertTrue(friends.count > 0, "應該包含至少一個好友")
        // 驗證資料結構正確
        XCTAssertFalse(friends.first?.name.isEmpty ?? true, "好友名稱不應該為空")
        XCTAssertFalse(friends.first?.fid.isEmpty ?? true, "好友 ID 不應該為空")
    }
    
    // MARK: - 測試 NetworkError
    
    func testNetworkError_ErrorDescription() {
        let error = NetworkError.invalidURL
        XCTAssertEqual(error.errorDescription, "URL 無效")
        
        let networkError = NetworkError.networkFailure(statusCode: 404)
        XCTAssertEqual(networkError.errorDescription, "網路請求失敗，狀態碼：404")
    }
}
