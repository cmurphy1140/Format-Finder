import Foundation

// MARK: - Golf Format Model
struct GolfFormat: Identifiable, Codable {
    let id: String
    let name: String
    let shortDescription: String
    let icon: String
    let difficulty: String
    let playerRange: String
    let duration: String
    let tags: [String]
    let rules: [String]
    
    init(id: String, name: String, shortDescription: String, icon: String, difficulty: String, playerRange: String, duration: String, tags: [String], rules: [String]) {
        self.id = id
        self.name = name
        self.shortDescription = shortDescription
        self.icon = icon
        self.difficulty = difficulty
        self.playerRange = playerRange
        self.duration = duration
        self.tags = tags
        self.rules = rules
    }
}

// MARK: - Sample Data Extension
extension GolfFormat {
    static var sampleFormats: [GolfFormat] {
        [
            GolfFormat(
                id: "scramble",
                name: "Scramble",
                shortDescription: "Team format where everyone plays from the best shot",
                icon: "person.3.fill",
                difficulty: "Easy",
                playerRange: "2-4",
                duration: "4 hours",
                tags: ["Team", "Fun", "Beginner"],
                rules: [
                    "All players tee off",
                    "Team selects best shot",
                    "Everyone plays from that spot"
                ]
            ),
            GolfFormat(
                id: "bestball",
                name: "Best Ball",
                shortDescription: "Each player plays their own ball, best score counts",
                icon: "star.fill",
                difficulty: "Medium",
                playerRange: "2-4",
                duration: "4.5 hours",
                tags: ["Team", "Competitive"],
                rules: [
                    "Everyone plays own ball",
                    "Best individual score per hole",
                    "No shot sharing"
                ]
            ),
            GolfFormat(
                id: "skins",
                name: "Skins",
                shortDescription: "Win holes outright to collect skins",
                icon: "dollarsign.circle.fill",
                difficulty: "Hard",
                playerRange: "2-4",
                duration: "4 hours",
                tags: ["Gambling", "Competitive"],
                rules: [
                    "Lowest score wins the hole",
                    "Ties carry over",
                    "Winner takes accumulated skins"
                ]
            ),
            GolfFormat(
                id: "stableford",
                name: "Stableford",
                shortDescription: "Point-based scoring system",
                icon: "chart.bar.fill",
                difficulty: "Medium",
                playerRange: "1-4",
                duration: "4 hours",
                tags: ["Points", "Individual"],
                rules: [
                    "Points based on score vs par",
                    "Higher points win",
                    "Encourages aggressive play"
                ]
            ),
            GolfFormat(
                id: "match-play",
                name: "Match Play",
                shortDescription: "Hole-by-hole competition",
                icon: "flag.fill",
                difficulty: "Medium",
                playerRange: "2",
                duration: "4 hours",
                tags: ["Head-to-head", "Classic"],
                rules: [
                    "Win individual holes",
                    "Most holes won wins match",
                    "Can end before 18"
                ]
            )
        ]
    }
}