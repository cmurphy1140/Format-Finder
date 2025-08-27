import SwiftUI
import Combine

// MARK: - Physics-Based Ball Flight Animation System
struct BallPhysicsEngine {
    // Physics constants
    static let gravity: Double = 9.81
    static let airDensity: Double = 1.225
    static let ballMass: Double = 0.0459 // kg (golf ball)
    static let ballRadius: Double = 0.0214 // m
    static let dragCoefficient: Double = 0.47
    
    struct LaunchParameters {
        let velocity: Double // m/s
        let angle: Double // degrees
        let spin: Double // rpm
        let windSpeed: Vector2D
        let elevation: Double
    }
    
    struct Vector2D {
        var x: Double
        var y: Double
        
        static let zero = Vector2D(x: 0, y: 0)
        
        func magnitude() -> Double {
            sqrt(x * x + y * y)
        }
        
        func normalized() -> Vector2D {
            let mag = magnitude()
            guard mag > 0 else { return .zero }
            return Vector2D(x: x / mag, y: y / mag)
        }
        
        static func +(lhs: Vector2D, rhs: Vector2D) -> Vector2D {
            Vector2D(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
        }
        
        static func *(lhs: Vector2D, rhs: Double) -> Vector2D {
            Vector2D(x: lhs.x * rhs, y: lhs.y * rhs)
        }
    }
    
    static func calculateTrajectory(launch: LaunchParameters, timeStep: Double = 0.01) -> [CGPoint] {
        var points: [CGPoint] = []
        var time: Double = 0
        let maxTime: Double = 10 // Maximum simulation time
        
        // Initial conditions
        let angleRad = launch.angle * .pi / 180
        var position = Vector2D(x: 0, y: launch.elevation)
        var velocity = Vector2D(
            x: launch.velocity * cos(angleRad),
            y: launch.velocity * sin(angleRad)
        )
        
        // Magnus effect from spin
        let magnusCoefficient = 0.00001 * launch.spin
        
        while time < maxTime && position.y >= 0 {
            // Air resistance
            let speed = velocity.magnitude()
            let dragForce = 0.5 * airDensity * pow(speed, 2) * dragCoefficient * .pi * pow(ballRadius, 2)
            let dragDeceleration = dragForce / ballMass
            
            // Magnus force (simplified)
            let magnusForce = magnusCoefficient * speed
            
            // Wind effect
            let relativeVelocity = Vector2D(
                x: velocity.x - launch.windSpeed.x,
                y: velocity.y - launch.windSpeed.y
            )
            
            // Update velocity
            let dragVector = relativeVelocity.normalized() * dragDeceleration * timeStep
            velocity.x -= dragVector.x
            velocity.y -= dragVector.y - gravity * timeStep + magnusForce * timeStep
            
            // Update position
            position.x += velocity.x * timeStep
            position.y += velocity.y * timeStep
            
            // Add point to trajectory
            points.append(CGPoint(x: position.x, y: position.y))
            
            time += timeStep
        }
        
        return points
    }
}

// MARK: - Ball Flight View
struct BallFlightView: View {
    @State private var ballPosition: CGPoint = .zero
    @State private var trailPoints: [CGPoint] = []
    @State private var animationProgress: Double = 0
    @State private var showWindEffect = false
    @State private var selectedClub = "Driver"
    
    let clubs: [(name: String, velocity: Double, angle: Double, spin: Double)] = [
        ("Driver", 70, 12, 2500),
        ("3 Wood", 65, 14, 3500),
        ("5 Iron", 55, 18, 5000),
        ("7 Iron", 48, 22, 6500),
        ("9 Iron", 40, 28, 8500),
        ("PW", 35, 35, 9500),
        ("SW", 28, 45, 10500)
    ]
    
    var selectedClubData: (name: String, velocity: Double, angle: Double, spin: Double) {
        clubs.first { $0.name == selectedClub } ?? clubs[0]
    }
    
