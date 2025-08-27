import SwiftUI

// MARK: - Enhanced Score Entry View
/// Combines quick score buttons, haptic feedback, and celebrations
struct EnhancedScoreEntry: View {
    @Binding var score: Int
    let par: Int
    let holeNumber: Int
    let playerName: String
    
    @State private var showCelebration = false
    @State private var celebrationType: ScoreType?
    @State private var previousScore: Int = 0
    @State private var isEditing = false
    
    // Animation states
    @State private var scoreScale: CGFloat = 1.0
    @State private var scoreRotation: Double = 0
    @State private var glowOpacity: Double = 0
    
    private var scoreType: ScoreType {
        guard score > 0 else { return .other }
        let diff = score - par
        switch diff {
        case ...(-3): return .albatross
        case -2: return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        case 2: return .doubleBogey
        default: return .other
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Player and hole info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playerName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Hole \(holeNumber) • Par \(par)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Score display with animation
                ZStack {
                    // Glow background
                    Circle()
                        .fill(scoreType.color.opacity(glowOpacity))
                        .blur(radius: 20)
                        .frame(width: 80, height: 80)
                    
                    // Score circle
                    Button(action: { 
                        isEditing.toggle()
                        HapticManager.selection()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .shadow(color: scoreType.color.opacity(0.3), radius: 8)
                            
                            Circle()
                                .stroke(scoreType.color, lineWidth: 3)
                            
                            if score > 0 {
                                VStack(spacing: 2) {
                                    Text("\(score)")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(scoreType.color)
                                    
                                    Text(scoreTypeLabel())
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(scoreType.color.opacity(0.8))
                                }
                            } else {
                                Text("—")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .frame(width: 70, height: 70)
                        .scaleEffect(scoreScale)
                        .rotationEffect(.degrees(scoreRotation))
                    }
                }
            }
            
            if isEditing {
                // Quick score entry
                QuickScoreView(
                    par: par,
                    score: $score,
                    onScoreSelected: { newScore in
                        handleScoreChange(from: previousScore, to: newScore)
                        withAnimation(.spring()) {
                            isEditing = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            } else {
                // Increment/Decrement buttons
                HStack(spacing: 40) {
                    // Decrease button
                    Button(action: {
                        if score > 1 {
                            let newScore = score - 1
                            handleScoreChange(from: score, to: newScore)
                            score = newScore
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(Color.red.opacity(0.8))
                    }
                    .disabled(score <= 1)
                    
                    // Quick par button
                    Button(action: {
                        handleScoreChange(from: score, to: par)
                        score = par
                    }) {
                        VStack(spacing: 4) {
                            Text("PAR")
                                .font(.system(size: 12, weight: .bold))
                            Text("\(par)")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    
                    // Increase button
                    Button(action: {
                        if score < 20 {
                            let newScore = score == 0 ? par : score + 1
                            handleScoreChange(from: score, to: newScore)
                            score = newScore
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.primaryGreen.opacity(0.8))
                    }
                    .disabled(score >= 20)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        )
        .overlay(
            // Celebration overlay
            Group {
                if let celebType = celebrationType {
                    CelebrationView(
                        scoreType: celebType,
                        isActive: true,
                        onComplete: {
                            celebrationType = nil
                        }
                    )
                    .allowsHitTesting(false)
                }
            }
        )
        .onAppear {
            previousScore = score
        }
    }
    
    private func scoreTypeLabel() -> String {
        guard score > 0 else { return "" }
        let diff = score - par
        switch diff {
        case ...(-3): return "WOW!"
        case -2: return "EAGLE"
        case -1: return "BIRDIE"
        case 0: return "PAR"
        case 1: return "BOGEY"
        case 2: return "DOUBLE"
        case 3: return "TRIPLE"
        default: return "+\(diff)"
        }
    }
    
    private func handleScoreChange(from oldScore: Int, to newScore: Int) {
        guard newScore != oldScore else { return }
        
        // Determine score type for new score
        let diff = newScore - par
        let newScoreType: ScoreType = {
            switch diff {
            case ...(-3): return .albatross
            case -2: return .eagle
            case -1: return .birdie
            case 0: return .par
            case 1: return .bogey
            case 2: return .doubleBogey
            default: return .other
            }
        }()
        
        // Trigger haptic feedback
        HapticManager.scoreEntry(type: newScoreType, par: par)
        
        // Trigger celebration for good scores
        if newScoreType.shouldCelebrate {
            celebrationType = newScoreType
            
            // Animate score display
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scoreScale = 1.2
                glowOpacity = 0.3
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
                scoreScale = 1.0
                glowOpacity = 0
            }
        }
        
        previousScore = newScore
    }
}

// MARK: - Compact Score Entry
/// Smaller version for use in lists and grids
struct CompactScoreEntry: View {
    @Binding var score: Int
    let par: Int
    let playerName: String
    
    @State private var showQuickEntry = false
    
    private var scoreColor: Color {
        guard score > 0 else { return AppColors.textSecondary }
        let diff = score - par
        if diff < 0 { return AppColors.primaryGreen }
        if diff == 0 { return Color.blue }
        return Color.red
    }
    
    var body: some View {
        HStack {
            Text(playerName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: {
                showQuickEntry = true
                HapticManager.selection()
            }) {
                HStack(spacing: 8) {
                    if score > 0 {
                        Text("\(score)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)
                        
                        Text(scoreLabel())
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(scoreColor.opacity(0.7))
                    } else {
                        Text("Enter")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(scoreColor.opacity(0.1))
                )
            }
        }
        .sheet(isPresented: $showQuickEntry) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("\(playerName) - Hole Par \(par)")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.top)
                    
                    QuickScoreView(
                        par: par,
                        score: $score,
                        onScoreSelected: { _ in
                            showQuickEntry = false
                        }
                    )
                    
                    Spacer()
                }
                .padding()
                .navigationBarItems(
                    trailing: Button("Done") {
                        showQuickEntry = false
                    }
                )
            }
        }
    }
    
    private func scoreLabel() -> String {
        guard score > 0 else { return "" }
        let diff = score - par
        switch diff {
        case ...(-2): return "🔥"  // Using text until we replace with icon
        case -1: return "↓"
        case 0: return "="
        case 1: return "↑"
        default: return "+\(diff)"
        }
    }
}

// MARK: - Score Entry Grid
/// Grid layout for multiple players
struct ScoreEntryGrid: View {
    let players: [Player]
    @Binding var scores: [UUID: Int]
    let par: Int
    let holeNumber: Int
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hole \(holeNumber)")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Text("Par \(par)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(players) { player in
                    CompactScoreEntry(
                        score: Binding(
                            get: { scores[player.id] ?? 0 },
                            set: { scores[player.id] = $0 }
                        ),
                        par: par,
                        playerName: player.name
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8)
        )
    }
}