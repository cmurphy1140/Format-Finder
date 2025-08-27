import XCTest
@testable import FormatFinder

// MARK: - Scramble Format Tests

final class ScrambleFormatTests: XCTestCase {
    
    var scrambleFormat: ScrambleFormat!
    var testPlayers: [PlayerIdentifier]!
    
    override func setUp() {
        super.setUp()
        scrambleFormat = ScrambleFormat()
        
        testPlayers = [
            PlayerIdentifier(id: UUID(), name: "Player 1", handicap: 10),
            PlayerIdentifier(id: UUID(), name: "Player 2", handicap: 15),
            PlayerIdentifier(id: UUID(), name: "Player 3", handicap: 5),
            PlayerIdentifier(id: UUID(), name: "Player 4", handicap: 20)
        ]
    }
    
    override func tearDown() {
        scrambleFormat = nil
        testPlayers = nil
        super.tearDown()
    }
    
    // MARK: - Score Calculation Tests
    
    func testCalculateScore_ReturnsLowestScore() {
        // Given
        let scores = [
            PlayerScore(playerId: testPlayers[0], strokes: 5, handicapStrokes: 0, metadata: nil),
            PlayerScore(playerId: testPlayers[1], strokes: 4, handicapStrokes: 0, metadata: nil),
            PlayerScore(playerId: testPlayers[2], strokes: 6, handicapStrokes: 0, metadata: nil),
            PlayerScore(playerId: testPlayers[3], strokes: 7, handicapStrokes: 0, metadata: nil)
        ]
        
        // When
        let result = scrambleFormat.calculateScore(for: 1, scores: scores)
        
        // Then
        XCTAssertEqual(result.grossScore, 4, "Should return the lowest score")
    }
    
    func testSelectBestBall_ReturnsPlayerWithBestNetScore() {
        // Given
        let scores = [
            PlayerScore(playerId: testPlayers[0], strokes: 5, handicapStrokes: 1, metadata: nil),
            PlayerScore(playerId: testPlayers[1], strokes: 4, handicapStrokes: 0, metadata: nil),
            PlayerScore(playerId: testPlayers[2], strokes: 6, handicapStrokes: 2, metadata: nil)
        ]
        
        // When
        let bestPlayer = scrambleFormat.selectBestBall(scores: scores)
        
        // Then
        XCTAssertEqual(bestPlayer, testPlayers[0], "Should select player with best net score (5-1=4 equals 4-0=4, but first is selected)")
    }
    
    func testValidateScore_AcceptsValidScores() {
        // Given
        let player = testPlayers[0]
        
        // When & Then
        XCTAssertTrue(scrambleFormat.validateScore(1, for: player, hole: 1))
        XCTAssertTrue(scrambleFormat.validateScore(5, for: player, hole: 1))
        XCTAssertTrue(scrambleFormat.validateScore(10, for: player, hole: 1))
    }
    
    func testValidateScore_RejectsInvalidScores() {
        // Given
        let player = testPlayers[0]
        
        // When & Then
        XCTAssertFalse(scrambleFormat.validateScore(0, for: player, hole: 1))
        XCTAssertFalse(scrambleFormat.validateScore(-1, for: player, hole: 1))
        XCTAssertFalse(scrambleFormat.validateScore(11, for: player, hole: 1))
    }
    
    func testApplyHandicap_ReducesScoreCorrectly() {
        // Given
        let score = 5
        let handicap = 18
        let hole = 1
        
        // When
        let adjustedScore = scrambleFormat.applyHandicap(score, handicap: handicap, hole: hole)
        
        // Then
        XCTAssertEqual(adjustedScore, 4, "Should reduce score by 1 for 18 handicap on hole 1")
    }
    
    func testApplyHandicap_NeverGoesBelowOne() {
        // Given
        let score = 1
        let handicap = 36
        let hole = 1
        
        // When
        let adjustedScore = scrambleFormat.applyHandicap(score, handicap: handicap, hole: hole)
        
        // Then
        XCTAssertEqual(adjustedScore, 1, "Score should never go below 1")
    }
    
    // MARK: - Ball Selection Tests
    
    func testRecordBallSelection_StoresSelection() {
        // Given
        let hole = 1
        let player = testPlayers[0]
        let shotType = ShotType.tee
        
        // When
        scrambleFormat.recordBallSelection(hole: hole, player: player, shotType: shotType)
        
        // Then
        XCTAssertEqual(scrambleFormat.getBallSelection(for: hole), player)
    }
    
    func testGetShotBreakdown_ReturnsCorrectBreakdown() {
        // Given
        let hole = 1
        scrambleFormat.recordBallSelection(hole: hole, player: testPlayers[0], shotType: .tee)
        scrambleFormat.recordBallSelection(hole: hole, player: testPlayers[1], shotType: .approach)
        scrambleFormat.recordBallSelection(hole: hole, player: testPlayers[2], shotType: .putt)
        
        // When
        let breakdown = scrambleFormat.getShotBreakdown(for: hole)
        
        // Then
        XCTAssertEqual(breakdown["Tee Shot"], "Player 1")
        XCTAssertEqual(breakdown["Approach"], "Player 2")
        XCTAssertEqual(breakdown["Putt"], "Player 3")
    }
    
    // MARK: - Round Summary Tests
    
    func testGetRoundSummary_CalculatesCorrectStatistics() {
        // Given
        let scores: [Int: [PlayerIdentifier: Int]] = [
            1: [testPlayers[0]: 3, testPlayers[1]: 4],  // Birdie
            2: [testPlayers[0]: 4, testPlayers[1]: 4],  // Par
            3: [testPlayers[0]: 2, testPlayers[1]: 3]   // Birdie
        ]
        
        // When
        let summary = scrambleFormat.getRoundSummary(scores: scores)
        
        // Then
        XCTAssertEqual(summary.statistics.totalStrokes, 9)  // 3 + 4 + 2
        XCTAssertEqual(summary.statistics.birdies, 2)
        XCTAssertEqual(summary.statistics.averageScore, 3.0)
        XCTAssertEqual(summary.highlights.count, 2)
    }
    
    // MARK: - Performance Tests
    
    func testCalculateScorePerformance() {
        measure {
            let scores = testPlayers.map { player in
                PlayerScore(playerId: player, strokes: Int.random(in: 3...8), handicapStrokes: 0, metadata: nil)
            }
            
            for hole in 1...18 {
                _ = scrambleFormat.calculateScore(for: hole, scores: scores)
            }
        }
    }
}

// MARK: - Match Play Format Tests

final class MatchPlayFormatTests: XCTestCase {
    
    func testDetermineHoleWinner() {
        // Test implementation for Match Play format
        XCTAssertTrue(true, "Match Play tests to be implemented")
    }
}

// MARK: - Stableford Format Tests

final class StablefordFormatTests: XCTestCase {
    
    func testCalculatePoints() {
        // Test implementation for Stableford format
        XCTAssertTrue(true, "Stableford tests to be implemented")
    }
}