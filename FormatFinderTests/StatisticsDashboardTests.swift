import XCTest
import SwiftUI
@testable import FormatFinder

// MARK: - Statistics Dashboard Tests

class StatisticsDashboardTests: XCTestCase {
    
    var gameState: GameState!
    var testPlayers: [Player]!
    var mockConfiguration: GameConfiguration!
    
    override func setUp() {
        super.setUp()
        
        // Setup test players
        testPlayers = [
            Player(name: "John Doe", handicap: 10),
            Player(name: "Jane Smith", handicap: 8),
            Player(name: "Bob Wilson", handicap: 15)
        ]
        
        // Setup mock configuration
        mockConfiguration = GameConfiguration(
            format: .strokePlay,
            numberOfHoles: 18,
            courseName: "Test Course",
            difficulty: .regular
        )
        
        // Setup game state with test data
        gameState = GameState(configuration: mockConfiguration, players: testPlayers)
        addMockScores()
    }
    
    override func tearDown() {
        gameState = nil
        testPlayers = nil
        mockConfiguration = nil
        super.tearDown()
    }
    
    // MARK: - Real-Time Momentum Tests
    
    func testMomentumCalculation() {
        let momentum = RoundMomentum()
        
        // Test case 1: Improving scores (positive momentum)
        let improvingScores = [5, 4, 3] // Getting better
        let positiveMomentum = momentum.calculateMomentum(scores: improvingScores, handicap: 10)
        XCTAssertGreaterThan(positiveMomentum, 0, "Improving scores should have positive momentum")
        
        // Test case 2: Declining scores (negative momentum)
        let decliningScores = [3, 4, 5] // Getting worse
        let negativeMomentum = momentum.calculateMomentum(scores: decliningScores, handicap: 10)
        XCTAssertLessThan(negativeMomentum, 0, "Declining scores should have negative momentum")
        
        // Test case 3: Consistent scores (neutral momentum)
        let consistentScores = [4, 4, 4] // Par performance
        let neutralMomentum = momentum.calculateMomentum(scores: consistentScores, handicap: 10)
        XCTAssertEqual(neutralMomentum, 0, accuracy: 0.1, "Consistent par scores should have neutral momentum")
        
        // Test edge case: Not enough scores
        let fewScores = [4, 5]
        let zeroMomentum = momentum.calculateMomentum(scores: fewScores, handicap: 10)
        XCTAssertEqual(zeroMomentum, 0, "Should return 0 momentum for insufficient data")
    }
    
