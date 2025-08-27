import SwiftUI

// MARK: - Gesture-Enabled Score Entry View
// Demonstrates integration of gesture backend with existing scorecards

struct GestureScoreEntryView: View {
    
    // MARK: - Properties
    
    let player: Player
    let hole: Int
    @Binding var score: Int
    
    @StateObject private var gestureService = GestureScoreService.shared
    @StateObject private var gridService = MultiPlayerGridService.shared
    
    @State private var currentGesture: DragGesture.Value?
    @State private var gestureStartTime = Date()
    @State private var gestureStartScore = 0
    @State private var predictedScore = 0
    @State private var showPrediction = false
    @State private var lastUpdateTime = Date()
    
    // Visual feedback
    @State private var cellScale = 1.0
    @State private var cellOpacity = 1.0
    @State private var showConfidence = false
    @State private var confidenceValue = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            // Player info
            HStack {
                Text(player.name)
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                if player.handicap > 0 {
                    Text("HCP: \(player.handicap)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // Score display with gesture support
            ZStack {
                // Background for gesture detection
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 80)
                
                // Score display
                VStack(spacing: 4) {
                    if showPrediction {
                        Text("\(predictedScore)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue.opacity(0.6))
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("\(score)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(scoreColor(for: score))
                    }
                    
                    if showConfidence {
                        ConfidenceIndicator(confidence: confidenceValue)
                            .transition(.opacity)
                    }
                }
                .scaleEffect(cellScale)
                .opacity(cellOpacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cellScale)
                
                // Probability hints
                if let predictions = gestureService.scorePredictions {
                    ProbabilityHints(distribution: predictions)
                        .opacity(0.3)
                }
            }
            .gesture(createSwipeGesture())
            
            // Quick score buttons with haptic feedback
            HStack(spacing: 8) {
                QuickScoreButton(label: "Birdie", score: 3, currentScore: $score, player: player, hole: hole)
                QuickScoreButton(label: "Par", score: 4, currentScore: $score, player: player, hole: hole)
                QuickScoreButton(label: "Bogey", score: 5, currentScore: $score, player: player, hole: hole)
            }
            
            // Traditional +/- buttons
            HStack(spacing: 20) {
                Button(action: { adjustScore(-1) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: { adjustScore(1) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            loadPredictions()
        }
    }
    
    // MARK: - Gesture Handling
    
    private func createSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                handleGestureChange(value)
            }
            .onEnded { value in
                handleGestureEnd(value)
            }
    }
    
    private func handleGestureChange(_ value: DragGesture.Value) {
        if currentGesture == nil {
            gestureStartTime = Date()
            gestureStartScore = score
            currentGesture = value
            
            // Visual feedback
            withAnimation(.easeOut(duration: 0.1)) {
                cellScale = 1.05
                cellOpacity = 0.8
            }
        }
        
        // Calculate predicted score based on gesture
        let distance = value.translation.height
        let velocity = abs(distance) / Date().timeIntervalSince(gestureStartTime)
        
        let swipeData = SwipeData(
            velocity: velocity,
            distance: abs(distance),
            startPoint: value.startLocation,
            endPoint: value.location,
            duration: Date().timeIntervalSince(gestureStartTime)
        )
        
        let scoreChange = gestureService.interpretGesture(swipeData, for: player)
        
        // Update prediction
        if distance < 0 {
            // Swipe up - decrease score
            predictedScore = max(1, gestureStartScore - scoreChange.value)
        } else {
            // Swipe down - increase score
            predictedScore = gestureStartScore + scoreChange.value
        }
        
        showPrediction = true
        confidenceValue = scoreChange.confidence
        showConfidence = true
    }
    
    private func handleGestureEnd(_ value: DragGesture.Value) {
        let distance = value.translation.height
        let duration = Date().timeIntervalSince(gestureStartTime)
        let velocity = abs(distance) / duration
        
        let swipeData = SwipeData(
            velocity: velocity * 1000, // Convert to pixels/second
            distance: abs(distance),
            startPoint: value.startLocation,
            endPoint: value.location,
            duration: duration
        )
        
        // Process with grid service
        let result = gridService.processGestureUpdate(
            playerId: player.id,
            hole: hole,
            gesture: swipeData,
            currentScore: score
        )
        
        // Apply the result
        if result.accepted {
            withAnimation(.spring()) {
                score = result.finalScore
            }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        
        // Reset visual state
        withAnimation(.spring()) {
            cellScale = 1.0
            cellOpacity = 1.0
            showPrediction = false
            showConfidence = false
        }
        
        currentGesture = nil
    }
    
    // MARK: - Helper Methods
    
    private func adjustScore(_ delta: Int) {
        let newScore = max(1, score + delta)
        
        let update = PlayerScoreUpdate(
            playerId: player.id,
            hole: hole,
            score: newScore,
            previousScore: score,
            timestamp: Date(),
            source: .manual,
            animationStyle: .quick
        )
        
        gridService.submitScoreUpdate(update)
        
        withAnimation(.spring()) {
            score = newScore
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func loadPredictions() {
        _ = gestureService.preCalculateProbabilities(
            for: player,
            hole: hole,
            par: 4
        )
    }
    
    private func scoreColor(for score: Int) -> Color {
        let par = 4 // TODO: Get actual par
        let diff = score - par
        
        switch diff {
        case ..<(-1):
            return .purple // Eagle or better
        case -1:
            return .blue // Birdie
        case 0:
            return .green // Par
        case 1:
            return .orange // Bogey
        case 2:
            return .red.opacity(0.8) // Double bogey
        default:
            return .red // Triple or worse
        }
    }
}

// MARK: - Supporting Views

struct QuickScoreButton: View {
    let label: String
    let score: Int
    @Binding var currentScore: Int
    let player: Player
    let hole: Int
    
    @StateObject private var gridService = MultiPlayerGridService.shared
    
    var body: some View {
        Button(action: {
            let update = PlayerScoreUpdate(
                playerId: player.id,
                hole: hole,
                score: score,
                previousScore: currentScore,
                timestamp: Date(),
                source: .quickButton,
                animationStyle: .bounce
            )
            
            gridService.submitScoreUpdate(update)
            
            withAnimation(.spring()) {
                currentScore = score
            }
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(currentScore == score ? .white : scoreButtonColor())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    currentScore == score ? scoreButtonColor() : scoreButtonColor().opacity(0.15)
                )
                .cornerRadius(8)
        }
    }
    
    private func scoreButtonColor() -> Color {
        switch label {
        case "Birdie": return .blue
        case "Par": return .green
        case "Bogey": return .orange
        default: return .gray
        }
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(index < Int(confidence * 5) ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 8)
            }
        }
    }
}

struct ProbabilityHints: View {
    let distribution: ScoreProbabilityDistribution
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(distribution.distribution.sorted(by: { $0.key < $1.key })), id: \.key) { score, probability in
                if probability > 0.1 {
                    HStack {
                        Text("\(score)")
                            .font(.system(size: 10))
                            .frame(width: 20)
                        
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(score == distribution.mostLikely ? Color.blue : Color.gray)
                                .frame(width: geometry.size.width * probability)
                                .opacity(0.3)
                        }
                        .frame(height: 4)
                    }
                }
            }
        }
        .frame(maxWidth: 100)
    }
}

// MARK: - Multi-Player Grid View

struct MultiPlayerGridView: View {
    let players: [Player]
    let hole: Int
    @State private var scores: [UUID: Int] = [:]
    @StateObject private var gridService = MultiPlayerGridService.shared
    
    var body: some View {
        GeometryReader { geometry in
            let layout = gridService.getOptimizedGridLayout(
                playerCount: players.count,
                screenWidth: geometry.size.width
            )
            
            ScrollView(layout.scrollDirection.swiftUIAxis) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(layout.cellSize.width), spacing: layout.spacing), count: layout.columns),
                    spacing: layout.spacing
                ) {
                    ForEach(players) { player in
                        GestureScoreEntryView(
                            player: player,
                            hole: hole,
                            score: binding(for: player)
                        )
                        .frame(width: layout.cellSize.width, height: layout.cellSize.height)
                    }
                }
                .padding()
            }
        }
    }
    
    private func binding(for player: Player) -> Binding<Int> {
        Binding(
            get: { scores[player.id] ?? 0 },
            set: { scores[player.id] = $0 }
        )
    }
}

extension Axis {
    var swiftUIAxis: Axis.Set {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }
}