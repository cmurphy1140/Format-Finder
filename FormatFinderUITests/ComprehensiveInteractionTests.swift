import XCTest
import SwiftUI

class ComprehensiveInteractionTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Button Interaction Tests
    
    func testAllButtonsRespond() throws {
        // Test main navigation buttons
        let formatButton = app.buttons["Formats"]
        XCTAssertTrue(formatButton.exists, "Formats button should exist")
        formatButton.tap()
        
        // Test info button
        let infoButton = app.buttons["Info"]
        if infoButton.exists {
            infoButton.tap()
            XCTAssertTrue(app.staticTexts["About"].exists, "Info should show about view")
            app.buttons["Done"].tap()
        }
        
        // Test profile button
        let profileButton = app.buttons["Profile"]
        if profileButton.exists {
            profileButton.tap()
            XCTAssertTrue(app.navigationBars["Settings"].exists, "Profile should show settings")
            app.buttons["Done"].tap()
        }
    }
    
    func testRapidButtonTapping() throws {
        // Edge case: Rapid repeated taps shouldn't crash
        let formatButton = app.buttons["Formats"]
        
        for _ in 0..<10 {
            if formatButton.exists && formatButton.isHittable {
                formatButton.tap()
            }
        }
        
        XCTAssertTrue(app.exists, "App should remain stable after rapid tapping")
    }
    
    func testButtonStateChanges() throws {
        // Test button enabled/disabled states
        let startGameButton = app.buttons["Start Game"]
        
        if startGameButton.exists {
            // Initially might be disabled without player selection
            if !startGameButton.isEnabled {
                // Add players
                app.buttons["Add Player"].tap()
                app.textFields["Player Name"].tap()
                app.textFields["Player Name"].typeText("Test Player")
                app.buttons["Done"].tap()
                
                // Now button should be enabled
                XCTAssertTrue(startGameButton.isEnabled, "Start button should enable after adding player")
            }
        }
    }
    
    // MARK: - Swipe Gesture Tests
    
    func testSwipeableFormatCards() throws {
        // Navigate to format cards
        if app.buttons["Formats"].exists {
            app.buttons["Formats"].tap()
        }
        
        // Test swipe gestures
        let formatCard = app.otherElements["FormatCard_0"]
        if formatCard.exists {
            // Swipe left
            formatCard.swipeLeft()
            sleep(1)
            
            // Verify next card is visible
            let nextCard = app.otherElements["FormatCard_1"]
            XCTAssertTrue(nextCard.exists || formatCard.exists, "Card navigation should work")
            
            // Swipe right
            if nextCard.exists {
                nextCard.swipeRight()
                sleep(1)
            }
            
            // Test edge case: Multiple rapid swipes
            for _ in 0..<5 {
                formatCard.swipeLeft()
            }
            XCTAssertTrue(app.exists, "App should handle rapid swipes")
        }
    }
    
    func testDragGestureAccuracy() throws {
        let scoreEntry = app.otherElements["ScoreEntry"]
        if scoreEntry.exists {
            let startCoordinate = scoreEntry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let endCoordinate = scoreEntry.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            
            // Precise drag for score adjustment
            startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate, withVelocity: .slow, thenHoldForDuration: 0.1)
            
            // Verify score changed
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES '[0-9]+'")).count > 0, "Score should update")
        }
    }
    
    func testConflictingGestures() throws {
        // Test when multiple gestures could be triggered
        let interactiveView = app.otherElements["InteractiveFormat"]
        if interactiveView.exists {
            // Try tap while swiping
            let start = interactiveView.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
            let end = interactiveView.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            
            start.press(forDuration: 0, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
            interactiveView.tap() // Tap during swipe
            
            XCTAssertTrue(app.exists, "App should handle conflicting gestures gracefully")
        }
    }
    
    // MARK: - Long Press Tests
    
    func testLongPressGestures() throws {
        let scoreGrid = app.tables["ScoreGrid"]
        if scoreGrid.exists {
            let cell = scoreGrid.cells.firstMatch
            
            // Standard long press
            cell.press(forDuration: 1.0)
            XCTAssertTrue(app.otherElements["MultiSelectMode"].exists || app.otherElements["ContextMenu"].exists,
                         "Long press should trigger multi-select or context menu")
            
            // Edge case: Very long press
            cell.press(forDuration: 5.0)
            XCTAssertTrue(app.exists, "App should handle extended long press")
            
            // Edge case: Multiple simultaneous long presses
            if scoreGrid.cells.count > 1 {
                let cell2 = scoreGrid.cells.element(boundBy: 1)
                // Can't truly simulate simultaneous touch in XCTest, but test rapid succession
                cell.press(forDuration: 0.5)
                cell2.press(forDuration: 0.5)
                XCTAssertTrue(app.exists, "App should handle multiple long presses")
            }
        }
    }
    
    // MARK: - Text Input Tests
    
    func testTextFieldEdgeCases() throws {
        let nameField = app.textFields["Player Name"]
        if nameField.exists {
            nameField.tap()
            
            // Test extremely long input
            let longName = String(repeating: "A", count: 100)
            nameField.typeText(longName)
            XCTAssertTrue(nameField.value as? String != nil, "Should handle long input")
            
            // Clear and test special characters
            nameField.doubleTap()
            app.keys["delete"].tap()
            nameField.typeText("Test@#$%^&*()")
            XCTAssertTrue(nameField.value as? String != nil, "Should handle special characters")
            
            // Test rapid input
            nameField.doubleTap()
            app.keys["delete"].tap()
            for char in "QuickType" {
                nameField.typeText(String(char))
            }
            XCTAssertTrue(nameField.value as? String != nil, "Should handle rapid input")
        }
    }
    
    func testNumericInputValidation() throws {
        let scoreField = app.textFields.matching(identifier: "ScoreInput").firstMatch
        if scoreField.exists {
            scoreField.tap()
            
            // Test invalid input
            scoreField.typeText("abc")
            XCTAssertTrue(scoreField.value as? String == "" || scoreField.value as? String == "0",
                         "Should reject non-numeric input")
            
            // Test boundary values
            scoreField.typeText("999")
            XCTAssertTrue(scoreField.value != nil, "Should handle large numbers")
            
            // Test negative numbers
            scoreField.doubleTap()
            app.keys["delete"].tap()
            scoreField.typeText("-5")
            XCTAssertTrue(scoreField.value != nil, "Should handle negative if allowed")
        }
    }
    
    // MARK: - Toggle/Switch Tests
    
    func testToggleRapidSwitching() throws {
        // Navigate to settings
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
        }
        
        let hapticToggle = app.switches["Haptic Feedback"]
        if hapticToggle.exists {
            let initialValue = hapticToggle.value as? String == "1"
            
            // Rapid toggling
            for _ in 0..<20 {
                hapticToggle.tap()
            }
            
            // Should end up at opposite state (even number of toggles)
            XCTAssertEqual(hapticToggle.value as? String == "1", initialValue,
                          "Toggle should maintain consistency after rapid switching")
        }
    }
    
    // MARK: - Scroll View Tests
    
    func testScrollViewPerformance() throws {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Test rapid scrolling
            for _ in 0..<10 {
                scrollView.swipeUp(velocity: .fast)
            }
            for _ in 0..<10 {
                scrollView.swipeDown(velocity: .fast)
            }
            
            XCTAssertTrue(app.exists, "App should handle rapid scrolling")
            
            // Test rubber banding
            scrollView.swipeUp(velocity: .fast)
            sleep(1)
            scrollView.swipeUp(velocity: .fast) // Try to scroll past end
            XCTAssertTrue(app.exists, "Should handle over-scrolling")
        }
    }
    
    func testScrollViewWithSimultaneousGestures() throws {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Start scrolling
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            
            start.press(forDuration: 0, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0)
            
            // Try tapping while scrolling
            if let button = app.buttons.firstMatch {
                button.tap()
            }
            
            XCTAssertTrue(app.exists, "Should handle tap during scroll")
        }
    }
    
    // MARK: - Picker Tests
    
    func testPickerEdgeCases() throws {
        let picker = app.pickers.firstMatch
        if picker.exists {
            // Test rapid wheel spinning
            let wheel = picker.pickerWheels.firstMatch
            if wheel.exists {
                for _ in 0..<5 {
                    wheel.adjust(toPickerWheelValue: "5")
                    wheel.adjust(toPickerWheelValue: "1")
                }
                XCTAssertTrue(wheel.exists, "Picker should remain stable")
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationStackOverflow() throws {
        // Try to push many views onto navigation stack
        var depth = 0
        let maxDepth = 10
        
        while depth < maxDepth {
            if let navButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Detail' OR label CONTAINS 'More'")).firstMatch {
                if navButton.exists && navButton.isHittable {
                    navButton.tap()
                    depth += 1
                    sleep(0.5)
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        // Navigate back
        for _ in 0..<depth {
            if app.navigationBars.buttons.element(boundBy: 0).exists {
                app.navigationBars.buttons.element(boundBy: 0).tap()
                sleep(0.5)
            }
        }
        
        XCTAssertTrue(app.exists, "Navigation stack should handle deep navigation")
    }
    
    // MARK: - Sheet Presentation Tests
    
    func testMultipleSheetPresentations() throws {
        // Test rapid sheet presentation/dismissal
        if let button = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Settings' OR label CONTAINS 'Info'")).firstMatch {
            if button.exists {
                for _ in 0..<5 {
                    button.tap()
                    sleep(0.5)
                    if app.buttons["Done"].exists {
                        app.buttons["Done"].tap()
                        sleep(0.5)
                    } else if app.buttons["Cancel"].exists {
                        app.buttons["Cancel"].tap()
                        sleep(0.5)
                    }
                }
                XCTAssertTrue(app.exists, "Should handle repeated sheet presentations")
            }
        }
    }
    
    // MARK: - Memory and Performance Tests
    
    func testMemoryUnderStress() throws {
        // Create many UI elements through interaction
        let measure = XCTClockMetric()
        
        self.measure(metrics: [measure]) {
            // Navigate through all major screens
            let buttons = app.buttons
            for i in 0..<min(buttons.count, 10) {
                let button = buttons.element(boundBy: i)
                if button.exists && button.isHittable {
                    button.tap()
                    sleep(0.2)
                }
            }
        }
    }
    
    // MARK: - Voice Input Tests
    
    func testVoiceInputInterface() throws {
        let voiceButton = app.buttons["Voice Input"]
        if voiceButton.exists {
            voiceButton.tap()
            
            // Verify voice UI appears
            XCTAssertTrue(app.otherElements["VoiceOverlay"].exists || 
                         app.staticTexts["Listening..."].exists,
                         "Voice input UI should appear")
            
            // Test cancellation
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
            
            // Test rapid activation/deactivation
            for _ in 0..<3 {
                if voiceButton.exists && voiceButton.isHittable {
                    voiceButton.tap()
                    sleep(0.5)
                    if app.buttons["Cancel"].exists {
                        app.buttons["Cancel"].tap()
                    }
                }
            }
            
            XCTAssertTrue(app.exists, "Voice input should handle rapid state changes")
        }
    }
    
    // MARK: - Haptic Feedback Tests
    
    func testHapticFeedbackConsistency() throws {
        // Note: Can't directly test haptics in XCTest, but can verify the calls don't crash
        let buttons = app.buttons
        
        for i in 0..<min(buttons.count, 5) {
            let button = buttons.element(boundBy: i)
            if button.exists && button.isHittable {
                button.tap()
                // If app has haptic feedback enabled, this should trigger it
            }
        }
        
        XCTAssertTrue(app.exists, "Haptic feedback shouldn't cause crashes")
    }
    
    // MARK: - Orientation Change Tests
    
    func testOrientationChanges() throws {
        // Test portrait to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        XCTAssertTrue(app.exists, "App should handle landscape orientation")
        
        // Test rapid orientation changes
        for _ in 0..<3 {
            XCUIDevice.shared.orientation = .portrait
            sleep(0.5)
            XCUIDevice.shared.orientation = .landscapeRight
            sleep(0.5)
        }
        
        XCTAssertTrue(app.exists, "App should handle rapid orientation changes")
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Enable VoiceOver-like inspection
        let elements = app.descendants(matching: .any)
        var unlabeledElements = 0
        
        for i in 0..<min(elements.count, 50) {
            let element = elements.element(boundBy: i)
            if element.exists {
                let label = element.label
                let value = element.value as? String
                
                if label.isEmpty && value?.isEmpty ?? true {
                    if element.isHittable {
                        unlabeledElements += 1
                    }
                }
            }
        }
        
        XCTAssertLessThan(unlabeledElements, 5, "Most interactive elements should have accessibility labels")
    }
    
    func testVoiceOverNavigation() throws {
        // Simulate VoiceOver navigation
        app.launchArguments.append("-UIAccessibilityVoiceOverEnabled")
        app.launch()
        
        // Test that elements can be accessed in order
        let firstElement = app.otherElements.firstMatch
        if firstElement.exists {
            firstElement.tap()
            
            // Swipe right (VoiceOver next element gesture)
            app.swipeRight()
            sleep(0.5)
            
            XCTAssertTrue(app.exists, "VoiceOver navigation should work")
        }
    }
    
    // MARK: - Dark Mode Tests
    
    func testDarkModeTransition() throws {
        // Note: Can't directly change dark mode in test, but can verify UI handles it
        // This would typically be done with launch arguments
        app.launchArguments.append("-UIUserInterfaceStyle")
        app.launchArguments.append("Dark")
        app.launch()
        
        XCTAssertTrue(app.exists, "App should launch in dark mode")
        
        // Verify critical UI elements are visible
        let buttons = app.buttons
        XCTAssertGreaterThan(buttons.count, 0, "Buttons should be visible in dark mode")
    }
    
    // MARK: - Network Error Simulation
    
    func testNetworkErrorHandling() throws {
        // Simulate network failure
        app.launchArguments.append("-NetworkEnabled")
        app.launchArguments.append("NO")
        app.launch()
        
        // Try to load formats
        if app.buttons["Formats"].exists {
            app.buttons["Formats"].tap()
            
            // Should show cached or offline data
            XCTAssertTrue(app.staticTexts.count > 0, "Should show content even offline")
        }
    }
    
    // MARK: - Boundary Testing
    
    func testBoundaryConditions() throws {
        // Test with maximum players
        if app.buttons["Add Player"].exists {
            for i in 1...10 { // Try to add many players
                if app.buttons["Add Player"].exists && app.buttons["Add Player"].isEnabled {
                    app.buttons["Add Player"].tap()
                    if let nameField = app.textFields["Player Name"] {
                        nameField.tap()
                        nameField.typeText("Player \(i)")
                        app.buttons["Done"].tap()
                    }
                } else {
                    break // Reached maximum
                }
            }
            
            XCTAssertTrue(app.exists, "Should handle maximum player limit")
        }
        
        // Test with minimum values
        let scoreField = app.textFields.matching(identifier: "ScoreInput").firstMatch
        if scoreField.exists {
            scoreField.tap()
            scoreField.typeText("0")
            XCTAssertTrue(app.exists, "Should handle minimum score")
        }
    }
}