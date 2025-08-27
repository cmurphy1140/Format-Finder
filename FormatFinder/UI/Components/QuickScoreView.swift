import SwiftUI

// MARK: - Quick Score View
/// Intelligent quick score entry with par-based suggestions
struct QuickScoreView: View {
    let par: Int
    @Binding var score: Int
    let onScoreSelected: ((Int) -> Void)?
    
    @State private var showFullPicker = false
    @State private var lastHapticScore: Int = 0
    
    /// Calculate available score options based on par
    private var scoreOptions: [ScoreOption] {
        var options: [ScoreOption] = []
        
        // Add scores relative to par
        switch par {
        case 3:
            // Par 3: Hole-in-one (1), Eagle (2), Birdie (2), Par (3), Bogey (4), Double (5)
            options = [
                ScoreOption(score: 1, label: "Ace", type: .ace),
                ScoreOption(score: 2, label: "Birdie", type: .birdie),
                ScoreOption(score: 3, label: "Par", type: .par),
                ScoreOption(score: 4, label: "Bogey", type: .bogey),
                ScoreOption(score: 5, label: "Double", type: .doubleBogey)
            ]
        case 4:
            // Par 4: Eagle (2), Birdie (3), Par (4), Bogey (5), Double (6)
            options = [
                ScoreOption(score: 2, label: "Eagle", type: .eagle),
                ScoreOption(score: 3, label: "Birdie", type: .birdie),
                ScoreOption(score: 4, label: "Par", type: .par),
                ScoreOption(score: 5, label: "Bogey", type: .bogey),
                ScoreOption(score: 6, label: "Double", type: .doubleBogey)
            ]
        case 5:
            // Par 5: Albatross (2), Eagle (3), Birdie (4), Par (5), Bogey (6), Double (7)
            options = [
                ScoreOption(score: 2, label: "Albatross", type: .albatross),
                ScoreOption(score: 3, label: "Eagle", type: .eagle),
                ScoreOption(score: 4, label: "Birdie", type: .birdie),
                ScoreOption(score: 5, label: "Par", type: .par),
                ScoreOption(score: 6, label: "Bogey", type: .bogey)
            ]
        default:
            // Fallback for non-standard pars
            options = [
                ScoreOption(score: par - 1, label: "Birdie", type: .birdie),
                ScoreOption(score: par, label: "Par", type: .par),
                ScoreOption(score: par + 1, label: "Bogey", type: .bogey),
                ScoreOption(score: par + 2, label: "Double", type: .doubleBogey)
            ]
        }
        
        return options
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Current score display
            CurrentScoreDisplay(score: score, par: par)
            
            // Quick score buttons
            HStack(spacing: 8) {
                ForEach(scoreOptions) { option in
                    QuickScoreButton(
                        option: option,
                        isSelected: score == option.score,
                        action: {
                            selectScore(option.score, type: option.type)
                        }
                    )
                }
            }
            
            // More options button
            Button(action: { showFullPicker = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "ellipsis.circle")
                    Text("More")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            }
        }
        .sheet(isPresented: $showFullPicker) {
            FullScorePicker(
                currentScore: $score,
                par: par,
                onDismiss: { showFullPicker = false }
            )
        }
    }
    
    private func selectScore(_ newScore: Int, type: ScoreType) {
        let previousScore = score
        score = newScore
        
        // Trigger haptic feedback based on score type
        HapticManager.scoreEntry(type: type, par: par)
        
        // Check if we should celebrate
        if type.shouldCelebrate {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                onScoreSelected?(newScore)
            }
        } else {
            onScoreSelected?(newScore)
        }
    }
}

// MARK: - Score Option Model
struct ScoreOption: Identifiable {
    let id = UUID()
    let score: Int
    let label: String
    let type: ScoreType
}

enum ScoreType {
    case ace
    case albatross
    case eagle
    case birdie
    case par
    case bogey
    case doubleBogey
    case other
    
    var color: Color {
        switch self {
        case .ace, .albatross:
            return Color(red: 255/255, green: 215/255, blue: 0/255) // Gold
        case .eagle:
            return Color(red: 148/255, green: 0/255, blue: 211/255) // Purple
        case .birdie:
            return AppColors.primaryGreen
        case .par:
            return Color.blue
        case .bogey:
            return Color.orange
        case .doubleBogey, .other:
            return Color.red
        }
    }
    
    var shouldCelebrate: Bool {
        switch self {
        case .ace, .albatross, .eagle, .birdie:
            return true
        default:
            return false
        }
    }
    
    var celebrationIntensity: Double {
        switch self {
        case .ace, .albatross:
            return 1.0
        case .eagle:
            return 0.8
        case .birdie:
            return 0.5
        default:
            return 0
        }
    }
}

// MARK: - Quick Score Button
struct QuickScoreButton: View {
    let option: ScoreOption
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            VStack(spacing: 4) {
                Text("\(option.score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : option.type.color)
                
                Text(option.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : AppColors.textSecondary)
            }
            .frame(minWidth: 60, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? option.type.color : Color.white)
                    .shadow(
                        color: isSelected ? option.type.color.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white.opacity(0.3) : option.type.color.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.92 : (isSelected ? 1.05 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
            if pressing {
                HapticManager.impact(.light)
            }
        }, perform: {})
    }
}

// MARK: - Current Score Display
struct CurrentScoreDisplay: View {
    let score: Int
    let par: Int
    
    private var scoreToPar: Int {
        score - par
    }
    
    private var scoreColor: Color {
        if score == 0 { return AppColors.textSecondary }
        if scoreToPar < 0 { return AppColors.primaryGreen }
        if scoreToPar == 0 { return Color.blue }
        return Color.red
    }
    
    private var scoreLabel: String {
        if score == 0 { return "—" }
        return "\(score)"
    }
    
    private var scoreToParLabel: String {
        if score == 0 { return "" }
        if scoreToPar == 0 { return "E" }
        if scoreToPar > 0 { return "+\(scoreToPar)" }
        return "\(scoreToPar)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                Text(scoreLabel)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
            }
            
            if score > 0 {
                VStack(spacing: 2) {
                    Text("To Par")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text(scoreToParLabel)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(scoreColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Full Score Picker
struct FullScorePicker: View {
    @Binding var currentScore: Int
    let par: Int
    let onDismiss: () -> Void
    
    private let scores = Array(1...20)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Score for Par \(par)")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.top)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(scores, id: \.self) { score in
                        FullScoreButton(
                            score: score,
                            par: par,
                            isSelected: currentScore == score,
                            action: {
                                currentScore = score
                                HapticManager.selection()
                                onDismiss()
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    onDismiss()
                }
            )
        }
    }
}

// MARK: - Full Score Button
struct FullScoreButton: View {
    let score: Int
    let par: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var scoreType: ScoreType {
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
        Button(action: action) {
            Text("\(score)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSelected ? .white : scoreType.color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? scoreType.color : Color.white)
                        .shadow(color: scoreType.color.opacity(0.2), radius: 4)
                )
                .overlay(
                    Circle()
                        .stroke(scoreType.color.opacity(0.3), lineWidth: 1)
                )
        }
    }
}