import SwiftUI
import Combine

// MARK: - State Adapter

/// Bridges the new Redux-style state management with existing SwiftUI views
final class StateAdapter: ObservableObject {
    @Published var legacyGameState: GameState
    
    private let store: GameStore
    private var cancellables = Set<AnyCancellable>()
    private let featureFlags = FeatureFlags.shared
    
    init(store: GameStore? = nil) {
        self.store = store ?? GameStore()
        self.legacyGameState = GameState()
        
        setupBindings()
    }
    
    // MARK: - Setup Bindings
    
    private func setupBindings() {
        // Sync new store state to legacy GameState
        store.$state
            .sink { [weak self] newState in
                self?.updateLegacyState(from: newState)
            }
            .store(in: &cancellables)
    }
    
    private func updateLegacyState(from state: GameAppState) {
        // Map new state to legacy GameState
        if let round = state.currentRound {
            // Update scores
            for (hole, playerScores) in round.scores {
                for (player, score) in playerScores {
                    legacyGameState.setScore(hole: hole, player: player.id, score: score)
                }
            }
            
            // Update format-specific state
            if let matchPlayStatus = round.metadata.matchPlayStatus {
                legacyGameState.matchPlayStatus = matchPlayStatus
            }
            
            legacyGameState.skinsCarryover = round.metadata.skinsCarryover
            
            // Update scramble selections
            for (hole, player) in round.metadata.scrambleSelections {
                legacyGameState.scrambleSelections[hole] = player.id
            }
            
            // Update wolf selections
            for (hole, selection) in round.metadata.wolfSelections {
                legacyGameState.wolfSelections[hole] = selection
            }
            
            // Update Nassau matches
            if let nassauMatches = round.metadata.nassauMatches {
                legacyGameState.nassauMatches = nassauMatches
            }
        }
    }
    
    // MARK: - Public Interface (Used by existing views)
    
    func startRound(format: GolfFormat, configuration: GameConfiguration) {
        if featureFlags.useNewStateManagement {
            // Use new system
            let formatType = FormatType(rawValue: format.name) ?? .scramble
            let players = configuration.players.map { player in
                PlayerIdentifier(id: player.id, name: player.name, handicap: player.handicap)
            }
            
            store.dispatch(.startRound(format: formatType, players: players, configuration: configuration))
        } else {
            // Use legacy system
            // Existing implementation
        }
    }
    
    func updateScore(hole: Int, player: UUID, score: Int) {
        if featureFlags.useNewStateManagement {
            // Find player identifier
            if let playerIdentifier = store.state.players.first(where: { $0.id == player }) {
                store.dispatch(.updateScore(hole: hole, player: playerIdentifier, score: score))
            }
        } else {
            // Use legacy system
            legacyGameState.setScore(hole: hole, player: player, score: score)
        }
    }
    
    func recordScrambleSelection(hole: Int, player: UUID, shotType: String) {
        if featureFlags.useNewStateManagement {
            if let playerIdentifier = store.state.players.first(where: { $0.id == player }),
               let shot = ShotType(rawValue: shotType) {
                store.dispatch(.selectScrambleBall(hole: hole, player: playerIdentifier, shotType: shot))
            }
        } else {
            legacyGameState.scrambleSelections[hole] = player
        }
    }
    
    func updateMatchPlayStatus(_ status: MatchPlayStatus) {
        if featureFlags.useNewStateManagement {
            store.dispatch(.updateMatchPlayStatus(status))
        } else {
            legacyGameState.matchPlayStatus = status
        }
    }
    
    func navigateToHole(_ hole: Int) {
        if featureFlags.useNewStateManagement {
            store.dispatch(.navigateToHole(hole))
        }
        // Also update UI state if needed
    }
    
    // MARK: - Time Travel Debugging
    
    var canUndo: Bool {
        featureFlags.enableTimeTravelDebugging && store.canUndo()
    }
    
    var canRedo: Bool {
        featureFlags.enableTimeTravelDebugging && store.canRedo()
    }
    
    func undo() {
        guard featureFlags.enableTimeTravelDebugging else { return }
        store.undo()
    }
    
    func redo() {
        guard featureFlags.enableTimeTravelDebugging else { return }
        store.redo()
    }
}

// MARK: - Modified Scorecard Container

/// Updated ScorecardContainerView that uses StateAdapter
struct EnhancedScorecardContainerView: View {
    let format: GolfFormat
    let configuration: GameConfiguration
    @State private var currentHole = 1
    @StateObject private var stateAdapter = StateAdapter()
    @State private var showMenu = false
    @State private var showStats = false
    @State private var showDebugPanel = false
    @Environment(\.dismiss) var dismiss
    
    private var featureFlags = FeatureFlags.shared
    
    var body: some View {
        ZStack {
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Enhanced Header with Time Travel Controls
                EnhancedHeader(
                    format: format,
                    currentHole: $currentHole,
                    totalHoles: configuration.numberOfHoles,
                    canUndo: stateAdapter.canUndo,
                    canRedo: stateAdapter.canRedo,
                    onMenu: { showMenu = true },
                    onStats: { showStats = true },
                    onUndo: { stateAdapter.undo() },
                    onRedo: { stateAdapter.redo() }
                )
                
                // Main Scorecard Content
                TabView(selection: $currentHole) {
                    ForEach(1...configuration.numberOfHoles, id: \.self) { hole in
                        getScorecardView(for: format, hole: hole)
                            .tag(hole)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .background(AppColors.cardBackground)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: -2)
                .onChange(of: currentHole) { newHole in
                    stateAdapter.navigateToHole(newHole)
                }
                
                // Bottom Navigation
                ScorecardBottomNav(
                    currentHole: $currentHole,
                    totalHoles: configuration.numberOfHoles,
                    gameState: stateAdapter.legacyGameState
                )
            }
            
            // Debug Panel (only in DEBUG builds)
            #if DEBUG
            if showDebugPanel {
                DebugPanel(stateAdapter: stateAdapter)
            }
            #endif
        }
        .onAppear {
            stateAdapter.startRound(format: format, configuration: configuration)
        }
        .sheet(isPresented: $showMenu) {
            EnhancedMenuView(
                format: format,
                stateAdapter: stateAdapter,
                showDebugPanel: $showDebugPanel,
                onEndGame: { dismiss() }
            )
        }
        .sheet(isPresented: $showStats) {
            EnhancedStatsView(
                format: format,
                stateAdapter: stateAdapter,
                configuration: configuration
            )
        }
    }
    
