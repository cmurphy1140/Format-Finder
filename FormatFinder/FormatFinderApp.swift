import SwiftUI

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
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 46/255, green: 125/255, blue: 50/255),
                    Color(red: 102/255, green: 187/255, blue: 106/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(animateText ? 1 : 0)
                                .offset(y: animateText ? 0 : 30)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateText)
                        }
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(Array("Finder".enumerated()), id: \.offset) { index, letter in
                            Text(String(letter))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .opacity(animateText ? 1 : 0)
                                .offset(y: animateText ? 0 : 30)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.05), value: animateText)
                        }
                    }
                }
                
                // Tagline
                Text("Discover Your Perfect Golf Format")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 10)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: animateText)
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 15) {
                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 200, height: 6)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 200 * loadingProgress, height: 6)
                            .animation(.linear(duration: 3), value: loadingProgress)
                    }
                    
                    // Loading dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .opacity(showLoadingDots ? 1 : 0.3)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: showLoadingDots
                                )
                        }
                    }
                    .padding(.bottom, 20)
                }
                .opacity(animateText ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(1), value: animateText)
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateGolf = true
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateText = true
            }
            
            // Start loading dots animation
            withAnimation {
                showLoadingDots = true
            }
            
            // Animate progress bar
            withAnimation(.linear(duration: 3).delay(0.5)) {
                loadingProgress = 1
            }
            
            // Rotate golf icon
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Data Models

struct GolfFormat: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let players: String
    let difficulty: String
    let description: String
    let howToPlay: [String]
    let example: String
    
    var type: String {
        if players.contains("team") || players.contains("Team") {
            return "Team"
        }
        return "Individual"
    }
}

// MARK: - Sample Data

let sampleFormats = [
    GolfFormat(
        name: "Scramble",
        category: "Tournament",
        players: "2-4 players",
        difficulty: "Easy",
        description: "All players hit from the best shot",
        howToPlay: [
            "Everyone tees off",
            "Choose the best drive",
            "All play from that spot",
            "Repeat until holed"
        ],
        example: "Team uses best drive, then best approach, best putt. Score: 4"
    ),
    GolfFormat(
        name: "Best Ball",
        category: "Tournament",
        players: "2-4 players",
        difficulty: "Easy",
        description: "Count the best individual score",
        howToPlay: [
            "Everyone plays own ball",
            "Record individual scores",
            "Use lowest score for team"
        ],
        example: "Player A: 5, Player B: 4, Player C: 6. Team score: 4"
    ),
    GolfFormat(
        name: "Stableford",
        category: "Tournament",
        players: "Any number",
        difficulty: "Easy",
        description: "Points-based scoring system",
        howToPlay: [
            "Assign points based on score relative to par",
            "Double Bogey or worse: 0 points",
            "Bogey: 1 point, Par: 2 points",
            "Birdie: 3 points, Eagle: 4 points"
        ],
        example: "Par 4: Score 5 = 1 point, Score 4 = 2 points, Score 3 = 3 points"
    ),
    GolfFormat(
        name: "Alternate Shot",
        category: "Tournament",
        players: "2 or 4 players",
        difficulty: "Medium",
        description: "Partners alternate hitting shots",
        howToPlay: [
            "Player 1 tees off on odd holes",
            "Player 2 hits second shot",
            "Continue alternating until holed",
            "Player 2 tees off on even holes"
        ],
        example: "Player A drives, Player B hits approach, Player A putts"
    ),
    GolfFormat(
        name: "Match Play",
        category: "Tournament",
        players: "2 players or teams",
        difficulty: "Medium",
        description: "Win individual holes, not total strokes",
        howToPlay: [
            "Compare scores hole by hole",
            "Win hole = 1 up, tie = all square",
            "First to go more up than holes remaining wins",
            "Can end before 18 holes"
        ],
        example: "3 up with 2 holes to play = match won 3&2"
    ),
    GolfFormat(
        name: "Skins",
        category: "Betting",
        players: "2-4 players",
        difficulty: "Easy",
        description: "Win holes outright for money",
        howToPlay: [
            "Each hole worth a 'skin'",
            "Lowest score wins the skin",
            "Ties carry to next hole"
        ],
        example: "Hole 1: Tie. Hole 2: Tie. Hole 3: Player A wins 3 skins"
    ),
    GolfFormat(
        name: "Nassau",
        category: "Betting",
        players: "2-4 players",
        difficulty: "Medium",
        description: "Three bets: front 9, back 9, overall",
        howToPlay: [
            "Front 9 is one bet",
            "Back 9 is another bet",
            "Overall 18 is third bet"
        ],
        example: "Win front 9, lose back 9, tie overall = break even"
    ),
    GolfFormat(
        name: "Vegas",
        category: "Betting",
        players: "4 players",
        difficulty: "Medium",
        description: "Team scores combine to form two-digit numbers",
        howToPlay: [
            "Form two teams of two players each",
            "Combine partner scores as two-digit number",
            "Lower score first: 4 & 5 = 45, not 54",
            "Compare team totals"
        ],
        example: "Team A: 4 & 5 = 45, Team B: 3 & 6 = 36. Team B wins by 9"
    ),
    GolfFormat(
        name: "Wolf",
        category: "Betting",
        players: "4 players",
        difficulty: "Complex",
        description: "One player is 'Wolf' each hole, chooses partner or goes alone",
        howToPlay: [
            "Rotate who is Wolf each hole",
            "Wolf watches others tee off",
            "Choose a partner after seeing shots",
            "Or declare 'Lone Wolf' and play 1v3"
        ],
        example: "Wolf partners with Player B, they score 8 vs others' 9. Wolf team wins"
    ),
    GolfFormat(
        name: "Bingo Bango Bongo",
        category: "Betting",
        players: "2-4 players",
        difficulty: "Easy",
        description: "Three points available on each hole",
        howToPlay: [
            "Bingo: First on the green",
            "Bango: Closest to pin once all on green",
            "Bongo: First to hole out",
            "Can win multiple points per hole"
        ],
        example: "Player A: Bingo + Bongo (2 pts), Player B: Bango (1 pt)"
    ),
    GolfFormat(
        name: "Quota",
        category: "Tournament",
        players: "Any number",
        difficulty: "Medium",
        description: "Try to meet or exceed your personal quota",
        howToPlay: [
            "Calculate quota based on handicap",
            "Quota = 36 - (Handicap * 0.8)",
            "Score points like Stableford",
            "Goal is to reach your quota"
        ],
        example: "12 handicap: Quota = 36 - 9.6 = 26.4 points needed"
    ),
    GolfFormat(
        name: "Four Ball",
        category: "Tournament",
        players: "4 players (2 teams)",
        difficulty: "Easy",
        description: "Each player plays own ball, best score counts",
        howToPlay: [
            "Form two teams of two players",
            "All four players play their own ball",
            "Record best score from each team",
            "Compare team scores hole by hole"
        ],
        example: "Team 1: Player A scores 4, Player B scores 5. Team score: 4"
    )
]

