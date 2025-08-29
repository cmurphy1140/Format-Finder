import SwiftUI

// MARK: - Main Format Grid View with Apple Styling
struct AppleStyledFormatGrid: View {
    let formats: [GolfFormat]
    @State private var selectedFormat: GolfFormat?
    @State private var showingScorecard = false
    @State private var showingInteractiveGuide = false
    @State private var expandedFormat: GolfFormat?
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animationNamespace
    
    var filteredFormats: [GolfFormat] {
        if searchText.isEmpty {
            return formats
        }
        return formats.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Apple-style background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        headerSection
                            .padding(.top, -8)
                        
                        // Search Bar
                        searchBar
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        
                        // Quick Actions
                        quickActionsSection
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        
                        // Format Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredFormats) { format in
                                AppleFormatCard(
                                    format: format,
                                    isExpanded: expandedFormat?.id == format.id,
                                    namespace: animationNamespace,
                                    onTap: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            if expandedFormat?.id == format.id {
                                                expandedFormat = nil
                                            } else {
                                                expandedFormat = format
                                            }
                                        }
                                    },
                                    onInteractiveGuide: {
                                        selectedFormat = format
                                        showingInteractiveGuide = true
                                    },
                                    onPlay: {
                                        selectedFormat = format
                                        showingScorecard = true
                                    }
                                )
                                .matchedGeometryEffect(id: format.id, in: animationNamespace)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingScorecard) {
                if let format = selectedFormat {
                    NavigationStack {
                        FormatSpecificScorecard(format: format)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showingScorecard = false
                                    }
                                    .fontWeight(.semibold)
                                }
                            }
                    }
                }
            }
            .sheet(isPresented: $showingInteractiveGuide) {
                if let format = selectedFormat {
                    NavigationStack {
                        InteractiveFormatGuide(format: format)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showingInteractiveGuide = false
                                    }
                                    .fontWeight(.semibold)
                                }
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Golf Formats")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(formats.count) formats available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Profile Button
                Button(action: {}) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
        .background(
            Color(UIColor.systemBackground)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search formats", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionChip(
                    icon: "star.fill",
                    title: "Popular",
                    color: .orange
                )
                
                QuickActionChip(
                    icon: "person.2.fill",
                    title: "Team",
                    color: .blue
                )
                
                QuickActionChip(
                    icon: "flag.fill",
                    title: "Tournament",
                    color: .green
                )
                
                QuickActionChip(
                    icon: "dollarsign.circle.fill",
                    title: "Betting",
                    color: .purple
                )
                
                QuickActionChip(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Scoring",
                    color: .red
                )
            }
        }
    }
}

