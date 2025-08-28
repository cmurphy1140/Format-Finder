import Foundation

// MARK: - Scramble Format Implementation

final class ScrambleFormat: TeamFormatProtocol {
    
    var formatType: FormatType { .scramble }
    
    var scoringRules: ProtocolScoringRules {
        ProtocolScoringRules(
            maxScore: 10,
            allowNegative: false,
            useHandicaps: true,
            teamPlay: true
        )
    }
    
    private var ballSelections: [Int: PlayerIdentifier] = [:]
    private var shotTypeSelections: [Int: [ShotType: PlayerIdentifier]] = [:]
    
    func calculateScore(for hole: Int, scores: [GamePlayerScore]) -> FormatScore {
        let teamScore = calculateTeamScore(scores: scores)
        let bestPlayer = selectBestBall(scores: scores)
        
        return FormatScore(
            grossScore: teamScore,
            netScore: applyTeamHandicap(teamScore, scores: scores),
            points: nil,
            winner: nil,
            metadata: [
                "selectedPlayer": bestPlayer,
                "shotBreakdown": getShotBreakdown(for: hole)
            ]
        )
    }
    
    func selectBestBall(scores: [GamePlayerScore]) -> PlayerIdentifier {
        guard let bestScore = scores.min(by: { $0.netScore < $1.netScore }) else {
            fatalError("No scores provided for best ball selection")
        }
        return bestScore.playerId
    }
    
    func calculateTeamScore(scores: [GamePlayerScore]) -> Int {
        // In scramble, team takes best shot and everyone plays from there
        // Return the best score among all players
        return scores.map { $0.strokes }.min() ?? 0
    }
    
    func determineWinner(scores: [GamePlayerScore]) -> PlayerIdentifier? {
        // Scramble is a team format, return nil for individual winner
        return nil
    }
    
    func validateScore(_ score: Int, for player: PlayerIdentifier, hole: Int) -> Bool {
        guard score > 0 && score <= scoringRules.maxScore else { return false }
        
        // Additional scramble-specific validation
        if let previousScore = getPreviousScore(for: player, hole: hole) {
            // Can't have wildly different scores in scramble
            return abs(score - previousScore) <= 2
        }
        
        return true
    }
    
    func applyHandicap(_ score: Int, handicap: Int, hole: Int) -> Int {
        // Apply handicap strokes based on hole difficulty
        let strokesReceived = calculateHandicapStrokes(handicap: handicap, hole: hole)
        return max(score - strokesReceived, 1)
    }
    
    func getRoundSummary(scores: [Int: [PlayerIdentifier: Int]]) -> RoundSummary {
        var totalStrokes = 0
        var holesWon = 0
        var highlights: [String] = []
        
        for (hole, playerScores) in scores {
            if let teamScore = playerScores.values.min() {
                totalStrokes += teamScore
                
                if teamScore <= getParForHole(hole) - 1 {
                    highlights.append("Birdie on hole \(hole)")
                    holesWon += 1
                }
            }
        }
        
        let stats = RoundStatistics(
            totalStrokes: totalStrokes,
            birdies: holesWon,
            pars: scores.count - holesWon,
            bogeys: 0,
            averageScore: Double(totalStrokes) / Double(scores.count),
            bestHole: nil,
            worstHole: nil
        )
        
        return RoundSummary(
            winner: nil, // Team format
            finalScores: [:],
            highlights: highlights,
            statistics: stats
        )
    }
    
    // MARK: - Scramble-Specific Methods
    
    func recordBallSelection(hole: Int, player: PlayerIdentifier, shotType: ShotType) {
        ballSelections[hole] = player
        
        if shotTypeSelections[hole] == nil {
            shotTypeSelections[hole] = [:]
        }
        shotTypeSelections[hole]?[shotType] = player
    }
    
    func getBallSelection(for hole: Int) -> PlayerIdentifier? {
        return ballSelections[hole]
    }
    
    func getShotBreakdown(for hole: Int) -> [String: String] {
        guard let selections = shotTypeSelections[hole] else { return [:] }
        
        var breakdown: [String: String] = [:]
        for (shotType, player) in selections {
            breakdown[shotType.rawValue] = player.name
        }
        return breakdown
    }
    
    // MARK: - Helper Methods
    
    private func calculateHandicapStrokes(handicap: Int, hole: Int) -> Int {
        // Simplified handicap calculation
        let holeHandicap = getHoleHandicap(hole)
        return handicap >= holeHandicap ? 1 : 0
    }
    
    private func getHoleHandicap(_ hole: Int) -> Int {
        // Mock hole handicap - would come from course data
        return ((hole - 1) % 18) + 1
    }
    
    private func getParForHole(_ hole: Int) -> Int {
        // Use standard pars until centralized system is properly integrated
        let standardPars = [4, 4, 3, 5, 4, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5]
        return standardPars[(hole - 1) % 18]
    }
    
    private func getPreviousScore(for player: PlayerIdentifier, hole: Int) -> Int? {
        // Would retrieve from persistence layer
        return nil
    }
    
    private func applyTeamHandicap(_ score: Int, scores: [GamePlayerScore]) -> Int {
        let averageHandicap = scores.map { $0.handicapStrokes }.reduce(0, +) / scores.count
        return score - averageHandicap
    }
}

// MARK: - Supporting Types
// ShotType is defined in GolfFormatProtocol.swift