// MARK: - Main App Views

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("bookmarks") private var bookmarkData = Data()
    @Binding var showGameModeSelector: Bool
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(showGameModeSelector: $showGameModeSelector)
                .tabItem {
                    Label("Browse", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            BookmarksView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(1)
            
            PlayView(showGameModeSelector: $showGameModeSelector)
                .tabItem {
                    Label("Play", systemImage: "play.circle.fill")
                }
                .tag(2)
        }
        .tint(Color(red: 46/255, green: 125/255, blue: 50/255))
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedFormat: GolfFormat?
    @Binding var showGameModeSelector: Bool
    
    let filters = ["All", "Tournament", "Betting"]
    
    var filteredFormats: [GolfFormat] {
        sampleFormats.filter { format in
            let matchesSearch = searchText.isEmpty || 
                              format.name.localizedCaseInsensitiveContains(searchText) ||
                              format.description.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilter == "All" || format.category == selectedFilter
            return matchesSearch && matchesFilter
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search formats...", text: $searchText)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter ? 
                                        Color(red: 46/255, green: 125/255, blue: 50/255) : 
                                        Color.gray.opacity(0.1)
                                    )
                                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Format grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredFormats) { format in
                            FormatCard(format: format)
                                .onTapGesture {
                                    selectedFormat = format
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Golf Formats")
            .sheet(item: $selectedFormat) { format in
                FormatDetailView(format: format)
            }
        }
    }
}

// MARK: - Format Card

struct FormatCard: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: format.category == "Tournament" ? "trophy.fill" : "dollarsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255))
                
                Spacer()
                
                Text(format.difficulty)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            Text(format.name)
                .font(.headline)
            
            Text(format.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(format.players)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    var difficultyColor: Color {
        switch format.difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        default: return .red
        }
    }
}

// MARK: - Format Detail View

// MARK: - Format Diagram View

struct FormatDiagramView: View {
    let formatName: String
    @State private var animationPhase = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Golf course background
                LinearGradient(
                    colors: [
                        Color(red: 124/255, green: 179/255, blue: 66/255),
                        Color(red: 139/255, green: 195/255, blue: 74/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Format-specific visuals
                FormatVisual(formatName: formatName, animationPhase: animationPhase)
                    .animation(.easeInOut(duration: 0.8), value: animationPhase)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animationPhase = 1
                }
            }
        }
    }
}

struct FormatVisual: View {
    let formatName: String
    let animationPhase: Int
    
    var body: some View {
        switch formatName {
        case "Scramble":
            ScrambleDiagram(animated: animationPhase == 1)
        case "Best Ball":
            BestBallDiagram(animated: animationPhase == 1)
        default:
            DefaultDiagram(formatName: formatName)
        }
    }
}

struct ScrambleDiagram: View {
    let animated: Bool
    
