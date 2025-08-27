import SwiftUI

@main
struct FormatFinderApp: App {
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MastersColors.magnoliaWhite
                    .ignoresSafeArea()
                
                MastersMainView()
                
                if showLaunchScreen {
                    MastersLaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                }
            }
            .preferredColorScheme(.light) // Masters app is always light
        }
    }
}

// MARK: - Masters Launch Screen
struct MastersLaunchScreenView: View {
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Masters green background
            MastersColors.augustaGreen
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Masters style logo
                ZStack {
                    Circle()
                        .fill(MastersColors.magnoliaWhite)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "flag.fill")
                        .font(.system(size: 60))
                        .foregroundColor(MastersColors.augustaGreen)
                }
                .opacity(logoOpacity)
                
                VStack(spacing: 8) {
                    Text("FORMAT FINDER")
                        .font(MastersTypography.largeTitle)
                        .foregroundColor(MastersColors.magnoliaWhite)
                        .tracking(3)
                    
                    Text("A Tradition Unlike Any Other")
                        .font(MastersTypography.subheadline)
                        .foregroundColor(MastersColors.magnoliaWhite.opacity(0.9))
                        .tracking(1.5)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textOpacity = 1
            }
        }
    }
}

// MARK: - Main Masters View
struct MastersMainView: View {
    @State private var selectedTab = 0
    @State private var savedFormats: [SavedFormat] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MastersHomeView()
                .tabItem {
                    MastersTabItem(
                        icon: "house.fill",
                        title: "HOME",
                        isSelected: selectedTab == 0
                    )
                }
                .tag(0)
            
            MastersFormatsView()
                .tabItem {
                    MastersTabItem(
                        icon: "list.bullet",
                        title: "FORMATS",
                        isSelected: selectedTab == 1
                    )
                }
                .tag(1)
            
            MastersScoreView()
                .tabItem {
                    MastersTabItem(
                        icon: "flag.fill",
                        title: "SCORE",
                        isSelected: selectedTab == 2
                    )
                }
                .tag(2)
            
            MastersStatsView()
                .tabItem {
                    MastersTabItem(
                        icon: "chart.bar.fill",
                        title: "STATS",
                        isSelected: selectedTab == 3
                    )
                }
                .tag(3)
        }
        .accentColor(MastersColors.augustaGreen)
    }
}

// MARK: - Masters Home View
struct MastersHomeView: View {
    @State private var currentHour = Calendar.current.component(.hour, from: Date())
    @State private var weatherTemp = "72°"
    @State private var isLoadingNews = true
    @State private var newsItems: [NewsItem] = []
    
    var greeting: String {
        if currentHour < 12 {
            return "Good Morning"
        } else if currentHour < 17 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header like Masters app
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(greeting)
                                .font(MastersTypography.title2)
                                .foregroundColor(MastersColors.textPrimary)
                            
                            Spacer()
                            
                            Text(weatherTemp)
                                .font(MastersTypography.body)
                                .foregroundColor(MastersColors.textSecondary)
                        }
                        
