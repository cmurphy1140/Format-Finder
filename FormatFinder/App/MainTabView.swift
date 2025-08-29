import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState.shared
    @State private var showingProfile = false
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Home Tab
            NavigationStack(path: $appState.navigationPath) {
                HomeView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Formats Tab
            NavigationStack {
                FormatsListView()
            }
            .tabItem {
                Label("Formats", systemImage: "list.bullet.rectangle")
            }
            .tag(1)
            
            // Play Tab
            NavigationStack {
                if let session = appState.activeGameSession {
                    ActiveGameView(session: session)
                } else {
                    QuickStartView()
                }
            }
            .tabItem {
                Label("Play", systemImage: "play.circle.fill")
            }
            .tag(2)
            
            // Stats Tab
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(3)
            
            // Settings Tab
            NavigationStack {
                SettingsMainView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .environmentObject(appState)
        .accentColor(Color.green)
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .alert("Error", isPresented: $appState.showError) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred")
        }
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
            if let achievement = notification.object as? Achievement {
                showAchievementCelebration(achievement)
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .formatDetail(let format):
            FormatDetailView(format: format)
        case .gameSetup(let format):
            GameSetupView(format: format)
        case .gamePlay(let session):
            ActiveGameView(session: session)
        case .gameResults(let session):
            GameResultsView(session: session)
        case .statistics:
            StatisticsView()
        case .settings:
            SettingsMainView()
        case .profile:
            ProfileView()
        }
    }
    
    private func showAchievementCelebration(_ achievement: Achievement) {
        // Trigger celebration animation
        appState.hapticManager.notification(type: .success)
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                WelcomeHeaderView()
                
                // Quick Actions
                QuickActionsSection()
                
                // Recent Formats
                if !appState.recentFormats.isEmpty {
                    RecentFormatsSection()
                }
                
                // Active Games
                if !appState.activeSessions.isEmpty {
                    ActiveGamesSection()
                }
                
                // Popular Formats
                PopularFormatsSection()
                
                // Stats Summary
                if appState.playerStats != nil {
                    QuickStatsSection()
                }
            }
            .padding()
        }
        .navigationTitle("Format Finder")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText)
        .refreshable {
            await appState.loadInitialData()
        }
    }
}

// MARK: - Welcome Header
struct WelcomeHeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title2)
                .foregroundColor(.secondary)
            
            if let user = appState.currentUser {
                Text("Welcome back, \(user.name)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } else {
                Text("Welcome to Format Finder")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            if let session = appState.activeGameSession {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.green)
                    Text("Playing \(session.format.name) - Hole \(session.currentHole)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                title: "New Game",
                icon: "plus.circle.fill",
                color: .green
            ) {
                appState.selectedTab = 2
            }
            
            QuickActionButton(
                title: "Resume",
                icon: "play.fill",
                color: .blue
            ) {
                if appState.activeGameSession != nil {
                    appState.selectedTab = 2
                }
            }
            .disabled(appState.activeGameSession == nil)
            
            QuickActionButton(
                title: "Stats",
                icon: "chart.bar.fill",
                color: .purple
            ) {
                appState.selectedTab = 3
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Recent Formats Section
struct RecentFormatsSection: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Formats")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appState.recentFormats) { format in
                        RecentFormatCard(format: format)
                            .onTapGesture {
                                appState.navigateToFormat(format)
                            }
                    }
                }
            }
        }
    }
}

struct RecentFormatCard: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: format.icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(format.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(format.playerRange)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(width: 120, height: 120)
        .background(
            LinearGradient(
                colors: [Color.green, Color.green.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Active Games Section
struct ActiveGamesSection: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Games")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to active games
                }
                .font(.caption)
            }
            
            ForEach(appState.activeSessions.prefix(2)) { session in
                ActiveGameCard(session: session)
                    .onTapGesture {
                        appState.activeGameSession = session
                        appState.selectedTab = 2
                    }
            }
        }
    }
}

struct ActiveGameCard: View {
    let session: GameSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.format.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Hole \(session.currentHole) of 18")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(session.players.prefix(3)) { player in
                        Circle()
                            .fill(player.color.color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text(String(player.name.prefix(1)))
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    if session.players.count > 3 {
                        Text("+\(session.players.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Popular Formats Section
struct PopularFormatsSection: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Popular Formats")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    appState.selectedTab = 1
                }
                .font(.caption)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(appState.availableFormats.prefix(4)) { format in
                    PopularFormatCard(format: format)
                        .onTapGesture {
                            appState.navigateToFormat(format)
                        }
                }
            }
        }
    }
}

struct PopularFormatCard: View {
    let format: GolfFormat
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: format.icon)
                    .font(.title3)
                
                Spacer()
                
                Button(action: {
                    appState.toggleFavoriteFormat(format)
                }) {
                    Image(systemName: appState.favoriteFormats.contains(format.id) ? "heart.fill" : "heart")
                        .foregroundColor(appState.favoriteFormats.contains(format.id) ? .red : .gray)
                }
            }
            
            Text(format.name)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(format.difficulty)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(difficultyColor(format.difficulty).opacity(0.2))
                .foregroundColor(difficultyColor(format.difficulty))
                .cornerRadius(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
}

// MARK: - Quick Stats Section
struct QuickStatsSection: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Rounds",
                    value: "\(appState.playerStats?.roundsPlayed ?? 0)",
                    icon: "flag.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Avg Score",
                    value: String(format: "%.1f", appState.playerStats?.scoringAverage ?? 0),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                StatCard(
                    title: "Best",
                    value: "\(appState.playerStats?.bestScore ?? 0)",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}