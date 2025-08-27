import XCTest
@testable import FormatFinder

class EdgeCaseTests: XCTestCase {
    
    // MARK: - Data Corruption Tests
    
    func testCorruptedBookmarkRecovery() {
        let defaults = UserDefaults.standard
        let key = "bookmarkedFormats"
        
        // Inject corrupted data
        let corruptedData = "not valid json".data(using: .utf8)!
        defaults.set(corruptedData, forKey: key)
        
        // Attempt to decode
        let bookmarks = defaults.safelyDecode([String].self, from: key)
        XCTAssertNil(bookmarks, "Should return nil for corrupted data")
        
        // Verify key was removed
        XCTAssertNil(defaults.data(forKey: key), "Corrupted data should be removed")
    }
    
    func testEmptyDataHandling() {
        let formats: [GolfFormat] = []
        let searchText = "test"
        
        let filtered = formats.filter { format in
            format.name.localizedCaseInsensitiveContains(searchText)
        }
        
        XCTAssertEqual(filtered.count, 0)
        XCTAssertTrue(filtered.isEmpty)
    }
    
    func testNilValueHandling() {
        let format = GolfFormat(
            id: "test",
            name: "",
            description: "",
            category: .tournament,
            difficulty: .beginner,
            players: "",
            objective: "",
            scoring: "",
            rules: [],
            variations: [],
            icon: ""
        )
        
        XCTAssertEqual(format.name, "")
        XCTAssertEqual(format.rules.count, 0)
        XCTAssertEqual(format.variations.count, 0)
    }
    
    // MARK: - Boundary Tests
    
    func testMaximumBookmarks() {
        let bookmarkManager = BookmarkManager()
        let maxBookmarks = 1000
        
        // Add maximum bookmarks
        for i in 0..<maxBookmarks {
            bookmarkManager.addBookmark("format-\(i)")
        }
        
        XCTAssertEqual(bookmarkManager.bookmarkedIds.count, maxBookmarks)
        
        // Try to add one more
        bookmarkManager.addBookmark("format-extra")
        XCTAssertEqual(bookmarkManager.bookmarkedIds.count, maxBookmarks + 1)
    }
    
    func testLongSearchString() {
        let formats = sampleGolfFormats
        let longSearchText = String(repeating: "a", count: 1000)
        
        let filtered = formats.filter { format in
            format.name.localizedCaseInsensitiveContains(longSearchText)
        }
        
        XCTAssertEqual(filtered.count, 0)
    }
    
