import Foundation
import SwiftUI
import Combine

// MARK: - Multi-Player Grid Update Service
// Manages simultaneous score updates for multiple players in a grid view

@MainActor
final class MultiPlayerGridService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var gridState = GridState()
    @Published private(set) var pendingUpdates: [PlayerScoreUpdate] = []
    @Published private(set) var isProcessingBatch = false
    @Published private(set) var conflictResolutions: [ConflictResolution] = []
    
    // MARK: - Private Properties
    
    private var updateQueue = DispatchQueue(label: "com.formatfinder.gridupdate", qos: .userInteractive)
    private var updateBuffer: [PlayerScoreUpdate] = []
    private var updateTimer: Timer?
    private let batchInterval: TimeInterval = 0.1 // 100ms batching
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    static let shared = MultiPlayerGridService()
    
    private init() {
        setupUpdateBatching()
    }
    
    // MARK: - Public Methods
    
    /// Submit a score update for a player
    func submitScoreUpdate(_ update: PlayerScoreUpdate) {
        // Add to buffer for batching
        updateQueue.async { [weak self] in
            self?.updateBuffer.append(update)
        }
        
        // Visual feedback immediately
        Task { @MainActor in
            self.gridState.setPending(for: update.playerId, hole: update.hole)
        }
    }
    
    /// Submit multiple updates simultaneously
    func submitBatchUpdate(_ updates: [PlayerScoreUpdate]) {
        updateQueue.async { [weak self] in
            self?.updateBuffer.append(contentsOf: updates)
        }
        
        Task { @MainActor in
            for update in updates {
                self.gridState.setPending(for: update.playerId, hole: update.hole)
            }
        }
    }
    
    /// Process gesture-based update with prediction
    func processGestureUpdate(
        playerId: UUID,
        hole: Int,
        gesture: SwipeData,
        currentScore: Int
    ) -> ScoreUpdateResult {
        
        // Get player's gesture profile
        let player = Player(id: playerId, name: "", handicap: 0)
        let gestureService = GestureScoreService.shared
        let scoreChange = gestureService.interpretGesture(gesture, for: player)
        
        // Calculate new score
        let newScore: Int
        if gesture.direction == .up {
            newScore = max(1, currentScore - scoreChange.value)
        } else {
            newScore = currentScore + scoreChange.value
        }
        
        // Create update with confidence
        let update = PlayerScoreUpdate(
            playerId: playerId,
            hole: hole,
            score: newScore,
            previousScore: currentScore,
            timestamp: Date(),
            source: .gesture(confidence: scoreChange.confidence),
            animationStyle: scoreChange.animationStyle
        )
        
        // Submit for processing
        submitScoreUpdate(update)
        
        return ScoreUpdateResult(
            accepted: true,
            finalScore: newScore,
            confidence: scoreChange.confidence,
            animation: scoreChange.animationStyle
        )
    }
    
    /// Get optimized grid layout for current players
    func getOptimizedGridLayout(
        playerCount: Int,
        screenWidth: CGFloat
    ) -> GridLayoutConfiguration {
        
        let configuration: GridLayoutConfiguration
        
        switch playerCount {
        case 1:
            configuration = GridLayoutConfiguration(
                columns: 1,
                rows: 1,
                cellSize: CGSize(width: screenWidth * 0.9, height: 120),
                spacing: 16,
                scrollDirection: .vertical
            )
        case 2:
            configuration = GridLayoutConfiguration(
                columns: 1,
                rows: 2,
                cellSize: CGSize(width: screenWidth * 0.9, height: 100),
                spacing: 12,
                scrollDirection: .vertical
            )
        case 3...4:
            configuration = GridLayoutConfiguration(
                columns: 2,
                rows: 2,
                cellSize: CGSize(width: (screenWidth - 48) / 2, height: 90),
                spacing: 12,
                scrollDirection: .vertical
            )
        case 5...6:
            configuration = GridLayoutConfiguration(
                columns: 2,
                rows: 3,
                cellSize: CGSize(width: (screenWidth - 48) / 2, height: 80),
                spacing: 10,
                scrollDirection: .vertical
            )
        case 7...8:
            configuration = GridLayoutConfiguration(
                columns: 2,
                rows: 4,
                cellSize: CGSize(width: (screenWidth - 48) / 2, height: 75),
                spacing: 8,
                scrollDirection: .vertical
            )
        default:
            // More than 8 players - use 3 column grid
            let columns = 3
            let rows = (playerCount + columns - 1) / columns
            configuration = GridLayoutConfiguration(
                columns: columns,
                rows: rows,
                cellSize: CGSize(width: (screenWidth - 64) / 3, height: 70),
                spacing: 8,
                scrollDirection: .vertical
            )
        }
        
        return configuration
    }
    
    /// Resolve conflicts when multiple updates affect same player/hole
    func resolveConflict(_ conflict: UpdateConflict) -> ConflictResolution {
        let resolution: ConflictResolution
        
        switch conflict.type {
        case .simultaneousUpdate:
            // Last write wins for simultaneous updates
            let winner = conflict.updates.max { $0.timestamp < $1.timestamp }!
            resolution = ConflictResolution(
                conflict: conflict,
                resolvedUpdate: winner,
                strategy: .lastWriteWins
            )
            
        case .gestureCollision:
            // Higher confidence gesture wins
            let winner = conflict.updates.max { update1, update2 in
                guard case .gesture(let conf1) = update1.source,
                      case .gesture(let conf2) = update2.source else {
                    return false
                }
                return conf1 < conf2
            }!
            resolution = ConflictResolution(
                conflict: conflict,
                resolvedUpdate: winner,
                strategy: .highestConfidence
            )
            
        case .validation:
            // Take the most reasonable score
            let par = 4 // TODO: Get actual par
            let winner = conflict.updates.min { abs($0.score - par) < abs($1.score - par) }!
            resolution = ConflictResolution(
                conflict: conflict,
                resolvedUpdate: winner,
                strategy: .closestToPar
            )
        }
        
        // Store resolution for UI feedback
        conflictResolutions.append(resolution)
        
        return resolution
    }
    
    // MARK: - Private Methods
    
    private func setupUpdateBatching() {
        // Process updates in batches every 100ms
        updateTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            self?.processBatchedUpdates()
        }
    }
    
    private func processBatchedUpdates() {
        updateQueue.async { [weak self] in
            guard let self = self,
                  !self.updateBuffer.isEmpty else { return }
            
            let updates = self.updateBuffer
            self.updateBuffer.removeAll()
            
            Task { @MainActor in
                await self.processBatch(updates)
            }
        }
    }
    
    @MainActor
    private func processBatch(_ updates: [PlayerScoreUpdate]) async {
        isProcessingBatch = true
        
        // Group updates by player and hole to detect conflicts
        var groupedUpdates: [PlayerHoleKey: [PlayerScoreUpdate]] = [:]
        
        for update in updates {
            let key = PlayerHoleKey(playerId: update.playerId, hole: update.hole)
            groupedUpdates[key, default: []].append(update)
        }
        
        // Process each group
        var finalUpdates: [PlayerScoreUpdate] = []
        
        for (key, group) in groupedUpdates {
            if group.count > 1 {
                // Conflict detected
                let conflict = UpdateConflict(
                    playerId: key.playerId,
                    hole: key.hole,
                    updates: group,
                    type: determineConflictType(group)
                )
                
                let resolution = resolveConflict(conflict)
                finalUpdates.append(resolution.resolvedUpdate)
            } else {
                finalUpdates.append(group[0])
            }
        }
        
        // Apply final updates to grid state
        for update in finalUpdates {
            gridState.applyUpdate(update)
            
            // Notify game state (integrate with existing GameState)
            notifyGameState(update)
        }
        
        // Clear pending states
        for update in finalUpdates {
            gridState.clearPending(for: update.playerId, hole: update.hole)
        }
        
        isProcessingBatch = false
    }
    
    private func determineConflictType(_ updates: [PlayerScoreUpdate]) -> ConflictType {
        // Check if all updates are gestures
        let allGestures = updates.allSatisfy { update in
            if case .gesture = update.source { return true }
            return false
        }
        
        if allGestures {
            return .gestureCollision
        }
        
        // Check if updates are within 100ms of each other
        let timestamps = updates.map { $0.timestamp.timeIntervalSince1970 }
        let minTime = timestamps.min()!
        let maxTime = timestamps.max()!
        
        if maxTime - minTime < 0.1 {
            return .simultaneousUpdate
        }
        
        return .validation
    }
    
    private func notifyGameState(_ update: PlayerScoreUpdate) {
        // Post notification for game state to handle
        NotificationCenter.default.post(
            name: .scoreUpdateProcessed,
            object: nil,
            userInfo: [
                "playerId": update.playerId,
                "hole": update.hole,
                "score": update.score
            ]
        )
    }
}

