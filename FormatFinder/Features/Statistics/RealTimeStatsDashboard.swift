import SwiftUI
import Charts
import Combine

// MARK: - Real-Time Performance Dashboard

struct RealTimeStatsDashboard: View {
    @ObservedObject var gameState: GameState
    let configuration: GameConfiguration
    let players: [Player]
    
    @State private var selectedPlayer: Player?
    @State private var showGhostData = true
    @State private var selectedGhostRound: GhostRoundType = .bestRound
    @State private var animateMomentum = false
    
    // Animation states
    @State private var momentumValue: Double = 0
    @State private var storyOpacity: Double = 0
    @State private var graphOffset: CGFloat = 0
    
    private let momentum = RoundMomentum()
    private let storyGenerator = RoundStoryGenerator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Player Selector
                PlayerSelectorBar(
                    players: players,
                    selectedPlayer: $selectedPlayer
                )
                
                // Momentum Meter
                MomentumMeter(
                    momentum: momentumValue,
                    isAnimating: animateMomentum,
                    playerName: selectedPlayer?.name ?? "Player"
                )
                .onAppear {
                    updateMomentum()
                }
                
                // Round Story
                RoundStoryView(
                    story: generateStory(),
                    opacity: storyOpacity
                )
                .onAppear {
                    withAnimation(.easeIn(duration: 0.8)) {
                        storyOpacity = 1
                    }
                }
                
                // Performance Graph with Ghost Data
                PerformanceGraph(
                    currentScores: getCurrentScores(),
                    ghostData: getGhostData(),
                    showGhost: showGhostData,
                    ghostType: selectedGhostRound,
                    offset: graphOffset
                )
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        graphOffset = 0
                    }
                }
                
                // Quick Stats Grid
                QuickStatsGrid(
                    player: selectedPlayer,
                    gameState: gameState
                )
                
                // Trend Analysis
                TrendAnalysisView(
                    player: selectedPlayer,
                    gameState: gameState
                )
            }
            .padding()
        }
        .background(Color.gray.opacity(0.05))
        .onReceive(gameState.$scores) { _ in
            updateMomentum()
            updateStory()
        }
    }
    
    private func updateMomentum() {
        guard let player = selectedPlayer else { return }
        
        let scores = getPlayerScores(for: player.id)
        let newMomentum = momentum.calculateMomentum(
            scores: scores,
            handicap: player.handicap
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            momentumValue = newMomentum
            animateMomentum = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animateMomentum = false
        }
    }
    
    private func updateStory() {
        withAnimation(.easeOut(duration: 0.3)) {
            storyOpacity = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.5)) {
                storyOpacity = 1
            }
        }
    }
    
    private func generateStory() -> RoundStory {
        guard let player = selectedPlayer else {
            return RoundStory(segments: [])
        }
        
        let scores = getPlayerScores(for: player.id)
        return storyGenerator.generateStory(
            scores: scores,
            pars: getPars(),
            playerName: player.name
        )
    }
    
    private func getCurrentScores() -> [Int] {
        guard let player = selectedPlayer else { return [] }
        return getPlayerScores(for: player.id)
    }
    
    private func getGhostData() -> [Int] {
        // TODO: Fetch from historical data
        // Placeholder ghost data
        return [4, 5, 3, 4, 5, 4, 4, 3, 5]
    }
    
    private func getPlayerScores(for playerId: UUID) -> [Int] {
        var scores: [Int] = []
        for hole in 1...18 {
            if let score = gameState.scores[hole]?[playerId] {
                scores.append(score)
            }
        }
        return scores
    }
    
    private func getPars() -> [Int] {
        // TODO: Get from course data
        return Array(repeating: 4, count: 18)
    }
}

// MARK: - Momentum Meter

struct MomentumMeter: View {
    let momentum: Double // -1 to 1
    let isAnimating: Bool
    let playerName: String
    
    @State private var needleRotation: Double = 0
    @State private var glowOpacity: Double = 0
    
    private var momentumColor: Color {
        if momentum > 0.3 { return .green }
        if momentum > 0 { return .blue }
        if momentum > -0.3 { return .orange }
        return .red
    }
    
