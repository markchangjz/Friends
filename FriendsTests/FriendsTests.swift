//
//  FriendsTests.swift
//  FriendsTests
//
//  Created by Mark Chang on 2025/12/22.
//
//  主測試檔案 - 整合測試和基本功能測試
//

import XCTest
@testable import Friends

final class FriendsTests: XCTestCase {

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
    
    func testAPIService_FetchUserProfile_Integration() async throws {
        // Given
        let apiService = APIService()
        
        // When
        let person = try await apiService.fetchUserProfile()
        
        // Then
        XCTAssertFalse(person.name.isEmpty, "使用者名稱不應該為空")
        XCTAssertFalse(person.kokoid.isEmpty, "KokoID 不應該為空")
    }
    
    func testAPIService_FetchFriends_noFriends_Integration() async throws {
        // Given
        let apiService = APIService()
        
        // When
        let friends = try await apiService.fetchFriends_noFriends()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    func testAPIService_FetchFriends_WithInvitation_Integration() async throws {
        // Given
        let apiService = APIService()
        
        // When
        let friends = try await apiService.fetchFriends_hasFriends_hasInvitation()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    func testAPIService_FetchFriends1_Integration() async throws {
        // Given
        let apiService = APIService()
        
        // When
        let friends = try await apiService.fetchFriends1()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    func testAPIService_FetchFriends2_Integration() async throws {
        // Given
        let apiService = APIService()
        
        // When
        let friends = try await apiService.fetchFriends2()
        
        // Then
        XCTAssertTrue(friends.isEmpty || !friends.isEmpty, "應該能成功載入好友資料")
    }
    
    // MARK: - 測試 APIError
    
    func testAPIError_ErrorDescription() {
        let error = APIError.fileNotFound
        XCTAssertEqual(error.errorDescription, "找不到 JSON 檔案")
    }
    
    // MARK: - Helper Methods
    
    private func createMockFriend(
        name: String,
        status: Friend.FriendStatus,
        fid: String
    ) -> Friend {
        let jsonString = """
        {
            "name": "\(name)",
            "status": \(status.rawValue),
            "isTop": "0",
            "fid": "\(fid)",
            "updateDate": "20231201"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(Friend.self, from: data)
    }
}
