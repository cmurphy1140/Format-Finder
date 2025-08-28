import SwiftUI

// MARK: - Golf Animation View Modifiers

extension View {
    
    // MARK: Background Modifiers
    
    func morningTeeBackground() -> some View {
        self.background(MorningTeeBackground().ignoresSafeArea())
    }
    
    func afternoonFairwayBackground() -> some View {
        self.background(AfternoonFairwayBackground().ignoresSafeArea())
    }
    
    func sunsetRoundBackground() -> some View {
        self.background(SunsetRoundBackground().ignoresSafeArea())
    }
    
    func timeBasedGolfBackground(for time: TimeOfDay = .afternoon) -> some View {
        self.modifier(TimeBasedBackgroundModifier(timeOfDay: time))
    }
    
    // MARK: Weather Effect Modifiers
    
    func rainEffect(intensity: RainIntensity = .medium) -> some View {
        self.overlay(
            RainEffectModifier(intensity: intensity)
        )
    }
    
    func windEffect(strength: WindStrength = .moderate) -> some View {
        self.overlay(
            WindEffectModifier(strength: strength)
        )
    }
    
    // MARK: Celebration Modifiers
    
    func celebrateHoleInOne() -> some View {
        self.modifier(HoleInOneCelebrationModifier())
    }
    
    func celebrateBirdie() -> some View {
        self.modifier(BirdieCelebrationModifier())
    }
    
    func celebrateEagle() -> some View {
        self.modifier(EagleCelebrationModifier())
    }
    
    // MARK: Transition Modifiers
    
    func golfBallTransition() -> AnyTransition {
        .modifier(
            active: GolfBallTransitionModifier(phase: .disappearing),
            identity: GolfBallTransitionModifier(phase: .appeared)
        )
    }
    
    func flagTransition() -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // MARK: Loading Modifiers
    
    func golfLoadingOverlay(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                        GolfBallRollingLoader()
                    }
                    .ignoresSafeArea()
                }
            }
        )
    }
    
    // MARK: Parallax Effect
    
    func parallaxEffect(offset: CGFloat) -> some View {
        self.modifier(ParallaxEffectModifier(scrollOffset: offset))
    }
}

// MARK: - Time-Based Background Modifier

struct TimeBasedBackgroundModifier: ViewModifier {
    let timeOfDay: TimeOfDay
    @State private var currentBackground: Int = 0
    
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    switch timeOfDay {
                    case .morning, .dawn:
                        MorningTeeBackground()
                    case .afternoon:
                        AfternoonFairwayBackground()
                    case .evening, .sunset:
                        SunsetRoundBackground()
                    case .night:
                        NightGolfBackground()
                    }
                }
                .ignoresSafeArea()
            )
    }
}

// MARK: - Weather Effect Modifiers

struct RainEffectModifier: View {
    let intensity: RainIntensity
    
    var body: some View {
        ZStack {
            ForEach(0..<intensity.dropCount, id: \.self) { _ in
                RainDropView()
            }
        }
    }
}

struct WindEffectModifier: View {
    let strength: WindStrength
    @State private var particles: [LeafParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                LeafView(particle: particle, strength: strength)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        for i in 0..<strength.particleCount {
            particles.append(LeafParticle(id: i))
        }
    }
}

// MARK: - Celebration Modifiers

struct HoleInOneCelebrationModifier: ViewModifier {
    @State private var showCelebration = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showCelebration {
                        ZStack {
                            HoleInOneFireworks()
                            
                            VStack {
                                Text("HOLE IN ONE!")
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(radius: 10)
                                    .scaleEffect(showCelebration ? 1.2 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCelebration)
                                
                                Spacer()
                            }
                            .padding(.top, 100)
                        }
                    }
                }
            )
            .onAppear {
                showCelebration = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showCelebration = false
                }
            }
    }
}

struct BirdieCelebrationModifier: ViewModifier {
    @State private var showBirds = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showBirds {
                        ForEach(0..<3, id: \.self) { index in
                            BirdieBirdAnimation()
                                .offset(x: CGFloat(index * 50 - 50))
                                .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.2), value: showBirds)
                        }
                    }
                }
            )
            .onAppear {
                showBirds = true
            }
    }
}

