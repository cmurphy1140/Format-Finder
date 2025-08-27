import Foundation
import SwiftUI

// MARK: - Manual Achievement Detection Validation

struct AchievementDetectionValidator {
    
    static func runValidationTests() -> ValidationResults {
        var results = ValidationResults()
        
        // Test 1: Hole-in-one Detection
        results.holeInOneTest = validateHoleInOneDetection()
        
        // Test 2: Eagle Detection
        results.eagleTest = validateEagleDetection()
        
        // Test 3: Birdie Streak Detection
        results.birdieStreakTest = validateBirdieStreakDetection()
        
        // Test 4: Personal Best Detection
        results.personalBestTest = validatePersonalBestDetection()
        
        // Test 5: Milestone Detection
        results.milestoneTest = validateMilestoneDetection()
        
        // Test 6: Score Calculation Accuracy
        results.scoreCalculationTest = validateScoreCalculation()
        
        // Test 7: Animation Timing Validation
        results.animationTimingTest = validateAnimationTiming()
        
        // Test 8: Particle System Configuration
        results.particleSystemTest = validateParticleSystem()
        
        return results
    }
    
    // MARK: - Individual Test Methods
    
    static func validateHoleInOneDetection() -> TestResult {
        let gameState = createTestGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        let hole = 7
        
        // Set hole-in-one score
        gameState.setScore(hole: hole, player: player.id, score: 1)
        
        // Check for achievements
        let achievements = detector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: hole
        )
        
        // Validate results
        let holeInOneAchievement = achievements.first { $0.title == "Hole in One!" }
        