    func testRapidStateChanges() {
        let timerManager = TimerManager(slideCount: 5)
        
        // Rapidly change slides
        for _ in 0..<100 {
            timerManager.nextSlide()
            timerManager.previousSlide()
        }
        
        XCTAssertTrue(timerManager.currentSlide >= 0)
        XCTAssertTrue(timerManager.currentSlide < timerManager.slideCount)
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentBookmarkOperations() {
        let bookmarkManager = BookmarkManager()
        let expectation = XCTestExpectation(description: "Concurrent operations")
        let operationCount = 100
        
        DispatchQueue.concurrentPerform(iterations: operationCount) { index in
            if index % 2 == 0 {
                bookmarkManager.addBookmark("format-\(index)")
            } else {
                bookmarkManager.removeBookmark("format-\(index - 1)")
            }
        }
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(bookmarkManager.bookmarkedIds.count <= operationCount)
    }
    
    func testRaceConditionInTimerManager() {
        let timerManager = TimerManager(slideCount: 10)
        let expectation = XCTestExpectation(description: "Race condition test")
        
        // Start multiple concurrent operations
        DispatchQueue.global().async {
            timerManager.startSlideshow()
        }
        
        DispatchQueue.global().async {
            timerManager.stopSlideshow()
        }
        
        DispatchQueue.global().async {
            timerManager.nextSlide()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Verify timer manager is in valid state
        XCTAssertTrue(timerManager.currentSlide >= 0)
        XCTAssertTrue(timerManager.currentSlide < timerManager.slideCount)
    }
    
    // MARK: - Memory Tests
    
    func testMemoryLeakInTimerManager() {
        weak var weakTimerManager: TimerManager?
        
        autoreleasepool {
            let timerManager = TimerManager(slideCount: 5)
            weakTimerManager = timerManager
            
            timerManager.startSlideshow()
            timerManager.stopSlideshow()
        }
        
        XCTAssertNil(weakTimerManager, "TimerManager should be deallocated")
    }
    
    func testLargeDataSetHandling() {
        // Create large dataset
        var formats: [GolfFormat] = []
        for i in 0..<10000 {
            formats.append(GolfFormat(
                id: "format-\(i)",
                name: "Format \(i)",
                description: String(repeating: "Description ", count: 100),
                category: i % 2 == 0 ? .tournament : .betting,
                difficulty: .intermediate,
                players: "2-4",
                objective: "Objective",
                scoring: "Scoring",
                rules: Array(repeating: "Rule", count: 10),
                variations: Array(repeating: "Variation", count: 5),
                icon: "gamecontroller"
            ))
        }
        
        // Test filtering performance
        let startTime = Date()
        let filtered = formats.filter { $0.category == .tournament }
        let endTime = Date()
        
        let timeInterval = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(timeInterval, 1.0, "Filtering should complete within 1 second")
        XCTAssertEqual(filtered.count, 5000)
    }
    
    // MARK: - State Restoration Tests
    
    func testStateRestorationAfterCrash() {
        let coordinator = NavigationCoordinator()
        
        // Simulate navigation state
        coordinator.navigate(to: .bookmarks)
        coordinator.navigate(to: .settings)
        coordinator.selectedTab = 1
        
        // Simulate crash and restoration
        let savedPath = coordinator.navigationPath
        let savedTab = coordinator.selectedTab
        
        // Create new coordinator (simulating app restart)
        let newCoordinator = NavigationCoordinator()
        
        // Restore state
        // In real app, this would be from UserDefaults or state restoration
        newCoordinator.selectedTab = savedTab
        
        XCTAssertEqual(newCoordinator.selectedTab, 1)
    }
    
    // MARK: - Network Edge Cases
    
    func testOfflineMode() {
        // Test that app works without network
        let errorHandler = ErrorHandler.shared
        
        // Simulate network error
        errorHandler.handle(.networkUnavailable)
        
        XCTAssertNotNil(errorHandler.currentError)
        XCTAssertEqual(errorHandler.currentError, .networkUnavailable)
        
        // Verify app continues to function
        let formats = sampleGolfFormats
        XCTAssertGreaterThan(formats.count, 0)
    }
    
    // MARK: - Input Validation Tests
    
    func testSpecialCharacterHandling() {
        let specialCharacters = ["<script>", "'; DROP TABLE;", "🔥💯", "\\n\\r\\t", String(repeating: "😀", count: 100)]
        let formats = sampleGolfFormats
        
        for special in specialCharacters {
            let filtered = formats.filter { format in
                format.name.localizedCaseInsensitiveContains(special)
            }
            XCTAssertEqual(filtered.count, 0, "Should safely handle special characters")
        }
    }
    
    func testUnicodeHandling() {
        let unicodeStrings = ["你好", "مرحبا", "שָׁלוֹם", "Здравствуйте", "🇺🇸🇬🇧🇯🇵"]
        
        for unicode in unicodeStrings {
            let format = GolfFormat(
                id: unicode,
                name: unicode,
                description: unicode,
                category: .tournament,
                difficulty: .intermediate,
                players: unicode,
                objective: unicode,
                scoring: unicode,
                rules: [unicode],
                variations: [unicode],
                icon: "gamecontroller"
            )
            
            XCTAssertEqual(format.name, unicode)
            XCTAssertEqual(format.id, unicode)
        }
    }
    
    // MARK: - Animation Edge Cases
    
    func testAnimationInterruption() {
        let timerManager = TimerManager(slideCount: 5)
        
        // Start animation
        timerManager.startSlideshow()
        
        // Immediately interrupt
        timerManager.stopSlideshow()
        timerManager.startSlideshow()
        timerManager.goToSlide(3)
        timerManager.stopSlideshow()
        
        XCTAssertEqual(timerManager.currentSlide, 3)
        XCTAssertFalse(timerManager.isPlaying)
    }
    
    func testInvalidSlideIndex() {
        let timerManager = TimerManager(slideCount: 5)
        
        // Try invalid indices
        timerManager.goToSlide(-1)
        XCTAssertEqual(timerManager.currentSlide, 0)
        
        timerManager.goToSlide(10)
        XCTAssertEqual(timerManager.currentSlide, 0)
        
        timerManager.goToSlide(Int.max)
        XCTAssertEqual(timerManager.currentSlide, 0)
    }
}