    @ViewBuilder
    func getScorecardView(for format: GolfFormat, hole: Int) -> some View {
        // Use existing scorecard views but pass stateAdapter
        switch format.name {
        case "Scramble":
            AdaptedScrambleScorecardView(
                hole: hole,
                configuration: configuration,
                stateAdapter: stateAdapter
            )
        default:
            // Other adapted scorecard views
            Text("Format: \(format.name)")
        }
    }
}

// MARK: - Enhanced Header with Time Travel

struct EnhancedHeader: View {
    let format: GolfFormat
    @Binding var currentHole: Int
    let totalHoles: Int
    let canUndo: Bool
    let canRedo: Bool
    let onMenu: () -> Void
    let onStats: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onMenu) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            // Time Travel Controls (if enabled)
            if FeatureFlags.shared.enableTimeTravelDebugging {
                HStack(spacing: 8) {
                    Button(action: onUndo) {
                        Image(systemName: "arrow.uturn.backward")
                            .foregroundColor(canUndo ? .white : .white.opacity(0.3))
                    }
                    .disabled(!canUndo)
                    
                    Button(action: onRedo) {
                        Image(systemName: "arrow.uturn.forward")
                            .foregroundColor(canRedo ? .white : .white.opacity(0.3))
                    }
                    .disabled(!canRedo)
                }
                .padding(.leading, 8)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(format.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Hole \(currentHole) of \(totalHoles)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: onStats) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(AppColors.primaryGreen)
    }
}

// MARK: - Adapted Scramble Scorecard

struct AdaptedScrambleScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    @ObservedObject var stateAdapter: StateAdapter
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(configuration.players, id: \.id) { player in
                    PlayerScoreCard(
                        player: player,
                        hole: hole,
                        score: stateAdapter.legacyGameState.scores[hole]?[player.id],
                        onScoreUpdate: { score in
                            stateAdapter.updateScore(hole: hole, player: player.id, score: score)
                        }
                    )
                }
                
                // Ball selection section
                if FeatureFlags.shared.useNewGameEngine {
                    BallSelectionView(
                        hole: hole,
                        players: configuration.players,
                        onSelection: { player, shotType in
                            stateAdapter.recordScrambleSelection(
                                hole: hole,
                                player: player.id,
                                shotType: shotType
                            )
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Debug Panel

#if DEBUG
struct DebugPanel: View {
    @ObservedObject var stateAdapter: StateAdapter
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Debug Panel")
                    .font(.headline)
                
                Text("State Management: \(FeatureFlags.shared.useNewStateManagement ? "Redux" : "Legacy")")
                    .font(.caption)
                
                Text("Persistence: \(FeatureFlags.shared.useCoreDataPersistence ? "Core Data" : "Memory")")
                    .font(.caption)
                
                Text("Sync: \(FeatureFlags.shared.useCloudKitSync ? "CloudKit" : "None")")
                    .font(.caption)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding()
        }
    }
}
#endif

// MARK: - Supporting Views

struct PlayerScoreCard: View {
    let player: Player
    let hole: Int
    let score: Int?
    let onScoreUpdate: (Int) -> Void
    
    var body: some View {
        HStack {
            Text(player.name)
            Spacer()
            Text("Score: \(score ?? 0)")
            Stepper("", value: Binding(
                get: { score ?? 0 },
                set: { onScoreUpdate($0) }
            ), in: 0...10)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }
}

struct BallSelectionView: View {
    let hole: Int
    let players: [Player]
    let onSelection: (Player, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Ball Selection")
                .font(.headline)
            
            ForEach(ShotType.allCases, id: \.self) { shotType in
                HStack {
                    Text(shotType.rawValue)
                    Spacer()
                    Menu("Select Player") {
                        ForEach(players, id: \.id) { player in
                            Button(player.name) {
                                onSelection(player, shotType.rawValue)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(8)
    }
}

struct EnhancedMenuView: View {
    let format: GolfFormat
    @ObservedObject var stateAdapter: StateAdapter
    @Binding var showDebugPanel: Bool
    let onEndGame: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("Resume Game") {
                        // Dismiss
                    }
                    
                    Button("Save Game") {
                        // Trigger save
                    }
                    
                    #if DEBUG
                    Toggle("Show Debug Panel", isOn: $showDebugPanel)
                    
                    NavigationLink("Feature Flags") {
                        FeatureFlagsDebugView()
                    }
                    #endif
                    
                    Button("End Game", role: .destructive) {
                        onEndGame()
                    }
                }
            }
            .navigationTitle("Game Menu")
        }
    }
}

struct EnhancedStatsView: View {
    let format: GolfFormat
    @ObservedObject var stateAdapter: StateAdapter
    let configuration: GameConfiguration
    
    var body: some View {
        Text("Enhanced Statistics View")
            .padding()
    }
}