    var body: some View {
        VStack {
            Text("SCRAMBLE")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Spacer()
            
            HStack(spacing: 40) {
                // Players
                VStack {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                        .scaleEffect(animated ? 1.2 : 1.0)
                    
                    Image(systemName: "figure.golf")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Image(systemName: "figure.golf")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                }
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 25))
                    .foregroundColor(.white)
                    .offset(x: animated ? 10 : -10)
                
                // Best ball selection
                ZStack {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 50, height: 50)
                        .scaleEffect(animated ? 1.3 : 1.0)
                    
                    Text("BEST")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            Text("All play from best shot")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 20)
        }
    }
}

struct BestBallDiagram: View {
    let animated: Bool
    
    var body: some View {
        VStack {
            Text("BEST BALL")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Spacer()
            
            VStack(spacing: 20) {
                // Player scores
                HStack(spacing: 30) {
                    PlayerScore(score: "5", color: .blue, isLowest: false, animated: animated)
                    PlayerScore(score: "4", color: .green, isLowest: true, animated: animated)
                    PlayerScore(score: "6", color: .orange, isLowest: false, animated: animated)
                }
                
                Image(systemName: "arrow.down")
                    .font(.title)
                    .foregroundColor(.white)
                
                // Team score
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green)
                        .frame(width: 100, height: 40)
                        .scaleEffect(animated ? 1.1 : 1.0)
                    
                    Text("Team: 4")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Text("Count the best score")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 20)
        }
    }
}

struct PlayerScore: View {
    let score: String
    let color: Color
    let isLowest: Bool
    let animated: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "figure.golf")
                .font(.title)
                .foregroundColor(color)
            
            ZStack {
                Circle()
                    .fill(isLowest ? color : color.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .scaleEffect(isLowest && animated ? 1.3 : 1.0)
                
                Text(score)
                    .font(.headline)
                    .foregroundColor(isLowest ? .white : color)
            }
        }
    }
}

struct DefaultDiagram: View {
    let formatName: String
    
    var body: some View {
        VStack {
            Text(formatName.uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            Spacer()
            
            Image(systemName: "figure.golf")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Format Detail View

struct FormatDetailView: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    @AppStorage("bookmarks") private var bookmarkData = Data()
    @State private var isBookmarked = false
    @State private var selectedStepIndex: Int? = nil
    @State private var showDiagram = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with animation
                    HStack {
                        Label(format.players, systemImage: "person.2.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(format.difficulty)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: difficultyGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 2)
                    }
                    .padding(.horizontal)
                    
                    // Description with larger text
                    Text(format.description)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.horizontal)
                        .multilineTextAlignment(.leading)
                    
                    // Interactive Visual Diagram - Now with Slideshow!
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "photo.stack.fill")
                                .font(.title3)
                                .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255))
                            Text("Visual Guide")
                                .font(.headline)
                                .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255))
                            Spacer()
                            if showDiagram {
                                Text("Swipe to explore →")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if showDiagram {
                            FormatDiagramSlideshow(formatName: format.name)
                                .frame(height: 350)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        } else {
                            Button(action: { withAnimation(.spring()) { showDiagram = true } }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.1),
                                                    Color(red: 76/255, green: 175/255, blue: 80/255).opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 200)
                                    
                                    VStack(spacing: 12) {
                                        Image(systemName: "hand.tap.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255))
                                        Text("Tap to view interactive guide")
                                            .font(.headline)
                                            .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255))
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // How to Play - Enhanced and Interactive
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255))
                            Text("How to Play")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                        
                        ForEach(Array(format.howToPlay.enumerated()), id: \.offset) { index, step in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedStepIndex = selectedStepIndex == index ? nil : index
                                }
                            }) {
                                HStack(alignment: .top, spacing: 16) {
                                    // Step number circle
                                    ZStack {
                                        Circle()
                                            .fill(
                                                selectedStepIndex == index ?
                                                Color(red: 46/255, green: 125/255, blue: 50/255) :
                                                Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.2)
                                            )
                                            .frame(width: 40, height: 40)
                                        
                                        Text("\(index + 1)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(selectedStepIndex == index ? .white : Color(red: 46/255, green: 125/255, blue: 50/255))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(step)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        if selectedStepIndex == index {
                                            // Additional detail when tapped
                                            Text(getStepDetail(for: format.name, step: index))
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                                .transition(.move(edge: .top).combined(with: .opacity))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Image(systemName: selectedStepIndex == index ? "chevron.up.circle.fill" : "chevron.down.circle")
                                        .font(.title3)
                                        .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.6))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            selectedStepIndex == index ?
                                            Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.05) :
                                            Color.gray.opacity(0.03)
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedStepIndex == index ?
                                            Color(red: 46/255, green: 125/255, blue: 50/255).opacity(0.3) :
                                            Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                    
                    // Example - Enhanced visual
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Example")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(format.example)
                            .font(.system(size: 16))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.orange.opacity(0.05),
                                        Color.yellow.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle(format.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .onAppear {
            loadBookmarkStatus()
        }
    }
    
    var difficultyColor: Color {
        switch format.difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        default: return .red
        }
    }
    
    var difficultyGradient: [Color] {
        switch format.difficulty {
        case "Easy": return [.green, Color(red: 76/255, green: 175/255, blue: 80/255)]
        case "Medium": return [.orange, Color(red: 255/255, green: 183/255, blue: 77/255)]
        default: return [.red, Color(red: 239/255, green: 83/255, blue: 80/255)]
        }
    }
    
    func getStepDetail(for formatName: String, step: Int) -> String {
        // Add contextual details for each step
        switch formatName {
        case "Scramble":
            let details = [
                "Each player should aim for their best drive - don't hold back!",
                "Consider position, lie, and distance to the green when choosing.",
                "Everyone hits from the exact same spot - mark it carefully.",
                "Continue this process for approach shots and putts."
            ]
            return step < details.count ? details[step] : ""
            
        case "Best Ball":
            let details = [
                "Each player plays their own ball from tee to green.",
                "Keep accurate scores for each player on every hole.",
                "Only the lowest score counts - other scores don't matter."
            ]
            return step < details.count ? details[step] : ""
            
        case "Stableford":
            let details = [
                "Award points based on your score relative to the par of the hole.",
                "No points for double bogey - so pick up if you're struggling!",
                "Standard scoring: 1 point for bogey, 2 for par.",
                "Bonus points: 3 for birdie, 4 for eagle or better."
            ]
            return step < details.count ? details[step] : ""
            
        case "Alternate Shot":
            let details = [
                "Decide who tees off first - they'll tee off on all odd holes.",
                "Hit every other shot - no exceptions, even for putts!",
                "Keep alternating throughout the entire hole.",
                "The other player tees off on all even-numbered holes."
            ]
            return step < details.count ? details[step] : ""
            
        default:
            return "Tap to learn more about this step."
        }
    }
    
    func loadBookmarkStatus() {
        if let bookmarks = try? JSONDecoder().decode([String].self, from: bookmarkData) {
            isBookmarked = bookmarks.contains(format.name)
        }
    }
    
    func toggleBookmark() {
        var bookmarks = (try? JSONDecoder().decode([String].self, from: bookmarkData)) ?? []
        
        if isBookmarked {
            bookmarks.removeAll { $0 == format.name }
        } else {
            bookmarks.append(format.name)
        }
        
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            bookmarkData = encoded
        }
        
        isBookmarked.toggle()
    }
}