                        Text("Augusta National Golf Club")
                            .font(MastersTypography.subheadline)
                            .foregroundColor(MastersColors.textSecondary)
                    }
                    .padding()
                    .background(MastersColors.magnoliaWhite)
                    
                    Rectangle()
                        .fill(MastersColors.divider)
                        .frame(height: 1)
                    
                    // Quick Actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                        MastersQuickAction(
                            icon: "play.circle.fill",
                            title: "Quick Game",
                            color: MastersColors.augustaGreen
                        )
                        
                        MastersQuickAction(
                            icon: "book.fill",
                            title: "Learn Formats",
                            color: MastersColors.fairwayGreen
                        )
                        
                        MastersQuickAction(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "View Stats",
                            color: MastersColors.darkGreen
                        )
                        
                        MastersQuickAction(
                            icon: "person.2.fill",
                            title: "Tournaments",
                            color: MastersColors.lightGreen
                        )
                    }
                    
                    Rectangle()
                        .fill(MastersColors.divider)
                        .frame(height: 1)
                    
                    // News/Updates section with skeleton loading
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TODAY'S FORMATS")
                            .font(MastersTypography.headline)
                            .foregroundColor(MastersColors.textPrimary)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if isLoadingNews {
                            ForEach(0..<3) { _ in
                                MastersNewsSkeletonRow()
                            }
                        } else if newsItems.isEmpty {
                            MastersEmptyState(
                                icon: "newspaper.fill",
                                title: "No Updates",
                                message: "Check back later for format recommendations and tips",
                                actionTitle: "Refresh",
                                action: { loadNews() }
                            )
                            .frame(height: 200)
                        } else {
                            ForEach(newsItems) { item in
                                MastersNewsRow(item: item)
                            }
                        }
                    }
                }
            }
            .background(MastersColors.sandBunker.opacity(0.3))
            .navigationBarHidden(true)
            .onAppear { loadNews() }
        }
    }
    
    func loadNews() {
        isLoadingNews = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newsItems = [
                NewsItem(title: "Scramble Format", subtitle: "Perfect for today's conditions", icon: "flag.fill"),
                NewsItem(title: "Best Ball Strategy", subtitle: "Tips from the pros", icon: "star.fill"),
                NewsItem(title: "Match Play Mode", subtitle: "Weekend tournament ready", icon: "person.2.fill")
            ]
            isLoadingNews = false
        }
    }
}

// MARK: - Supporting Views
struct MastersQuickAction: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Action here
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(MastersTypography.footnote)
                    .foregroundColor(MastersColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isPressed ? MastersColors.sandBunker.opacity(0.3) : MastersColors.magnoliaWhite)
            .overlay(
                Rectangle()
                    .stroke(MastersColors.divider, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct MastersNewsRow: View {
    let item: NewsItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .font(.system(size: 24))
                .foregroundColor(MastersColors.augustaGreen)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(MastersTypography.headline)
                    .foregroundColor(MastersColors.textPrimary)
                
                Text(item.subtitle)
                    .font(MastersTypography.footnote)
                    .foregroundColor(MastersColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(MastersColors.textSecondary)
        }
        .padding()
        .background(MastersColors.magnoliaWhite)
        .overlay(
            Rectangle()
                .stroke(MastersColors.divider, lineWidth: 0.5)
        )
    }
}

struct MastersNewsSkeletonRow: View {
    var body: some View {
        HStack(spacing: 16) {
            MastersSkeletonView()
                .frame(width: 40, height: 40)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                MastersSkeletonView()
                    .frame(width: 150, height: 16)
                
                MastersSkeletonView()
                    .frame(width: 200, height: 12)
            }
            
            Spacer()
        }
        .padding()
        .background(MastersColors.magnoliaWhite)
    }
}

// MARK: - Formats View
struct MastersFormatsView: View {
    @State private var searchText = ""
    @State private var selectedFormat: GolfFormat?
    @State private var showingFormatDetail = false
    @State private var savedFormats: [GolfFormat] = []
    @State private var isRefreshing = false
    
    var filteredFormats: [GolfFormat] {
        if searchText.isEmpty {
            return GolfFormat.allFormats
        }
        return GolfFormat.allFormats.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Masters-style navigation bar
                MastersNavigationBar(title: "FORMATS", showBack: false, onBack: nil)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MastersColors.textSecondary)
                    
                    TextField("Search formats", text: $searchText)
                        .font(MastersTypography.body)
                }
                .padding()
                .background(MastersColors.sandBunker.opacity(0.5))
                .overlay(
                    Rectangle()
                        .stroke(MastersColors.divider, lineWidth: 0.5)
                )
                .padding()
                
                if savedFormats.isEmpty && searchText.isEmpty {
                    MastersEmptyState(
                        icon: "bookmark.fill",
                        title: "No Saved Formats",
                        message: "Browse and save your favorite golf formats for quick access",
                        actionTitle: "Browse Formats",
                        action: {}
                    )
                } else {
                    List {
                        ForEach(filteredFormats) { format in
                            MastersFormatRow(format: format)
                                .mastersSwipeToDelete {
                                    savedFormats.removeAll { $0.id == format.id }
                                }
                                .mastersLongPressPreview(
                                    AnyView(FormatPreview(format: format))
                                )
                                .onTapGesture {
                                    selectedFormat = format
                                    showingFormatDetail = true
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .mastersPullToRefresh(isRefreshing: $isRefreshing) {
                        await refreshFormats()
                    }
                }
            }
            .background(MastersColors.sandBunker.opacity(0.3))
            .sheet(item: $selectedFormat) { format in
                MastersFormatDetailView(format: format)
            }
        }
    }
    
    func refreshFormats() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isRefreshing = false
    }
}

