import Foundation
import Combine
import SwiftUI

// MARK: - Game Store (Redux-like State Management)

@MainActor
final class GameStore: ObservableObject {
    @Published private(set) var state: GameAppState
    
    private var cancellables = Set<AnyCancellable>()
    private let middleware: [Middleware]
    private let reducer: Reducer<GameAppState, GameAction>
    
    // For time-travel debugging
    private var stateHistory: [GameAppState] = []
    private var currentHistoryIndex: Int = 0
    private let maxHistorySize = 50
    
    init(
        initialState: GameAppState = GameAppState(),
        middleware: [Middleware] = [],
        reducer: @escaping Reducer<GameAppState, GameAction> = gameReducer
    ) {
        self.state = initialState
        self.middleware = middleware
        self.reducer = reducer
        self.stateHistory.append(initialState)
    }
    
    func dispatch(_ action: GameAction) {
        // Apply reducer
        let newState = reducer(state, action)
        
        // Update state
        state = newState
        
        // Add to history for time-travel debugging
        addToHistory(newState)
        
        // Process middleware
        Task {
            for mw in middleware {
                await mw.process(action: action, state: newState, dispatch: dispatch)
            }
        }
        
        // Log action in debug mode
        #if DEBUG
        print("[GameStore] Action: \(action)")
        #endif
    }
    
    // MARK: - Time Travel Debugging
    
    func canUndo() -> Bool {
        currentHistoryIndex > 0
    }
    
    func canRedo() -> Bool {
        currentHistoryIndex < stateHistory.count - 1
    }
    
    func undo() {
        guard canUndo() else { return }
        currentHistoryIndex -= 1
        state = stateHistory[currentHistoryIndex]
    }
    
    func redo() {
        guard canRedo() else { return }
        currentHistoryIndex += 1
        state = stateHistory[currentHistoryIndex]
    }
    
    private func addToHistory(_ state: GameAppState) {
        // Remove any states after current index (for branching history)
        if currentHistoryIndex < stateHistory.count - 1 {
            stateHistory = Array(stateHistory[0...currentHistoryIndex])
        }
        
        // Add new state
        stateHistory.append(state)
        currentHistoryIndex = stateHistory.count - 1
        
        // Limit history size
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
            currentHistoryIndex -= 1
        }
    }
    
    // Default middleware
    static let defaultMiddleware: [Middleware] = [
        LoggingMiddleware(),
        PersistenceMiddleware(),
        AnalyticsMiddleware(),
        SyncMiddleware()
    ]
}

// MARK: - State

struct GameAppState: Equatable {
    var currentRound: RoundState?
    var players: [PlayerIdentifier] = []
    var gameConfiguration: GameConfiguration?
    var scoreHistory: [Int: [PlayerIdentifier: Int]] = [:]
    var formatEngine: FormatType?
    var ui: UIState = UIState()
    var sync: SyncState = SyncState()
}

struct RoundState: Equatable {
    let id: UUID
    let format: FormatType
    let startTime: Date
    var currentHole: Int
    var scores: [Int: [PlayerIdentifier: Int]]
    var isCompleted: Bool
    var metadata: RoundMetadata
}

struct RoundMetadata: Equatable {
    var scrambleSelections: [Int: PlayerIdentifier]
    var matchPlayStatus: MatchPlayStatus?
    var skinsCarryover: Double
    var wolfSelections: [Int: WolfSelection]
    var nassauMatches: NassauMatches?
}

struct UIState: Equatable {
    var showingStats: Bool = false
    var showingMenu: Bool = false
    var selectedPlayer: PlayerIdentifier?
    var animationTrigger: UUID = UUID()
}

struct SyncState: Equatable {
    var isSyncing: Bool = false
    var lastSyncTime: Date?
    var pendingChanges: Int = 0
    var syncErrors: [String] = []
}

// MARK: - Actions

enum GameAction {
    // Round Actions
    case startRound(format: FormatType, players: [PlayerIdentifier], configuration: GameConfiguration)
    case endRound
    case saveRound
    
    // Score Actions
    case updateScore(hole: Int, player: PlayerIdentifier, score: Int)
    case updateBulkScores([ScoreUpdate])
    case clearHoleScores(hole: Int)
    
    // Navigation Actions
    case navigateToHole(Int)
    case nextHole
    case previousHole
    
