import SwiftUI

@main
struct FormatFinderApp: App {
    @State private var showLaunchScreen = true
    
    init() {
        // Initialize haptic engine
        // HapticManager setup if needed
    }
    
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
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.2),
                    Color(red: 0.05, green: 0.25, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Icon with animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .blur(radius: 10)
                    
                    Image(systemName: "flag.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(iconRotation))
                        .scaleEffect(iconScale)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                // App Name
                VStack(spacing: 10) {
                    Text("Format Finder")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                    
                    Text("Master Every Golf Format")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                }
                
                // Shimmer effect overlay
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 100)
                    .offset(x: shimmerOffset)
                    .mask(
                        Text("Format Finder")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                    )
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                iconScale = 1.0
                iconRotation = 360
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textOpacity = 1.0
                textOffset = 0
            }
            
            withAnimation(.linear(duration: 1.5).delay(1.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @Binding var showGameModeSelector: Bool
    @State private var selectedFormat: GolfFormat?
    @State private var selectedTab = 0
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            HomeView(selectedFormat: $selectedFormat, showGameModeSelector: $showGameModeSelector)
                .navigationBarHidden(true)
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @Binding var selectedFormat: GolfFormat?
    @Binding var showGameModeSelector: Bool
    @State private var searchText = ""
    @State private var showBookmarks = false
    
    let formats: [GolfFormat] = GolfFormat.allFormats
    
    var filteredFormats: [GolfFormat] {
        if searchText.isEmpty {
            return formats
        } else {
            return formats.filter { format in
                format.name.localizedCaseInsensitiveContains(searchText) ||
                format.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Text("Format Finder")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showGameModeSelector = true }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search formats...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.top, 50)
            .padding(.bottom, 10)
            .background(Color(.systemBackground))
            
            // Format List
            ScrollView {
                LazyVStack(spacing: 15) {
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
        .sheet(item: $selectedFormat) { format in
            FormatDetailView(format: format)
        }
    }
}

// MARK: - Format Card

struct FormatCard: View {
    let format: GolfFormat
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            Image(systemName: format.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [format.color, format.color.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(format.name)
                    .font(.headline)
                
                Text(format.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label("\(format.players)", systemImage: "person.2.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Label(format.difficulty, systemImage: "speedometer")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Format Detail View

struct FormatDetailView: View {
    let format: GolfFormat
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 2 // Start with Interactive tab
    @State private var showingTutorial = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: format.icon)
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(format.color)
                                .cornerRadius(12)
                            
                            VStack(alignment: .leading) {
                                Text(format.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text(format.tagline)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(format.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Players")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(format.players)
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Difficulty")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(format.difficulty)
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Team Format")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(format.isTeamFormat ? "Yes" : "No")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                    
                    // Tab Selection with larger size and green hue
                    Picker("View", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("Rules").tag(1)
                        Text("Tutorial").tag(2)
                        Text("Simulator").tag(3)
                        Text("Strategy").tag(4)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.6, blue: 0.3).opacity(0.1),
                                Color(red: 0.1, green: 0.5, blue: 0.2).opacity(0.15)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .scaleEffect(1.05) // Make it slightly larger
                    
                    // Tab Content
                    Group {
                        switch selectedTab {
                        case 0:
                            OverviewTab(format: format)
                        case 1:
                            RulesTab(format: format)
                        case 2:
                            InteractiveTutorialTab(format: format, showingTutorial: $showingTutorial)
                        case 3:
                            ScoringSimulatorTab(format: format)
                        case 4:
                            StrategyTab(format: format)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            if format.hasDiagramSlides {
                FormatDiagramSlideshow(format: format, isPresented: $showingTutorial)
            }
        }
    }
}

// MARK: - Tab Views

struct OverviewTab: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(format.overview, id: \.self) { section in
                Text(section)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(10)
            }
        }
    }
}

struct RulesTab: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(Array(format.rules.enumerated()), id: \.offset) { index, rule in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .clipShape(Circle())
                    
                    Text(rule)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
            }
        }
    }
}

struct InteractiveTutorialTab: View {
    let format: GolfFormat
    @Binding var showingTutorial: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            if format.hasDiagramSlides {
                Button(action: {
                    showingTutorial = true
                }) {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading) {
                            Text("View Interactive Tutorial")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Click through step-by-step visual guide")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.6, blue: 0.4),
                                Color(red: 0.1, green: 0.5, blue: 0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            
            NavigationLink(destination: InteractiveFormatView(format: format)) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading) {
                        Text("Interactive Practice")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Try the format yourself")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Text("Tip: Click anywhere on the tutorial slides to advance to the next step")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
        }
    }
}

struct ScoringSimulatorTab: View {
    let format: GolfFormat
    @State private var player1Score = 4
    @State private var player2Score = 5
    @State private var player3Score = 4
    @State private var player4Score = 6
    @State private var currentHole = 1
    @State private var simulationResult = ""
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Current hole display
            VStack {
                Text("Hole \(currentHole)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Par 4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.4, blue: 0.2).opacity(0.1),
                        Color(red: 0.05, green: 0.3, blue: 0.15).opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            
            // Score input for each player
            VStack(spacing: 15) {
                HStack {
                    Label("Player 1", systemImage: "person.fill")
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper(value: $player1Score, in: 1...10) {
                        Text("\(player1Score)")
                            .font(.headline)
                            .frame(width: 30)
                    }
                }
                
                HStack {
                    Label("Player 2", systemImage: "person.fill")
                        .frame(width: 100, alignment: .leading)
                    
                    Stepper(value: $player2Score, in: 1...10) {
                        Text("\(player2Score)")
                            .font(.headline)
                            .frame(width: 30)
                    }
                }
                
                if format.players.contains("4") {
                    HStack {
                        Label("Player 3", systemImage: "person.fill")
                            .frame(width: 100, alignment: .leading)
                        
                        Stepper(value: $player3Score, in: 1...10) {
                            Text("\(player3Score)")
                                .font(.headline)
                                .frame(width: 30)
                        }
                    }
                    
                    HStack {
                        Label("Player 4", systemImage: "person.fill")
                            .frame(width: 100, alignment: .leading)
                        
                        Stepper(value: $player4Score, in: 1...10) {
                            Text("\(player4Score)")
                                .font(.headline)
                                .frame(width: 30)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Calculate button
            Button(action: calculateFormatScore) {
                Text("Calculate \(format.name) Score")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.6, blue: 0.3),
                                Color(red: 0.1, green: 0.5, blue: 0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            
            // Result display
            if showResult {
                VStack(spacing: 10) {
                    Text("Result")
                        .font(.headline)
                    
                    Text(simulationResult)
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
                .transition(.scale)
            }
            
            Spacer()
        }
    }
    
    func calculateFormatScore() {
        withAnimation {
            switch format.name {
            case "Scramble":
                let bestScore = min(player1Score, player2Score, player3Score, player4Score)
                simulationResult = "Team Score: \(bestScore)\nAll players play from the best shot location."
                
            case "Best Ball":
                let bestScore = min(player1Score, player2Score, player3Score, player4Score)
                simulationResult = "Team Score: \(bestScore)\nEach player played their own ball, best score counts."
                
            case "Stableford":
                let points = calculateStablefordPoints(score: player1Score, par: 4)
                simulationResult = "Player 1 Points: \(points)\nScoring: Eagle=4, Birdie=3, Par=2, Bogey=1, Double+=0"
                
            case "Alternate Shot":
                let avgScore = (player1Score + player2Score) / 2
                simulationResult = "Team Score: ~\(avgScore)\nPartners alternated shots throughout the hole."
                
            case "Match Play":
                let winner = player1Score < player2Score ? "Player 1" : player2Score < player1Score ? "Player 2" : "Halved"
                simulationResult = "Hole Winner: \(winner)\n\(winner == "Halved" ? "Hole is tied" : "\(winner) wins the hole")"
                
            case "Skins":
                let scores = [player1Score, player2Score, player3Score, player4Score].prefix(format.players.contains("4") ? 4 : 2)
                let minScore = scores.min() ?? 0
                let winners = scores.filter { $0 == minScore }
                simulationResult = winners.count == 1 ? "Skin won by player with score \(minScore)" : "No skin - hole is tied, carries over"
                
            case "Nassau":
                simulationResult = "Front 9: \(player1Score < player2Score ? "Player 1" : "Player 2") leads\nThis is hole \(currentHole) of 18"
                
            case "Vegas":
                let team1Score = min(player1Score, player2Score) * 10 + max(player1Score, player2Score)
                let team2Score = min(player3Score, player4Score) * 10 + max(player3Score, player4Score)
                simulationResult = "Team 1: \(team1Score)\nTeam 2: \(team2Score)\nDifference: \(abs(team1Score - team2Score)) points"
                
            case "Wolf":
                simulationResult = "Wolf chose to play alone\nWolf: \(player1Score)\nOther 3 best: \(min(player2Score, player3Score, player4Score))"
                
            case "Bingo Bango Bongo":
                simulationResult = "Bingo: First on green (1 pt)\nBango: Closest to pin (1 pt)\nBongo: First in hole (1 pt)\nTotal: 3 points available"
                
            default:
                simulationResult = "Format scoring calculated based on \(format.name) rules"
            }
            
            showResult = true
        }
    }
    
    func calculateStablefordPoints(score: Int, par: Int) -> Int {
        let differential = score - par
        switch differential {
        case ...(-2): return 4 // Eagle or better
        case -1: return 3 // Birdie
        case 0: return 2 // Par
        case 1: return 1 // Bogey
        default: return 0 // Double bogey or worse
        }
    }
}

struct StrategyTab: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(Array(format.strategy.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text(tip)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
            }
        }
    }
}


// MARK: - Golf Format Data Model

struct GolfFormat: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let description: String
    let tagline: String
    let players: String
    let difficulty: String
    let isTeamFormat: Bool
    let overview: [String]
    let rules: [String]
    let strategy: [String]
    let hasDiagramSlides: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(icon)
    }
    
    static func == (lhs: GolfFormat, rhs: GolfFormat) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    static let allFormats: [GolfFormat] = [
        GolfFormat(
            name: "Scramble",
            icon: "flag.fill",
            color: .green,
            description: "All players tee off, choose the best shot, and everyone plays from there",
            tagline: "Teamwork at its finest",
            players: "2-4 per team",
            difficulty: "Beginner",
            isTeamFormat: true,
            overview: [
                "Perfect for charity tournaments and casual play",
                "Reduces pressure on individual players",
                "Speeds up play significantly"
            ],
            rules: [
                "All team members tee off on each hole",
                "The team selects the best shot",
                "All players hit from that spot",
                "Continue until the ball is holed",
                "Record one score for the team"
            ],
            strategy: [
                "Put your longest hitter first to set up good drives",
                "Save your best putter for last",
                "Use each player's strengths strategically"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Best Ball",
            icon: "star.fill",
            color: .blue,
            description: "Each player plays their own ball, lowest score counts for the team",
            tagline: "Individual play, team scoring",
            players: "2-4 per team",
            difficulty: "Intermediate",
            isTeamFormat: true,
            overview: [
                "Each player plays their own ball throughout",
                "Only the best score counts for the team",
                "Great for mixed skill levels"
            ],
            rules: [
                "Everyone plays their own ball",
                "Record each player's score",
                "Use the lowest score for the team",
                "Can be played as stroke or match play",
                "Handicaps often used for fairness"
            ],
            strategy: [
                "Play your normal game",
                "Take calculated risks when partner is safe",
                "Support teammates mentally"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Stableford",
            icon: "chart.bar.fill",
            color: .purple,
            description: "Point-based scoring system that rewards aggressive play",
            tagline: "Points for performance",
            players: "Any",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Earn points based on your score relative to par",
                "Higher points for better scores",
                "No penalty for very bad holes"
            ],
            rules: [
                "Eagle or better: 4+ points",
                "Birdie: 3 points",
                "Par: 2 points",
                "Bogey: 1 point",
                "Double bogey or worse: 0 points"
            ],
            strategy: [
                "Be aggressive on scoring opportunities",
                "Pick up if you can't score points",
                "Focus on consistency over hero shots"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Alternate Shot",
            icon: "arrow.triangle.swap",
            color: .orange,
            description: "Partners alternate hitting the same ball",
            tagline: "True partnership golf",
            players: "2 per team",
            difficulty: "Advanced",
            isTeamFormat: true,
            overview: [
                "Ultimate team format requiring strategy",
                "Partners must work together completely",
                "Tests both skill and partnership"
            ],
            rules: [
                "Partners alternate shots throughout the hole",
                "Player A tees off odd holes, Player B even holes",
                "Continue alternating until holed",
                "Penalties don't change the rotation",
                "One score per team per hole"
            ],
            strategy: [
                "Play to each other's strengths",
                "Leave comfortable shots for partner",
                "Communicate constantly"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Match Play",
            icon: "person.2.fill",
            color: .red,
            description: "Hole-by-hole competition between players or teams",
            tagline: "Win the hole, win the match",
            players: "2 or 4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Win individual holes rather than total strokes",
                "Creates exciting head-to-head competition",
                "Used in Ryder Cup and major championships"
            ],
            rules: [
                "Lowest score on each hole wins that hole",
                "Track holes won/lost, not total score",
                "Match ends when one side is up more holes than remain",
                "Halved holes when scores are tied",
                "Can concede holes or putts"
            ],
            strategy: [
                "Play the opponent, not the course",
                "Take risks when down",
                "Apply pressure when ahead"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Skins",
            icon: "dollarsign.circle.fill",
            color: .yellow,
            description: "Each hole has a value, lowest score wins the skin",
            tagline: "Winner takes all",
            players: "2-4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Each hole is worth a 'skin' or prize",
                "Ties carry value to next hole",
                "Creates dramatic moments"
            ],
            rules: [
                "Each hole has a predetermined value",
                "Lowest score wins the skin",
                "Ties carry over to next hole",
                "Last hole must have a winner",
                "Can play with or without handicaps"
            ],
            strategy: [
                "Be aggressive when skins accumulate",
                "Protect your position when leading a hole",
                "Know when to take risks"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Nassau",
            icon: "divide.circle.fill",
            color: .indigo,
            description: "Three separate bets: front 9, back 9, and overall 18",
            tagline: "Three matches in one",
            players: "2 or 4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Most popular betting game in golf",
                "Three separate competitions",
                "Often includes 'presses' for comebacks"
            ],
            rules: [
                "Three separate matches: Front 9, Back 9, Total 18",
                "Each match worth equal value",
                "Can be stroke or match play",
                "Presses can double the bet",
                "Automatic press when 2 down"
            ],
            strategy: [
                "Manage three matches simultaneously",
                "Know when to press",
                "Stay focused after winning/losing nine"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Vegas",
            icon: "dice.fill",
            color: .pink,
            description: "Team scores combined to create two-digit numbers",
            tagline: "High stakes team golf",
            players: "4 (2 teams)",
            difficulty: "Advanced",
            isTeamFormat: true,
            overview: [
                "Unique scoring creates big swings",
                "Combines both players' scores",
                "Birdies can flip opponent's score"
            ],
            rules: [
                "Combine team scores (lower first) to make 2-digit number",
                "Example: 4 and 5 becomes 45",
                "Lowest team number wins the difference in points",
                "Birdie flips opponent's score (4,5 becomes 54)",
                "Usually played for money per point"
            ],
            strategy: [
                "Avoid big numbers at all costs",
                "Coordinate risk-taking with partner",
                "Birdies are extremely valuable"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Wolf",
            icon: "moon.fill",
            color: .gray,
            description: "Rotating captain chooses partners or plays alone",
            tagline: "Strategy and partnerships",
            players: "4",
            difficulty: "Advanced",
            isTeamFormat: false,
            overview: [
                "Different partnerships every hole",
                "Captain ('Wolf') makes strategic choices",
                "Can go alone for double points"
            ],
            rules: [
                "Rotation determines the 'Wolf' each hole",
                "Wolf tees off last and chooses partner or goes alone",
                "Must choose partner immediately after their tee shot",
                "Lone Wolf plays against other three for double points",
                "Better ball format for teams"
            ],
            strategy: [
                "Choose partners based on the hole layout",
                "Go alone when you have an advantage",
                "Save 'Lone Wolf' for your best holes"
            ],
            hasDiagramSlides: true
        ),
        GolfFormat(
            name: "Bingo Bango Bongo",
            icon: "target",
            color: .teal,
            description: "Points for first on green, closest to pin, first in hole",
            tagline: "Three ways to score",
            players: "2-4",
            difficulty: "Beginner",
            isTeamFormat: false,
            overview: [
                "Rewards different achievements each hole",
                "Gives everyone a chance to score",
                "Great for mixed skill levels"
            ],
            rules: [
                "Bingo: First ball on the green (1 point)",
                "Bango: Closest to pin once all on green (1 point)",
                "Bongo: First ball in the hole (1 point)",
                "Strict order of play must be followed",
                "Furthest from hole plays first"
            ],
            strategy: [
                "Play quickly when you're furthest away",
                "Focus on accuracy over distance",
                "Take advantage of scoring opportunities"
            ],
            hasDiagramSlides: true
        )
    ]
}