struct MastersFormatRow: View {
    let format: GolfFormat
    @State private var isSaved = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with Masters green
            ZStack {
                Rectangle()
                    .fill(format.isTeamFormat ? MastersColors.augustaGreen : MastersColors.fairwayGreen)
                    .frame(width: 44, height: 44)
                
                Image(systemName: format.icon)
                    .font(.system(size: 20))
                    .foregroundColor(MastersColors.magnoliaWhite)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(format.name.uppercased())
                        .font(MastersTypography.headline)
                        .foregroundColor(MastersColors.textPrimary)
                    
                    if format.isTeamFormat {
                        Text("TEAM")
                            .font(MastersTypography.caption2)
                            .foregroundColor(MastersColors.magnoliaWhite)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MastersColors.augustaGreen)
                    }
                }
                
                Text(format.tagline)
                    .font(MastersTypography.footnote)
                    .foregroundColor(MastersColors.textSecondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label(format.players, systemImage: "person.2.fill")
                        .font(MastersTypography.caption)
                        .foregroundColor(MastersColors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(MastersColors.divider)
                    
                    Text(format.difficulty)
                        .font(MastersTypography.caption)
                        .foregroundColor(MastersColors.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: { isSaved.toggle() }) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .foregroundColor(MastersColors.augustaGreen)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(MastersColors.magnoliaWhite)
        .overlay(
            Rectangle()
                .stroke(MastersColors.divider, lineWidth: 0.5)
        )
    }
}

// MARK: - Score View
struct MastersScoreView: View {
    @State private var currentHole = 1
    @State private var scores: [Int: [String: Int]] = [:]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MastersNavigationBar(title: "SCORECARD", showBack: false, onBack: nil)
                
                // Hole selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(1...18, id: \.self) { hole in
                            MastersHoleTab(
                                hole: hole,
                                isSelected: hole == currentHole,
                                onTap: { currentHole = hole }
                            )
                        }
                    }
                    .padding()
                }
                .background(MastersColors.magnoliaWhite)
                .overlay(
                    Rectangle()
                        .stroke(MastersColors.divider, lineWidth: 0.5),
                    alignment: .bottom
                )
                
                // Score entry with number pad
                ScrollView {
                    VStack(spacing: 16) {
                        MastersScoreEntry(hole: currentHole)
                    }
                    .padding()
                }
                .background(MastersColors.sandBunker.opacity(0.3))
                .keyboardType(.numberPad)
            }
        }
    }
}

struct MastersHoleTab: View {
    let hole: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(hole)")
                    .font(MastersTypography.headline)
                    .foregroundColor(isSelected ? MastersColors.magnoliaWhite : MastersColors.textPrimary)
                
                Text("PAR 4")
                    .font(MastersTypography.caption2)
                    .foregroundColor(isSelected ? MastersColors.magnoliaWhite.opacity(0.8) : MastersColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? MastersColors.augustaGreen : MastersColors.magnoliaWhite)
            .overlay(
                Rectangle()
                    .stroke(isSelected ? MastersColors.augustaGreen : MastersColors.divider, lineWidth: 1)
            )
        }
    }
}

struct MastersScoreEntry: View {
    let hole: Int
    @State private var player1Score = ""
    @State private var player2Score = ""
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(["Player 1", "Player 2"], id: \.self) { player in
                HStack {
                    Text(player)
                        .font(MastersTypography.body)
                        .foregroundColor(MastersColors.textPrimary)
                        .frame(width: 100, alignment: .leading)
                    
                    TextField("Score", text: player == "Player 1" ? $player1Score : $player2Score)
                        .font(MastersTypography.title2)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                        .padding(8)
                        .background(MastersColors.magnoliaWhite)
                        .overlay(
                            Rectangle()
                                .stroke(MastersColors.augustaGreen, lineWidth: 2)
                        )
                    
                    Spacer()
                    
                    // Copy score button
                    Button(action: {
                        UIPasteboard.general.string = player == "Player 1" ? player1Score : player2Score
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(MastersColors.textSecondary)
                    }
                }
                .padding()
                .mastersCard()
            }
        }
    }
}

