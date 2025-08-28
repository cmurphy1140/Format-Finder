import SwiftUI
import UIKit

// MARK: - Time-Based Golf Course Backgrounds

struct MorningTeeBackground: View {
    @State private var animateGradient = false
    @State private var sunPosition: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 255/255, green: 147/255, blue: 0/255), // Sunrise orange
                    Color(red: 255/255, green: 179/255, blue: 71/255), // Golden
                    Color(red: 124/255, green: 179/255, blue: 66/255)  // Fairway green
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated sun
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 255/255, green: 223/255, blue: 0/255),
                                Color(red: 255/255, green: 193/255, blue: 7/255).opacity(0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 5)
                    .position(
                        x: geo.size.width * 0.8,
                        y: geo.size.height * 0.3 + sunPosition
                    )
            }
            
            // Morning mist overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(x: 1, y: animateGradient ? 1.1 : 1, anchor: .bottom)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
                sunPosition = -20
            }
        }
    }
}

struct AfternoonFairwayBackground: View {
    @State private var cloudOffset1: CGFloat = 0
    @State private var cloudOffset2: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Sky to fairway gradient
            LinearGradient(
                colors: [
                    Color(red: 135/255, green: 206/255, blue: 235/255), // Sky blue
                    Color(red: 173/255, green: 216/255, blue: 230/255), // Light blue
                    Color(red: 0/255, green: 106/255, blue: 78/255)     // Masters green
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Animated clouds
            GeometryReader { geo in
                CloudShape()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 150, height: 60)
                    .offset(x: cloudOffset1 - geo.size.width)
                    .offset(y: geo.size.height * 0.1)
                
                CloudShape()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 120, height: 50)
                    .offset(x: cloudOffset2 - geo.size.width)
                    .offset(y: geo.size.height * 0.15)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                cloudOffset1 = UIScreen.main.bounds.width * 2
            }
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
                cloudOffset2 = UIScreen.main.bounds.width * 2.5
            }
        }
    }
}

struct SunsetRoundBackground: View {
    @State private var animateColors = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: animateColors ? sunsetColorsEnd : sunsetColorsStart,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    animateColors = true
                }
            }
    }
    
    private var sunsetColorsStart: [Color] {
        [
            Color(red: 255/255, green: 94/255, blue: 77/255),   // Coral
            Color(red: 255/255, green: 154/255, blue: 0/255),   // Orange
            Color(red: 123/255, green: 31/255, blue: 162/255),  // Purple
            Color(red: 32/255, green: 64/255, blue: 32/255)     // Dark green
        ]
    }
    
    private var sunsetColorsEnd: [Color] {
        [
            Color(red: 255/255, green: 119/255, blue: 119/255), // Light coral
            Color(red: 255/255, green: 171/255, blue: 64/255),  // Golden
            Color(red: 156/255, green: 39/255, blue: 176/255),  // Light purple
            Color(red: 0/255, green: 51/255, blue: 25/255)      // Deep green
        ]
    }
}

// MARK: - Parallax Background

struct ParallaxGolfBackground: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sky layer
                SkyLayer()
                    .offset(y: scrollOffset * 0.1)
                
                // Mountains layer
                MountainsLayer()
                    .offset(y: scrollOffset * 0.3)
                
                // Trees layer
                TreesLayer()
                    .offset(y: scrollOffset * 0.5)
                
                // Fairway layer
                FairwayLayer()
                    .offset(y: scrollOffset * 0.8)
                
                // Foreground grass
                GrassLayer()
                    .offset(y: scrollOffset)
            }
        }
    }
    
    func updateScroll(_ offset: CGFloat) {
        scrollOffset = offset
    }
}

// MARK: - Animated Golf Elements

struct GolfBallTrajectoryAnimation: View {
    @State private var ballPosition = CGPoint(x: 50, y: 300)
    @State private var showTrail = false
    let trajectory: Path
    
