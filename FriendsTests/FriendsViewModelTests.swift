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
    
    // MARK: - Helper
    
    func waitForStateLoaded(timeout: TimeInterval = 2.0) async {
        let expectation = XCTestExpectation(description: "State became loaded")
        
        viewModel.$state
            .sink { state in
                if case .loaded = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: timeout)
    }

    func waitForStateError(timeout: TimeInterval = 2.0) async -> Error? {
        let expectation = XCTestExpectation(description: "State became error")
        var resultError: Error?
        
        viewModel.$state
            .sink { state in
                if case .error(let error) = state {
                    resultError = error
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: timeout)
        return resultError
    }

    // MARK: - 測試載入好友資料

    func testLoadFriendsData_NoFriends() async throws {
        // When
        viewModel.loadFriendsData(for: .noFriends)
        
        // Then
        await waitForStateLoaded()
        
        // friend4.json 是空陣列
        XCTAssertEqual(viewModel.allFriends.count, 0)
        XCTAssertFalse(viewModel.hasFriends)
    }
    
    func testLoadFriendsData_WithConfirmedFriends() async throws {
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        await waitForStateLoaded()
        
        // friend3.json 包含多個好友，包含已確認和邀請狀態
        XCTAssertTrue(viewModel.allFriends.count > 0)
        XCTAssertTrue(viewModel.hasFriends)
        // friend3.json 包含 status=1 (accepted) 和 status=2 (pending) 的好友
        XCTAssertTrue(viewModel.hasConfirmedFriends || viewModel.hasFriendRequests)
    }
    
    func testLoadFriendsData_WithRequests() async throws {
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        await waitForStateLoaded()
        
        // friend3.json 包含 status=0 (requestSent), status=1 (accepted), status=2 (pending)
        XCTAssertTrue(viewModel.allFriends.count > 0)
        // 如果有邀請和已確認好友，應該分別有 displayRequestFriends 和 displayConfirmedFriends
        if viewModel.hasFriendRequests && viewModel.hasConfirmedFriends {
            XCTAssertTrue(viewModel.displayRequestFriends.count > 0)
            XCTAssertTrue(viewModel.displayConfirmedFriends.count > 0)
        }
    }
    
    func testLoadFriendsData_MergeFriends() async throws {
        // When
        viewModel.loadFriendsData(for: .friendsListOnly)
        
        // Then
        await waitForStateLoaded()
        
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
    }
    
    // MARK: - 測試搜尋功能
    
    func testFilterFriends_EmptySearch() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        let initialConfirmedCount = viewModel.displayConfirmedFriends.count
        
        // When
        viewModel.filterFriends(name: "")
        
        // Then - 空搜尋應該顯示所有已確認好友
        XCTAssertEqual(viewModel.displayConfirmedFriends.count, initialConfirmedCount)
    }
    
    func testFilterFriends_WithSearchText() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        // When - 搜尋 friend3.json 中的實際好友名稱（例如 "黃"）
        viewModel.filterFriends(name: "黃")
        
        // Then - 應該過濾出包含 "黃" 的好友
        let filteredCount = viewModel.displayConfirmedFriends.count
        XCTAssertTrue(filteredCount >= 0)
        if filteredCount > 0 {
            XCTAssertTrue(viewModel.displayConfirmedFriends.first?.name.contains("黃") ?? false)
        }
    }
    
    func testClearSearch() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        let initialConfirmedCount = viewModel.displayConfirmedFriends.count
        viewModel.filterFriends(name: "test")
        
        // When
        viewModel.clearSearch()
        
        // Then - 過濾結果應該恢復（顯示所有好友）
        XCTAssertEqual(viewModel.displayConfirmedFriends.count, initialConfirmedCount, "清除搜尋後應該顯示所有好友")
    }
    
    // MARK: - 測試搜尋狀態管理
    
    func testStartSearching_WithFriendRequests() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        guard viewModel.hasFriendRequests else {
            throw XCTSkip("此測試需要包含邀請的資料")
        }
        
        // 預設折疊狀態
        viewModel.isRequestsSectionExpanded = false
        let previousState = viewModel.isRequestsSectionExpanded
        
        // When - 開始搜尋
        viewModel.startSearching()
        
        // Then - 應該設為搜尋中，如果有邀請則強制展開
        XCTAssertTrue(viewModel.isSearching, "應該設為搜尋中")
        XCTAssertTrue(viewModel.isRequestsSectionExpanded, "如果有邀請，應該強制展開")
        
        // 驗證狀態被保存：結束搜尋後應該恢復到之前的狀態
        viewModel.stopSearching()
        XCTAssertEqual(viewModel.isRequestsSectionExpanded, previousState, "結束搜尋後應該恢復到搜尋前的狀態")
    }
    
    func testStartSearching_WithoutFriendRequests() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListOnly)
        await waitForStateLoaded()
        
        // 預設折疊狀態
        viewModel.isRequestsSectionExpanded = false
        let previousState = viewModel.isRequestsSectionExpanded
        
        // When - 開始搜尋
        viewModel.startSearching()
        
        // Then - 應該設為搜尋中，但不會改變展開狀態（因為沒有邀請）
        XCTAssertTrue(viewModel.isSearching, "應該設為搜尋中")
        XCTAssertEqual(viewModel.isRequestsSectionExpanded, previousState, "沒有邀請時，展開狀態不應該改變")
        
        // 驗證狀態被保存：結束搜尋後應該恢復到之前的狀態
        viewModel.stopSearching()
        XCTAssertEqual(viewModel.isRequestsSectionExpanded, previousState, "結束搜尋後應該恢復到搜尋前的狀態")
    }
    
    func testStopSearching() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        // 設定初始狀態為折疊
        viewModel.isRequestsSectionExpanded = false
        let originalState = viewModel.isRequestsSectionExpanded
        
        // 開始搜尋（如果有邀請會改變狀態）
        viewModel.startSearching()
        
        // When - 結束搜尋
        viewModel.stopSearching()
        
        // Then - 應該恢復搜尋前的狀態
        XCTAssertFalse(viewModel.isSearching, "應該設為非搜尋中")
        XCTAssertEqual(viewModel.isRequestsSectionExpanded, originalState, "應該恢復到原始狀態")
        
        // 驗證：如果搜尋前是展開的，結束後也應該是展開的
        viewModel.isRequestsSectionExpanded = true
        let expandedState = viewModel.isRequestsSectionExpanded
        viewModel.startSearching()
        viewModel.stopSearching()
        XCTAssertEqual(viewModel.isRequestsSectionExpanded, expandedState, "應該恢復到搜尋前的展開狀態")
    }
    
    func testStartSearching_StopSearching_CompleteFlow() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        guard viewModel.hasFriendRequests else {
            throw XCTSkip("此測試需要包含邀請的資料")
        }
        
        // 設定初始折疊狀態
        viewModel.isRequestsSectionExpanded = false
        let initialState = viewModel.isRequestsSectionExpanded
        
        // When - 開始搜尋
        viewModel.startSearching()
        
        // Then - 驗證搜尋開始後的狀態
        XCTAssertTrue(viewModel.isSearching)
        XCTAssertTrue(viewModel.isRequestsSectionExpanded, "有邀請時應該強制展開")
        
        // 驗證狀態被保存：結束搜尋後應該恢復到原始狀態
        viewModel.stopSearching()
        XCTAssertEqual(viewModel.isRequestsSectionExpanded, initialState, "應該恢復到原始折疊狀態")
        
        // When - 結束搜尋
        viewModel.stopSearching()
        
        // Then - 驗證搜尋結束後的狀態
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertEqual(viewModel.isRequestsSectionExpanded, initialState, "應該恢復到原始折疊狀態")
    }
    
    // MARK: - 測試排序功能
    
    func testFriendsSorting_ByIsTop() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        // 驗證排序：isTop=true 的好友應該排在前面
        if viewModel.displayConfirmedFriends.count > 1 {
            let firstFriend = viewModel.displayConfirmedFriends.first!
            // 第一個好友應該是 isTop=true，或者如果沒有置頂的，則按日期排序
            // friend3.json 中 "翁勳儀" 是 isTop="1"，應該排在前面
            XCTAssertTrue(firstFriend.isTop || viewModel.displayConfirmedFriends.allSatisfy { !$0.isTop })
        }
    }
    
    func testFriendsSorting_ByUpdateDate() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        // 驗證排序：較新的日期應該排在前面（如果 isTop 相同）
        if viewModel.displayConfirmedFriends.count > 1 {
            let firstDate = viewModel.displayConfirmedFriends.first!.updateDate
            let secondDate = viewModel.displayConfirmedFriends[1].updateDate
            // 如果第一個不是置頂，日期應該較新或相等
            if !viewModel.displayConfirmedFriends.first!.isTop {
                XCTAssertGreaterThanOrEqual(firstDate, secondDate)
            }
        }
    }
    
    func testFriendsSorting_CompleteRules() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
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
        // Given
        // When
        viewModel.loadAllData(for: .noFriends)
        
        // Then
        await waitForStateLoaded()
        
        // 驗證從 JSON 檔案讀取的資料
        XCTAssertFalse(viewModel.userName.isEmpty)
        XCTAssertFalse(viewModel.userKokoId.isEmpty)
        // friend4.json 是空陣列
        XCTAssertEqual(viewModel.allFriends.count, 0)
    }


    // MARK: - 測試資料存取
    
    func testDisplayRequestFriends() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        // Pre-check
        guard viewModel.hasFriendRequests else {
            XCTFail("Should have friend requests for this test")
            return
        }
        
        // When
        let requestFriend = viewModel.displayRequestFriends[0]
        
        // Then
        XCTAssertEqual(requestFriend.status, .requestSent)
    }
    
    func testDisplayConfirmedFriends() async throws {
        // Given
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        await waitForStateLoaded()
        
        // Pre-check
        guard viewModel.hasConfirmedFriends else {
            XCTFail("Should have confirmed friends for this test")
            return
        }
        
        // When
        let confirmedFriend = viewModel.displayConfirmedFriends[0]
        
        // Then
        XCTAssertTrue(confirmedFriend.status == .accepted || confirmedFriend.status == .pending)
        
        // 驗證排序：第一個應該是置頂的好友 (如果資料中有置頂好友)
        if let topFriend = viewModel.displayConfirmedFriends.first(where: { $0.isTop }) {
            XCTAssertEqual(confirmedFriend.fid, topFriend.fid)
        }
    }
    
    // MARK: - 測試初始化狀態
    
    func testInitialState() {
        XCTAssertEqual(viewModel.userName, "")
        XCTAssertEqual(viewModel.userKokoId, "")
        XCTAssertEqual(viewModel.selectedOption, .noFriends)
        XCTAssertFalse(viewModel.hasFriends)
        XCTAssertFalse(viewModel.hasFriendRequests)
        XCTAssertFalse(viewModel.hasConfirmedFriends)
        XCTAssertEqual(viewModel.currentTab, .friends, "預設應該選中 Friends tab")
        // 驗證初始狀態是 idle
        if case .idle = viewModel.state {
            // Success
        } else {
            XCTFail("Initial state should be idle")
        }
    }
    
    // MARK: - 測試 currentTab
    
    func testCurrentTab_Default() {
        // Then - 預設應該是 .friends
        XCTAssertEqual(viewModel.currentTab, .friends)
    }
    
    func testCurrentTab_SetToChat() {
        // When
        viewModel.currentTab = .chat
        
        // Then
        XCTAssertEqual(viewModel.currentTab, .chat)
    }
    
    func testCurrentTab_SetToFriends() {
        // Given - 先設為 .chat
        viewModel.currentTab = .chat
        XCTAssertEqual(viewModel.currentTab, .chat)
        
        // When - 改回 .friends
        viewModel.currentTab = .friends
        
        // Then
        XCTAssertEqual(viewModel.currentTab, .friends)
    }
    
    func testCurrentTab_Toggle() {
        // Given - 初始為 .friends
        XCTAssertEqual(viewModel.currentTab, .friends)
        
        // When - 切換到 .chat
        viewModel.currentTab = .chat
        
        // Then
        XCTAssertEqual(viewModel.currentTab, .chat)
        
        // When - 切換回 .friends
        viewModel.currentTab = .friends
        
        // Then
        XCTAssertEqual(viewModel.currentTab, .friends)
    }
    
    // MARK: - 測試 isRequestsSectionExpanded
    
    func testIsRequestsSectionExpanded_Default() {
        // Then - 預設應該是折疊的
        XCTAssertFalse(viewModel.isRequestsSectionExpanded)
    }
    
    func testIsRequestsSectionExpanded_Toggle() {
        // When
        viewModel.isRequestsSectionExpanded = false
        
        // Then
        XCTAssertFalse(viewModel.isRequestsSectionExpanded)
        
        // When
        viewModel.isRequestsSectionExpanded = true
        
        // Then
        XCTAssertTrue(viewModel.isRequestsSectionExpanded)
    }
    
    // MARK: - 測試 isUsingRealSearchController
    
    func testIsUsingRealSearchController_Default() {
        // Then - 預設應該不使用真實 SearchController
        XCTAssertFalse(viewModel.isUsingRealSearchController)
    }
    
    func testIsUsingRealSearchController_Toggle() {
        // When
        viewModel.isUsingRealSearchController = true
        
        // Then
        XCTAssertTrue(viewModel.isUsingRealSearchController)
    }
    
    // MARK: - 測試 ViewOption Enum
    
    func testViewOption_RawValues() {
        XCTAssertEqual(FriendsViewModel.ViewOption.noFriends.rawValue, "無好友畫面")
        XCTAssertEqual(FriendsViewModel.ViewOption.friendsListOnly.rawValue, "只有好友列表")
        XCTAssertEqual(FriendsViewModel.ViewOption.friendsListWithInvitation.rawValue, "好友列表含邀請")
    }
    
    // MARK: - 測試錯誤處理 (shouldThrowError = true)
    
    func testLoadFriendsData_ShouldThrowError_NoFriends() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        viewModel.loadFriendsData(for: .noFriends)
        
        // Then
        let error = await waitForStateError()
        XCTAssertNotNil(error)
        
        // 驗證錯誤類型 - 應該是 NetworkError.invalidURL (因為 Mock 拋出這個)
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                // Correct
                break
            default:
                XCTFail("應該收到 NetworkError.invalidURL")
            }
        } else {
            XCTFail("應該收到 NetworkError")
        }
    }
    
    func testLoadFriendsData_ShouldThrowError_WithInvitation() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        viewModel.loadFriendsData(for: .friendsListWithInvitation)
        
        // Then
        let error = await waitForStateError()
        XCTAssertNotNil(error)
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                break
            default:
                XCTFail("應該收到 NetworkError.invalidURL")
            }
        } else {
            XCTFail("應該收到 NetworkError")
        }
    }
    
    func testLoadFriendsData_ShouldThrowError_FriendsListOnly() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        viewModel.loadFriendsData(for: .friendsListOnly)
        
        // Then
        let error = await waitForStateError()
        XCTAssertNotNil(error)
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                break
            default:
                XCTFail("應該收到 NetworkError.invalidURL")
            }
        } else {
            XCTFail("應該收到 NetworkError")
        }
    }
    
    func testLoadAllData_ShouldThrowError() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        viewModel.loadAllData(for: .noFriends)
        
        // Then
        let error = await waitForStateError()
        XCTAssertNotNil(error)
        
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                break
            default:
                XCTFail("應該收到 NetworkError.invalidURL")
            }
        } else {
            XCTFail("應該收到 NetworkError")
        }
    }
}
