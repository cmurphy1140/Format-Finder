import SwiftUI

// MARK: - Smart Caddie Feature

struct SmartCaddieView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var playerHandicaps: [String: Double] = [:]
    @State private var recommendedFormat: GolfFormat? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Handicap Calculator
            HandicapCalculatorView()
                .tabItem {
                    Label("Handicap", systemImage: "percent")
                }
                .tag(0)
            
            // Format Recommender
            FormatRecommenderView()
                .tabItem {
                    Label("Recommend", systemImage: "wand.and.stars")
                }
                .tag(1)
            
            // Live Scoring
            LiveScoringView()
                .tabItem {
                    Label("Score", systemImage: "pencil.and.list.clipboard")
                }
                .tag(2)
            
            // Group Manager
            GroupManagerView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
                .tag(3)
        }
        .accentColor(colorScheme == .dark ? .green : .blue)
    }
}

// MARK: - Handicap Calculator

struct HandicapCalculatorView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var courseRating: String = "72.0"
    @State private var slopeRating: String = "130"
    @State private var handicapIndex: String = ""
    @State private var calculatedHandicap: Int? = nil
    @State private var formatAdjustments: [String: String] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Handicap Calculator")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                VStack(alignment: .leading, spacing: 15) {
                    InputField(
                        title: "Handicap Index",
                        value: $handicapIndex,
                        placeholder: "Enter your index",
                        keyboardType: .decimalPad
                    )
                    
                    InputField(
                        title: "Course Rating",
                        value: $courseRating,
                        placeholder: "72.0",
                        keyboardType: .decimalPad
                    )
                    
                    InputField(
                        title: "Slope Rating",
                        value: $slopeRating,
                        placeholder: "130",
                        keyboardType: .numberPad
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                )
                
                Button(action: calculateHandicap) {
                    Text("Calculate Course Handicap")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
                
                if let handicap = calculatedHandicap {
                    VStack(spacing: 15) {
                        Text("Your Course Handicap")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("\(handicap)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.green)
                        
                        Divider()
                        
                        Text("Format-Specific Adjustments")
                            .font(.system(size: 18, weight: .semibold))
                        
                        VStack(spacing: 10) {
                            FormatHandicapRow(format: "Scramble", adjustment: "25% of combined")
                            FormatHandicapRow(format: "Best Ball", adjustment: "90% of handicap")
                            FormatHandicapRow(format: "Chapman", adjustment: "60% of combined")
                            FormatHandicapRow(format: "Stableford", adjustment: "Full handicap")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.green.opacity(0.1))
                    )
                }
            }
            .padding()
        }
    }
    
    func calculateHandicap() {
        guard let index = Double(handicapIndex),
              let slope = Double(slopeRating) else { return }
        
        let courseHandicap = Int(round(index * slope / 113))
        withAnimation {
            calculatedHandicap = courseHandicap
        }
    }
}

// MARK: - Format Recommender

