import SwiftUI
import Foundation

@main
struct FormatFinderApp: App {
    @State private var showLaunchScreen = true
    @StateObject private var gameStore = GameStore()
    @StateObject private var themeEngine = ThemeEngine()
    @StateObject private var timeEnvironmentService = TimeEnvironmentService.shared
    @StateObject private var physicsEngine = PhysicsSimulationEngine.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainNavigationView()
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
                EnhancedFormatsGrid()
                    .tabItem {
                        Image(systemName: "square.grid.3x3.fill")
                        Text("Formats")
                    }
                    .tag(0)
                
                PlayView()
                    .tabItem {
                        Image(systemName: "play.circle.fill")
                        Text("Play")
                    }
                    .tag(1)
                
                StatsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Stats")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Profile")
                    }
                    .tag(3)
            }
            .accentColor(AppColors.primaryGreen)
            
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

// MARK: - Enhanced Launch Screen with Green Theme

struct EnhancedLaunchScreen: View {
    @State private var animateGolf = false
    @State private var animateText = false
    @State private var animateBall = false
    @State private var loadingProgress: CGFloat = 0
    @State private var ballPosition = CGPoint(x: -100, y: 200)
    @StateObject private var physicsEngine = PhysicsSimulationEngine.shared
    
    var body: some View {
        ZStack {
            // Golf course green gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.fairwayGreen,
                    AppColors.primaryGreen,
                    AppColors.darkGreen
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated grass particles
            ForEach(0..<20, id: \.self) { index in
                LaunchGrassParticle()
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(0.3)
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animateGolf
                    )
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated golf ball with physics
                ZStack {
                    // Golf hole
                    Circle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    // Flag pole
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 100)
                        .offset(y: -50)
                    
                    // Flag
                    Path { path in
                        path.move(to: CGPoint(x: 2, y: -100))
                        path.addLine(to: CGPoint(x: 40, y: -80))
                        path.addLine(to: CGPoint(x: 2, y: -60))
                        path.closeSubpath()
                    }
                    .fill(Color.red)
                    
                    // Animated golf ball
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 10, height: 10)
                                .offset(x: -3, y: -3)
                        )
                        .position(ballPosition)
                        .onAppear {
                            // Simulate ball rolling into hole
                            withAnimation(.interpolatingSpring(stiffness: 50, damping: 5).delay(0.5)) {
                                ballPosition = CGPoint(x: 0, y: 0)
                            }
                        }
                }
                .frame(width: 200, height: 200)
                .scaleEffect(animateGolf ? 1 : 0.5)
                .rotation3DEffect(
                    .degrees(animateGolf ? 0 : 180),
                    axis: (x: 0, y: 1, z: 0)
                )
                
                // App title with green theme
                VStack(spacing: 8) {
                    Text("FORMAT")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: AppColors.darkGreen, radius: 10, x: 0, y: 5)
                        .scaleEffect(animateText ? 1 : 0)
                        .opacity(animateText ? 1 : 0)
                    
                    Text("FINDER")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.brightGreen)
                        .shadow(color: AppColors.darkGreen, radius: 10, x: 0, y: 5)
                        .scaleEffect(animateText ? 1 : 0)
                        .opacity(animateText ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: animateText)
                    
                    Text("Master Every Golf Format")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(animateText ? 1 : 0)
                        .animation(.easeOut.delay(0.5), value: animateText)
                }
                
                Spacer()
                
                // Loading bar
                VStack(spacing: 20) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 250, height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.brightGreen)
                            .frame(width: 250 * loadingProgress, height: 8)
                    }
                    
                    Text("Loading golf formats...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            animateGolf = true
            
            withAnimation(.easeOut(duration: 0.8)) {
                animateText = true
            }
            
            withAnimation(.linear(duration: 3)) {
                loadingProgress = 1
            }
        }
    }
}

// MARK: - Format Hub View (Main Screen)

struct FormatHubView: View {
    @Binding var showGameModeSelector: Bool
    @State private var selectedCategory = "All"
    @State private var animateIn = false
    @EnvironmentObject var physicsEngine: PhysicsSimulationEngine
    @EnvironmentObject var timeEnvironmentService: TimeEnvironmentService
    
    let categories = ["All", "Tournament", "Betting", "Team", "Individual"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.fairwayGreen.opacity(0.3),
                        AppColors.backgroundPrimary
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 20) {
                        Text("Choose Your Format")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.darkGreen)
                        
