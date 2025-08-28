import SwiftUI

// MARK: - Enhanced Scorecard with Backend Services

struct EnhancedScorecardView: View {
    let format: GolfFormat
    let configuration: GameConfiguration
    @State private var currentHole = 1
    @State private var scores: [UUID: [Int: Int]] = [:]
    @StateObject private var gridSyncEngine = GridSyncEngine.shared
    @StateObject private var physicsEngine = PhysicsSimulationEngine.shared
    @StateObject private var animationOrchestrator = AnimationOrchestrator.shared
    @StateObject private var gestureScoreService = GestureScoreService.shared
    @Environment(\.dismiss) var dismiss
    @State private var showStats = false
    @State private var swipeOffset = CGSize.zero
    
    var body: some View {
        NavigationView {
            ZStack {
                // Green gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.fairwayGreen.opacity(0.1),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with hole navigation
                    ScorecardHeader(
                        format: format,
                        currentHole: $currentHole,
                        totalHoles: configuration.numberOfHoles,
                        onDismiss: { dismiss() }
                    )
                    
                    // Main scorecard content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Hole information card
                            HoleInfoCard(hole: currentHole)
                            
                            // Player score entries
                            ForEach(configuration.players.filter { $0.isActive }) { player in
                                EnhancedPlayerScoreCard(
                                    player: player,
                                    hole: currentHole,
                                    score: binding(for: player.id, hole: currentHole),
                                    format: format,
                                    gridSyncEngine: gridSyncEngine,
                                    physicsEngine: physicsEngine
                                )
                            }
                            
                            // Quick actions
                            QuickActionsRow(
                                currentHole: $currentHole,
                                totalHoles: configuration.numberOfHoles
                            )
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        swipeOffset = value.translation
                    }
                    .onEnded { value in
                        handleSwipe(value.translation)
                        swipeOffset = .zero
                    }
            )
            .sheet(isPresented: $showStats) {
                StatsOverlay(scores: scores, format: format, players: configuration.players)
            }
        }
    }
    
    private func binding(for playerId: UUID, hole: Int) -> Binding<Int> {
        Binding(
            get: { scores[playerId]?[hole] ?? 0 },
            set: { newScore in
                if scores[playerId] == nil {
                    scores[playerId] = [:]
                }
                scores[playerId]?[hole] = newScore
                
                // Sync with backend
                Task {
                    await gridSyncEngine.updateScore(
                        playerId: playerId,
                        hole: hole,
                        score: newScore
                    )
                }
            }
        )
    }
    
    private func handleSwipe(_ translation: CGSize) {
        let threshold: CGFloat = 100
        
        withAnimation(.spring()) {
            if translation.width < -threshold && currentHole < configuration.numberOfHoles {
                currentHole += 1
                animationOrchestrator.triggerHaptic(.light)
            } else if translation.width > threshold && currentHole > 1 {
                currentHole -= 1
                animationOrchestrator.triggerHaptic(.light)
            }
        }
    }
}

// MARK: - Enhanced Player Score Card with Quick Buttons

struct EnhancedPlayerScoreCard: View {
    let player: Player
    let hole: Int
    @Binding var score: Int
    let format: GolfFormat
    let gridSyncEngine: GridSyncEngine
    let physicsEngine: PhysicsSimulationEngine
    @State private var isEditing = false
    @State private var animateScore = false
    
    // Hardcoded par for now - would normally come from course data
    let par = 4
    
