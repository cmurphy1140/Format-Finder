import Foundation
import Combine
import SwiftUI

// MARK: - Format Data Service
/// Manages format data, caching, and backend synchronization
@MainActor
class FormatDataService: ObservableObject {
    static let shared = FormatDataService()
    
    // Published properties for UI binding
    @Published var formats: [EnhancedGolfFormat] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastSyncDate: Date?
    @Published var cachedFormats: [EnhancedGolfFormat] = []
    
    // Backend services
    private let networkService = NetworkService()
    // private let cacheManager = CacheManager.shared // TODO: Implement CacheManager
    private let analyticsService = AnalyticsService.shared
    
    // Combine
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let cacheKey = "golf_formats_cache"
    private let cacheExpiration: TimeInterval = 3600 * 24 // 24 hours
    
    private init() {
        loadCachedFormats()
        setupAutoSync()
    }
    
    // MARK: - Public Methods
    
    /// Load formats with intelligent caching
    func loadFormats(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil
        
        // Check cache first unless force refresh
        if !forceRefresh, let cached = loadFromCache(), !isCacheExpired() {
            formats = cached
            isLoading = false
            
            // Sync in background
            Task.detached { [weak self] in
                await self?.syncInBackground()
            }
            return
        }
        
        // Load from backend
        do {
            let fetchedFormats = try await fetchFromBackend()
            formats = fetchedFormats
            saveToCache(fetchedFormats)
            lastSyncDate = Date()
            
            // Track analytics
            analyticsService.trackEvent(.formatsLoaded, properties: [
                "count": fetchedFormats.count,
                "source": forceRefresh ? "force_refresh" : "normal"
            ])
        } catch {
            self.error = error
            
            // Fallback to cache or static data
            if let cached = loadFromCache() {
                formats = cached
            } else {
                formats = Self.staticFormats
            }
            
            analyticsService.trackError(error)
        }
        
        isLoading = false
    }
    
    /// Get format by ID
    func getFormat(byId id: String) -> EnhancedGolfFormat? {
        formats.first { $0.id == id }
    }
    
    /// Get formats by difficulty
    func getFormats(byDifficulty difficulty: String) -> [EnhancedGolfFormat] {
        formats.filter { $0.difficulty == difficulty }
    }
    
    /// Get formats for group size
    func getFormats(forGroupSize size: Int) -> [EnhancedGolfFormat] {
        formats.filter { $0.idealGroupSize.contains(size) }
    }
    
