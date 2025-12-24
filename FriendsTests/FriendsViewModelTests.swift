//
//  FriendsViewModelTests.swift
//  FriendsTests
//
//  測試 FriendsViewModel 的業務邏輯
//

import XCTest
import Combine
@testable import Friends

final class FriendsViewModelTests: XCTestCase {
    
    var viewModel: FriendsViewModel!
    var mockRepository: MockFriendsRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockRepository = MockFriendsRepository()
        viewModel = FriendsViewModel(repository: mockRepository)
    }
    
    override func tearDownWithError() throws {
        super.tearDown()
    }
    
    // MARK: - 測試初始化狀態
    
    func testInitialState() {
        XCTAssertEqual(viewModel.userName, "")
        XCTAssertEqual(viewModel.userKokoId, "")
        XCTAssertEqual(viewModel.selectedOption, .noFriends)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.numberOfSections, 0)
        XCTAssertFalse(viewModel.hasFriends)
        XCTAssertFalse(viewModel.hasFriendRequests)
        XCTAssertFalse(viewModel.hasConfirmedFriends)
    }
    
    // MARK: - 測試載入使用者資料
    
    func testLoadUserData_Success() async throws {
        // Given
        let mockPerson = try createMockPerson(name: "測試使用者", kokoid: "test123")
        mockRepository.mockUserProfile = mockPerson
        
        let expectation = XCTestExpectation(description: "User data loaded")
        
        viewModel.userProfileDataLoadedPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadUserData()
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.userName, "測試使用者")
        XCTAssertEqual(viewModel.userKokoId, "test123")
        XCTAssertEqual(mockRepository.fetchUserProfileCallCount, 1)
    }
    
    func testLoadUserData_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        let expectation = XCTestExpectation(description: "Error published")
        
        viewModel.errorPublisher
            .sink { error in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadUserData()
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - 測試載入好友資料
    
    func testLoadFriendsData_NoFriends() async throws {
        // Given
        mockRepository.mockFriends_noFriends = []
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        
        viewModel.friendsDataLoadedPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadFriendsData(for: .noFriends)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.allFriends.count, 0)
        XCTAssertFalse(viewModel.hasFriends)
        XCTAssertEqual(mockRepository.fetchFriends_noFriendsCallCount, 1)
    }
    
    func testLoadFriendsData_WithConfirmedFriends() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Alice", status: .accepted, fid: "1"),
            createMockFriend(name: "Bob", status: .accepted, fid: "2")
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        
        viewModel.friendsDataLoadedPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.allFriends.count, 2)
        XCTAssertTrue(viewModel.hasFriends)
        XCTAssertTrue(viewModel.hasConfirmedFriends)
        XCTAssertFalse(viewModel.hasFriendRequests)
    }
    
    func testLoadFriendsData_WithRequests() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Charlie", status: .requestSent, fid: "3"),
            createMockFriend(name: "David", status: .accepted, fid: "4")
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        
        viewModel.friendsDataLoadedPublisher
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.allFriends.count, 2)
        XCTAssertTrue(viewModel.hasFriendRequests)
        XCTAssertTrue(viewModel.hasConfirmedFriends)
        XCTAssertEqual(viewModel.numberOfSections, 2)
    }
    
    // MARK: - 測試搜尋功能
    
    func testFilterFriends_EmptySearch() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Alice", status: .accepted, fid: "1"),
            createMockFriend(name: "Bob", status: .accepted, fid: "2")
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // When
        viewModel.searchText = ""
        viewModel.filterFriends()
        
        // Then
        XCTAssertEqual(viewModel.displayConfirmedFriends.count, 2)
    }
    
    func testFilterFriends_WithSearchText() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Alice", status: .accepted, fid: "1"),
            createMockFriend(name: "Bob", status: .accepted, fid: "2"),
            createMockFriend(name: "Charlie", status: .accepted, fid: "3")
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // When
        viewModel.searchText = "ali"
        viewModel.filterFriends()
        
        // Then
        XCTAssertEqual(viewModel.displayConfirmedFriends.count, 1)
        XCTAssertEqual(viewModel.displayConfirmedFriends.first?.name, "Alice")
    }
    
    func testClearSearch() async throws {
        // Given
        viewModel.searchText = "test"
        
        // When
        viewModel.clearSearch()
        
        // Then
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    // MARK: - 測試排序功能
    
    func testFriendsSorting_ByIsTop() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Alice", status: .accepted, fid: "1", isTop: false),
            createMockFriend(name: "Bob", status: .accepted, fid: "2", isTop: true)
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.displayConfirmedFriends.first?.name, "Bob")
        XCTAssertTrue(viewModel.displayConfirmedFriends.first!.isTop)
    }
    
    func testFriendsSorting_ByUpdateDate() async throws {
        // Given
        // 創建明顯不同的日期（相差一年）
        let calendar = Calendar.current
        let oldDate = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let newDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
        let mockFriends = [
            createMockFriend(name: "Alice", status: .accepted, fid: "1", isTop: false, updateDate: oldDate),
            createMockFriend(name: "Bob", status: .accepted, fid: "2", isTop: false, updateDate: newDate)
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        // 驗證較新的日期（Bob）排在前面
        XCTAssertEqual(viewModel.displayConfirmedFriends.count, 2)
        XCTAssertEqual(viewModel.displayConfirmedFriends.first?.name, "Bob")
        XCTAssertEqual(viewModel.displayConfirmedFriends.last?.name, "Alice")
    }
    
    func testFriendsSorting_CompleteRules() async throws {
        // Given - 測試完整的排序規則：1. isTop, 2. updateDate, 3. fid
        let calendar = Calendar.current
        let date1 = calendar.date(from: DateComponents(year: 2023, month: 1, day: 1))!
        let date2 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
        let mockFriends = [
            // 非置頂，舊日期，fid="3"
            createMockFriend(name: "Charlie", status: .accepted, fid: "3", isTop: false, updateDate: date1),
            // 置頂，舊日期，fid="1"
            createMockFriend(name: "Alice", status: .accepted, fid: "1", isTop: true, updateDate: date1),
            // 非置頂，新日期，fid="4"
            createMockFriend(name: "David", status: .accepted, fid: "4", isTop: false, updateDate: date2),
            // 置頂，新日期，fid="2"
            createMockFriend(name: "Bob", status: .accepted, fid: "2", isTop: true, updateDate: date2)
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        let friends = viewModel.displayConfirmedFriends
        XCTAssertEqual(friends.count, 4)
        
        // 預期排序：
        // 1. Bob (isTop=true, date=2024, fid=2)
        // 2. Alice (isTop=true, date=2023, fid=1)
        // 3. David (isTop=false, date=2024, fid=4)
        // 4. Charlie (isTop=false, date=2023, fid=3)
        XCTAssertEqual(friends[0].name, "Bob")
        XCTAssertEqual(friends[1].name, "Alice")
        XCTAssertEqual(friends[2].name, "David")
        XCTAssertEqual(friends[3].name, "Charlie")
    }
    
    // MARK: - 測試 TableView Data Source
    
    func testNumberOfRows() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Alice", status: .requestSent, fid: "1"),
            createMockFriend(name: "Bob", status: .accepted, fid: "2"),
            createMockFriend(name: "Charlie", status: .accepted, fid: "3")
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // When & Then
        XCTAssertEqual(viewModel.numberOfRows(in: 0), 1) // Requests section
        XCTAssertEqual(viewModel.numberOfRows(in: 1), 2) // Friends section
    }
    
    func testIsRequestSection() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Alice", status: .requestSent, fid: "1"),
            createMockFriend(name: "Bob", status: .accepted, fid: "2")
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // When & Then
        XCTAssertTrue(viewModel.isRequestSection(0))
        XCTAssertFalse(viewModel.isRequestSection(1))
    }
    
    func testTitleForHeader() async throws {
        // Given
        let mockFriends = [
            createMockFriend(name: "Alice", status: .requestSent, fid: "1"),
            createMockFriend(name: "Bob", status: .accepted, fid: "2")
        ]
        mockRepository.mockFriends_hasFriends_hasInvitation = mockFriends
        
        let expectation = XCTestExpectation(description: "Friends data loaded")
        viewModel.friendsDataLoadedPublisher
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // When & Then
        XCTAssertEqual(viewModel.titleForHeader(in: 0), "Requests")
        XCTAssertEqual(viewModel.titleForHeader(in: 1), "Friends")
    }
    
    // MARK: - 測試選項切換
    
    func testSelectOption() async {
        // Given
        let expectation = XCTestExpectation(description: "Option changed")
        
        viewModel.$selectedOption
            .dropFirst() // 跳過初始值
            .sink { option in
                XCTAssertEqual(option, .friendsListOnly)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        viewModel.selectOption(.friendsListOnly)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testCreateMenu() {
        // When
        let menu = viewModel.createMenu()
        
        // Then
        XCTAssertEqual(menu.children.count, 3)
    }
    
    // MARK: - 測試載入所有資料
    
    func testLoadAllData_Success() async throws {
        // Given
        let mockPerson = try createMockPerson(name: "測試使用者", kokoid: "test123")
        let mockFriends = [
            createMockFriend(name: "Alice", status: .accepted, fid: "1")
        ]
        mockRepository.mockUserProfile = mockPerson
        mockRepository.mockFriends_noFriends = mockFriends
        
        let profileExpectation = XCTestExpectation(description: "User profile loaded")
        let friendsExpectation = XCTestExpectation(description: "Friends data loaded")
        
        viewModel.userProfileDataLoadedPublisher
            .sink { _ in profileExpectation.fulfill() }
            .store(in: &cancellables)
        
        viewModel.friendsDataLoadedPublisher
            .sink { _ in friendsExpectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        viewModel.loadAllData(for: .noFriends)
        
        // Then
        await fulfillment(of: [profileExpectation, friendsExpectation], timeout: 2.0)
        XCTAssertEqual(viewModel.userName, "測試使用者")
        XCTAssertEqual(viewModel.userKokoId, "test123")
        XCTAssertEqual(viewModel.allFriends.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createMockFriend(
        name: String,
        status: Friend.FriendStatus,
        fid: String,
        isTop: Bool = false,
        updateDate: Date = Date()
    ) -> Friend {
        // 將 Date 轉換為 yyyyMMdd 格式的字串
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        let updateDateString = formatter.string(from: updateDate)
        
        let jsonString = """
        {
            "name": "\(name)",
            "status": \(status.rawValue),
            "isTop": "\(isTop ? "1" : "0")",
            "fid": "\(fid)",
            "updateDate": "\(updateDateString)"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(Friend.self, from: data)
    }
    
    private func createMockPerson(name: String, kokoid: String) throws -> Person {
        let jsonString = """
        {
            "response": [
                {
                    "name": "\(name)",
                    "kokoid": "\(kokoid)"
                }
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(Person.self, from: data)
    }
}

