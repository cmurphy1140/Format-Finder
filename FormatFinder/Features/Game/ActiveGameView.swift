import SwiftUI

// MARK: - Active Game View
struct ActiveGameView: View {
    @ObservedObject var session: GameSession
    @EnvironmentObject var appState: AppState
    @State private var showScoreEntry = false
    @State private var selectedPlayer: Player?
    @State private var showEndGameAlert = false
    @State private var currentTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Game Header
            GameHeaderView(session: session)
            
            // Tab View for different views
            TabView(selection: $currentTab) {
                // Scorecard View
                ScorecardView(session: session)
                    .tag(0)
                
                // Leaderboard View
                LeaderboardView(session: session)
                    .tag(1)
                
                // Stats View
                GameStatsView(session: session)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            
            // Score Entry Section
            ScoreEntrySection(
                session: session,
                showScoreEntry: $showScoreEntry,
                selectedPlayer: $selectedPlayer
            )
        }
        .navigationTitle(session.format.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { /* Show game info */ }) {
                        Label("Game Info", systemImage: "info.circle")
                    }
                    
                    Button(action: { /* Edit scores */ }) {
                        Label("Edit Scores", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        showEndGameAlert = true
                    }) {
                        Label("End Game", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("End Game?", isPresented: $showEndGameAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Game", role: .destructive) {
                appState.endCurrentGame()
            }
        } message: {
            Text("Are you sure you want to end this game? Your progress will be saved.")
        }
        .sheet(isPresented: $showScoreEntry) {
            if let player = selectedPlayer {
                ScoreEntrySheet(
                    session: session,
                    player: player,
                    hole: session.currentHole
                )
            }
        }
    }
}

// MARK: - Game Header
struct GameHeaderView: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        VStack(spacing: 12) {
            // Hole Navigation
            HStack {
                Button(action: previousHole) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(session.currentHole > 1 ? .primary : .gray)
                }
                .disabled(session.currentHole <= 1)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Hole \(session.currentHole)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let courseData = CourseData.sampleCourse {
                        let hole = courseData.holes[safe: session.currentHole - 1]
                        HStack(spacing: 8) {
                            Text("Par \(hole?.par ?? 4)")
                            Text("•")
                            Text("\(hole?.yards ?? 0) yds")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: nextHole) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(session.currentHole < 18 ? .primary : .gray)
                }
                .disabled(session.currentHole >= 18)
            }
            .padding(.horizontal)
            
            // Progress Bar
            ProgressView(value: Double(session.currentHole), total: 18)
                .tint(.green)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
    }
    
    private func previousHole() {
        withAnimation {
            session.currentHole = max(1, session.currentHole - 1)
        }
    }
    
    private func nextHole() {
        withAnimation {
            session.currentHole = min(18, session.currentHole + 1)
        }
    }
}