// MARK: - Bookmarks View

struct BookmarksView: View {
    @AppStorage("bookmarks") private var bookmarkData = Data()
    @State private var selectedFormat: GolfFormat?
    
    var bookmarkedFormats: [GolfFormat] {
        guard let bookmarks = try? JSONDecoder().decode([String].self, from: bookmarkData) else {
            return []
        }
        return sampleFormats.filter { bookmarks.contains($0.name) }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if bookmarkedFormats.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No saved formats yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Tap the bookmark icon on any format to save it here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(bookmarkedFormats) { format in
                                FormatCard(format: format)
                                    .onTapGesture {
                                        selectedFormat = format
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Saved Formats")
            .sheet(item: $selectedFormat) { format in
                FormatDetailView(format: format)
            }
        }
    }
}

import SwiftUI

// MARK: - Diagram Slideshow Container

struct FormatDiagramSlideshow: View {
    let formatName: String
    @State private var currentSlide = 0
    
    var slides: [AnyView] {
        switch formatName {
        case "Scramble":
            return ScrambleSlides.slides
        case "Best Ball":
            return BestBallSlides.slides
        case "Stableford":
            return StablefordSlides.slides
        case "Alternate Shot":
            return AlternateShotSlides.slides
        case "Match Play":
            return MatchPlaySlides.slides
        case "Skins":
            return SkinsSlides.slides
        case "Nassau":
            return NassauSlides.slides
        case "Vegas":
            return VegasSlides.slides
        case "Wolf":
            return WolfSlides.slides
        case "Bingo Bango Bongo":
            return BingoBangoBongoSlides.slides
        default:
            return [AnyView(DefaultDiagramSlide(title: formatName))]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Slide content
            TabView(selection: $currentSlide) {
                ForEach(0..<slides.count, id: \.self) { index in
                    slides[index]
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
            
            // Custom page indicators
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(currentSlide == index ? 
                            Color(red: 46/255, green: 125/255, blue: 50/255) : 
                            Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentSlide == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentSlide)
                }
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Scramble Format Slides

struct ScrambleSlides {
    static var slides: [AnyView] {
        [
            AnyView(ScrambleSetupSlide()),
            AnyView(ScrambleTeeShots()),
            AnyView(ScrambleBestShot()),
            AnyView(ScrambleScoring()),
            AnyView(ScrambleProTips())
        ]
    }
}

struct ScrambleSetupSlide: View {
    @State private var showPlayers = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "SCRAMBLE - Setup",
            subtitle: "2-4 Players per Team"
        ) {
            VStack(spacing: 20) {
                // Team formation visual
                HStack(spacing: 30) {
                    ForEach(0..<4) { index in
                        VStack {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 40))
                                .foregroundColor(playerColors[index])
                                .scaleEffect(showPlayers ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5)
                                    .delay(Double(index) * 0.1),
                                    value: showPlayers
                                )
                            
                            Text("Player \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .opacity(showPlayers ? 1 : 0)
                                .animation(
                                    .easeIn(duration: 0.3)
                                    .delay(Double(index) * 0.1 + 0.2),
                                    value: showPlayers
                                )
                        }
                    }
                }
                
                Text("All players on same team")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                    )
            }
            .onAppear {
                showPlayers = true
            }
        }
    }
}

