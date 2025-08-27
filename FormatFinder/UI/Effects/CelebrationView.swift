import SwiftUI

// MARK: - Celebration View
/// Subtle visual feedback for good shots with spring animations
struct CelebrationView: View {
    let scoreType: ScoreType
    let isActive: Bool
    let onComplete: (() -> Void)?
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var particlesVisible = false
    
    // Respect accessibility settings
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var celebrationColor: Color {
        scoreType.color
    }
    
    private var intensity: Double {
        scoreType.celebrationIntensity
    }
    
    var body: some View {
        ZStack {
            if isActive && !reduceMotion {
                // Glow effect
                Circle()
                    .fill(celebrationColor.opacity(0.3))
                    .blur(radius: glowRadius)
                    .scaleEffect(scale * 1.5)
                    .opacity(opacity)
                
                // Main celebration circle
                Circle()
                    .stroke(celebrationColor, lineWidth: 3)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                
                // Score type icon
                Image(systemName: getIconForScoreType())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(celebrationColor)
                    .scaleEffect(scale * 0.8)
                    .opacity(opacity)
                    .rotationEffect(.degrees(-rotation * 0.5))
                
                // Particle effects for special scores
                if particlesVisible && (scoreType == .ace || scoreType == .albatross || scoreType == .eagle) {
                    ParticleEffectView(
                        color: celebrationColor,
                        particleCount: Int(intensity * 20),
                        duration: 1.5
                    )
                }
            }
        }
        .frame(width: 200, height: 200)
        .allowsHitTesting(false)
        .onChange(of: isActive) { newValue in
            if newValue {
                startCelebration()
            } else {
                reset()
            }
        }
    }
    
    private func getIconForScoreType() -> String {
        switch scoreType {
        case .ace:
            return "star.fill"
        case .albatross:
            return "bird.fill"
        case .eagle:
            return "eagle"
        case .birdie:
            return "bird"
        case .par:
            return "checkmark.circle"
        case .bogey:
            return "minus.circle"
        case .doubleBogey:
            return "xmark.circle"
        case .other:
            return "circle"
        }
    }
    
    private func startCelebration() {
        // Initial spring animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
            scale = 1.2
            opacity = 1.0
            glowRadius = 20
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 2.0)) {
            rotation = 360
        }
        
        // Show particles for special scores
        if scoreType.shouldCelebrate {
            withAnimation(.easeIn(duration: 0.2)) {
                particlesVisible = true
            }
        }
        
        // Fade out animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.7)) {
                scale = 1.5
                opacity = 0
                glowRadius = 40
            }
        }
        
        // Complete and reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            reset()
            onComplete?()
        }
    }
    
    private func reset() {
        scale = 0.5
        opacity = 0
        rotation = 0
        glowRadius = 0
        particlesVisible = false
    }
}

// MARK: - Particle Effect View
struct ParticleEffectView: View {
    let color: Color
    let particleCount: Int
    let duration: Double
    
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ParticleView(particle: particle, color: color)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(x: 0, y: 0),
                velocity: CGPoint(
                    x: CGFloat.random(in: -150...150),
                    y: CGFloat.random(in: -200...(-50))
                ),
                scale: CGFloat.random(in: 0.3...1.0),
                rotation: Double.random(in: 0...360),
                lifetime: duration
            )
        }
    }
}

// MARK: - Individual Particle
struct ParticleView: View {
    let particle: Particle
    let color: Color
    
    @State private var position: CGPoint
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat
    @State private var rotation: Double
    
    init(particle: Particle, color: Color) {
        self.particle = particle
        self.color = color
        self._position = State(initialValue: particle.position)
        self._scale = State(initialValue: particle.scale)
        self._rotation = State(initialValue: particle.rotation)
    }
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12))
            .foregroundColor(color)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(position)
            .onAppear {
                animate()
            }
    }
    
    private func animate() {
        withAnimation(.easeOut(duration: particle.lifetime)) {
            position = CGPoint(
                x: position.x + particle.velocity.x,
                y: position.y + particle.velocity.y + 100 // Gravity effect
            )
            opacity = 0
            scale = scale * 0.3
            rotation = rotation + 360
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let velocity: CGPoint
    let scale: CGFloat
    let rotation: Double
    let lifetime: Double
}

// MARK: - Score Celebration Modifier
struct ScoreCelebrationModifier: ViewModifier {
    @Binding var celebrationType: ScoreType?
    let onComplete: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let type = celebrationType {
                CelebrationView(
                    scoreType: type,
                    isActive: true,
                    onComplete: {
                        celebrationType = nil
                        onComplete?()
                    }
                )
            }
        }
    }
}

extension View {
    func celebration(type: Binding<ScoreType?>, onComplete: (() -> Void)? = nil) -> some View {
        modifier(ScoreCelebrationModifier(celebrationType: type, onComplete: onComplete))
    }
}

// MARK: - Subtle Score Animation
struct SubtleScoreAnimation: View {
    let score: Int
    let par: Int
    @State private var animate = false
    
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
    
    private var shouldAnimate: Bool {
        scoreType.shouldCelebrate
    }
    
    var body: some View {
        Text("\(score)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(scoreType.color)
            .scaleEffect(animate && shouldAnimate ? 1.15 : 1.0)
            .shadow(
                color: animate && shouldAnimate ? scoreType.color.opacity(0.5) : Color.clear,
                radius: animate ? 20 : 0
            )
            .animation(
                shouldAnimate ? .spring(response: 0.4, dampingFraction: 0.6) : .none,
                value: animate
            )
            .onAppear {
                if shouldAnimate {
                    animate = true
                    
                    // Reset after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            animate = false
                        }
                    }
                }
            }
    }
}

// MARK: - Pulse Animation
struct PulseEffect: ViewModifier {
    let color: Color
    let duration: Double
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .background(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(scale)
                    .opacity(opacity)
            )
            .onAppear {
                withAnimation(
                    .easeOut(duration: duration)
                    .repeatForever(autoreverses: false)
                ) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

extension View {
    func pulse(color: Color = .blue, duration: Double = 1.5) -> some View {
        modifier(PulseEffect(color: color, duration: duration))
    }
}