import SwiftUI

// MARK: - Four-Ball Scorecard

struct FourBallScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var teamScores: [UUID: Int] = [:]
    @State private var bestBallScores: [String: Int] = ["Team 1": 0, "Team 2": 0]
    @State private var selectedBalls: [String: UUID] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hole Header
                HoleHeaderView(hole: hole, par: 4, yards: 385)
                
                // Team 1 Scores
                TeamScorecardSection(
                    teamName: "Team 1",
                    players: Array(configuration.players.prefix(2)),
                    hole: hole,
                    gameState: gameState,
                    selectedBall: selectedBalls["Team 1"],
                    onBallSelected: { playerId in
                        selectedBalls["Team 1"] = playerId
                        updateBestBall(team: "Team 1", playerId: playerId)
                    }
                )
                
                // Team 2 Scores
                TeamScorecardSection(
                    teamName: "Team 2",
                    players: Array(configuration.players.suffix(2)),
                    hole: hole,
                    gameState: gameState,
                    selectedBall: selectedBalls["Team 2"],
                    onBallSelected: { playerId in
                        selectedBalls["Team 2"] = playerId
                        updateBestBall(team: "Team 2", playerId: playerId)
                    }
                )
                
                // Match Status
                FourBallMatchStatus(
                    team1Score: bestBallScores["Team 1"] ?? 0,
                    team2Score: bestBallScores["Team 2"] ?? 0,
                    hole: hole
                )
                
                // Format Rules
                FormatRulesCard(
                    title: "Four-Ball Rules",
                    rules: [
                        "Each player plays their own ball",
                        "Best score from each team counts",
                        "Teams compete against each other",
                        "Handicaps can be applied"
                    ]
                )
            }
            .padding()
        }
    }
    
    private func updateBestBall(team: String, playerId: UUID) {
        let score = gameState.getScore(hole: hole, player: playerId)
        bestBallScores[team] = score
    }
}