    private var momentumText: String {
        if momentum > 0.5 { return "On Fire!" }
        if momentum > 0.2 { return "Building Momentum" }
        if momentum > -0.2 { return "Steady" }
        if momentum > -0.5 { return "Losing Steam" }
        return "Struggling"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Momentum")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray)
            
            ZStack {
                // Background arc
                MomentumArc()
                    .stroke(
                        LinearGradient(
                            colors: [.red, .orange, .yellow, .green],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 100)
                    .opacity(0.3)
                
                // Active arc
                MomentumArc()
                    .trim(from: 0, to: CGFloat((momentum + 1) / 2))
                    .stroke(
                        momentumColor,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 100)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: momentum)
                
                // Glow effect
                MomentumArc()
                    .trim(from: max(0, CGFloat((momentum + 1) / 2 - 0.05)),
                          to: CGFloat((momentum + 1) / 2))
                    .stroke(
                        momentumColor,
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .frame(width: 200, height: 100)
                    .blur(radius: 10)
                    .opacity(glowOpacity)
                
                // Needle
                MomentumNeedle()
                    .fill(Color.primary)
                    .frame(width: 4, height: 80)
                    .offset(y: 40)
                    .rotationEffect(.degrees(needleRotation), anchor: .bottom)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: needleRotation)
                
                // Center dot
                Circle()
                    .fill(Color.primary)
                    .frame(width: 12, height: 12)
                    .offset(y: 40)
            }
            .frame(height: 100)
            
            Text(momentumText)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(momentumColor)
                .animation(.easeInOut, value: momentumText)
            
            Text("\(playerName)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: momentumColor.opacity(0.2), radius: 10)
        )
        .onAppear {
            needleRotation = momentum * 90
            
            if isAnimating {
                withAnimation(.easeInOut(duration: 0.3).repeatCount(2, autoreverses: true)) {
                    glowOpacity = 0.8
                }
            }
        }
        .onChange(of: momentum) { newValue in
            needleRotation = newValue * 90
        }
    }
}

struct MomentumArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

struct MomentumNeedle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - 2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + 2, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Round Story View

struct RoundStoryView: View {
    let story: RoundStory
    let opacity: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Round Story")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray)
            
            ForEach(story.segments) { segment in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: segment.icon)
                        .font(.system(size: 16))
                        .foregroundColor(segment.color)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(segment.title)
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text(segment.description)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .opacity(opacity)
                .animation(.easeInOut(duration: 0.5), value: opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 5)
        )
    }
}

// MARK: - Performance Graph

struct PerformanceGraph: View {
    let currentScores: [Int]
    let ghostData: [Int]
    let showGhost: Bool
    let ghostType: GhostRoundType
    let offset: CGFloat
    