struct ScrambleTeeShots: View {
    @State private var animateShots = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Step 1: Everyone Tees Off",
            subtitle: "All players hit their drive"
        ) {
            ZStack {
                // Golf hole visualization
                GolfHoleView()
                
                // Animated shot paths
                ForEach(0..<4) { index in
                    ShotPath(
                        startX: 50,
                        startY: 200,
                        endX: shotEndpoints[index].x,
                        endY: shotEndpoints[index].y,
                        color: playerColors[index],
                        animate: animateShots,
                        delay: Double(index) * 0.2
                    )
                }
                
                // Ball positions
                ForEach(0..<4) { index in
                    Circle()
                        .fill(playerColors[index])
                        .frame(width: 12, height: 12)
                        .position(
                            x: animateShots ? shotEndpoints[index].x : 50,
                            y: animateShots ? shotEndpoints[index].y : 200
                        )
                        .animation(
                            .easeOut(duration: 0.8)
                            .delay(Double(index) * 0.2),
                            value: animateShots
                        )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateShots = true
                }
            }
        }
    }
    
    var shotEndpoints: [CGPoint] {
        [
            CGPoint(x: 180, y: 120),
            CGPoint(x: 200, y: 100),  // Best shot
            CGPoint(x: 160, y: 110),
            CGPoint(x: 190, y: 130)
        ]
    }
}

struct ScrambleBestShot: View {
    @State private var selectBest = false
    @State private var moveToSpot = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Step 2: Choose Best Shot",
            subtitle: "Team selects optimal position"
        ) {
            VStack(spacing: 20) {
                ZStack {
                    GolfHoleView()
                    
                    // Show all ball positions
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == 1 ? Color.yellow : playerColors[index].opacity(0.3))
                            .frame(width: index == 1 && selectBest ? 20 : 12)
                            .position(shotEndpoints[index])
                            .overlay(
                                index == 1 && selectBest ?
                                Text("BEST")
                                    .font(.caption2.bold())
                                    .foregroundColor(.black)
                                    .position(shotEndpoints[index])
                                : nil
                            )
                    }
                    
                    // Arrow pointing to best shot
                    if selectBest {
                        Image(systemName: "arrow.down")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .position(x: shotEndpoints[1].x, y: shotEndpoints[1].y - 30)
                            .transition(.scale)
                    }
                    
                    // All players at best shot
                    if moveToSpot {
                        ForEach(0..<4) { index in
                            Image(systemName: "figure.golf")
                                .font(.caption)
                                .foregroundColor(playerColors[index])
                                .position(
                                    x: shotEndpoints[1].x + CGFloat(index - 2) * 15,
                                    y: shotEndpoints[1].y + 20
                                )
                                .transition(.scale)
                        }
                    }
                }
                
                Text(moveToSpot ? "Everyone plays from here!" : "Team discusses best option")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .animation(.easeInOut, value: moveToSpot)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { selectBest = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { moveToSpot = true }
                    }
                }
            }
        }
    }
    
    var shotEndpoints: [CGPoint] {
        [
            CGPoint(x: 180, y: 120),
            CGPoint(x: 200, y: 100),  // Best shot
            CGPoint(x: 160, y: 110),
            CGPoint(x: 190, y: 130)
        ]
    }
}

struct ScrambleScoring: View {
    @State private var showScore = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring",
            subtitle: "One score for the team"
        ) {
            VStack(spacing: 30) {
                // Scorecard visual
                VStack(spacing: 15) {
                    HStack {
                        Text("Hole")
                        Spacer()
                        Text("Par")
                        Spacer()
                        Text("Team Score")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                    HStack {
                        Text("1")
                        Spacer()
                        Text("4")
                        Spacer()
                        Text(showScore ? "3" : "-")
                            .font(.title2.bold())
                            .foregroundColor(showScore ? .green : .gray)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                if showScore {
                    Label("Birdie! Great teamwork!", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.spring()) {
                        showScore = true
                    }
                }
            }
        }
    }
}

struct ScrambleProTips: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Pro Tips",
            subtitle: "Strategy for success"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                ForEach(scrambleTips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                            .opacity(showTips ? 1 : 0)
                            .scaleEffect(showTips ? 1 : 0.5)
                            .animation(
                                .spring()
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                        
                        Text(scrambleTips[index])
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(showTips ? 1 : 0)
                            .offset(x: showTips ? 0 : -20)
                            .animation(
                                .easeOut(duration: 0.5)
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                    }
                }
            }
            .padding(.horizontal)
            .onAppear {
                showTips = true
            }
        }
    }
    
    var scrambleTips: [String] {
        [
            "Have at least one consistent player for safety",
            "Let big hitters go for distance",
            "Save your best putter for pressure putts",
            "Communicate about best angles and lies"
        ]
    }
}