// MARK: - Scorecard View
struct ScorecardView: View {
    @ObservedObject var session: GameSession
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(session.players) { player in
                    PlayerScoreCard(
                        player: player,
                        session: session,
                        hole: session.currentHole
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Player Score Card
struct PlayerScoreCard: View {
    let player: Player
    @ObservedObject var session: GameSession
    let hole: Int
    @EnvironmentObject var appState: AppState
    @State private var score: String = ""
    
    var currentHoleScore: Int? {
        session.scores
            .first { $0.hole == hole && $0.playerId == player.id }?
            .strokes
    }
    
    var totalScore: Int {
        session.scores
            .filter { $0.playerId == player.id }
            .reduce(0) { $0 + $1.strokes }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Player Header
            HStack {
                Circle()
                    .fill(player.color.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(player.name.prefix(2)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.headline)
                    
                    if let handicap = player.handicap {
                        Text("HCP: \(handicap)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalScore)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            Divider()
            
            // Score Entry
            HStack {
                Text("Hole \(hole):")
                    .font(.subheadline)
                
                Spacer()
                
                if let score = currentHoleScore {
                    // Score already entered
                    HStack(spacing: 12) {
                        Text("\(score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(score))
                        
                        Button(action: {
                            editScore()
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                        }
                    }
                } else {
                    // Quick score entry buttons
                    HStack(spacing: 8) {
                        ForEach(2...7, id: \.self) { strokes in
                            Button(action: {
                                recordScore(strokes)
                            }) {
                                Text("\(strokes)")
                                    .font(.headline)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(Color(.tertiarySystemBackground))
                                    )
                            }
                        }
                        
                        Button(action: {
                            // Show full score entry
                        }) {
                            Image(systemName: "plus")
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .stroke(Color.gray, lineWidth: 1)
                                    )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func scoreColor(_ strokes: Int) -> Color {
        guard let par = getCourseData()?.holes[safe: hole - 1]?.par else {
            return .primary
        }
        
        let diff = strokes - par
        switch diff {
        case ..<(-1): return .orange // Eagle or better
        case -1: return .green // Birdie
        case 0: return .primary // Par
        case 1: return .blue // Bogey
        default: return .red // Double or worse
        }
    }
    
    private func recordScore(_ strokes: Int) {
        appState.recordScore(hole: hole, player: player, strokes: strokes)
    }
    
    private func editScore() {
        // Show edit sheet
    }
    
    private func getCourseData() -> CourseData? {
        CourseData.sampleCourse
    }
}

// MARK: - Leaderboard View
struct LeaderboardView: View {
    @ObservedObject var session: GameSession
    
    var leaderboard: [(player: Player, score: Int, thru: Int)] {
        session.players.map { player in
            let scores = session.scores.filter { $0.playerId == player.id }
            let total = scores.reduce(0) { $0 + $1.strokes }
            let holesPlayed = Set(scores.map { $0.hole }).count
            return (player, total, holesPlayed)
        }.sorted { $0.score < $1.score }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(leaderboard.enumerated()), id: \.1.player.id) { index, entry in
                    LeaderboardRow(
                        position: index + 1,
                        player: entry.player,
                        score: entry.score,
                        thru: entry.thru
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let position: Int
    let player: Player
    let score: Int
    let thru: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Position
            Text("\(position)")
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 30)
                .foregroundColor(positionColor)
            
            // Player
            HStack(spacing: 8) {
                Circle()
                    .fill(player.color.color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text(String(player.name.prefix(1)))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text(player.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(score)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("thru \(thru)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            position == 1 ? Color.yellow.opacity(0.1) : Color(.secondarySystemBackground)
        )
        .cornerRadius(12)
    }
    
    private var positionColor: Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.orange
        default: return .primary
        }
    }
}

// MARK: - Game Stats View
struct GameStatsView: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Format-specific stats
                FormatSpecificStats(session: session)
                
                // General stats
                GeneralGameStats(session: session)
                
                // Pace of play
                PaceOfPlayCard(session: session)
            }
            .padding()
        }
    }
}

// MARK: - Format Specific Stats
struct FormatSpecificStats: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(session.format.name) Stats")
                .font(.headline)
            
            // Format-specific content based on game type
            switch session.format.id {
            case "scramble":
                ScrambleStats(session: session)
            case "bestball":
                BestBallStats(session: session)
            case "skins":
                SkinsStats(session: session)
            default:
                Text("Stats for \(session.format.name)")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Helper Views
struct ScrambleStats: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(label: "Drives Used", value: "8")
            StatRow(label: "Approach Shots Used", value: "12")
            StatRow(label: "Putts Used", value: "15")
        }
    }
}

struct BestBallStats: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(label: "Best Scores Used", value: "14")
            StatRow(label: "Contributing Players", value: "All")
        }
    }
}

struct SkinsStats: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(label: "Skins Won", value: "5")
            StatRow(label: "Carryovers", value: "2")
            StatRow(label: "Current Pot", value: "3 skins")
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// Additional helper views...
struct GeneralGameStats: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        // Implementation
        Text("General Stats")
    }
}

struct PaceOfPlayCard: View {
    @ObservedObject var session: GameSession
    
    var body: some View {
        // Implementation
        Text("Pace of Play")
    }
}

struct ScoreEntrySection: View {
    @ObservedObject var session: GameSession
    @Binding var showScoreEntry: Bool
    @Binding var selectedPlayer: Player?
    
    var body: some View {
        // Implementation
        EmptyView()
    }
}

struct ScoreEntrySheet: View {
    @ObservedObject var session: GameSession
    let player: Player
    let hole: Int
    
    var body: some View {
        // Implementation
        Text("Score Entry for \(player.name)")
    }
}

// Array safe subscript
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}