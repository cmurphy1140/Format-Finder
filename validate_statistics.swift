#!/usr/bin/env swift

import Foundation

// MARK: - Test Data Structures

struct Player {
    let id: UUID
    let name: String
    let handicap: Int
    
    init(name: String, handicap: Int) {
        self.id = UUID()
        self.name = name
        self.handicap = handicap
    }
}

struct Round {
    let id: UUID
    let course: String
    let date: Date
    let scores: [Int: Int]  // [Hole: Score]
    let players: [String]
    
    init(course: String, players: [String], scores: [Int: Int]) {
        self.id = UUID()
        self.course = course
        self.date = Date()
        self.players = players
        self.scores = scores
    }
}

// MARK: - Statistics Validation Functions

class StatisticsValidator {
    
    // MARK: - Momentum Calculation Tests
    
    func testMomentumCalculation() -> Bool {
        print("Testing Momentum Calculation...")
        
        // Test case 1: Improving scores (positive momentum)
        let improvingScores = [5, 4, 3]
        let positiveMomentum = calculateMomentum(scores: improvingScores, handicap: 10)
        
        // Test case 2: Declining scores (negative momentum)
        let decliningScores = [3, 4, 5]
        let negativeMomentum = calculateMomentum(scores: decliningScores, handicap: 10)
        
        // Test case 3: Consistent scores (neutral momentum)
        let consistentScores = [4, 4, 4]
        let neutralMomentum = calculateMomentum(scores: consistentScores, handicap: 10)
        
        let test1 = positiveMomentum > 0
        let test2 = negativeMomentum < 0
        let test3 = abs(neutralMomentum) < 0.2
        
        print("  - Positive momentum: \(positiveMomentum) > 0 = \(test1 ? "PASS" : "FAIL")")
        print("  - Negative momentum: \(negativeMomentum) < 0 = \(test2 ? "PASS" : "FAIL")")
        print("  - Neutral momentum: \(neutralMomentum) ~= 0 = \(test3 ? "PASS" : "FAIL")")
        
        return test1 && test2 && test3
    }
    
    func calculateMomentum(scores: [Int], handicap: Int) -> Double {
        guard scores.count >= 3 else { return 0 }
        
        let recentScores = Array(scores.suffix(3))
        let pars = Array(repeating: 4, count: 3)
        
        let recentAvg = Double(recentScores.reduce(0, +)) / Double(recentScores.count)
        let expectedAvg = 4.0 + Double(handicap) / 18.0
        
        let momentum = (expectedAvg - recentAvg) / 2.0
        return max(-1, min(1, momentum))
    }
    
    // MARK: - Round Statistics Tests
    
    func testRoundStatistics() -> Bool {
        print("Testing Round Statistics Calculation...")
        
        let testScores = [4, 3, 5, 4, 6, 3, 4, 5, 4] // 9 holes
        let testPars = [4, 4, 4, 4, 4, 4, 4, 4, 4]
        
        let stats = calculateRoundStatistics(scores: testScores, pars: testPars)
        
        let expectedTotal = 38
        let expectedToPar = 2
        let expectedBirdies = 2
        let expectedPars = 5
        let expectedBogeys = 1
        
        let test1 = stats.totalScore == expectedTotal
        let test2 = stats.toPar == expectedToPar
        let test3 = stats.birdies == expectedBirdies
        let test4 = stats.pars == expectedPars
        let test5 = stats.bogeys == expectedBogeys
        
        print("  - Total Score: \(stats.totalScore) == \(expectedTotal) = \(test1 ? "PASS" : "FAIL")")
        print("  - To Par: \(stats.toPar) == \(expectedToPar) = \(test2 ? "PASS" : "FAIL")")
        print("  - Birdies: \(stats.birdies) == \(expectedBirdies) = \(test3 ? "PASS" : "FAIL")")
        print("  - Pars: \(stats.pars) == \(expectedPars) = \(test4 ? "PASS" : "FAIL")")
        print("  - Bogeys: \(stats.bogeys) == \(expectedBogeys) = \(test5 ? "PASS" : "FAIL")")
        
        return test1 && test2 && test3 && test4 && test5
    }
    
