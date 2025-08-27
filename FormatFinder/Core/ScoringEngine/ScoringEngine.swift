import Foundation

// MARK: - Scoring Engine
/// Centralized scoring engine for all golf game formats
/// Provides pure functions for score calculations without any UI dependencies
public final class ScoringEngine {
    
    // MARK: - Par Estimation
    
    /// Estimates par for a hole based on distance
    /// - Parameter distance: Distance in yards
    /// - Returns: Estimated par value
    public static func estimatePar(forDistance distance: Double) -> Int {
        switch distance {
        case 0..<250:
            return 3
        case 250..<470:
            return 4
        default:
            return 5
        }
    }
    
    /// Estimates par for multiple holes
    /// - Parameter distances: Array of distances in yards
    /// - Returns: Array of estimated par values
    public static func estimatePars(forDistances distances: [Double]) -> [Int] {
        return distances.map { estimatePar(forDistance: $0) }
    }
    
    // MARK: - Scramble Scoring
    
    /// Represents a shot in scramble format
    public struct ScrambleShot {
        let playerId: String
        let playerName: String
        let shotNumber: Int
        let distance: Double
        let isSelected: Bool
    }
    
    /// Calculates scramble score from a series of shots
    /// - Parameters:
    ///   - shots: Array of scramble shots for a hole
    ///   - par: Par for the hole
    /// - Returns: Team score and selected shots
    public static func calculateScrambleScore(shots: [ScrambleShot], par: Int) -> (score: Int, selectedShots: [ScrambleShot]) {
        let selectedShots = shots.filter { $0.isSelected }
        let score = selectedShots.count
        return (score, selectedShots)
    }
    
    /// Calculates scramble score relative to par
    /// - Parameters:
    ///   - shots: Array of scramble shots
    ///   - par: Par for the hole
    /// - Returns: Score relative to par (negative is under par)
    public static func calculateScrambleScoreToPar(shots: [ScrambleShot], par: Int) -> Int {
        let (score, _) = calculateScrambleScore(shots: shots, par: par)
        return score - par
    }
    
    // MARK: - Match Play Scoring
    
    /// Represents match play status
    public enum MatchPlayStatus {
        case allSquare
        case up(player: String, holes: Int)
        case dormie(player: String)
        case won(player: String, margin: String)
        
        var displayText: String {
            switch self {
            case .allSquare:
                return "All Square"
            case .up(let player, let holes):
                return "\(player) \(holes) UP"
            case .dormie(let player):
                return "\(player) Dormie"
            case .won(let player, let margin):
                return "\(player) wins \(margin)"
            }
        }
    }
    
    /// Calculates match play status
    /// - Parameters:
    ///   - player1Scores: Array of scores for player 1
    ///   - player2Scores: Array of scores for player 2
    ///   - pars: Array of par values for each hole
    ///   - player1Name: Name of player 1
    ///   - player2Name: Name of player 2
    /// - Returns: Current match play status
    public static func calculateMatchPlayStatus(
        player1Scores: [Int],
        player2Scores: [Int],
        pars: [Int],
        player1Name: String,
        player2Name: String
    ) -> MatchPlayStatus {
        var player1Holes = 0
        var player2Holes = 0
        let holesPlayed = min(player1Scores.count, player2Scores.count)
        let holesRemaining = 18 - holesPlayed
        
        for i in 0..<holesPlayed {
            let p1Score = player1Scores[i]
            let p2Score = player2Scores[i]
            
            if p1Score < p2Score {
                player1Holes += 1
            } else if p2Score < p1Score {
                player2Holes += 1
            }
        }
        
        let difference = abs(player1Holes - player2Holes)
        
        // Check if match is over
        if difference > holesRemaining {
            let winner = player1Holes > player2Holes ? player1Name : player2Name
            let margin = "\(difference) & \(holesRemaining)"
            return .won(player: winner, margin: margin)
        }
        
        // Check for dormie
        if difference == holesRemaining && holesRemaining > 0 {
            let leader = player1Holes > player2Holes ? player1Name : player2Name
            return .dormie(player: leader)
        }
        
        // Check who's up
        if difference > 0 {
            let leader = player1Holes > player2Holes ? player1Name : player2Name
            return .up(player: leader, holes: difference)
        }
        
        return .allSquare
    }
    