    @State private var windSpeed = BallPhysicsEngine.Vector2D(x: 5, y: 0)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky gradient background
                LinearGradient(
                    colors: [
                        Color(red: 135/255, green: 206/255, blue: 235/255),
                        Color(red: 255/255, green: 255/255, blue: 255/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Ground
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.8))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.8))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 34/255, green: 139/255, blue: 34/255),
                            Color(red: 0/255, green: 100/255, blue: 0/255)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Wind effect visualization
                if showWindEffect {
                    WindVisualization(windSpeed: windSpeed)
                        .frame(width: 100, height: 100)
                        .position(x: geometry.size.width - 60, y: 60)
                }
                
                // Ball trajectory trail
                Canvas { context, size in
                    // Draw trail with gradient
                    if trailPoints.count > 1 {
                        var path = Path()
                        path.move(to: scalePoint(trailPoints[0], in: size))
                        
                        for i in 1..<min(Int(Double(trailPoints.count) * animationProgress), trailPoints.count) {
                            path.addLine(to: scalePoint(trailPoints[i], in: size))
                        }
                        
                        context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.8),
                                    Color.yellow.opacity(0.6)
                                ]),
                                startPoint: .zero,
                                endPoint: CGPoint(x: size.width, y: 0)
                            ),
                            style: StrokeStyle(
                                lineWidth: 2,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [5, 3]
                            )
                        )
                    }
                    
                    // Draw distance markers
                    for distance in stride(from: 50, to: 300, by: 50) {
                        let x = CGFloat(distance) * 2
                        let y = size.height * 0.8
                        
                        context.draw(
                            Text("\(distance)y")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7)),
                            at: CGPoint(x: x, y: y + 20)
                        )
                    }
                }
                
                // Golf ball
                if animationProgress > 0 && animationProgress <= 1 {
                    let index = Int(Double(trailPoints.count - 1) * animationProgress)
                    if index < trailPoints.count {
                        GolfBallView()
                            .frame(width: 20, height: 20)
                            .position(scalePoint(trailPoints[index], in: geometry.size))
                            .shadow(radius: 3)
                    }
                }
                
                // Club selection and controls
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Club selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(clubs, id: \.name) { club in
                                    ClubButton(
                                        name: club.name,
                                        isSelected: selectedClub == club.name
                                    ) {
                                        selectedClub = club.name
                                        launchBall()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Wind control
                        HStack {
                            Text("Wind:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Slider(value: $windSpeed.x, in: -20...20)
                                .frame(width: 150)
                                .accentColor(.white)
                            
                            Text("\(Int(windSpeed.x)) mph")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 50)
                            
                            Toggle("", isOn: $showWindEffect)
                                .labelsHidden()
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(15)
                        
                        // Launch button
                        Button(action: launchBall) {
                            HStack {
                                Image(systemName: "sportscourt")
                                Text("Launch Ball")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            launchBall()
        }
    }
    
    func scalePoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * 2 + 50,
            y: size.height * 0.8 - point.y * 2
        )
    }
    
    func launchBall() {
        let clubData = selectedClubData
        let launch = BallPhysicsEngine.LaunchParameters(
            velocity: clubData.velocity,
            angle: clubData.angle,
            spin: clubData.spin,
            windSpeed: windSpeed,
            elevation: 0
        )
        
        trailPoints = BallPhysicsEngine.calculateTrajectory(launch: launch)
        animationProgress = 0
        
        withAnimation(.easeOut(duration: 3)) {
            animationProgress = 1
        }
    }
}

// MARK: - Golf Ball View
struct GolfBallView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color.gray.opacity(0.3)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 10
                    )
                )
            
            // Dimples pattern
            ForEach(0..<6) { i in
                ForEach(0..<6) { j in
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 2, height: 2)
                        .offset(
                            x: CGFloat(i - 3) * 3,
                            y: CGFloat(j - 3) * 3
                        )
                }
            }
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 1, y: 1, z: 0)
        )
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Wind Visualization
struct WindVisualization: View {
    let windSpeed: BallPhysicsEngine.Vector2D
    @State private var animationOffset: CGFloat = 0
    