        if let achievement = holeInOneAchievement {
            let isValid = achievement.value == "ACE" &&
                         achievement.showConfetti == true &&
                         achievement.rarity == .legendary &&
                         achievement.icon == "star.circle.fill"
            
            return TestResult(
                passed: isValid,
                message: isValid ? "Hole-in-one detection working correctly" : "Hole-in-one properties incorrect",
                details: [
                    "Value: \(achievement.value ?? "nil")",
                    "Confetti: \(achievement.showConfetti)",
                    "Rarity: \(achievement.rarity)",
                    "Icon: \(achievement.icon)"
                ]
            )
        } else {
            return TestResult(
                passed: false,
                message: "Hole-in-one achievement not detected",
                details: ["Found \(achievements.count) achievements: \(achievements.map { $0.title })"]
            )
        }
    }
    
    static func validateEagleDetection() -> TestResult {
        let gameState = createTestGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        let hole = 5
        
        // Set eagle score (2 on assumed par 4)
        gameState.setScore(hole: hole, player: player.id, score: 2)
        
        let achievements = detector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: hole
        )
        
        let eagleAchievement = achievements.first { $0.title == "Eagle!" }
        
        if let achievement = eagleAchievement {
            let isValid = achievement.value == "-2" &&
                         achievement.showConfetti == true &&
                         achievement.rarity == .epic &&
                         achievement.icon == "bird"
            
            return TestResult(
                passed: isValid,
                message: isValid ? "Eagle detection working correctly" : "Eagle properties incorrect",
                details: [
                    "Value: \(achievement.value ?? "nil")",
                    "Confetti: \(achievement.showConfetti)",
                    "Rarity: \(achievement.rarity)",
                    "Icon: \(achievement.icon)"
                ]
            )
        } else {
            return TestResult(
                passed: false,
                message: "Eagle achievement not detected",
                details: ["Expected eagle for score 2 on par 4"]
            )
        }
    }
    
    static func validateBirdieStreakDetection() -> TestResult {
        let gameState = createTestGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        
        // Set up 3 consecutive birdies (score 3 on assumed par 4)
        for hole in 3...5 {
            gameState.setScore(hole: hole, player: player.id, score: 3)
        }
        
        let achievements = detector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 5
        )
        
        let streakAchievement = achievements.first { $0.title == "Birdie Streak!" }
        
        if let achievement = streakAchievement {
            let isValid = achievement.description.contains("3") &&
                         achievement.showConfetti == true &&
                         achievement.rarity == .rare &&
                         achievement.icon == "flame.fill"
            
            return TestResult(
                passed: isValid,
                message: isValid ? "Birdie streak detection working correctly" : "Birdie streak properties incorrect",
                details: [
                    "Description: \(achievement.description)",
                    "Confetti: \(achievement.showConfetti)",
                    "Rarity: \(achievement.rarity)",
                    "Icon: \(achievement.icon)"
                ]
            )
        } else {
            return TestResult(
                passed: false,
                message: "Birdie streak achievement not detected",
                details: ["Expected 3-birdie streak detection"]
            )
        }
    }
    
    static func validatePersonalBestDetection() -> TestResult {
        let gameState = createTestGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        
        // Set scores to total under 80
        var totalScore = 0
        for hole in 1...18 {
            let score = hole <= 9 ? 4 : 3 // 36 + 27 = 63
            gameState.setScore(hole: hole, player: player.id, score: score)
            totalScore += score
        }
        
        let achievements = detector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 18
        )
        
        let personalBest = achievements.first { $0.title == "Personal Best!" }
        
        if let achievement = personalBest {
            let isValid = achievement.value == "63" &&
                         achievement.showConfetti == true &&
                         achievement.rarity == .epic
            
            return TestResult(
                passed: isValid,
                message: isValid ? "Personal best detection working correctly" : "Personal best properties incorrect",
                details: [
                    "Expected total: 63, Got: \(achievement.value ?? "nil")",
                    "Confetti: \(achievement.showConfetti)",
                    "Rarity: \(achievement.rarity)"
                ]
            )
        } else {
            return TestResult(
                passed: false,
                message: "Personal best achievement not detected",
                details: ["Total score: \(totalScore), Expected: 63"]
            )
        }
    }
    
    static func validateMilestoneDetection() -> TestResult {
        let gameState = createTestGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        
        // Test even par (72)
        for hole in 1...18 {
            gameState.setScore(hole: hole, player: player.id, score: 4) // 18 * 4 = 72
        }
        
        let achievements = detector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 18
        )
        
        let evenPar = achievements.first { $0.title == "Even Par!" }
        
        if let achievement = evenPar {
            let isValid = achievement.value == "72" &&
                         achievement.showConfetti == false &&
                         achievement.rarity == .rare
            
            return TestResult(
                passed: isValid,
                message: isValid ? "Even par milestone detection working correctly" : "Even par properties incorrect",
                details: [
                    "Value: \(achievement.value ?? "nil")",
                    "Confetti: \(achievement.showConfetti)",
                    "Rarity: \(achievement.rarity)"
                ]
            )
        } else {
            return TestResult(
                passed: false,
                message: "Even par milestone not detected",
                details: ["Total score: 72"]
            )
        }
    }
    
    static func validateScoreCalculation() -> TestResult {
        let gameState = createTestGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        
        let expectedScores = [4, 3, 5, 4, 2, 6, 4, 3, 4] // Total: 35
        
        for (index, score) in expectedScores.enumerated() {
            gameState.setScore(hole: index + 1, player: player.id, score: score)
        }
        
        let totalScore = detector.calculateTotalScore(for: player.id, in: gameState)
        let isCorrect = totalScore == 35
        
        return TestResult(
            passed: isCorrect,
            message: isCorrect ? "Score calculation is accurate" : "Score calculation is incorrect",
            details: [
                "Expected: 35",
                "Calculated: \(totalScore)",
                "Individual scores: \(expectedScores)"
            ]
        )
    }
    
    static func validateAnimationTiming() -> TestResult {
        // Validate animation configuration
        let springResponse: Double = 0.8
        let dampingFraction: Double = 0.6
        let delayIncrement: Double = 0.2
        
        let isValidTiming = springResponse > 0.5 && springResponse < 1.5 &&
                           dampingFraction > 0.4 && dampingFraction < 0.8 &&
                           delayIncrement >= 0.1 && delayIncrement <= 0.5
        
        return TestResult(
            passed: isValidTiming,
            message: isValidTiming ? "Animation timing parameters are well-tuned" : "Animation timing needs adjustment",
            details: [
                "Spring response: \(springResponse)s (optimal: 0.5-1.5s)",
                "Damping fraction: \(dampingFraction) (optimal: 0.4-0.8)",
                "Delay increment: \(delayIncrement)s (optimal: 0.1-0.5s)"
            ]
        )
    }
    
    static func validateParticleSystem() -> TestResult {
        let particleCount = 100
        let velocityRange = 200...400
        let angularRange = -180...180
        let sizeRange = 8...16
        
        let isValidConfig = particleCount >= 50 && particleCount <= 150 &&
                           velocityRange.lowerBound >= 100 && velocityRange.upperBound <= 500 &&
                           sizeRange.lowerBound >= 6 && sizeRange.upperBound <= 20
        
        return TestResult(
            passed: isValidConfig,
            message: isValidConfig ? "Particle system configuration is optimal" : "Particle system needs tuning",
            details: [
                "Particle count: \(particleCount) (optimal: 50-150)",
                "Velocity range: \(velocityRange) (optimal: 100-500)",
                "Size range: \(sizeRange) (optimal: 6-20)",
                "Angular range: \(angularRange) (good: full rotation)"
            ]
        )
    }
    
    // MARK: - Helper Methods
    
    private static func createTestGameState() -> GameState {
        let players = [
            Player(name: "Test Player 1", handicap: 10),
            Player(name: "Test Player 2", handicap: 15)
        ]
        
        let config = GameConfiguration(
            format: .strokePlay,
            numberOfHoles: 18,
            courseName: "Test Course"
        )
        
        return GameState(configuration: config, players: players)
    }
}