    // Format-Specific Actions
    case selectScrambleBall(hole: Int, player: PlayerIdentifier, shotType: ShotType)
    case updateMatchPlayStatus(MatchPlayStatus)
    case recordSkinWinner(hole: Int, player: PlayerIdentifier?)
    case selectWolfPartner(hole: Int, partner: PlayerIdentifier?)
    case recordNassauPress(hole: Int, type: PressType)
    
    // UI Actions
    case toggleStats
    case toggleMenu
    case selectPlayer(PlayerIdentifier?)
    case triggerAnimation
    
    // Sync Actions
    case startSync
    case syncCompleted(Date)
    case syncFailed(String)
    case updatePendingChanges(Int)
}

struct ScoreUpdate {
    let hole: Int
    let player: PlayerIdentifier
    let score: Int
}

// MARK: - Reducer

typealias Reducer<State, Action> = (State, Action) -> State

func gameReducer(state: GameAppState, action: GameAction) -> GameAppState {
    var newState = state
    
    switch action {
    case let .startRound(format, players, configuration):
        newState.currentRound = RoundState(
            id: UUID(),
            format: format,
            startTime: Date(),
            currentHole: 1,
            scores: [:],
            isCompleted: false,
            metadata: RoundMetadata(
                scrambleSelections: [:],
                matchPlayStatus: nil,
                skinsCarryover: 0,
                wolfSelections: [:],
                nassauMatches: nil
            )
        )
        newState.players = players
        newState.gameConfiguration = configuration
        newState.formatEngine = format
        
    case .endRound:
        if var round = newState.currentRound {
            round.isCompleted = true
            newState.currentRound = round
        }
        
    case .saveRound:
        // Trigger persistence through middleware
        break
        
    case let .updateScore(hole, player, score):
        if var round = newState.currentRound {
            if round.scores[hole] == nil {
                round.scores[hole] = [:]
            }
            round.scores[hole]?[player] = score
            newState.currentRound = round
            newState.scoreHistory[hole] = round.scores[hole]
        }
        
    case let .updateBulkScores(updates):
        if var round = newState.currentRound {
            for update in updates {
                if round.scores[update.hole] == nil {
                    round.scores[update.hole] = [:]
                }
                round.scores[update.hole]?[update.player] = update.score
            }
            newState.currentRound = round
        }
        
    case let .clearHoleScores(hole):
        if var round = newState.currentRound {
            round.scores[hole] = nil
            newState.currentRound = round
        }
        
    case let .navigateToHole(hole):
        if var round = newState.currentRound {
            round.currentHole = hole
            newState.currentRound = round
        }
        
    case .nextHole:
        if var round = newState.currentRound {
            let maxHoles = newState.gameConfiguration?.numberOfHoles ?? 18
            round.currentHole = min(round.currentHole + 1, maxHoles)
            newState.currentRound = round
        }
        
    case .previousHole:
        if var round = newState.currentRound {
            round.currentHole = max(round.currentHole - 1, 1)
            newState.currentRound = round
        }
        
    case let .selectScrambleBall(hole, player, _):
        if var round = newState.currentRound {
            round.metadata.scrambleSelections[hole] = player
            newState.currentRound = round
        }
        
    case let .updateMatchPlayStatus(status):
        if var round = newState.currentRound {
            round.metadata.matchPlayStatus = status
            newState.currentRound = round
        }
        
    case .recordSkinWinner:
        // Handle skins logic
        break
        
    case let .selectWolfPartner(hole, partner):
        if var round = newState.currentRound, let partner = partner {
            round.metadata.wolfSelections[hole] = WolfSelection(
                wolf: newState.players[hole % newState.players.count].id,
                partner: partner.id,
                isLoneWolf: false,
                isBlindWolf: false
            )
            newState.currentRound = round
        }
        
    case .recordNassauPress:
        // Handle Nassau press logic
        break
        
    case .toggleStats:
        newState.ui.showingStats.toggle()
        
    case .toggleMenu:
        newState.ui.showingMenu.toggle()
        
    case let .selectPlayer(player):
        newState.ui.selectedPlayer = player
        
    case .triggerAnimation:
        newState.ui.animationTrigger = UUID()
        
    case .startSync:
        newState.sync.isSyncing = true
        
    case let .syncCompleted(date):
        newState.sync.isSyncing = false
        newState.sync.lastSyncTime = date
        newState.sync.pendingChanges = 0
        newState.sync.syncErrors = []
        
    case let .syncFailed(error):
        newState.sync.isSyncing = false
        newState.sync.syncErrors.append(error)
        
    case let .updatePendingChanges(count):
        newState.sync.pendingChanges = count
    }
    
    return newState
}