    var windDirection: Double {
        atan2(windSpeed.y, windSpeed.x) * 180 / .pi
    }
    
    var windStrength: Double {
        windSpeed.magnitude()
    }
    
    var body: some View {
        ZStack {
            // Wind direction arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .rotationEffect(.degrees(windDirection))
                .scaleEffect(1 + windStrength / 40)
            
            // Wind particles
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .offset(x: animationOffset + CGFloat(index * 10))
                    .rotationEffect(.degrees(windDirection))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationOffset = 50
            }
        }
    }
}

// MARK: - Club Button
struct ClubButton: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: "figure.golf")
                    .font(.system(size: 24))
                
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green : Color.white.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Particle System for Achievements
struct AchievementParticleSystem: View {
    @State private var particles: [Particle] = []
    let achievement: String
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
        var color: Color
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: particleIcon(for: achievement))
                    .font(.system(size: 20))
                    .foregroundColor(particle.color)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .position(particle.position)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    func particleIcon(for achievement: String) -> String {
        switch achievement {
        case "birdie": return "star.fill"
        case "eagle": return "star.circle.fill"
        case "albatross": return "crown.fill"
        case "ace": return "flag.fill"
        default: return "sparkle"
        }
    }
    
    func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(x: 200, y: 200),
                velocity: CGVector(
                    dx: Double.random(in: -100...100),
                    dy: Double.random(in: -150...(-50))
                ),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0,
                rotation: Double.random(in: 0...360),
                color: achievementColor()
            )
        }
    }
    
    func achievementColor() -> Color {
        switch achievement {
        case "birdie": return .yellow
        case "eagle": return .orange
        case "albatross": return .purple
        case "ace": return .red
        default: return .blue
        }
    }
    
    func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in particles.indices {
                // Update position
                particles[i].position.x += particles[i].velocity.dx * 0.016
                particles[i].position.y += particles[i].velocity.dy * 0.016
                
                // Apply gravity
                particles[i].velocity.dy += 200 * 0.016
                
                // Update rotation
                particles[i].rotation += 5
                
                // Fade out
                particles[i].opacity = max(0, particles[i].opacity - 0.016)
                
                // Scale down
                particles[i].scale = max(0, particles[i].scale - 0.01)
            }
            
            // Remove dead particles
            particles = particles.filter { $0.opacity > 0 }
            
            // Stop timer when all particles are gone
            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
}

// MARK: - 3D Card Flip for Format Selection
struct FlippableFormatCard: View {
    let format: GolfFormat
    @State private var flipped = false
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Front of card
            FormatCardFront(format: format)
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // Back of card
            FormatCardBack(format: format)
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotation + 180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                rotation += 180
                flipped.toggle()
            }
        }
    }
}

struct FormatCardFront: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: formatIcon(format.name))
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text(format.name)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(format.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
        }
        .padding()
        .frame(width: 160, height: 200)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

struct FormatCardBack: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Quick Rules")
                .font(.headline)
                .foregroundColor(.white)
            
            Divider()
                .background(Color.white.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 8) {
                Label(format.players, systemImage: "person.2")
                Label(format.difficulty, systemImage: "speedometer")
                Label(format.type, systemImage: "flag")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Text("Tap to flip back")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .frame(width: 160, height: 200)
        .background(
            LinearGradient(
                colors: [Color.green, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

func formatIcon(_ name: String) -> String {
    switch name {
    case "Scramble": return "arrow.triangle.merge"
    case "Best Ball": return "star.circle"
    case "Match Play": return "person.2.circle"
    case "Skins": return "dollarsign.circle"
    case "Stableford": return "chart.line.uptrend.xyaxis"
    case "Four-Ball": return "circle.grid.2x2"
    case "Alternate Shot": return "arrow.left.arrow.right"
    case "Nassau": return "divide.circle"
    case "Bingo Bango Bongo": return "target"
    case "Wolf": return "pawprint"
    case "Chapman": return "arrow.triangle.branch"
    case "Vegas": return "die.face.6"
    default: return "flag"
    }
}