    init() {
        var path = Path()
        path.move(to: CGPoint(x: 50, y: 300))
        path.addQuadCurve(
            to: CGPoint(x: 350, y: 300),
            control: CGPoint(x: 200, y: 50)
        )
        self.trajectory = path
    }
    
    var body: some View {
        ZStack {
            // Trail effect
            if showTrail {
                trajectory
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                    )
            }
            
            // Golf ball
            Circle()
                .fill(Color.white)
                .frame(width: 15, height: 15)
                .shadow(radius: 3)
                .position(ballPosition)
                .modifier(FollowPath(path: trajectory, progress: showTrail ? 1 : 0))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                showTrail = true
            }
        }
    }
}

struct FlagWavingAnimation: View {
    @State private var wavePhase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, size in
                let flagWidth: CGFloat = 60
                let flagHeight: CGFloat = 40
                let poleX = size.width * 0.2
                
                // Draw pole
                let pole = Path { path in
                    path.move(to: CGPoint(x: poleX, y: size.height))
                    path.addLine(to: CGPoint(x: poleX, y: 0))
                }
                context.stroke(pole, with: .color(.brown), lineWidth: 3)
                
                // Draw waving flag
                let flag = Path { path in
                    path.move(to: CGPoint(x: poleX, y: 10))
                    
                    for x in stride(from: 0, to: flagWidth, by: 2) {
                        let wave = sin((x / flagWidth * .pi * 2) + wavePhase) * 5
                        let y = 10 + (x / flagWidth * 10) + wave
                        path.addLine(to: CGPoint(x: poleX + x, y: y))
                    }
                    
                    for x in stride(from: flagWidth, to: 0, by: -2) {
                        let wave = sin((x / flagWidth * .pi * 2) + wavePhase) * 5
                        let y = 10 + flagHeight + (x / flagWidth * 10) + wave
                        path.addLine(to: CGPoint(x: poleX + x, y: y))
                    }
                    
                    path.closeSubpath()
                }
                
                context.fill(flag, with: .color(.red))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }
}

// MARK: - Weather Effects

struct RainEffect: View {
    @State private var drops: [RainDrop] = []
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                for drop in drops {
                    let rect = CGRect(
                        x: drop.x,
                        y: drop.y,
                        width: 2,
                        height: drop.length
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.blue.opacity(drop.opacity))
                    )
                }
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                createRainDrops()
                updateRainDrops()
            }
        }
    }
    
    private func createRainDrops() {
        for _ in 0..<3 {
            drops.append(RainDrop())
        }
    }
    
    private func updateRainDrops() {
        drops = drops.compactMap { drop in
            var newDrop = drop
            newDrop.y += newDrop.speed
            newDrop.opacity -= 0.01
            
            return newDrop.y < UIScreen.main.bounds.height && newDrop.opacity > 0 ? newDrop : nil
        }
    }
}

struct WindParticles: View {
    @State private var particles: [WindParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: "leaf.fill")
                    .font(.system(size: particle.size))
                    .foregroundColor(.green.opacity(particle.opacity))
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createWindParticles()
            animateParticles()
        }
    }
    
    private func createWindParticles() {
        for i in 0..<10 {
            particles.append(WindParticle(id: i))
        }
    }
    
    private func animateParticles() {
        for index in particles.indices {
            withAnimation(
                .easeInOut(duration: Double.random(in: 3...6))
                .repeatForever(autoreverses: false)
            ) {
                particles[index].x += CGFloat.random(in: 100...300)
                particles[index].y += CGFloat.random(in: -50...50)
                particles[index].rotation += Double.random(in: 180...720)
                particles[index].opacity = 0
            }
        }
    }
}

// MARK: - Celebration Animations

struct HoleInOneFireworks: View {
    @State private var particles: [FireworkParticle] = []
    @State private var showExplosion = false
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
            