struct EagleCelebrationModifier: ViewModifier {
    @State private var soarAnimation = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Image(systemName: "bird")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(soarAnimation ? 0 : -45))
                    .offset(x: soarAnimation ? 400 : -400, y: soarAnimation ? -200 : 0)
                    .opacity(soarAnimation ? 0 : 1)
                    .animation(.easeInOut(duration: 2), value: soarAnimation)
                    .onAppear {
                        soarAnimation = true
                    }
            )
    }
}

// MARK: - Transition Modifiers

struct GolfBallTransitionModifier: ViewModifier {
    enum Phase {
        case appearing, appeared, disappearing
    }
    
    let phase: Phase
    @State private var ballOffset = CGSize.zero
    @State private var ballScale: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(phase == .appeared ? 1 : 0)
            .opacity(phase == .appeared ? 1 : 0)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .scaleEffect(ballScale)
                    .offset(ballOffset)
                    .opacity(phase == .appeared ? 0 : 1)
            )
            .onAppear {
                animate()
            }
    }
    
    private func animate() {
        withAnimation(.easeOut(duration: 0.6)) {
            switch phase {
            case .appearing:
                ballScale = 1
                ballOffset = CGSize(width: 200, height: -100)
            case .appeared:
                ballScale = 0
            case .disappearing:
                ballScale = 0
                ballOffset = CGSize(width: -200, height: -100)
            }
        }
    }
}

// MARK: - Parallax Modifier

struct ParallaxEffectModifier: ViewModifier {
    let scrollOffset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                ParallaxGolfBackground()
                    .offset(y: scrollOffset * 0.5)
            )
    }
}

// MARK: - Night Golf Background

struct NightGolfBackground: View {
    @State private var starOpacity: [Double] = Array(repeating: 0, count: 50)
    
    var body: some View {
        ZStack {
            // Dark sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0/255, green: 0/255, blue: 30/255),
                    Color(red: 0/255, green: 20/255, blue: 40/255),
                    Color(red: 0/255, green: 40/255, blue: 30/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Stars
            GeometryReader { geo in
                ForEach(0..<50, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height * 0.6)
                        )
                        .opacity(starOpacity[index])
                }
            }
            
            // Moon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.white.opacity(0.8), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 40
                    )
                )
                .frame(width: 60, height: 60)
                .position(x: UIScreen.main.bounds.width * 0.8, y: 100)
        }
        .onAppear {
            animateStars()
        }
    }
    
    private func animateStars() {
        for index in starOpacity.indices {
            withAnimation(
                .easeInOut(duration: Double.random(in: 1...3))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2))
            ) {
                starOpacity[index] = Double.random(in: 0.3...1.0)
            }
        }
    }
}

// MARK: - Supporting Components

struct RainDropView: View {
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0.6
    let startX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
    let speed = Double.random(in: 1...2)
    
    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(opacity))
            .frame(width: 2, height: 20)
            .position(x: startX, y: offset)
            .onAppear {
                withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                    offset = UIScreen.main.bounds.height + 100
                }
                
                withAnimation(.easeIn(duration: speed)) {
                    opacity = 0
                }
            }
    }
}

struct LeafView: View {
    let particle: LeafParticle
    let strength: WindStrength
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: particle.size))
            .foregroundColor(.green.opacity(particle.opacity))
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: strength.animationDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = CGSize(
                        width: UIScreen.main.bounds.width + 100,
                        height: CGFloat.random(in: -50...50)
                    )
                    rotation = 360
                }
            }
    }
}

// MARK: - Supporting Types

enum TimeOfDay {
    case morning, dawn, afternoon, evening, sunset, night
}

enum RainIntensity {
    case light, medium, heavy
    
    var dropCount: Int {
        switch self {
        case .light: return 20
        case .medium: return 50
        case .heavy: return 100
        }
    }
}

enum WindStrength {
    case calm, light, moderate, strong
    
    var particleCount: Int {
        switch self {
        case .calm: return 0
        case .light: return 5
        case .moderate: return 10
        case .strong: return 20
        }
    }
    
    var animationDuration: Double {
        switch self {
        case .calm: return 0
        case .light: return 8
        case .moderate: return 5
        case .strong: return 3
        }
    }
}

struct LeafParticle: Identifiable {
    let id: Int
    let size = CGFloat.random(in: 10...20)
    let opacity = Double.random(in: 0.3...0.8)
    let startY = CGFloat.random(in: 0...UIScreen.main.bounds.height)
}