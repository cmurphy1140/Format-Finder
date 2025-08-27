import XCTest
import SwiftUI
@testable import FormatFinder

// MARK: - Achievement Celebration System Tests

class AchievementCelebrationTests: XCTestCase {
    
    var achievementDetector: AchievementDetector!
    var gameState: GameState!
    var players: [Player]!
    
    override func setUp() {
        super.setUp()
        achievementDetector = AchievementDetector()
        
        // Setup test players
        players = [
            Player(name: "Test Player 1", handicap: 10),
            Player(name: "Test Player 2", handicap: 15),
            Player(name: "Pro Player", handicap: 0)
        ]
        
        // Setup test game state
        let config = GameConfiguration(
            format: .strokePlay,
            numberOfHoles: 18,
            courseName: "Test Course"
        )
        gameState = GameState(configuration: config, players: players)
    }
    
    // MARK: - Achievement Detection Tests
    
    func testHoleInOneDetection() {
        // Given: A player scores 1 on a hole
        let player = players[0]
        let hole = 7
        gameState.setScore(hole: hole, player: player.id, score: 1)
        
        // When: Checking for achievements
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: hole
        )
        
        // Then: Hole-in-one achievement should be detected
        XCTAssertFalse(achievements.isEmpty, "Should detect hole-in-one achievement")
        
        let holeInOneAchievement = achievements.first(where: { $0.title == "Hole in One!" })
        XCTAssertNotNil(holeInOneAchievement, "Should find hole-in-one achievement")
        