// MARK: - Apple-Styled Format Card
struct AppleFormatCard: View {
    let format: GolfFormat
    let isExpanded: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    let onInteractiveGuide: () -> Void
    let onPlay: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Header
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Icon and Title
                    HStack(spacing: 12) {
                        Image(systemName: getFormatIcon(format.name))
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                LinearGradient(
                                    colors: getFormatGradient(format.name),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(format.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                Text(format.players)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick Description
                    Text(quickDescription(for: format))
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
            }
            .buttonStyle(CardButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Detailed Description
                        VStack(alignment: .leading, spacing: 8) {
                            Label("How to Play", systemImage: "info.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(format.description)
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Key Rules
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Key Rules", systemImage: "list.bullet")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ForEach(Array(format.rules.prefix(3).enumerated()), id: \.offset) { index, rule in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                    
                                    Text(rule)
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        
                        // Difficulty Badge
                        HStack(spacing: 8) {
                            Label("Difficulty", systemImage: "speedometer")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            DifficultyIndicator(difficulty: format.difficulty)
                            
                            Spacer()
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: onInteractiveGuide) {
                                Label("Learn", systemImage: "play.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: onPlay) {
                                Label("Play", systemImage: "flag.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(16)
                }
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    func getFormatIcon(_ name: String) -> String {
        switch name {
        case "Scramble": return "arrow.triangle.merge"
        case "Best Ball": return "star.circle.fill"
        case "Match Play": return "person.2.square.stack.fill"
        case "Skins": return "dollarsign.circle.fill"
        case "Stableford": return "chart.line.uptrend.xyaxis"
        case "Four-Ball": return "circle.grid.2x2.fill"
        case "Alternate Shot": return "arrow.left.arrow.right.circle.fill"
        case "Nassau": return "flag.2.crossed.fill"
        case "Wolf": return "pawprint.fill"
        case "Vegas": return "die.face.6.fill"
        case "Chapman": return "arrow.triangle.branch"
        case "Shamble": return "arrow.triangle.turn.up.right.diamond.fill"
        case "Pinehurst": return "pine.cone.fill"
        case "Greensome": return "leaf.fill"
        case "Bloodsome": return "drop.fill"
        case "Bingo Bango Bongo": return "target"
        case "Quota": return "gauge"
        case "Texas Scramble": return "star.square.fill"
        default: return "flag.fill"
        }
    }
    
    func getFormatGradient(_ name: String) -> [Color] {
        switch name {
        case "Scramble": return [Color.blue, Color.cyan]
        case "Best Ball": return [Color.orange, Color.yellow]
        case "Match Play": return [Color.purple, Color.pink]
        case "Skins": return [Color.green, Color.mint]
        case "Stableford": return [Color.red, Color.orange]
        case "Nassau": return [Color.indigo, Color.blue]
        case "Wolf": return [Color.brown, Color.orange]
        default: return [Color.accentColor, Color.accentColor.opacity(0.7)]
        }
    }
    
    func quickDescription(for format: GolfFormat) -> String {
        switch format.name {
        case "Scramble": return "All players tee off, team plays the best shot. Perfect for mixed skill levels."
        case "Best Ball": return "Each player plays their own ball, team takes the best score per hole."
        case "Alternate Shot": return "Partners alternate hitting the same ball throughout the hole."
        case "Four-Ball": return "Partners each play their own ball, better score counts for the team."
        case "Shamble": return "Scramble off the tee, then everyone plays their own ball to the hole."
        case "Chapman": return "Both players tee off, switch balls for second shot, then alternate."
        case "Pinehurst": return "Both tee off, switch for second shot, then play alternate shot."
        case "Greensome": return "Both players tee off, choose one ball, then play alternate shot."
        case "Bloodsome": return "Opposing team chooses which of your tee shots you must play."
        case "Match Play": return "Win individual holes rather than counting total strokes."
        case "Skins": return "Each hole has a value that goes to the outright winner. Ties carry over."
        case "Nassau": return "Three separate bets: front nine, back nine, and overall 18 holes."
        case "Wolf": return "Rotating captain chooses to partner or play alone against others."
        case "Bingo Bango Bongo": return "Points for first on green, closest to pin, and first in hole."
        case "Stableford": return "Point-based scoring rewards aggressive play and good holes."
        case "Medal Play": return "Traditional stroke play where lowest total score wins."
        case "Vegas": return "Team scores are combined into a two-digit number for betting."
        case "Quota": return "Earn points based on your handicap and try to exceed your quota."
        case "Texas Scramble": return "Scramble format with minimum drive requirements per player."
        case "Florida Scramble": return "Scramble where the player whose shot is used sits out next shot."
        case "Las Vegas": return "Combine team scores with lower score first for betting action."
        case "Rabbit": return "Hold the 'rabbit' by winning holes to score points."
        default: return format.description.prefix(80) + "..."
        }
    }
}

// MARK: - Quick Action Chip
struct QuickActionChip: View {
    let icon: String
    let title: String
    let color: Color
    @State private var isSelected = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isSelected.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Difficulty Indicator
struct DifficultyIndicator: View {
    let difficulty: String
    
    var difficultyLevel: Int {
        switch difficulty {
        case "Easy": return 1
        case "Medium": return 2
        case "Hard": return 3
        default: return 2
        }
    }
    
    var difficultyColor: Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < difficultyLevel ? difficultyColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            
            Text(difficulty)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(difficultyColor)
        }
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Apple-Styled Scorecard Components
struct AppleStyledScorecard: View {
    let format: GolfFormat
    @StateObject private var gameStore = GameStore()
    @State private var currentHole = 1
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Hole Navigation
                        HoleNavigationView(currentHole: $currentHole)
                        
                        // Score Entry Cards
                        VStack(spacing: 16) {
                            ForEach(0..<4) { playerIndex in
                                PlayerScoreCard(
                                    playerNumber: playerIndex + 1,
                                    playerName: "Player \(playerIndex + 1)",
                                    currentHole: currentHole,
                                    format: format
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Format-Specific Info
                        if format.name == "Skins" {
                            SkinsInfoCard(currentHole: currentHole)
                                .padding(.horizontal)
                        } else if format.name == "Match Play" {
                            MatchPlayStatusCard()
                                .padding(.horizontal)
                        } else if format.name == "Nassau" {
                            NassauBetsCard()
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(format.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Hole Navigation View
struct HoleNavigationView: View {
    @Binding var currentHole: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    if currentHole > 1 {
                        withAnimation {
                            currentHole -= 1
                        }
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(currentHole == 1)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Hole")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(currentHole)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button(action: {
                    if currentHole < 18 {
                        withAnimation {
                            currentHole += 1
                        }
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(currentHole == 18)
            }
            
            // Hole dots indicator
            HStack(spacing: 6) {
                ForEach(1...18, id: \.self) { hole in
                    Circle()
                        .fill(hole == currentHole ? Color.accentColor : 
                              hole < currentHole ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: hole == currentHole ? 8 : 6, 
                               height: hole == currentHole ? 8 : 6)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Player Score Card
struct PlayerScoreCard: View {
    let playerNumber: Int
    let playerName: String
    let currentHole: Int
    let format: GolfFormat
    @State private var score = ""
    @FocusState private var isFocused: Bool
    
    var playerColor: Color {
        [Color.blue, Color.green, Color.orange, Color.purple][playerNumber - 1]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Player Avatar
            ZStack {
                Circle()
                    .fill(playerColor.gradient)
                    .frame(width: 44, height: 44)
                
                Text("\(playerNumber)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playerName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Par 4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score Input
            HStack(spacing: 8) {
                Button(action: {
                    if let currentScore = Int(score), currentScore > 1 {
                        score = "\(currentScore - 1)"
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                }
                
                TextField("0", text: $score)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .fontWeight(.semibold)
                    .frame(width: 50)
                    .padding(8)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
                    .focused($isFocused)
                
                Button(action: {
                    let currentScore = Int(score) ?? 0
                    score = "\(currentScore + 1)"
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Format-Specific Cards
struct SkinsInfoCard: View {
    let currentHole: Int
    @State private var skinValue = 10
    @State private var carryOver = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Skins Information", systemImage: "dollarsign.circle.fill")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Skin Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(skinValue * (carryOver ? 2 : 1))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Toggle("Carry Over", isOn: $carryOver)
                    .labelsHidden()
                
                if carryOver {
                    Label("Carried", systemImage: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MatchPlayStatusCard: View {
    @State private var matchStatus = "All Square"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Match Status", systemImage: "person.2.square.stack.fill")
                .font(.headline)
            
            HStack {
                Text(matchStatus)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(["2 UP", "1 UP", "AS", "1 DN", "2 DN"], id: \.self) { status in
                        Button(action: {
                            withAnimation {
                                matchStatus = status == "AS" ? "All Square" : status
                            }
                        }) {
                            Text(status)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(matchStatus.contains(status) || (status == "AS" && matchStatus == "All Square") ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(matchStatus.contains(status) || (status == "AS" && matchStatus == "All Square") ? Color.accentColor : Color.gray.opacity(0.2))
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct NassauBetsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nassau Bets", systemImage: "flag.2.crossed.fill")
                .font(.headline)
            
            HStack(spacing: 12) {
                BetSegment(title: "Front 9", value: "$10", color: .blue)
                BetSegment(title: "Back 9", value: "$10", color: .green)
                BetSegment(title: "Overall", value: "$10", color: .purple)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BetSegment: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    AppleStyledFormatGrid(formats: GolfFormat.allFormats)
}