    struct RoundStatistics {
        let totalScore: Int
        let toPar: Int
        let birdies: Int
        let pars: Int
        let bogeys: Int
        let bestHole: (hole: Int, score: Int)?
        let worstHole: (hole: Int, score: Int)?
    }
    
    func calculateRoundStatistics(scores: [Int], pars: [Int]) -> RoundStatistics {
        let totalScore = scores.reduce(0, +)
        let toPar = scores.enumerated().reduce(0) { $0 + ($1.element - pars[$1.offset]) }
        
        let birdies = scores.enumerated().filter { $0.element < pars[$0.offset] }.count
        let parCount = scores.enumerated().filter { $0.element == pars[$0.offset] }.count
        let bogeys = scores.enumerated().filter { $0.element == pars[$0.offset] + 1 }.count
        
        let bestHole = findBestHole(scores: scores, pars: pars)
        let worstHole = findWorstHole(scores: scores, pars: pars)
        
        return RoundStatistics(
            totalScore: totalScore,
            toPar: toPar,
            birdies: birdies,
            pars: parCount,
            bogeys: bogeys,
            bestHole: bestHole,
            worstHole: worstHole
        )
    }
    
    func findBestHole(scores: [Int], pars: [Int]) -> (hole: Int, score: Int)? {
        guard !scores.isEmpty else { return nil }
        let diffs = scores.enumerated().map { ($0.offset + 1, $0.element - pars[$0.offset]) }
        let best = diffs.min { $0.1 < $1.1 }
        if let best = best {
            return (best.0, scores[best.0 - 1])
        }
        return nil
    }
    
    func findWorstHole(scores: [Int], pars: [Int]) -> (hole: Int, score: Int)? {
        guard !scores.isEmpty else { return nil }
        let diffs = scores.enumerated().map { ($0.offset + 1, $0.element - pars[$0.offset]) }
        let worst = diffs.max { $0.1 < $1.1 }
        if let worst = worst {
            return (worst.0, scores[worst.0 - 1])
        }
        return nil
    }
    
    // MARK: - Visualization Data Tests
    
    func testVisualizationData() -> Bool {
        print("Testing Visualization Data Processing...")
        
        let scores = [4, 3, 5, 4, 6, 3, 4, 5, 4]
        let pars = [4, 4, 4, 4, 4, 4, 4, 4, 4]
        
        // Test cumulative differential calculation
        let cumulative = calculateCumulativeDifferential(scores: scores, pars: pars)
        
        let test1 = cumulative.count == scores.count
        let test2 = cumulative.last?.differential == 2 // +2 total
        
        print("  - Cumulative count: \(cumulative.count) == \(scores.count) = \(test1 ? "PASS" : "FAIL")")
        print("  - Final differential: \(cumulative.last?.differential ?? 0) == 2 = \(test2 ? "PASS" : "FAIL")")
        
        // Test emotion mapping
        let emotions = scores.enumerated().map { emotionForScore($0.element, par: pars[$0.offset]) }
        let hasValidEmotions = emotions.allSatisfy { !$0.emoji.isEmpty }
        
        print("  - Emotion mapping: Valid = \(hasValidEmotions ? "PASS" : "FAIL")")
        
        return test1 && test2 && hasValidEmotions
    }
    
    struct CumulativePoint {
        let hole: Int
        let differential: Int
    }
    
    func calculateCumulativeDifferential(scores: [Int], pars: [Int]) -> [CumulativePoint] {
        var result: [CumulativePoint] = []
        var cumulative = 0
        
        for (index, score) in scores.enumerated() {
            let par = pars[index]
            cumulative += score - par
            result.append(CumulativePoint(hole: index + 1, differential: cumulative))
        }
        
        return result
    }
    
    func emotionForScore(_ score: Int, par: Int) -> (emoji: String, color: String, intensity: Double) {
        let diff = score - par
        switch diff {
        case ..<(-1): return ("star.fill", "purple", 1.0)
        case -1: return ("star", "green", 0.8)
        case 0: return ("checkmark.circle", "blue", 0.6)
        case 1: return ("exclamationmark.triangle", "orange", 0.7)
        default: return ("xmark.circle", "red", 0.9)
        }
    }
    