// MARK: - Stats View
struct MastersStatsView: View {
    @State private var isRefreshing = false
    @State private var stats = GameStats()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                MastersNavigationBar(title: "STATISTICS", showBack: false, onBack: nil)
                
                ScrollView {
                    VStack(spacing: 16) {
                        MastersStatCard(title: "SCORING AVERAGE", value: "72.3", trend: "-2.1")
                        MastersStatCard(title: "BEST ROUND", value: "68", trend: nil)
                        MastersStatCard(title: "FORMATS PLAYED", value: "12", trend: "+3")
                        MastersStatCard(title: "WIN PERCENTAGE", value: "42%", trend: "+5%")
                    }
                    .padding()
                }
                .background(MastersColors.sandBunker.opacity(0.3))
                .mastersPullToRefresh(isRefreshing: $isRefreshing) {
                    await refreshStats()
                }
            }
        }
    }
    
    func refreshStats() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Refresh stats logic
        isRefreshing = false
    }
}

struct MastersStatCard: View {
    let title: String
    let value: String
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(MastersTypography.caption)
                .foregroundColor(MastersColors.textSecondary)
            
            HStack(alignment: .bottom) {
                Text(value)
                    .font(MastersTypography.largeTitle)
                    .foregroundColor(MastersColors.textPrimary)
                
                if let trend = trend {
                    Text(trend)
                        .font(MastersTypography.footnote)
                        .foregroundColor(trend.starts(with: "+") ? MastersColors.lightGreen : MastersColors.birdie)
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .mastersCard()
    }
}

// MARK: - Format Detail View
struct MastersFormatDetailView: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var showingTutorial = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .font(MastersTypography.body)
                    .foregroundColor(MastersColors.augustaGreen)
                    
                    Spacer()
                    
                    Text(format.name.uppercased())
                        .font(MastersTypography.headline)
                        .foregroundColor(MastersColors.textPrimary)
                    
                    Spacer()
                    
                    Button("Play") {
                        // Start game
                    }
                    .font(MastersTypography.body)
                    .foregroundColor(MastersColors.augustaGreen)
                }
                .padding()
                .background(MastersColors.magnoliaWhite)
                .overlay(
                    Rectangle()
                        .stroke(MastersColors.divider, lineWidth: 0.5),
                    alignment: .bottom
                )
                
                // Tab selector (Masters style - minimal)
                HStack(spacing: 0) {
                    ForEach(["OVERVIEW", "RULES", "TUTORIAL", "SCORING"], id: \.self) { tab in
                        Button(action: {
                            withAnimation {
                                selectedTab = ["OVERVIEW", "RULES", "TUTORIAL", "SCORING"].firstIndex(of: tab) ?? 0
                            }
                        }) {
                            Text(tab)
                                .font(MastersTypography.caption)
                                .foregroundColor(selectedTab == ["OVERVIEW", "RULES", "TUTORIAL", "SCORING"].firstIndex(of: tab) ? MastersColors.magnoliaWhite : MastersColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedTab == ["OVERVIEW", "RULES", "TUTORIAL", "SCORING"].firstIndex(of: tab) ? MastersColors.augustaGreen : MastersColors.magnoliaWhite)
                        }
                    }
                }
                .overlay(
                    Rectangle()
                        .stroke(MastersColors.divider, lineWidth: 0.5)
                )
                
                // Content
                ScrollView {
                    switch selectedTab {
                    case 0:
                        MastersFormatOverview(format: format)
                    case 1:
                        MastersFormatRules(format: format)
                    case 2:
                        MastersFormatTutorial(format: format, showingTutorial: $showingTutorial)
                    case 3:
                        MastersFormatScoring(format: format)
                    default:
                        EmptyView()
                    }
                }
                .background(MastersColors.sandBunker.opacity(0.3))
            }
        }
        .onAppear {
            // Auto-show tutorial
            if format.hasDiagramSlides && selectedTab == 2 {
                showingTutorial = true
            }
        }
    }
}

