import SwiftUI

// MARK: - Scorecard Container

struct ScorecardContainerView: View {
    let format: GolfFormat
    let configuration: GameConfiguration
    @State private var currentHole = 1
    @State private var gameState = GameState()
    @State private var showMenu = false
    @State private var showStats = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Light background
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ContainerScorecardHeader(
                    format: format,
                    currentHole: $currentHole,
                    totalHoles: configuration.numberOfHoles,
                    onMenu: { showMenu = true },
                    onStats: { showStats = true }
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
                
                // Bottom Navigation
                ScorecardBottomNav(
                    currentHole: $currentHole,
                    totalHoles: configuration.numberOfHoles,
                    gameState: gameState
                )
            }
        }
        .sheet(isPresented: $showMenu) {
            ScorecardMenuView(
                format: format,
                gameState: gameState,
                onEndGame: {
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showStats) {
            GameStatsView(
                format: format,
                gameState: gameState,
                configuration: configuration
            )
        }
    }
    
    @ViewBuilder
    func getScorecardView(for format: GolfFormat, hole: Int) -> some View {
        switch format.name {
        case "Scramble":
            ScrambleScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Best Ball":
            BestBallScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Match Play":
            MatchPlayScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Skins":
            SkinsScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Stableford":
            StablefordScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Nassau":
            NassauScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Wolf":
            WolfScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Vegas":
            VegasScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Four-Ball":
            FourBallScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Alternate Shot":
            AlternateShotScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Bingo Bango Bongo":
            BingoBangoBongoScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        case "Chapman":
            ChapmanScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        default:
            GenericScorecardView(
                hole: hole,
                configuration: configuration,
                gameState: gameState
            )
        }
    }
}

// MARK: - Game State

class GameState: ObservableObject {
    @Published var scores: [Int: [UUID: Int]] = [:]  // [hole: [playerID: score]]
    @Published var scrambleSelections: [Int: UUID] = [:]  // [hole: selectedPlayerID]
    @Published var putts: [Int: [UUID: Int]] = [:]  // [hole: [playerID: putts]]
    @Published var fairwayHits: [Int: [UUID: Bool]] = [:]
    @Published var greensInRegulation: [Int: [UUID: Bool]] = [:]
    
    // Match Play specific
    @Published var matchPlayStatus: MatchPlayStatus = MatchPlayStatus()
    
    // Skins specific
    @Published var skinsWon: [Int: UUID] = [:]
    @Published var skinValues: [Int: Int] = [:]
    
    // Nassau specific
    @Published var nassauMatches: NassauMatches = NassauMatches()
    
    // Wolf specific
    @Published var wolfSelections: [Int: WolfSelection] = [:]
    
    // Vegas specific
    @Published var vegasFlips: [Int: Bool] = [:]
    
    func getScore(hole: Int, player: UUID) -> Int {
        scores[hole]?[player] ?? 0
    }
    
    func setScore(hole: Int, player: UUID, score: Int) {
        if scores[hole] == nil {
            scores[hole] = [:]
        }
        scores[hole]?[player] = score
    }
}

// MARK: - Format-Specific State Models

struct MatchPlayStatus: Equatable, Codable {
    var holesWon: [UUID: Int] = [:]
    var currentStatus: String = "All Square"
    var holesUp: Int = 0
}

struct NassauMatches: Equatable, Codable {
    var front9: MatchStatus = MatchStatus()
    var back9: MatchStatus = MatchStatus()
    var overall: MatchStatus = MatchStatus()
    var presses: [Press] = []
}

struct MatchStatus: Equatable, Codable {
    var leader: UUID?
    var holesUp: Int = 0
}

struct Press: Equatable, Codable {
    let hole: Int
    let type: PressType
    let value: Int
}

enum PressType: Codable {
    case front, back, overall
}

struct WolfSelection: Equatable {
    let wolf: UUID
    let partner: UUID?
    let isLoneWolf: Bool
    let isBlindWolf: Bool
}

// MARK: - Container Scorecard Header

struct ContainerScorecardHeader: View {
    let format: GolfFormat
    @Binding var currentHole: Int
    let totalHoles: Int
    let onMenu: () -> Void
    let onStats: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onMenu) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
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
        .background(AppColors.headerGradient)
        .cornerRadius(12)
        .shadow(color: AppColors.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Scorecard Bottom Navigation

struct ScorecardBottomNav: View {
    @Binding var currentHole: Int
    let totalHoles: Int
    let gameState: GameState
    
    var body: some View {
        HStack(spacing: 30) {
            // Previous Hole
            Button(action: {
                if currentHole > 1 {
                    withAnimation {
                        currentHole -= 1
                    }
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .foregroundColor(currentHole > 1 ? .white : .white.opacity(0.3))
            }
            .disabled(currentHole == 1)
            
            // Hole Indicator
            HStack(spacing: 4) {
                ForEach(1...min(totalHoles, 9), id: \.self) { hole in
                    Circle()
                        .fill(hole == currentHole ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                if totalHoles > 9 {
                    Text("...")
                        .foregroundColor(.white.opacity(0.5))
                    
                    ForEach(max(10, currentHole-1)...min(totalHoles, max(10, currentHole+1)), id: \.self) { hole in
                        Circle()
                            .fill(hole == currentHole ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            // Next Hole
            Button(action: {
                if currentHole < totalHoles {
                    withAnimation {
                        currentHole += 1
                    }
                }
            }) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(currentHole < totalHoles ? .white : .white.opacity(0.3))
            }
            .disabled(currentHole == totalHoles)
        }
        .padding()
        .background(AppColors.headerGradient)
        .cornerRadius(12)
        .shadow(color: AppColors.cardShadow, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Menu View

struct ScorecardMenuView: View {
    let format: GolfFormat
    let gameState: GameState
    let onEndGame: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showEndGameConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        // Save game logic
                        dismiss()
                    }) {
                        Label("Save Game", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: {
                        // Export scorecard
                        dismiss()
                    }) {
                        Label("Export Scorecard", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section {
                    Button(action: {
                        // Game settings
                        dismiss()
                    }) {
                        Label("Game Settings", systemImage: "gearshape")
                    }
                    
                    Button(action: {
                        // Scoring rules
                        dismiss()
                    }) {
                        Label("Scoring Rules", systemImage: "book")
                    }
                }
                
                Section {
                    Button(action: {
                        showEndGameConfirmation = true
                    }) {
                        Label("End Game", systemImage: "xmark.circle")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("End Game?", isPresented: $showEndGameConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("End Game", role: .destructive) {
                    onEndGame()
                }
            } message: {
                Text("Are you sure you want to end this game? Your progress will be saved.")
            }
        }
    }
}

// MARK: - Game Stats View

struct GameStatsView: View {
    let format: GolfFormat
    let gameState: GameState
    let configuration: GameConfiguration
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Score Summary
                    OverallScoreCard(
                        gameState: gameState,
                        configuration: configuration
                    )
                    
                    // Player Statistics
                    ForEach(configuration.players.filter { $0.isActive }) { player in
                        PlayerStatsCard(
                            player: player,
                            gameState: gameState
                        )
                    }
                    
                    // Format-Specific Stats
                    if format.name == "Skins" {
                        SkinsStatsCard(gameState: gameState)
                    } else if format.name == "Nassau" {
                        NassauStatsCard(gameState: gameState)
                    }
                }
                .padding()
            }
            .navigationTitle("Game Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}