import Foundation
import Combine

// MARK: - Format Filter Criteria

struct FormatFilterCriteria {
    var groupSize: Int?
    var skillLevel: DifficultyLevel?
    var timeAvailable: Int? // in minutes
    var category: FormatCategory?
    var preferTeamPlay: Bool?
    var requireHandicap: Bool?
    var searchText: String = ""
    
    var hasActiveFilters: Bool {
        groupSize != nil ||
        skillLevel != nil ||
        timeAvailable != nil ||
        category != nil ||
        preferTeamPlay != nil ||
        requireHandicap != nil ||
        !searchText.isEmpty
    }
}

// MARK: - Format Database

class FormatDatabase: ObservableObject {
    @Published var formats: [GolfFormat] = []
    @Published var filteredFormats: [GolfFormat] = []
    @Published var favoriteFormatIDs: Set<UUID> = []
    @Published var recentlyViewedFormatIDs: [UUID] = []
    @Published var filterCriteria = FormatFilterCriteria()
    
    private var cancellables = Set<AnyCancellable>()
    private let maxRecentItems = 10
    
    init() {
        loadFormats()
        setupFilterSubscription()
        loadUserPreferences()
    }
    
    // MARK: - Data Loading
    
    private func loadFormats() {
        formats = Self.sampleFormats
        filteredFormats = formats
    }
    
    private func loadUserPreferences() {
        // Load from UserDefaults
        if let favoriteData = UserDefaults.standard.data(forKey: "favoriteFormats"),
           let favorites = try? JSONDecoder().decode(Set<UUID>.self, from: favoriteData) {
            favoriteFormatIDs = favorites
        }
        
        if let recentData = UserDefaults.standard.data(forKey: "recentFormats"),
           let recent = try? JSONDecoder().decode([UUID].self, from: recentData) {
            recentlyViewedFormatIDs = recent
        }
    }
    
    private func saveUserPreferences() {
        if let favoriteData = try? JSONEncoder().encode(favoriteFormatIDs) {
            UserDefaults.standard.set(favoriteData, forKey: "favoriteFormats")
        }
        
        if let recentData = try? JSONEncoder().encode(recentlyViewedFormatIDs) {
            UserDefaults.standard.set(recentData, forKey: "recentFormats")
        }
    }
    
    // MARK: - Filtering
    
