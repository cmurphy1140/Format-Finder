import SwiftUI

// MARK: - Gesture-Based Score Entry

struct GestureScoreEntry: View {
    @Binding var score: Int
    let predictedScore: Int?
    let par: Int
    let onScoreChange: (Int) -> Void
    
    // Gesture states
    @State private var currentOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var showNumberWheel = false
    @State private var wheelSelection: Int
    @State private var lastVelocity: CGFloat = 0
    
    // Visual feedback
    @State private var scoreScale: CGFloat = 1.0
    @State private var impactOccurred = false
    
    // Score thresholds for swipe distance
    private let shortSwipeThreshold: CGFloat = 30
    private let mediumSwipeThreshold: CGFloat = 80
    private let longSwipeThreshold: CGFloat = 150
    
    init(score: Binding<Int>, predictedScore: Int? = nil, par: Int = 4, onScoreChange: @escaping (Int) -> Void) {
        self._score = score
        self.predictedScore = predictedScore
        self.par = par
        self.onScoreChange = onScoreChange
        self._wheelSelection = State(initialValue: score.wrappedValue > 0 ? score.wrappedValue : par)
    }
    
    private var scoreColor: Color {
        guard score > 0 else { return .gray }
        if score < par { return .green }
        if score == par { return .blue }
        if score == par + 1 { return .orange }
        return .red
    }
    
    private var displayScore: String {
        if score > 0 {
            return "\(score)"
        } else if let predicted = predictedScore {
            return "\(predicted)"
        } else {
            return "-"
        }
    }
    
    private var scoreOpacity: Double {
        score > 0 ? 1.0 : 0.4
    }
    
    private func calculateScoreChange(from offset: CGFloat, velocity: CGFloat) -> Int {
        let absOffset = abs(offset)
        let absVelocity = abs(velocity)
        
        // Velocity-based changes for quick swipes
        if absVelocity > 2000 {
            return offset < 0 ? 3 : -3
        } else if absVelocity > 1000 {
            return offset < 0 ? 2 : -2
        }
        
        // Distance-based changes
        if absOffset < shortSwipeThreshold {
            return 0
        } else if absOffset < mediumSwipeThreshold {
            return offset < 0 ? 1 : -1
        } else if absOffset < longSwipeThreshold {
            return offset < 0 ? 2 : -2
        } else {
            return offset < 0 ? 3 : -3
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        ZStack {
            // Background with gradient based on score
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            scoreColor.opacity(0.1),
                            scoreColor.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 4) {
                // Score Display
                Text(displayScore)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(score > 0 ? scoreColor : .gray)
                    .opacity(scoreOpacity)
                    .scaleEffect(scoreScale)
                    .offset(y: currentOffset / 10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scoreScale)
                
                // Swipe Indicator (only when dragging)
                if isDragging {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { i in
                            Image(systemName: currentOffset < 0 ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(scoreColor.opacity(0.6))
                                .opacity(Double(3 - i) / 3)
                        }
                    }
                    .transition(.opacity)
                }
                
                // Prediction indicator
                if score == 0 && predictedScore != nil {
                    Text("Predicted")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .opacity(0.6)
                }
            }
            .frame(width: 80, height: 80)
        }
        .frame(width: 80, height: 80)
        .contentShape(Rectangle())
        .onTapGesture {
            showNumberWheel = true
            hapticFeedback()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    currentOffset = value.translation.height
                    lastVelocity = value.velocity.height
                    
                    if !isDragging {
                        isDragging = true
                        hapticFeedback()
                    }
                    
                    // Haptic feedback at thresholds
                    let absOffset = abs(currentOffset)
                    if absOffset >= longSwipeThreshold && !impactOccurred {
                        hapticFeedback(.medium)
                        impactOccurred = true
                    } else if absOffset >= mediumSwipeThreshold && !impactOccurred {
                        hapticFeedback(.light)
                        impactOccurred = true
                    }
                }
                .onEnded { value in
                    let change = calculateScoreChange(
                        from: value.translation.height,
                        velocity: value.velocity.height
                    )
                    
                    if change != 0 {
                        let currentScore = score > 0 ? score : (predictedScore ?? par)
                        let newScore = max(1, currentScore + change)
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            score = newScore
                            scoreScale = 1.1
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scoreScale = 1.0
                            }
                        }
                        
                        onScoreChange(newScore)
                        hapticFeedback(.medium)
                    }
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentOffset = 0
                        isDragging = false
                        impactOccurred = false
                    }
                }
        )
        .sheet(isPresented: $showNumberWheel) {
            ScoreWheelPicker(
                selection: $wheelSelection,
                score: $score,
                par: par,
                onDismiss: {
                    if wheelSelection != score {
                        score = wheelSelection
                        onScoreChange(wheelSelection)
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scoreScale = 1.1
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scoreScale = 1.0
                            }
                        }
                    }
                    showNumberWheel = false
                }
            )
        }
    }
}

