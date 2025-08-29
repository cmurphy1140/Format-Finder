import SwiftUI
import Foundation
import CoreData
import Combine

@main
struct FormatFinderApp: App {
    @State private var showLaunchScreen = true
    @StateObject private var appState = AppState.shared
    @StateObject private var gameStore = GameStore()
    @StateObject private var themeEngine = ThemeEngine()
    @StateObject private var timeEnvironmentService = TimeEnvironmentService.shared
    @StateObject private var physicsEngine = PhysicsSimulationEngine.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainNavigationView()
                    .environmentObject(appState)
                    .environmentObject(gameStore)
                    .environmentObject(themeEngine)
                    .environmentObject(timeEnvironmentService)
                    .environmentObject(physicsEngine)
                
                if showLaunchScreen {
                    EnhancedLaunchScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                startServices()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
    
    private func startServices() {
        // Start backend services
        Task {
            await timeEnvironmentService.startMonitoring()
            physicsEngine.startSimulation()
            AnimationOrchestrator.shared.start()
        }
    }
}

// MARK: - Main Navigation View

struct MainNavigationView: View {
    @State private var showGameModeSelector = false
    @State private var selectedTab = 0
    @EnvironmentObject var timeEnvironmentService: TimeEnvironmentService
    
    var body: some View {
        ZStack {
            // Dynamic background based on time of day
            timeBasedBackground
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                GolfFormatHomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                SwipeableFormatCards()
                    .tabItem {
                        Image(systemName: "square.grid.3x3.fill")
                        Text("Formats")
                    }
                    .tag(1)
                
                PlayView()
                    .tabItem {
                        Image(systemName: "play.circle.fill")
                        Text("Play")
                    }
                    .tag(2)
                
                StatsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Stats")
                    }
                    .tag(3)
            }
            .accentColor(MastersColors.mastersGreen)
            
            if showGameModeSelector {
                EnhancedGameModeSelector(showGameModeSelector: $showGameModeSelector)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(1)
            }
        }
    }
    
    var timeBasedBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: timeEnvironmentService.colorPalette.gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Masters-Inspired Professional Loading Screen

