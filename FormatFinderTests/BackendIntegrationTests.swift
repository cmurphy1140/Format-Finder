import XCTest
import SwiftUI
@testable import FormatFinder

class BackendIntegrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - FormatDataService Tests
    
    func testFormatDataServiceSingleton() {
        let service1 = FormatDataService.shared
        let service2 = FormatDataService.shared
        XCTAssertTrue(service1 === service2, "FormatDataService should be a singleton")
    }
    
    func testLoadFormatsFromStaticData() async {
        let service = FormatDataService.shared
        
        await service.loadFormats()
        
        await MainActor.run {
            XCTAssertFalse(service.formats.isEmpty, "Formats should be loaded")
            XCTAssertGreaterThan(service.formats.count, 0, "Should have at least one format")
        }
    }
    
    func testFormatPropertiesAreValid() async {
        let service = FormatDataService.shared
        await service.loadFormats()
        
        await MainActor.run {
            for format in service.formats {
                XCTAssertFalse(format.name.isEmpty, "Format name should not be empty")
                XCTAssertFalse(format.tagline.isEmpty, "Format tagline should not be empty")
                XCTAssertFalse(format.description.isEmpty, "Format description should not be empty")
                XCTAssertTrue(["Easy", "Medium", "Hard"].contains(format.difficulty), "Difficulty should be valid")
                XCTAssertGreaterThan(format.idealGroupSize.lowerBound, 0, "Group size should be positive")
            }
        }
    }
    
    // MARK: - Backend Services Tests
    
    func testTimeEnvironmentServiceSingleton() {
        let service1 = TimeEnvironmentService.shared
        let service2 = TimeEnvironmentService.shared
        XCTAssertTrue(service1 === service2, "TimeEnvironmentService should be a singleton")
    }
    
    func testAnimationOrchestratorHapticFeedback() {
        let orchestrator = AnimationOrchestrator.shared
        
        // Test that haptic methods don't crash
        orchestrator.triggerHaptic(.light)
        orchestrator.triggerHaptic(.medium)
        orchestrator.triggerHaptic(.heavy)
        
        XCTAssertTrue(true, "Haptic feedback should not crash")
    }
    
    // MARK: - Analytics Service Tests
    
    func testAnalyticsServiceTracking() {
        let analytics = AnalyticsService.shared
        
        // Test event tracking doesn't crash
        analytics.trackEvent(.formatsLoaded, properties: ["count": 10])
        analytics.trackEvent(.formatSelected, properties: ["format": "Scramble"])
        
        // Test error tracking doesn't crash
        let testError = NSError(domain: "TestDomain", code: 404, userInfo: nil)
        analytics.trackError(testError)
        
        XCTAssertTrue(true, "Analytics tracking should not crash")
    }
    
    // MARK: - SwipeableFormatCards Integration Tests
    
    func testFormatCardsViewModelLoadsData() async {
        let viewModel = FormatCardsViewModel()
        
        // Wait a moment for async loading
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await MainActor.run {
            XCTAssertFalse(viewModel.formats.isEmpty, "ViewModel should load formats")
        }
    }
    
    func testFormatCardsCodableConformance() throws {
        let format = EnhancedGolfFormat(
            name: "Test Format",
            tagline: "Test Tagline",
            difficulty: "Easy",
            description: "Test Description",
            quickRules: ["Rule 1"],
            completeRules: ["Complete Rule 1"],
            scoringMethod: "Test Scoring",
            detailedScoring: "Detailed Scoring",
            idealGroupSize: 2...4,
            proTips: ["Tip 1"],
            animationType: .scramble
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(format)
        XCTAssertNotNil(data, "Should encode format")
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedFormat = try decoder.decode(EnhancedGolfFormat.self, from: data)
        XCTAssertEqual(decodedFormat.name, format.name, "Should decode format correctly")
    }
    
    // MARK: - Performance Tests
    
    func testFormatLoadingPerformance() {
        measure {
            let service = FormatDataService.shared
            let expectation = XCTestExpectation(description: "Load formats")
            
            Task {
                await service.loadFormats()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - UI Integration Tests
    
    func testSwipeableFormatCardsViewCreation() {
        let view = SwipeableFormatCards()
        XCTAssertNotNil(view, "SwipeableFormatCards view should be created")
    }
    
    func testFormatComparisonVisualizerCreation() {
        let analytics = [FormatAnalytics.sampleData.first!]
        let view = RadarChart(
            analytics: analytics,
            selectedFormats: ["Scramble"],
            animated: false
        )
        XCTAssertNotNil(view, "RadarChart view should be created")
    }
}

// MARK: - Mock Data for Testing

extension FormatAnalytics {
    static let sampleData: [FormatAnalytics] = [
        FormatAnalytics(
            format: GolfFormat(
                id: "1",
                name: "Scramble",
                description: "Team format",
                difficulty: .easy,
                minPlayers: 2,
                maxPlayers: 4,
                scoringType: .team,
                rules: []
            ),
            skillLevel: 0.3,
            socialAspect: 0.9,
            competitiveness: 0.4,
            paceOfPlay: 0.8,
            strategy: 0.5,
            funFactor: 0.9,
            learning: 0.9,
            popularity: 0.95
        )
    ]
}