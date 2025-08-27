import Foundation

// MARK: - Statistics Manager
/// Manages golf statistics and provides analytical insights
public final class StatisticsManager {
    
    // MARK: - Data Models
    
    /// Represents a player's round for statistical analysis
    public struct RoundData {
        let id: String
        let playerId: String
        let date: Date
        let courseId: String
        let scores: [Int]
        let pars: [Int]
        let distances: [Double]?
        let handicap: Int?
        
        /// Calculate total score relative to par
        var scoreToPar: Int {
            let totalScore = scores.reduce(0, +)
            let totalPar = pars.reduce(0, +)
            return totalScore - totalPar
        }
        
        /// Calculate gross score
        var grossScore: Int {
            return scores.reduce(0, +)
        }
        
        /// Calculate net score if handicap available
        var netScore: Int? {
            guard let handicap = handicap else { return nil }
            return grossScore - handicap
        }
    }
    
    /// Statistical analysis result for a player
    public struct PlayerStatistics {
        let playerId: String
        let averageScoreToPar: Double
        let averageGross: Double
        let averageNet: Double?
        let scoringTrend: ScoringTrend
        let troubleHoles: [HolePerformance]
        let goodHoles: [HolePerformance]
        let consistencyRating: Double
        let roundsAnalyzed: Int
    }
    
    /// Represents scoring trend over time
    public enum ScoringTrend {
        case improving(percentageChange: Double)
        case steady
        case declining(percentageChange: Double)
        
        var description: String {
            switch self {
            case .improving(let change):
                return String(format: "Improving (%.1f%% better)", abs(change))
            case .steady:
                return "Steady"
            case .declining(let change):
                return String(format: "Declining (%.1f%% worse)", change)
            }
        }
    }
    
    /// Performance data for a specific hole
    public struct HolePerformance {
        let holeNumber: Int
        let averageScore: Double
        let averageScoreToPar: Double
        let par: Int
        let timesPlayed: Int
        let birdieRate: Double
        let parRate: Double
        let bogeyRate: Double
    }
    
    /// Format recommendation based on player statistics
    public struct FormatRecommendation {
        let format: String
        let confidence: Double
        let reasoning: String
    }
    
    // MARK: - Par-Based Averaging
    
    /// Calculate average score relative to par
    /// - Parameter rounds: Array of round data
    /// - Returns: Average score to par (negative is under par)
    public static func calculateAverageScoreToPar(rounds: [RoundData]) -> Double {
        guard !rounds.isEmpty else { return 0 }
        
        let totalScoreToPar = rounds.reduce(0) { $0 + $1.scoreToPar }
        return Double(totalScoreToPar) / Double(rounds.count)
    }
    
    /// Calculate average gross score
    /// - Parameter rounds: Array of round data
    /// - Returns: Average gross score
    public static func calculateAverageGross(rounds: [RoundData]) -> Double {
        guard !rounds.isEmpty else { return 0 }
        
        let totalGross = rounds.reduce(0) { $0 + $1.grossScore }
        return Double(totalGross) / Double(rounds.count)
    }
    
    /// Calculate average net score
    /// - Parameter rounds: Array of round data
    /// - Returns: Average net score if handicap data available
    public static func calculateAverageNet(rounds: [RoundData]) -> Double? {
        let roundsWithHandicap = rounds.compactMap { round -> Int? in
            return round.netScore
        }
        
        guard !roundsWithHandicap.isEmpty else { return nil }
        
        let totalNet = roundsWithHandicap.reduce(0, +)
        return Double(totalNet) / Double(roundsWithHandicap.count)
    }
    
    // MARK: - Scoring Trends
    
    /// Analyze scoring trend over recent rounds
    /// - Parameter rounds: Array of round data (should be sorted by date)
    /// - Returns: Scoring trend analysis
    public static func analyzeScoringTrend(rounds: [RoundData]) -> ScoringTrend {
        guard rounds.count >= GolfConstants.Statistics.minimumRoundsForTrend else {
            return .steady
        }
        
        // Get recent rounds window
        let recentCount = min(rounds.count, GolfConstants.Statistics.recentRoundsWindow)
        let halfPoint = recentCount / 2
        
        let recentRounds = Array(rounds.suffix(recentCount))
        let firstHalf = Array(recentRounds.prefix(halfPoint))
        let secondHalf = Array(recentRounds.suffix(recentCount - halfPoint))
        
        let firstHalfAverage = calculateAverageScoreToPar(rounds: firstHalf)
        let secondHalfAverage = calculateAverageScoreToPar(rounds: secondHalf)
        
        guard firstHalfAverage != 0 else {
            return secondHalfAverage < 0 ? .improving(percentageChange: abs(secondHalfAverage)) : .steady
        }
        
        let percentageChange = ((secondHalfAverage - firstHalfAverage) / abs(firstHalfAverage)) * 100
        
        if percentageChange <= GolfConstants.Statistics.improvingTrendThreshold {
            return .improving(percentageChange: abs(percentageChange))
        } else if percentageChange >= GolfConstants.Statistics.decliningTrendThreshold {
            return .declining(percentageChange: percentageChange)
        } else {
            return .steady
        }
    }
    