struct FormatRecommenderView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var groupSize = 4
    @State private var skillLevel = "Mixed"
    @State private var timeAvailable = "Full Round"
    @State private var competitiveness = 5
    @State private var recommendedFormats: [GolfFormat] = []
    @State private var showingRecommendations = false
    
    let skillLevels = ["Beginner", "Intermediate", "Advanced", "Mixed"]
    let timeOptions = ["Quick 9", "Full Round", "Tournament"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Format Recommender")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("Answer a few questions to find the perfect format")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                VStack(spacing: 20) {
                    // Group Size
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Group Size")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Picker("Group Size", selection: $groupSize) {
                            ForEach(2...8, id: \.self) { size in
                                Text("\(size) Players").tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Skill Level
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Skill Level")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Picker("Skill Level", selection: $skillLevel) {
                            ForEach(skillLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Time Available
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Time Available")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Picker("Time", selection: $timeAvailable) {
                            ForEach(timeOptions, id: \.self) { time in
                                Text(time).tag(time)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Competitiveness
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Competitiveness")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Spacer()
                            
                            Text("\(competitiveness)/10")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(competitiveness) },
                            set: { competitiveness = Int($0) }
                        ), in: 1...10, step: 1)
                        .accentColor(.green)
                        
                        HStack {
                            Text("Casual")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Competitive")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                )
                
                Button(action: generateRecommendations) {
                    Label("Get Recommendations", systemImage: "wand.and.stars")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
                
                if showingRecommendations && !recommendedFormats.isEmpty {
                    VStack(spacing: 15) {
                        Text("Recommended Formats")
                            .font(.system(size: 20, weight: .bold))
                        
                        ForEach(recommendedFormats.prefix(3), id: \.name) { format in
                            RecommendedFormatCard(format: format)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    func generateRecommendations() {
        // Logic to recommend formats based on inputs
        withAnimation {
            recommendedFormats = getRecommendedFormats()
            showingRecommendations = true
        }
    }
    
    func getRecommendedFormats() -> [GolfFormat] {
        var formats: [GolfFormat] = []
        let allFormats = GolfFormat.allFormats
        
        // Sample recommendation logic
        if groupSize == 4 {
            if let scramble = allFormats.first(where: { $0.name == "Scramble" }) {
                formats.append(scramble)
            }
            
            if competitiveness > 7 {
                if let nassau = allFormats.first(where: { $0.name == "Nassau" }) {
                    formats.append(nassau)
                }
            }
        }
        
        if skillLevel == "Mixed" {
            if let bingoBangoBongo = allFormats.first(where: { $0.name == "Bingo Bango Bongo" }) {
                formats.append(bingoBangoBongo)
            }
        }
        
        // If no specific recommendations, return top 3 formats
        if formats.isEmpty {
            formats = Array(allFormats.prefix(3))
        }
        
        return formats
    }
}

// MARK: - Live Scoring

struct LiveScoringView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedFormat = "Scramble"
    @State private var currentHole = 1
    @State private var scores: [Int: [String: Int]] = [:]
    @State private var players = ["Player 1", "Player 2", "Player 3", "Player 4"]
    @State private var isGameActive = false
    
    let formats = ["Scramble", "Best Ball", "Skins", "Nassau", "Stableford"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Live Scoring")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if !isGameActive {
                    // Setup View
                    VStack(spacing: 20) {
                        Picker("Select Format", selection: $selectedFormat) {
                            ForEach(formats, id: \.self) { format in
                                Text(format).tag(format)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Players")
                                .font(.system(size: 16, weight: .semibold))
                            
                            ForEach(0..<4) { index in
                                TextField("Player \(index + 1)", text: $players[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                        
                        Button(action: startGame) {
                            Text("Start Game")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    // Active Game View
                    VStack(spacing: 20) {
                        HStack {
                            Text("Hole \(currentHole)")
                                .font(.system(size: 24, weight: .bold))
                            
                            Spacer()
                            
                            Text(selectedFormat)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        // Score Input
                        VStack(spacing: 15) {
                            ForEach(players, id: \.self) { player in
                                HStack {
                                    Text(player)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 10) {
                                        Button("-") {
                                            adjustScore(for: player, by: -1)
                                        }
                                        .buttonStyle(ScoreButtonStyle(color: .red))
                                        
                                        Text("\(scores[currentHole]?[player] ?? 0)")
                                            .font(.system(size: 20, weight: .bold))
                                            .frame(width: 40)
                                        
                                        Button("+") {
                                            adjustScore(for: player, by: 1)
                                        }
                                        .buttonStyle(ScoreButtonStyle(color: .green))
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                                )
                            }
                        }
                        
                        // Navigation
                        HStack(spacing: 20) {
                            Button(action: previousHole) {
                                Label("Previous", systemImage: "chevron.left")
                            }
                            .disabled(currentHole == 1)
                            
                            Spacer()
                            
                            if currentHole < 18 {
                                Button(action: nextHole) {
                                    Label("Next Hole", systemImage: "chevron.right")
                                }
                            } else {
                                Button(action: finishGame) {
                                    Text("Finish Game")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        
                        // Leaderboard
                        LeaderboardView(scores: scores, players: players, format: selectedFormat)
                    }
                }
            }
            .padding()
        }
    }
    
    func startGame() {
        isGameActive = true
        scores[1] = Dictionary(uniqueKeysWithValues: players.map { ($0, 0) })
    }
    
    func adjustScore(for player: String, by value: Int) {
        if scores[currentHole] == nil {
            scores[currentHole] = Dictionary(uniqueKeysWithValues: players.map { ($0, 0) })
        }
        scores[currentHole]?[player, default: 0] += value
        if scores[currentHole]?[player] ?? 0 < 0 {
            scores[currentHole]?[player] = 0
        }
    }
    
    func nextHole() {
        if currentHole < 18 {
            currentHole += 1
            if scores[currentHole] == nil {
                scores[currentHole] = Dictionary(uniqueKeysWithValues: players.map { ($0, 0) })
            }
        }
    }
    
    func previousHole() {
        if currentHole > 1 {
            currentHole -= 1
        }
    }
    
    func finishGame() {
        // Show final results
        isGameActive = false
    }
}

// MARK: - Group Manager

struct GroupManagerView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var groups: [GolfGroup] = []
    @State private var showingCreateGroup = false
    @State private var newGroupName = ""
    @State private var newGroupPlayers: [String] = ["", "", "", ""]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if groups.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.3")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Groups Yet")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            Text("Create a group to track your regular golf partners")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { showingCreateGroup = true }) {
                                Label("Create Group", systemImage: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.top, 50)
                    } else {
                        ForEach(groups) { group in
                            GroupCard(group: group)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Golf Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(groups: $groups, isPresented: $showingCreateGroup)
            }
        }
    }
}

// MARK: - Helper Views

struct InputField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $value)
                .keyboardType(keyboardType)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct FormatHandicapRow: View {
    let format: String
    let adjustment: String
    
    var body: some View {
        HStack {
            Text(format)
                .font(.system(size: 15))
            
            Spacer()
            
            Text(adjustment)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
}

struct RecommendedFormatCard: View {
    let format: GolfFormat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(format.name)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Label("Perfect Match", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            Text(format.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            HStack {
                Label(format.players, systemImage: "person.2")
                Spacer()
                Text(format.difficulty)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getDifficultyColor(format.difficulty).opacity(0.2))
                    .foregroundColor(getDifficultyColor(format.difficulty))
                    .cornerRadius(5)
            }
            .font(.system(size: 12))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
        )
    }
    
    func getDifficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
}

struct ScoreButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 35, height: 35)
            .background(color)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct LeaderboardView: View {
    let scores: [Int: [String: Int]]
    let players: [String]
    let format: String
    @Environment(\.colorScheme) var colorScheme
    
    var totalScores: [(String, Int)] {
        var totals: [String: Int] = [:]
        for player in players {
            totals[player] = 0
            for (_, holeScores) in scores {
                totals[player]? += holeScores[player] ?? 0
            }
        }
        return totals.sorted { $0.value < $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leaderboard")
                .font(.system(size: 18, weight: .bold))
            
            ForEach(Array(totalScores.enumerated()), id: \.element.0) { index, score in
                HStack {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 20)
                    
                    Text(score.0)
                        .font(.system(size: 15))
                    
                    Spacer()
                    
                    Text("\(score.1)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(index == 0 ? .green : colorScheme == .dark ? .white : .black)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
        )
    }
}

struct GolfGroup: Identifiable {
    let id = UUID()
    let name: String
    let players: [String]
    let createdDate: Date
}

struct GroupCard: View {
    let group: GolfGroup
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(group.name)
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Image(systemName: "person.\(group.players.count).fill")
                    .foregroundColor(.blue)
            }
            
            HStack {
                ForEach(group.players.filter { !$0.isEmpty }, id: \.self) { player in
                    Text(player)
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                }
            }
            
            Text("Created \(group.createdDate, style: .date)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
        )
    }
}

struct CreateGroupView: View {
    @Binding var groups: [GolfGroup]
    @Binding var isPresented: Bool
    @State private var groupName = ""
    @State private var players = ["", "", "", ""]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Name")) {
                    TextField("Sunday Squad", text: $groupName)
                }
                
                Section(header: Text("Players")) {
                    ForEach(0..<4) { index in
                        TextField("Player \(index + 1)", text: $players[index])
                    }
                }
            }
            .navigationTitle("Create Group")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newGroup = GolfGroup(
                            name: groupName,
                            players: players,
                            createdDate: Date()
                        )
                        groups.append(newGroup)
                        isPresented = false
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Theme Manager

struct ThemeManager {
    static func textColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .black
    }
    
    static func backgroundColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color.white
    }
    
    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }
    
    static func accentColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .green : .blue
    }
}