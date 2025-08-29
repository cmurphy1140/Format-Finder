import Foundation
import SwiftUI

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: String
    var name: String
    var email: String?
    var handicap: Int?
    var favoriteFormatIds: [String]
    var profileImageUrl: String?
    var memberSince: Date
    var stats: QuickStats?
    
    struct QuickStats: Codable {
        var totalRounds: Int
        var averageScore: Double
        var bestScore: Int?
        var favoriteFormat: String?
    }
    
    static var sample: UserProfile {
        UserProfile(
            id: UUID().uuidString,
            name: "John Doe",
            email: "john@example.com",
            handicap: 15,
            favoriteFormatIds: ["scramble", "bestball"],
            profileImageUrl: nil,
            memberSince: Date(),
            stats: QuickStats(
                totalRounds: 42,
                averageScore: 85.5,
                bestScore: 78,
                favoriteFormat: "Scramble"
            )
        )
    }
}

// MARK: - Player
struct Player: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var handicap: Int?
    var color: PlayerColor
    var isGuest: Bool
    
    enum PlayerColor: String, Codable, CaseIterable {
        case blue, green, red, yellow, purple, orange
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .green: return .green
            case .red: return .red
            case .yellow: return .yellow
            case .purple: return .purple
            case .orange: return .orange
            }
        }
    }
    
    static func guest(name: String, color: PlayerColor) -> Player {
        Player(
            id: UUID().uuidString,
            name: name,
            handicap: nil,
            color: color,
            isGuest: true
        )
    }
}

// MARK: - Game Session
class GameSession: ObservableObject, Codable, Identifiable {
    let id: String
    let format: GolfFormat
    @Published var players: [Player]
    @Published var startTime: Date
    var endTime: Date?
    let courseId: String?
    
    @Published var scores: [HoleScore] = []
    @Published var currentHole: Int = 1
    var finalScores: FinalScores?
    
    enum CodingKeys: CodingKey {
        case id, format, players, startTime, endTime, courseId, scores, currentHole, finalScores
    }
    
    init(id: String, format: GolfFormat, players: [Player], startTime: Date, courseId: String?) {
        self.id = id
        self.format = format
        self.players = players
        self.startTime = startTime
        self.courseId = courseId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        format = try container.decode(GolfFormat.self, forKey: .format)
        players = try container.decode([Player].self, forKey: .players)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        courseId = try container.decodeIfPresent(String.self, forKey: .courseId)
        scores = try container.decode([HoleScore].self, forKey: .scores)
        currentHole = try container.decode(Int.self, forKey: .currentHole)
        finalScores = try container.decodeIfPresent(FinalScores.self, forKey: .finalScores)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(format, forKey: .format)
        try container.encode(players, forKey: .players)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(courseId, forKey: .courseId)
        try container.encode(scores, forKey: .scores)
        try container.encode(currentHole, forKey: .currentHole)
        try container.encode(finalScores, forKey: .finalScores)
    }
    
    var isComplete: Bool {
        currentHole > 18 || endTime != nil
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

// MARK: - Hole Score
struct HoleScore: Codable, Identifiable {
    let id = UUID().uuidString
    let hole: Int
    let playerId: String
    let strokes: Int
    let timestamp: Date
    var putts: Int?
    var fairwayHit: Bool?
    var greenInRegulation: Bool?
}

// MARK: - Final Scores
struct FinalScores: Codable {
    let scores: [PlayerScore]
    let winner: String?
    let formatSpecificData: [String: Any]?
    
    struct PlayerScore: Codable, Identifiable {
        let id = UUID().uuidString
        let playerId: String
        let playerName: String
        let totalStrokes: Int
        let netScore: Int?
        let points: Int?
        let position: Int
    }
    
    enum CodingKeys: CodingKey {
        case scores, winner
    }
    
    init(scores: [PlayerScore], winner: String?) {
        self.scores = scores
        self.winner = winner
        self.formatSpecificData = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scores = try container.decode([PlayerScore].self, forKey: .scores)
        winner = try container.decodeIfPresent(String.self, forKey: .winner)
        formatSpecificData = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scores, forKey: .scores)
        try container.encode(winner, forKey: .winner)
    }
}

// MARK: - Round Data
struct RoundData: Codable {
    let id: String
    let date: Date
    let courseId: String
    let formatId: String
    let players: [Player]
    let scores: [HoleScore]
    let weather: WeatherConditions?
    let notes: String?
}

// MARK: - Weather Conditions
struct WeatherConditions: Codable {
    let temperature: Double
    let windSpeed: Double
    let windDirection: String
    let conditions: String
}

// MARK: - Player Statistics
class PlayerStatistics: ObservableObject, Codable {
    @Published var playerId: String
    @Published var roundsPlayed: Int = 0
    @Published var scoringAverage: Double = 0
    @Published var bestScore: Int?
    @Published var handicap: Double = 0
    @Published var formatStats: [String: FormatStatistics] = [:]
    @Published var courseStats: [String: CourseStatistics] = [:]
    
