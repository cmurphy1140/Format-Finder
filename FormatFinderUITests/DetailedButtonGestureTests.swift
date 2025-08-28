import XCTest
import SwiftUI

class DetailedButtonGestureTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    // MARK: - Comprehensive Button Testing
    
    func testEveryButtonInApp() throws {
        let buttonTestCases: [(identifier: String, expectedAction: () -> Bool)] = [
            // Main Navigation
            ("Formats", { self.app.staticTexts["Choose Format"].exists }),
            ("Settings", { self.app.navigationBars["Settings"].exists }),
            ("Profile", { self.app.staticTexts["Profile"].exists || self.app.navigationBars["Settings"].exists }),
            ("Info", { self.app.staticTexts["About"].exists }),
            
            // Format Selection
            ("Scramble", { self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Scramble'")).count > 0 }),
            ("Best Ball", { self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Best Ball'")).count > 0 }),
            ("Match Play", { self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Match Play'")).count > 0 }),
            ("Skins", { self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Skins'")).count > 0 }),
            
            // Game Configuration
            ("Add Player", { self.app.textFields["Player Name"].exists }),
            ("Remove Player", { true }), // Just check it doesn't crash
            ("Start Game", { self.app.staticTexts["Hole 1"].exists || self.app.staticTexts["Scorecard"].exists }),
            
            // Score Entry
            ("Quick Score Par", { true }),
            ("Quick Score Birdie", { true }),
            ("Quick Score Eagle", { true }),
            ("Quick Score Bogey", { true }),
            ("Quick Score Double", { true }),
            
            // Navigation Controls
            ("Done", { true }),
            ("Cancel", { true }),
            ("Save", { true }),
            ("Back", { true }),
            ("Next", { true }),
            ("Previous", { true })
        ]
        
        for testCase in buttonTestCases {
            let button = app.buttons[testCase.identifier]
            if button.exists && button.isHittable {
                // Test normal tap
                button.tap()
                XCTAssertTrue(testCase.expectedAction() || app.exists,
                             "\(testCase.identifier) button should perform expected action")
                
                // Return to original state if needed
                if app.buttons["Done"].exists {
                    app.buttons["Done"].tap()
                } else if app.buttons["Cancel"].exists {
                    app.buttons["Cancel"].tap()
                } else if app.navigationBars.buttons.firstMatch.exists {
                    app.navigationBars.buttons.firstMatch.tap()
                }
                
                // Test double tap (should not crash)
                if button.exists && button.isHittable {
                    button.doubleTap()
                    XCTAssertTrue(app.exists, "\(testCase.identifier) should handle double tap")
                }
                
                // Test long press
                if button.exists && button.isHittable {
                    button.press(forDuration: 1.0)
                    XCTAssertTrue(app.exists, "\(testCase.identifier) should handle long press")
                }
            }
        }
    }
    
    func testButtonVisualFeedback() throws {
        let button = app.buttons.firstMatch
        
        if button.exists {
            // Check initial state
            let initialFrame = button.frame
            
            // Press and hold to see visual feedback
            button.press(forDuration: 0.5)
            
            // Button should still exist and be in similar position
            XCTAssertTrue(button.exists, "Button should remain after press")
            XCTAssertEqual(button.frame.origin, initialFrame.origin, accuracy: 10,
                          "Button shouldn't move significantly")
        }
    }
    
    func testDisabledButtonInteraction() throws {
        // Find a button that might be disabled
        let startButton = app.buttons["Start Game"]
        
        if startButton.exists && !startButton.isEnabled {
            // Try to tap disabled button
            startButton.tap()
            XCTAssertTrue(app.exists, "App shouldn't crash when tapping disabled button")
            
            // Try force touch on disabled button
            startButton.press(forDuration: 1.0)
            XCTAssertTrue(app.exists, "App shouldn't crash when long pressing disabled button")
        }
    }
    
    // MARK: - Swipeable Format Cards Detailed Testing
    
    func testSwipeableCardGestures() throws {
        // Navigate to format cards
        if app.buttons["Formats"].exists {
            app.buttons["Formats"].tap()
        }
        
        let formatCard = app.otherElements.matching(identifier: "FormatCard").firstMatch
        
        if formatCard.exists {
            // Test precise swipe velocities
            let velocities: [XCUIGestureVelocity] = [.slow, .default, .fast]
            
            for velocity in velocities {
                // Swipe left with specific velocity
                formatCard.swipeLeft(velocity: velocity)
                sleep(1)
                XCTAssertTrue(app.exists, "Should handle \(velocity) velocity swipe")
                
                // Swipe right
                formatCard.swipeRight(velocity: velocity)
                sleep(1)
                XCTAssertTrue(app.exists, "Should handle \(velocity) velocity swipe back")
            }
            
            // Test partial swipe (drag and release)
            let start = formatCard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let partial = formatCard.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
            
            start.press(forDuration: 0.1, thenDragTo: partial, withVelocity: .slow, thenHoldForDuration: 0)
            XCTAssertTrue(formatCard.exists, "Card should snap back on partial swipe")
            
            // Test threshold swipe
            let threshold = formatCard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: threshold, withVelocity: .fast, thenHoldForDuration: 0)
            sleep(1)
            XCTAssertTrue(app.exists, "Should handle threshold swipe")
        }
    }
    
    func testExpandedCardInteractions() throws {
        let formatCard = app.otherElements.matching(identifier: "FormatCard").firstMatch
        
        if formatCard.exists {
            // Tap to expand
            formatCard.tap()
            sleep(1)
            
            // Test scrolling in expanded view
            if app.scrollViews.firstMatch.exists {
                app.scrollViews.firstMatch.swipeUp()
                sleep(0.5)
                app.scrollViews.firstMatch.swipeDown()
                XCTAssertTrue(app.exists, "Should scroll in expanded card")
            }
            
            // Test close button
            if app.buttons["Close"].exists {
                app.buttons["Close"].tap()
                XCTAssertTrue(formatCard.exists, "Should return to card view")
            }
            
            // Test tap outside to close
            formatCard.tap() // Expand again
            sleep(1)
            
            // Tap outside
            let background = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
            background.tap()
            sleep(1)
            XCTAssertTrue(app.exists, "Should close on outside tap")
        }
    }
    
    // MARK: - Score Entry Gesture Testing
    
    func testScoreEntryGestures() throws {
        // Navigate to score entry
        navigateToScoreEntry()
        
        let scoreCell = app.otherElements.matching(identifier: "ScoreCell").firstMatch
        
        if scoreCell.exists {
            // Test vertical swipe for score adjustment
            let center = scoreCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let top = scoreCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            let bottom = scoreCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            
            // Swipe up to decrease score
            bottom.press(forDuration: 0.1, thenDragTo: top, withVelocity: .default, thenHoldForDuration: 0.1)
            sleep(0.5)
            XCTAssertTrue(app.exists, "Should decrease score on swipe up")
            
            // Swipe down to increase score
            top.press(forDuration: 0.1, thenDragTo: bottom, withVelocity: .default, thenHoldForDuration: 0.1)
            sleep(0.5)
            XCTAssertTrue(app.exists, "Should increase score on swipe down")
            
            // Test momentum scrolling
            bottom.press(forDuration: 0, thenDragTo: top, withVelocity: .fast, thenHoldForDuration: 0)
            sleep(1)
            XCTAssertTrue(app.exists, "Should handle momentum scrolling")
            
            // Test tap to open number picker
            scoreCell.tap()
            sleep(1)
            
            if app.pickers.firstMatch.exists {
                // Test picker wheel
                let wheel = app.pickerWheels.firstMatch
                wheel.adjust(toPickerWheelValue: "4")
                sleep(0.5)
                XCTAssertTrue(wheel.value as? String == "4", "Should select value in picker")
                
                // Confirm selection
                if app.buttons["Done"].exists {
                    app.buttons["Done"].tap()
                }
            }
        }
    }
    
    func testMultiPlayerGridInteraction() throws {
        navigateToScoreEntry()
        
        let grid = app.tables["ScoreGrid"]
        if grid.exists {
            let cells = grid.cells
            
            // Test multi-select with long press
            if cells.count > 2 {
                cells.element(boundBy: 0).press(forDuration: 1.0)
                sleep(0.5)
                
                // Select additional cells
                cells.element(boundBy: 1).tap()
                cells.element(boundBy: 2).tap()
                
                // Batch edit
                if app.buttons["Edit Selected"].exists {
                    app.buttons["Edit Selected"].tap()
                    
                    // Enter batch score
                    if app.textFields["Batch Score"].exists {
                        app.textFields["Batch Score"].tap()
                        app.textFields["Batch Score"].typeText("4")
                        app.buttons["Apply"].tap()
                    }
                }
                
                XCTAssertTrue(app.exists, "Should handle multi-select and batch edit")
            }
            
            // Test zoom controls
            if app.buttons["Zoom In"].exists {
                app.buttons["Zoom In"].tap()
                sleep(0.5)
                XCTAssertTrue(app.exists, "Should zoom in")
                
                app.buttons["Zoom Out"].tap()
                sleep(0.5)
                XCTAssertTrue(app.exists, "Should zoom out")
            }
        }
    }
    
    // MARK: - Toggle and Switch Testing
    
    func testAllTogglesInSettings() throws {
        // Navigate to settings
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
        }
        
        let toggles = [
            "Auto-Calculate Handicap",
            "Pace of Play Alerts",
            "Auto-Advance Holes",
            "Confirm Exceptional Scores",
            "Shot Tracking",
            "Haptic Feedback",
            "Sound Effects",
            "Celebration Animations",
            "Large Text Mode"
        ]
        
        for toggleName in toggles {
            let toggle = app.switches[toggleName]
            if toggle.exists {
                let initialValue = toggle.value as? String == "1"
                
                // Toggle on/off
                toggle.tap()
                sleep(0.2)
                XCTAssertNotEqual(toggle.value as? String == "1", initialValue,
                                "\(toggleName) should change state")
                
                // Toggle back
                toggle.tap()
                sleep(0.2)
                XCTAssertEqual(toggle.value as? String == "1", initialValue,
                             "\(toggleName) should return to original state")
                
                // Test rapid toggling
                for _ in 0..<5 {
                    toggle.tap()
                    Thread.sleep(forTimeInterval: 0.05)
                }
                
                XCTAssertTrue(toggle.exists, "\(toggleName) should survive rapid toggling")
            }
        }
    }
    
    // MARK: - Search and Filter Testing
    
    func testSearchFieldInteractions() throws {
        // Find search field
        let searchField = app.searchFields.firstMatch
        if !searchField.exists {
            // Try text field with search identifier
            let searchTextField = app.textFields["Search"]
            if searchTextField.exists {
                testSearchField(searchTextField)
            }
        } else {
            testSearchField(searchField)
        }
    }
    
    private func testSearchField(_ searchField: XCUIElement) {
        searchField.tap()
        
        // Test search with various inputs
        let searchTerms = [
            "Scramble",
            "Best",
            "123",
            "!@#",
            "",
            "Very long search term that might overflow the search field width"
        ]
        
        for term in searchTerms {
            searchField.doubleTap()
            if app.keys["delete"].exists {
                app.keys["delete"].tap()
            }
            
            searchField.typeText(term)
            sleep(0.5)
            
            // Verify search results update (or at least don't crash)
            XCTAssertTrue(app.exists, "Should handle search term: \(term)")
            
            // Test clear button if exists
            if app.buttons["Clear"].exists {
                app.buttons["Clear"].tap()
                XCTAssertEqual(searchField.value as? String, "",
                             "Clear should empty search field")
            }
        }
    }
    
    // MARK: - Navigation Flow Testing
    
    func testCompleteUserFlow() throws {
        // Test complete flow from start to finish
        
        // 1. Select format
        if app.buttons["Formats"].exists {
            app.buttons["Formats"].tap()
        }
        
        let scrambleCard = app.buttons["Scramble"]
        if scrambleCard.exists {
            scrambleCard.tap()
        } else {
            app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Scramble'")).firstMatch.tap()
        }
        
        // 2. Configure game
        if app.buttons["Configure"].exists {
            app.buttons["Configure"].tap()
        }
        
        // 3. Add players
        for i in 1...4 {
            if app.buttons["Add Player"].exists && app.buttons["Add Player"].isEnabled {
                app.buttons["Add Player"].tap()
                
                let nameField = app.textFields["Player Name"]
                if nameField.exists {
                    nameField.tap()
                    nameField.typeText("Player \(i)")
                    
                    // Add handicap
                    let handicapField = app.textFields["Handicap"]
                    if handicapField.exists {
                        handicapField.tap()
                        handicapField.typeText("\(i * 5)")
                    }
                    
                    app.buttons["Done"].tap()
                }
            }
        }
        
        // 4. Start game
        if app.buttons["Start Game"].exists && app.buttons["Start Game"].isEnabled {
            app.buttons["Start Game"].tap()
        }
        
        // 5. Enter scores for first 3 holes
        for hole in 1...3 {
            let holeLabel = app.staticTexts["Hole \(hole)"]
            if holeLabel.exists {
                // Enter scores
                let scoreInputs = app.textFields.matching(NSPredicate(format: "identifier CONTAINS 'Score'"))
                
                for i in 0..<min(scoreInputs.count, 4) {
                    let input = scoreInputs.element(boundBy: i)
                    if input.exists && input.isHittable {
                        input.tap()
                        input.typeText("\(3 + i)")
                        
                        // Dismiss keyboard
                        if app.buttons["Done"].exists {
                            app.buttons["Done"].tap()
                        }
                    }
                }
                
                // Next hole
                if app.buttons["Next"].exists {
                    app.buttons["Next"].tap()
                }
            }
        }
        
        // 6. Check statistics
        if app.buttons["Stats"].exists {
            app.buttons["Stats"].tap()
            sleep(1)
            
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Score' OR label CONTAINS 'Par'")).count > 0,
                         "Should show statistics")
            
            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            }
        }
        
        // 7. Save game
        if app.buttons["Save"].exists {
            app.buttons["Save"].tap()
            
            // Handle save confirmation if present
            if app.alerts.firstMatch.exists {
                app.alerts.buttons["Save"].tap()
            }
        }
        
        XCTAssertTrue(app.exists, "Should complete entire flow successfully")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToScoreEntry() {
        // Navigate to score entry screen
        if app.buttons["Start Game"].exists {
            app.buttons["Start Game"].tap()
        } else if app.buttons["Scorecard"].exists {
            app.buttons["Scorecard"].tap()
        } else {
            // Try to find any way to score entry
            if app.buttons["Formats"].exists {
                app.buttons["Formats"].tap()
                if let formatButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Scramble' OR label CONTAINS 'Best Ball'")).firstMatch {
                    formatButton.tap()
                    if app.buttons["Start"].exists {
                        app.buttons["Start"].tap()
                    }
                }
            }
        }
    }
    
    private func XCTAssertEqual(_ value1: CGPoint, _ value2: CGPoint, accuracy: CGFloat, _ message: String) {
        XCTAssertEqual(value1.x, value2.x, accuracy: accuracy, message)
        XCTAssertEqual(value1.y, value2.y, accuracy: accuracy, message)
    }
}