// MARK: - Best Ball Format Slides

struct BestBallSlides {
    static var slides: [AnyView] {
        [
            AnyView(BestBallSetupSlide()),
            AnyView(BestBallGameplay()),
            AnyView(BestBallScoring()),
            AnyView(BestBallStrategy())
        ]
    }
}

struct BestBallSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "BEST BALL - Setup",
            subtitle: "Each player plays own ball"
        ) {
            VStack(spacing: 25) {
                // Show players with their own balls
                HStack(spacing: 40) {
                    ForEach(0..<3) { index in
                        VStack(spacing: 10) {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 35))
                                .foregroundColor(playerColors[index])
                            
                            Circle()
                                .fill(playerColors[index])
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                )
                            
                            Text("Own Ball")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .opacity(showSetup ? 1 : 0)
                        .offset(y: showSetup ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.5)
                            .delay(Double(index) * 0.15),
                            value: showSetup
                        )
                    }
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 30)
                
                Text("Everyone plays independently")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.5), value: showSetup)
            }
            .onAppear { showSetup = true }
        }
    }
}

struct BestBallGameplay: View {
    @State private var playShots = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Gameplay",
            subtitle: "Each player completes the hole"
        ) {
            ZStack {
                GolfHoleView()
                
                // Three separate paths for each player
                ForEach(0..<3) { index in
                    ShotPath(
                        startX: 50,
                        startY: 200,
                        endX: 250,
                        endY: 100,
                        color: playerColors[index],
                        animate: playShots,
                        delay: Double(index) * 0.3,
                        curved: true,
                        curveFactor: CGFloat(index - 1) * 30
                    )
                }
                
                // Show scores at the hole
                if playShots {
                    VStack {
                        ForEach(0..<3) { index in
                            HStack {
                                Circle()
                                    .fill(playerColors[index])
                                    .frame(width: 16, height: 16)
                                Text("Score: \(playerScores[index])")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .position(x: 250, y: 160)
                    .transition(.scale)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        playShots = true
                    }
                }
            }
        }
    }
    
    var playerScores: [Int] { [5, 4, 6] }
}

struct BestBallScoring: View {
    @State private var highlightBest = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring",
            subtitle: "Count only the best score"
        ) {
            VStack(spacing: 20) {
                // Score comparison
                HStack(spacing: 30) {
                    ForEach(0..<3) { index in
                        VStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(playerColors[index])
                            
                            ZStack {
                                Circle()
                                    .fill(index == 1 && highlightBest ? 
                                        Color.green : 
                                        playerColors[index].opacity(0.3))
                                    .frame(width: 50, height: 50)
                                
                                Text("\(playerScores[index])")
                                    .font(.title2.bold())
                                    .foregroundColor(index == 1 && highlightBest ? 
                                        .white : 
                                        playerColors[index])
                            }
                            .scaleEffect(index == 1 && highlightBest ? 1.2 : 1.0)
                            .animation(.spring(), value: highlightBest)
                        }
                    }
                }
                
                Image(systemName: "arrow.down")
                    .font(.title)
                    .foregroundColor(.white)
                    .opacity(highlightBest ? 1 : 0)
                
                if highlightBest {
                    Text("Team Score: 4")
                        .font(.title.bold())
                        .foregroundColor(.green)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        )
                        .transition(.scale)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { highlightBest = true }
                }
            }
        }
    }
    
    var playerScores: [Int] { [5, 4, 6] }
}

struct BestBallStrategy: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Tips for Best Ball success"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                ForEach(bestBallTips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: strategIcons[index])
                            .foregroundColor(.cyan)
                            .font(.system(size: 18))
                            .frame(width: 24)
                            .opacity(showTips ? 1 : 0)
                            .scaleEffect(showTips ? 1 : 0.5)
                            .animation(
                                .spring()
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                        
                        Text(bestBallTips[index])
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(showTips ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.5)
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                    }
                }
            }
            .padding(.horizontal)
            .onAppear { showTips = true }
        }
    }
    
    var bestBallTips: [String] {
        [
            "Play your normal game - no pressure!",
            "One bad hole doesn't hurt the team",
            "Support teammates even when struggling",
            "Aggressive play can pay off"
        ]
    }
    
    var strategIcons: [String] {
        ["checkmark.circle", "xmark.shield", "person.2", "flame"]
    }
}

