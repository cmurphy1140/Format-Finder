import SwiftUI

struct ModernFormatGrid: View {
    let formats: [GolfFormat]
    @State private var selectedFormat: GolfFormat?
    @State private var showingScorecard = false
    @State private var showingInteractiveGuide = false
    @State private var expandedFormat: GolfFormat?
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title Card
                    VStack(spacing: 12) {
                        Text("Golf Format Finder")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Master every golf format with clear explanations and interactive guides")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 24)
                    
                    // Format Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(formats) { format in
                            ModernFormatCard(
                                format: format,
                                isExpanded: expandedFormat?.id == format.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.4)) {
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
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingScorecard) {
            if let format = selectedFormat {
                FormatSpecificScorecard(format: format)
            }
        }
        .sheet(isPresented: $showingInteractiveGuide) {
            if let format = selectedFormat {
                InteractiveFormatGuide(format: format)
            }
        }
    }
}

struct ModernFormatCard: View {
    let format: GolfFormat
    let isExpanded: Bool
    let onTap: () -> Void
    let onInteractiveGuide: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text(format.icon)
                    .font(.system(size: 28))
                
                Text(format.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(quickDescription(for: format))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                    
                    // Comprehensive Explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How It Works")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(format.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Step by Step
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rules & Steps")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            ForEach(Array(format.rules.prefix(3).enumerated()), id: \.offset) { index, rule in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 20, alignment: .leading)
                                    
                                    Text(rule)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: onInteractiveGuide) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.circle")
                                    .font(.system(size: 16))
                                Text("Interactive Guide")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Button(action: onPlay) {
                            HStack(spacing: 6) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 16))
                                Text("Play")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // More Details Button (when collapsed)
            if !isExpanded {
                Button(action: onTap) {
                    HStack {
                        Text("More Details")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                }
            } else {
                Button(action: onTap) {
                    HStack {
                        Text("Less Details")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    func quickDescription(for format: GolfFormat) -> String {
        switch format.name {
        case "Scramble": return "All tee off, play best shot as a team"
        case "Best Ball": return "Play own ball, take team's best score"
        case "Alternate Shot": return "Partners alternate hitting same ball"
        case "Four-Ball": return "Partners play own balls, best score counts"
        case "Shamble": return "Scramble off tee, then play own ball"
        case "Chapman": return "Both tee off, switch balls, then alternate"
        case "Pinehurst": return "Both tee off, switch for second, then alternate"
        case "Greensome": return "Both tee off, pick one ball, alternate shots"
        case "Bloodsome": return "Opposing team chooses which tee shot you play"
        case "Match Play": return "Win holes instead of counting total strokes"
        case "Skins": return "Each hole worth money, must win outright"
        case "Nassau": return "Three bets: front 9, back 9, and overall 18"
        case "Wolf": return "Rotating captain chooses partner or plays alone"
        case "Bingo Bango Bongo": return "Points for first on, closest, first in"
        case "Stableford": return "Points based scoring, rewards good holes"
        case "Medal Play": return "Traditional stroke play, lowest total wins"
        case "Vegas": return "Team scores combined for two-digit number"
        case "Quota": return "Points based on handicap, exceed your quota"
        case "Texas Scramble": return "Scramble with minimum drives per player"
        case "Florida Scramble": return "Scramble but player whose shot is used sits out"
        case "Las Vegas": return "Combine team scores, lower score goes first"
        case "Rabbit": return "Hold the 'rabbit' by winning holes to score"
        default: return format.description.prefix(60) + "..."
        }
    }
}

// Interactive Guide View
struct InteractiveFormatGuide: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if format.name == "Scramble" || format.name == "Match Play" || 
                   format.name == "Skins" || format.name == "Stableford" {
                    // Use the IntuitiveDemonstration for supported formats
                    IntuitiveFormatDemonstration(format: format)
                } else {
                    // Use stick figure animations for other formats
                    StickFigureGolfAnimation(format: format)
                }
            }
            .navigationTitle("\(format.name) Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Format-Specific Scorecard
struct FormatSpecificScorecard: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    @StateObject private var gameStore = GameStore()
    
    var body: some View {
        NavigationView {
            VStack {
                switch format.name {
                case "Match Play":
                    MatchPlayScorecard(gameStore: gameStore)
                case "Skins":
                    SkinsScorecard(gameStore: gameStore)
                case "Stableford":
                    StablefordScorecard(gameStore: gameStore)
                case "Nassau":
                    NassauScorecard(gameStore: gameStore)
                case "Wolf":
                    WolfScorecard(gameStore: gameStore)
                case "Vegas", "Las Vegas":
                    VegasScorecard(gameStore: gameStore)
                default:
                    StandardScorecard(gameStore: gameStore, format: format)
                }
            }
            .navigationTitle("\(format.name) Scorecard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupGame()
        }
    }
    
    func setupGame() {
        // Initialize game with format-specific settings
        let configuration = GameConfiguration(
            selectedFormat: format,
            players: [
                Player(name: "Player 1", handicap: 0),
                Player(name: "Player 2", handicap: 0),
                Player(name: "Player 3", handicap: 0),
                Player(name: "Player 4", handicap: 0)
            ],
            numberOfHoles: 18
        )
        
        // Map format name to FormatType enum
        let formatType: FormatType = {
            switch format.name {
            case "Scramble": return .scramble
            case "Best Ball": return .bestBall
            case "Match Play": return .matchPlay
            case "Skins": return .skins
            case "Stableford": return .stableford
            case "Four-Ball": return .fourBall
            case "Alternate Shot": return .alternateShot
            case "Nassau": return .nassau
            case "Wolf": return .wolf
            default: return .scramble // Use scramble as default
            }
        }()
        
        gameStore.dispatch(.startRound(
            format: formatType,
            players: configuration.players.map { PlayerIdentifier(id: $0.id, name: $0.name, handicap: $0.handicap) },
            configuration: configuration
        ))
    }
}

// Individual Format Scorecards
struct MatchPlayScorecard: View {
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Match Status
                HStack {
                    VStack(alignment: .leading) {
                        Text("Match Status")
                            .font(.headline)
                        Text("All Square")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Holes Played")
                            .font(.caption)
                        Text("0 / 18")
                            .font(.title3)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Hole-by-hole grid
                ForEach(1...18, id: \.self) { hole in
                    HoleMatchPlayCard(hole: hole, gameStore: gameStore)
                }
            }
            .padding()
        }
    }
}

struct HoleMatchPlayCard: View {
    let hole: Int
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Hole \(hole)")
                    .font(.headline)
                Spacer()
                Text("Par 4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                ForEach(0..<2) { player in
                    VStack {
                        Text("P\(player + 1)")
                            .font(.caption)
                        TextField("Score", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("Winner")
                        .font(.caption)
                    Text("-")
                        .frame(width: 60, height: 40)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SkinsScorecard: View {
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Skins Value Display
                HStack {
                    Text("Current Skin Value")
                        .font(.headline)
                    Spacer()
                    Text("$10")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Hole-by-hole tracking
                ForEach(1...18, id: \.self) { hole in
                    HoleSkinCard(hole: hole, gameStore: gameStore)
                }
            }
            .padding()
        }
    }
}

struct HoleSkinCard: View {
    let hole: Int
    @ObservedObject var gameStore: GameStore
    @State private var skinWinner: String = "None"
    @State private var carryOver = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Hole \(hole)")
                    .font(.headline)
                Spacer()
                Toggle("Carry Over", isOn: $carryOver)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
            
            HStack(spacing: 12) {
                ForEach(0..<4) { player in
                    VStack {
                        Text("P\(player + 1)")
                            .font(.caption)
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("Skin")
                        .font(.caption)
                    Text(skinWinner)
                        .font(.caption2)
                        .frame(width: 50, height: 35)
                        .background(carryOver ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StablefordScorecard: View {
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Points System Reference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stableford Points")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Eagle: 4", systemImage: "4.circle.fill")
                                .font(.caption)
                            Label("Birdie: 3", systemImage: "3.circle.fill")
                                .font(.caption)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Par: 2", systemImage: "2.circle.fill")
                                .font(.caption)
                            Label("Bogey: 1", systemImage: "1.circle.fill")
                                .font(.caption)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Double+: 0", systemImage: "0.circle.fill")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Hole-by-hole with point calculation
                ForEach(1...18, id: \.self) { hole in
                    HoleStablefordCard(hole: hole, gameStore: gameStore)
                }
            }
            .padding()
        }
    }
}

struct HoleStablefordCard: View {
    let hole: Int
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Hole \(hole) - Par 4")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                ForEach(0..<4) { player in
                    VStack(spacing: 4) {
                        Text("P\(player + 1)")
                            .font(.caption)
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        Text("0 pts")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NassauScorecard: View {
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Nassau Bets Display
                HStack(spacing: 16) {
                    VStack {
                        Text("Front 9")
                            .font(.caption)
                        Text("$10")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    VStack {
                        Text("Back 9")
                            .font(.caption)
                        Text("$10")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    VStack {
                        Text("Overall")
                            .font(.caption)
                        Text("$10")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Standard scorecard with Nassau tracking
                ForEach(1...18, id: \.self) { hole in
                    HoleNassauCard(hole: hole, gameStore: gameStore)
                }
            }
            .padding()
        }
    }
}

struct HoleNassauCard: View {
    let hole: Int
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Hole \(hole)")
                    .font(.headline)
                Spacer()
                if hole == 9 {
                    Text("Front 9 Complete")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if hole == 18 {
                    Text("Match Complete")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            
            HStack(spacing: 12) {
                ForEach(0..<4) { player in
                    VStack {
                        Text("P\(player + 1)")
                            .font(.caption)
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WolfScorecard: View {
    @ObservedObject var gameStore: GameStore
    @State private var currentWolf = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Wolf Rotation Display
                HStack {
                    Text("Current Wolf")
                        .font(.headline)
                    Spacer()
                    Text("Player \(currentWolf + 1)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Hole-by-hole with wolf tracking
                ForEach(1...18, id: \.self) { hole in
                    HoleWolfCard(hole: hole, wolf: (hole - 1) % 4, gameStore: gameStore)
                }
            }
            .padding()
        }
    }
}

struct HoleWolfCard: View {
    let hole: Int
    let wolf: Int
    @ObservedObject var gameStore: GameStore
    @State private var wolfChoice = "Undecided"
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Hole \(hole)")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("P\(wolf + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            
            // Wolf decision
            HStack {
                Text("Wolf plays:")
                    .font(.caption)
                Picker("", selection: $wolfChoice) {
                    Text("Alone").tag("Alone")
                    Text("With P2").tag("With P2")
                    Text("With P3").tag("With P3")
                    Text("With P4").tag("With P4")
                }
                .pickerStyle(SegmentedPickerStyle())
                .scaleEffect(0.9)
            }
            
            HStack(spacing: 12) {
                ForEach(0..<4) { player in
                    VStack {
                        Text("P\(player + 1)")
                            .font(.caption)
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(player == wolf ? Color.orange.opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct VegasScorecard: View {
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Team Display
                HStack(spacing: 16) {
                    VStack {
                        Text("Team 1")
                            .font(.headline)
                        Text("P1 & P3")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    
                    VStack {
                        Text("Team 2")
                            .font(.headline)
                        Text("P2 & P4")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Hole-by-hole with Vegas scoring
                ForEach(1...18, id: \.self) { hole in
                    HoleVegasCard(hole: hole, gameStore: gameStore)
                }
            }
            .padding()
        }
    }
}

struct HoleVegasCard: View {
    let hole: Int
    @ObservedObject var gameStore: GameStore
    @State private var team1Score = "--"
    @State private var team2Score = "--"
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Hole \(hole)")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Team 1
                VStack(spacing: 8) {
                    Text("Team 1")
                        .font(.caption)
                    HStack(spacing: 8) {
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    Text(team1Score)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Team 2
                VStack(spacing: 8) {
                    Text("Team 2")
                        .font(.caption)
                    HStack(spacing: 8) {
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    Text(team2Score)
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StandardScorecard: View {
    @ObservedObject var gameStore: GameStore
    let format: GolfFormat
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(format.name) Scorecard")
                    .font(.headline)
                
                // Basic hole-by-hole scorecard
                ForEach(1...18, id: \.self) { hole in
                    HoleStandardCard(hole: hole, gameStore: gameStore)
                }
            }
            .padding()
        }
    }
}

struct HoleStandardCard: View {
    let hole: Int
    @ObservedObject var gameStore: GameStore
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Hole \(hole)")
                    .font(.headline)
                Spacer()
                Text("Par 4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                ForEach(0..<4) { player in
                    VStack {
                        Text("P\(player + 1)")
                            .font(.caption)
                        TextField("", text: .constant(""))
                            .multilineTextAlignment(.center)
                            .frame(width: 35, height: 35)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ModernFormatGrid(formats: GolfFormat.allFormats)
}