    // MARK: - Hole Performance
    
    /// Analyze performance on individual holes
    /// - Parameter rounds: Array of round data
    /// - Returns: Array of hole performance data
    public static func analyzeHolePerformance(rounds: [RoundData]) -> [HolePerformance] {
        var holeData: [Int: (scores: [Int], pars: [Int])] = [:]
        
        // Collect scores for each hole
        for round in rounds {
            for (index, score) in round.scores.enumerated() {
                let holeNumber = index + 1
                if index < round.pars.count {
                    if holeData[holeNumber] == nil {
                        holeData[holeNumber] = (scores: [], pars: [])
                    }
                    holeData[holeNumber]?.scores.append(score)
                    holeData[holeNumber]?.pars.append(round.pars[index])
                }
            }
        }
        
        // Calculate statistics for each hole
        var performances: [HolePerformance] = []
        
        for (holeNumber, data) in holeData {
            guard !data.scores.isEmpty,
                  let firstPar = data.pars.first else { continue }
            
            let averageScore = Double(data.scores.reduce(0, +)) / Double(data.scores.count)
            let averageScoreToPar = averageScore - Double(firstPar)
            
            // Calculate scoring distribution
            var birdies = 0
            var pars = 0
            var bogeys = 0
            
            for (score, par) in zip(data.scores, data.pars) {
                let scoreToPar = score - par
                if scoreToPar <= -1 {
                    birdies += 1
                } else if scoreToPar == 0 {
                    pars += 1
                } else if scoreToPar == 1 {
                    bogeys += 1
                }
            }
            
            let timesPlayed = data.scores.count
            let birdieRate = Double(birdies) / Double(timesPlayed)
            let parRate = Double(pars) / Double(timesPlayed)
            let bogeyRate = Double(bogeys) / Double(timesPlayed)
            
            performances.append(HolePerformance(
                holeNumber: holeNumber,
                averageScore: averageScore,
                averageScoreToPar: averageScoreToPar,
                par: firstPar,
                timesPlayed: timesPlayed,
                birdieRate: birdieRate,
                parRate: parRate,
                bogeyRate: bogeyRate
            ))
        }
        
        return performances.sorted { $0.holeNumber < $1.holeNumber }
    }
    
    /// Identify trouble holes (holes where player struggles)
    /// - Parameter holePerformances: Array of hole performance data
    /// - Returns: Array of trouble holes
    public static func identifyTroubleHoles(_ holePerformances: [HolePerformance]) -> [HolePerformance] {
        return holePerformances.filter { hole in
            hole.timesPlayed >= GolfConstants.Statistics.minimumPlaysForTroubleHole &&
            hole.averageScoreToPar >= GolfConstants.Statistics.troubleHoleThreshold
        }.sorted { $0.averageScoreToPar > $1.averageScoreToPar }
    }
    
    /// Identify good holes (holes where player excels)
    /// - Parameter holePerformances: Array of hole performance data
    /// - Returns: Array of good holes
    public static func identifyGoodHoles(_ holePerformances: [HolePerformance]) -> [HolePerformance] {
        return holePerformances.filter { hole in
            hole.timesPlayed >= GolfConstants.Statistics.minimumPlaysForTroubleHole &&
            hole.averageScoreToPar <= GolfConstants.Statistics.goodHoleThreshold
        }.sorted { $0.averageScoreToPar < $1.averageScoreToPar }
    }
    
    // MARK: - Format Recommendations
    