// MARK: - Supporting Types

struct PlayerScoreUpdate {
    let playerId: UUID
    let hole: Int
    let score: Int
    let previousScore: Int
    let timestamp: Date
    let source: UpdateSource
    let animationStyle: AnimationStyle
}

enum UpdateSource {
    case manual
    case gesture(confidence: Double)
    case voice
    case quickButton
}

struct ScoreUpdateResult {
    let accepted: Bool
    let finalScore: Int
    let confidence: Double
    let animation: AnimationStyle
}

struct GridState {
    private var scores: [PlayerHoleKey: Int] = [:]
    private var pendingUpdates: Set<PlayerHoleKey> = []
    private var lastUpdate: [PlayerHoleKey: Date] = [:]
    
    mutating func applyUpdate(_ update: PlayerScoreUpdate) {
        let key = PlayerHoleKey(playerId: update.playerId, hole: update.hole)
        scores[key] = update.score
        lastUpdate[key] = update.timestamp
    }
    
    mutating func setPending(for playerId: UUID, hole: Int) {
        let key = PlayerHoleKey(playerId: playerId, hole: hole)
        pendingUpdates.insert(key)
    }
    
    mutating func clearPending(for playerId: UUID, hole: Int) {
        let key = PlayerHoleKey(playerId: playerId, hole: hole)
        pendingUpdates.remove(key)
    }
    