// MARK: - Score Wheel Picker

struct ScoreWheelPicker: View {
    @Binding var selection: Int
    @Binding var score: Int
    let par: Int
    let onDismiss: () -> Void
    
    @State private var tempSelection: Int
    
    init(selection: Binding<Int>, score: Binding<Int>, par: Int, onDismiss: @escaping () -> Void) {
        self._selection = selection
        self._score = score
        self.par = par
        self.onDismiss = onDismiss
        self._tempSelection = State(initialValue: selection.wrappedValue)
    }
    
    private let scores = Array(1...15)
    
    private func isCommonScore(_ value: Int) -> Bool {
        return value == par || value == par + 1 || value == par - 1
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Current hole info
                HStack {
                    Text("Select Score")
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Text("Par \(par)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding()
                
                // Custom wheel picker
                GeometryReader { geometry in
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Top spacer for centering
                                Spacer()
                                    .frame(height: geometry.size.height / 2 - 30)
                                
                                ForEach(scores, id: \.self) { value in
                                    ScoreWheelItem(
                                        value: value,
                                        isSelected: value == tempSelection,
                                        isCommon: isCommonScore(value),
                                        par: par,
                                        action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                tempSelection = value
                                            }
                                            // Haptic feedback
                                            let generator = UISelectionFeedbackGenerator()
                                            generator.prepare()
                                            generator.selectionChanged()
                                        }
                                    )
                                    .id(value)
                                }
                                
                                // Bottom spacer for centering
                                Spacer()
                                    .frame(height: geometry.size.height / 2 - 30)
                            }
                        }
                        .onAppear {
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(tempSelection, anchor: .center)
                                }
                            }
                        }
                    }
                }
                
                // Selection indicator overlay
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .allowsHitTesting(false)
                    .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selection = tempSelection
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(400)])
    }
}

struct ScoreWheelItem: View {
    let value: Int
    let isSelected: Bool
    let isCommon: Bool
    let par: Int
    let action: () -> Void
    
    private var scoreLabel: String {
        let diff = value - par
        if diff == 0 { return "Par" }
        if diff == -2 { return "Eagle" }
        if diff == -1 { return "Birdie" }
        if diff == 1 { return "Bogey" }
        if diff == 2 { return "Double" }
        if diff >= 3 { return "+\(diff)" }
        return "\(diff)"
    }
    
    private var scoreColor: Color {
        if value < par { return .green }
        if value == par { return .blue }
        if value == par + 1 { return .orange }
        return .red
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(value)")
                    .font(.system(
                        size: isCommon ? 32 : 28,
                        weight: isSelected ? .bold : .medium,
                        design: .rounded
                    ))
                    .foregroundColor(isSelected ? scoreColor : .primary)
                    .frame(width: 60)
                
                if isSelected {
                    Text(scoreLabel)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(scoreColor)
                        .transition(.opacity)
                }
                
                Spacer()
            }
            .frame(height: 60)
            .padding(.horizontal)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Score Prediction Service Protocol

protocol ScorePredictionService {
    func predictScore(for player: Player, hole: Hole) -> Int
    func getPlayerAverages(player: Player) -> PlayerStatistics
    func updatePredictionModel(actual: Int, predicted: Int)
}

// MARK: - Mock Implementation

class MockScorePredictionService: ScorePredictionService {
    func predictScore(for player: Player, hole: Hole) -> Int {
        // Simple prediction based on handicap and par
        let handicapAdjustment = player.handicap > 0 ? (player.handicap / 18) : 0
        return hole.par + handicapAdjustment
    }
    
    func getPlayerAverages(player: Player) -> PlayerStatistics {
        return PlayerStatistics(
            averageScore: 85,
            averagePerPar3: 3.8,
            averagePerPar4: 4.9,
            averagePerPar5: 5.8
        )
    }
    
    func updatePredictionModel(actual: Int, predicted: Int) {
        // TODO: Update ML model with actual vs predicted
        print("Updating model: predicted \(predicted), actual \(actual)")
    }
}

struct PlayerStatistics {
    let averageScore: Double
    let averagePerPar3: Double
    let averagePerPar4: Double
    let averagePerPar5: Double
}

struct Hole {
    let number: Int
    let par: Int
    let yards: Int
    let handicapIndex: Int
}