    /// Recommend game formats based on player statistics and preferences
    /// - Parameters:
    ///   - playerStats: Array of player statistics
    ///   - playerCount: Number of players
    ///   - skillVariance: Variance in skill levels (handicap difference)
    /// - Returns: Array of format recommendations sorted by confidence
    public static func recommendFormats(
        playerStats: [PlayerStatistics],
        playerCount: Int,
        skillVariance: Int
    ) -> [FormatRecommendation] {
        var recommendations: [FormatRecommendation] = []
        
        // Scramble recommendation
        if playerCount >= GolfConstants.GameFormats.scrambleMinPlayers &&
           playerCount <= GolfConstants.GameFormats.scrambleMaxPlayers {
            if skillVariance >= GolfConstants.HandicapRecommendations.scrambleRecommendedDifference {
                recommendations.append(FormatRecommendation(
                    format: "Scramble",
                    confidence: 0.9,
                    reasoning: "High skill variance makes scramble ideal for balanced competition"
                ))
            } else if playerCount > 2 {
                recommendations.append(FormatRecommendation(
                    format: "Scramble",
                    confidence: 0.6,
                    reasoning: "Good for team building and fun with \(playerCount) players"
                ))
            }
        }
        
        // Match Play recommendation
        if playerCount == GolfConstants.GameFormats.matchPlayMaxPlayers {
            if skillVariance <= GolfConstants.HandicapRecommendations.matchPlayMaxDifference {
                recommendations.append(FormatRecommendation(
                    format: "Match Play",
                    confidence: 0.85,
                    reasoning: "Similar skill levels make for competitive match play"
                ))
            } else {
                recommendations.append(FormatRecommendation(
                    format: "Match Play",
                    confidence: 0.5,
                    reasoning: "Can use handicaps to balance match play competition"
                ))
            }
        }
        
        // Best Ball recommendation
        if playerCount >= 2 && playerCount <= 4 {
            if skillVariance >= GolfConstants.HandicapRecommendations.bestBallRecommendedDifference {
                recommendations.append(FormatRecommendation(
                    format: "Best Ball",
                    confidence: 0.8,
                    reasoning: "Allows individual play while supporting teammates"
                ))
            } else {
                recommendations.append(FormatRecommendation(
                    format: "Best Ball",
                    confidence: 0.65,
                    reasoning: "Fun team format with individual scoring"
                ))
            }
        }
        
        // Skins recommendation
        if playerCount >= 2 {
            let avgConsistency = playerStats.reduce(0.0) { $0 + $1.consistencyRating } / Double(playerStats.count)
            if avgConsistency > 0.7 {
                recommendations.append(FormatRecommendation(
                    format: "Skins",
                    confidence: 0.75,
                    reasoning: "Consistent players make skins exciting with close competition"
                ))
            } else {
                recommendations.append(FormatRecommendation(
                    format: "Skins",
                    confidence: 0.6,
                    reasoning: "Adds excitement with potential for big swings"
                ))
            }
        }
        
        // Nassau recommendation
        if playerCount >= 2 && playerCount <= 4 {
            recommendations.append(FormatRecommendation(
                format: "Nassau",
                confidence: 0.7,
                reasoning: "Classic format with three separate competitions"
            ))
        }
        
        // Stableford recommendation
        let avgScoreToPar = playerStats.reduce(0.0) { $0 + $1.averageScoreToPar } / Double(playerStats.count)
        if avgScoreToPar > 5 {
            recommendations.append(FormatRecommendation(
                format: "Stableford",
                confidence: 0.8,
                reasoning: "Points system rewards good holes and minimizes impact of bad holes"
            ))
        } else {
            recommendations.append(FormatRecommendation(
                format: "Stableford",
                confidence: 0.5,
                reasoning: "Alternative scoring system for variety"
            ))
        }
        
        // Stroke Play recommendation (always available)
        recommendations.append(FormatRecommendation(
            format: "Stroke Play",
            confidence: 0.65,
            reasoning: "Traditional format suitable for all skill levels"
        ))
        
        return recommendations.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Consistency Rating
    
    /// Calculate consistency rating based on scoring variance
    /// - Parameter rounds: Array of round data
    /// - Returns: Consistency rating from 0 (inconsistent) to 1 (very consistent)
    public static func calculateConsistencyRating(rounds: [RoundData]) -> Double {
        guard rounds.count >= 2 else { return 0.5 }
        
        let scoresToPar = rounds.map { Double($0.scoreToPar) }
        let mean = scoresToPar.reduce(0, +) / Double(scoresToPar.count)
        
        let squaredDifferences = scoresToPar.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)
        let standardDeviation = sqrt(variance)
        
        // Convert to 0-1 rating (lower std dev = higher consistency)
        // Assume 10 strokes std dev is very inconsistent
        let maxExpectedStdDev = 10.0
        let consistencyRating = max(0, min(1, 1 - (standardDeviation / maxExpectedStdDev)))
        
        return consistencyRating
    }
    
    // MARK: - Complete Player Analysis
    
    /// Generate complete statistical analysis for a player
    /// - Parameter rounds: Array of round data for the player
    /// - Returns: Complete player statistics
    public static func analyzePlayer(playerId: String, rounds: [RoundData]) -> PlayerStatistics? {
        guard !rounds.isEmpty else { return nil }
        
        let averageScoreToPar = calculateAverageScoreToPar(rounds: rounds)
        let averageGross = calculateAverageGross(rounds: rounds)
        let averageNet = calculateAverageNet(rounds: rounds)
        let scoringTrend = analyzeScoringTrend(rounds: rounds)
        
        let holePerformances = analyzeHolePerformance(rounds: rounds)
        let troubleHoles = identifyTroubleHoles(holePerformances)
        let goodHoles = identifyGoodHoles(holePerformances)
        
        let consistencyRating = calculateConsistencyRating(rounds: rounds)
        
        return PlayerStatistics(
            playerId: playerId,
            averageScoreToPar: averageScoreToPar,
            averageGross: averageGross,
            averageNet: averageNet,
            scoringTrend: scoringTrend,
            troubleHoles: troubleHoles,
            goodHoles: goodHoles,
            consistencyRating: consistencyRating,
            roundsAnalyzed: rounds.count
        )
    }
}