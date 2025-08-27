import XCTest
@testable import FormatFinder

class FormatFinderUnitTests: XCTestCase {
    
    // MARK: - Golf Format Tests
    
    func testGolfFormatInitialization() {
        let format = GolfFormat(
            id: "test-1",
            name: "Test Format",
            description: "Test Description",
            category: .tournament,
            difficulty: .intermediate,
            players: "2-4",
            objective: "Test Objective",
            scoring: "Test Scoring",
            rules: ["Rule 1", "Rule 2"],
            variations: ["Variation 1"],
            icon: "gamecontroller"
        )
        
        XCTAssertEqual(format.id, "test-1")
        XCTAssertEqual(format.name, "Test Format")
        XCTAssertEqual(format.category, .tournament)
        XCTAssertEqual(format.difficulty, .intermediate)
        XCTAssertEqual(format.rules.count, 2)
        XCTAssertEqual(format.variations.count, 1)
    }
    
    func testFormatSearchFilter() {
        let formats = sampleGolfFormats
        let searchText = "scramble"
        
        let filtered = formats.filter { format in
            format.name.localizedCaseInsensitiveContains(searchText) ||
            format.description.localizedCaseInsensitiveContains(searchText)
        }
        
        XCTAssertGreaterThan(filtered.count, 0)
        XCTAssertTrue(filtered.allSatisfy { format in
            format.name.localizedCaseInsensitiveContains(searchText) ||
            format.description.localizedCaseInsensitiveContains(searchText)
        })
    }
    
    func testCategoryFiltering() {
        let formats = sampleGolfFormats
        let tournamentFormats = formats.filter { $0.category == .tournament }
        let bettingFormats = formats.filter { $0.category == .betting }
        
        XCTAssertGreaterThan(tournamentFormats.count, 0)
        XCTAssertGreaterThan(bettingFormats.count, 0)
        XCTAssertEqual(tournamentFormats.count + bettingFormats.count, formats.count)
    }
    
    // MARK: - Bookmark Tests
    
    func testBookmarkAddition() {
        let bookmarkManager = BookmarkManager()
        let formatId = "test-format-1"
        
        bookmarkManager.addBookmark(formatId)
        XCTAssertTrue(bookmarkManager.isBookmarked(formatId))
        XCTAssertEqual(bookmarkManager.bookmarkedIds.count, 1)
    }
    
    func testBookmarkRemoval() {
        let bookmarkManager = BookmarkManager()
        let formatId = "test-format-1"
        
        bookmarkManager.addBookmark(formatId)
        XCTAssertTrue(bookmarkManager.isBookmarked(formatId))
        
        bookmarkManager.removeBookmark(formatId)
        XCTAssertFalse(bookmarkManager.isBookmarked(formatId))
        XCTAssertEqual(bookmarkManager.bookmarkedIds.count, 0)
    }
    
    func testBookmarkToggle() {
        let bookmarkManager = BookmarkManager()
        let formatId = "test-format-1"
        
        bookmarkManager.toggleBookmark(formatId)
        XCTAssertTrue(bookmarkManager.isBookmarked(formatId))
        
        bookmarkManager.toggleBookmark(formatId)
        XCTAssertFalse(bookmarkManager.isBookmarked(formatId))
    }
    
    func testBookmarkPersistence() {
        let bookmarkManager = BookmarkManager()
        let formatIds = ["test-1", "test-2", "test-3"]
        
        formatIds.forEach { bookmarkManager.addBookmark($0) }
        
        // Simulate saving and loading
        let savedData = try? JSONEncoder().encode(bookmarkManager.bookmarkedIds)
        XCTAssertNotNil(savedData)
        
        let loadedIds = try? JSONDecoder().decode([String].self, from: savedData!)
        XCTAssertEqual(loadedIds?.count, 3)
        XCTAssertEqual(Set(loadedIds!), Set(formatIds))
    }
    
    // MARK: - Timer Manager Tests
    
    func testTimerManagerInitialization() {
        let timerManager = TimerManager(slideCount: 5, slideDuration: 2.0)
        
        XCTAssertEqual(timerManager.slideCount, 5)
        XCTAssertEqual(timerManager.slideDuration, 2.0)
        XCTAssertEqual(timerManager.currentSlide, 0)
        XCTAssertFalse(timerManager.isPlaying)
    }
    
