import SwiftUI
import AVFoundation
import CoreHaptics

// MARK: - Modern Scorecard View with Fluid Gestures
struct ModernScorecardView: View {
    @StateObject private var scoreManager = ScorecardManager()
    @StateObject private var hapticManager = HapticManager()
    @State private var currentHole = 1
    @State private var isRefreshing = false
    @State private var showCelebration = false
    @State private var lastSwipeDirection: SwipeDirection = .none
    @State private var pageOffset: CGFloat = 0
    @State private var showVoiceInput = false
    @State private var collaborators: [Collaborator] = []
    @GestureState private var dragOffset: CGSize = .zero
    @Namespace private var scoreAnimation
    
    enum SwipeDirection {
        case left, right, none
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 34/255, green: 139/255, blue: 34/255).opacity(0.1),
                    Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with hole navigation
                ScorecardHeader(
                    currentHole: $currentHole,
                    totalHoles: 18,
                    format: scoreManager.format,
                    onRefresh: refreshScores
                )
                
                // Horizontal paging for holes
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(1...18, id: \.self) { hole in
                            HoleScoreView(
                                hole: hole,
                                scoreData: scoreManager.scoreFor(hole: hole),
                                isActive: hole == currentHole,
                                geometry: geometry,
                                onScoreUpdate: { score in
                                    updateScore(hole: hole, score: score)
                                },
                                namespace: scoreAnimation
                            )
                            .frame(width: geometry.size.width)
                        }
                    }
                    .offset(x: CGFloat(1 - currentHole) * geometry.size.width + dragOffset.width)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                handleSwipe(value: value, in: geometry)
                            }
                    )
                }
                
                // Bottom controls and summary
                ScorecardBottomBar(
                    scoreManager: scoreManager,
                    currentHole: currentHole,
                    showVoiceInput: $showVoiceInput,
                    collaborators: collaborators
                )
            }
            
            // Celebration overlay
            if showCelebration {
                CelebrationView(achievement: scoreManager.lastAchievement)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            // Voice input overlay
            if showVoiceInput {
                VoiceInputOverlay(
                    onScoreRecognized: { score in
                        updateScore(hole: currentHole, score: score)
                        showVoiceInput = false
                    },
                    onDismiss: {
                        showVoiceInput = false
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            hapticManager.prepare()
            setupCollaborators()
        }
        .onShake {
            undoLastAction()
        }
    }
    
    func handleSwipe(value: DragGesture.Value, in geometry: GeometryProxy) {
        let threshold = geometry.size.width * 0.3
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            if value.translation.width > threshold && currentHole > 1 {
                currentHole -= 1
                lastSwipeDirection = .right
                hapticManager.impact(.light)
            } else if value.translation.width < -threshold && currentHole < 18 {
                currentHole += 1
                lastSwipeDirection = .left
                hapticManager.impact(.light)
            }
        }
    }
    
    func updateScore(hole: Int, score: Int) {
        let oldScore = scoreManager.scoreFor(hole: hole)
        scoreManager.updateScore(for: hole, score: score)
        
        // Check for achievements
        if let achievement = scoreManager.checkAchievement(hole: hole, score: score) {
            showCelebration(for: achievement)
        }
        
        // Haptic feedback based on score
        if score < oldScore.par {
            hapticManager.success()
        } else if score > oldScore.par {
            hapticManager.warning()
        } else {
            hapticManager.impact(.medium)
        }
    }
    
    func showCelebration(for achievement: Achievement) {
        withAnimation(.spring()) {
            showCelebration = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring()) {
                showCelebration = false
            }
        }
    }
    
    func refreshScores() {
        withAnimation(.spring()) {
            isRefreshing = true
        }
        
        hapticManager.impact(.medium)
        
        // Simulate network refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            scoreManager.syncScores()
            withAnimation(.spring()) {
                isRefreshing = false
            }
        }
    }
    
    func undoLastAction() {
        scoreManager.undo()
        hapticManager.impact(.heavy)
    }
    
    func setupCollaborators() {
        // Simulate live collaboration
        collaborators = [
            Collaborator(id: "1", name: "John", color: .blue, currentHole: 3),
            Collaborator(id: "2", name: "Sarah", color: .purple, currentHole: 5)
        ]
    }
}

// MARK: - Hole Score View
struct HoleScoreView: View {
    let hole: Int
    let scoreData: ScoreData
    let isActive: Bool
    let geometry: GeometryProxy
    let onScoreUpdate: (Int) -> Void
    let namespace: Namespace.ID
    
