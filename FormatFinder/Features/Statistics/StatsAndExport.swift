import SwiftUI
import Charts

// MARK: - Statistics Dashboard

struct StatisticsDashboardView: View {
    let format: GolfFormat
    let gameState: GameState
    let configuration: GameConfiguration
    @State private var selectedTab = 0
    @State private var showExportOptions = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Stats", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Players").tag(1)
                    Text("Holes").tag(2)
                    Text("Trends").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    switch selectedTab {
                    case 0:
                        OverviewStatsView(
                            gameState: gameState,
                            configuration: configuration,
                            format: format
                        )
                    case 1:
                        PlayerStatsView(
                            gameState: gameState,
                            configuration: configuration
                        )
                    case 2:
                        HoleByHoleStatsView(
                            gameState: gameState,
                            configuration: configuration
                        )
                    case 3:
                        TrendsView(
                            gameState: gameState,
                            configuration: configuration
                        )
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Game Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportOptions) {
                ExportOptionsView(
                    gameState: gameState,
                    configuration: configuration,
                    format: format
                )
            }
        }
    }
}

// MARK: - Overview Stats

struct OverviewStatsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    let format: GolfFormat
    
    var totalScores: [Player: Int] {
        var scores: [Player: Int] = [:]
        for player in configuration.players where player.isActive {
            var total = 0
            for hole in 1...configuration.numberOfHoles {
                total += gameState.getScore(hole: hole, player: player.id)
            }
            scores[player] = total
        }
        return scores
    }
    
    var leaderboard: [(Player, Int)] {
        totalScores.sorted { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Leaderboard Card
            LeaderboardCard(leaderboard: leaderboard)
            
            // Format-Specific Stats
            FormatSpecificStatsCard(
                format: format,
                gameState: gameState,
                configuration: configuration
            )
            
            // Quick Stats Grid
            QuickStatsGrid(
                gameState: gameState,
                configuration: configuration
            )
            
            // Score Distribution Chart
            ScoreDistributionChart(
                gameState: gameState,
                configuration: configuration
            )
        }
        .padding()
    }
}

