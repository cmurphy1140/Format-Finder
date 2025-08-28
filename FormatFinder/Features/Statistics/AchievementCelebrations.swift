import SwiftUI
import UIKit

// MARK: - Achievement Celebrations

struct AchievementCelebrationView: View {
    let achievement: Achievement
    let player: Player
    @State private var showCelebration = false
    @State private var confettiTrigger = 0
    @State private var shareCard = false
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }
            
            // Main celebration content
            VStack(spacing: 24) {
                // Achievement icon with animation
                AchievementIcon(
                    achievement: achievement,
                    isAnimating: showCelebration
                )
                
                // Achievement text
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showCelebration ? 1 : 0.5)
                        .opacity(showCelebration ? 1 : 0)
                    
                    Text(achievement.description)
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(showCelebration ? 1 : 0)
                        .animation(.easeIn(duration: 0.5).delay(0.2), value: showCelebration)
                    
                    if let value = achievement.value {
                        Text(value)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(achievement.color)
                            .opacity(showCelebration ? 1 : 0)
                            .animation(.easeIn(duration: 0.5).delay(0.3), value: showCelebration)
                    }
                }
                
                // Player name
                Text(player.name)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        shareCard = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: dismissCelebration) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .opacity(showCelebration ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.5), value: showCelebration)
            }
            .padding()
            .scaleEffect(showCelebration ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showCelebration)
            
            // Confetti overlay
            if achievement.showConfetti {
                ConfettiView(trigger: confettiTrigger)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            triggerCelebration()
        }
        .sheet(isPresented: $shareCard) {
            AchievementShareView(
                achievement: achievement,
                player: player
            )
        }
    }
    
    private func triggerCelebration() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            showCelebration = true
        }
        
        if achievement.showConfetti {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiTrigger += 1
            }
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            showCelebration = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Achievement Icon

struct AchievementIcon: View {
    let achievement: Achievement
    let isAnimating: Bool
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(achievement.color)
                .frame(width: 150, height: 150)
                .blur(radius: 40)
                .opacity(glowOpacity)
                .scaleEffect(scale * 1.5)
            
            // Icon background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            achievement.color.opacity(0.8),
                            achievement.color
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(scale)
                .shadow(color: achievement.color.opacity(0.5), radius: 20)
            
            // Icon
            Image(systemName: achievement.icon)
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
        }
        .onAppear {
            if isAnimating {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.5)) {
                    scale = 1.0
                }
                
                withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                    rotation = 360
                }
                
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.6
                }
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let trigger: Int
    
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle)
                }
            }
            .onChange(of: trigger) { _ in
                createConfetti(in: geometry.size)
            }
        }
    }
    
    private func createConfetti(in size: CGSize) {
        particles = []
        
        for _ in 0..<100 {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -50,
                color: [.red, .blue, .green, .yellow, .orange, .purple].randomElement()!,
                size: CGFloat.random(in: 8...16),
                velocity: CGFloat.random(in: 200...400),
                angularVelocity: Double.random(in: -180...180)
            )
            particles.append(particle)
        }
        
        // Animate particles falling
        withAnimation(.easeOut(duration: 3)) {
            for i in particles.indices {
                particles[i].y = size.height + 100
            }
        }
        
        // Clear particles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            particles = []
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    let velocity: CGFloat
    let angularVelocity: Double
}

struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    @State private var rotation: Double = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 1.5)
            .position(x: particle.x, y: particle.y)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 3)) {
                    rotation = particle.angularVelocity * 3
                }
            }
    }
}

// MARK: - Achievement Share View

struct AchievementShareView: View {
    let achievement: Achievement
    let player: Player
    @Environment(\.dismiss) var dismiss
    @State private var shareImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Achievement card preview
                AchievementShareCard(
                    achievement: achievement,
                    player: player
                )
                .scaleEffect(0.8)
                .shadow(radius: 10)
                