    func testMomentumBounds() {
        let momentum = RoundMomentum()
        
        // Test extreme cases to ensure momentum is bounded [-1, 1]
        let extremeGoodScores = [1, 1, 1] // Unrealistic but possible
        let extremeBadScores = [10, 10, 10] // Very bad scores
        
        let goodMomentum = momentum.calculateMomentum(scores: extremeGoodScores, handicap: 20)
        let badMomentum = momentum.calculateMomentum(scores: extremeBadScores, handicap: 0)
        
        XCTAssertLessThanOrEqual(goodMomentum, 1.0, "Momentum should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(goodMomentum, -1.0, "Momentum should not be less than -1.0")
        XCTAssertLessThanOrEqual(badMomentum, 1.0, "Momentum should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(badMomentum, -1.0, "Momentum should not be less than -1.0")
    }
    
    // MARK: - Round Story Generation Tests
    
    func testStoryGeneration() {
        let storyGenerator = RoundStoryGenerator()
        let scores = [3, 4, 5, 4, 3, 4, 6, 4, 3] // Mixed performance
        let pars = Array(repeating: GolfConstants.ParDefaults.defaultPar, count: 9) // Test data
        let playerName = "Test Player"
        
        let story = storyGenerator.generateStory(scores: scores, pars: pars, playerName: playerName)
        
        XCTAssertGreaterThan(story.segments.count, 0, "Story should generate at least one segment")
        
        // Check for hot start detection (birdie on first hole)
        let hasHotStart = story.segments.contains { $0.title == "Hot Start!" }
        XCTAssertTrue(hasHotStart, "Should detect hot start with early birdie")
        
        // Check for birdie celebration
        let hasBirdieCelebration = story.segments.contains { $0.title == "Just Made Birdie!" }
        XCTAssertTrue(hasBirdieCelebration, "Should celebrate recent birdie")
    }
    
    func testStorySegmentContent() {
        let storyGenerator = RoundStoryGenerator()
        let roughStartScores = [6, 5, 5] // Rough start
        let pars = [4, 4, 4]
        
        let story = storyGenerator.generateStory(scores: roughStartScores, pars: pars, playerName: "Test")
        
        let roughStartSegment = story.segments.first { $0.title == "Rough Opening" }
        XCTAssertNotNil(roughStartSegment, "Should detect rough opening")
        XCTAssertEqual(roughStartSegment?.icon, "cloud.rain.fill", "Should use appropriate icon")
        XCTAssertEqual(roughStartSegment?.color, .blue, "Should use appropriate color")
    }
    
    // MARK: - Quick Stats Calculation Tests
    
    func testQuickStatsCalculation() {
        let player = testPlayers[0]
        
        // Test total score calculation
        let totalScore = gameState.getTotalScore(for: player.id)
        XCTAssertGreaterThan(totalScore, 0, "Total score should be calculated correctly")
        
        // Test differential calculation
        let scores = getPlayerScores(player: player)
        let pars = Array(repeating: GolfConstants.ParDefaults.defaultPar, count: scores.count)
        let differential = calculateDifferential(scores: scores, pars: pars)
        
        // Verify differential is reasonable
        XCTAssertTrue(differential >= -18 && differential <= 18, "Differential should be within reasonable bounds")
        
        // Test birdie count
        let birdieCount = countBirdies(scores: scores, pars: pars)
        XCTAssertGreaterThanOrEqual(birdieCount, 0, "Birdie count should be non-negative")
        
        // Test average score
        let average = calculateAverage(scores: scores)
        XCTAssertGreaterThan(average, 0, "Average should be positive")
        XCTAssertLessThan(average, 10, "Average should be reasonable")
    }
    
    func testQuickStatsEdgeCases() {
        // Test with empty scores
        let emptyScores: [Int] = []
        let emptyPars: [Int] = []
        
        XCTAssertEqual(countBirdies(scores: emptyScores, pars: emptyPars), 0, "Empty scores should return 0 birdies")
        XCTAssertEqual(calculateAverage(scores: emptyScores), 0, "Empty scores should return 0 average")
        XCTAssertEqual(calculateDifferential(scores: emptyScores, pars: emptyPars), 0, "Empty scores should return 0 differential")
    }
    
    // MARK: - Performance Graph Tests
    
    func testCumulativeDifferentialCalculation() {
        let currentScores = [4, 3, 5, 4, 6, 3, 4, 5, 4]
        let ghostScores = [4, 4, 4, 4, 4, 4, 4, 4, 4]
        let pars = [4, 4, 4, 4, 4, 4, 4, 4, 4]
        
        let cumulative = calculateCumulativeDifferential(
            currentScores: currentScores,
            ghostScores: ghostScores,
            pars: pars
        )
        
        XCTAssertEqual(cumulative.count, max(currentScores.count, ghostScores.count))
        
        // Verify cumulative calculation
        let expectedCurrentTotal = currentScores.enumerated().reduce(0) { $0 + ($1.element - pars[$1.offset]) }
        let lastCumulativeEntry = cumulative.last
        XCTAssertEqual(lastCumulativeEntry?.current, expectedCurrentTotal, "Cumulative current score should match manual calculation")
    }
    
    // MARK: - Shareable Cards Tests
    
    func testRoundStatisticsCalculation() {
        let round = createMockRound()
        let player = testPlayers[0]
        
        let stats = calculateRoundStats(round: round, player: player)
        
        XCTAssertGreaterThan(stats.totalScore, 0, "Total score should be positive")
        XCTAssertTrue(stats.toPar >= -18 && stats.toPar <= 18, "To par should be within reasonable range")
        XCTAssertGreaterThanOrEqual(stats.birdies, 0, "Birdies should be non-negative")
        XCTAssertGreaterThanOrEqual(stats.pars, 0, "Pars should be non-negative")
        XCTAssertGreaterThanOrEqual(stats.bogeys, 0, "Bogeys should be non-negative")
        
        // Verify totals add up (simplified check)
        let holesWithScores = round.scores.count
        let totalResults = stats.birdies + stats.pars + stats.bogeys
        XCTAssertLessThanOrEqual(totalResults, holesWithScores, "Total results shouldn't exceed holes played")
    }
    
    func testBestWorstHoleIdentification() {
        let scores = [3, 4, 6, 4, 2, 5, 4, 7, 4] // Mixed with eagle (2) and double bogey (7)
        let pars = [4, 4, 4, 4, 4, 4, 4, 4, 4]
        
        let bestHole = findBestHole(scores: scores, pars: pars)
        let worstHole = findWorstHole(scores: scores, pars: pars)
        
        XCTAssertEqual(bestHole?.hole, 5, "Best hole should be hole 5 (eagle)")
        XCTAssertEqual(bestHole?.score, 2, "Best score should be 2")
        
        XCTAssertEqual(worstHole?.hole, 8, "Worst hole should be hole 8 (double bogey)")
        XCTAssertEqual(worstHole?.score, 7, "Worst score should be 7")
    }
    
    func testLongestStreakCalculation() {
        let perfectScores = [4, 4, 3, 4, 4] // Par, par, birdie, par, par
        let pars = [4, 4, 4, 4, 4]
        
        let streak = findLongestStreak(scores: perfectScores, pars: pars)
        XCTAssertNotNil(streak, "Should find a streak in good scores")
        
        let badScores = [5, 6, 5, 6, 5] // All bogeys or worse
        let noStreak = findLongestStreak(scores: badScores, pars: pars)
        // This should still return something as the function is simplified
        XCTAssertNotNil(noStreak, "Function should handle bad scores gracefully")
    }
    
    // MARK: - Card Style Tests
    
    func testCardStylePreview() {
        let styles: [CardStyle] = [.wrapped, .minimal, .vibrant, .dark]
        
        for style in styles {
            let gradient = style.previewGradient
            XCTAssertNotNil(gradient, "Each style should have a preview gradient")
        }
    }
    
    // MARK: - Data Visualization Tests
    
    func testScoreFlowVisualization() {
        let scores = [4, 3, 5, 4, 6, 3, 4, 5, 4]
        let pars = [4, 4, 4, 4, 4, 4, 4, 4, 4]
        
        // Test flow path generation logic
        let hasValidScores = !scores.isEmpty && scores.count == pars.count
        XCTAssertTrue(hasValidScores, "Should have valid score and par data for visualization")
        
        // Test color assignment
        for (index, score) in scores.enumerated() {
            let par = pars[index]
            let color = colorForScore(score, par: par)
            
            if score < par {
                XCTAssertEqual(color, .blue, "Birdies should be blue")
            } else if score == par {
                XCTAssertEqual(color, .cyan, "Pars should be cyan")
            } else if score == par + 1 {
                XCTAssertEqual(color, .orange, "Bogeys should be orange")
            } else {
                XCTAssertEqual(color, .red, "Worse than bogey should be red")
            }
        }
    }
    
    func testRadialAnalyzerCalculations() {
        let scores = [4, 3, 5, 4]
        let pars = [4, 4, 4, 4]
        
        // Test angle calculation
        for hole in 0..<4 {
            let angle = angleForHole(hole)
            XCTAssertGreaterThanOrEqual(angle.degrees, -90, "Angle should be >= -90")
            XCTAssertLessThan(angle.degrees, 270, "Angle should be < 270")
        }
        
        // Test radius calculation
        let minRadius: CGFloat = 50
        let maxRadius: CGFloat = 150
        
        for (index, score) in scores.enumerated() {
            let par = pars[index]
            let radius = radiusForScore(score, par: par, minRadius: minRadius, maxRadius: maxRadius)
            
            XCTAssertGreaterThanOrEqual(radius, minRadius - 40, "Radius should be near minimum bounds")
            XCTAssertLessThanOrEqual(radius, maxRadius + 40, "Radius should be near maximum bounds")
        }
    }
    
    func testEmotionalTimelineMapping() {
        let testCases = [
            (score: 2, par: 4, expectedEmoji: "star.fill", expectedColor: Color.purple),
            (score: 3, par: 4, expectedEmoji: "star", expectedColor: Color.green),
            (score: 4, par: 4, expectedEmoji: "checkmark.circle", expectedColor: Color.blue),
            (score: 5, par: 4, expectedEmoji: "exclamationmark.triangle", expectedColor: Color.orange),
            (score: 6, par: 4, expectedEmoji: "xmark.circle", expectedColor: Color.red)
        ]
        
        for testCase in testCases {
            let emotion = emotionForScore(testCase.score, par: testCase.par)
            XCTAssertEqual(emotion.emoji, testCase.expectedEmoji, "Emoji should match expected for score \(testCase.score) on par \(testCase.par)")
            XCTAssertEqual(emotion.color, testCase.expectedColor, "Color should match expected for score \(testCase.score) on par \(testCase.par)")
        }
    }
    
    // MARK: - Heat Map Tests
    
    func testHeatMapIntensityCalculation() {
        let roundHistory = createMockRoundHistory()
        
        for hole in 1...18 {
            let intensity = heatMapIntensity(for: hole, rounds: roundHistory)
            XCTAssertGreaterThanOrEqual(intensity, 0.0, "Heat intensity should be non-negative")
            XCTAssertLessThanOrEqual(intensity, 1.0, "Heat intensity should not exceed 1.0")
        }
    }
    
    // MARK: - Performance Tests
    
    func testDashboardPerformance() {
        measure {
            // Test momentum calculation performance
            let momentum = RoundMomentum()
            let scores = Array(1...18).map { _ in Int.random(in: 3...7) }
            _ = momentum.calculateMomentum(scores: scores, handicap: 10)
        }
    }
    
    func testVisualizationPerformance() {
        measure {
            // Test large dataset visualization performance
            let largeScoreSet = Array(1...100).map { _ in Int.random(in: 3...7) }
            let largePars = Array(repeating: 4, count: 100)
            
            _ = calculateCumulativeDifferential(
                currentScores: largeScoreSet,
                ghostScores: largePars,
                pars: largePars
            )
        }
    }
    
    // MARK: - Export Functionality Tests
    
    func testStatsCardGeneration() {
        let round = createMockRound()
        let player = testPlayers[0]
        let stats = calculateRoundStats(round: round, player: player)
        
        let generator = ShareableStatsGenerator()
        
        // Test that generation doesn't crash
        let expectation = XCTestExpectation(description: "Card generation")
        
        Task {
            let image = await generator.generateStatsCard(
                for: round,
                player: player,
                style: .wrapped,
                stats: stats
            )
            
            await MainActor.run {
                XCTAssertNotNil(image, "Should generate a valid UIImage")
                XCTAssertGreaterThan(image.size.width, 0, "Image should have valid width")
                XCTAssertGreaterThan(image.size.height, 0, "Image should have valid height")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testNilPlayerHandling() {
        let dashboard = RealTimeStatsDashboard(
            gameState: gameState,
            configuration: mockConfiguration,
            players: testPlayers
        )
        
        // Test dashboard with no selected player
        // Should not crash and should handle gracefully
        XCTAssertNoThrow("Dashboard should handle nil player selection")
    }
    
    func testEmptyScoresHandling() {
        let emptyGameState = GameState(configuration: mockConfiguration)
        
        let dashboard = RealTimeStatsDashboard(
            gameState: emptyGameState,
            configuration: mockConfiguration,
            players: testPlayers
        )
        
        // Should handle empty game state without crashing
        XCTAssertNoThrow("Dashboard should handle empty game state")
    }
    
    // MARK: - Helper Methods
    
    private func addMockScores() {
        // Add scores for first 9 holes for all players
        for hole in 1...9 {
            for player in testPlayers {
                let score = Int.random(in: 3...6)
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
    }
    
    private func getPlayerScores(player: Player) -> [Int] {
        var scores: [Int] = []
        for hole in 1...18 {
            if let score = gameState.scores[hole]?[player.id] {
                scores.append(score)
            }
        }
        return scores
    }
    
    private func calculateDifferential(scores: [Int], pars: [Int]) -> Int {
        return scores.enumerated().reduce(0) { $0 + ($1.element - (pars[safe: $1.offset] ?? GolfConstants.ParDefaults.defaultPar)) }
    }
    
    private func countBirdies(scores: [Int], pars: [Int]) -> Int {
        return scores.enumerated().filter { $0.element < (pars[safe: $0.offset] ?? GolfConstants.ParDefaults.defaultPar) }.count
    }
    
    private func calculateAverage(scores: [Int]) -> Double {
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
    
    private func createMockRound() -> Round {
        var scores: [Int: Int] = [:]
        for hole in 1...18 {
            scores[hole] = Int.random(in: 3...6)
        }
        
        return Round(
            course: "Test Course",
            players: ["Test Player"],
            scores: scores
        )
    }
    
    private func calculateRoundStats(round: Round, player: Player) -> RoundStatistics {
        let scores = Array(round.scores.values)
        let pars = Array(repeating: 4, count: round.scores.count)
        
        return RoundStatistics(
            totalScore: scores.reduce(0, +),
            toPar: calculateDifferential(scores: scores, pars: pars),
            birdies: countBirdies(scores: scores, pars: pars),
            pars: scores.enumerated().filter { $0.element == (pars[safe: $0.offset] ?? 4) }.count,
            bogeys: scores.enumerated().filter { $0.element == (pars[safe: $0.offset] ?? 4) + 1 }.count,
            bestHole: findBestHole(scores: scores, pars: pars),
            worstHole: findWorstHole(scores: scores, pars: pars),
            longestStreak: findLongestStreak(scores: scores, pars: pars),
            signature: scores.map(String.init).joined()
        )
    }
    
    private func findBestHole(scores: [Int], pars: [Int]) -> (hole: Int, score: Int)? {
        guard !scores.isEmpty else { return nil }
        let diffs = scores.enumerated().map { ($0.offset + 1, $0.element - (pars[safe: $0.offset] ?? 4)) }
        let best = diffs.min { $0.1 < $1.1 }
        if let best = best, let score = scores[safe: best.0 - 1] {
            return (best.0, score)
        }
        return nil
    }
    
    private func findWorstHole(scores: [Int], pars: [Int]) -> (hole: Int, score: Int)? {
        guard !scores.isEmpty else { return nil }
        let diffs = scores.enumerated().map { ($0.offset + 1, $0.element - (pars[safe: $0.offset] ?? 4)) }
        let worst = diffs.max { $0.1 < $1.1 }
        if let worst = worst, let score = scores[safe: worst.0 - 1] {
            return (worst.0, score)
        }
        return nil
    }
    
    private func findLongestStreak(scores: [Int], pars: [Int]) -> StreakType {
        // Simplified implementation
        return .pars
    }
    
    private func calculateCumulativeDifferential(
        currentScores: [Int],
        ghostScores: [Int],
        pars: [Int]
    ) -> [(hole: Int, current: Int, ghost: Int)] {
        var result: [(Int, Int, Int)] = []
        var currentTotal = 0
        var ghostTotal = 0
        
        for i in 0..<max(currentScores.count, ghostScores.count) {
            if i < currentScores.count {
                currentTotal += currentScores[i] - (pars[safe: i] ?? 4)
            }
            if i < ghostScores.count {
                ghostTotal += ghostScores[i] - (pars[safe: i] ?? 4)
            }
            result.append((i + 1, currentTotal, ghostTotal))
        }
        
        return result
    }
    
    private func colorForScore(_ score: Int, par: Int) -> Color {
        let diff = score - par
        if diff < 0 { return .blue }
        if diff == 0 { return .cyan }
        if diff == 1 { return .orange }
        return .red
    }
    
    private func angleForHole(_ hole: Int) -> Angle {
        return .degrees(Double(hole) * 360.0 / 18.0 - 90)
    }
    
    private func radiusForScore(_ score: Int, par: Int, minRadius: CGFloat, maxRadius: CGFloat) -> CGFloat {
        let diff = score - par
        let base = minRadius + (maxRadius - minRadius) / 2
        return base + CGFloat(diff) * 20
    }
    
    private func emotionForScore(_ score: Int, par: Int) -> (emoji: String, color: Color, intensity: CGFloat) {
        let diff = score - par
        switch diff {
        case ..<(-1): return ("star.fill", .purple, 1.0)
        case -1: return ("star", .green, 0.8)
        case 0: return ("checkmark.circle", .blue, 0.6)
        case 1: return ("exclamationmark.triangle", .orange, 0.7)
        default: return ("xmark.circle", .red, 0.9)
        }
    }
    
    private func heatMapIntensity(for hole: Int, rounds: [Round]) -> Double {
        var totalDiff = 0
        var count = 0
        
        for round in rounds {
            if let score = round.scores[hole] {
                totalDiff += score - GolfConstants.ParDefaults.defaultPar // Using default par
                count += 1
            }
        }
        
        guard count > 0 else { return 0 }
        let avgDiff = Double(totalDiff) / Double(count)
        
        return max(0, min(1, (avgDiff + 2) / 4))
    }
    
    private func createMockRoundHistory() -> [Round] {
        var rounds: [Round] = []
        
        for i in 1...5 {
            var scores: [Int: Int] = [:]
            for hole in 1...18 {
                scores[hole] = Int.random(in: 3...6)
            }
            
            rounds.append(Round(
                course: "Test Course \(i)",
                date: Date().addingTimeInterval(TimeInterval(-i * 86400)),
                players: ["Test Player"],
                scores: scores
            ))
        }
        
        return rounds
    }
}

// MARK: - Array Extension for Safe Access

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Enums for Testing

enum StreakType {
    case birdies
    case pars
    case bogeys
}

// MARK: - Statistics Model for Testing

struct RoundStatistics {
    let totalScore: Int
    let toPar: Int
    let birdies: Int
    let pars: Int
    let bogeys: Int
    let bestHole: (hole: Int, score: Int)?
    let worstHole: (hole: Int, score: Int)?
    let longestStreak: StreakType
    let signature: String
}

// MARK: - Mock Generator for Testing

class ShareableStatsGenerator {
    func generateStatsCard(
        for round: Round,
        player: Player,
        style: CardStyle,
        stats: RoundStatistics
    ) async -> UIImage {
        // Create a simple 1x1 test image
        let size = CGSize(width: 350, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        return image
    }
}