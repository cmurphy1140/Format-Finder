import Foundation

// MARK: - Enums

enum FormatCategory: String, CaseIterable, Codable {
    case competitive = "Competitive"
    case casual = "Casual"
    case team = "Team"
    case tournament = "Tournament"
    case practice = "Practice"
}

enum ScoringType: String, CaseIterable, Codable {
    case strokePlay = "Stroke Play"
    case matchPlay = "Match Play"
    case stableford = "Stableford"
    case skins = "Skins"
    case bestBall = "Best Ball"
    case scramble = "Scramble"
    case modified = "Modified"
    case points = "Points"
    case nassau = "Nassau"
}

enum DifficultyLevel: String, CaseIterable, Codable, Comparable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    static func < (lhs: DifficultyLevel, rhs: DifficultyLevel) -> Bool {
        let order: [DifficultyLevel] = [.beginner, .intermediate, .advanced, .expert]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Player Configuration

struct PlayerConfiguration: Codable, Equatable {
    let totalPlayers: Int
    let teamsNeeded: Int
    let playersPerTeam: Int
    let allowsIndividualPlay: Bool
    
    var isTeamFormat: Bool {
        teamsNeeded > 0 && playersPerTeam > 1
    }
    
    var totalTeamPlayers: Int {
        teamsNeeded * playersPerTeam
    }
    
    func isCompatible(with groupSize: Int) -> Bool {
        if allowsIndividualPlay {
            return groupSize >= totalPlayers
        } else if isTeamFormat {
            return groupSize >= totalTeamPlayers && groupSize % playersPerTeam == 0
        } else {
            return groupSize == totalPlayers
        }
    }
}

// MARK: - Golf Format Model

struct GolfFormat: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let detailedRules: [String]
    let category: FormatCategory
    let scoringType: ScoringType
    let minPlayers: Int
    let maxPlayers: Int
    let idealPlayers: Int
    let handicapRequired: Bool
    let difficulty: DifficultyLevel
    let timeEstimate: Int // in minutes
    let teamBased: Bool
    let playerConfiguration: PlayerConfiguration
    let variations: [String]
    let tips: [String]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        detailedRules: [String],
        category: FormatCategory,
        scoringType: ScoringType,
        minPlayers: Int,
        maxPlayers: Int,
        idealPlayers: Int,
        handicapRequired: Bool,
        difficulty: DifficultyLevel,
        timeEstimate: Int,
        teamBased: Bool,
        playerConfiguration: PlayerConfiguration,
        variations: [String] = [],
        tips: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.detailedRules = detailedRules
        self.category = category
        self.scoringType = scoringType
        self.minPlayers = minPlayers
        self.maxPlayers = maxPlayers
        self.idealPlayers = idealPlayers
        self.handicapRequired = handicapRequired
        self.difficulty = difficulty
        self.timeEstimate = timeEstimate
        self.teamBased = teamBased
        self.playerConfiguration = playerConfiguration
        self.variations = variations
        self.tips = tips
    }
    
    // MARK: - Computed Properties
    
    var playerCountRange: String {
        if minPlayers == maxPlayers {
            return "\(minPlayers) players"
        } else {
            return "\(minPlayers)-\(maxPlayers) players"
        }
    }
    
    var formattedTimeEstimate: String {
        let hours = timeEstimate / 60
        let minutes = timeEstimate % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    var quickSummary: String {
        var summary = category.rawValue
        if teamBased {
            summary += " • Team"
        }
        if handicapRequired {
            summary += " • Handicap"
        }
        summary += " • \(formattedTimeEstimate)"
        return summary
    }
    
    // MARK: - Compatibility Checks
    
    func isCompatible(withGroupSize size: Int) -> Bool {
        if size < minPlayers || size > maxPlayers {
            return false
        }
        return playerConfiguration.isCompatible(with: size)
    }
    
    func isCompatible(withSkillLevel level: DifficultyLevel) -> Bool {
        return difficulty <= level
    }
    
    func isCompatible(withTimeAvailable minutes: Int) -> Bool {
        return timeEstimate <= minutes
    }
    
    func compatibilityScore(
        groupSize: Int,
        skillLevel: DifficultyLevel,
        timeAvailable: Int,
        preferTeamPlay: Bool? = nil
    ) -> Int {
        var score = 0
        
        // Group size compatibility (highest weight)
        if groupSize == idealPlayers {
            score += 30
        } satellitePlayerConfiguration.isCompatible(with: groupSize) {
            score += 20
        }
        
        // Skill level match
        if difficulty == skillLevel {
            score += 25
        } else if isCompatible(withSkillLevel: skillLevel) {
            score += 15
        }
        
        // Time compatibility
        if isCompatible(withTimeAvailable: timeAvailable) {
            let timeRatio = Double(timeEstimate) / Double(timeAvailable)
            if timeRatio > 0.8 {
                score += 20 // Uses most of available time
            } else if timeRatio > 0.6 {
                score += 15
            } else {
                score += 10
            }
        }
        
        // Team preference
        if let preferTeam = preferTeamPlay {
            if teamBased == preferTeam {
                score += 10
            }
        }
        
        return score
    }
}

// MARK: - Search Support

extension GolfFormat {
    func matches(searchText: String) -> Bool {
        let searchText = searchText.lowercased()
        
        if searchText.isEmpty {
            return true
        }
        
        // Search in name
        if name.lowercased().contains(searchText) {
            return true
        }
        
        // Search in description
        if description.lowercased().contains(searchText) {
            return true
        }
        
        // Search in category
        if category.rawValue.lowercased().contains(searchText) {
            return true
        }
        
        // Search in scoring type
        if scoringType.rawValue.lowercased().contains(searchText) {
            return true
        }
        
        // Search in rules
        for rule in detailedRules {
            if rule.lowercased().contains(searchText) {
                return true
            }
        }
        
        // Search in variations
        for variation in variations {
            if variation.lowercased().contains(searchText) {
                return true
            }
        }
        
        return false
    }
}