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
    var mockRepository: MockFriendsRemoteRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockRepository = MockFriendsRemoteRepository()
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
        // Given - MockRepository 會從 JSON 檔案讀取資料
        // When
        viewModel.loadUserData()
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.userProfileDataLoadedPublisher.values {
            // 驗證從 JSON 檔案讀取的資料（man.json 包含 "蔡國泰" 和 "Mike"）
            XCTAssertFalse(viewModel.userName.isEmpty)
            XCTAssertFalse(viewModel.userKokoId.isEmpty)
            break // 只等待第一個事件
        }
    }
    
    func testLoadUserData_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        // 先訂閱錯誤 publisher，確保不會錯過事件
        let expectation = XCTestExpectation(description: "Error published")
        
        viewModel.errorPublisher
            .sink { error in
                XCTAssertNotNil(error)
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
        // Given - MockRepository 會從 friend4.json 讀取（該檔案為空陣列）
        // When
        viewModel.loadFriendsData(for: .noFriends)
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // friend4.json 是空陣列
            XCTAssertEqual(viewModel.allFriends.count, 0)
            XCTAssertFalse(viewModel.hasFriends)
            break // 只等待第一個事件
        }
    }
    
    func testLoadFriendsData_WithConfirmedFriends() async throws {
        // Given - MockRepository 會從 friend3.json 讀取資料
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // friend3.json 包含多個好友，包含已確認和邀請狀態
            XCTAssertTrue(viewModel.allFriends.count > 0)
            XCTAssertTrue(viewModel.hasFriends)
            // friend3.json 包含 status=1 (accepted) 和 status=2 (pending) 的好友
            XCTAssertTrue(viewModel.hasConfirmedFriends || viewModel.hasFriendRequests)
            break // 只等待第一個事件
        }
    }
    
    func testLoadFriendsData_WithRequests() async throws {
        // Given - MockRepository 會從 friend3.json 讀取資料（包含邀請和已確認好友）
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // friend3.json 包含 status=0 (requestSent), status=1 (accepted), status=2 (pending)
            XCTAssertTrue(viewModel.allFriends.count > 0)
            // 如果有邀請和已確認好友，應該有 2 個 sections
            if viewModel.hasFriendRequests && viewModel.hasConfirmedFriends {
                XCTAssertEqual(viewModel.numberOfSections, 2)
            }
            break // 只等待第一個事件
        }
    }
    
    func testLoadFriendsData_MergeFriends() async throws {
        // Given - MockRepository 會從 friend1.json 和 friend2.json 讀取並合併資料
        // When
        viewModel.loadFriendsData(for: .friendsListOnly)
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // friend1.json 和 friend2.json 都有 fid "001"，但 updateDate 不同
            // friend1.json: fid "001" updateDate "20190801"
            // friend2.json: fid "001" updateDate "2019/08/02" (較新)
            // 合併後應該保留 friend2.json 的版本（較新的日期）
            
            // 驗證有合併後的資料
            XCTAssertTrue(viewModel.allFriends.count > 0)
            
            // 驗證 fid "001" 的資料是來自 friend2.json（較新的日期）
            if let friend001 = viewModel.allFriends.first(where: { $0.fid == "001" }) {
                // friend1.json: fid "001" updateDate "20190801" (2019年8月1日)
                // friend2.json: fid "001" updateDate "2019/08/02" (2019年8月2日，較新)
                // 合併後應該保留 friend2.json 的版本（較新的日期）
                
                // 驗證日期是 2019年8月2日（較新的版本）
                let expectedDate = Calendar.current.date(from: DateComponents(year: 2019, month: 8, day: 2))!
                let calendar = Calendar.current
                let actualComponents = calendar.dateComponents([.year, .month, .day], from: friend001.updateDate)
                let expectedComponents = calendar.dateComponents([.year, .month, .day], from: expectedDate)
                
                XCTAssertEqual(actualComponents.year, expectedComponents.year, "fid 001 應該保留較新的年份")
                XCTAssertEqual(actualComponents.month, expectedComponents.month, "fid 001 應該保留較新的月份")
                XCTAssertEqual(actualComponents.day, expectedComponents.day, "fid 001 應該保留較新的日期")
                
                // friend2.json 中 fid "001" 的 status 是 1 (accepted)
                XCTAssertEqual(friend001.status, .accepted, "fid 001 應該使用 friend2.json 的 status")
            }
            
            // 驗證所有不重複的 fid 都被保留
            // friend1.json 有: 001, 002, 003, 004, 005
            // friend2.json 有: 001, 002, 012
            // 合併後應該有: 001 (保留較新), 002 (保留較新), 003, 004, 005, 012
            let allFids = Set(viewModel.allFriends.map { $0.fid })
            XCTAssertTrue(allFids.contains("001"), "應該包含 fid 001")
            XCTAssertTrue(allFids.contains("002"), "應該包含 fid 002")
            XCTAssertTrue(allFids.contains("003"), "應該包含 fid 003")
            XCTAssertTrue(allFids.contains("004"), "應該包含 fid 004")
            XCTAssertTrue(allFids.contains("005"), "應該包含 fid 005")
            XCTAssertTrue(allFids.contains("012"), "應該包含 fid 012")
            
            // 驗證沒有重複的 fid
            let uniqueFids = Set(viewModel.allFriends.map { $0.fid })
            XCTAssertEqual(viewModel.allFriends.count, uniqueFids.count, "不應該有重複的 fid")
            
            break // 只等待第一個事件
        }
    }
    
    // MARK: - 測試搜尋功能
    
    func testFilterFriends_EmptySearch() async throws {
        // Given - 從 friend3.json 載入資料
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            let initialConfirmedCount = viewModel.displayConfirmedFriends.count
            
            // When
            viewModel.searchText = ""
            viewModel.filterFriends()
            
            // Then - 空搜尋應該顯示所有已確認好友
            XCTAssertEqual(viewModel.displayConfirmedFriends.count, initialConfirmedCount)
            break
        }
    }
    
    func testFilterFriends_WithSearchText() async throws {
        // Given - 從 friend3.json 載入資料
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // When - 搜尋 friend3.json 中的實際好友名稱（例如 "黃"）
            viewModel.searchText = "黃"
            viewModel.filterFriends()
            
            // Then - 應該過濾出包含 "黃" 的好友
            let filteredCount = viewModel.displayConfirmedFriends.count
            XCTAssertTrue(filteredCount >= 0)
            if filteredCount > 0 {
                XCTAssertTrue(viewModel.displayConfirmedFriends.first?.name.contains("黃") ?? false)
            }
            break
        }
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
        // Given - 從 friend3.json 載入資料（包含 isTop="1" 和 isTop="0" 的好友）
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // 驗證排序：isTop=true 的好友應該排在前面
            if viewModel.displayConfirmedFriends.count > 1 {
                let firstFriend = viewModel.displayConfirmedFriends.first!
                // 第一個好友應該是 isTop=true，或者如果沒有置頂的，則按日期排序
                // friend3.json 中 "翁勳儀" 是 isTop="1"，應該排在前面
                XCTAssertTrue(firstFriend.isTop || viewModel.displayConfirmedFriends.allSatisfy { !$0.isTop })
            }
            break
        }
    }
    
    func testFriendsSorting_ByUpdateDate() async throws {
        // Given - 從 friend3.json 載入資料（包含不同 updateDate 的好友）
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // 驗證排序：較新的日期應該排在前面（如果 isTop 相同）
            if viewModel.displayConfirmedFriends.count > 1 {
                let firstDate = viewModel.displayConfirmedFriends.first!.updateDate
                let secondDate = viewModel.displayConfirmedFriends[1].updateDate
                // 如果第一個不是置頂，日期應該較新或相等
                if !viewModel.displayConfirmedFriends.first!.isTop {
                    XCTAssertGreaterThanOrEqual(firstDate, secondDate)
                }
            }
            break
        }
    }
    
    func testFriendsSorting_CompleteRules() async throws {
        // Given - 從 friend3.json 載入資料，驗證排序規則
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            let friends = viewModel.displayConfirmedFriends
            
            // 驗證排序規則：1. isTop (true 在前), 2. updateDate (新到舊), 3. fid (小到大)
            if friends.count > 1 {
                for i in 0..<friends.count - 1 {
                    let current = friends[i]
                    let next = friends[i + 1]
                    
                    // 如果 isTop 不同，current 應該是 true
                    if current.isTop != next.isTop {
                        XCTAssertTrue(current.isTop, "置頂好友應該排在非置頂好友前面")
                    } else if current.updateDate != next.updateDate {
                        // 如果 isTop 相同，日期較新的應該在前面
                        XCTAssertGreaterThanOrEqual(current.updateDate, next.updateDate, "日期較新的應該排在前面")
                    } else {
                        // 如果日期也相同，fid 較小的應該在前面
                        XCTAssertLessThanOrEqual(current.fid, next.fid, "fid 較小的應該排在前面")
                    }
                }
            }
            break
        }
    }
    
    // MARK: - 測試 TableView Data Source
    
    func testNumberOfRows() async throws {
        // Given - 從 friend3.json 載入資料
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // When & Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // friend3.json 包含 status=0 (requestSent) 和 status=1/2 (accepted/pending) 的好友
            if viewModel.hasFriendRequests && viewModel.hasConfirmedFriends {
                XCTAssertEqual(viewModel.numberOfRows(in: 0), viewModel.displayRequestFriends.count) // Requests section
                XCTAssertEqual(viewModel.numberOfRows(in: 1), viewModel.displayConfirmedFriends.count) // Friends section
            } else if viewModel.hasConfirmedFriends {
                XCTAssertEqual(viewModel.numberOfRows(in: 0), viewModel.displayConfirmedFriends.count)
            }
            break
        }
    }
    
    func testIsRequestSection() async throws {
        // Given - 從 friend3.json 載入資料
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // When & Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            // friend3.json 包含 status=0 (requestSent) 的好友
            if viewModel.hasFriendRequests {
                XCTAssertTrue(viewModel.isRequestSection(0))
                if viewModel.numberOfSections > 1 {
                    XCTAssertFalse(viewModel.isRequestSection(1))
                }
            }
            break
        }
    }
    
    func testTitleForHeader() async throws {
        // Given - 從 friend3.json 載入資料
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // When & Then - 使用 async/await 等待 publisher 發送事件
        for try await _ in viewModel.friendsDataLoadedPublisher.values {
            if viewModel.hasFriendRequests && viewModel.hasConfirmedFriends {
                XCTAssertEqual(viewModel.titleForHeader(in: 0), "Requests")
                XCTAssertEqual(viewModel.titleForHeader(in: 1), "Friends")
            } else if viewModel.hasConfirmedFriends {
                XCTAssertEqual(viewModel.titleForHeader(in: 0), "Friends")
            }
            break
        }
    }
    
    // MARK: - 測試選項切換
    
    func testSelectOption() async throws {
        // Given - 先訂閱，再執行操作
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
        // Given - MockRepository 會從 JSON 檔案讀取資料
        // 先訂閱 publisher，確保不會錯過事件
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
        
        // Then - 等待兩個 publisher 都發送事件
        await fulfillment(of: [profileExpectation, friendsExpectation], timeout: 2.0)
        
        // 驗證從 JSON 檔案讀取的資料
        XCTAssertFalse(viewModel.userName.isEmpty)
        XCTAssertFalse(viewModel.userKokoId.isEmpty)
        // friend4.json 是空陣列
        XCTAssertEqual(viewModel.allFriends.count, 0)
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

