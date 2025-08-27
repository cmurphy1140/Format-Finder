import SwiftUI

// MARK: - Golf Theme Color Palette
struct GolfColors {
    // Primary Golf Course Colors
    static let fairwayGreen = Color(red: 34/255, green: 139/255, blue: 34/255)
    static let deepGreen = Color(red: 0/255, green: 100/255, blue: 0/255)
    static let limeGreen = Color(red: 124/255, green: 252/255, blue: 0/255)
    static let grassGreen = Color(red: 86/255, green: 125/255, blue: 70/255)
    
    // Sand & Earth Tones
    static let bunkerSand = Color(red: 238/255, green: 203/255, blue: 173/255)
    static let goldenSand = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let earthBrown = Color(red: 139/255, green: 90/255, blue: 43/255)
    
    // Sky & Water Colors
    static let skyBlue = Color(red: 135/255, green: 206/255, blue: 235/255)
    static let waterBlue = Color(red: 70/255, green: 130/255, blue: 180/255)
    static let morningMist = Color(red: 230/255, green: 240/255, blue: 250/255)
    
    // Accent Colors
    static let flagRed = Color(red: 220/255, green: 20/255, blue: 60/255)
    static let trophyGold = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let scorecardWhite = Color(red: 250/255, green: 250/255, blue: 250/255)
    
    // Gradient Definitions
    static let fairwayGradient = LinearGradient(
        colors: [deepGreen, fairwayGreen, grassGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let morningGradient = LinearGradient(
        colors: [skyBlue, morningMist, fairwayGreen.opacity(0.3)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let sunsetGradient = LinearGradient(
        colors: [
            Color(red: 255/255, green: 94/255, blue: 77/255),
            Color(red: 255/255, green: 167/255, blue: 0/255),
            fairwayGreen.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Custom SVG Golf Shapes
struct GolfBallShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Main circle
        path.addArc(center: center, radius: radius,
                   startAngle: .degrees(0), endAngle: .degrees(360),
                   clockwise: false)
        
        // Dimple pattern
        let dimpleSize: CGFloat = radius * 0.15
        let rows = 5
        let cols = 5
        
        for row in 0..<rows {
            for col in 0..<cols {
                let x = center.x + (CGFloat(col - 2) * dimpleSize * 1.5)
                let y = center.y + (CGFloat(row - 2) * dimpleSize * 1.5)
                
                if sqrt(pow(x - center.x, 2) + pow(y - center.y, 2)) < radius * 0.8 {
                    path.move(to: CGPoint(x: x + dimpleSize/2, y: y))
                    path.addArc(center: CGPoint(x: x, y: y),
                              radius: dimpleSize/2,
                              startAngle: .degrees(0),
                              endAngle: .degrees(360),
                              clockwise: false)
                }
            }
        }
        
        return path
    }
}

struct GolfFlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Flag pole
        path.move(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.9))
        path.addLine(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.1))
        
        // Flag
        path.move(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.4))
        path.closeSubpath()
        
        return path
    }
}

struct GolfClubShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Shaft
        path.move(to: CGPoint(x: rect.width * 0.2, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.2))
        
        // Grip
        path.move(to: CGPoint(x: rect.width * 0.55, y: rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.15))
        
        // Club head
        path.move(to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.75))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.85),
            control: CGPoint(x: rect.width * 0.2, y: rect.height * 0.85)
        )
        path.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.75))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.1, y: rect.height * 0.75),
            control: CGPoint(x: rect.width * 0.15, y: rect.height * 0.72)
        )
        
        return path
    }
}

struct GolfTeeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = rect.width / 2
        
        // Tee top
        path.addEllipse(in: CGRect(
            x: center - rect.width * 0.15,
            y: rect.height * 0.2,
            width: rect.width * 0.3,
            height: rect.height * 0.1
        ))
        
        // Tee stem
        path.move(to: CGPoint(x: center - rect.width * 0.05, y: rect.height * 0.25))
        path.addLine(to: CGPoint(x: center - rect.width * 0.02, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: center + rect.width * 0.02, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: center + rect.width * 0.05, y: rect.height * 0.25))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Animated Golf Components
struct AnimatedGolfBall: View {
    @State private var rotation: Double = 0
    @State private var bounce: Bool = false
    
    var body: some View {
        GolfBallShape()
            .fill(Color.white)
            .frame(width: 40, height: 40)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 1, y: 1, z: 0)
            )
            .offset(y: bounce ? -10 : 0)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }
    }
}

struct SwingingGolfClub: View {
    @State private var swingAngle: Double = 0
    
    var body: some View {
        GolfClubShape()
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .foregroundColor(.brown)
            .frame(width: 60, height: 60)
            .rotationEffect(.degrees(swingAngle), anchor: .bottomLeading)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    swingAngle = -70
                }
            }
    }
}

struct WavingFlag: View {
    @State private var wave: CGFloat = 0
    
    var body: some View {
        GolfFlagShape()
            .fill(GolfColors.flagRed)
            .frame(width: 50, height: 50)
            .modifier(WaveEffect(wave: wave))
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    wave = 1
                }
            }
    }
}

struct WaveEffect: GeometryEffect {
    var wave: CGFloat
    
    var animatableData: CGFloat {
        get { wave }
        set { wave = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let angle = sin(wave * .pi * 2) * 0.1
        return ProjectionTransform(
            CGAffineTransform(rotationAngle: angle)
                .concatenating(CGAffineTransform(translationX: sin(wave * .pi * 2) * 5, y: 0))
        )
    }
}

// MARK: - Particle Effects
struct GrassParticle: View {
    let size: CGFloat
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1
    