    init(playerId: String) {
        self.playerId = playerId
    }
}

// MARK: - Format Statistics
struct FormatStatistics: Codable {
    var gamesPlayed: Int = 0
    var wins: Int = 0
    var averageScore: Double = 0
    var bestScore: Int?
}

// MARK: - Course Statistics
struct CourseStatistics: Codable {
    var roundsPlayed: Int = 0
    var averageScore: Double = 0
    var bestScore: Int?
    var scoring: [Int: HoleStatistics] = [:] // Hole number to stats
}

// MARK: - Hole Statistics
struct HoleStatistics: Codable {
    var averageScore: Double
    var birdies: Int
    var pars: Int
    var bogeys: Int
    var other: Int
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable {
    let id = UUID().uuidString
    let type: AchievementType
    let unlockedAt: Date
    var viewed: Bool = false
}

enum AchievementType: String, Codable, CaseIterable {
    case holeInOne = "Hole in One"
    case eagle = "Eagle Hunter"
    case birdieStreak = "Birdie Machine"
    case parRound = "Par Excellence"
    case underPar = "Under Par"
    case century = "Century Club" // 100 rounds
    case perfectGame = "Perfect Game"
    case comebackKid = "Comeback Kid"
    
    var icon: String {
        switch self {
        case .holeInOne: return "flag.fill"
        case .eagle: return "bird.fill"
        case .birdieStreak: return "flame.fill"
        case .parRound: return "star.fill"
        case .underPar: return "arrow.down.circle.fill"
        case .century: return "100.circle.fill"
        case .perfectGame: return "crown.fill"
        case .comebackKid: return "arrow.turn.up.right"
        }
    }
    
    var description: String {
        switch self {
        case .holeInOne: return "Score a hole in one"
        case .eagle: return "Score an eagle or better"
        case .birdieStreak: return "Three birdies in a row"
        case .parRound: return "Complete a round at par"
        case .underPar: return "Finish under par"
        case .century: return "Play 100 rounds"
        case .perfectGame: return "No bogeys in a round"
        case .comebackKid: return "Win after being 3 down"
        }
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    let id = UUID().uuidString
    let playerId: String
    let playerName: String
    let score: Int
    let formatId: String
    let courseId: String
    let date: Date
    let rank: Int?
}

// MARK: - User Preferences
class UserPreferences: ObservableObject, Codable {
    @Published var defaultCourseId: String?
    @Published var preferredTeeBox: String = "White"
    @Published var autoSync: Bool = true
    @Published var hapticFeedback: Bool = true
    @Published var soundEffects: Bool = true
    @Published var showAnimations: Bool = true
    @Published var defaultPlayerCount: Int = 4
    @Published var quickScoreEntry: Bool = true
    @Published var theme: AppTheme = .automatic
    
    enum AppTheme: String, Codable {
        case light, dark, automatic
    }
    
    static func load() -> UserPreferences {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            return preferences
        }
        return UserPreferences()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "userPreferences")
        }
    }
}