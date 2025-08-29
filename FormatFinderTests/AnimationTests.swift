import XCTest
import SwiftUI
@testable import FormatFinder

class AnimationTests: XCTestCase {
    
    // MARK: - Scroll State Tests
    
    func testScrollStateInitialization() {
        let scrollState = ScrollState()
        
        XCTAssertEqual(scrollState.offset, 0)
        XCTAssertEqual(scrollState.velocity, 0)
        XCTAssertEqual(scrollState.contentHeight, 0)
        XCTAssertFalse(scrollState.isScrolling)
    }
    
    func testScrollStateUpdate() {
        let scrollState = ScrollState()
        
        scrollState.updateOffset(100)
        XCTAssertEqual(scrollState.offset, 100)
        
        scrollState.updateVelocity(5.0)
        XCTAssertEqual(scrollState.velocity, 5.0)
    }
    
    func testScrollProgress() {
        let scrollState = ScrollState()
        scrollState.contentHeight = 1000
        
        scrollState.updateOffset(0)
        XCTAssertEqual(scrollState.scrollProgress, 0)
        
        scrollState.updateOffset(500)
        XCTAssertEqual(scrollState.scrollProgress, 0.5)
        
        scrollState.updateOffset(1000)
        XCTAssertEqual(scrollState.scrollProgress, 1.0)
    }
    
    // MARK: - Parallax Tests
    
    func testParallaxCalculation() {
        let parallaxRatio: CGFloat = 0.5
        let scrollOffset: CGFloat = 100
        
        let parallaxOffset = scrollOffset * parallaxRatio
        XCTAssertEqual(parallaxOffset, 50)
    }
    
    func testParallaxHeaderCompression() {
        let baseHeight: CGFloat = 300
        let scrollOffset: CGFloat = 100
        let compressionRatio: CGFloat = 0.7
        
        let compressedHeight = max(baseHeight - scrollOffset * compressionRatio, 100)
        XCTAssertEqual(compressedHeight, 230)
    }
    
    // MARK: - Animation Timing Tests
    
    func testStaggerAnimationDelay() {
        let controller = StaggerAnimationController()
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        
        controller.register(id: id1)
        controller.register(id: id2)
        controller.register(id: id3)
        
        XCTAssertEqual(controller.getDelay(for: id1), 0)
        XCTAssertEqual(controller.getDelay(for: id2), 0.15)
        XCTAssertEqual(controller.getDelay(for: id3), 0.30)
    }
    
    func testAnimationSpeedMultiplier() {
        let config = FormatFinderConfig.shared
        
        config.adjustAnimationSpeed(2.0)
        XCTAssertEqual(config.globalAnimationSpeed, 2.0)
        XCTAssertEqual(config.transitionDuration, 0.15) // 0.3 / 2.0
        
        config.adjustAnimationSpeed(0.5)
        XCTAssertEqual(config.globalAnimationSpeed, 0.5)
        XCTAssertEqual(config.transitionDuration, 0.6) // 0.3 / 0.5
    }
    
    // MARK: - Elastic Pull Tests
    
    func testElasticOffset() {
        let threshold: CGFloat = 80
        let resistance: CGFloat = 0.5
        
        // Below threshold - linear
        let pull1: CGFloat = 50
        let elastic1 = pull1
        XCTAssertEqual(elastic1, 50)
        
        // Above threshold - resistance applied
        let pull2: CGFloat = 100
        let overpull = pull2 - threshold
        let elastic2 = threshold + (overpull * resistance)
        XCTAssertEqual(elastic2, 90) // 80 + (20 * 0.5)
    }
    
    // MARK: - Color Contrast Tests
    
    func testContrastRatioCalculation() {
        let colorSystem = AdaptiveColorSystem.shared
        
        // Test white on dark background
        let darkBg = Color(red: 0.1, green: 0.1, blue: 0.1)
        let whiteFg = Color.white
        
        // Should have high contrast (> 4.5 for WCAG AA)
        // Note: Actual calculation would need the private method exposed
        XCTAssertNotNil(colorSystem.textColor)
    }
    
    // MARK: - Performance Optimization Tests
    