            if showExplosion {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .scaleEffect(showExplosion ? 3 : 0)
                    .opacity(showExplosion ? 0 : 1)
            }
        }
        .onAppear {
            explode()
        }
    }
    
    private func explode() {
        withAnimation(.easeOut(duration: 0.5)) {
            showExplosion = true
        }
        
        for i in 0..<50 {
            let angle = Double(i) * (360.0 / 50.0) * .pi / 180
            let particle = FireworkParticle(
                position: CGPoint(x: 200, y: 200),
                velocity: CGPoint(
                    x: cos(angle) * Double.random(in: 100...200),
                    y: sin(angle) * Double.random(in: 100...200)
                ),
                color: [.red, .yellow, .orange, .white].randomElement()!
            )
            particles.append(particle)
        }
        
        animateParticles()
    }
    
    private func animateParticles() {
        for index in particles.indices {
            withAnimation(.easeOut(duration: 2)) {
                particles[index].position.x += particles[index].velocity.x
                particles[index].position.y += particles[index].velocity.y
                particles[index].opacity = 0
                particles[index].size = 2
            }
        }
    }
}

struct BirdieBirdAnimation: View {
    @State private var birdOffset = CGSize.zero
    @State private var wingAnimation = false
    
    var body: some View {
        ZStack {
            // Bird body
            Image(systemName: wingAnimation ? "bird" : "bird.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .offset(birdOffset)
                .rotationEffect(.degrees(birdOffset.width > 0 ? -10 : 10))
        }
        .onAppear {
            // Wing flapping
            withAnimation(.easeInOut(duration: 0.2).repeatForever()) {
                wingAnimation = true
            }
            
            // Flight path
            withAnimation(.easeInOut(duration: 3)) {
                birdOffset = CGSize(width: 300, height: -100)
            }
        }
    }
}

// MARK: - Loading Animations

struct GolfBallRollingLoader: View {
    @State private var rotation: Double = 0
    @State private var position: CGFloat = -50
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Hole
                Ellipse()
                    .fill(Color.black)
                    .frame(width: 30, height: 15)
                    .offset(x: 100)
                
                // Golf ball
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                    .rotationEffect(.degrees(rotation))
                    .offset(x: position)
            }
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
                position = 100
            }
        }
    }
}

// MARK: - Custom Transitions

struct GolfBallTransition: ViewModifier {
    let isPresented: Bool
    @State private var ballPosition = CGPoint.zero
    @State private var ballScale: CGFloat = 0
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isPresented ? 1 : 0)
            
            if !isPresented {
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .scaleEffect(ballScale)
                    .position(ballPosition)
                    .shadow(radius: 5)
            }
        }
        .onAppear {
            if isPresented {
                withAnimation(.easeOut(duration: 0.6)) {
                    ballScale = 0
                    ballPosition = CGPoint(x: UIScreen.main.bounds.width, y: 0)
                }
            }
        }
    }
}

// MARK: - Animated Tab Bar

struct AnimatedGolfTabBar: View {
    @Binding var selectedTab: Int
    @State private var animatingTab: Int = 0
    
    let tabs = [
        ("Bag", "bag.fill"),
        ("Ball", "circle.fill"),
        ("Flag", "flag.fill"),
        ("Score", "list.bullet.rectangle")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = index
                        animatingTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].1)
                            .font(.system(size: 24))
                            .scaleEffect(selectedTab == index ? 1.2 : 1)
                            .rotationEffect(.degrees(animatingTab == index ? 360 : 0))
                        
                        Text(tabs[index].0)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == index ? .green : .gray)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(radius: 2)
    }
}

// MARK: - Grass Texture Overlay