    private func setupFilterSubscription() {
        $filterCriteria
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] criteria in
                self?.applyFilters(criteria)
            }
            .store(in: &cancellables)
    }
    
    func applyFilters(_ criteria: FormatFilterCriteria) {
        var results = formats
        
        // Apply search text filter
        if !criteria.searchText.isEmpty {
            results = results.filter { $0.matches(searchText: criteria.searchText) }
        }
        
        // Apply group size filter
        if let groupSize = criteria.groupSize {
            results = results.filter { $0.isCompatible(withGroupSize: groupSize) }
        }
        
        // Apply skill level filter
        if let skillLevel = criteria.skillLevel {
            results = results.filter { $0.isCompatible(withSkillLevel: skillLevel) }
        }
        
        // Apply time filter
        if let timeAvailable = criteria.timeAvailable {
            results = results.filter { $0.isCompatible(withTimeAvailable: timeAvailable) }
        }
        
        // Apply category filter
        if let category = criteria.category {
            results = results.filter { $0.category == category }
        }
        
        // Apply team preference filter
        if let preferTeamPlay = criteria.preferTeamPlay {
            results = results.filter { $0.teamBased == preferTeamPlay }
        }
        
        // Apply handicap requirement filter
        if let requireHandicap = criteria.requireHandicap {
            if requireHandicap {
                results = results.filter { $0.handicapRequired }
            } else {
                results = results.filter { !$0.handicapRequired }
            }
        }
        
        // Sort by compatibility score if criteria are set
        if criteria.groupSize != nil || criteria.skillLevel != nil || criteria.timeAvailable != nil {
            results = sortByCompatibility(
                formats: results,
                groupSize: criteria.groupSize ?? 4,
                skillLevel: criteria.skillLevel ?? .intermediate,
                timeAvailable: criteria.timeAvailable ?? 240,
                preferTeamPlay: criteria.preferTeamPlay
            )
        }
        
        filteredFormats = results
    }
    
    private func sortByCompatibility(
        formats: [GolfFormat],
        groupSize: Int,
        skillLevel: DifficultyLevel,
        timeAvailable: Int,
        preferTeamPlay: Bool?
    ) -> [GolfFormat] {
        return formats.sorted { format1, format2 in
            let score1 = format1.compatibilityScore(
                groupSize: groupSize,
                skillLevel: skillLevel,
                timeAvailable: timeAvailable,
                preferTeamPlay: preferTeamPlay
            )
            let score2 = format2.compatibilityScore(
                groupSize: groupSize,
                skillLevel: skillLevel,
                timeAvailable: timeAvailable,
                preferTeamPlay: preferTeamPlay
            )
            return score1 > score2
        }
    }
    
    // MARK: - User Actions
    
    func toggleFavorite(_ formatId: UUID) {
        if favoriteFormatIDs.contains(formatId) {
            favoriteFormatIDs.remove(formatId)
        } else {
            favoriteFormatIDs.insert(formatId)
        }
        saveUserPreferences()
    }
    
    func markAsViewed(_ formatId: UUID) {
        // Remove if already exists to move to front
        recentlyViewedFormatIDs.removeAll { $0 == formatId }
        recentlyViewedFormatIDs.insert(formatId, at: 0)
        
        // Keep only the most recent items
        if recentlyViewedFormatIDs.count > maxRecentItems {
            recentlyViewedFormatIDs = Array(recentlyViewedFormatIDs.prefix(maxRecentItems))
        }
        
        saveUserPreferences()
    }
    
    func isFavorite(_ formatId: UUID) -> Bool {
        favoriteFormatIDs.contains(formatId)
    }
    
    // MARK: - Quick Access
    
    var favoriteFormats: [GolfFormat] {
        formats.filter { favoriteFormatIDs.contains($0.id) }
    }
    
    var recentFormats: [GolfFormat] {
        recentlyViewedFormatIDs.compactMap { id in
            formats.first { $0.id == id }
        }
    }
    
    var popularFormats: [GolfFormat] {
        // Return a curated list of popular formats
        formats.filter { format in
            ["Nassau", "Skins", "Best Ball", "Scramble", "Wolf", "Match Play", "Stroke Play"]
                .contains(format.name)
        }
    }
    
    var beginnerFriendlyFormats: [GolfFormat] {
        formats.filter { $0.difficulty == .beginner && !$0.handicapRequired }
            .sorted { $0.name < $1.name }
    }
    
    // MARK: - Search
    
    func search(_ text: String) {
        filterCriteria.searchText = text
    }
    
    func clearFilters() {
        filterCriteria = FormatFilterCriteria()
    }
    
    func getFormat(by id: UUID) -> GolfFormat? {
        formats.first { $0.id == id }
    }
    
    // MARK: - Recommendations
    
    func getRecommendedFormats(for groupSize: Int) -> [GolfFormat] {
        let compatible = formats.filter { $0.isCompatible(withGroupSize: groupSize) }
        
        // Sort by how well they match the ideal player count
        return compatible.sorted { format1, format2 in
            let diff1 = abs(format1.idealPlayers - groupSize)
            let diff2 = abs(format2.idealPlayers - groupSize)
            return diff1 < diff2
        }.prefix(5).map { $0 }
    }
    
    func getSimilarFormats(to format: GolfFormat, limit: Int = 5) -> [GolfFormat] {
        formats
            .filter { $0.id != format.id }
            .filter { other in
                // Similar if same category or scoring type
                other.category == format.category ||
                other.scoringType == format.scoringType ||
                other.teamBased == format.teamBased
            }
            .sorted { format1, format2 in
                // Sort by number of matching attributes
                var score1 = 0
                var score2 = 0
                
                if format1.category == format.category { score1 += 1 }
                if format1.scoringType == format.scoringType { score1 += 1 }
                if format1.teamBased == format.teamBased { score1 += 1 }
                if format1.difficulty == format.difficulty { score1 += 1 }
                
                if format2.category == format.category { score2 += 1 }
                if format2.scoringType == format.scoringType { score2 += 1 }
                if format2.teamBased == format.teamBased { score2 += 1 }
                if format2.difficulty == format.difficulty { score2 += 1 }
                
                return score1 > score2
            }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Sample Data Extension

extension FormatDatabase {
    static let sampleFormats: [GolfFormat] = [
        // Nassau
        GolfFormat(
            name: "Nassau",
            description: "A three-part bet on the front nine, back nine, and overall 18 holes. One of golf's most popular betting games.",
            detailedRules: [
                "The round is divided into three separate bets: front 9, back 9, and overall 18",
                "Each bet is worth the same amount (e.g., $5 Nassau means $5 per bet)",
                "Players can press (double the bet) when down by 2 holes",
                "Automatic presses can be agreed upon before the round",
                "Ties can either push or carry over to the next hole"
            ],
            category: .competitive,
            scoringType: .nassau,
            minPlayers: 2,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: true
            ),
            variations: ["2-2-2 Press", "Automatic Press", "Rooback Nassau"],
            tips: ["Agree on press rules before starting", "Keep careful track of all bets"]
        ),
        
        // Wolf
        GolfFormat(
            name: "Wolf",
            description: "A rotating captain format where the 'Wolf' chooses to play alone or with a partner on each hole.",
            detailedRules: [
                "Players rotate being the Wolf based on tee order",
                "The Wolf tees off last and watches other players hit",
                "After each player hits, the Wolf can choose them as a partner",
                "The Wolf can go 'Lone Wolf' and play 1 vs 3 for double points",
                "If Wolf chooses a partner: 2 vs 2 for 1 point",
                "Lone Wolf wins: 4 points. Lone Wolf loses: each opponent gets 1 point",
                "Blind Wolf (declaring before anyone tees off) triples the stakes"
            ],
            category: .competitive,
            scoringType: .points,
            minPlayers: 4,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .advanced,
            timeEstimate: 270,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 0,
                allowsIndividualPlay: false
            ),
            variations: ["Blind Wolf", "Umbrella Wolf", "Better Ball Wolf"],
            tips: ["Keep track of who's the Wolf", "Consider going Lone Wolf on your best holes"]
        ),
        
        // Skins
        GolfFormat(
            name: "Skins",
            description: "Each hole is worth a 'skin' - win the hole outright to claim it. Ties carry the skin to the next hole.",
            detailedRules: [
                "Each hole is worth one skin (or a set dollar amount)",
                "To win a skin, a player must have the lowest score on the hole",
                "If players tie, the skin carries over to the next hole",
                "Carried over skins accumulate (validation)",
                "The player with the most skins at the end wins",
                "Often played with automatic validation after ties"
            ],
            category: .competitive,
            scoringType: .skins,
            minPlayers: 2,
            maxPlayers: 8,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Whole Round Skins", "Back It Up", "No Carry Over"],
            tips: ["Aggressive play is rewarded", "Birdies often win skins"]
        ),
        
        // Best Ball
        GolfFormat(
            name: "Best Ball",
            description: "Team format where each player plays their own ball and the team takes the best score.",
            detailedRules: [
                "Each player plays their own ball for the entire hole",
                "The team score is the lowest score among team members",
                "All players must complete each hole",
                "Can be played as stroke play or match play",
                "Handicaps are typically used in competitive play"
            ],
            category: .team,
            scoringType: .bestBall,
            minPlayers: 2,
            maxPlayers: 8,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .beginner,
            timeEstimate: 240,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Two Best Balls", "Three Best Balls", "Aggregate Score"],
            tips: ["Good for players of different skill levels", "Reduces pressure on individual shots"]
        ),
        
        // Scramble
        GolfFormat(
            name: "Scramble",
            description: "Team format where all players hit from the best shot location. Great for beginners and charity events.",
            detailedRules: [
                "All team members tee off",
                "Team selects the best shot",
                "All players hit their next shot from that location",
                "Continue until the ball is holed",
                "Each player must contribute a minimum number of drives (usually 2-4)",
                "Team records one score per hole"
            ],
            category: .team,
            scoringType: .scramble,
            minPlayers: 2,
            maxPlayers: 8,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .beginner,
            timeEstimate: 210,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Texas Scramble", "Florida Scramble", "Ambrose"],
            tips: ["Fastest format to play", "Great for team building", "Order players strategically"]
        ),
        
        // Bingo Bango Bongo
        GolfFormat(
            name: "Bingo Bango Bongo",
            description: "Three points available per hole: first on green, closest to pin, first in hole.",
            detailedRules: [
                "Bingo: First ball on the green (1 point)",
                "Bango: Closest to the pin once all balls are on green (1 point)",
                "Bongo: First ball in the hole (1 point)",
                "Strict order of play must be maintained",
                "Player furthest from the hole always plays first",
                "Great equalizer for different skill levels"
            ],
            category: .casual,
            scoringType: .points,
            minPlayers: 2,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .beginner,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Double points on par 5s", "Bonus for birdies"],
            tips: ["Emphasizes strategy over distance", "Good for mixed skill groups"]
        ),
        
        // Four-Ball
        GolfFormat(
            name: "Four-Ball",
            description: "Partners play their own balls; the better score counts for the team on each hole.",
            detailedRules: [
                "Each player plays their own ball throughout",
                "The lower score of the partners counts as the team score",
                "Used in Ryder Cup and Presidents Cup",
                "Can be played as match play or stroke play",
                "Partners can give each other advice"
            ],
            category: .tournament,
            scoringType: .bestBall,
            minPlayers: 4,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Better Ball", "Four-Ball Aggregate"],
            tips: ["Partners should play complementary styles", "Aggressive play from one partner when the other is safe"]
        ),
        
        // Alternate Shot
        GolfFormat(
            name: "Alternate Shot",
            description: "Partners play one ball, alternating shots until the hole is completed. Also called Foursomes.",
            detailedRules: [
                "Partners play the same ball, alternating shots",
                "One player tees off on odd holes, the other on even holes",
                "After the tee shot, partners alternate until the ball is holed",
                "Penalties don't affect the rotation",
                "Strategy in choosing who tees off where is crucial"
            ],
            category: .tournament,
            scoringType: .strokePlay,
            minPlayers: 4,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .advanced,
            timeEstimate: 210,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Greensomes", "Bloodsomes", "Pinehurst"],
            tips: ["Communication is key", "Play to each partner's strengths"]
        ),
        
        // Chapman
        GolfFormat(
            name: "Chapman",
            description: "Both partners tee off, play each other's ball for the second shot, then choose one ball to finish.",
            detailedRules: [
                "Both partners tee off",
                "Each plays their partner's tee shot for the second shot",
                "After both second shots, choose one ball to play alternately",
                "Continue alternating shots until holed",
                "Strategic format combining best of scramble and alternate shot"
            ],
            category: .tournament,
            scoringType: .strokePlay,
            minPlayers: 4,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .advanced,
            timeEstimate: 240,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Modified Chapman", "Selective Chapman"],
            tips: ["Requires good strategy and teamwork", "Consider each player's strengths when selecting ball"]
        ),
        
        // Shamble
        GolfFormat(
            name: "Shamble",
            description: "Combines scramble and best ball - all tee off, play from best drive, then play own ball.",
            detailedRules: [
                "All team members tee off",
                "Select the best drive",
                "All players play their own ball from the selected drive location",
                "Record the best score among team members",
                "Each player must contribute a minimum number of drives"
            ],
            category: .team,
            scoringType: .bestBall,
            minPlayers: 2,
            maxPlayers: 8,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Two-Man Shamble", "Bramble"],
            tips: ["Faster than best ball, slower than scramble", "Good format for mixed abilities"]
        ),
        
        // Stableford
        GolfFormat(
            name: "Stableford",
            description: "Point-based scoring system that rewards aggressive play. More points for better scores.",
            detailedRules: [
                "Points based on score relative to par:",
                "Eagle or better: 5 points",
                "Birdie: 3 points",
                "Par: 2 points",
                "Bogey: 1 point",
                "Double bogey or worse: 0 points",
                "Modified versions can adjust point values",
                "Highest point total wins"
            ],
            category: .competitive,
            scoringType: .stableford,
            minPlayers: 1,
            maxPlayers: 100,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Modified Stableford", "International Stableford"],
            tips: ["Encourages aggressive play", "Bad holes don't ruin your round"]
        ),
        
        // Match Play
        GolfFormat(
            name: "Match Play",
            description: "Hole-by-hole competition where you win, lose, or tie each hole. Win the most holes to win the match.",
            detailedRules: [
                "Each hole is a separate competition",
                "Win a hole by having the lowest score",
                "Track match status (e.g., 2 up, 1 down, all square)",
                "Match ends when one player is up by more holes than remain",
                "Concessions (gimmies) are common in friendly play",
                "Can be played with or without handicaps"
            ],
            category: .competitive,
            scoringType: .matchPlay,
            minPlayers: 2,
            maxPlayers: 2,
            idealPlayers: 2,
            handicapRequired: false,
            difficulty: .beginner,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 2,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Best Ball Match Play", "Four-Ball Match Play"],
            tips: ["Each hole is a fresh start", "Strategy changes based on match status"]
        ),
        
        // Stroke Play
        GolfFormat(
            name: "Stroke Play",
            description: "Traditional golf scoring - count every stroke, lowest total score wins.",
            detailedRules: [
                "Count every stroke taken",
                "Add penalty strokes to score",
                "Complete every hole",
                "Lowest total score wins",
                "Standard tournament format",
                "Can be played gross or net (with handicap)"
            ],
            category: .tournament,
            scoringType: .strokePlay,
            minPlayers: 1,
            maxPlayers: 100,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .beginner,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Medal Play", "Gross vs Net"],
            tips: ["Every stroke counts", "Course management is key"]
        ),
        
        // Las Vegas
        GolfFormat(
            name: "Las Vegas",
            description: "Team game where scores are paired to create two-digit numbers. Low number goes first.",
            detailedRules: [
                "Teams of two players each",
                "Combine scores to make a two-digit number (lower score first)",
                "Example: Scores of 4 and 5 become 45",
                "Lower team number wins the difference in points",
                "Flips: If one team gets a birdie and the other gets worse, numbers flip",
                "Example flip: 45 vs 56 becomes 45 vs 65"
            ],
            category: .competitive,
            scoringType: .points,
            minPlayers: 4,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .advanced,
            timeEstimate: 240,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Flips and Doubles", "No Flip Vegas"],
            tips: ["Big swings possible with flips", "Avoid high scores at all costs"]
        ),
        
        // 9 Point
        GolfFormat(
            name: "9 Point",
            description: "Nine points are distributed among players on each hole based on their scores.",
            detailedRules: [
                "9 points available on each hole",
                "Best score gets 5 points",
                "Second best gets 3 points",
                "Third best gets 1 point",
                "Ties split points evenly",
                "All tie: each gets 3 points",
                "Player with most points after 18 holes wins"
            ],
            category: .competitive,
            scoringType: .points,
            minPlayers: 3,
            maxPlayers: 3,
            idealPlayers: 3,
            handicapRequired: true,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 3,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["6 Point Game", "5-3-1 Scoring"],
            tips: ["Perfect for threesomes", "Every hole matters equally"]
        ),
        
        // Defender
        GolfFormat(
            name: "Defender",
            description: "One player defends against the other three on each hole, with points at stake.",
            detailedRules: [
                "One player is the defender each hole",
                "Defender plays against the best ball of the other three",
                "If defender wins: gets 3 points",
                "If defender ties: gets 1 point",
                "If defender loses: each opponent gets 1 point",
                "Rotate defender role throughout round"
            ],
            category: .competitive,
            scoringType: .points,
            minPlayers: 4,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: false
            ),
            variations: ["Random Defender", "Lowest Score Defends"],
            tips: ["Pressure is on the defender", "Good format for similar skill levels"]
        ),
        
        // Rabbit
        GolfFormat(
            name: "Rabbit",
            description: "The 'Rabbit' is won by the first player to win a hole outright, then defended on subsequent holes.",
            detailedRules: [
                "First player to win a hole outright captures the Rabbit",
                "Rabbit holder keeps it until someone else wins a hole outright",
                "Player holding the Rabbit after 9 holes wins the bet",
                "Start fresh on the back nine",
                "Can add side bets for longest Rabbit streak"
            ],
            category: .casual,
            scoringType: .points,
            minPlayers: 2,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .beginner,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Bear (opposite of Rabbit)", "Multiple Rabbits"],
            tips: ["Simple to track", "Adds excitement to every hole"]
        ),
        
        // Aces and Deuces
        GolfFormat(
            name: "Aces and Deuces",
            description: "Points for low and high scores - Aces (birdies) and Deuces (bogeys or worse) have value.",
            detailedRules: [
                "Set point values before round:",
                "Ace (birdie): Positive points from others",
                "Deuce (bogey or worse): Negative points to others",
                "Eagles worth double",
                "Double bogeys worth double negative",
                "Track running totals throughout round",
                "Settle up at the end"
            ],
            category: .competitive,
            scoringType: .points,
            minPlayers: 2,
            maxPlayers: 8,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Positive Only", "Include Pars"],
            tips: ["Rewards good play, penalizes bad", "Can lead to big swings"]
        ),
        
        // Round Robin
        GolfFormat(
            name: "Round Robin",
            description: "Partners rotate every six holes, playing three different partnership combinations.",
            detailedRules: [
                "Four players form different partnerships",
                "Holes 1-6: Player A+B vs C+D",
                "Holes 7-12: Player A+C vs B+D",
                "Holes 13-18: Player A+D vs B+C",
                "Each partnership plays better ball",
                "Track points for each player individually",
                "Player with most points wins"
            ],
            category: .team,
            scoringType: .points,
            minPlayers: 4,
            maxPlayers: 4,
            idealPlayers: 4,
            handicapRequired: true,
            difficulty: .intermediate,
            timeEstimate: 240,
            teamBased: true,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 2,
                playersPerTeam: 2,
                allowsIndividualPlay: false
            ),
            variations: ["Six Hole Segments", "Nine Hole Segments"],
            tips: ["Everyone partners with everyone", "Great for social rounds"]
        ),
        
        // Snake
        GolfFormat(
            name: "Snake",
            description: "The 'Snake' is held by whoever three-putts. Last player holding it pays the penalty.",
            detailedRules: [
                "First player to three-putt holds the Snake",
                "Snake passes to next player who three-putts",
                "Player holding Snake at round's end pays agreed amount",
                "Can add four-putt double snake",
                "Optional: one-putt releases the Snake to no one",
                "Track Snake holder after each hole"
            ],
            category: .casual,
            scoringType: .points,
            minPlayers: 2,
            maxPlayers: 8,
            idealPlayers: 4,
            handicapRequired: false,
            difficulty: .beginner,
            timeEstimate: 240,
            teamBased: false,
            playerConfiguration: PlayerConfiguration(
                totalPlayers: 4,
                teamsNeeded: 0,
                playersPerTeam: 1,
                allowsIndividualPlay: true
            ),
            variations: ["Reverse Snake (for one-putts)", "Multiple Snakes"],
            tips: ["Improves putting focus", "Simple side game"]
        )
    ]
}