// Supporting structures
struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

struct SavedFormat: Identifiable {
    let id = UUID()
    let format: GolfFormat
    let dateSaved: Date
}

struct GameStats {
    var averageScore: Double = 72.3
    var bestRound: Int = 68
    var formatsPlayed: Int = 12
    var winPercentage: Double = 42.0
}

struct FormatPreview: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(format.name)
                .font(MastersTypography.title3)
            
            Text(format.description)
                .font(MastersTypography.body)
            
            HStack {
                Label(format.players, systemImage: "person.2")
                Label(format.difficulty, systemImage: "speedometer")
            }
            .font(MastersTypography.caption)
        }
        .padding()
        .frame(width: 300)
        .background(MastersColors.magnoliaWhite)
    }
}

// Tab content views
struct MastersFormatOverview: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(format.overview, id: \.self) { point in
                HStack(alignment: .top) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(MastersColors.augustaGreen)
                        .padding(.top, 6)
                    
                    Text(point)
                        .font(MastersTypography.body)
                        .foregroundColor(MastersColors.textPrimary)
                }
            }
        }
        .padding()
    }
}

struct MastersFormatRules: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(format.rules.enumerated()), id: \.offset) { index, rule in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .font(MastersTypography.headline)
                        .foregroundColor(MastersColors.augustaGreen)
                        .frame(width: 30, alignment: .leading)
                    
                    Text(rule)
                        .font(MastersTypography.body)
                        .foregroundColor(MastersColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
    }
}

struct MastersFormatTutorial: View {
    let format: GolfFormat
    @Binding var showingTutorial: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                showingTutorial = true
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading) {
                        Text("VIEW INTERACTIVE TUTORIAL")
                            .font(MastersTypography.headline)
                        
                        Text("Tap anywhere to advance")
                            .font(MastersTypography.caption)
                            .foregroundColor(MastersColors.textSecondary)
                    }
                    
                    Spacer()
                }
                .foregroundColor(MastersColors.magnoliaWhite)
                .padding()
                .background(MastersColors.augustaGreen)
            }
            
            Text("Learn this format step-by-step with interactive diagrams")
                .font(MastersTypography.body)
                .foregroundColor(MastersColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

struct MastersFormatScoring: View {
    let format: GolfFormat
    @State private var player1Score = 4
    @State private var player2Score = 5
    @State private var result = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SCORING SIMULATOR")
                .font(MastersTypography.headline)
                .foregroundColor(MastersColors.textPrimary)
            
            // Score inputs
            VStack(spacing: 16) {
                HStack {
                    Text("Player 1")
                        .font(MastersTypography.body)
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper("\(player1Score)", value: $player1Score, in: 1...10)
                        .font(MastersTypography.headline)
                }
                
                HStack {
                    Text("Player 2")
                        .font(MastersTypography.body)
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper("\(player2Score)", value: $player2Score, in: 1...10)
                        .font(MastersTypography.headline)
                }
            }
            .padding()
            .mastersCard()
            
            Button(action: calculateScore) {
                Text("CALCULATE")
            }
            .buttonStyle(MastersButtonStyle(isPrimary: true))
            
            if !result.isEmpty {
                Text(result)
                    .font(MastersTypography.body)
                    .foregroundColor(MastersColors.textPrimary)
                    .padding()
                    .mastersCard()
            }
        }
        .padding()
    }
    
    func calculateScore() {
        switch format.name {
        case "Scramble":
            result = "Team Score: \(min(player1Score, player2Score))"
        case "Best Ball":
            result = "Team Score: \(min(player1Score, player2Score))"
        case "Match Play":
            if player1Score < player2Score {
                result = "Player 1 wins hole"
            } else if player2Score < player1Score {
                result = "Player 2 wins hole"
            } else {
                result = "Hole halved"
            }
        default:
            result = "Score calculated"
        }
    }
}