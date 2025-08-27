import SwiftUI
import Foundation

@main
struct FormatFinderApp: App {
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainNavigationView()
                
                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
}

// MARK: - Main Navigation View

struct MainNavigationView: View {
    @State private var showGameModeSelector = false
    
    var body: some View {
        ZStack {
            ContentView(showGameModeSelector: $showGameModeSelector)
            
            if showGameModeSelector {
                GameModeSelectorView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(1)
            }
        }
    }
}

// MARK: - Launch Screen

struct LaunchScreenView: View {
    @State private var animateGolf = false
    @State private var animateText = false
    @State private var showLoadingDots = false
    @State private var loadingProgress: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Light background
            AppColors.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Golf icon animation with rotation
                ZStack {
                    // Animated background circles
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 180, height: 180)
                        .scaleEffect(animateGolf ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGolf)
                    
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateGolf ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.2), value: animateGolf)
                    
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateGolf ? 1.05 : 0.95)
                    
                    Image(systemName: "figure.golf")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .scaleEffect(animateGolf ? 1 : 0.6)
                        .rotationEffect(.degrees(rotationAngle))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                // App name with staggered animation
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        ForEach(Array("Format".enumerated()), id: \.offset) { index, letter in
                            Text(String(letter))
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .scaleEffect(animateText ? 1 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.1), value: animateText)
                        }
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(Array("Finder".enumerated()), id: \.offset) { index, letter in
                            Text(String(letter))
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .scaleEffect(animateText ? 1 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index + 6) * 0.1), value: animateText)
                        }
                    }
                    
                    Text("Golf Game Companion")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(animateText ? 1 : 0)
                        .animation(.easeIn(duration: 0.8).delay(1.2), value: animateText)
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 15) {
                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 250, height: 6)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 250 * loadingProgress, height: 6)
                    }
                    
                    // Loading text with dots
                    HStack(spacing: 4) {
                        Text("Loading")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { index in
                                Text(".")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                                    .opacity(showLoadingDots ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: showLoadingDots)
                            }
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1)) {
                animateGolf = true
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                animateText = true
            }
            
            withAnimation {
                showLoadingDots = true
            }
            
            // Simulate loading progress
            withAnimation(.easeInOut(duration: 3)) {
                loadingProgress = 1
            }
            
            // Rotate the golf icon
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Content View with Tab Navigation

struct ContentView: View {
    @State private var selectedTab = 0
    @Binding var showGameModeSelector: Bool
    @StateObject private var gameStore = GameStore()
    @StateObject private var themeEngine = ThemeEngine()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            FormatsView(showGameModeSelector: $showGameModeSelector)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Formats")
                }
                .tag(1)
            
            ScoreView()
                .tabItem {
                    Image(systemName: "pencil.circle.fill")
                    Text("Score")
                }
                .tag(2)
            
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Stats")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(AppColors.primaryGreen)
        .environmentObject(gameStore)
        .environmentObject(themeEngine)
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var animateIn = false
    @State private var selectedQuickAction: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppColors.backgroundPrimary,
                        AppColors.backgroundSecondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Welcome Card
                        WelcomeCard()
                            .offset(y: animateIn ? 0 : -30)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateIn)
                        
                        // Quick Actions
                        QuickActionsSection(selectedQuickAction: $selectedQuickAction)
                            .offset(y: animateIn ? 0 : 30)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateIn)
                        
                        // Recent Games
                        RecentGamesSection()
                            .offset(y: animateIn ? 0 : 30)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateIn)
                        
                        // Tips Section
                        TipsSection()
                            .offset(y: animateIn ? 0 : 30)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateIn)
                    }
                    .padding()
                }
                .navigationTitle("Format Finder")
                .navigationBarTitleDisplayMode(.large)
            }
            .onAppear {
                withAnimation {
                    animateIn = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct WelcomeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back!")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("Ready for your next round?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            
            Divider()
            
            HStack {
                StatisticItem(title: "Rounds", value: "12", icon: "flag.fill", color: .blue)
                Spacer()
                StatisticItem(title: "Best Score", value: "72", icon: "star.fill", color: .yellow)
                Spacer()
                StatisticItem(title: "Handicap", value: "8.2", icon: "chart.line.uptrend.xyaxis", color: .green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickActionsSection: View {
    @Binding var selectedQuickAction: String?
    
    let actions = [
        ("New Game", "plus.circle.fill", Color.green),
        ("Practice", "target", Color.orange),
        ("Tournament", "trophy.fill", Color.purple),
        ("Stats", "chart.bar.xaxis", Color.blue)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(actions, id: \.0) { action in
                    QuickActionCard(
                        title: action.0,
                        icon: action.1,
                        color: action.2,
                        isSelected: selectedQuickAction == action.0
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedQuickAction = selectedQuickAction == action.0 ? nil : action.0
                        }
                    }
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(isSelected ? .white : color)
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isSelected ? color : Color.white)
                .shadow(color: isSelected ? color.opacity(0.3) : .black.opacity(0.1),
                       radius: isSelected ? 8 : 5,
                       x: 0,
                       y: isSelected ? 4 : 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1)
    }
}

struct RecentGamesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Games")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("See All") {
                    // Action
                }
                .font(.subheadline)
                .foregroundColor(AppColors.primaryGreen)
            }
            
            VStack(spacing: 12) {
                RecentGameRow(format: "Scramble", date: "Today", score: "68")
                RecentGameRow(format: "Match Play", date: "Yesterday", score: "Won 3&2")
                RecentGameRow(format: "Skins", date: "Dec 20", score: "4 Skins")
            }
        }
    }
}

struct RecentGameRow: View {
    let format: String
    let date: String
    let score: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(format)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(score)
                .font(.subheadline.bold())
                .foregroundColor(AppColors.primaryGreen)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
}

struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Tip")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    Text("Scramble Strategy")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                Text("In a scramble, let your longest hitter tee off last. This allows them to take more risks knowing the team already has safe shots in play.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.yellow.opacity(0.1),
                            Color.orange.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
        }
    }
}

// MARK: - Stub Views for Other Tabs

struct FormatsView: View {
    @Binding var showGameModeSelector: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Game Formats")
                    .font(.largeTitle)
                    .padding()
                
                Button("Open Game Mode Selector") {
                    showGameModeSelector = true
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Game Formats")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ScoreView: View {
    var body: some View {
        NavigationView {
            ModernScorecardView()
                .navigationTitle("Scorecard")
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Statistics Dashboard")
                    .font(.largeTitle)
                    .padding()
                
                Text("View your game statistics here")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Statistics")
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