        if let achievement = holeInOneAchievement {
            XCTAssertEqual(achievement.value, "ACE", "Achievement value should be ACE")
            XCTAssertTrue(achievement.showConfetti, "Should show confetti for hole-in-one")
            XCTAssertEqual(achievement.rarity, .legendary, "Hole-in-one should be legendary")
            XCTAssertEqual(achievement.icon, "star.circle.fill", "Should use star icon")
        }
    }
    
    func testEagleDetection() {
        // Given: A player scores 2 on a par 4 (eagle)
        let player = players[0]
        let hole = 5
        gameState.setScore(hole: hole, player: player.id, score: 2)
        
        // When: Checking for achievements
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: hole
        )
        
        // Then: Eagle achievement should be detected
        let eagleAchievement = achievements.first(where: { $0.title == "Eagle!" })
        XCTAssertNotNil(eagleAchievement, "Should detect eagle achievement")
        
        if let achievement = eagleAchievement {
            XCTAssertEqual(achievement.value, "-2", "Eagle should show -2")
            XCTAssertTrue(achievement.showConfetti, "Should show confetti for eagle")
            XCTAssertEqual(achievement.rarity, .epic, "Eagle should be epic rarity")
            XCTAssertEqual(achievement.icon, "bird", "Should use bird icon")
        }
    }
    
    func testBirdieStreakDetection() {
        // Given: A player scores 3 consecutive birdies
        let player = players[0]
        let startHole = 3
        
        // Set up birdie streak (assuming par 4)
        for hole in startHole...(startHole + 2) {
            gameState.setScore(hole: hole, player: player.id, score: 3) // Birdie on par 4
        }
        
        // When: Checking for achievements on the third birdie
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: startHole + 2
        )
        
        // Then: Birdie streak achievement should be detected
        let streakAchievement = achievements.first(where: { $0.title == "Birdie Streak!" })
        XCTAssertNotNil(streakAchievement, "Should detect birdie streak")
        
        if let achievement = streakAchievement {
            XCTAssertTrue(achievement.description.contains("3"), "Should mention 3 birdies")
            XCTAssertTrue(achievement.showConfetti, "Should show confetti for streak")
            XCTAssertEqual(achievement.rarity, .rare, "Streak should be rare")
            XCTAssertEqual(achievement.icon, "flame.fill", "Should use flame icon")
        }
    }
    
    func testPersonalBestDetection() {
        // Given: A player finishes with a score under 80
        let player = players[0]
        
        // Set scores for all 18 holes to total under 80
        var totalScore = 0
        for hole in 1...18 {
            let score = hole <= 9 ? 4 : 3 // Front 9: 36, Back 9: 27 = 63 total
            gameState.setScore(hole: hole, player: player.id, score: score)
            totalScore += score
        }
        
        // When: Checking for achievements after final hole
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 18
        )
        
        // Then: Personal best achievement should be detected
        let personalBest = achievements.first(where: { $0.title == "Personal Best!" })
        XCTAssertNotNil(personalBest, "Should detect personal best")
        
        if let achievement = personalBest {
            XCTAssertEqual(achievement.value, "63", "Should show total score")
            XCTAssertTrue(achievement.showConfetti, "Should show confetti for personal best")
            XCTAssertEqual(achievement.rarity, .epic, "Personal best should be epic")
        }
    }
    
    func testMilestoneEvenParDetection() {
        // Given: A player scores exactly 72 (even par)
        let player = players[0]
        
        // Set scores to total exactly 72
        for hole in 1...18 {
            gameState.setScore(hole: hole, player: player.id, score: 4) // 18 x 4 = 72
        }
        
        // When: Checking for achievements
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 18
        )
        
        // Then: Even par milestone should be detected
        let evenPar = achievements.first(where: { $0.title == "Even Par!" })
        XCTAssertNotNil(evenPar, "Should detect even par milestone")
        
        if let achievement = evenPar {
            XCTAssertEqual(achievement.value, "72", "Should show par score")
            XCTAssertFalse(achievement.showConfetti, "Even par shouldn't show confetti")
            XCTAssertEqual(achievement.rarity, .rare, "Even par should be rare")
        }
    }
    
    func testMilestoneBreaking70Detection() {
        // Given: A player scores under 70
        let player = players[0]
        
        // Set scores to total under 70
        for hole in 1...18 {
            let score = hole <= 12 ? 4 : 3 // 12 x 4 + 6 x 3 = 66
            gameState.setScore(hole: hole, player: player.id, score: score)
        }
        
        // When: Checking for achievements
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 18
        )
        
        // Then: Breaking 70 milestone should be detected
        let breaking70 = achievements.first(where: { $0.title == "Breaking 70!" })
        XCTAssertNotNil(breaking70, "Should detect breaking 70 milestone")
        
        if let achievement = breaking70 {
            XCTAssertEqual(achievement.value, "66", "Should show actual score")
            XCTAssertTrue(achievement.showConfetti, "Breaking 70 should show confetti")
            XCTAssertEqual(achievement.rarity, .legendary, "Breaking 70 should be legendary")
        }
    }
    
    // MARK: - Score Calculation Tests
    
    func testTotalScoreCalculation() {
        // Given: Scores set for multiple holes
        let player = players[0]
        let expectedScores = [4, 3, 5, 4, 2, 6, 4, 3, 4] // Total: 35
        
        for (index, score) in expectedScores.enumerated() {
            gameState.setScore(hole: index + 1, player: player.id, score: score)
        }
        
        // When: Calculating total score
        let totalScore = achievementDetector.calculateTotalScore(for: player.id, in: gameState)
        
        // Then: Should return correct sum
        XCTAssertEqual(totalScore, 35, "Total score calculation should be correct")
    }
    
    // MARK: - Achievement Model Tests
    
    func testAchievementInitialization() {
        // Given: Achievement parameters
        let title = "Test Achievement"
        let description = "Test description"
        let icon = "star.fill"
        let color = Color.blue
        let value = "Test Value"
        
        // When: Creating achievement
        let achievement = Achievement(
            title: title,
            description: description,
            icon: icon,
            color: color,
            value: value,
            showConfetti: true,
            rarity: .epic
        )
        
        // Then: All properties should be set correctly
        XCTAssertEqual(achievement.title, title)
        XCTAssertEqual(achievement.description, description)
        XCTAssertEqual(achievement.icon, icon)
        XCTAssertEqual(achievement.value, value)
        XCTAssertTrue(achievement.showConfetti)
        XCTAssertEqual(achievement.rarity, .epic)
        XCTAssertNotNil(achievement.id)
    }
    
    func testAchievementRarityColors() {
        // Test each rarity level has correct color
        XCTAssertEqual(AchievementRarity.common.color, .gray)
        XCTAssertEqual(AchievementRarity.rare.color, .blue)
        XCTAssertEqual(AchievementRarity.epic.color, .purple)
        XCTAssertEqual(AchievementRarity.legendary.color, .yellow)
    }
    
    // MARK: - Edge Cases
    
    func testNoAchievementForRegularScore() {
        // Given: A player scores a regular par
        let player = players[0]
        let hole = 5
        gameState.setScore(hole: hole, player: player.id, score: 4) // Par score
        
        // When: Checking for achievements
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: hole
        )
        
        // Then: No special achievements should be detected
        let specialAchievements = achievements.filter {
            ["Hole in One!", "Eagle!", "Birdie Streak!"].contains($0.title)
        }
        XCTAssertTrue(specialAchievements.isEmpty, "Regular par should not trigger achievements")
    }
    
    func testMultipleAchievementsInOneCheck() {
        // Given: A scenario that triggers multiple achievements
        let player = players[0]
        let hole = 7
        
        // Set up a hole-in-one (which could also be part of a streak)
        gameState.setScore(hole: hole, player: player.id, score: 1)
        
        // Set up previous holes for potential streak/total
        for h in 1...(hole-1) {
            gameState.setScore(hole: h, player: player.id, score: 3)
        }
        
        // When: Checking for achievements
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: hole
        )
        
        // Then: Should detect hole-in-one achievement
        XCTAssertTrue(achievements.count >= 1, "Should detect at least hole-in-one")
        
        let holeInOne = achievements.first { $0.title == "Hole in One!" }
        XCTAssertNotNil(holeInOne, "Should detect hole-in-one")
    }
    
    func testStreakInterruption() {
        // Given: A birdie streak that gets interrupted
        let player = players[0]
        
        // Set up 2 birdies, then a bogey, then another birdie
        gameState.setScore(hole: 1, player: player.id, score: 3) // Birdie
        gameState.setScore(hole: 2, player: player.id, score: 3) // Birdie
        gameState.setScore(hole: 3, player: player.id, score: 5) // Bogey
        gameState.setScore(hole: 4, player: player.id, score: 3) // Birdie
        
        // When: Checking for achievements on hole 4
        let achievements = achievementDetector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 4
        )
        
        // Then: Should not detect a streak achievement
        let streakAchievement = achievements.first { $0.title == "Birdie Streak!" }
        XCTAssertNil(streakAchievement, "Interrupted streak should not trigger achievement")
    }
}