// MARK: - Reusable Components

struct DiagramSlideTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 10)
            
            // Content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 46/255, green: 125/255, blue: 50/255),
                    Color(red: 76/255, green: 175/255, blue: 80/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct GolfHoleView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fairway
                Path { path in
                    path.move(to: CGPoint(x: 30, y: 220))
                    path.addQuadCurve(
                        to: CGPoint(x: 270, y: 100),
                        control: CGPoint(x: 150, y: 150)
                    )
                    path.addLine(to: CGPoint(x: 270, y: 120))
                    path.addQuadCurve(
                        to: CGPoint(x: 30, y: 240),
                        control: CGPoint(x: 150, y: 170)
                    )
                    path.closeSubpath()
                }
                .fill(Color(red: 139/255, green: 195/255, blue: 74/255).opacity(0.6))
                
                // Tee box
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 93/255, green: 64/255, blue: 55/255))
                    .frame(width: 30, height: 30)
                    .position(x: 50, y: 200)
                
                // Green
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255))
                    .frame(width: 60, height: 60)
                    .position(x: 250, y: 100)
                
                // Hole
                Circle()
                    .fill(Color.black)
                    .frame(width: 8, height: 8)
                    .position(x: 250, y: 100)
                
                // Flag
                Path { path in
                    path.move(to: CGPoint(x: 250, y: 100))
                    path.addLine(to: CGPoint(x: 250, y: 70))
                }
                .stroke(Color.white, lineWidth: 2)
                
                Path { path in
                    path.move(to: CGPoint(x: 250, y: 70))
                    path.addLine(to: CGPoint(x: 250, y: 80))
                    path.addLine(to: CGPoint(x: 265, y: 75))
                    path.closeSubpath()
                }
                .fill(Color.red)
            }
        }
    }
}

struct ShotPath: View {
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let color: Color
    let animate: Bool
    let delay: Double
    var curved: Bool = false
    var curveFactor: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            
            if curved {
                let controlX = (startX + endX) / 2 + curveFactor
                let controlY = (startY + endY) / 2 - 30
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: controlX, y: controlY)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: (startX + endX) / 2, y: min(startY, endY) - 40)
                )
            }
        }
        .trim(from: 0, to: animate ? 1 : 0)
        .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
        .animation(
            .easeOut(duration: 0.8)
            .delay(delay),
            value: animate
        )
    }
}

struct DefaultDiagramSlide: View {
    let title: String
    
    var body: some View {
        DiagramSlideTemplate(title: title.uppercased(), subtitle: "Golf Format") {
            Image(systemName: "figure.golf")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Additional Format Slides (Stableford)

struct StablefordSlides {
    static var slides: [AnyView] {
        [
            AnyView(StablefordScoringSystem()),
            AnyView(StablefordExample()),
            AnyView(StablefordStrategy())
        ]
    }
}

struct StablefordScoringSystem: View {
    @State private var showPoints = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "STABLEFORD",
            subtitle: "Points-based scoring"
        ) {
            VStack(spacing: 15) {
                ForEach(stablefordPoints.indices, id: \.self) { index in
                    HStack {
                        Text(stablefordPoints[index].score)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 100, alignment: .leading)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(stablefordPoints[index].color.opacity(0.3))
                                .frame(width: 60, height: 30)
                            
                            Text("\(stablefordPoints[index].points) pts")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(stablefordPoints[index].color)
                        }
                        .scaleEffect(showPoints ? 1 : 0)
                        .animation(
                            .spring()
                            .delay(Double(index) * 0.1),
                            value: showPoints
                        )
                    }
                    .padding(.horizontal, 30)
                }
            }
            .onAppear { showPoints = true }
        }
    }
    
    var stablefordPoints: [(score: String, points: Int, color: Color)] {
        [
            ("Eagle or better", 4, .yellow),
            ("Birdie", 3, .green),
            ("Par", 2, .blue),
            ("Bogey", 1, .orange),
            ("Double Bogey+", 0, .red)
        ]
    }
}