    // MARK: - Skins Scoring
    
    /// Represents a skin result for a hole
    public struct SkinResult {
        let holeNumber: Int
        let winner: String?
        let value: Int
        let carryOver: Int
    }
    
    /// Calculates skins for a series of holes
    /// - Parameters:
    ///   - scores: Dictionary of player names to their scores for each hole
    ///   - skinValue: Base value of each skin
    /// - Returns: Array of skin results for each hole
    public static func calculateSkins(scores: [String: [Int]], skinValue: Int = 1) -> [SkinResult] {
        guard let firstPlayer = scores.keys.first,
              let holeCount = scores[firstPlayer]?.count else {
            return []
        }
        
        var results: [SkinResult] = []
        var carryOver = 0
        
        for hole in 0..<holeCount {
            var holeScores: [(player: String, score: Int)] = []
            
            for (player, playerScores) in scores {
                if hole < playerScores.count {
                    holeScores.append((player: player, score: playerScores[hole]))
                }
            }
            
            // Find the minimum score
            let minScore = holeScores.map { $0.score }.min() ?? 0
            let winners = holeScores.filter { $0.score == minScore }
            
            if winners.count == 1 {
                // Single winner takes the skin plus any carryover
                let winner = winners[0].player
                let totalValue = skinValue + carryOver
                results.append(SkinResult(
                    holeNumber: hole + 1,
                    winner: winner,
                    value: totalValue,
                    carryOver: 0
                ))
                carryOver = 0
            } else {
                // Tie - skin carries over
                carryOver += skinValue
                results.append(SkinResult(
                    holeNumber: hole + 1,
                    winner: nil,
                    value: 0,
                    carryOver: carryOver
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Nassau Scoring
    
    /// Represents Nassau match results
    public struct NassauResult {
        let frontNine: MatchResult
        let backNine: MatchResult
        let overall: MatchResult
        let totalPoints: [String: Int]
        
        public struct MatchResult {
            let winner: String?
            let margin: Int
            let points: [String: Int]
        }
    }
    
    /// Calculates Nassau points for a match
    /// - Parameters:
    ///   - scores: Dictionary of player names to their 18-hole scores
    ///   - pointsPerMatch: Points awarded for each match (front, back, overall)
    /// - Returns: Nassau result with points for each segment
    public static func calculateNassau(
        scores: [String: [Int]],
        pointsPerMatch: Int = 1
    ) -> NassauResult {
        guard scores.keys.count >= 2 else {
            return NassauResult(
                frontNine: NassauResult.MatchResult(winner: nil, margin: 0, points: [:]),
                backNine: NassauResult.MatchResult(winner: nil, margin: 0, points: [:]),
                overall: NassauResult.MatchResult(winner: nil, margin: 0, points: [:]),
                totalPoints: [:]
            )
        }
        
        var frontNineScores: [String: Int] = [:]
        var backNineScores: [String: Int] = [:]
        var totalScores: [String: Int] = [:]
        
        for (player, playerScores) in scores {
            // Calculate front nine (holes 1-9)
            let frontNine = playerScores.prefix(9).reduce(0, +)
            frontNineScores[player] = frontNine
            
            // Calculate back nine (holes 10-18)
            let backNine = playerScores.dropFirst(9).prefix(9).reduce(0, +)
            backNineScores[player] = backNine
            
            // Calculate total
            totalScores[player] = frontNine + backNine
        }
        
        // Determine winners
        let frontResult = determineWinner(scores: frontNineScores, points: pointsPerMatch)
        let backResult = determineWinner(scores: backNineScores, points: pointsPerMatch)
        let overallResult = determineWinner(scores: totalScores, points: pointsPerMatch)
        
        // Calculate total points
        var totalPoints: [String: Int] = [:]
        for player in scores.keys {
            let front = frontResult.points[player] ?? 0
            let back = backResult.points[player] ?? 0
            let overall = overallResult.points[player] ?? 0
            totalPoints[player] = front + back + overall
        }
        
        return NassauResult(
            frontNine: frontResult,
            backNine: backResult,
            overall: overallResult,
            totalPoints: totalPoints
        )
    }
    
    /// Helper function to determine winner and points
    private static func determineWinner(scores: [String: Int], points: Int) -> NassauResult.MatchResult {
        guard scores.count >= 2 else {
            return NassauResult.MatchResult(winner: nil, margin: 0, points: [:])
        }
        
        let sortedScores = scores.sorted { $0.value < $1.value }
        let lowestScore = sortedScores[0].value
        let winners = scores.filter { $0.value == lowestScore }
        
        var matchPoints: [String: Int] = [:]
        
        if winners.count == 1 {
            // Single winner
            let winner = winners.keys.first!
            let margin = sortedScores[1].value - lowestScore
            matchPoints[winner] = points
            return NassauResult.MatchResult(winner: winner, margin: margin, points: matchPoints)
        } else {
            // Tie - split points
            let splitPoints = Double(points) / Double(winners.count)
            for winner in winners.keys {
                matchPoints[winner] = Int(splitPoints.rounded())
            }
            return NassauResult.MatchResult(winner: nil, margin: 0, points: matchPoints)
        }
    }
    
    // MARK: - Stableford Scoring
    
    /// Calculates Stableford points for a score
    /// - Parameters:
    ///   - score: Player's score for the hole
    ///   - par: Par for the hole
    ///   - handicapStrokes: Handicap strokes for the hole (0 if no handicap)
    /// - Returns: Stableford points
    public static func calculateStablefordPoints(score: Int, par: Int, handicapStrokes: Int = 0) -> Int {
        let adjustedScore = score - handicapStrokes
        let scoreToPar = adjustedScore - par
        
        switch scoreToPar {
        case ...(-3): return 5 // Albatross or better
        case -2: return 4 // Eagle
        case -1: return 3 // Birdie
        case 0: return 2 // Par
        case 1: return 1 // Bogey
        default: return 0 // Double bogey or worse
        }
    }
    
    /// Calculates total Stableford points for a round
    /// - Parameters:
    ///   - scores: Array of scores for each hole
    ///   - pars: Array of par values for each hole
    ///   - handicapStrokes: Array of handicap strokes for each hole (empty if no handicap)
    /// - Returns: Total Stableford points
    public static func calculateTotalStableford(
        scores: [Int],
        pars: [Int],
        handicapStrokes: [Int] = []
    ) -> Int {
        var totalPoints = 0
        for i in 0..<min(scores.count, pars.count) {
            let handicap = i < handicapStrokes.count ? handicapStrokes[i] : 0
            totalPoints += calculateStablefordPoints(score: scores[i], par: pars[i], handicapStrokes: handicap)
        }
        return totalPoints
    }
    
    // MARK: - Stroke Play Scoring
    
    /// Calculates gross and net scores
    /// - Parameters:
    ///   - scores: Array of scores for each hole
    ///   - handicap: Player's handicap
    /// - Returns: Tuple of (gross score, net score)
    public static func calculateStrokePlayScore(scores: [Int], handicap: Int) -> (gross: Int, net: Int) {
        let gross = scores.reduce(0, +)
        let net = gross - handicap
        return (gross, net)
    }
    
    /// Formats score relative to par
    /// - Parameters:
    ///   - score: Total score
    ///   - par: Total par for the course
    /// - Returns: Formatted string (e.g., "-3", "E", "+5")
    public static func formatScoreToPar(score: Int, par: Int) -> String {
        let difference = score - par
        if difference == 0 {
            return "E"
        } else if difference > 0 {
            return "+\(difference)"
        } else {
            return "\(difference)"
        }
    }
}

// MARK: - Score Validation

extension ScoringEngine {
    
    /// Validates if a score is reasonable for golf
    /// - Parameter score: Score to validate
    /// - Returns: True if score is valid
    public static func isValidScore(_ score: Int) -> Bool {
        return score >= 1 && score <= 20
    }
    
    /// Validates an array of scores
    /// - Parameter scores: Array of scores to validate
    /// - Returns: True if all scores are valid
    public static func areValidScores(_ scores: [Int]) -> Bool {
        return scores.allSatisfy { isValidScore($0) }
    }
}