struct TeamScorecardSection: View {
    let teamName: String
    let players: [Player]
    let hole: Int
    let gameState: GameState
    let selectedBall: UUID?
    let onBallSelected: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(teamName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            ForEach(players.filter { $0.isActive }) { player in
                HStack {
                    // Ball Selection
                    Button(action: { onBallSelected(player.id) }) {
                        Image(systemName: selectedBall == player.id ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedBall == player.id ? .blue : .gray)
                            .font(.system(size: 20))
                    }
                    
                    Text(player.name)
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Score Input
                    ScoreInputView(
                        score: Binding(
                            get: { gameState.getScore(hole: hole, player: player.id) },
                            set: { gameState.setScore(hole: hole, player: player.id, score: $0) }
                        ),
                        par: 4
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedBall == player.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct FourBallMatchStatus: View {
    let team1Score: Int
    let team2Score: Int
    let hole: Int
    
    var matchStatus: String {
        if team1Score == 0 || team2Score == 0 {
            return "Enter scores to see match status"
        }
        if team1Score < team2Score {
            return "Team 1 wins hole"
        } else if team2Score < team1Score {
            return "Team 2 wins hole"
        } else {
            return "Hole halved"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Hole \(hole) Result")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(matchStatus)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Alternate Shot Scorecard

struct AlternateShotScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var currentStriker: [String: UUID] = [:]
    @State private var teamScores: [String: Int] = ["Team 1": 0, "Team 2": 0]
    @State private var shotLog: [ShotEntry] = []
    
    struct ShotEntry {
        let shotNumber: Int
        let team: String
        let player: UUID
        let location: String
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hole Header
                HoleHeaderView(hole: hole, par: 4, yards: 385)
                
                // Team 1 Alternate Shot
                AlternateShotTeamSection(
                    teamName: "Team 1",
                    players: Array(configuration.players.prefix(2)),
                    hole: hole,
                    gameState: gameState,
                    currentStriker: currentStriker["Team 1"],
                    onStrikerChange: { playerId in
                        currentStriker["Team 1"] = playerId
                        recordShot(team: "Team 1", player: playerId)
                    }
                )
                
                // Team 2 Alternate Shot
                AlternateShotTeamSection(
                    teamName: "Team 2",
                    players: Array(configuration.players.suffix(2)),
                    hole: hole,
                    gameState: gameState,
                    currentStriker: currentStriker["Team 2"],
                    onStrikerChange: { playerId in
                        currentStriker["Team 2"] = playerId
                        recordShot(team: "Team 2", player: playerId)
                    }
                )
                
                // Shot Log
                if !shotLog.isEmpty {
                    ShotLogView(shotLog: shotLog)
                }
                
                // Format Rules
                FormatRulesCard(
                    title: "Alternate Shot Rules",
                    rules: [
                        "Partners alternate hitting shots",
                        "One player tees off on odd holes",
                        "Other player tees off on even holes",
                        "Continue alternating until hole is complete"
                    ]
                )
            }
            .padding()
        }
    }
    
    private func recordShot(team: String, player: UUID) {
        let entry = ShotEntry(
            shotNumber: shotLog.count + 1,
            team: team,
            player: player,
            location: getShotLocation(shotNumber: shotLog.count + 1)
        )
        shotLog.append(entry)
    }
    
    private func getShotLocation(shotNumber: Int) -> String {
        switch shotNumber {
        case 1: return "Tee"
        case 2: return "Fairway"
        case 3: return "Approach"
        default: return "Green"
        }
    }
}

struct AlternateShotTeamSection: View {
    let teamName: String
    let players: [Player]
    let hole: Int
    let gameState: GameState
    let currentStriker: UUID?
    let onStrikerChange: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(teamName)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                // Team Score
                HStack(spacing: 4) {
                    Text("Score:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    ScoreInputView(
                        score: Binding(
                            get: { gameState.getScore(hole: hole, player: players[0].id) },
                            set: { score in
                                players.forEach { player in
                                    gameState.setScore(hole: hole, player: player.id, score: score)
                                }
                            }
                        ),
                        par: 4
                    )
                }
            }
            
            // Shot Order Indicator
            HStack(spacing: 16) {
                ForEach(players.filter { $0.isActive }) { player in
                    Button(action: { onStrikerChange(player.id) }) {
                        VStack(spacing: 4) {
                            Image(systemName: currentStriker == player.id ? "person.fill" : "person")
                                .font(.system(size: 24))
                                .foregroundColor(currentStriker == player.id ? .blue : .gray)
                            
                            Text(player.name)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            
                            if hole % 2 == 1 && players[0].id == player.id {
                                Text("Tee Off")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            } else if hole % 2 == 0 && players[1].id == player.id {
                                Text("Tee Off")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(currentStriker == player.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        )
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

struct ShotLogView: View {
    let shotLog: [AlternateShotScorecardView.ShotEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shot Log")
                .font(.system(size: 16, weight: .semibold))
            
            ForEach(shotLog.indices, id: \.self) { index in
                HStack {
                    Text("#\(shotLog[index].shotNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                    
                    Text(shotLog[index].team)
                        .font(.system(size: 14))
                        .frame(width: 60, alignment: .leading)
                    
                    Text(shotLog[index].location)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Bingo Bango Bongo Scorecard

struct BingoBangoBongoScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var bingoWinner: UUID?
    @State private var bangoWinner: UUID?
    @State private var bongoWinner: UUID?
    @State private var pointTotals: [UUID: Int] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hole Header
                HoleHeaderView(hole: hole, par: 4, yards: 385)
                
                // Point Awards Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Point Awards - Hole \(hole)")
                        .font(.system(size: 20, weight: .bold))
                    
                    // Bingo (First on Green)
                    PointAwardRow(
                        title: "BINGO - First on Green",
                        icon: "target",
                        players: configuration.players.filter { $0.isActive },
                        winner: bingoWinner,
                        onSelect: { playerId in
                            bingoWinner = playerId
                            awardPoint(to: playerId, type: "bingo")
                        }
                    )
                    
                    // Bango (Closest to Pin)
                    PointAwardRow(
                        title: "BANGO - Closest to Pin",
                        icon: "flag.fill",
                        players: configuration.players.filter { $0.isActive },
                        winner: bangoWinner,
                        onSelect: { playerId in
                            bangoWinner = playerId
                            awardPoint(to: playerId, type: "bango")
                        }
                    )
                    
                    // Bongo (First in Hole)
                    PointAwardRow(
                        title: "BONGO - First in Hole",
                        icon: "circle.circle.fill",
                        players: configuration.players.filter { $0.isActive },
                        winner: bongoWinner,
                        onSelect: { playerId in
                            bongoWinner = playerId
                            awardPoint(to: playerId, type: "bongo")
                        }
                    )
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Player Scores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scores")
                        .font(.system(size: 18, weight: .semibold))
                    
                    ForEach(configuration.players.filter { $0.isActive }) { player in
                        HStack {
                            Text(player.name)
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            ScoreInputView(
                                score: Binding(
                                    get: { gameState.getScore(hole: hole, player: player.id) },
                                    set: { gameState.setScore(hole: hole, player: player.id, score: $0) }
                                ),
                                par: 4
                            )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Point Standings
                PointStandingsCard(
                    players: configuration.players.filter { $0.isActive },
                    pointTotals: pointTotals
                )
                
                // Format Rules
                FormatRulesCard(
                    title: "Bingo Bango Bongo Rules",
                    rules: [
                        "BINGO: First ball on the green (1 point)",
                        "BANGO: Closest to pin once all on green (1 point)",
                        "BONGO: First ball in the hole (1 point)",
                        "Three points available per hole",
                        "Player farthest away plays first"
                    ]
                )
            }
            .padding()
        }
    }
    
    private func awardPoint(to playerId: UUID, type: String) {
        pointTotals[playerId] = (pointTotals[playerId] ?? 0) + 1
    }
}

struct PointAwardRow: View {
    let title: String
    let icon: String
    let players: [Player]
    let winner: UUID?
    let onSelect: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(players) { player in
                        Button(action: { onSelect(player.id) }) {
                            Text(player.name)
                                .font(.system(size: 14, weight: winner == player.id ? .semibold : .regular))
                                .foregroundColor(winner == player.id ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(winner == player.id ? Color.blue : Color.gray.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PointStandingsCard: View {
    let players: [Player]
    let pointTotals: [UUID: Int]
    
    var sortedPlayers: [Player] {
        players.sorted { (pointTotals[$0.id] ?? 0) > (pointTotals[$1.id] ?? 0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Point Standings")
                .font(.system(size: 18, weight: .semibold))
            
            ForEach(sortedPlayers) { player in
                HStack {
                    Text(player.name)
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    Text("\(pointTotals[player.id] ?? 0) pts")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Chapman Scorecard

struct ChapmanScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var teeShots: [String: [UUID: Bool]] = [:]
    @State private var selectedDrives: [String: UUID] = [:]
    @State private var alternateSequence: [String: [UUID]] = [:]
    @State private var teamScores: [String: Int] = ["Team 1": 0, "Team 2": 0]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hole Header
                HoleHeaderView(hole: hole, par: 4, yards: 385)
                
                // Chapman Format Phases
                ChapmanPhaseIndicator()
                
                // Team 1 Chapman Play
                ChapmanTeamSection(
                    teamName: "Team 1",
                    players: Array(configuration.players.prefix(2)),
                    hole: hole,
                    gameState: gameState,
                    teeShots: teeShots["Team 1"] ?? [:],
                    selectedDrive: selectedDrives["Team 1"],
                    onTeeShot: { playerId in
                        if teeShots["Team 1"] == nil {
                            teeShots["Team 1"] = [:]
                        }
                        teeShots["Team 1"]?[playerId] = true
                    },
                    onDriveSelection: { playerId in
                        selectedDrives["Team 1"] = playerId
                    }
                )
                
                // Team 2 Chapman Play
                ChapmanTeamSection(
                    teamName: "Team 2",
                    players: Array(configuration.players.suffix(2)),
                    hole: hole,
                    gameState: gameState,
                    teeShots: teeShots["Team 2"] ?? [:],
                    selectedDrive: selectedDrives["Team 2"],
                    onTeeShot: { playerId in
                        if teeShots["Team 2"] == nil {
                            teeShots["Team 2"] = [:]
                        }
                        teeShots["Team 2"]?[playerId] = true
                    },
                    onDriveSelection: { playerId in
                        selectedDrives["Team 2"] = playerId
                    }
                )
                
                // Match Status
                ChapmanMatchStatus(
                    team1Score: teamScores["Team 1"] ?? 0,
                    team2Score: teamScores["Team 2"] ?? 0
                )
                
                // Format Rules
                FormatRulesCard(
                    title: "Chapman System Rules",
                    rules: [
                        "Both partners tee off",
                        "Select best drive",
                        "Both hit second shots from selected ball",
                        "Choose best second shot",
                        "Alternate shots until hole is complete"
                    ]
                )
            }
            .padding()
        }
    }
}

struct ChapmanPhaseIndicator: View {
    @State private var currentPhase = 0
    
    let phases = [
        ("1. Both Tee Off", "person.2.fill"),
        ("2. Select Best Drive", "checkmark.circle.fill"),
        ("3. Both Play 2nd", "arrow.triangle.swap"),
        ("4. Select Best 2nd", "star.fill"),
        ("5. Alternate to Finish", "arrow.left.arrow.right")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Chapman System Phases")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 4) {
                ForEach(0..<phases.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        Image(systemName: phases[index].1)
                            .font(.system(size: 16))
                            .foregroundColor(currentPhase >= index ? .blue : .gray)
                        
                        Text(phases[index].0)
                            .font(.system(size: 9))
                            .multilineTextAlignment(.center)
                            .foregroundColor(currentPhase >= index ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(currentPhase == index ? Color.blue.opacity(0.1) : Color.clear)
                    )
                    .onTapGesture {
                        currentPhase = index
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

struct ChapmanTeamSection: View {
    let teamName: String
    let players: [Player]
    let hole: Int
    let gameState: GameState
    let teeShots: [UUID: Bool]
    let selectedDrive: UUID?
    let onTeeShot: (UUID) -> Void
    let onDriveSelection: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(teamName)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                // Team Score
                ScoreInputView(
                    score: Binding(
                        get: { gameState.getScore(hole: hole, player: players[0].id) },
                        set: { score in
                            players.forEach { player in
                                gameState.setScore(hole: hole, player: player.id, score: score)
                            }
                        }
                    ),
                    par: 4
                )
            }
            
            // Phase 1: Tee Shots
            VStack(alignment: .leading, spacing: 8) {
                Text("Tee Shots")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(players.filter { $0.isActive }) { player in
                        Button(action: { onTeeShot(player.id) }) {
                            HStack(spacing: 4) {
                                Image(systemName: teeShots[player.id] == true ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(teeShots[player.id] == true ? .green : .gray)
                                Text(player.name)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(teeShots[player.id] == true ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                            )
                        }
                    }
                }
            }
            
            // Phase 2: Drive Selection
            if teeShots.count == 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Best Drive")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(players.filter { $0.isActive }) { player in
                            Button(action: { onDriveSelection(player.id) }) {
                                Text(player.name + "'s drive")
                                    .font(.system(size: 14, weight: selectedDrive == player.id ? .semibold : .regular))
                                    .foregroundColor(selectedDrive == player.id ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedDrive == player.id ? Color.blue : Color.gray.opacity(0.1))
                                    )
                            }
                        }
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

struct ChapmanMatchStatus: View {
    let team1Score: Int
    let team2Score: Int
    
    var status: String {
        if team1Score == 0 || team2Score == 0 {
            return "Enter scores to see status"
        }
        if team1Score < team2Score {
            return "Team 1 leads"
        } else if team2Score < team1Score {
            return "Team 2 leads"
        } else {
            return "Teams tied"
        }
    }
    
    var body: some View {
        HStack {
            VStack {
                Text("Team 1")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("\(team1Score)")
                    .font(.system(size: 24, weight: .bold))
            }
            
            Spacer()
            
            Text(status)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack {
                Text("Team 2")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("\(team2Score)")
                    .font(.system(size: 24, weight: .bold))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.indigo.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct HoleHeaderView: View {
    let hole: Int
    let par: Int
    let yards: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Hole \(hole)")
                    .font(.system(size: 24, weight: .bold))
                Text("\(yards) yards")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Par")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text("\(par)")
                    .font(.system(size: 24, weight: .bold))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ScoreInputView: View {
    @Binding var score: Int
    let par: Int
    
    var scoreColor: Color {
        if score == 0 { return .gray }
        if score < par { return .red }
        if score == par { return .black }
        return .blue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { if score > 0 { score -= 1 } }) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            Text("\(score == 0 ? "-" : "\(score)")")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(scoreColor)
                .frame(width: 30)
            
            Button(action: { score += 1 }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
        }
    }
}

struct FormatRulesCard: View {
    let title: String
    let rules: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(rules, id: \.self) { rule in
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.blue)
                        Text(rule)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Generic Scorecard (Fallback)

struct GenericScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleHeaderView(hole: hole, par: 4, yards: 385)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Player Scores")
                        .font(.system(size: 18, weight: .semibold))
                    
                    ForEach(configuration.players.filter { $0.isActive }) { player in
                        HStack {
                            Text(player.name)
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            ScoreInputView(
                                score: Binding(
                                    get: { gameState.getScore(hole: hole, player: player.id) },
                                    set: { gameState.setScore(hole: hole, player: player.id, score: $0) }
                                ),
                                par: 4
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding()
        }
    }
}

// MARK: - Stats Cards

struct OverallScoreCard: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Scores")
                .font(.system(size: 20, weight: .bold))
            
            ForEach(configuration.players.filter { $0.isActive }) { player in
                HStack {
                    Text(player.name)
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    Text("\(calculateTotalScore(for: player.id))")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func calculateTotalScore(for playerId: UUID) -> Int {
        var total = 0
        for hole in 1...configuration.numberOfHoles {
            total += gameState.getScore(hole: hole, player: playerId)
        }
        return total
    }
}

struct PlayerStatsCard: View {
    let player: Player
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(player.name)
                .font(.system(size: 18, weight: .semibold))
            
            HStack {
                StatItem(label: "Score", value: "0")
                Spacer()
                StatItem(label: "Putts", value: "0")
                Spacer()
                StatItem(label: "FIR", value: "0%")
                Spacer()
                StatItem(label: "GIR", value: "0%")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

struct SkinsStatsCard: View {
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skins Summary")
                .font(.system(size: 18, weight: .semibold))
            
            // Skins won display
            Text("Implementation needed")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct NassauStatsCard: View {
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nassau Matches")
                .font(.system(size: 18, weight: .semibold))
            
            // Nassau match status
            Text("Implementation needed")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}