    /// Search formats
    func searchFormats(query: String) -> [EnhancedGolfFormat] {
        guard !query.isEmpty else { return formats }
        
        return formats.filter { format in
            format.name.localizedCaseInsensitiveContains(query) ||
            format.description.localizedCaseInsensitiveContains(query) ||
            format.tagline.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Get personalized recommendations
    func getRecommendations(for preferences: UserPreferences) -> [EnhancedGolfFormat] {
        formats.sorted { first, second in
            scoreFormat(first, for: preferences) > scoreFormat(second, for: preferences)
        }.prefix(5).map { $0 }
    }
    
    /// Track format view
    func trackFormatView(_ format: EnhancedGolfFormat) {
        analyticsService.trackEvent(.formatViewed, properties: [
            "format_id": format.id,
            "format_name": format.name,
            "difficulty": format.difficulty
        ])
    }
    
    /// Track format selection for game
    func trackFormatSelection(_ format: EnhancedGolfFormat) {
        analyticsService.trackEvent(.formatSelected, properties: [
            "format_id": format.id,
            "format_name": format.name,
            "group_size": format.idealGroupSize.lowerBound
        ])
        
        // Update user preferences
        UserDefaults.standard.set(format.id, forKey: "last_selected_format")
    }
    
    // MARK: - Private Methods
    
    private func fetchFromBackend() async throws -> [EnhancedGolfFormat] {
        // TODO: Replace with actual API call
        // let response = try await networkService.request(.getFormats)
        // return try JSONDecoder().decode([EnhancedGolfFormat].self, from: response)
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Return enhanced static data with backend simulation
        return Self.staticFormats
    }
    
    private func syncInBackground() async {
        guard let lastSync = lastSyncDate else { return }
        
        // Only sync if cache is older than 1 hour
        if Date().timeIntervalSince(lastSync) > 3600 {
            do {
                let freshFormats = try await fetchFromBackend()
                await MainActor.run {
                    formats = freshFormats
                    saveToCache(freshFormats)
                    lastSyncDate = Date()
                }
            } catch {
                // Silent fail for background sync
                print("Background sync failed: \(error)")
            }
        }
    }
    
    private func setupAutoSync() {
        // Auto sync every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.loadFormats()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Cache Management
    
    private func loadFromCache() -> [EnhancedGolfFormat]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode([EnhancedGolfFormat].self, from: data)
    }
    
    private func saveToCache(_ formats: [EnhancedGolfFormat]) {
        guard let data = try? JSONEncoder().encode(formats) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: "\(cacheKey)_date")
    }
    
    private func isCacheExpired() -> Bool {
        guard let cacheDate = UserDefaults.standard.object(forKey: "\(cacheKey)_date") as? Date else {
            return true
        }
        return Date().timeIntervalSince(cacheDate) > cacheExpiration
    }
    
    private func loadCachedFormats() {
        if let cached = loadFromCache() {
            cachedFormats = cached
            formats = cached
        } else {
            formats = Self.staticFormats
        }
    }
    
    // MARK: - Recommendation Scoring
    
    private func scoreFormat(_ format: EnhancedGolfFormat, for preferences: UserPreferences) -> Double {
        var score: Double = 0
        
        // Skill level match
        let skillMatch = 5 - abs(difficultyToSkillLevel(format.difficulty) - preferences.skillLevel)
        score += skillMatch * 20
        
        // Group size match
        if format.idealGroupSize.contains(preferences.preferredGroupSize) {
            score += 30
        }
        
        // Play style preference
        if preferences.preferCompetitive && format.isCompetitive {
            score += 25
        }
        
        if preferences.preferCasual && !format.isCompetitive {
            score += 25
        }
        
        // Recent selection bonus
        if let lastSelected = UserDefaults.standard.string(forKey: "last_selected_format"),
           lastSelected == format.id {
            score += 10
        }
        
        // Popularity factor
        score += format.popularityScore * 10
        
        return score
    }
    
    private func difficultyToSkillLevel(_ difficulty: String) -> Double {
        switch difficulty {
        case "Easy": return 1.5
        case "Medium": return 3.0
        case "Hard": return 4.5
        default: return 2.5
        }
    }
}

// MARK: - Extended Format Model
// Note: EnhancedGolfFormat is defined in SwipeableFormatCards.swift

// MARK: - User Preferences
struct UserPreferences {
    var skillLevel: Double = 2.5
    var preferredGroupSize: Int = 4
    var preferCompetitive: Bool = false
    var preferCasual: Bool = true
    var favoriteFormats: [String] = []
}

// MARK: - Analytics Events
extension AnalyticsService {
    enum Event: String {
        case formatsLoaded = "formats_loaded"
        case formatViewed = "format_viewed"
        case formatSelected = "format_selected"
        case formatFiltered = "format_filtered"
        case formatSearched = "format_searched"
    }
    
    func trackEvent(_ event: Event, properties: [String: Any]? = nil) {
        // TODO: Implement actual analytics tracking
        print("Analytics: \(event.rawValue) - \(properties ?? [:])")
    }
    
    func trackError(_ error: Error) {
        print("Error tracked: \(error.localizedDescription)")
    }
}

// MARK: - Network Service
class NetworkService {
    enum Endpoint {
        case getFormats
        case getFormatDetails(String)
        case updateFormatStats(String, [String: Any])
        
