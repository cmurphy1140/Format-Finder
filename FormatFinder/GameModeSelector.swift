import SwiftUI

// MARK: - Golf Formats Data

let golfFormats = [
    GolfFormat(
        name: "Scramble",
        category: "Tournament",
        players: "2-4 players (teams)",
        difficulty: "Easy",
        description: "All team members tee off, select the best shot, and all play from there. Repeat until the ball is holed.",
        howToPlay: [
            "All players tee off",
            "Team selects the best shot",
            "All players play from that spot",
            "Repeat until the ball is holed"
        ],
        example: "Team of 4: All tee off, choose John's drive. All hit from John's ball position. Choose Mary's approach. All putt from Mary's spot."
    ),
    GolfFormat(
        name: "Best Ball",
        category: "Tournament",
        players: "2-4 players (teams)",
        difficulty: "Easy",
        description: "Each player plays their own ball. The lowest score among teammates counts as the team score for each hole.",
        howToPlay: [
            "Everyone plays their own ball",
            "Record each player's score",
            "Use the best score for the team",
            "Total best scores for final"
        ],
        example: "Hole 1: Player A scores 4, Player B scores 5. Team score is 4."
    ),
    GolfFormat(
        name: "Match Play",
        category: "Tournament",
        players: "2 or 4 players",
        difficulty: "Medium",
        description: "Players compete hole-by-hole. The player with the lowest score wins the hole. Most holes won wins the match.",
        howToPlay: [
            "Play each hole as a separate competition",
            "Lowest score wins the hole",
            "Ties result in a 'halved' hole",
            "Player with most holes wins"
        ],
        example: "Player A wins 3 holes, Player B wins 2, 4 holes halved. Player A wins 3&2."
    ),
    GolfFormat(
        name: "Skins",
        category: "Betting",
        players: "2-4 players",
        difficulty: "Medium",
        description: "Each hole has a value. The player with the lowest score wins the 'skin'. Ties carry over value to next hole.",
        howToPlay: [
            "Assign a value to each hole",
            "Lowest score wins the skin",
            "Ties carry value to next hole",
            "Settle up after the round"
        ],
        example: "Hole 1 ($10): Players tie, carries to Hole 2 ($20 total). Player C wins with birdie, wins $20."
    ),
    GolfFormat(
        name: "Stableford",
        category: "Tournament",
        players: "Any number",
        difficulty: "Easy",
        description: "Point-based scoring where players earn points based on their score relative to par. Higher points win.",
        howToPlay: [
            "Eagle or better: 4 points",
            "Birdie: 3 points",
            "Par: 2 points",
            "Bogey: 1 point",
            "Double bogey+: 0 points"
        ],
        example: "Par 4: Score 3 (birdie) = 3 points. Score 4 (par) = 2 points."
    ),
    GolfFormat(
        name: "Four-Ball",
        category: "Tournament",
        players: "4 players (2 teams)",
        difficulty: "Easy",
        description: "Two teams of two. Each player plays own ball. Best score from each team counts. Used in Ryder Cup.",
        howToPlay: [
            "Form two teams of two",
            "Everyone plays own ball",
            "Best score from each team counts",
            "Lower team score wins hole"
        ],
        example: "Team 1: Player A (4), Player B (5) = 4. Team 2: Player C (3), Player D (6) = 3. Team 2 wins."
    ),
    GolfFormat(
        name: "Alternate Shot",
        category: "Tournament",
        players: "4 players (2 teams)",
        difficulty: "Hard",
        description: "Partners alternate hitting the same ball. One tees off on odd holes, the other on even holes.",
        howToPlay: [
            "Partners share one ball",
            "Alternate shots until holed",
            "Player A tees off odd holes",
            "Player B tees off even holes"
        ],
        example: "Hole 1: Player A drives, B hits approach, A chips, B putts."
    ),
    GolfFormat(
        name: "Nassau",
        category: "Betting",
        players: "2 or 4 players",
        difficulty: "Medium",
        description: "Three separate bets: front 9, back 9, and overall 18. Common in match play format.",
        howToPlay: [
            "Three separate matches",
            "Front 9 winner",
            "Back 9 winner",
            "Overall 18 winner"
        ],
        example: "Player wins front 9 (+$10), loses back 9 (-$10), wins overall (+$10) = +$10 total."
    ),
    GolfFormat(
        name: "Bingo Bango Bongo",
        category: "Betting",
        players: "2-4 players",
        difficulty: "Easy",
        description: "Three points per hole: first on green (bingo), closest to pin (bango), first in hole (bongo).",
        howToPlay: [
            "Bingo: First on the green",
            "Bango: Closest to pin once all on green",
            "Bongo: First in the hole",
            "Furthest away plays first"
        ],
        example: "Player A reaches green first (+1), Player B is closest (+1), Player A holes out first (+1)."
    ),
    GolfFormat(
        name: "Wolf",
        category: "Betting",
        players: "4 players",
        difficulty: "Hard",
        description: "Rotating 'Wolf' chooses to play alone or with a partner after seeing tee shots. Complex betting game.",
        howToPlay: [
            "Rotate who is Wolf each hole",
            "Wolf tees off last",
            "Wolf chooses partner or goes alone",
            "Points vary based on format"
        ],
        example: "Player A is Wolf, sees drives, picks Player C as partner. They win 2 points each."
    ),
    GolfFormat(
        name: "Chapman",
        category: "Tournament",
        players: "4 players (2 teams)",
        difficulty: "Medium",
        description: "Both partners tee off, play each other's ball for second shot, then select one ball to alternate into the hole.",
        howToPlay: [
            "Both partners tee off",
            "Switch balls for second shot",
            "Select best ball after second shot",
            "Alternate shots until holed"
        ],
        example: "Both tee off, A plays B's drive, B plays A's drive, choose best, alternate in."
    ),
    GolfFormat(
        name: "Vegas",
        category: "Betting",
        players: "4 players (2 teams)",
        difficulty: "Hard",
        description: "Team scores combine into two-digit numbers. Lower number goes first. Birdies can flip opponent's score.",
        howToPlay: [
            "Teams of two",
            "Combine scores (lower first)",
            "Team A: 4,5 = 45",
            "Birdies flip opponent's score"
        ],
        example: "Team A scores 4 and 5 = 45. Team B scores 3 and 6 = 36. Team B wins 9 points."
    )
]