struct EnhancedLaunchScreen: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleSlideIn = false
    @State private var loadingProgress: CGFloat = 0
    @State private var loadingPhase = 0 // 0: initial, 1: loading, 2: completing
    @State private var progressShimmer = false
    @State private var statusText = "Initializing..."
    
    let loadingSteps = [
        "Initializing...",
        "Loading golf formats...", 
        "Preparing scorecard engine...",
        "Synchronizing analytics...",
        "Ready to play!"
    ]
    
    var body: some View {
        ZStack {
            // Masters-inspired gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    MastersColors.mastersGreen,
                    MastersColors.shadowGreen,
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle background pattern
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.02))
                    .frame(width: CGFloat.random(in: 40...120))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 8...15))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: titleSlideIn
                    )
            }
            
            VStack(spacing: 60) {
                Spacer()
                
                // Elegant golf club logo with Masters aesthetic
                ZStack {
                    // Outer glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    MastersColors.augustaGold.opacity(0.4),
                                    MastersColors.augustaGold.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .opacity(logoOpacity > 0.5 ? 1 : 0)
                    
                    // Main logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    MastersColors.azaleaWhite,
                                    MastersColors.magnoliaLane
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
                    
                    // Golf flag icon
                    VStack(spacing: 0) {
                        // Flag
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 30, y: 8))
                            path.addLine(to: CGPoint(x: 0, y: 16))
                            path.closeSubpath()
                        }
                        .fill(MastersColors.mastersGreen)
                        .frame(width: 30, height: 16)
                        
                        // Flag pole
                        Rectangle()
                            .fill(MastersColors.graphite)
                            .frame(width: 2, height: 60)
                    }
                    .rotationEffect(.degrees(logoScale > 0.8 ? 0 : 45))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App title with Masters typography
                VStack(spacing: 16) {
                    Text("FORMAT FINDER")
                        .font(MastersTypography.heroTitle())
                        .foregroundColor(MastersColors.azaleaWhite)
                        .tracking(2)
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                        .offset(x: titleSlideIn ? 0 : -50)
                        .opacity(titleSlideIn ? 1 : 0)
                    
                    Text("PROFESSIONAL GOLF COMPANION")
                        .font(MastersTypography.captionText())
                        .foregroundColor(MastersColors.augustaGold)
                        .tracking(1.5)
                        .offset(x: titleSlideIn ? 0 : 50)
                        .opacity(titleSlideIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.3), value: titleSlideIn)
                }
                
                Spacer()
                
                // Professional loading bar with Masters styling
                VStack(spacing: 24) {
                    // Progress container
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                        
                        // Progress bar with gradient and shimmer
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        MastersColors.augustaGold,
                                        MastersColors.eagleGold,
                                        MastersColors.augustaGold
                                    ],
                                    startPoint: progressShimmer ? .leading : .trailing,
                                    endPoint: progressShimmer ? .trailing : .leading
                                )
                            )
                            .frame(height: 6)
                            .scaleEffect(x: loadingProgress, y: 1, anchor: .leading)
                            .shadow(color: MastersColors.augustaGold.opacity(0.6), radius: 8, x: 0, y: 0)
                    }
                    .frame(maxWidth: 280)
                    
                    // Status text
                    Text(statusText)
                        .font(MastersTypography.bodyText())
                        .foregroundColor(MastersColors.magnoliaLane)
                        .opacity(0.9)
                        .animation(.easeInOut(duration: 0.3), value: statusText)
                }
                .padding(.bottom, 80)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startLoadingSequence()
        }
    }
    
    private func startLoadingSequence() {
        // Logo entrance animation
        withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title slide in
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            titleSlideIn = true
        }
        
        // Start shimmering effect
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                progressShimmer.toggle()
            }
        }
        
        // Loading progress simulation
        loadProgressSimulation()
    }
    
    private func loadProgressSimulation() {
        let totalDuration: Double = 3.5
        let steps = loadingSteps.count
        let stepDuration = totalDuration / Double(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                withAnimation(.easeInOut(duration: stepDuration * 0.8)) {
                    loadingProgress = CGFloat(i + 1) / CGFloat(steps)
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    statusText = loadingSteps[i]
                }
                
                // Add subtle haptic feedback for each step
                if i < steps - 1 {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
        }
        
        // Final completion haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - 0.2) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}


// MARK: - Enhanced Game Mode Selector

struct EnhancedGameModeSelector: View {
    @Binding var showGameModeSelector: Bool
    @State private var selectedFormat: GolfFormat? = nil
    @State private var showConfiguration = false
    @State private var gameConfiguration = GameConfiguration()
    @State private var showScorecard = false
    @StateObject private var gridSyncEngine = GridSyncEngine.shared
    @StateObject private var animationOrchestrator = AnimationOrchestrator.shared
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Green gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        MastersColors.mastersGreen.opacity(0.9),
                        MastersColors.shadowGreen
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Button(action: { showGameModeSelector = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Text("Select Format")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Placeholder for balance
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(golfFormats) { format in
                                EnhancedFormatCard(
                                    format: format,
                                    isSelected: selectedFormat?.id == format.id,
                                    action: {
                                        withHapticFeedback(.light)
                                        selectedFormat = format
                                        gameConfiguration.selectedFormat = format
                                        showConfiguration = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
            .sheet(isPresented: $showConfiguration) {
                GameConfigurationView(
                    configuration: $gameConfiguration,
                    onStart: {
                        showConfiguration = false
                        showScorecard = true
                    }
                )
            }
            .fullScreenCover(isPresented: $showScorecard) {
                if let format = gameConfiguration.selectedFormat {
                    EnhancedScorecardView(
                        format: format,
                        configuration: gameConfiguration
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Components


struct EnhancedFormatCard: View {
    let format: GolfFormat
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    @StateObject private var animationOrchestrator = AnimationOrchestrator.shared
    
    var body: some View {
        Button(action: {
            animationOrchestrator.triggerHaptic(.light)
            action()
        }) {
            VStack(spacing: 12) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? 
                                    [Color.white.opacity(0.3), Color.white.opacity(0.1)] :
                                    [MastersColors.mastersGreen.opacity(0.2), MastersColors.mastersGreen.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: getFormatIcon(format.name))
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : MastersColors.mastersGreen)
                        .rotationEffect(.degrees(isPressed ? 10 : 0))
                }
                
                Text(format.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : MastersColors.shadowGreen)
                    .lineLimit(1)
                
                Text(format.players)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : MastersColors.textSecondary)
                    .lineLimit(1)
                
                DifficultyBadge(difficulty: format.difficulty)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ? 
                            LinearGradient(
                                colors: [MastersColors.mastersGreen, MastersColors.shadowGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.95)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .shadow(
                        color: isSelected ? MastersColors.mastersGreen.opacity(0.5) : MastersColors.cardShadow,
                        radius: isSelected ? 10 : 6,
                        x: 0,
                        y: isSelected ? 5 : 3
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.white.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    func getFormatIcon(_ name: String) -> String {
        switch name {
        case "Scramble": return "arrow.triangle.merge"
        case "Best Ball": return "star.circle.fill"
        case "Match Play": return "person.2.square.stack"
        case "Skins": return "dollarsign.circle.fill"
        case "Stableford": return "chart.line.uptrend.xyaxis"
        case "Four-Ball": return "circle.grid.2x2.fill"
        case "Alternate Shot": return "arrow.left.arrow.right.circle"
        case "Nassau": return "divide.circle.fill"
        case "Bingo Bango Bongo": return "target"
        case "Wolf": return "hare.fill"
        case "Chapman": return "arrow.triangle.branch"
        case "Vegas": return "die.face.6.fill"
        default: return "flag.fill"
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: String
    
    var color: Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(difficulty)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
            )
    }
}



struct LaunchGrassParticle: View {
    @State private var offset = CGSize.zero
    @State private var rotation = 0.0
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: CGFloat.random(in: 10...20)))
            .foregroundColor(MastersColors.mastersGreen.opacity(Double.random(in: 0.3...0.6)))
            .rotationEffect(.degrees(rotation))
            .offset(offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 4...8))
                    .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -30...30),
                        height: CGFloat.random(in: -30...30)
                    )
                    rotation = Double.random(in: -45...45)
                }
            }
    }
}

// MARK: - Stub Views

struct PlayView: View {
    var body: some View {
        NavigationView {
            ModernScorecardView()
                .navigationTitle("Active Round")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatsView: View {
    @State private var roundsPlayed = 0
    @State private var avgScore = 0
    @State private var favoriteFormat = "Scramble"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Masters-inspired gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        MastersColors.fairwayMist,
                        MastersColors.azaleaWhite
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Header
                        VStack(spacing: 8) {
                            Text("Performance Analytics")
                                .font(MastersTypography.sectionHeader())
                                .foregroundColor(MastersColors.graphite)
                            
                            Text("Track your golf journey")
                                .font(MastersTypography.bodyText())
                                .foregroundColor(MastersColors.silver)
                        }
                        .padding(.top, 20)
                        
                        // Quick Stats Cards
                        HStack(spacing: 16) {
                            StatCard(title: "Rounds", value: "\(roundsPlayed)", icon: "flag.fill", color: MastersColors.mastersGreen)
                            StatCard(title: "Avg Score", value: "\(avgScore)", icon: "chart.line.uptrend.xyaxis", color: MastersColors.augustaGold)
                        }
                        .padding(.horizontal)
                        
                        // Favorite Format Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most Played Format")
                                .font(MastersTypography.dataLabel())
                                .foregroundColor(MastersColors.graphite)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(MastersColors.eagleGold)
                                
                                Text(favoriteFormat)
                                    .font(MastersTypography.cardTitle())
                                    .foregroundColor(MastersColors.mastersGreen)
                                
                                Spacer()
                            }
                            .padding()
                            .background(MastersColors.azaleaWhite)
                            .cornerRadius(MastersLayout.cardRadius)
                            .shadow(color: MastersLayout.cardShadow.color, radius: MastersLayout.cardShadow.radius)
                        }
                        .padding(.horizontal)
                        
                        // Coming Soon
                        VStack(spacing: 16) {
                            Text("Coming Soon")
                                .font(MastersTypography.dataLabel())
                                .foregroundColor(MastersColors.silver)
                            
                            Text("Detailed analytics, handicap tracking, and performance insights")
                                .font(MastersTypography.bodyText())
                                .foregroundColor(MastersColors.fog)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(MastersTypography.scoreDisplay())
                .foregroundColor(MastersColors.graphite)
            
            Text(title)
                .font(MastersTypography.captionText())
                .foregroundColor(MastersColors.silver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(MastersColors.azaleaWhite)
        .cornerRadius(MastersLayout.cardRadius)
        .shadow(color: MastersLayout.cardShadow.color, radius: MastersLayout.cardShadow.radius)
    }
}

// Helper function for haptic feedback
func withHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}

// Use the RoundedCorner shape that's already defined
struct AppRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