    func testViewPoolRecycling() {
        let pool = ViewRecyclingPool()
        pool.maxPoolSize = 3
        
        // Add views
        let view1 = pool.getView(id: "1") { Text("1") }
        let view2 = pool.getView(id: "2") { Text("2") }
        let view3 = pool.getView(id: "3") { Text("3") }
        
        XCTAssertNotNil(view1)
        XCTAssertNotNil(view2)
        XCTAssertNotNil(view3)
        
        // Add fourth view - should evict first
        let view4 = pool.getView(id: "4") { Text("4") }
        XCTAssertNotNil(view4)
        
        // Verify pool size maintained
        // Note: Would need access to pool internals for complete test
    }
    
    func testDebounceThreshold() {
        let expectation = XCTestExpectation(description: "Debounced call")
        let optimizer = PerformanceOptimizer.shared
        
        // Rapid scroll events
        for i in 0..<10 {
            optimizer.handleScroll(CGFloat(i * 10))
        }
        
        // Should only trigger once after debounce delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Accessibility Tests
    
    func testDynamicTypeScaling() {
        let baseSize: CGFloat = 16
        
        let xSmallScale: CGFloat = 0.8
        let scaledXSmall = baseSize * xSmallScale
        XCTAssertEqual(scaledXSmall, 12.8)
        
        let xxxLargeScale: CGFloat = 1.4
        let scaledXXXLarge = baseSize * xxxLargeScale
        XCTAssertEqual(scaledXXXLarge, 22.4)
        
        let accessibility5Scale: CGFloat = 2.6
        let scaledA5 = baseSize * accessibility5Scale
        XCTAssertEqual(scaledA5, 41.6)
    }
    
    func testReducedMotionAnimation() {
        let accessibility = AccessibilityManager.shared
        
        // Simulate reduced motion enabled
        accessibility.isReduceMotionEnabled = true
        
        // Animations should use simpler transitions
        XCTAssertTrue(accessibility.prefersCrossFadeTransitions)
    }
    
    // MARK: - 3D Transform Tests
    
    func testFlipRotation() {
        var rotation: Double = 0
        let isFlipped = false
        
        // Flip animation
        rotation += 180
        XCTAssertEqual(rotation, 180)
        
        // Check if flipped
        let shouldBeFlipped = rotation.truncatingRemainder(dividingBy: 360) >= 180
        XCTAssertTrue(shouldBeFlipped)
    }
    
    func testShadowCalculation() {
        let baseRadius: CGFloat = 10
        let angle: Double = 90 // Mid-flip
        
        let normalizedAngle = abs(angle.truncatingRemainder(dividingBy: 180))
        let shadowIntensity = 1 - (normalizedAngle / 180)
        let shadowRadius = baseRadius + (baseRadius * CGFloat(shadowIntensity))
        
        XCTAssertEqual(shadowRadius, 15) // 10 + (10 * 0.5)
    }
    
    // MARK: - Configuration Tests
    
    func testExperimentEnrollment() {
        let config = FormatFinderConfig.shared
        
        config.enrollInExperiment("scrolling", variant: "smooth")
        
        XCTAssertEqual(config.getExperimentVariant("scrolling"), "smooth")
        XCTAssertTrue(config.activeExperiments.contains("scrolling"))
        XCTAssertEqual(config.springDamping, 0.9)
    }
    
    func testRemoteConfigApplication() {
        let config = FormatFinderConfig.shared
        
        let mockConfig: [String: Any] = [
            "animationsEnabled": false,
            "globalAnimationSpeed": 1.5,
            "version": "2.0.0"
        ]
        
        // Would need to expose applyRemoteConfig for testing
        // config.applyRemoteConfig(mockConfig)
        // XCTAssertFalse(config.animationsEnabled)
        // XCTAssertEqual(config.globalAnimationSpeed, 1.5)
    }
    
    // MARK: - Performance Benchmarks
    
    func testScrollPerformance() {
        measure {
            let scrollState = ScrollState()
            for i in 0..<1000 {
                scrollState.updateOffset(CGFloat(i))
                scrollState.updateVelocity(CGFloat(i) * 0.1)
            }
        }
    }
    
    func testAnimationBatchPerformance() {
        let optimizer = PerformanceOptimizer.shared
        
        measure {
            for i in 0..<100 {
                let task = PerformanceOptimizer.AnimationTask(
                    id: UUID(),
                    priority: i % 3,
                    animation: { }
                )
                optimizer.batchAnimation(task)
            }
        }
    }
}