                // Share options
                VStack(spacing: 12) {
                    Button(action: shareToSocial) {
                        Label("Share to Social", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: saveToPhotos) {
                        Label("Save to Photos", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Share Achievement")
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
    
    private func shareToSocial() {
        // Generate and share image
    }
    
    private func saveToPhotos() {
        // Save to photo library
    }
}

struct AchievementShareCard: View {
    let achievement: Achievement
    let player: Player
    
    var body: some View {
        VStack(spacing: 20) {
            // Achievement badge
            ZStack {
                Circle()
                    .fill(achievement.color)
                    .frame(width: 100, height: 100)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Achievement details
            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(.system(size: 28, weight: .bold))
                
                Text(achievement.description)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                if let value = achievement.value {
                    Text(value)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(achievement.color)
                }
            }
            
            // Player info
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                
                Text(player.name)
                    .font(.system(size: 18, weight: .medium))
            }
            
            // Date
            Text(Date().formatted(date: .long, time: .omitted))
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            // App branding
            HStack {
                Image(systemName: "flag.fill")
                    .font(.system(size: 16))
                
                Text("Format Finder")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.blue)
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// MARK: - Achievement Detector

class AchievementDetector: ObservableObject {
    @Published var pendingAchievements: [Achievement] = []
    
    func checkForAchievements(
        player: Player,
        gameState: GameState,
        hole: Int
    ) -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Check for various achievements
        if let aceAchievement = checkForHoleInOne(player: player, gameState: gameState, hole: hole) {
            achievements.append(aceAchievement)
        }
        
        if let eagleAchievement = checkForEagle(player: player, gameState: gameState, hole: hole) {
            achievements.append(eagleAchievement)
        }
        
        if let streakAchievement = checkForStreak(player: player, gameState: gameState, hole: hole) {
            achievements.append(streakAchievement)
        }
        
        if let personalBest = checkForPersonalBest(player: player, gameState: gameState) {
            achievements.append(personalBest)
        }
        
        if let milestone = checkForMilestone(player: player, gameState: gameState) {
            achievements.append(milestone)
        }
        
        return achievements
    }
    
    private func checkForHoleInOne(player: Player, gameState: GameState, hole: Int) -> Achievement? {
        guard let score = gameState.scores[hole]?[player.id], score == 1 else { return nil }
        
        return Achievement(
            title: "Hole in One!",
            description: "The perfect shot on hole \(hole)",
            icon: "star.circle.fill",
            color: .yellow,
            value: "ACE",
            showConfetti: true,
            rarity: .legendary
        )
    }
    
    private func checkForEagle(player: Player, gameState: GameState, hole: Int) -> Achievement? {
        guard let score = gameState.scores[hole]?[player.id] else { return nil }
        let par = GolfConstants.ParManagement.parForHole(hole)
        
        if score <= par - 2 {
            return Achievement(
                title: "Eagle!",
                description: "Soaring high on hole \(hole)",
                icon: "bird",
                color: .purple,
                value: "-2",
                showConfetti: true,
                rarity: .epic
            )
        }
        return nil
    }
    
    private func checkForStreak(player: Player, gameState: GameState, hole: Int) -> Achievement? {
        // Check for birdie streak
        var birdieStreak = 0
        for h in max(1, hole - 2)...hole {
            if let score = gameState.scores[h]?[player.id] {
                let par = GolfConstants.ParManagement.parForHole(h)
                if score < par {
                    birdieStreak += 1
                } else {
                    break
                }
            }
        }
        
        if birdieStreak >= 3 {
            return Achievement(
                title: "Birdie Streak!",
                description: "\(birdieStreak) birdies in a row",
                icon: "flame.fill",
                color: .orange,
                value: "\(birdieStreak) in a row",
                showConfetti: true,
                rarity: .rare
            )
        }
        
        return nil
    }
    
    private func checkForPersonalBest(player: Player, gameState: GameState) -> Achievement? {
        // Check if this is player's best round
        let totalScore = calculateTotalScore(for: player.id, in: gameState)
        
        // TODO: Compare with historical data
        if totalScore < 80 { // Placeholder
            return Achievement(
                title: "Personal Best!",
                description: "Your best round ever",
                icon: "trophy.fill",
                color: .yellow,
                value: "\(totalScore)",
                showConfetti: true,
                rarity: .epic
            )
        }
        
        return nil
    }
    
    private func checkForMilestone(player: Player, gameState: GameState) -> Achievement? {
        // Check for scoring milestones
        let totalScore = calculateTotalScore(for: player.id, in: gameState)
        
        if totalScore == 72 {
            return Achievement(
                title: "Even Par!",
                description: "Perfect balance achieved",
                icon: "equal.circle.fill",
                color: .green,
                value: "72",
                showConfetti: false,
                rarity: .rare
            )
        }
        
        if totalScore < 70 {
            return Achievement(
                title: "Breaking 70!",
                description: "Elite performance",
                icon: "bolt.circle.fill",
                color: .blue,
                value: "\(totalScore)",
                showConfetti: true,
                rarity: .legendary
            )
        }
        
        return nil
    }
    
    private func calculateTotalScore(for playerId: UUID, in gameState: GameState) -> Int {
        var total = 0
        for (_, scores) in gameState.scores {
            total += scores[playerId] ?? 0
        }
        return total
    }
}

// MARK: - Achievement Model

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let value: String?
    let showConfetti: Bool
    let rarity: AchievementRarity
    let timestamp = Date()
}

enum AchievementRarity {
    case common
    case rare
    case epic
    case legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .yellow
        }
    }
}