    func testSlideNavigation() {
        let timerManager = TimerManager(slideCount: 5)
        
        timerManager.nextSlide()
        XCTAssertEqual(timerManager.currentSlide, 1)
        
        timerManager.previousSlide()
        XCTAssertEqual(timerManager.currentSlide, 0)
        
        timerManager.goToSlide(3)
        XCTAssertEqual(timerManager.currentSlide, 3)
    }
    
    func testSlideWrapAround() {
        let timerManager = TimerManager(slideCount: 3)
        
        // Test forward wrap
        timerManager.goToSlide(2)
        timerManager.nextSlide()
        XCTAssertEqual(timerManager.currentSlide, 0)
        
        // Test backward wrap
        timerManager.goToSlide(0)
        timerManager.previousSlide()
        XCTAssertEqual(timerManager.currentSlide, 2)
    }
    
    // MARK: - Navigation Coordinator Tests
    
    func testNavigationCoordinatorDeepLink() {
        let coordinator = NavigationCoordinator()
        let formatId = sampleGolfFormats[0].id
        let url = URL(string: "formatfinder://format?id=\(formatId)")!
        
        coordinator.handleDeepLink(url)
        XCTAssertNotNil(coordinator.presentedSheet)
        
        if case let .formatDetail(format) = coordinator.presentedSheet {
            XCTAssertEqual(format.id, formatId)
        } else {
            XCTFail("Expected format detail sheet")
        }
    }
    
    func testRecentlyViewedTracking() {
        let coordinator = NavigationCoordinator()
        let formatIds = ["format-1", "format-2", "format-3"]
        
        formatIds.forEach { coordinator.navigateToFormat(withId: $0) }
        
        XCTAssertEqual(coordinator.recentlyViewed.count, 3)
        XCTAssertEqual(coordinator.recentlyViewed[0], "format-3")
        
        // Test duplicate handling
        coordinator.navigateToFormat(withId: "format-1")
        XCTAssertEqual(coordinator.recentlyViewed[0], "format-1")
        XCTAssertEqual(coordinator.recentlyViewed.count, 3)
    }
    
    func testNavigationStack() {
        let coordinator = NavigationCoordinator()
        let format = sampleGolfFormats[0]
        
        coordinator.navigate(to: .formatDetail(format))
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        
        coordinator.navigate(to: .bookmarks)
        XCTAssertEqual(coordinator.navigationPath.count, 2)
        
        coordinator.navigateBack()
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        
        coordinator.navigateToRoot()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlerInitialization() {
        let errorHandler = ErrorHandler.shared
        XCTAssertNil(errorHandler.currentError)
        XCTAssertFalse(errorHandler.showError)
    }
    
    func testErrorHandling() {
        let errorHandler = ErrorHandler.shared
        errorHandler.handle(.bookmarkCorrupted)
        
        XCTAssertNotNil(errorHandler.currentError)
        XCTAssertTrue(errorHandler.showError)
        XCTAssertEqual(errorHandler.currentError, .bookmarkCorrupted)
        
        errorHandler.reset()
        XCTAssertNil(errorHandler.currentError)
        XCTAssertFalse(errorHandler.showError)
    }
    
    func testSafeDataOperations() {
        let defaults = UserDefaults.standard
        let key = "test_key"
        let testData = ["item1", "item2", "item3"]
        
        // Test safe encoding
        defaults.safelyEncode(testData, for: key)
        
        // Test safe decoding
        let decoded = defaults.safelyDecode([String].self, from: key)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded, testData)
        
        // Test corrupted data handling
        defaults.set(Data(), forKey: key)
        let corruptedDecode = defaults.safelyDecode([String].self, from: key)
        XCTAssertNil(corruptedDecode)
    }
}

// MARK: - Bookmark Manager Mock
class BookmarkManager {
    private(set) var bookmarkedIds: [String] = []
    
    func addBookmark(_ id: String) {
        if !bookmarkedIds.contains(id) {
            bookmarkedIds.append(id)
        }
    }
    
    func removeBookmark(_ id: String) {
        bookmarkedIds.removeAll { $0 == id }
    }
    
    func toggleBookmark(_ id: String) {
        if isBookmarked(id) {
            removeBookmark(id)
        } else {
            addBookmark(id)
        }
    }
    
    func isBookmarked(_ id: String) -> Bool {
        bookmarkedIds.contains(id)
    }
}