    // MARK: - Heat Map Tests
    
    func testHeatMapCalculation() -> Bool {
        print("Testing Heat Map Calculation...")
        
        let rounds = createMockRounds()
        
        var allTests = true
        for hole in 1...18 {
            let intensity = calculateHeatMapIntensity(for: hole, rounds: rounds)
            let validRange = intensity >= 0.0 && intensity <= 1.0
            
            if !validRange {
                print("  - Hole \(hole): Intensity \(intensity) out of range = FAIL")
                allTests = false
            }
        }
        
        print("  - Heat map intensity range validation: \(allTests ? "PASS" : "FAIL")")
        
        return allTests
    }
    
    func calculateHeatMapIntensity(for hole: Int, rounds: [Round]) -> Double {
        var totalDiff = 0
        var count = 0
        
        for round in rounds {
            if let score = round.scores[hole] {
                totalDiff += score - 4 // Assuming par 4
                count += 1
            }
        }
        
        guard count > 0 else { return 0 }
        let avgDiff = Double(totalDiff) / Double(count)
        
        return max(0, min(1, (avgDiff + 2) / 4))
    }
    
    func createMockRounds() -> [Round] {
        var rounds: [Round] = []
        
        for i in 1...5 {
            var scores: [Int: Int] = [:]
            for hole in 1...18 {
                scores[hole] = Int.random(in: 3...6)
            }
            
            rounds.append(Round(
                course: "Test Course \(i)",
                players: ["Test Player"],
                scores: scores
            ))
        }
        
        return rounds
    }
    
    // MARK: - Performance Tests
    
    func testPerformance() -> Bool {
        print("Testing Performance...")
        
        let largeScoreSet = (1...1000).map { _ in Int.random(in: 3...7) }
        let largePars = Array(repeating: 4, count: 1000)
        
        let startTime = Date()
        
        // Test momentum calculation performance
        for _ in 1...1000 {
            _ = calculateMomentum(scores: Array(largeScoreSet.prefix(3)), handicap: 10)
        }
        
        let momentumTime = Date().timeIntervalSince(startTime)
        
        let cumulativeStart = Date()
        _ = calculateCumulativeDifferential(scores: largeScoreSet, pars: largePars)
        let cumulativeTime = Date().timeIntervalSince(cumulativeStart)
        
        let momentumTest = momentumTime < 1.0  // Should complete in under 1 second
        let cumulativeTest = cumulativeTime < 0.5  // Should complete in under 0.5 seconds
        
        print("  - Momentum calculation (1000x): \(String(format: "%.3f", momentumTime))s = \(momentumTest ? "PASS" : "FAIL")")
        print("  - Cumulative calculation (1000 holes): \(String(format: "%.3f", cumulativeTime))s = \(cumulativeTest ? "PASS" : "FAIL")")
        
        return momentumTest && cumulativeTest
    }
    
    // MARK: - Main Test Runner
    
    func runAllTests() {
        print("🏌️ Format Finder Statistics Validation")
        print("======================================")
        print()
        
        var passCount = 0
        var totalTests = 0
        
        let tests = [
            ("Momentum Calculation", testMomentumCalculation),
            ("Round Statistics", testRoundStatistics),
            ("Visualization Data", testVisualizationData),
            ("Heat Map Calculation", testHeatMapCalculation),
            ("Performance", testPerformance)
        ]
        
        for (testName, testFunction) in tests {
            totalTests += 1
            let result = testFunction()
            passCount += result ? 1 : 0
            
            print()
            print("\(testName): \(result ? "✅ PASS" : "❌ FAIL")")
            print("--------------------------------------")
        }
        
        print()
        print("Summary: \(passCount)/\(totalTests) tests passed")
        print("Overall: \(passCount == totalTests ? "✅ ALL TESTS PASSED" : "❌ SOME TESTS FAILED")")
        print()
        
        if passCount == totalTests {
            print("🎉 Statistics dashboard functionality is working correctly!")
        } else {
            print("⚠️ Some issues detected in statistics functionality.")
        }
    }
}

// MARK: - Run Tests

let validator = StatisticsValidator()
validator.runAllTests()