struct AnimatedGrassTexture: View {
    @State private var sway: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                for x in stride(from: 0, to: size.width, by: 3) {
                    for y in stride(from: size.height - 100, to: size.height, by: 5) {
                        let grassHeight = CGFloat.random(in: 10...20)
                        let swayAmount = sin(sway + x * 0.01) * 2
                        
                        let grass = Path { path in
                            path.move(to: CGPoint(x: x, y: y))
                            path.addQuadCurve(
                                to: CGPoint(x: x + swayAmount, y: y - grassHeight),
                                control: CGPoint(x: x + swayAmount/2, y: y - grassHeight/2)
                            )
                        }
                        
                        context.stroke(
                            grass,
                            with: .color(.green.opacity(0.6)),
                            lineWidth: 1
                        )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                sway = .pi * 2
            }
        }
    }
}

// MARK: - Supporting Types

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.addEllipse(in: CGRect(x: rect.width * 0.2, y: rect.height * 0.3, 
                                   width: rect.width * 0.4, height: rect.height * 0.5))
        path.addEllipse(in: CGRect(x: rect.width * 0.4, y: rect.height * 0.1, 
                                   width: rect.width * 0.35, height: rect.height * 0.6))
        path.addEllipse(in: CGRect(x: rect.width * 0.5, y: rect.height * 0.25, 
                                   width: rect.width * 0.4, height: rect.height * 0.55))
        
        return path
    }
}

struct RainDrop {
    let id = UUID()
    var x: CGFloat = CGFloat.random(in: 0...UIScreen.main.bounds.width)
    var y: CGFloat = CGFloat.random(in: -100...0)
    let length: CGFloat = CGFloat.random(in: 10...20)
    let speed: CGFloat = CGFloat.random(in: 5...15)
    var opacity: Double = Double.random(in: 0.3...0.7)
}

struct WindParticle: Identifiable {
    let id: Int
    var x: CGFloat = CGFloat.random(in: -100...0)
    var y: CGFloat = CGFloat.random(in: 0...UIScreen.main.bounds.height)
    var size: CGFloat = CGFloat.random(in: 8...16)
    var rotation: Double = 0
    var opacity: Double = Double.random(in: 0.3...0.8)
}

struct FireworkParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let velocity: CGPoint
    var size: CGFloat = 8
    var opacity: Double = 1
    let color: Color
}

struct FollowPath: AnimatableModifier {
    let path: Path
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .position(
                path.trimmedPath(from: 0, to: progress).currentPoint ?? CGPoint.zero
            )
    }
}

// MARK: - Parallax Layers

struct SkyLayer: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 135/255, green: 206/255, blue: 235/255),
                Color(red: 255/255, green: 255/255, blue: 255/255)
            ],
            startPoint: .top,
            endPoint: .center
        )
    }
}

struct MountainsLayer: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height * 0.4))
                path.addLine(to: CGPoint(x: geo.size.width * 0.3, y: geo.size.height * 0.2))
                path.addLine(to: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.25))
                path.addLine(to: CGPoint(x: geo.size.width * 0.7, y: geo.size.height * 0.15))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.3))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(Color.gray.opacity(0.3))
        }
    }
}

struct TreesLayer: View {
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 20) {
                ForEach(0..<8) { _ in
                    Image(systemName: "tree.fill")
                        .font(.system(size: CGFloat.random(in: 30...50)))
                        .foregroundColor(.green.opacity(0.7))
                        .offset(y: CGFloat.random(in: -10...10))
                }
            }
            .offset(y: geo.size.height * 0.5)
        }
    }
}

struct FairwayLayer: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height * 0.6))
                path.addQuadCurve(
                    to: CGPoint(x: geo.size.width, y: geo.size.height * 0.65),
                    control: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.55)
                )
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 124/255, green: 179/255, blue: 66/255),
                        Color(red: 76/255, green: 175/255, blue: 80/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

struct GrassLayer: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 76/255, green: 175/255, blue: 80/255),
                                Color(red: 56/255, green: 142/255, blue: 60/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geo.size.height * 0.2)
                    .overlay(
                        AnimatedGrassTexture()
                            .opacity(0.3)
                    )
            }
        }
    }
}