    @State private var score: Int = 0
    @State private var isEditing = false
    @State private var showDetails = false
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Hole info with parallax effect
            VStack(spacing: 8) {
                Text("HOLE \(hole)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(isActive ? 1 : 0.6)
                
                HStack(spacing: 20) {
                    VStack {
                        Text("PAR")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(scoreData.par)")
                            .font(.title2.bold())
                    }
                    
                    VStack {
                        Text("YARDS")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(scoreData.yards)")
                            .font(.title2.bold())
                    }
                }
                .opacity(isActive ? 1 : 0.7)
                .scaleEffect(isActive ? 1 : 0.9)
            }
            .offset(y: isActive ? 0 : 20)
            
            // Score input with animation
            ZStack {
                // Background circle
                Circle()
                    .fill(scoreBackground)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // Score display
                if isEditing {
                    ScoreInputWheel(
                        score: $score,
                        par: scoreData.par,
                        onCommit: {
                            isEditing = false
                            onScoreUpdate(score)
                        }
                    )
                    .matchedGeometryEffect(id: "score_\(hole)", in: namespace)
                } else {
                    VStack(spacing: 4) {
                        Text(score > 0 ? "\(score)" : "-")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)
                        
                        if score > 0 {
                            Text(scoreLabel)
                                .font(.caption)
                                .foregroundColor(scoreColor.opacity(0.8))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .matchedGeometryEffect(id: "score_\(hole)", in: namespace)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isEditing = true
                        }
                    }
                }
                
                // Achievement indicator
                if scoreData.hasAchievement {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                        .position(x: 100, y: 20)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                }
            }
            .scaleEffect(isActive ? 1.1 : 0.95)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
            
            // Quick score buttons
            if isActive && !isEditing {
                HStack(spacing: 15) {
                    ForEach([scoreData.par - 1, scoreData.par, scoreData.par + 1], id: \.self) { quickScore in
                        QuickScoreButton(
                            score: quickScore,
                            par: scoreData.par,
                            isSelected: score == quickScore
                        ) {
                            withAnimation(.spring()) {
                                score = quickScore
                                onScoreUpdate(quickScore)
                            }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Stroke details
            if score > 0 && isActive {
                StrokeDetailsView(
                    hole: hole,
                    score: score,
                    par: scoreData.par,
                    showDetails: $showDetails
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            score = scoreData.score
        }
    }
    
    var scoreBackground: Color {
        if score == 0 { return Color.gray.opacity(0.1) }
        if score < scoreData.par { return Color.green.opacity(0.2) }
        if score > scoreData.par { return Color.red.opacity(0.2) }
        return Color.blue.opacity(0.2)
    }
    
    var scoreColor: Color {
        if score == 0 { return .gray }
        if score < scoreData.par { return .green }
        if score > scoreData.par { return .red }
        return .blue
    }
    
    var scoreLabel: String {
        let diff = score - scoreData.par
        switch diff {
        case -3: return "ALBATROSS!"
        case -2: return "EAGLE"
        case -1: return "BIRDIE"
        case 0: return "PAR"
        case 1: return "BOGEY"
        case 2: return "DOUBLE"
        case 3: return "TRIPLE"
        default: return diff > 0 ? "+\(diff)" : "\(diff)"
        }
    }
}

// MARK: - Score Input Wheel
struct ScoreInputWheel: View {
    @Binding var score: Int
    let par: Int
    let onCommit: () -> Void
    @State private var selectedScore: Int = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Picker("Score", selection: $selectedScore) {
                ForEach(1...12, id: \.self) { value in
                    Text("\(value)")
                        .font(.title.bold())
                        .tag(value)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
            
            Button(action: {
                score = selectedScore
                onCommit()
            }) {
                Text("Done")
                    .font(.callout.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
            }
        }
        .onAppear {
            selectedScore = score > 0 ? score : par
        }
    }
}

// MARK: - Quick Score Button
struct QuickScoreButton: View {
    let score: Int
    let par: Int
    let isSelected: Bool
    let action: () -> Void
    
    var scoreLabel: String {
        if score < par { return "-\(par - score)" }
        if score > par { return "+\(score - par)" }
        return "E"
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.title3.bold())
                Text(scoreLabel)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(isSelected ? Color.green : Color.gray.opacity(0.1))
            )
            .overlay(
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: isSelected ? 2 : 0)
            )
        }
        .scaleEffect(isSelected ? 1.1 : 1)
    }
}

// MARK: - Scorecard Header
struct ScorecardHeader: View {
    @Binding var currentHole: Int
    let totalHoles: Int
    let format: GolfFormat
    let onRefresh: () -> Void
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Format and refresh
            HStack {
                VStack(alignment: .leading) {
                    Text(format.name)
                        .font(.title2.bold())
                    Text("\(format.players) • \(format.type)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    isRefreshing = true
                    onRefresh()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isRefreshing = false
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(
                            isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                            value: isRefreshing
                        )
                }
            }
            .padding(.horizontal)
            
            // Hole navigation dots
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...totalHoles, id: \.self) { hole in
                            HoleNavigationDot(
                                hole: hole,
                                isActive: hole == currentHole,
                                hasScore: true // Check actual score data
                            ) {
                                withAnimation(.spring()) {
                                    currentHole = hole
                                }
                            }
                            .id(hole)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: currentHole) { newHole in
                    withAnimation {
                        proxy.scrollTo(newHole, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.95))
    }
}

// MARK: - Hole Navigation Dot
struct HoleNavigationDot: View {
    let hole: Int
    let isActive: Bool
    let hasScore: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(dotColor)
                    .frame(width: isActive ? 36 : 28, height: isActive ? 36 : 28)
                
