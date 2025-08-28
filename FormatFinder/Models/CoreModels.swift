import SwiftUI
import Foundation

// MARK: - Core Data Models

struct Player: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let handicap: Int
    let profileImage: String?
    var isActive: Bool = true
    
    init(id: UUID = UUID(), name: String, handicap: Int = 0, profileImage: String? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.handicap = handicap
        self.profileImage = profileImage
        self.isActive = isActive
    }
}

// MARK: - Game State Management

class GameState: ObservableObject {
    @Published var scores: [Int: [UUID: Int]] = [:]
    @Published var currentHole: Int = 1
    @Published var players: [Player] = []
    @Published var configuration: GameConfiguration
    
    init(configuration: GameConfiguration, players: [Player] = []) {
        self.configuration = configuration
        self.players = players
    }
    
    func getScore(hole: Int, player: UUID) -> Int {
        return scores[hole]?[player] ?? 0
    }
    
    func setScore(hole: Int, player: UUID, score: Int) {
        if scores[hole] == nil {
            scores[hole] = [:]
        }
        scores[hole]?[player] = score
    }
    
    func getTotalScore(for player: UUID) -> Int {
        var total = 0
        for hole in 1...configuration.numberOfHoles {
            total += getScore(hole: hole, player: player)
        }
        return total
    }
    
    func getHoleScore(hole: Int, player: UUID) -> Int? {
        return scores[hole]?[player]
    }
    
    func hasScore(hole: Int, player: UUID) -> Bool {
        return scores[hole]?[player] != nil
    }
}

struct GameConfiguration {
    var selectedFormat: GolfFormat?
    var players: [Player] = [
        Player(name: "Player 1", handicap: 0),
        Player(name: "Player 2", handicap: 0),
        Player(name: "Player 3", handicap: 0),
        Player(name: "Player 4", handicap: 0)
    ]
    var numberOfHoles: Int = 18
    var courseRating: Double = 72.0
    var slopeRating: Int = 130
    var teams: [Team] = []
    var startingHole: Int = 1
    var teeBox: String = "White"
    var scoringRules: ScoringRules = ScoringRules()
}

struct Team: Identifiable {
    let id = UUID()
    var name: String
    var players: [Player]
}

struct ScoringRules {
    var strokePlay = true
    var matchPlay = false
    var stableford = false
    var handicapsEnabled = true
}

enum CourseDifficulty: String, CaseIterable {
    case easy = "Easy"
    case regular = "Regular"
    case hard = "Hard"
    case championship = "Championship"
}

// MARK: - Score Models

struct Score: Identifiable, Codable {
    let id: UUID
    let hole: Int
    let value: Int
    let timestamp: Date
    let playerId: UUID
    
    init(hole: Int, value: Int, timestamp: Date = Date(), playerId: UUID, id: UUID = UUID()) {
        self.id = id
        self.hole = hole
        self.value = value
        self.timestamp = timestamp
        self.playerId = playerId
    }
    
    static func random() -> Score {
        Score(hole: Int.random(in: 1...18), value: Int.random(in: 3...6), playerId: UUID())
    }
    
    static func mockScores() -> [Score] {
        return (1...18).map { hole in
            Score(hole: hole, value: Int.random(in: 3...6), playerId: UUID())
        }
    }
}

// MARK: - Round and Tournament Models

struct Round: Identifiable, Codable {
    let id: UUID
    let course: String
    let date: Date
    let scores: [Int: Int]  // [Hole: Score] mapping
    let players: [String]   // Player names for compatibility
    
    init(id: UUID = UUID(), course: String, date: Date = Date(), players: [String] = [], scores: [Int: Int] = [:]) {
        self.id = id
        self.course = course
        self.date = date
        self.players = players
        self.scores = scores
    }
    
    // Computed properties for statistics
    var totalScore: Int {
        scores.values.reduce(0, +)
    }
    
    var averageScore: Double {
        guard !scores.isEmpty else { return 0 }
        return Double(totalScore) / Double(scores.count)
    }
    
    func scoreTo(par: Int) -> Int {
        totalScore - (scores.count * par)
    }
}

// MARK: - Achievement Models

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: Color
    let value: String?
    let showConfetti: Bool
    let rarity: AchievementRarity
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        color: Color = .blue,
        value: String? = nil,
        showConfetti: Bool = false,
        rarity: AchievementRarity = .common,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.value = value
        self.showConfetti = showConfetti
        self.rarity = rarity
        self.timestamp = timestamp
    }
    
    // Custom Codable implementation for Color
    enum CodingKeys: String, CodingKey {
        case id, title, description, icon, value, showConfetti, rarity, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        icon = try container.decode(String.self, forKey: .icon)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        showConfetti = try container.decode(Bool.self, forKey: .showConfetti)
        rarity = try container.decode(AchievementRarity.self, forKey: .rarity)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Default color for decoded achievements
        color = .blue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(icon, forKey: .icon)
        try container.encodeIfPresent(value, forKey: .value)
        try container.encode(showConfetti, forKey: .showConfetti)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

enum AchievementRarity: String, CaseIterable, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        }
    }
}

// MARK: - Card and UI Models

enum CardStyle: String, CaseIterable {
    case wrapped = "Wrapped"
    case minimal = "Minimal"
    case vibrant = "Vibrant"
    case dark = "Dark"
    case summary = "Summary"
    case detailed = "Detailed"
}

// MARK: - Navigation Models

enum NavigationPattern: String, CaseIterable {
    case byHole = "By Hole"
    case byPlayer = "By Player"
    case smart = "Smart"
    case automatic = "Automatic"
    case none = "Manual"
}

struct NavigationMove {
    let from: (hole: Int, player: Int)
    let to: (hole: Int, player: Int)
    let timestamp: Date
    let pattern: NavigationPattern?
    
    init(from: (hole: Int, player: Int), to: (hole: Int, player: Int), pattern: NavigationPattern? = nil) {
        self.from = from
        self.to = to
        self.timestamp = Date()
        self.pattern = pattern
    }
}

// MARK: - Mock Data

extension Player {
    static let mockPlayers: [Player] = [
        Player(name: "John Smith", handicap: 12),
        Player(name: "Sarah Johnson", handicap: 8),
        Player(name: "Mike Davis", handicap: 15),
        Player(name: "Lisa Wilson", handicap: 6)
    ]
}

extension GameState {
    static func mockGameState() -> GameState {
        let players = Player.mockPlayers
        let config = GameConfiguration(format: .strokePlay, numberOfHoles: 18, courseName: "Augusta National")
        let gameState = GameState(configuration: config, players: players)
        
        // Add some mock scores
        for hole in 1...9 {
            for player in players {
                let score = Int.random(in: 3...6)
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
        
        return gameState
    }
}