                        // Category selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(categories, id: \.self) { category in
                                    CategoryChip(
                                        title: category,
                                        isSelected: selectedCategory == category,
                                        action: {
                                            withAnimation(.spring()) {
                                                selectedCategory = category
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(AppRoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                    .shadow(color: AppColors.cardShadow, radius: 10, x: 0, y: 5)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Quick Start Button
                            QuickStartCard(action: { showGameModeSelector = true })
                                .offset(y: animateIn ? 0 : 30)
                                .opacity(animateIn ? 1 : 0)
                                .animation(.spring().delay(0.1), value: animateIn)
                            
                            // Popular Formats
                            PopularFormatsSection(
                                selectedCategory: selectedCategory,
                                onSelectFormat: { showGameModeSelector = true }
                            )
                            .offset(y: animateIn ? 0 : 30)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring().delay(0.2), value: animateIn)
                            
                            // Format Tips
                            FormatTipsCard()
                                .offset(y: animateIn ? 0 : 30)
                                .opacity(animateIn ? 1 : 0)
                                .animation(.spring().delay(0.3), value: animateIn)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation {
                    animateIn = true
                }
            }
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
                        AppColors.primaryGreen.opacity(0.9),
                        AppColors.darkGreen
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

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppColors.darkGreen)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppColors.primaryGreen : Color.white)
                        .shadow(color: isSelected ? AppColors.primaryGreen.opacity(0.3) : .clear, radius: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : AppColors.primaryGreen.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct QuickStartCard: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppColors.brightGreen)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Start")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.darkGreen)
                    
                    Text("Jump into a game with smart format selection")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primaryGreen)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, AppColors.lightGreen.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct PopularFormatsSection: View {
    let selectedCategory: String
    let onSelectFormat: () -> Void
    
    var filteredFormats: [GolfFormat] {
        if selectedCategory == "All" {
            return Array(golfFormats.prefix(6))
        } else if selectedCategory == "Team" {
            return golfFormats.filter { $0.type == "Team" }
        } else {
            return golfFormats.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Popular Formats")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.darkGreen)
            
            ForEach(filteredFormats.prefix(4)) { format in
                PopularFormatRow(format: format, action: onSelectFormat)
            }
        }
    }
}

struct PopularFormatRow: View {
    let format: GolfFormat
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.primaryGreen.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: getFormatIcon(format.name))
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primaryGreen)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 8) {
                        Label(format.players, systemImage: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        
                        DifficultyBadge(difficulty: format.difficulty)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: AppColors.cardShadow, radius: 4, x: 0, y: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
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
        default: return "flag.fill"
        }
    }
}

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
                                    [AppColors.primaryGreen.opacity(0.2), AppColors.primaryGreen.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: getFormatIcon(format.name))
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : AppColors.primaryGreen)
                        .rotationEffect(.degrees(isPressed ? 10 : 0))
                }
                
                Text(format.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppColors.darkGreen)
                    .lineLimit(1)
                
                Text(format.players)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppColors.textSecondary)
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
                                colors: [AppColors.primaryGreen, AppColors.darkGreen],
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
                        color: isSelected ? AppColors.primaryGreen.opacity(0.5) : AppColors.cardShadow,
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

struct FormatTipsCard: View {
    @State private var currentTip = 0
    let tips = [
        ("Scramble", "Perfect for mixed skill levels - everyone contributes!"),
        ("Match Play", "Focus on each hole, not total score"),
        ("Skins", "Ties carry over - pressure builds each hole!"),
        ("Stableford", "Rewards aggressive play - go for birdies!")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.brightGreen)
                
                Text("Format Tip")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.darkGreen)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(tips[currentTip].0)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryGreen)
                
                Text(tips[currentTip].1)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.lightGreen.opacity(0.1),
                            AppColors.primaryGreen.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.primaryGreen.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                withAnimation {
                    currentTip = (currentTip + 1) % tips.count
                }
            }
        }
    }
}


struct LaunchGrassParticle: View {
    @State private var offset = CGSize.zero
    @State private var rotation = 0.0
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: CGFloat.random(in: 10...20)))
            .foregroundColor(AppColors.primaryGreen.opacity(Double.random(in: 0.3...0.6)))
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
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Statistics")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile Settings")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
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