    func isPending(for playerId: UUID, hole: Int) -> Bool {
        let key = PlayerHoleKey(playerId: playerId, hole: hole)
        return pendingUpdates.contains(key)
    }
    
    func getScore(for playerId: UUID, hole: Int) -> Int? {
        let key = PlayerHoleKey(playerId: playerId, hole: hole)
        return scores[key]
    }
}

struct PlayerHoleKey: Hashable {
    let playerId: UUID
    let hole: Int
}

struct GridLayoutConfiguration {
    let columns: Int
    let rows: Int
    let cellSize: CGSize
    let spacing: CGFloat
    let scrollDirection: Axis
}

struct UpdateConflict {
    let playerId: UUID
    let hole: Int
    let updates: [PlayerScoreUpdate]
    let type: ConflictType
}

enum ConflictType {
    case simultaneousUpdate
    case gestureCollision
    case validation
}

struct ConflictResolution {
    let conflict: UpdateConflict
    let resolvedUpdate: PlayerScoreUpdate
    let strategy: ResolutionStrategy
}

enum ResolutionStrategy {
    case lastWriteWins
    case highestConfidence
    case closestToPar
    case userChoice
}

// MARK: - Notification Names

extension Notification.Name {
    static let scoreUpdateProcessed = Notification.Name("scoreUpdateProcessed")
    static let conflictResolved = Notification.Name("conflictResolved")
    static let gridLayoutChanged = Notification.Name("gridLayoutChanged")
}