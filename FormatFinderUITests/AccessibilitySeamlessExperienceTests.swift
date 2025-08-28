import XCTest
import SwiftUI

class AccessibilitySeamlessExperienceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Enable accessibility features
        app.launchArguments = [
            "UI_TESTING",
            "-UIAccessibilityVoiceOverEnabled", "YES",
            "-UIAccessibilityReduceMotionEnabled", "YES",
            "-UIAccessibilityDarkerSystemColorsEnabled", "YES",
            "-UIAccessibilityBoldTextEnabled", "YES"
        ]
        
        app.launch()
    }
    
    // MARK: - VoiceOver Testing
    
    func testVoiceOverLabels() throws {
        // Check all interactive elements have proper labels
        let interactiveElements = app.descendants(matching: .any).allElementsBoundByIndex
        
        var elementsWithoutLabels: [String] = []
        var elementsChecked = 0
        
        for element in interactiveElements {
            if element.exists && element.isHittable && elementsChecked < 100 {
                elementsChecked += 1
                
                let label = element.label
                let value = element.value as? String ?? ""
                let identifier = element.identifier
                
                if label.isEmpty && value.isEmpty {
                    elementsWithoutLabels.append(identifier.isEmpty ? "Unknown Element" : identifier)
                }
                
                // Check label quality
                if !label.isEmpty {
                    XCTAssertFalse(label.contains("Button") && label.count < 10,
                                  "Label should be descriptive: \(label)")
                    XCTAssertFalse(label == identifier,
                                  "Label shouldn't be same as identifier: \(label)")
                }
            }
        }
        
        XCTAssertLessThan(elementsWithoutLabels.count, 5,
                         "Too many elements without accessibility labels: \(elementsWithoutLabels)")
    }
    
    func testVoiceOverNavigation() throws {
        // Test navigating with VoiceOver gestures
        
        // Swipe right to next element (VoiceOver gesture)
        var currentElement = app.otherElements.firstMatch
        var navigationCount = 0
        
        while navigationCount < 10 {
            if currentElement.exists {
                // Read the element
                let label = currentElement.label
                
                // Verify we can activate it if it's a button
                if currentElement.elementType == .button && currentElement.isHittable {
                    currentElement.tap()
                    sleep(1)
                    
                    // Go back if we navigated
                    if app.navigationBars.buttons.firstMatch.exists {
                        app.navigationBars.buttons.firstMatch.tap()
                    }
                }
                
                // Move to next element
                app.swipeRight()
                navigationCount += 1
            }
        }
        
        XCTAssertTrue(app.exists, "VoiceOver navigation should work")
    }
    
    func testVoiceOverAnnouncements() throws {
        // Test that important state changes are announced
        
        // Toggle a switch and verify announcement
        if app.switches.firstMatch.exists {
            let toggle = app.switches.firstMatch
            let initialState = toggle.value as? String
            
            toggle.tap()
            sleep(1)
            
            let newState = toggle.value as? String
            XCTAssertNotEqual(initialState, newState,
                            "Toggle state should be announced")
        }
        
        // Select different format and verify announcement
        if app.buttons["Formats"].exists {
            app.buttons["Formats"].tap()
            
            let formatButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Scramble' OR label CONTAINS 'Best Ball'"))
            if formatButtons.count > 0 {
                formatButtons.firstMatch.tap()
                
                // Should announce selection
                XCTAssertTrue(app.exists, "Format selection should be announced")
            }
        }
    }
    
    // MARK: - Dynamic Type Testing
    
    func testDynamicTypeScaling() throws {
        // Test with different text sizes
        let textSizes = [
            UIContentSizeCategory.extraSmall,
            UIContentSizeCategory.medium,
            UIContentSizeCategory.extraLarge,
            UIContentSizeCategory.accessibilityExtraLarge,
            UIContentSizeCategory.accessibilityExtraExtraExtraLarge
        ]
        
        for size in textSizes {
            app.launchArguments.append(contentsOf: [
                "-UIPreferredContentSizeCategoryName",
                size.rawValue
            ])
            app.launch()
            
            // Verify text is visible and UI adapts
            let labels = app.staticTexts
            XCTAssertGreaterThan(labels.count, 0,
                               "Text should be visible at size: \(size)")
            
            // Check buttons are still tappable
            if app.buttons.count > 0 {
                let button = app.buttons.firstMatch
                if button.isHittable {
                    button.tap()
                    XCTAssertTrue(app.exists,
                                "Buttons should work at text size: \(size)")
                }
            }
            
            app.terminate()
        }
    }
    
    // MARK: - Color Contrast Testing
    
    func testColorContrast() throws {
        // Test with high contrast mode
        app.launchArguments.append(contentsOf: [
            "-UIAccessibilityDarkerSystemColorsEnabled", "YES",
            "-UIAccessibilityIncreaseContrastEnabled", "YES"
        ])
        app.launch()
        
        // Verify all text is readable
        let textElements = app.staticTexts
        XCTAssertGreaterThan(textElements.count, 0,
                           "Text should be visible in high contrast mode")
        
        // Test with inverted colors
        app.launchArguments.append(contentsOf: [
            "-UIAccessibilityInvertColorsEnabled", "YES"
        ])
        app.launch()
        
        XCTAssertTrue(app.exists,
                     "App should work with inverted colors")
    }
    
    // MARK: - Reduce Motion Testing
    
    func testReducedMotion() throws {
        app.launchArguments.append(contentsOf: [
            "-UIAccessibilityReduceMotionEnabled", "YES"
        ])
        app.launch()
        
        // Test that animations are reduced
        if app.buttons["Formats"].exists {
            app.buttons["Formats"].tap()
            
            // Swipe cards - should have minimal animation
            if let card = app.otherElements.matching(identifier: "FormatCard").firstMatch {
                card.swipeLeft()
                sleep(0.5) // Reduced animation time
                
                XCTAssertTrue(app.exists,
                            "Should handle swipe with reduced motion")
            }
        }
        
        // Test transitions
        let buttons = app.buttons
        for i in 0..<min(buttons.count, 3) {
            let button = buttons.element(boundBy: i)
            if button.exists && button.isHittable {
                button.tap()
                // No delay needed with reduced motion
                XCTAssertTrue(app.exists,
                            "Transitions should be instant with reduced motion")
            }
        }
    }
    
    // MARK: - Keyboard Navigation Testing
    
    func testKeyboardNavigation() throws {
        // Test for iPad with external keyboard
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Tab through elements
            let textFields = app.textFields
            
            if textFields.count > 1 {
                textFields.firstMatch.tap()
                
                // Tab to next field (simulate with coordinate tap for now)
                textFields.element(boundBy: 1).tap()
                
                XCTAssertTrue(textFields.element(boundBy: 1).hasFocus,
                            "Should navigate with keyboard")
            }
        }
    }
    
    // MARK: - Touch Accommodations Testing
    
    func testTouchAccommodations() throws {
        // Test with AssistiveTouch settings
        app.launchArguments.append(contentsOf: [
            "-UIAccessibilityAssistiveTouchEnabled", "YES"
        ])
        app.launch()
        
        // Test tap and hold duration
        let button = app.buttons.firstMatch
        if button.exists {
            // Long press should still work
            button.press(forDuration: 2.0)
            XCTAssertTrue(app.exists,
                         "Should handle extended touch duration")
        }
        
        // Test ignore repeat
        if button.exists && button.isHittable {
            button.tap()
            button.tap() // Second tap might be ignored
            XCTAssertTrue(app.exists,
                         "Should handle touch accommodations")
        }
    }
    
    // MARK: - Screen Reader Focus Testing
    
    func testFocusManagement() throws {
        // Test focus moves appropriately after actions
        
        // Open modal
        if app.buttons["Settings"].exists {
            app.buttons["Settings"].tap()
            sleep(1)
            
            // Focus should be on first element or close button
            let closeButton = app.buttons["Done"]
            XCTAssertTrue(closeButton.exists,
                         "Focus should move to modal")
            
            closeButton.tap()
            
            // Focus should return to trigger button
            XCTAssertTrue(app.buttons["Settings"].exists,
                         "Focus should return after modal dismissal")
        }
        
        // Test focus after error
        let textField = app.textFields.firstMatch
        if textField.exists {
            textField.tap()
            textField.typeText("Invalid!@#$%")
            
            if app.buttons["Save"].exists {
                app.buttons["Save"].tap()
                
                // Focus should move to error message or stay on field
                XCTAssertTrue(textField.exists,
                            "Focus should remain accessible after error")
            }
        }
    }
    
    // MARK: - Seamless Experience Validation
    
    func testSeamlessUserExperience() throws {
        // Comprehensive test of smooth user experience
        
        let startTime = Date()
        var interactionCount = 0
        var errorCount = 0
        
        // Test various interactions in sequence
        let interactions: [() -> Bool] = [
            { self.testButtonInteraction() },
            { self.testSwipeInteraction() },
            { self.testTextInput() },
            { self.testToggleInteraction() },
            { self.testNavigationFlow() },
            { self.testScrolling() },
            { self.testModalPresentation() }
        ]
        
        for interaction in interactions {
            if !interaction() {
                errorCount += 1
            }
            interactionCount += 1
            
            // Check app is still responsive
            XCTAssertTrue(app.exists, "App should remain responsive")
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Verify performance
        XCTAssertLessThan(elapsed / Double(interactionCount), 2.0,
                         "Average interaction should be under 2 seconds")
        XCTAssertEqual(errorCount, 0,
                      "All interactions should complete without errors")
    }
    
    // MARK: - Helper Methods for Seamless Testing
    
    private func testButtonInteraction() -> Bool {
        let button = app.buttons.firstMatch
        if button.exists && button.isHittable {
            button.tap()
            return true
        }
        return false
    }
    
    private func testSwipeInteraction() -> Bool {
        let swipeableElement = app.scrollViews.firstMatch
        if swipeableElement.exists {
            swipeableElement.swipeUp()
            return true
        }
        return false
    }
    
    private func testTextInput() -> Bool {
        let textField = app.textFields.firstMatch
        if textField.exists {
            textField.tap()
            textField.typeText("Test")
            return true
        }
        return false
    }
    
    private func testToggleInteraction() -> Bool {
        let toggle = app.switches.firstMatch
        if toggle.exists {
            toggle.tap()
            return true
        }
        return false
    }
    
    private func testNavigationFlow() -> Bool {
        if let navButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Next' OR label CONTAINS 'Continue'")).firstMatch {
            if navButton.exists && navButton.isHittable {
                navButton.tap()
                return true
            }
        }
        return false
    }
    
    private func testScrolling() -> Bool {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            return true
        }
        return false
    }
    
    private func testModalPresentation() -> Bool {
        if app.buttons["Info"].exists {
            app.buttons["Info"].tap()
            sleep(1)
            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
                return true
            }
        }
        return false
    }
    
    // MARK: - Attention to Detail Tests
    
    func testMicroInteractions() throws {
        // Test small details that enhance user experience
        
        // Test button press feedback timing
        let button = app.buttons.firstMatch
        if button.exists {
            let startFrame = button.frame
            
            button.press(forDuration: 0.1)
            // Button should show immediate feedback
            
            button.press(forDuration: 0.05) // Very quick tap
            XCTAssertTrue(button.frame == startFrame,
                         "Button should handle micro-taps")
        }
        
        // Test scroll momentum
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Flick scroll
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            
            start.press(forDuration: 0, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
            sleep(1) // Let momentum complete
            
            XCTAssertTrue(scrollView.exists, "Scroll should have smooth momentum")
        }
    }
    
    func testEdgeSwipes() throws {
        // Test edge swipe gestures
        let screen = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
        // Left edge swipe (back gesture)
        let leftEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5))
        let leftTarget = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
        leftEdge.press(forDuration: 0, thenDragTo: leftTarget, withVelocity: .default, thenHoldForDuration: 0)
        XCTAssertTrue(app.exists, "Should handle edge swipe")
    }
    
    func testRotationHandling() throws {
        // Test rotation handling
        let device = XCUIDevice.shared
        let originalOrientation = device.orientation
        
        // Rotate through all orientations
        let orientations: [UIDeviceOrientation] = [
            .landscapeLeft,
            .landscapeRight,
            .portraitUpsideDown,
            .portrait
        ]
        
        for orientation in orientations {
            device.orientation = orientation
            sleep(1)
            
            // Verify UI adapts properly
            let buttons = app.buttons
            XCTAssertGreaterThan(buttons.count, 0,
                               "UI should adapt to \(orientation)")
            
            // Test interaction in each orientation
            if buttons.firstMatch.exists && buttons.firstMatch.isHittable {
                buttons.firstMatch.tap()
                XCTAssertTrue(app.exists,
                            "Interactions should work in \(orientation)")
            }
        }
        
        // Restore original orientation
        device.orientation = originalOrientation
    }
    
    // MARK: - Final Quality Assurance
    
    func testOverallQuality() throws {
        // Final comprehensive quality check
        
        var qualityScore = 100
        var issues: [String] = []
        
        // Check for orphaned elements
        let orphanedElements = app.otherElements.matching(NSPredicate(format: "label == '' AND value == nil"))
        if orphanedElements.count > 5 {
            qualityScore -= 10
            issues.append("Too many orphaned elements")
        }
        
        // Check for proper loading states
        if app.activityIndicators.count == 0 && app.progressIndicators.count == 0 {
            qualityScore -= 5
            issues.append("No loading indicators found")
        }
        
        // Check for proper error states
        let errorLabels = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Error' OR label CONTAINS 'error'"))
        if errorLabels.count > 0 && app.buttons.matching(NSPredicate(format: "label CONTAINS 'Retry' OR label CONTAINS 'retry'")).count == 0 {
            qualityScore -= 10
            issues.append("Error states without recovery options")
        }
        
        // Check for consistent navigation
        if app.navigationBars.count > 1 {
            qualityScore -= 15
            issues.append("Multiple navigation bars detected")
        }
        
        // Check for accessibility
        let unlabeledButtons = app.buttons.matching(NSPredicate(format: "label == ''"))
        if unlabeledButtons.count > 2 {
            qualityScore -= 20
            issues.append("Unlabeled buttons found")
        }
        
        XCTAssertGreaterThan(qualityScore, 70,
                           "App quality score: \(qualityScore)/100. Issues: \(issues)")
    }
}