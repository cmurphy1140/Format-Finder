import SwiftUI
import Combine

// MARK: - Async State Manager

/// Centralized state management for async operations
/// Provides reactive state updates and optimistic mutations
@MainActor
final class AsyncStateManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var players: LoadableState<[Player]> = .idle
    @Published var currentRound: LoadableState<Round> = .idle
    @Published var courses: LoadableState<[Course]> = .idle
    @Published var recentRounds: LoadableState<[Round]> = .idle
    @Published var statistics: LoadableState<PlayerStatistics> = .idle
    
    // MARK: - Optimistic Updates
    
    @Published var optimisticChanges: [OptimisticChange] = []
    @Published var hasPendingChanges: Bool = false
    
    // MARK: - Error Recovery
    
    @Published var errorRecoveryStrategies: [ErrorRecoveryStrategy] = []
    @Published var isRecovering: Bool = false
    
    // MARK: - Dependencies
    
    private let coordinator: AsyncFrontendCoordinator
    private var cancellables = Set<AnyCancellable>()
    private let changeDebouncer = PassthroughSubject<StateChange, Never>()
    
    init(coordinator: AsyncFrontendCoordinator) {
        self.coordinator = coordinator
        setupBindings()
        setupDebouncing()
    }
    
    // MARK: - State Bindings
    
    private func setupBindings() {
        // React to backend status changes
        coordinator.$backendStatus
            .sink { [weak self] status in
                self?.handleBackendStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Monitor sync status
        coordinator.$syncStatus
            .sink { [weak self] status in
                self?.handleSyncStatusChange(status)
            }
            .store(in: &cancellables)
        
        // Track pending operations
        coordinator.$pendingOperations
            .map { !$0.isEmpty }
            .assign(to: &$hasPendingChanges)
    }
    
    private func setupDebouncing() {
        changeDebouncer
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] change in
                Task {
                    await self?.applyStateChange(change)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadPlayers() async {
        players = .loading
        
        let operation = AsyncOperation<[Player]>(
            type: .fetch,
            timeout: 10
        ) {
            // Simulate async backend fetch
            try await Task.sleep(nanoseconds: 500_000_000)
            return Player.mockPlayers()
        }
        
        do {
            let result = try await coordinator.executeAsyncOperation(operation)
            players = .loaded(result)
        } catch {
            players = .error(error)
            await attemptRecovery(for: error, retryAction: loadPlayers)
        }
    }
    
    func loadCurrentRound() async {
        currentRound = .loading
        
        let operation = AsyncOperation<Round>(
            type: .fetch,
            timeout: 10
        ) {
            // Check cache first
            if let cached = await self.getCachedCurrentRound() {
                return cached
            }
            
            // Fetch from backend
            try await Task.sleep(nanoseconds: 500_000_000)
            return Round.mockCurrent()
        }
        
        do {
            let result = try await coordinator.executeAsyncOperation(operation)
            currentRound = .loaded(result)
        } catch {
            currentRound = .error(error)
            // Try to load from cache as fallback
            if let cached = await getCachedCurrentRound() {
                currentRound = .loaded(cached, isStale: true)
            }
        }
    }
    
    func loadCourses() async {
        courses = .loading
        
        let operation = AsyncOperation<[Course]>(
            type: .fetch,
            timeout: 15
        ) {
            try await Task.sleep(nanoseconds: 700_000_000)
            return Course.mockCourses()
        }
        
        do {
            let result = try await coordinator.executeAsyncOperation(operation)
            courses = .loaded(result)
        } catch {
            courses = .error(error)
        }
    }
    
    // MARK: - Optimistic Updates
    
    func updateScoreOptimistically(hole: Int, score: Int) {
        guard case .loaded(var round) = currentRound else { return }
        
        // Store original value for rollback
        let originalScore = round.scores[hole] ?? 0
        let change = OptimisticChange(
            id: UUID(),
            type: .scoreUpdate,
            timestamp: Date(),
            rollback: { [weak self] in
                self?.rollbackScore(hole: hole, to: originalScore)
            }
        )
        
        // Apply optimistic update
        round.scores[hole] = score
        currentRound = .loaded(round, isOptimistic: true)
        optimisticChanges.append(change)
        
        // Send to backend
        Task {
            await persistScoreUpdate(hole: hole, score: score, change: change)
        }
    }
    
    private func persistScoreUpdate(hole: Int, score: Int, change: OptimisticChange) async {
        let operation = AsyncOperation<Void>(
            type: .update,
            timeout: 5
        ) {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            // Backend update would happen here
        }
        
        do {
            try await coordinator.executeAsyncOperation(operation)
            // Remove from optimistic changes on success
            optimisticChanges.removeAll { $0.id == change.id }
        } catch {
            // Rollback on failure
            change.rollback()
            optimisticChanges.removeAll { $0.id == change.id }
            await showError(error)
        }
    }
    
    private func rollbackScore(hole: Int, to originalScore: Int) {
        guard case .loaded(var round) = currentRound else { return }
        round.scores[hole] = originalScore
        currentRound = .loaded(round)
    }
    
    // MARK: - State Changes
    
    private func handleBackendStatusChange(_ status: BackendConnectionStatus) {
        switch status {
        case .connected:
            // Refresh stale data
            Task {
                await refreshStaleData()
            }
            
        case .offline:
            // Mark all loaded states as potentially stale
            markAllStatesAsStale()
            
        case .error(let message):
            // Show error recovery options
            errorRecoveryStrategies = [
                .retry,
                .useOfflineMode,
                .contactSupport
            ]
            
        default:
            break
        }
    }
    
    private func handleSyncStatusChange(_ status: SyncStatus) {
        switch status {
        case .syncing(let progress):
            // Update UI with sync progress
            break
            
        case .completed:
            // Clear optimistic changes
            optimisticChanges.removeAll()
            
        case .failed(let error):
            // Show sync error
            Task {
                await showError(SyncError(message: error))
            }
            
        default:
            break
        }
    }
    
    // MARK: - Error Recovery
    
    private func attemptRecovery(for error: Error, retryAction: @escaping () async -> Void) async {
        isRecovering = true
        defer { isRecovering = false }
        
        // Check if error is recoverable
        guard let strategy = determineRecoveryStrategy(for: error) else {
            await showError(error)
            return
        }
        
        switch strategy {
        case .retry:
            await retryAction()
            
        case .useOfflineMode:
            coordinator.dataAvailability = .localOnly
            
        case .clearCacheAndRetry:
            await clearCache()
            await retryAction()
            
        default:
            break
        }
    }
    
    private func determineRecoveryStrategy(for error: Error) -> ErrorRecoveryStrategy? {
        if error.isNetworkError {
            return .useOfflineMode
        } else if error.isTimeout {
            return .retry
        } else if error.isDataCorrupted {
            return .clearCacheAndRetry
        }
        return nil
    }
    
    // MARK: - Utility Functions
    
    private func refreshStaleData() async {
        if players.isStale {
            await loadPlayers()
        }
        if currentRound.isStale {
            await loadCurrentRound()
        }
        if courses.isStale {
            await loadCourses()
        }
    }
    
    private func markAllStatesAsStale() {
        players = players.markAsStale()
        currentRound = currentRound.markAsStale()
        courses = courses.markAsStale()
        recentRounds = recentRounds.markAsStale()
        statistics = statistics.markAsStale()
    }
    
    private func getCachedCurrentRound() async -> Round? {
        // Check local cache
        return nil // Placeholder
    }
    
    private func clearCache() async {
        // Clear all cached data
    }
    
    private func showError(_ error: Error) async {
        // Display error to user
    }
    
    private func applyStateChange(_ change: StateChange) async {
        // Apply debounced state changes
    }
}

// MARK: - Loadable State

enum LoadableState<T> {
    case idle
    case loading
    case loaded(T, isStale: Bool = false, isOptimistic: Bool = false)
    case error(Error)
    
    var value: T? {
        if case .loaded(let data, _, _) = self {
            return data
        }
        return nil
    }
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var isStale: Bool {
        if case .loaded(_, let stale, _) = self {
            return stale
        }
        return false
    }
    
    func markAsStale() -> LoadableState<T> {
        if case .loaded(let data, _, let optimistic) = self {
            return .loaded(data, isStale: true, isOptimistic: optimistic)
        }
        return self
    }
}

// MARK: - Supporting Types

struct OptimisticChange: Identifiable {
    let id: UUID
    let type: OptimisticChangeType
    let timestamp: Date
    let rollback: () -> Void
}

enum OptimisticChangeType {
    case scoreUpdate
    case playerAdd
    case roundCreate
    case courseUpdate
}

enum ErrorRecoveryStrategy {
    case retry
    case useOfflineMode
    case clearCacheAndRetry
    case contactSupport
}

struct StateChange {
    let type: StateChangeType
    let payload: Any
}

enum StateChangeType {
    case playerUpdate
    case roundUpdate
    case courseUpdate
}

// MARK: - Mock Data

extension Player {
    static func mockPlayers() -> [Player] {
        [
            Player(id: UUID(), name: "John Doe", handicap: 10),
            Player(id: UUID(), name: "Jane Smith", handicap: 15),
            Player(id: UUID(), name: "Bob Wilson", handicap: 8)
        ]
    }
}

extension Round {
    static func mockCurrent() -> Round {
        Round(
            id: UUID(),
            course: "Pebble Beach",
            date: Date(),
            players: ["John Doe"],
            scores: [1: 4, 2: 5, 3: 3]
        )
    }
}

extension Course {
    static func mockCourses() -> [Course] {
        [
            Course(id: UUID(), name: "Pebble Beach", holes: 18, par: 72),
            Course(id: UUID(), name: "Augusta National", holes: 18, par: 72),
            Course(id: UUID(), name: "St Andrews", holes: 18, par: 72)
        ]
    }
}

// MARK: - Error Extensions

extension Error {
    var isNetworkError: Bool {
        // Check if error is network related
        return false
    }
    
    var isTimeout: Bool {
        // Check if error is timeout
        return false
    }
    
    var isDataCorrupted: Bool {
        // Check if data is corrupted
        return false
    }
}

struct SyncError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        message
    }
}

// MARK: - Model Types

struct Player: Identifiable {
    let id: UUID
    let name: String
    let handicap: Int
}

struct Round: Identifiable {
    let id: UUID
    let course: String
    let date: Date
    let players: [String]
    var scores: [Int: Int]
}

struct Course: Identifiable {
    let id: UUID
    let name: String
    let holes: Int
    let par: Int
}

struct PlayerStatistics {
    let averageScore: Double
    let bestRound: Int
    let totalRounds: Int
    let favoriteVourse: String
}