    var body: some View {
        Circle()
            .fill(GolfColors.fairwayGreen)
            .frame(width: size, height: size)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 2...4))) {
                    offset = CGSize(
                        width: CGFloat.random(in: -50...50),
                        height: CGFloat.random(in: (-200)...(-100))
                    )
                    opacity = 0
                }
            }
    }
}

struct GolfCourseBackground: View {
    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [
                    GolfColors.skyBlue,
                    GolfColors.morningMist,
                    GolfColors.fairwayGreen.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Fairway pattern
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.6))
                    path.addQuadCurve(
                        to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.7),
                        control: CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.5)
                    )
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(GolfColors.fairwayGradient)
                
                // Sand bunkers
                Circle()
                    .fill(GolfColors.bunkerSand)
                    .frame(width: 60, height: 40)
                    .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.75)
                
                Circle()
                    .fill(GolfColors.bunkerSand)
                    .frame(width: 45, height: 35)
                    .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.8)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Enhanced Loading Screen
struct GolfLoadingScreen: View {
    @State private var ballPosition: CGFloat = 0
    @State private var showText = false
    @State private var grassParticles: [UUID] = []
    @State private var clubRotation: Double = -45
    @State private var fadeOut = false
    
    var body: some View {
        ZStack {
            // Animated background
            GolfCourseBackground()
            
            // Grass particles
            ForEach(grassParticles, id: \.self) { _ in
                GrassParticle(size: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 400...600)
                    )
            }
            
            VStack(spacing: 40) {
                // Animated golf club and ball
                ZStack {
                    // Golf Club
                    Image(systemName: "figure.golf")
                        .font(.system(size: 80))
                        .foregroundColor(GolfColors.deepGreen)
                        .rotationEffect(.degrees(clubRotation))
                        .offset(x: -30, y: -20)
                    
                    // Golf Ball trajectory
                    Path { path in
                        path.move(to: CGPoint(x: 50, y: 100))
                        path.addQuadCurve(
                            to: CGPoint(x: 300, y: 100),
                            control: CGPoint(x: 175, y: -50)
                        )
                    }
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .foregroundColor(GolfColors.grassGreen.opacity(0.5))
                    
                    // Moving golf ball
                    AnimatedGolfBall()
                        .offset(x: ballPosition - 175, y: -50 + abs(sin(ballPosition * 0.02)) * 100)
                }
                .frame(height: 150)
                
                // App Title with animation
                VStack(spacing: 10) {
                    Text("FORMAT")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(GolfColors.fairwayGradient)
                        .shadow(color: GolfColors.deepGreen.opacity(0.3), radius: 4, x: 2, y: 2)
                    
                    Text("FINDER")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [GolfColors.trophyGold, GolfColors.goldenSand],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: GolfColors.goldenSand.opacity(0.3), radius: 4, x: 2, y: 2)
                }
                .scaleEffect(showText ? 1 : 0.5)
                .opacity(showText ? 1 : 0)
                
                // Loading indicator
                HStack(spacing: 15) {
                    ForEach(0..<3) { index in
                        GolfTeeShape()
                            .fill(GolfColors.earthBrown)
                            .frame(width: 20, height: 30)
                            .scaleEffect(showText ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1),
                                value: showText
                            )
                    }
                }
                
                // Tagline
                Text("Your Perfect Golf Game Awaits")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(GolfColors.scorecardWhite)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(GolfColors.fairwayGreen.opacity(0.8))
                    )
                    .opacity(showText ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.5), value: showText)
            }
            .opacity(fadeOut ? 0 : 1)
        }
        .onAppear {
            // Ball animation
            withAnimation(.easeInOut(duration: 2)) {
                ballPosition = 250
            }
            
            // Club swing
            withAnimation(.easeIn(duration: 0.3)) {
                clubRotation = 45
            }
            
            // Show text after ball animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    showText = true
                }
            }
            
            // Generate grass particles
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
                if grassParticles.count < 10 {
                    grassParticles.append(UUID())
                } else {
                    timer.invalidate()
                }
            }
            
            // Fade out after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    fadeOut = true
                }
            }
        }
    }
}

// MARK: - Dynamic UI Elements
struct GolfCardView: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    @State private var isPressed = false
    @State private var showRipple = false
    
    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.8),
                            color.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Ripple effect
            if showRipple {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .scaleEffect(showRipple ? 2 : 0)
                    .opacity(showRipple ? 0 : 1)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isPressed ? 10 : 0))
                    
                    Spacer()
                    
                    GolfBallShape()
                        .fill(Color.white)
                        .frame(width: 25, height: 25)
                        .opacity(0.8)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .padding()
        }
        .frame(height: 140)
        .scaleEffect(isPressed ? 0.95 : 1)
        .shadow(
            color: color.opacity(0.4),
            radius: isPressed ? 5 : 10,
            x: 0,
            y: isPressed ? 2 : 5
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isPressed.toggle()
                showRipple = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isPressed = false
                showRipple = false
            }
        }
    }
}

// MARK: - Floating Action Button
struct GolfFloatingButton: View {
    let icon: String
    let action: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                isAnimating.toggle()
            }
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }) {
            ZStack {
                Circle()
                    .fill(GolfColors.fairwayGradient)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            .scaleEffect(isAnimating ? 1.2 : 1)
            .shadow(
                color: GolfColors.deepGreen.opacity(0.4),
                radius: isAnimating ? 15 : 10,
                x: 0,
                y: isAnimating ? 8 : 5
            )
        }
    }
}