struct StablefordExample: View {
    @State private var currentHole = 0
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Example Round",
            subtitle: "9 holes played"
        ) {
            VStack(spacing: 20) {
                // Scorecard grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(0..<9) { hole in
                            VStack(spacing: 8) {
                                Text("H\(hole + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Text(holeScores[hole])
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    Circle()
                                        .fill(pointColors[hole])
                                        .frame(width: 30, height: 30)
                                    
                                    Text("\(holePoints[hole])")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(currentHole >= hole ? 1 : 0)
                                .animation(
                                    .spring()
                                    .delay(Double(hole) * 0.1),
                                    value: currentHole
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Total
                HStack {
                    Text("Total Points:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(currentHole > 0 ? holePoints[0...min(currentHole-1, 8)].reduce(0, +) : 0)")
                        .font(.title2.bold())
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
                    if currentHole < 9 {
                        currentHole += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    var holeScores: [String] {
        ["Par", "Bogey", "Birdie", "Par", "Eagle", "Bogey", "Par", "Double", "Par"]
    }
    
    var holePoints: [Int] {
        [2, 1, 3, 2, 4, 1, 2, 0, 2]
    }
    
    var pointColors: [Color] {
        [.blue, .orange, .green, .blue, .yellow, .orange, .blue, .red, .blue]
    }
}

struct StablefordStrategy: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Maximize your points"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                ForEach(stablefordTips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 30, height: 30)
                            
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.purple)
                        }
                        .opacity(showTips ? 1 : 0)
                        .scaleEffect(showTips ? 1 : 0.5)
                        .animation(
                            .spring()
                            .delay(Double(index) * 0.15),
                            value: showTips
                        )
                        
                        Text(stablefordTips[index])
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(showTips ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.5)
                                .delay(Double(index) * 0.15),
                                value: showTips
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .onAppear { showTips = true }
        }
    }
    
    var stablefordTips: [String] {
        [
            "Pick up after double bogey - no points anyway",
            "Be aggressive on par 5s - eagle is 4 points!",
            "Steady play wins - pars add up quickly",
            "Don't chase lost balls - save time and energy"
        ]
    }
}

// MARK: - Other Format Slides (simplified for brevity)

struct AlternateShotSlides {
    static var slides: [AnyView] {
        [
            AnyView(AlternateShotSetup()),
            AnyView(AlternateShotGameplay()),
            AnyView(AlternateShotStrategy())
        ]
    }
}

struct AlternateShotSetup: View {
    var body: some View {
        DiagramSlideTemplate(title: "ALTERNATE SHOT", subtitle: "Partners take turns") {
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    PlayerIcon(color: .blue, label: "Player A", number: "1")
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title)
                        .foregroundColor(.white)
                    PlayerIcon(color: .orange, label: "Player B", number: "2")
                }
                
                Text("One ball, alternating shots")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

struct AlternateShotGameplay: View {
    @State private var currentShot = 0
    
    var body: some View {
        DiagramSlideTemplate(title: "Shot Sequence", subtitle: "Taking turns") {
            VStack(spacing: 15) {
                ForEach(0..<5) { shot in
                    HStack {
                        Image(systemName: shotIcons[shot])
                            .frame(width: 30)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(shotDescriptions[shot])
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Circle()
                            .fill(shot % 2 == 0 ? Color.blue : Color.orange)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(shot % 2 == 0 ? "A" : "B")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            )
                            .opacity(currentShot >= shot ? 1 : 0.3)
                            .scaleEffect(currentShot == shot ? 1.2 : 1)
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(), value: currentShot)
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                    if currentShot < 4 {
                        currentShot += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    var shotIcons: [String] {
        ["figure.golf", "arrow.up.right", "sportscourt", "target", "flag.fill"]
    }
    
    var shotDescriptions: [String] {
        ["Tee shot", "Approach", "Chip", "First putt", "Tap in"]
    }
}

struct AlternateShotStrategy: View {
    var body: some View {
        DiagramSlideTemplate(title: "Key Strategy", subtitle: "Work as a team") {
            VStack(alignment: .leading, spacing: 20) {
                StrategyPoint(
                    icon: "person.2.fill",
                    text: "Consider who tees off on par 3s",
                    color: .blue
                )
                StrategyPoint(
                    icon: "target",
                    text: "Leave makeable putts for partner",
                    color: .green
                )
                StrategyPoint(
                    icon: "checkmark.shield",
                    text: "Play safe when partner is struggling",
                    color: .orange
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// Additional format slides structures
struct MatchPlaySlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Match Play"))]
    }
}

struct SkinsSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Skins"))]
    }
}

struct NassauSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Nassau"))]
    }
}

struct VegasSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Vegas"))]
    }
}

struct WolfSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Wolf"))]
    }
}

struct BingoBangoBongoSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Bingo Bango Bongo"))]
    }
}

// MARK: - Helper Components

struct PlayerIcon: View {
    let color: Color
    let label: String
    let number: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.golf")
                .font(.system(size: 35))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

struct StrategyPoint: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Play View

struct PlayView: View {
    @Binding var showGameModeSelector: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 46/255, green: 125/255, blue: 50/255),
                        Color(red: 102/255, green: 187/255, blue: 106/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "flag.checkered.2.crossed")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Play a Game")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Track your scores and compete with friends")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Start Game Button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showGameModeSelector = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                            
                            Text("Start New Game")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 40)
                    
                    // Features list
                    VStack(spacing: 20) {
                        FeatureRow(icon: "person.2.fill", text: "2-4 Players")
                        FeatureRow(icon: "flag.fill", text: "12 Game Formats")
                        FeatureRow(icon: "chart.bar.fill", text: "Live Statistics")
                        FeatureRow(icon: "square.and.arrow.up", text: "Export Scorecards")
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

// MARK: - Constants

let playerColors: [Color] = [
    .blue,
    .green,
    .orange,
    .purple
]