                Text("\(hole)")
                    .font(.system(size: isActive ? 14 : 12, weight: .semibold))
                    .foregroundColor(isActive ? .white : .primary)
                
                if hasScore && !isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .position(x: 24, y: 6)
                }
            }
        }
        .scaleEffect(isActive ? 1.1 : 1)
    }
    
    var dotColor: Color {
        if isActive { return Color.green }
        if hasScore { return Color.green.opacity(0.3) }
        return Color.gray.opacity(0.2)
    }
}

// MARK: - Bottom Bar
struct ScorecardBottomBar: View {
    @ObservedObject var scoreManager: ScorecardManager
    let currentHole: Int
    @Binding var showVoiceInput: Bool
    let collaborators: [Collaborator]
    
    var body: some View {
        VStack(spacing: 16) {
            // Score summary
            HStack(spacing: 30) {
                ScoreSummaryItem(label: "SCORE", value: "\(scoreManager.totalScore)", color: .primary)
                ScoreSummaryItem(label: "THRU", value: "\(scoreManager.holesPlayed)", color: .secondary)
                ScoreSummaryItem(label: "TO PAR", value: scoreManager.toPar, color: scoreManager.parColor)
            }
            
            // Action buttons and collaborators
            HStack {
                // Voice input
                Button(action: { showVoiceInput = true }) {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.blue))
                }
                
                Spacer()
                
                // Collaborator avatars
                HStack(spacing: -10) {
                    ForEach(collaborators) { collaborator in
                        CollaboratorAvatar(collaborator: collaborator)
                    }
                }
                
                Spacer()
                
                // Stats button
                Button(action: {}) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.purple))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(
            Color.white
                .opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Supporting Views and Models

struct StrokeDetailsView: View {
    let hole: Int
    let score: Int
    let par: Int
    @Binding var showDetails: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: { showDetails.toggle() }) {
                HStack {
                    Text("Stroke Details")
                        .font(.caption)
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            if showDetails {
                VStack(spacing: 4) {
                    Text("Fairway: ✓")
                    Text("GIR: ✓")
                    Text("Putts: 2")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .transition(.opacity)
            }
        }
    }
}

struct ScoreSummaryItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
    }
}

struct CollaboratorAvatar: View {
    let collaborator: Collaborator
    
    var body: some View {
        ZStack {
            Circle()
                .fill(collaborator.color)
                .frame(width: 32, height: 32)
            
            Text(collaborator.name.prefix(1).uppercased())
                .font(.caption.bold())
                .foregroundColor(.white)
            
            // Activity indicator
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .position(x: 26, y: 26)
        }
    }
}

struct VoiceInputOverlay: View {
    let onScoreRecognized: (Int) -> Void
    let onDismiss: () -> Void
    @State private var isListening = false
    @State private var recognizedText = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Say the score")
                .font(.title2.bold())
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isListening ? 1.2 : 1)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isListening)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Button("Cancel") {
                onDismiss()
            }
            .foregroundColor(.red)
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .onAppear {
            startListening()
        }
    }
    
    func startListening() {
        isListening = true
        // Implement speech recognition
        // For demo, simulate recognition
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            recognizedText = "Four"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onScoreRecognized(4)
            }
        }
    }
}

struct CelebrationView: View {
    let achievement: Achievement?
    @State private var showParticles = false
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: achievement?.icon ?? "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .scaleEffect(showParticles ? 1.5 : 1)
                