        var url: URL {
            // TODO: Replace with actual API endpoints
            URL(string: "https://api.formatfinder.com/v1/formats")!
        }
    }
    
    func request(_ endpoint: Endpoint) async throws -> Data {
        // TODO: Implement actual network request
        throw NSError(domain: "NetworkService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
}

// MARK: - Analytics Service
class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}
}

// MARK: - Static Format Data
extension FormatDataService {
    static let staticFormats: [EnhancedGolfFormat] = [
        EnhancedGolfFormat(
            name: "Scramble",
            tagline: "Team plays best shot",
            difficulty: "Easy",
            description: "All players tee off, then the team selects the best shot and everyone plays from that spot. This format is perfect for mixed skill levels as it allows weaker players to contribute while learning from better players.",
            quickRules: [
                "Everyone tees off on each hole",
                "Team picks the best shot",
                "All play from that spot",
                "Continue until the ball is holed"
            ],
            completeRules: [
                "All team members tee off on each hole",
                "The team decides which tee shot is best",
                "All players pick up their balls and play their second shots from the chosen spot",
                "This process continues for every shot including putts",
                "The team records a single score for each hole",
                "In tournaments, teams often must use a minimum number of drives from each player",
                "Handicap strokes are typically divided among team members"
            ],
            scoringMethod: "Count total team strokes",
            detailedScoring: "Record one score per hole for the entire team. The team with the lowest total score wins. In handicapped events, team handicaps are usually calculated as a percentage of combined individual handicaps (e.g., 20% of total).",
            idealGroupSize: 2...4,
            proTips: [
                "Let the longest hitter tee off last to see the safe shots first",
                "Save the best putter's ball for approach shots to set up birdie putts",
                "Don't automatically choose the longest drive - position is often more important",
                "Communicate before each shot about strategy and club selection"
            ],
            animationType: .scramble
        ),
        
        EnhancedGolfFormat(
            name: "Best Ball",
            tagline: "Play your own, count the best",
            difficulty: "Easy",
            description: "Each player plays their own ball throughout the entire hole. The team score is the lowest individual score on each hole. Also known as 'Better Ball' in some regions.",
            quickRules: [
                "Everyone plays their own ball",
                "Take the best individual score",
                "Other scores don't count",
                "Each player maintains their own ball"
            ],
            completeRules: [
                "Each player plays their own ball from tee to green",
                "All players complete the hole with their own ball",
                "The lowest score among teammates becomes the team score",
                "If playing as a foursome in two teams: Team 1 (A & B) vs Team 2 (C & D)",
                "Can be played as stroke play (total score) or match play (by holes)",
                "Full handicaps typically apply for each player",
                "Players can pick up if they cannot help the team score"
            ],
            scoringMethod: "Lowest individual score per hole",
            detailedScoring: "Record each player's score, circle the best score that counts for the team. In a Four-Ball match play, the team wins, loses, or halves each hole. In stroke play, add up the best scores from each hole for the team total.",
            idealGroupSize: 2...4,
            proTips: [
                "Play aggressively when your partner is in a safe position",
                "Support your partner on difficult holes - play conservatively if they're in trouble",
                "Know when to pick up to maintain pace of play",
                "Encourage your partner even when you're having the better round"
            ],
            animationType: .bestBall
        ),
        
        EnhancedGolfFormat(
            name: "Match Play",
            tagline: "Win holes, not strokes",
            difficulty: "Medium",
            description: "Players compete to win individual holes rather than counting total strokes. The player with the lowest score on a hole wins that hole. The match is won by the player who is ahead by more holes than remain to be played.",
            quickRules: [
                "Lowest score wins the hole",
                "Track holes won, not strokes",
                "Tied holes are 'halved'",
                "Match can end before 18 holes"
            ],
            completeRules: [
                "Players compete to win individual holes",
                "The player with the lowest score on a hole wins that hole",
                "If players tie on a hole, it's 'halved' (no one wins)",
                "Match status is expressed as 'holes up' or 'all square'",
                "Example: '2 up' means leading by 2 holes",
                "Match ends when one player is up by more holes than remain",
                "Common match play formats: Singles, Foursomes, Four-Ball",
                "Concessions are allowed - opponent can concede a hole or putt"
            ],
            scoringMethod: "Holes won vs. holes lost",
            detailedScoring: "Track as 'up', 'down', or 'all square' throughout the round. Final results are recorded as winning margin and holes remaining (e.g., '3&2' means winner was 3 up with 2 holes to play).",
            idealGroupSize: 2...4,
            proTips: [
                "Play the hole, not your overall score - a 10 only loses one hole",
                "Take calculated risks when you're down in the match",
                "Apply pressure by hitting first when possible",
                "Concede short putts strategically to maintain pace and momentum"
            ],
            animationType: .matchPlay
        ),
        
        EnhancedGolfFormat(
            name: "Skins",
            tagline: "Win the hole, win the pot",
            difficulty: "Medium",
            description: "Each hole has a monetary value (skin). To win the skin, a player must win the hole outright - no ties. If players tie, the skin carries over to the next hole, building the pot.",
            quickRules: [
                "Each hole worth a set value",
                "Must win hole outright",
                "Ties carry over to next hole",
                "Pots can grow quickly"
            ],
            completeRules: [
                "Assign a value to each hole (e.g., $10 per hole)",
                "The player with the lowest score wins the skin",
                "If two or more players tie for low score, skin carries over",
                "Carried over skins accumulate (next hole worth $20, then $30, etc.)",
                "Some groups play 'validation' - must win or tie next hole to secure skin",
                "Can include automatic presses (new skin game) at certain points",
                "Often combined with other games like Nassau",
                "Handicaps can be applied using net scores"
            ],
            scoringMethod: "Track skins won and values",
            detailedScoring: "Keep a running tally of each player's skin wins and total value. Mark carried-over skins clearly. Calculate payouts at the end based on skin values won.",
            idealGroupSize: 3...4,
            proTips: [
                "Be aggressive when skins carry over - the reward is worth the risk",
                "Know when to play safe if others are in trouble",
                "Track the money carefully to know when to press",
                "Consider the group dynamics - some players get more aggressive with carried skins"
            ],
            animationType: .skins
        ),
        
        EnhancedGolfFormat(
            name: "Stableford",
            tagline: "Points reward good holes",
            difficulty: "Easy",
            description: "A points-based scoring system where players earn points based on their score relative to par. Unlike stroke play, there's no penalty for disaster holes, encouraging aggressive play.",
            quickRules: [
                "Points based on score vs par",
                "Higher points are better",
                "No penalty for bad holes",
                "Rewards aggressive play"
            ],
            completeRules: [
                "Standard Stableford Points:",
                "• Eagle or better: 4 points",
                "• Birdie: 3 points",
                "• Par: 2 points",
                "• Bogey: 1 point",
                "• Double bogey or worse: 0 points",
                "Modified Stableford can use different values",
                "Player with most points wins",
                "Can be played individually or in teams",
                "Handicaps applied before calculating points"
            ],
            scoringMethod: "Accumulate points per hole",
            detailedScoring: "Track points earned on each hole and maintain running total. Modified Stableford might use: Eagle=8, Birdie=5, Par=2, Bogey=0, Double=-1, Triple or worse=-3.",
            idealGroupSize: 1...4,
            proTips: [
                "Be aggressive - you can't lose points for bad holes",
                "Focus on birdie opportunities",
                "Pick up after double bogey to speed play",
                "This format favors aggressive players over consistent ones"
            ],
            animationType: .stableford
        ),
        
        EnhancedGolfFormat(
            name: "Alternate Shot",
            tagline: "True partnership golf",
            difficulty: "Hard",
            description: "Partners play one ball, alternating shots. One player tees off on odd holes, the other on even holes. Also known as 'Foursomes' in match play.",
            quickRules: [
                "Partners share one ball",
                "Alternate every shot",
                "Alternate tee shots by hole",
                "Requires great teamwork"
            ],
            completeRules: [
                "Partners play one ball, alternating shots",
                "Player A tees off on odd holes (1, 3, 5, etc.)",
                "Player B tees off on even holes (2, 4, 6, etc.)",
                "After the tee shot, partners alternate every shot",
                "This includes penalty shots",
                "If A hits into water, B must play the penalty drop",
                "Strategy in choosing who tees off where is crucial",
                "Can be played as stroke or match play"
            ],
            scoringMethod: "One score per team per hole",
            detailedScoring: "Record a single score for the team on each hole. The same as regular golf scoring but with alternating shots between partners.",
            idealGroupSize: 2...4,
            proTips: [
                "Choose tee shot order based on hole difficulty and player strengths",
                "Leave your partner in good positions",
                "Communication is essential",
                "Practice playing from awkward lies - you'll face your partner's misses"
            ],
            animationType: .alternateShot
        ),
        
        EnhancedGolfFormat(
            name: "Nassau",
            tagline: "Three bets in one round",
            difficulty: "Medium",
            description: "A three-part bet covering the front nine, back nine, and overall 18 holes. Each segment is a separate bet, allowing players to win even after a poor start.",
            quickRules: [
                "Three separate bets",
                "Front 9, Back 9, Overall 18",
                "Can press when down",
                "Most common betting game"
            ],
            completeRules: [
                "Three separate bets of equal value",
                "Front Nine (holes 1-9)",
                "Back Nine (holes 10-18)",
                "Overall 18 holes",
                "Can be played as stroke or match play",
                "Presses: Start new bet when down by 2 holes",
                "Automatic presses often used (2-down auto-press)",
                "Can be combined with other formats",
                "Teams or individual play"
            ],
            scoringMethod: "Track three separate matches",
            detailedScoring: "Keep separate tallies for front 9, back 9, and overall. In match play, track holes up/down for each bet. In stroke play, track total scores for each segment.",
            idealGroupSize: 2...4,
            proTips: [
                "Don't give up after a bad front nine - you have two bets left",
                "Know when to press to maximize opportunity",
                "Stay focused on all three bets simultaneously",
                "The 18-hole bet keeps pressure on throughout"
            ],
            animationType: .nassau
        ),
        
        EnhancedGolfFormat(
            name: "Wolf",
            tagline: "Captain chooses partners",
            difficulty: "Hard",
            description: "A rotating captain (Wolf) format where the Wolf can choose a partner or play alone against the other three. Points are doubled when playing alone.",
            quickRules: [
                "Rotating Wolf each hole",
                "Wolf picks partner or goes alone",
                "Lone Wolf earns double points",
                "Strategic partnership game"
            ],
            completeRules: [
                "Player order rotates who is Wolf each hole",
                "Wolf tees off last and watches others tee off",
                "Wolf can choose partner immediately after their tee shot",
                "Or Wolf can wait and go 'Lone Wolf' (play alone)",
                "Lone Wolf points are doubled (win or lose)",
                "If Wolf doesn't choose after all tee off, must go alone",
                "Points: 1 point for winning hole, 2 for Lone Wolf win",
                "Minus points for losses",
                "Can play Blind Wolf (decide before anyone tees off)"
            ],
            scoringMethod: "Points for holes won",
            detailedScoring: "Track points per player. Regular win = 1 point per opponent, Lone Wolf win = 2 points per opponent. Losses are negative points. Blind Wolf can be 3x points.",
            idealGroupSize: 4...4,
            proTips: [
                "Watch tee shots carefully before choosing",
                "Go Lone Wolf on your best holes",
                "Track who's winning to make strategic choices",
                "Consider Blind Wolf on short par 3s you like"
            ],
            animationType: .wolf
        )
    ]
}