// MARK: - Animation and UI Tests

class AchievementAnimationTests: XCTestCase {
    
    func testConfettiParticleInitialization() {
        // Given: Confetti particle parameters
        let x: CGFloat = 100
        let y: CGFloat = 50
        let color = Color.red
        let size: CGFloat = 10
        let velocity: CGFloat = 200
        let angularVelocity: Double = 45
        
        // When: Creating confetti particle
        let particle = ConfettiParticle(
            x: x,
            y: y,
            color: color,
            size: size,
            velocity: velocity,
            angularVelocity: angularVelocity
        )
        
        // Then: All properties should be set correctly
        XCTAssertEqual(particle.x, x)
        XCTAssertEqual(particle.y, y)
        XCTAssertEqual(particle.color, color)
        XCTAssertEqual(particle.size, size)
        XCTAssertEqual(particle.velocity, velocity)
        XCTAssertEqual(particle.angularVelocity, angularVelocity)
        XCTAssertNotNil(particle.id)
    }
    
    func testAchievementIconAnimationStates() {
        // Test that achievement icon has proper animation state tracking
        let achievement = Achievement(
            title: "Test",
            description: "Test",
            icon: "star.fill",
            color: .blue
        )
        
        // Verify achievement properties for animation
        XCTAssertNotNil(achievement.icon, "Icon should be set")
        XCTAssertNotNil(achievement.color, "Color should be set")
        XCTAssertEqual(achievement.icon, "star.fill", "Icon should match")
    }
}

// MARK: - Performance Tests

class AchievementPerformanceTests: XCTestCase {
    
    func testLargeConfettiPerformance() {
        // Test creating 100 confetti particles doesn't cause performance issues
        let expectation = XCTestExpectation(description: "Confetti creation performance")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            var particles: [ConfettiParticle] = []
            for _ in 0..<100 {
                let particle = ConfettiParticle(
                    x: CGFloat.random(in: 0...400),
                    y: -50,
                    color: [.red, .blue, .green, .yellow, .orange, .purple].randomElement()!,
                    size: CGFloat.random(in: 8...16),
                    velocity: CGFloat.random(in: 200...400),
                    angularVelocity: Double.random(in: -180...180)
                )
                particles.append(particle)
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            
            // Should complete in reasonable time (under 0.1 seconds)
            XCTAssertLessThan(executionTime, 0.1, "Confetti creation should be fast")
            XCTAssertEqual(particles.count, 100, "Should create all particles")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAchievementDetectionPerformance() {
        // Test achievement detection performance with full game state
        let gameState = GameState.mockGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        
        // Fill all holes with scores
        for hole in 1...18 {
            gameState.setScore(hole: hole, player: player.id, score: Int.random(in: 3...6))
        }
        
        measure {
            // This should complete quickly even with full game state
            for hole in 1...18 {
                _ = detector.checkForAchievements(
                    player: player,
                    gameState: gameState,
                    hole: hole
                )
            }
        }
    }
}

// MARK: - Integration Tests

class AchievementIntegrationTests: XCTestCase {
    
    func testAchievementWorkflowIntegration() {
        // Test complete workflow: score entry -> detection -> celebration
        let gameState = GameState.mockGameState()
        let detector = AchievementDetector()
        let player = gameState.players.first!
        
        // Simulate hole-in-one
        gameState.setScore(hole: 1, player: player.id, score: 1)
        
        // Detect achievements
        let achievements = detector.checkForAchievements(
            player: player,
            gameState: gameState,
            hole: 1
        )
        
        // Should find hole-in-one
        XCTAssertFalse(achievements.isEmpty)
        
        let holeInOne = achievements.first { $0.title == "Hole in One!" }
        XCTAssertNotNil(holeInOne)
        
        // Should be configured for full celebration
        if let achievement = holeInOne {
            XCTAssertTrue(achievement.showConfetti, "Should show confetti")
            XCTAssertEqual(achievement.rarity, .legendary, "Should be legendary")
        }
    }
}