                Text(achievement?.title ?? "Great Shot!")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(achievement?.description ?? "")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green)
            )
            .scaleEffect(showParticles ? 1 : 0.5)
            .opacity(showParticles ? 1 : 0)
            
            // Particle effect
            if showParticles {
                ParticleEmitter()
            }
        }
        .onAppear {
            withAnimation(.spring()) {
                showParticles = true
            }
        }
    }
}

struct ParticleEmitter: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var color: Color
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 10, height: 10)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    func createParticles() {
        for _ in 0..<30 {
            let particle = Particle(
                x: CGFloat.random(in: 100...300),
                y: CGFloat.random(in: 200...400),
                scale: CGFloat.random(in: 0.5...2),
                opacity: 1,
                color: [Color.yellow, .orange, .green, .blue].randomElement()!
            )
            particles.append(particle)
        }
        
        // Animate particles
        withAnimation(.easeOut(duration: 2)) {
            for i in particles.indices {
                particles[i].y -= CGFloat.random(in: 100...200)
                particles[i].opacity = 0
                particles[i].scale *= 0.5
            }
        }
    }
}

// MARK: - Data Models

class ScorecardManager: ObservableObject {
    @Published var scores: [Int: ScoreData] = [:]
    @Published var format = GolfFormat(
        name: "Stroke Play",
        description: "Traditional scoring",
        players: "1-4",
        difficulty: "Easy",
        type: "Individual"
    )
    @Published var lastAchievement: Achievement?
    
    var totalScore: Int {
        scores.values.reduce(0) { $0 + $1.score }
    }
    
    var holesPlayed: Int {
        scores.values.filter { $0.score > 0 }.count
    }
    
    var toPar: String {
        let par = scores.values.reduce(0) { $0 + $1.par }
        let diff = totalScore - par
        if diff == 0 { return "E" }
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }
    
    var parColor: Color {
        let par = scores.values.reduce(0) { $0 + $1.par }
        let diff = totalScore - par
        if diff < 0 { return .green }
        if diff > 0 { return .red }
        return .blue
    }
    
    init() {
        // Initialize with sample data
        for hole in 1...18 {
            scores[hole] = ScoreData(
                hole: hole,
                par: [3, 4, 5].randomElement()!,
                yards: Int.random(in: 150...550),
                score: 0,
                hasAchievement: false
            )
        }
    }
    
    func scoreFor(hole: Int) -> ScoreData {
        scores[hole] ?? ScoreData(hole: hole, par: 4, yards: 400, score: 0, hasAchievement: false)
    }
    
    func updateScore(for hole: Int, score: Int) {
        scores[hole]?.score = score
    }
    
    func checkAchievement(hole: Int, score: Int) -> Achievement? {
        guard let data = scores[hole] else { return nil }
        
        let diff = score - data.par
        switch diff {
        case -3:
            lastAchievement = Achievement(
                id: "albatross",
                title: "ALBATROSS!",
                description: "Three under par!",
                icon: "crown.fill"
            )
        case -2:
            lastAchievement = Achievement(
                id: "eagle",
                title: "EAGLE!",
                description: "Two under par!",
                icon: "star.circle.fill"
            )
        case -1:
            lastAchievement = Achievement(
                id: "birdie",
                title: "BIRDIE!",
                description: "One under par!",
                icon: "star.fill"
            )
        case 1 where score == 1:
            lastAchievement = Achievement(
                id: "ace",
                title: "HOLE IN ONE!",
                description: "Perfect shot!",
                icon: "flag.fill"
            )
        default:
            return nil
        }
        
        scores[hole]?.hasAchievement = true
        return lastAchievement
    }
    
    func syncScores() {
        // Simulate syncing with server
    }
    
    func undo() {
        // Implement undo logic
    }
}

struct ScoreData {
    let hole: Int
    let par: Int
    let yards: Int
    var score: Int
    var hasAchievement: Bool
}

struct Collaborator: Identifiable {
    let id: String
    let name: String
    let color: Color
    let currentHole: Int
}

struct Achievement {
    let id: String
    let title: String
    let description: String
    let icon: String
}

// MARK: - Haptic Manager

class HapticManager: ObservableObject {
    private var engine: CHHapticEngine?
    
    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Shake Gesture

struct ShakeDetector: ViewModifier {
    let onShake: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                onShake()
            }
    }
}

extension View {
    func onShake(perform: @escaping () -> Void) -> some View {
        modifier(ShakeDetector(onShake: perform))
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

// Override motion ended to detect shake
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}