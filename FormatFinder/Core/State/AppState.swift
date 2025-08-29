import SwiftUI
import Combine
import CoreData

// MARK: - Main App State Manager
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Navigation State
    @Published var selectedTab: Int = 0
    @Published var navigationPath = NavigationPath()
    @Published var showOnboarding: Bool = false
    @Published var activeGameSession: GameSession?
    
    // MARK: - User Data
    @Published var currentUser: UserProfile?
    @Published var userPreferences: UserPreferences
    
    // MARK: - Golf Formats
    @Published var availableFormats: [GolfFormat] = []
    @Published var favoriteFormats: Set<String> = []
    @Published var recentFormats: [GolfFormat] = []
    
    // MARK: - Game Sessions
    @Published var activeSessions: [GameSession] = []
    @Published var sessionHistory: [GameSession] = []
    @Published var currentRound: RoundData?
    
    // MARK: - Statistics
    @Published var playerStats: PlayerStatistics?
    @Published var achievements: [Achievement] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    
    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    
    // MARK: - Services
    let dataService: FormatDataService
    let scoringEngine: ScoringEngine
    let statisticsManager: StatisticsManager
    let cloudSync: CloudKitSyncService
    let hapticManager: HapticManager
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Initialize services
        self.dataService = FormatDataService()
        self.scoringEngine = ScoringEngine()
        self.statisticsManager = StatisticsManager()
        self.cloudSync = CloudKitSyncService()
        self.hapticManager = HapticManager.shared
        
        // Load user preferences
        self.userPreferences = UserPreferences.load()
        
        // Setup observers
        setupObservers()
        
        // Load initial data
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe preference changes
        userPreferences.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.userPreferences.save()
            }
            .store(in: &cancellables)
        
        // Auto-save game sessions
        $activeGameSession
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] session in
                self?.saveGameSession(session)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Load formats
            availableFormats = try await dataService.fetchFormats()
            
            // Load user data
            if let user = try await loadUserProfile() {
                currentUser = user
                favoriteFormats = Set(user.favoriteFormatIds)
            }
            
            // Load statistics
            playerStats = try await statisticsManager.loadStatistics()
            achievements = try await loadAchievements()
            
            // Load recent sessions
            sessionHistory = try await loadRecentSessions()
            
            await MainActor.run {
                isLoading = false
                
                // Check for first launch
                if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
                    showOnboarding = true
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Game Session Management
    
    func startNewGame(format: GolfFormat, players: [Player]) {
        let session = GameSession(
            id: UUID().uuidString,
            format: format,
            players: players,
            startTime: Date(),
            courseId: userPreferences.defaultCourseId
        )
        
        activeGameSession = session
        activeSessions.append(session)
        
        // Navigate to game view
        navigationPath.append(NavigationDestination.gamePlay(session))
        
        // Haptic feedback
        hapticManager.impact(style: .medium)
    }
    
    func endCurrentGame() {
        guard let session = activeGameSession else { return }
        
        // Calculate final scores
        let finalScores = scoringEngine.calculateFinalScores(for: session)
        session.finalScores = finalScores
        session.endTime = Date()
        
        // Update statistics
        Task {
            await updateStatistics(for: session)
        }
        
        // Move to history
        sessionHistory.insert(session, at: 0)
        activeSessions.removeAll { $0.id == session.id }
        activeGameSession = nil
        
        // Navigate to results
        navigationPath.append(NavigationDestination.gameResults(session))
    }
    
    func recordScore(hole: Int, player: Player, strokes: Int) {
        guard let session = activeGameSession else { return }
        
        // Update score
        let score = HoleScore(
            hole: hole,
            playerId: player.id,
            strokes: strokes,
            timestamp: Date()
        )
        
        session.scores.append(score)
        
        // Calculate running totals
        let runningScore = scoringEngine.calculateRunningScore(
            for: player,
            in: session,
            throughHole: hole
        )
        
        // Check for achievements
        checkAchievements(for: score, player: player, session: session)
        
        // Haptic feedback
        hapticManager.notification(type: .success)
        
        // Auto-sync
        if userPreferences.autoSync {
            Task {
                await syncToCloud()
            }
        }
    }
    
    // MARK: - Format Management
    
    func toggleFavoriteFormat(_ format: GolfFormat) {
        if favoriteFormats.contains(format.id) {
            favoriteFormats.remove(format.id)
        } else {
            favoriteFormats.insert(format.id)
        }
        
        // Update user profile
        currentUser?.favoriteFormatIds = Array(favoriteFormats)
        
        // Save to cloud
        Task {
            await saveUserProfile()
        }
        
        hapticManager.impact(style: .light)
    }
    
    func recordFormatUsage(_ format: GolfFormat) {
        // Update recent formats
        recentFormats.removeAll { $0.id == format.id }
        recentFormats.insert(format, at: 0)
        
        // Keep only last 5
        if recentFormats.count > 5 {
            recentFormats = Array(recentFormats.prefix(5))
        }
        
        // Save to user defaults
        saveRecentFormats()
    }
    
    // MARK: - Statistics & Achievements
    
    private func updateStatistics(for session: GameSession) async {
        guard let stats = playerStats else { return }
        
        // Update rounds played
        stats.roundsPlayed += 1
        
        // Update scoring average
        if let finalScore = session.finalScores?.first {
            stats.scoringAverage = ((stats.scoringAverage * Double(stats.roundsPlayed - 1)) + Double(finalScore.totalStrokes)) / Double(stats.roundsPlayed)
        }
        
        // Update format-specific stats
        stats.formatStats[session.format.id, default: FormatStatistics()].gamesPlayed += 1
        
        // Save
        await statisticsManager.saveStatistics(stats)
    }
    
    private func checkAchievements(for score: HoleScore, player: Player, session: GameSession) {
        // Check for hole-in-one
        if score.strokes == 1 {
            unlockAchievement(.holeInOne)
        }
        
        // Check for eagle (2 under par)
        if let par = getCourseData()?.holes[score.hole - 1].par,
           score.strokes <= par - 2 {
            unlockAchievement(.eagle)
        }
        
        // Check for birdie streak
        let recentScores = session.scores
            .filter { $0.playerId == player.id }
            .suffix(3)
        
        if recentScores.count == 3 {
            let allBirdies = recentScores.allSatisfy { holeScore in
                guard let par = getCourseData()?.holes[holeScore.hole - 1].par else { return false }
                return holeScore.strokes == par - 1
            }
            
            if allBirdies {
                unlockAchievement(.birdieStreak)
            }
        }
    }
    
    private func unlockAchievement(_ type: AchievementType) {
        guard !achievements.contains(where: { $0.type == type }) else { return }
        
        let achievement = Achievement(
            type: type,
            unlockedAt: Date()
        )
        
        achievements.append(achievement)
        
        // Show celebration
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: achievement
        )
        
        hapticManager.notification(type: .success)
    }
    
    // MARK: - Cloud Sync
    
    func syncToCloud() async {
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            // Sync user profile
            if let user = currentUser {
                try await cloudSync.saveUserProfile(user)
            }
            
            // Sync game sessions
            for session in sessionHistory.prefix(10) {
                try await cloudSync.saveGameSession(session)
            }
            
            // Sync statistics
            if let stats = playerStats {
                try await cloudSync.saveStatistics(stats)
            }
            
            await MainActor.run {
                syncStatus = .success
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Navigation
    
    func navigateToFormat(_ format: GolfFormat) {
        recordFormatUsage(format)
        navigationPath.append(NavigationDestination.formatDetail(format))
    }
    
    func navigateToGameSetup(format: GolfFormat) {
        navigationPath.append(NavigationDestination.gameSetup(format))
    }
    
    func navigateHome() {
        navigationPath.removeLast(navigationPath.count)
        selectedTab = 0
    }
    
    // MARK: - Helper Methods
    
    private func getCourseData() -> CourseData? {
        // Get current course data
        return CourseData.sampleCourse
    }
    
    private func saveGameSession(_ session: GameSession) {
        // Save to Core Data or UserDefaults
        // Implementation depends on persistence strategy
    }
    
    private func loadUserProfile() async throws -> UserProfile? {
        // Load from CloudKit or local storage
        return UserProfile.sample
    }
    
    private func saveUserProfile() async {
        // Save to CloudKit
    }
    
    private func loadAchievements() async throws -> [Achievement] {
        // Load from storage
        return []
    }
    
    private func loadRecentSessions() async throws -> [GameSession] {
        // Load from Core Data
        return []
    }
    
    private func saveRecentFormats() {
        let formatIds = recentFormats.map { $0.id }
        UserDefaults.standard.set(formatIds, forKey: "recentFormatIds")
    }
}

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case formatDetail(GolfFormat)
    case gameSetup(GolfFormat)
    case gamePlay(GameSession)
    case gameResults(GameSession)
    case statistics
    case settings
    case profile
}

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error(String)
}

// MARK: - Notifications
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let gameSessionUpdated = Notification.Name("gameSessionUpdated")
}