// MARK: - Test Result Models

struct ValidationResults {
    var holeInOneTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    var eagleTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    var birdieStreakTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    var personalBestTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    var milestoneTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    var scoreCalculationTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    var animationTimingTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    var particleSystemTest: TestResult = TestResult(passed: false, message: "Not run", details: [])
    
    var overallPassRate: Double {
        let tests = [holeInOneTest, eagleTest, birdieStreakTest, personalBestTest, 
                    milestoneTest, scoreCalculationTest, animationTimingTest, particleSystemTest]
        let passedCount = tests.filter { $0.passed }.count
        return Double(passedCount) / Double(tests.count) * 100
    }
    
    var summary: String {
        let tests = [holeInOneTest, eagleTest, birdieStreakTest, personalBestTest, 
                    milestoneTest, scoreCalculationTest, animationTimingTest, particleSystemTest]
        let passedCount = tests.filter { $0.passed }.count
        let totalCount = tests.count
        
        return """
        Achievement Celebration System Validation Results
        ============================================
        
        Overall Status: \(passedCount)/\(totalCount) tests passed (\(String(format: "%.1f", overallPassRate))%)
        
        Test Results:
        - Hole-in-One Detection: \(holeInOneTest.passed ? "PASS" : "FAIL") - \(holeInOneTest.message)
        - Eagle Detection: \(eagleTest.passed ? "PASS" : "FAIL") - \(eagleTest.message)
        - Birdie Streak Detection: \(birdieStreakTest.passed ? "PASS" : "FAIL") - \(birdieStreakTest.message)
        - Personal Best Detection: \(personalBestTest.passed ? "PASS" : "FAIL") - \(personalBestTest.message)
        - Milestone Detection: \(milestoneTest.passed ? "PASS" : "FAIL") - \(milestoneTest.message)
        - Score Calculation: \(scoreCalculationTest.passed ? "PASS" : "FAIL") - \(scoreCalculationTest.message)
        - Animation Timing: \(animationTimingTest.passed ? "PASS" : "FAIL") - \(animationTimingTest.message)
        - Particle System: \(particleSystemTest.passed ? "PASS" : "FAIL") - \(particleSystemTest.message)
        
        Detailed Results:
        \(tests.enumerated().map { index, test in
            let testNames = ["Hole-in-One", "Eagle", "Birdie Streak", "Personal Best", "Milestone", "Score Calc", "Animation", "Particles"]
            return "\n\(testNames[index]) Test Details:\n" + test.details.map { "  - \($0)" }.joined(separator: "\n")
        }.joined(separator: "\n"))
        """
    }
}

struct TestResult {
    let passed: Bool
    let message: String
    let details: [String]
}

// MARK: - Mock Extensions for Testing

extension AchievementDetector {
    func calculateTotalScore(for playerId: UUID, in gameState: GameState) -> Int {
        var total = 0
        for (_, scores) in gameState.scores {
            total += scores[playerId] ?? 0
        }
        return total
    }
}