    private var cumulativeDifferential: [(hole: Int, current: Int, ghost: Int)] {
        var result: [(Int, Int, Int)] = []
        var currentTotal = 0
        var ghostTotal = 0
        let pars = Array(repeating: 4, count: 18) // TODO: Get actual pars
        
        for i in 0..<max(currentScores.count, ghostData.count) {
            if i < currentScores.count {
                currentTotal += currentScores[i] - pars[i]
            }
            if i < ghostData.count {
                ghostTotal += ghostData[i] - pars[i]
            }
            result.append((i + 1, currentTotal, ghostTotal))
        }
        
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance Comparison")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                if showGhost {
                    Menu {
                        ForEach(GhostRoundType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                // Handle selection
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text(ghostType.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Chart(cumulativeDifferential, id: \.hole) { data in
                // Current round line
                LineMark(
                    x: .value("Hole", data.hole),
                    y: .value("Score", data.current)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .symbol {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
                
                // Current round area
                AreaMark(
                    x: .value("Hole", data.hole),
                    y: .value("Score", data.current)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                if showGhost {
                    // Ghost round line
                    LineMark(
                        x: .value("Hole", data.hole),
                        y: .value("Ghost", data.ghost)
                    )
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
            .frame(height: 200)
            .offset(x: offset)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text(intValue > 0 ? "+\(intValue)" : "\(intValue)")
                                .font(.system(size: 10))
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: 20, height: 3)
                    Text("Current")
                        .font(.system(size: 12))
                }
                
                if showGhost {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 20, height: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            )
                        Text(ghostType.rawValue)
                            .font(.system(size: 12))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 5)
        )
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let player: Player?
    let gameState: GameState
    
    private var stats: [QuickStat] {
        guard let player = player else { return [] }
        
        let scores = getPlayerScores()
        let pars = Array(repeating: 4, count: 18) // TODO: Get actual pars
        
        return [
            QuickStat(
                title: "Score",
                value: "\(scores.reduce(0, +))",
                subtitle: "Total",
                color: .blue,
                icon: "flag.fill"
            ),
            QuickStat(
                title: "To Par",
                value: formatDifferential(calculateDifferential()),
                subtitle: "Current",
                color: differentialColor(calculateDifferential()),
                icon: "chart.line.uptrend.xyaxis"
            ),
            QuickStat(
                title: "Birdies",
                value: "\(countBirdies())",
                subtitle: "Made",
                color: .green,
                icon: "star.fill"
            ),
            QuickStat(
                title: "Avg Score",
                value: String(format: "%.1f", calculateAverage()),
                subtitle: "Per Hole",
                color: .purple,
                icon: "chart.bar.fill"
            )
        ]
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(stats) { stat in
                QuickStatCard(stat: stat)
            }
        }
    }
    
    private func getPlayerScores() -> [Int] {
        guard let player = player else { return [] }
        var scores: [Int] = []
        for hole in 1...18 {
            if let score = gameState.scores[hole]?[player.id] {
                scores.append(score)
            }
        }
        return scores
    }
    
    private func calculateDifferential() -> Int {
        let scores = getPlayerScores()
        let pars = Array(repeating: 4, count: scores.count)
        return scores.enumerated().reduce(0) { $0 + ($1.element - pars[$1.offset]) }
    }
    
    private func formatDifferential(_ diff: Int) -> String {
        if diff == 0 { return "E" }
        if diff > 0 { return "+\(diff)" }
        return "\(diff)"
    }
    
    private func differentialColor(_ diff: Int) -> Color {
        if diff < 0 { return .green }
        if diff == 0 { return .blue }
        return .red
    }
    
    private func countBirdies() -> Int {
        let scores = getPlayerScores()
        let pars = Array(repeating: 4, count: scores.count)
        return scores.enumerated().filter { $0.element < pars[$0.offset] }.count
    }
    
    private func calculateAverage() -> Double {
        let scores = getPlayerScores()
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}

struct QuickStatCard: View {
    let stat: QuickStat
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: stat.icon)
                .font(.system(size: 20))
                .foregroundColor(stat.color)
                .frame(width: 32, height: 32)
                .background(stat.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(stat.color)
                
                Text(stat.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 3)
        )
    }
}

// MARK: - Supporting Types

struct RoundMomentum {
    private var scoreHistory: [Int] = []
    private var averageBaseline: Double = 0
    
    func calculateMomentum(scores: [Int], handicap: Int) -> Double {
        guard scores.count >= 3 else { return 0 }
        
        // Get last 3 scores
        let recentScores = Array(scores.suffix(3))
        let pars = Array(repeating: 4, count: 3) // TODO: Get actual pars
        
        // Calculate trend
        let recentAvg = Double(recentScores.reduce(0, +)) / Double(recentScores.count)
        let expectedAvg = 4.0 + Double(handicap) / 18.0
        
        let momentum = (expectedAvg - recentAvg) / 2.0
        return max(-1, min(1, momentum))
    }
}

struct RoundStoryGenerator {
    func generateStory(scores: [Int], pars: [Int], playerName: String) -> RoundStory {
        var segments: [StorySegment] = []
        
        // Opening
        if scores.count >= 3 {
            let start = Array(scores.prefix(3))
            let startDiff = start.enumerated().reduce(0) { $0 + ($1.element - pars[$1.offset]) }
            
            if startDiff <= -2 {
                segments.append(StorySegment(
                    title: "Hot Start!",
                    description: "Opened with great momentum through the first 3 holes",
                    icon: "flame.fill",
                    color: .orange
                ))
            } else if startDiff >= 3 {
                segments.append(StorySegment(
                    title: "Rough Opening",
                    description: "Struggled to find rhythm early",
                    icon: "cloud.rain.fill",
                    color: .blue
                ))
            }
        }
        
        // Middle stretch
        if scores.count >= 9 {
            let middle = Array(scores[3..<min(9, scores.count)])
            let middleDiff = middle.enumerated().reduce(0) { $0 + ($1.element - pars[3 + $1.offset]) }
            
            if middleDiff <= -1 {
                segments.append(StorySegment(
                    title: "Found Your Groove",
                    description: "Excellent stretch through the middle holes",
                    icon: "sparkles",
                    color: .green
                ))
            }
        }
        
        // Current status
        if let lastScore = scores.last, scores.count > 0 {
            let lastPar = pars[scores.count - 1]
            if lastScore < lastPar {
                segments.append(StorySegment(
                    title: "Just Made Birdie!",
                    description: "Great shot on hole \(scores.count)",
                    icon: "star.fill",
                    color: .yellow
                ))
            }
        }
        
        return RoundStory(segments: segments)
    }
}

struct RoundStory {
    let segments: [StorySegment]
}

struct StorySegment: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct QuickStat: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
}

enum GhostRoundType: String, CaseIterable {
    case bestRound = "Best Round"
    case averageRound = "Average"
    case lastRound = "Last Round"
    case courseRecord = "Course Record"
}

// MARK: - Trend Analysis

struct TrendAnalysisView: View {
    let player: Player?
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trend Analysis")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.gray)
            
            // Placeholder for trend analysis
            Text("Advanced analytics coming soon...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .italic()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 5)
        )
    }
}

// MARK: - Player Selector

struct PlayerSelectorBar: View {
    let players: [Player]
    @Binding var selectedPlayer: Player?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(players) { player in
                    PlayerChip(
                        player: player,
                        isSelected: selectedPlayer?.id == player.id,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPlayer = player
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PlayerChip: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 16))
                
                Text(player.name)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}