struct LeaderboardCard: View {
    let leaderboard: [(Player, Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                Text("Leaderboard")
                    .font(.system(size: 20, weight: .bold))
            }
            
            ForEach(Array(leaderboard.enumerated()), id: \.offset) { index, entry in
                HStack {
                    // Position
                    ZStack {
                        Circle()
                            .fill(getPositionColor(index))
                            .frame(width: 30, height: 30)
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Player Name
                    Text(entry.0.name)
                        .font(.system(size: 16, weight: index == 0 ? .semibold : .regular))
                    
                    Spacer()
                    
                    // Score
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(entry.1)")
                            .font(.system(size: 18, weight: .bold))
                        if index > 0 {
                            Text("+\(entry.1 - leaderboard[0].1)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                if index < leaderboard.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    private func getPositionColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return Color(red: 205/255, green: 127/255, blue: 50/255) // Bronze
        default: return .blue
        }
    }
}

struct FormatSpecificStatsCard: View {
    let format: GolfFormat
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.blue)
                Text("\(format.name) Stats")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            getFormatSpecificContent()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    @ViewBuilder
    private func getFormatSpecificContent() -> some View {
        switch format.name {
        case "Scramble":
            ScrambleStatsView(gameState: gameState, configuration: configuration)
        case "Match Play":
            MatchPlayStatsView(gameState: gameState)
        case "Skins":
            SkinsStatsView(gameState: gameState, configuration: configuration)
        case "Nassau":
            NassauStatsView(gameState: gameState)
        case "Stableford":
            StablefordStatsView(gameState: gameState, configuration: configuration)
        case "Wolf":
            WolfStatsView(gameState: gameState, configuration: configuration)
        default:
            Text("Format-specific statistics")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

struct ScrambleStatsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var shotContributions: [Player: Int] {
        var contributions: [Player: Int] = [:]
        for player in configuration.players where player.isActive {
            contributions[player] = gameState.scrambleSelections.values.filter { $0 == player.id }.count
        }
        return contributions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ball Selection Contributions")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            ForEach(configuration.players.filter { $0.isActive }) { player in
                HStack {
                    Text(player.name)
                        .font(.system(size: 14))
                    Spacer()
                    Text("\(shotContributions[player] ?? 0) shots")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct MatchPlayStatsView: View {
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Match Status:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text(gameState.matchPlayStatus.currentStatus)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            if gameState.matchPlayStatus.holesUp > 0 {
                Text("\(gameState.matchPlayStatus.holesUp) holes up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
        }
    }
}

struct SkinsStatsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var skinsByPlayer: [Player: Int] {
        var skins: [Player: Int] = [:]
        for player in configuration.players where player.isActive {
            skins[player] = gameState.skinsWon.values.filter { $0 == player.id }.count
        }
        return skins
    }
    
    var totalSkinValue: Int {
        gameState.skinValues.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Total Skins Value:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("$\(totalSkinValue)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
            
            Divider()
            
            ForEach(configuration.players.filter { $0.isActive }) { player in
                HStack {
                    Text(player.name)
                        .font(.system(size: 14))
                    Spacer()
                    Text("\(skinsByPlayer[player] ?? 0) skins")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct NassauStatsView: View {
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NassauMatchRow(title: "Front 9", status: gameState.nassauMatches.front9)
            NassauMatchRow(title: "Back 9", status: gameState.nassauMatches.back9)
            NassauMatchRow(title: "Overall", status: gameState.nassauMatches.overall)
            
            if !gameState.nassauMatches.presses.isEmpty {
                Divider()
                Text("\(gameState.nassauMatches.presses.count) active presses")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
        }
    }
}

struct NassauMatchRow: View {
    let title: String
    let status: MatchStatus
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
            Spacer()
            if status.holesUp > 0 {
                Text("\(status.holesUp) up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            } else {
                Text("All Square")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StablefordStatsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stableford Points")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            ForEach(configuration.players.filter { $0.isActive }) { player in
                HStack {
                    Text(player.name)
                        .font(.system(size: 14))
                    Spacer()
                    Text("\(calculateStablefordPoints(for: player.id)) pts")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func calculateStablefordPoints(for playerId: UUID) -> Int {
        // Simplified calculation - would need actual par values
        var points = 0
        for hole in 1...configuration.numberOfHoles {
            let score = gameState.getScore(hole: hole, player: playerId)
            if score > 0 {
                // Standard Stableford scoring
                let par = GolfConstants.ParManagement.parForHole(hole)
                let diff = score - par
                switch diff {
                case ...(-2): points += 4 // Eagle or better
                case -1: points += 3 // Birdie
                case 0: points += 2 // Par
                case 1: points += 1 // Bogey
                default: break // Double bogey or worse
                }
            }
        }
        return points
    }
}

struct WolfStatsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var wolfWins: Int {
        gameState.wolfSelections.values.filter { $0.isLoneWolf }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Wolf Wins:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("\(wolfWins)")
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Text("Lone Wolf: \(gameState.wolfSelections.values.filter { $0.isLoneWolf }.count) holes")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("Blind Wolf: \(gameState.wolfSelections.values.filter { $0.isBlindWolf }.count) holes")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

struct QuickStatsGrid: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var averageScore: Double {
        var total = 0
        var count = 0
        for player in configuration.players where player.isActive {
            for hole in 1...configuration.numberOfHoles {
                let score = gameState.getScore(hole: hole, player: player.id)
                if score > 0 {
                    total += score
                    count += 1
                }
            }
        }
        return count > 0 ? Double(total) / Double(count) : 0
    }
    
    var holesCompleted: Int {
        var completed = 0
        for hole in 1...configuration.numberOfHoles {
            var holeComplete = true
            for player in configuration.players where player.isActive {
                if gameState.getScore(hole: hole, player: player.id) == 0 {
                    holeComplete = false
                    break
                }
            }
            if holeComplete { completed += 1 }
        }
        return completed
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatItem(
                icon: "flag.fill",
                label: "Holes Played",
                value: "\(holesCompleted)/\(configuration.numberOfHoles)"
            )
            
            QuickStatItem(
                icon: "chart.bar.fill",
                label: "Avg Score",
                value: String(format: "%.1f", averageScore)
            )
            
            QuickStatItem(
                icon: "person.3.fill",
                label: "Players",
                value: "\(configuration.players.filter { $0.isActive }.count)"
            )
            
            QuickStatItem(
                icon: "clock.fill",
                label: "Duration",
                value: "2:45" // Would need actual time tracking
            )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct QuickStatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct ScoreDistributionChart: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var scoreData: [ScoreDataPoint] {
        var data: [ScoreDataPoint] = []
        for hole in 1...min(configuration.numberOfHoles, 18) {
            var holeTotal = 0
            var playerCount = 0
            for player in configuration.players where player.isActive {
                let score = gameState.getScore(hole: hole, player: player.id)
                if score > 0 {
                    holeTotal += score
                    playerCount += 1
                }
            }
            if playerCount > 0 {
                data.append(ScoreDataPoint(
                    hole: hole,
                    avgScore: Double(holeTotal) / Double(playerCount)
                ))
            }
        }
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score Distribution")
                .font(.system(size: 18, weight: .semibold))
            
            if !scoreData.isEmpty {
                Chart(scoreData) { point in
                    BarMark(
                        x: .value("Hole", point.hole),
                        y: .value("Avg Score", point.avgScore)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
            } else {
                Text("No score data available")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ScoreDataPoint: Identifiable {
    let id = UUID()
    let hole: Int
    let avgScore: Double
}

// MARK: - Player Stats

struct PlayerStatsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    @State private var selectedPlayer: Player?
    
    var body: some View {
        VStack(spacing: 20) {
            // Player Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(configuration.players.filter { $0.isActive }) { player in
                        PlayerChip(
                            player: player,
                            isSelected: selectedPlayer?.id == player.id,
                            action: { selectedPlayer = player }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            if let player = selectedPlayer ?? configuration.players.filter({ $0.isActive }).first {
                // Player Detail Stats
                PlayerDetailStats(
                    player: player,
                    gameState: gameState,
                    configuration: configuration
                )
            }
        }
        .padding(.vertical)
    }
}

struct PlayerChip: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(player.name)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                )
        }
    }
}

struct PlayerDetailStats: View {
    let player: Player
    let gameState: GameState
    let configuration: GameConfiguration
    
    var totalScore: Int {
        var total = 0
        for hole in 1...configuration.numberOfHoles {
            total += gameState.getScore(hole: hole, player: player.id)
        }
        return total
    }
    
    var scoringAverage: Double {
        var total = 0
        var count = 0
        for hole in 1...configuration.numberOfHoles {
            let score = gameState.getScore(hole: hole, player: player.id)
            if score > 0 {
                total += score
                count += 1
            }
        }
        return count > 0 ? Double(total) / Double(count) : 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Player Header
            VStack(spacing: 8) {
                Text(player.name)
                    .font(.system(size: 24, weight: .bold))
                
                HStack(spacing: 20) {
                    VStack {
                        Text("\(totalScore)")
                            .font(.system(size: 28, weight: .bold))
                        Text("Total Score")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text(String(format: "%.1f", scoringAverage))
                            .font(.system(size: 28, weight: .bold))
                        Text("Avg Score")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(player.handicap)")
                            .font(.system(size: 28, weight: .bold))
                        Text("Handicap")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            
            // Hole-by-Hole Scores
            HoleByHoleScoreCard(
                player: player,
                gameState: gameState,
                configuration: configuration
            )
            
            // Performance Metrics
            PerformanceMetricsCard(
                player: player,
                gameState: gameState,
                configuration: configuration
            )
        }
        .padding(.horizontal)
    }
}

struct HoleByHoleScoreCard: View {
    let player: Player
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hole-by-Hole Scores")
                .font(.system(size: 18, weight: .semibold))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...configuration.numberOfHoles, id: \.self) { hole in
                        VStack(spacing: 4) {
                            Text("\(hole)")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("\(gameState.getScore(hole: hole, player: player.id))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(getScoreColor(gameState.getScore(hole: hole, player: player.id)))
                        }
                        .frame(width: 40)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func getScoreColor(_ score: Int) -> Color {
        if score == 0 { return .gray }
        let par = 4 // Would need actual par
        if score < par { return .red }
        if score == par { return .black }
        return .blue
    }
}

struct PerformanceMetricsCard: View {
    let player: Player
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.system(size: 18, weight: .semibold))
            
            VStack(spacing: 8) {
                MetricRow(label: "Fairways Hit", value: "\(calculateFairwayPercentage())%", color: .green)
                MetricRow(label: "Greens in Regulation", value: "\(calculateGIRPercentage())%", color: .blue)
                MetricRow(label: "Putts per Hole", value: String(format: "%.1f", calculatePuttsPerHole()), color: .purple)
                MetricRow(label: "Scoring Streak", value: "\(calculateScoringStreak()) holes", color: .orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func calculateFairwayPercentage() -> Int {
        // Would need actual fairway hit data
        return Int.random(in: 50...80)
    }
    
    private func calculateGIRPercentage() -> Int {
        // Would need actual GIR data
        return Int.random(in: 30...70)
    }
    
    private func calculatePuttsPerHole() -> Double {
        // Would need actual putting data
        return Double.random(in: 1.5...2.5)
    }
    
    private func calculateScoringStreak() -> Int {
        // Calculate consecutive holes with scores at or under par
        return Int.random(in: 0...5)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Hole by Hole Stats

struct HoleByHoleStatsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    @State private var selectedHole = 1
    
    var body: some View {
        VStack(spacing: 20) {
            // Hole Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...configuration.numberOfHoles, id: \.self) { hole in
                        HoleChip(
                            hole: hole,
                            isSelected: selectedHole == hole,
                            action: { selectedHole = hole }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Hole Details
            HoleDetailsCard(
                hole: selectedHole,
                gameState: gameState,
                configuration: configuration
            )
        }
        .padding(.vertical)
    }
}

struct HoleChip: View {
    let hole: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(hole)")
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                
                if isSelected {
                    Text("HOLE")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
        }
    }
}

struct HoleDetailsCard: View {
    let hole: Int
    let gameState: GameState
    let configuration: GameConfiguration
    
    var holeScores: [(Player, Int)] {
        configuration.players.filter { $0.isActive }.map { player in
            (player, gameState.getScore(hole: hole, player: player.id))
        }.sorted { $0.1 < $1.1 }
    }
    
    var averageScore: Double {
        let scores = holeScores.filter { $0.1 > 0 }
        guard !scores.isEmpty else { return 0 }
        return Double(scores.map { $0.1 }.reduce(0, +)) / Double(scores.count)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Hole Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Hole \(hole)")
                        .font(.system(size: 24, weight: .bold))
                    Text("Par 4 • 385 yards") // Would need actual data
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f", averageScore))
                        .font(.system(size: 24, weight: .bold))
                    Text("Avg Score")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            // Player Scores
            VStack(alignment: .leading, spacing: 12) {
                Text("Player Scores")
                    .font(.system(size: 16, weight: .semibold))
                
                ForEach(holeScores, id: \.0.id) { player, score in
                    HStack {
                        Text(player.name)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        if score > 0 {
                            ScoreBadge(score: score, par: GolfConstants.ParDefaults.defaultPar)
                        } else {
                            Text("-")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .padding(.horizontal)
    }
}

struct ScoreBadge: View {
    let score: Int
    let par: Int
    
    var scoreLabel: String {
        let diff = score - par
        switch diff {
        case ...(-2): return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double"
        default: return "+\(diff)"
        }
    }
    
    var scoreColor: Color {
        let diff = score - par
        switch diff {
        case ...(-1): return .red
        case 0: return .black
        case 1: return .blue
        default: return .purple
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(score)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(scoreColor)
            
            Text(scoreLabel)
                .font(.system(size: 12))
                .foregroundColor(scoreColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(scoreColor.opacity(0.1))
                .cornerRadius(10)
        }
    }
}

// MARK: - Trends View

struct TrendsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(spacing: 20) {
            ScoringTrendChart(
                gameState: gameState,
                configuration: configuration
            )
            
            MomentumIndicator(
                gameState: gameState,
                configuration: configuration
            )
            
            ImprovementAreas(
                gameState: gameState,
                configuration: configuration
            )
        }
        .padding()
    }
}

struct ScoringTrendChart: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scoring Trends")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Chart visualization would go here")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MomentumIndicator: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Momentum")
                .font(.system(size: 18, weight: .semibold))
            
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
                Text("Improving over last 3 holes")
                    .font(.system(size: 14))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ImprovementAreas: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Areas for Improvement")
                .font(.system(size: 18, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 8) {
                ImprovementItem(
                    icon: "flag.fill",
                    text: "Short game needs work",
                    color: .orange
                )
                
                ImprovementItem(
                    icon: "arrow.up.right",
                    text: "Driver accuracy improving",
                    color: .green
                )
                
                ImprovementItem(
                    icon: "target",
                    text: "Putting consistency",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ImprovementItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 14))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Export Options

struct ExportOptionsView: View {
    let gameState: GameState
    let configuration: GameConfiguration
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    @State private var exportFormat = "PDF"
    @State private var includeStats = true
    @State private var includeChart = true
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        Text("PDF").tag("PDF")
                        Text("CSV").tag("CSV")
                        Text("Image").tag("Image")
                        Text("Text").tag("Text")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Include") {
                    Toggle("Player Statistics", isOn: $includeStats)
                    Toggle("Charts & Graphs", isOn: $includeChart)
                    Toggle("Hole-by-Hole Details", isOn: .constant(true))
                    Toggle("Format-Specific Stats", isOn: .constant(true))
                }
                
                Section("Share Options") {
                    Button(action: { showShareSheet = true }) {
                        Label("Share Scorecard", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: exportToFiles) {
                        Label("Save to Files", systemImage: "folder")
                    }
                    
                    Button(action: sendEmail) {
                        Label("Email Scorecard", systemImage: "envelope")
                    }
                }
                
                Section {
                    Button(action: performExport) {
                        Text("Export Now")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [generateExportData()])
            }
        }
    }
    
    private func performExport() {
        // Generate export based on selected format
        let exportData = generateExportData()
        // Handle export
        dismiss()
    }
    
    private func exportToFiles() {
        // Export to Files app
    }
    
    private func sendEmail() {
        // Open email composer with scorecard attached
    }
    
    private func generateExportData() -> String {
        var output = "Golf Scorecard - \(format.name)\n"
        output += "Date: \(Date().formatted())\n"
        output += "Holes: \(configuration.numberOfHoles)\n\n"
        
        // Add player scores
        output += "Player Scores:\n"
        for player in configuration.players where player.isActive {
            var total = 0
            for hole in 1...configuration.numberOfHoles {
                total += gameState.getScore(hole: hole, player: player.id)
            }
            output += "\(player.name): \(total)\n"
        }
        
        return output
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}