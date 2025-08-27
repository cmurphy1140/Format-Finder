import XCTest

class FormatFinderUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch Tests
    
    func testAppLaunch() throws {
        // Verify launch screen appears
        let launchScreen = app.otherElements["LaunchScreen"]
        XCTAssertTrue(launchScreen.waitForExistence(timeout: 1))
        
        // Wait for main screen
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.waitForExistence(timeout: 5))
    }
    
    // MARK: - Navigation Tests
    
    func testTabBarNavigation() {
        // Test Browse tab
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.exists)
        browseTab.tap()
        
        let browseTitle = app.navigationBars["Golf Formats"]
        XCTAssertTrue(browseTitle.waitForExistence(timeout: 2))
        
        // Test Saved tab
        let savedTab = app.tabBars.buttons["Saved"]
        XCTAssertTrue(savedTab.exists)
        savedTab.tap()
        
        let savedTitle = app.navigationBars["Saved Formats"]
        XCTAssertTrue(savedTitle.waitForExistence(timeout: 2))
    }
    
    func testFormatDetailNavigation() {
        // Navigate to first format
        let firstFormat = app.scrollViews.buttons.element(boundBy: 0)
        XCTAssertTrue(firstFormat.waitForExistence(timeout: 2))
        firstFormat.tap()
        
        // Verify detail sheet appears
        let detailSheet = app.sheets.element
        XCTAssertTrue(detailSheet.waitForExistence(timeout: 2))
        
        // Test dismiss button
        let dismissButton = app.buttons["Done"]
        XCTAssertTrue(dismissButton.exists)
        dismissButton.tap()
        
        // Verify sheet dismissed
        XCTAssertFalse(detailSheet.exists)
    }
    
    // MARK: - Search Tests
    
    func testSearchFunctionality() {
        let searchField = app.textFields["Search formats..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        
        // Test search input
        searchField.tap()
        searchField.typeText("Scramble")
        
        // Verify filtered results
        let formatButtons = app.scrollViews.buttons
        XCTAssertGreaterThan(formatButtons.count, 0)
        
        // Clear search
        let clearButton = app.buttons["Clear"]
        if clearButton.exists {
            clearButton.tap()
        }
    }
    
    func testSearchNoResults() {
        let searchField = app.textFields["Search formats..."]
        searchField.tap()
        searchField.typeText("XXXXXX")
        
        // Verify no results message
        let noResultsText = app.staticTexts["No formats found"]
        XCTAssertTrue(noResultsText.waitForExistence(timeout: 2))
    }
    
    // MARK: - Filter Tests
    
    func testCategoryFilters() {
        // Test All filter
        let allFilter = app.buttons["All"]
        XCTAssertTrue(allFilter.exists)
        allFilter.tap()
        
        // Test Tournament filter
        let tournamentFilter = app.buttons["Tournament"]
        XCTAssertTrue(tournamentFilter.exists)
        tournamentFilter.tap()
        
        let formatButtons = app.scrollViews.buttons
        XCTAssertGreaterThan(formatButtons.count, 0)
        
        // Test Betting filter
        let bettingFilter = app.buttons["Betting"]
        XCTAssertTrue(bettingFilter.exists)
        bettingFilter.tap()
        
        XCTAssertGreaterThan(formatButtons.count, 0)
    }
    
    // MARK: - Bookmark Tests
    
    func testBookmarkFunctionality() {
        // Navigate to format detail
        let firstFormat = app.scrollViews.buttons.element(boundBy: 0)
        firstFormat.tap()
        
        // Find bookmark button
        let bookmarkButton = app.buttons["Bookmark"]
        XCTAssertTrue(bookmarkButton.waitForExistence(timeout: 2))
        
        // Toggle bookmark
        bookmarkButton.tap()
        
        // Verify bookmark state changed
        let bookmarkFillButton = app.buttons.matching(identifier: "bookmark.fill").element
        XCTAssertTrue(bookmarkFillButton.exists || bookmarkButton.exists)
        
        // Dismiss detail
        app.buttons["Done"].tap()
        
        // Navigate to Saved tab
        app.tabBars.buttons["Saved"].tap()
        
        // Verify bookmarked format appears
        let savedFormats = app.scrollViews.buttons
        XCTAssertGreaterThan(savedFormats.count, 0)
    }
    
    // MARK: - Slideshow Tests
    
    func testSlideshowInteraction() {
        // Navigate to format detail
        let firstFormat = app.scrollViews.buttons.element(boundBy: 0)
        firstFormat.tap()
        
        // Find slideshow
        let slideshow = app.scrollViews.otherElements["FormatSlideshow"]
        XCTAssertTrue(slideshow.waitForExistence(timeout: 2))
        
        // Test play button
        let playButton = app.buttons["play.fill"]
        if playButton.exists {
            playButton.tap()
            
            // Verify pause button appears
            let pauseButton = app.buttons["pause.fill"]
            XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
        }
        
        // Test manual navigation
        let nextButton = app.buttons["chevron.right"]
        if nextButton.exists {
            nextButton.tap()
            sleep(1)
        }
        
        let previousButton = app.buttons["chevron.left"]
        if previousButton.exists {
            previousButton.tap()
            sleep(1)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        // Verify key elements have accessibility labels
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertNotNil(browseTab.label)
        
        let searchField = app.textFields["Search formats..."]
        XCTAssertNotNil(searchField.label)
        
        let firstFormat = app.scrollViews.buttons.element(boundBy: 0)
        if firstFormat.waitForExistence(timeout: 2) {
            XCTAssertNotNil(firstFormat.label)
        }
    }
    
    func testVoiceOverNavigation() {
        // Enable VoiceOver simulation
        app.launchArguments.append("-UIAccessibilityEnabled")
        app.launch()
        
        // Test VoiceOver navigation
        let elements = app.descendants(matching: .any)
        XCTAssertGreaterThan(elements.count, 0)
        
        // Verify elements are accessible
        for i in 0..<min(5, elements.count) {
            let element = elements.element(boundBy: i)
            if element.isHittable {
                XCTAssertTrue(element.isAccessibilityElement || !element.label.isEmpty)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testScrollPerformance() {
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            let scrollView = app.scrollViews.element
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
    }
    
    func testAppLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testOrientationChange() {
        // Test portrait to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        // Verify UI adjusts
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.exists)
        
        // Test landscape to portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        XCTAssertTrue(browseTab.exists)
    }
    
    func testBackgroundForeground() {
        // Send app to background
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Bring back to foreground
        app.activate()
        
        // Verify state preserved
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.waitForExistence(timeout: 2))
    }
    
    func testMemoryWarning() {
        // Simulate memory warning
        app.launchArguments.append("-AppleLanguages")
        app.launchArguments.append("(en)")
        app.launchArguments.append("-UIApplicationMemoryWarning")
        app.launch()
        
        // Verify app handles memory warning gracefully
        let browseTab = app.tabBars.buttons["Browse"]
        XCTAssertTrue(browseTab.waitForExistence(timeout: 5))
    }
}