    var body: some View {
        VStack(spacing: 15) {
            // Player header
            HStack {
                HStack(spacing: 10) {
                    Circle()
                        .fill(AppColors.primaryGreen)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(player.initials)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.darkGreen)
                        
                        if player.handicap > 0 {
                            Text("Handicap: \(player.handicap)")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Current score display
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(scoreColor)
                        .frame(width: 60, height: 60)
                    
                    if score > 0 {
                        Text("\(score)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(animateScore ? 1.2 : 1)
                    } else {
                        Text("-")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .onTapGesture {
                    isEditing = true
                }
            }
            
            // Quick Score Buttons (Par, Bogey, Birdie)
            HStack(spacing: 12) {
                QuickScoreButton(
                    title: "Birdie",
                    value: par - 1,
                    color: AppColors.brightGreen,
                    isSelected: score == par - 1,
                    action: {
                        updateScore(par - 1)
                    }
                )
                
                QuickScoreButton(
                    title: "Par",
                    value: par,
                    color: AppColors.primaryGreen,
                    isSelected: score == par,
                    action: {
                        updateScore(par)
                    }
                )
                
                QuickScoreButton(
                    title: "Bogey",
                    value: par + 1,
                    color: Color.orange,
                    isSelected: score == par + 1,
                    action: {
                        updateScore(par + 1)
                    }
                )
                
                QuickScoreButton(
                    title: "Double",
                    value: par + 2,
                    color: Color.red,
                    isSelected: score == par + 2,
                    action: {
                        updateScore(par + 2)
                    }
                )
            }
            
            // Score adjustment stepper
            if isEditing {
                HStack(spacing: 20) {
                    Button(action: { updateScore(max(1, score - 1)) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.primaryGreen)
                    }
                    
                    Text("\(score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.darkGreen)
                        .frame(width: 60)
                    
                    Button(action: { updateScore(min(12, score + 1)) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.primaryGreen)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppColors.cardShadow, radius: 6, x: 0, y: 3)
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    handleGesture(value.translation)
                }
        )
        .sheet(isPresented: $isEditing) {
            ScoreEditSheet(
                player: player,
                hole: hole,
                score: $score,
                par: par,
                onDismiss: { isEditing = false }
            )
        }
    }
    
    private func updateScore(_ newScore: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            score = newScore
            animateScore = true
        }
        
        // Haptic feedback
        AnimationOrchestrator.shared.triggerHaptic(.light)
        
        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateScore = false
        }
        
        // Close editor if open
        isEditing = false
    }
    
    private func handleGesture(_ translation: CGSize) {
        if abs(translation.height) > abs(translation.width) {
            if translation.height < -50 {
                // Swipe up - increase score
                updateScore(min(12, score + 1))
            } else if translation.height > 50 {
                // Swipe down - decrease score
                updateScore(max(0, score - 1))
            }
        }
    }
    
    private var scoreColor: Color {
        guard score > 0 else { return AppColors.textTertiary }
        
        let diff = score - par
        switch diff {
        case ..<(-1): return AppColors.brightGreen // Eagle or better
        case -1: return AppColors.primaryGreen      // Birdie
        case 0: return AppColors.darkGreen          // Par
        case 1: return Color.orange                 // Bogey
        default: return Color.red                   // Double or worse
        }
    }
}

// MARK: - Quick Score Button

struct QuickScoreButton: View {
    let title: String
    let value: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color)
                
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppColors.darkGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Supporting Components

struct ScorecardHeader: View {
    let format: GolfFormat
    @Binding var currentHole: Int
    let totalHoles: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Top bar
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text(format.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal)
            
            // Hole navigation
            HStack(spacing: 20) {
                Button(action: { 
                    if currentHole > 1 { currentHole -= 1 }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(currentHole > 1 ? 0.8 : 0.3))
                }
                .disabled(currentHole <= 1)
                
                VStack(spacing: 4) {
                    Text("Hole")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(currentHole)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 80)
                
                Button(action: { 
                    if currentHole < totalHoles { currentHole += 1 }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(currentHole < totalHoles ? 0.8 : 0.3))
                }
                .disabled(currentHole >= totalHoles)
            }
        }
        .padding(.vertical)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [AppColors.primaryGreen, AppColors.darkGreen]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct HoleInfoCard: View {
    let hole: Int
    // These would normally come from course data
    let par = 4
    let yards = 385
    
    var body: some View {
        HStack(spacing: 30) {
            InfoItem(title: "Par", value: "\(par)")
            InfoItem(title: "Yards", value: "\(yards)")
            InfoItem(title: "Handicap", value: "\(hole % 18 + 1)")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white, AppColors.lightGreen.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: AppColors.cardShadow, radius: 4, x: 0, y: 2)
        )
    }
}

struct InfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.darkGreen)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionsRow: View {
    @Binding var currentHole: Int
    let totalHoles: Int
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: {}) {
                Label("Notes", systemImage: "note.text")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.darkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: AppColors.cardShadow, radius: 3, x: 0, y: 2)
            }
            
            Button(action: {}) {
                Label("Stats", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.darkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: AppColors.cardShadow, radius: 3, x: 0, y: 2)
            }
            
            if currentHole == totalHoles {
                Button(action: {}) {
                    Label("Finish Round", systemImage: "flag.checkered")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppColors.primaryGreen)
                        .cornerRadius(20)
                        .shadow(color: AppColors.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 3)
                }
            }
        }
    }
}

struct ScoreEditSheet: View {
    let player: Player
    let hole: Int
    @Binding var score: Int
    let par: Int
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("\(player.name) - Hole \(hole)")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.darkGreen)
                
                // Score picker
                Picker("Score", selection: $score) {
                    ForEach(0...12, id: \.self) { value in
                        Text(value == 0 ? "-" : "\(value)")
                            .tag(value)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                
                // Score relative to par
                if score > 0 {
                    HStack(spacing: 20) {
                        Text("Par \(par)")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(scoreDescription)
                            .font(.title3.bold())
                            .foregroundColor(scoreColor)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(AppColors.primaryGreen)
                }
            }
        }
    }
    
    private var scoreDescription: String {
        let diff = score - par
        switch diff {
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double Bogey"
        default: return diff < 0 ? "\(abs(diff)) Under" : "\(diff) Over"
        }
    }
    
    private var scoreColor: Color {
        let diff = score - par
        switch diff {
        case ..<(-1): return AppColors.brightGreen
        case -1: return AppColors.primaryGreen
        case 0: return AppColors.darkGreen
        case 1: return Color.orange
        default: return Color.red
        }
    }
}

struct StatsOverlay: View {
    let scores: [UUID: [Int: Int]]
    let format: GolfFormat
    let players: [Player]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Round Statistics")
                    .font(.title.bold())
                    .foregroundColor(AppColors.darkGreen)
                
                // Stats content would go here
                Spacer()
            }
            .padding()
        }
    }
}

// Player extension for initials
extension Player {
    var initials: String {
        let words = name.split(separator: " ")
        let initials = words.compactMap { $0.first }
        return String(initials.prefix(2))
    }
}