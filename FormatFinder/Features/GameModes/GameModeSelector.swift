import SwiftUI

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
                AppColors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Select Game Mode")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Choose your format and start playing")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary)
                    
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
                GameConfigurationModalView(
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
                        .foregroundColor(isSelected ? .white : AppColors.primaryGreen)
                    
                    Spacer()
                    
                    if format.isTeamFormat {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : AppColors.textSecondary)
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
                                [AppColors.primaryGreen, AppColors.lightGreen] : 
                                [Color.white, Color.white.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppColors.cardShadow, radius: 6, x: 0, y: 3)
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

// MARK: - Difficulty Indicator (removed duplicate - using GolfFormatHomeView implementation)

// MARK: - Game Configuration

struct GameConfiguration: Equatable {
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

struct Team: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var players: [Player]
}

struct ScoringRules: Equatable {
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

// MARK: - Game Configuration Modal View

struct GameConfigurationModalView: View {
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
                Label(format.isTeamFormat ? "Team" : "Individual", systemImage: "flag")
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