// MARK: - Game Mode Selector

struct GameModeSelectorView: View {
    @State private var selectedFormat: GolfFormat? = nil
    @State private var showConfiguration = false
    @State private var gameConfiguration = GameConfiguration()
    @State private var showScorecard = false
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 46/255, green: 125/255, blue: 50/255),
                        Color(red: 102/255, green: 187/255, blue: 106/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Select Game Mode")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Choose your format and start playing")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(golfFormats) { format in
                                GameModeCard(
                                    format: format,
                                    isSelected: selectedFormat?.id == format.id,
                                    action: {
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
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
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
                    ScorecardContainerView(
                        format: format,
                        configuration: gameConfiguration
                    )
                }
            }
        }
    }
}

// MARK: - Game Mode Card

struct GameModeCard: View {
    let format: GolfFormat
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: getFormatIcon(format.name))
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if format.type == "Team" {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Text(format.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(format.players)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    DifficultyIndicator(difficulty: format.difficulty)
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isSelected ? 
                                [Color.blue, Color.purple] : 
                                [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(isSelected ? 0.5 : 0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
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

// MARK: - Difficulty Indicator

struct DifficultyIndicator: View {
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
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(getDotColor(index))
                    .frame(width: 8, height: 8)
            }
            Text(difficulty)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    func getDotColor(_ index: Int) -> Color {
        switch difficulty {
        case "Easy":
            return index == 0 ? color : Color.white.opacity(0.3)
        case "Medium":
            return index <= 1 ? color : Color.white.opacity(0.3)
        case "Hard":
            return color
        default:
            return Color.white.opacity(0.3)
        }
    }
}

// MARK: - Game Configuration

struct GameConfiguration {
    var selectedFormat: GolfFormat?
    var players: [Player] = [
        Player(name: "Player 1", handicap: 0),
        Player(name: "Player 2", handicap: 0),
        Player(name: "Player 3", handicap: 0),
        Player(name: "Player 4", handicap: 0)
    ]
    var numberOfHoles: Int = 18
    var courseRating: Double = 72.0
    var slopeRating: Int = 130
    var teams: [Team] = []
    var startingHole: Int = 1
    var teeBox: String = "White"
    var scoringRules: ScoringRules = ScoringRules()
}

struct Player: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var handicap: Int
    var isActive: Bool = true
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}

struct Team: Identifiable {
    let id = UUID()
    var name: String
    var players: [Player]
}

struct ScoringRules {
    // Format-specific rules
    var skinsValidation: Bool = false
    var nassauPresses: Bool = true
    var stablefordPoints: StablefordScoring = .standard
    var wolfBlindOption: Bool = true
    var vegasFlipRule: Bool = true
}

enum StablefordScoring {
    case standard  // Eagle: 4, Birdie: 3, Par: 2, Bogey: 1
    case modified  // Eagle: 5, Birdie: 3, Par: 2, Bogey: 1
    case aggressive // Eagle: 5, Birdie: 4, Par: 2, Bogey: 0
}

// MARK: - Game Configuration View

struct GameConfigurationView: View {
    @Binding var configuration: GameConfiguration
    let onStart: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var activePlayerCount = 4
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 240/255, green: 248/255, blue: 240/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Format Info
                        if let format = configuration.selectedFormat {
                            FormatInfoCard(format: format)
                        }
                        
                        // Players Configuration
                        PlayersConfigSection(
                            players: $configuration.players,
                            activeCount: $activePlayerCount,
                            format: configuration.selectedFormat
                        )
                        
                        // Course Settings
                        CourseSettingsSection(
                            holes: $configuration.numberOfHoles,
                            courseRating: $configuration.courseRating,
                            slopeRating: $configuration.slopeRating,
                            teeBox: $configuration.teeBox
                        )
                        
                        // Format-Specific Settings
                        if let format = configuration.selectedFormat {
                            FormatSpecificSettings(
                                format: format,
                                rules: $configuration.scoringRules
                            )
                        }
                        
                        // Start Button
                        Button(action: onStart) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Game")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color(red: 46/255, green: 125/255, blue: 50/255)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Game Setup")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Configuration Sections

struct FormatInfoCard: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(format.name)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            Text(format.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            HStack {
                Label(format.players, systemImage: "person.2")
                Spacer()
                Label(format.type, systemImage: "flag")
                Spacer()
                Label(format.difficulty, systemImage: "speedometer")
            }
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PlayersConfigSection: View {
    @Binding var players: [Player]
    @Binding var activeCount: Int
    let format: GolfFormat?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("Players")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // Player count selector
            HStack {
                Text("Number of Players:")
                Spacer()
                Picker("Players", selection: $activeCount) {
                    ForEach(2...4, id: \.self) { count in
                        Text("\(count)").tag(count)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            // Player details
            ForEach(0..<activeCount, id: \.self) { index in
                HStack {
                    TextField("Player \(index + 1)", text: $players[index].name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Text("HCP:")
                        TextField("0", value: $players[index].handicap, format: .number)
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CourseSettingsSection: View {
    @Binding var holes: Int
    @Binding var courseRating: Double
    @Binding var slopeRating: Int
    @Binding var teeBox: String
    
    let teeOptions = ["Black", "Blue", "White", "Gold", "Red"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.green)
                Text("Course Settings")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            HStack {
                Text("Holes:")
                Spacer()
                Picker("Holes", selection: $holes) {
                    Text("9").tag(9)
                    Text("18").tag(18)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            HStack {
                Text("Tee Box:")
                Spacer()
                Picker("Tees", selection: $teeBox) {
                    ForEach(teeOptions, id: \.self) { tee in
                        Text(tee).tag(tee)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                Text("Course Rating:")
                Spacer()
                TextField("72.0", value: $courseRating, format: .number)
                    .frame(width: 80)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            
            HStack {
                Text("Slope Rating:")
                Spacer()
                TextField("130", value: $slopeRating, format: .number)
                    .frame(width: 80)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct FormatSpecificSettings: View {
    let format: GolfFormat
    @Binding var rules: ScoringRules
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.orange)
                Text("\(format.name) Settings")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // Format-specific options
            switch format.name {
            case "Skins":
                Toggle("Validation Rule", isOn: $rules.skinsValidation)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
            case "Nassau":
                Toggle("Allow Presses", isOn: $rules.nassauPresses)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
            case "Stableford":
                VStack(alignment: .leading, spacing: 10) {
                    Text("Scoring System:")
                        .font(.system(size: 14, weight: .medium))
                    
                    Picker("Scoring", selection: $rules.stablefordPoints) {
                        Text("Standard").tag(StablefordScoring.standard)
                        Text("Modified").tag(StablefordScoring.modified)
                        Text("Aggressive").tag(StablefordScoring.aggressive)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
            case "Wolf":
                Toggle("Blind Wolf Option", isOn: $rules.wolfBlindOption)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
            case "Vegas":
                Toggle("Birdie Flip Rule", isOn: $rules.vegasFlipRule)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
            default:
                Text("No additional settings for this format")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}