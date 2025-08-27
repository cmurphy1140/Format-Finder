import Foundation

// MARK: - Core Protocols

protocol GolfFormatProtocol {
    var formatType: FormatType { get }
    var scoringRules: ProtocolScoringRules { get }
    
    func calculateScore(for hole: Int, scores: [GamePlayerScore]) -> FormatScore
    func determineWinner(scores: [GamePlayerScore]) -> PlayerIdentifier?
    func validateScore(_ score: Int, for player: PlayerIdentifier, hole: Int) -> Bool
    func applyHandicap(_ score: Int, handicap: Int, hole: Int) -> Int
    func getRoundSummary(scores: [Int: [PlayerIdentifier: Int]]) -> RoundSummary
}

protocol TeamFormatProtocol: GolfFormatProtocol {
    func selectBestBall(scores: [GamePlayerScore]) -> PlayerIdentifier
    func calculateTeamScore(scores: [GamePlayerScore]) -> Int
}

protocol MatchFormatProtocol: GolfFormatProtocol {
    func determineHoleWinner(scores: [GamePlayerScore]) -> PlayerIdentifier?
    func updateMatchStatus(after hole: Int, scores: [GamePlayerScore]) -> SimpleMatchStatus
    func canConcede(at hole: Int, currentStatus: SimpleMatchStatus) -> Bool
}

protocol BettingFormatProtocol: GolfFormatProtocol {
    func calculatePayout(for hole: Int, winner: PlayerIdentifier?) -> Double
    func handleCarryover(from previousHole: Int) -> Double
    func validateBet(amount: Double) -> Bool
}

// MARK: - Data Models

enum FormatType: String, CaseIterable {
    case scramble = "Scramble"
    case bestBall = "Best Ball"
    case matchPlay = "Match Play"
    case skins = "Skins"
    case stableford = "Stableford"
    case fourBall = "Four-Ball"
    case alternateShot = "Alternate Shot"
    case nassau = "Nassau"
    case bingoBangoBongo = "Bingo Bango Bongo"
    case wolf = "Wolf"
    case chapman = "Chapman"
    case vegas = "Vegas"
}

struct GamePlayerScore {
    let playerId: PlayerIdentifier
    let strokes: Int
    let handicapStrokes: Int
    let metadata: [String: Any]?
    
    var netScore: Int {
        strokes - handicapStrokes
    }
}

struct FormatScore {
    let grossScore: Int
    let netScore: Int
    let points: Int?
    let winner: PlayerIdentifier?
    let metadata: [String: Any]?
}

struct PlayerIdentifier: Hashable, Codable {
    let id: UUID
    let name: String
    let handicap: Int
}

struct RoundSummary {
    let winner: PlayerIdentifier?
    let finalScores: [PlayerIdentifier: Int]
    let highlights: [String]
    let statistics: RoundStatistics
}

struct RoundStatistics: Codable {
    let totalStrokes: Int
    let birdies: Int
    let pars: Int
    let bogeys: Int
    let averageScore: Double
    let bestHole: Int?
    let worstHole: Int?
}

struct ProtocolScoringRules {
    let maxScore: Int
    let allowNegative: Bool
    let useHandicaps: Bool
    let teamPlay: Bool
}

struct SimpleMatchStatus {
    let leader: PlayerIdentifier?
    let holesUp: Int
    let isComplete: Bool
}

enum ShotType: String, CaseIterable {
    case tee = "Tee Shot"
    case fairway = "Fairway"
    case approach = "Approach"
    case chip = "Chip"
    case putt = "Putt"
}