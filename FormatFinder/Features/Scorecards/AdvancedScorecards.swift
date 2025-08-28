import SwiftUI

// MARK: - Stableford Scorecard

struct StablefordScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var playerScores: [UUID: Int] = [:]
    @State private var playerPoints: [UUID: Int] = [:]
    
    var activePlayers: [Player] {
        configuration.players.filter { $0.isActive }
    }
    
    var par: Int { GolfConstants.ParManagement.parForHole(hole) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: par, yards: GolfConstants.ParManagement.service.getYardageForHole(hole))
                
                // Stableford Points Reference
                StablefordPointsReference(scoringSystem: configuration.scoringRules.stablefordPoints)
                
                // Player Scores and Points
                VStack(alignment: .leading, spacing: 15) {
                    Text("Scores & Points")
                        .font(.system(size: 20, weight: .bold))
                    
                    ForEach(activePlayers) { player in
                        StablefordPlayerRow(
                            player: player,
                            score: playerScores[player.id] ?? 0,
                            points: playerPoints[player.id] ?? 0,
                            par: par,
                            scoringSystem: configuration.scoringRules.stablefordPoints,
                            onScoreChange: { newScore in
                                playerScores[player.id] = newScore
                                playerPoints[player.id] = calculateStablefordPoints(
                                    score: newScore,
                                    par: par,
                                    system: configuration.scoringRules.stablefordPoints
                                )
                            }
                        )
                    }
                }
                .padding()
                
                // Total Points Display
                PointsTotalCard(players: activePlayers, points: playerPoints)
                
                Button(action: saveHoleScore) {
                    Text("Save Hole \(hole)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
    
    func calculateStablefordPoints(score: Int, par: Int, system: StablefordScoring) -> Int {
        guard score > 0 else { return 0 }
        
        let diff = score - par
        
        switch system {
        case .standard:
            switch diff {
            case ..<(-1): return 4  // Eagle or better
            case -1: return 3       // Birdie
            case 0: return 2        // Par
            case 1: return 1        // Bogey
            default: return 0       // Double bogey or worse
            }
        case .modified:
            switch diff {
            case ..<(-1): return 5  // Eagle or better
            case -1: return 3       // Birdie
            case 0: return 2        // Par
            case 1: return 1        // Bogey
            default: return 0       // Double bogey or worse
            }
        case .aggressive:
            switch diff {
            case ..<(-1): return 5  // Eagle or better
            case -1: return 4       // Birdie
            case 0: return 2        // Par
            case 1: return 0        // Bogey
            default: return 0       // Double bogey or worse
            }
        }
    }
    
    func saveHoleScore() {
        for player in activePlayers {
            if let score = playerScores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
    }
}

struct StablefordPointsReference: View {
    let scoringSystem: StablefordScoring
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Point Values")
                .font(.system(size: 16, weight: .semibold))
            
            HStack(spacing: 15) {
                PointBadge(label: "Eagle", points: scoringSystem == .standard ? 4 : 5, color: .purple)
                PointBadge(label: "Birdie", points: scoringSystem == .aggressive ? 4 : 3, color: .blue)
                PointBadge(label: "Par", points: 2, color: .green)
                PointBadge(label: "Bogey", points: scoringSystem == .aggressive ? 0 : 1, color: .orange)
                PointBadge(label: "2+", points: 0, color: .red)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct PointBadge: View {
    let label: String
    let points: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            Text("\(points)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StablefordPlayerRow: View {
    let player: Player
    let score: Int
    let points: Int
    let par: Int
    let scoringSystem: StablefordScoring
    let onScoreChange: (Int) -> Void
    
    var scoreColor: Color {
        guard score > 0 else { return .black }
        let diff = score - par
        switch diff {
        case ..<(-1): return .purple
        case -1: return .blue
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .medium))
                    
                    if player.handicap > 0 {
                        Text("HCP: \(player.handicap)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Points Display
                if points > 0 {
                    Text("\(points) pts")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(width: 60)
                }
                
                // Score Controls
                HStack(spacing: 15) {
                    Button(action: { if score > 0 { onScoreChange(score - 1) } }) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                    
                    Text("\(score)")
                        .font(.system(size: 24, weight: .bold))
                        .frame(minWidth: 40)
                        .foregroundColor(scoreColor)
                    
                    Button(action: { onScoreChange(score + 1) }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Quick Score Buttons (Par, Bogey, Birdie)
            HStack(spacing: 8) {
                // TODO: Connect to actual hole par data
                // Using par from component property for consistency
                
                Button(action: { onScoreChange(par - 1) }) {
                    Text("Birdie")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(score == par - 1 ? .white : .blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(score == par - 1 ? Color.blue : Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Button(action: { onScoreChange(par) }) {
                    Text("Par")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(score == par ? .white : .green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(score == par ? Color.green : Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Button(action: { onScoreChange(par + 1) }) {
                    Text("Bogey")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(score == par + 1 ? .white : .orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(score == par + 1 ? Color.orange : Color.orange.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PointsTotalCard: View {
    let players: [Player]
    let points: [UUID: Int]
    
    var totalPoints: [(Player, Int)] {
        players.compactMap { player in
            if let pts = points[player.id] {
                return (player, pts)
            }
            return nil
        }
        .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        if !totalPoints.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Standings")
                    .font(.system(size: 16, weight: .semibold))
                
                ForEach(totalPoints, id: \.0.id) { player, pts in
                    HStack {
                        Text(player.name)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        Text("\(pts) points")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

// MARK: - Nassau Scorecard

struct NassauScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var playerScores: [UUID: Int] = [:]
    @State private var showPressOptions = false
    
    var activePlayers: [Player] {
        configuration.players.filter { $0.isActive }
    }
    
    var currentNine: String {
        hole <= 9 ? "Front 9" : "Back 9"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: GolfConstants.ParManagement.parForHole(hole), yards: GolfConstants.ParManagement.service.getYardageForHole(hole))
                
                // Nassau Match Status
                NassauStatusCard(
                    hole: hole,
                    gameState: gameState,
                    players: activePlayers
                )
                
                // Player Scores
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Hole \(hole) - \(currentNine)")
                            .font(.system(size: 20, weight: .bold))
                        
                        Spacer()
                        
                        if configuration.scoringRules.nassauPresses {
                            Button(action: { showPressOptions = true }) {
                                Label("Press", systemImage: "plus.circle")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    ForEach(activePlayers) { player in
                        PlayerScoreRow(
                            player: player,
                            score: playerScores[player.id] ?? 0,
                            isBestScore: false,
                            onScoreChange: { newScore in
                                playerScores[player.id] = newScore
                            }
                        )
                    }
                }
                .padding()
                
                Button(action: saveHoleScore) {
                    Text("Save Hole \(hole)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPressOptions) {
            NassauPressView(
                hole: hole,
                gameState: gameState,
                onPress: { pressType in
                    // Handle press logic
                    showPressOptions = false
                }
            )
        }
    }
    
    func saveHoleScore() {
        for player in activePlayers {
            if let score = playerScores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
                updateNassauMatches(player: player.id, score: score)
            }
        }
    }
    
    func updateNassauMatches(player: UUID, score: Int) {
        // Update Nassau match status based on scores
        // This would include logic for front 9, back 9, and overall matches
    }
}

struct NassauStatusCard: View {
    let hole: Int
    let gameState: GameState
    let players: [Player]
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Nassau Status")
                .font(.system(size: 18, weight: .bold))
            
            HStack(spacing: 20) {
                NassauMatchBadge(
                    title: "Front",
                    status: getMatchStatus(gameState.nassauMatches.front9),
                    color: .blue
                )
                
                NassauMatchBadge(
                    title: "Back",
                    status: getMatchStatus(gameState.nassauMatches.back9),
                    color: .orange
                )
                
                NassauMatchBadge(
                    title: "Overall",
                    status: getMatchStatus(gameState.nassauMatches.overall),
                    color: .purple
                )
            }
            
            if !gameState.nassauMatches.presses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Presses")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    ForEach(gameState.nassauMatches.presses, id: \.hole) { press in
                        HStack {
                            Text("Hole \(press.hole)")
                                .font(.system(size: 12))
                            
                            Text("\(press.type == .front ? "Front" : press.type == .back ? "Back" : "Overall")")
                                .font(.system(size: 12, weight: .medium))
                            
                            Spacer()
                            
                            Text("$\(press.value)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    func getMatchStatus(_ match: MatchStatus) -> String {
        if let leader = match.leader, match.holesUp > 0 {
            let player = players.first { $0.id == leader }
            return "\(player?.name ?? "Player") \(match.holesUp) UP"
        }
        return "All Square"
    }
}

struct NassauMatchBadge: View {
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            Text(status)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NassauPressView: View {
    let hole: Int
    let gameState: GameState
    let onPress: (PressType) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add a Press")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Select which match to press")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                VStack(spacing: 15) {
                    Button(action: { onPress(.front) }) {
                        Label("Press Front 9", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { onPress(.back) }) {
                        Label("Press Back 9", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { onPress(.overall) }) {
                        Label("Press Overall", systemImage: "arrow.up.circle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Wolf Scorecard

struct WolfScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var currentWolf: Player? = nil
    @State private var wolfDecision: WolfDecision = .undecided
    @State private var selectedPartner: Player? = nil
    @State private var playerScores: [UUID: Int] = [:]
    @State private var isBlindWolf = false
    
    var activePlayers: [Player] {
        configuration.players.filter { $0.isActive }
    }
    
    var wolfRotation: Player {
        let index = (hole - 1) % activePlayers.count
        return activePlayers[index]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: GolfConstants.ParManagement.parForHole(hole), yards: GolfConstants.ParManagement.service.getYardageForHole(hole))
                
                // Wolf Selection
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "hare.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        Text("\(wolfRotation.name) is the Wolf")
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    if configuration.scoringRules.wolfBlindOption && wolfDecision == .undecided {
                        Toggle("Blind Wolf (Double Points)", isOn: $isBlindWolf)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    if !isBlindWolf && wolfDecision == .undecided {
                        Text("Watch tee shots, then decide:")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    WolfDecisionButtons(
                        wolfDecision: $wolfDecision,
                        isBlindWolf: isBlindWolf,
                        onPartnerSelection: { partner in
                            selectedPartner = partner
                        },
                        players: activePlayers.filter { $0.id != wolfRotation.id }
                    )
                    
                    if wolfDecision != .undecided {
                        WolfTeamsDisplay(
                            wolf: wolfRotation,
                            partner: selectedPartner,
                            decision: wolfDecision,
                            players: activePlayers
                        )
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Scores
                VStack(alignment: .leading, spacing: 15) {
                    Text("Scores")
                        .font(.system(size: 20, weight: .bold))
                    
                    ForEach(activePlayers) { player in
                        PlayerScoreRow(
                            player: player,
                            score: playerScores[player.id] ?? 0,
                            isBestScore: false,
                            onScoreChange: { newScore in
                                playerScores[player.id] = newScore
                            }
                        )
                    }
                }
                .padding()
                
                // Points Calculation
                if wolfDecision != .undecided && playerScores.values.filter({ $0 > 0 }).count == activePlayers.count {
                    WolfPointsCalculation(
                        wolf: wolfRotation,
                        partner: selectedPartner,
                        decision: wolfDecision,
                        isBlindWolf: isBlindWolf,
                        scores: playerScores,
                        players: activePlayers
                    )
                }
                
                Button(action: saveHoleScore) {
                    Text("Save Hole \(hole)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
    
    func saveHoleScore() {
        // Save scores and wolf selection
        for player in activePlayers {
            if let score = playerScores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
        
        // Save wolf selection
        gameState.wolfSelections[hole] = WolfSelection(
            wolf: wolfRotation.id,
            partner: selectedPartner?.id,
            isLoneWolf: wolfDecision == .loneWolf,
            isBlindWolf: isBlindWolf
        )
    }
}

enum WolfDecision {
    case undecided
    case partner
    case loneWolf
}

struct WolfDecisionButtons: View {
    @Binding var wolfDecision: WolfDecision
    let isBlindWolf: Bool
    let onPartnerSelection: (Player) -> Void
    let players: [Player]
    @State private var showPartnerPicker = false
    
    var body: some View {
        if wolfDecision == .undecided {
            HStack(spacing: 15) {
                if !isBlindWolf {
                    Button(action: {
                        wolfDecision = .partner
                        showPartnerPicker = true
                    }) {
                        VStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 30))
                            Text("Pick Partner")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    wolfDecision = .loneWolf
                }) {
                    VStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                        Text("Lone Wolf")
                            .font(.system(size: 14, weight: .medium))
                        Text(isBlindWolf ? "4x Points!" : "2x Points")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .sheet(isPresented: $showPartnerPicker) {
                PartnerSelectionView(
                    players: players,
                    onSelection: { partner in
                        onPartnerSelection(partner)
                        showPartnerPicker = false
                    }
                )
            }
        }
    }
}

struct PartnerSelectionView: View {
    let players: [Player]
    let onSelection: (Player) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Your Partner")
                    .font(.system(size: 24, weight: .bold))
                
                ForEach(players) { player in
                    Button(action: {
                        onSelection(player)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 30))
                            
                            Text(player.name)
                                .font(.system(size: 18, weight: .medium))
                            
                            Spacer()
                            
                            if player.handicap > 0 {
                                Text("HCP: \(player.handicap)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct WolfTeamsDisplay: View {
    let wolf: Player
    let partner: Player?
    let decision: WolfDecision
    let players: [Player]
    
    var wolfTeam: [Player] {
        if let partner = partner {
            return [wolf, partner]
        }
        return [wolf]
    }
    
    var otherTeam: [Player] {
        players.filter { player in
            !wolfTeam.contains { $0.id == player.id }
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Wolf Team
            VStack(alignment: .leading, spacing: 8) {
                Text(decision == .loneWolf ? "Lone Wolf" : "Wolf Team")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                ForEach(wolfTeam) { player in
                    HStack {
                        Image(systemName: player.id == wolf.id ? "hare.fill" : "person.fill")
                            .foregroundColor(.orange)
                        Text(player.name)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            
            Text("vs")
                .font(.system(size: 16, weight: .bold))
            
            // Other Team
            VStack(alignment: .leading, spacing: 8) {
                Text("Hunters")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                ForEach(otherTeam) { player in
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text(player.name)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct WolfPointsCalculation: View {
    let wolf: Player
    let partner: Player?
    let decision: WolfDecision
    let isBlindWolf: Bool
    let scores: [UUID: Int]
    let players: [Player]
    
    var wolfTeamScore: Int {
        if let partner = partner {
            let wolfScore = scores[wolf.id] ?? 0
            let partnerScore = scores[partner.id] ?? 0
            return min(wolfScore, partnerScore)
        }
        return scores[wolf.id] ?? 0
    }
    
    var otherTeamScore: Int {
        let otherPlayers = players.filter { player in
            player.id != wolf.id && player.id != partner?.id
        }
        return otherPlayers.compactMap { scores[$0.id] }.min() ?? 0
    }
    
    var pointsWon: Int {
        let base = wolfTeamScore < otherTeamScore ? 1 : wolfTeamScore > otherTeamScore ? -1 : 0
        
        if decision == .loneWolf {
            if isBlindWolf {
                return base * 4
            }
            return base * 2
        }
        return base
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Points This Hole")
                .font(.system(size: 16, weight: .semibold))
            
            HStack {
                Text("Wolf Team: \(wolfTeamScore)")
                Spacer()
                Text("Hunters: \(otherTeamScore)")
            }
            .font(.system(size: 14))
            
            Divider()
            
            if pointsWon > 0 {
                Text("Wolf wins \(pointsWon) point\(pointsWon == 1 ? "" : "s")!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
            } else if pointsWon < 0 {
                Text("Hunters win \(abs(pointsWon)) point\(abs(pointsWon) == 1 ? "" : "s")!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            } else {
                Text("Hole tied - No points")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Vegas Scorecard

struct VegasScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var team1Scores: [UUID: Int] = [:]
    @State private var team2Scores: [UUID: Int] = [:]
    @State private var flipped = false
    
    var team1: [Player] {
        Array(configuration.players.filter { $0.isActive }.prefix(2))
    }
    
    var team2: [Player] {
        Array(configuration.players.filter { $0.isActive }.suffix(2))
    }
    
    var team1Combined: Int {
        let scores = team1.compactMap { team1Scores[$0.id] }.filter { $0 > 0 }
        guard scores.count == 2 else { return 0 }
        
        let sorted = scores.sorted()
        if flipped && hasBirdie(team: 2) {
            return sorted[1] * 10 + sorted[0] // Flipped
        }
        return sorted[0] * 10 + sorted[1] // Normal
    }
    
    var team2Combined: Int {
        let scores = team2.compactMap { team2Scores[$0.id] }.filter { $0 > 0 }
        guard scores.count == 2 else { return 0 }
        
        let sorted = scores.sorted()
        if flipped && hasBirdie(team: 1) {
            return sorted[1] * 10 + sorted[0] // Flipped
        }
        return sorted[0] * 10 + sorted[1] // Normal
    }
    
    var pointDifference: Int {
        guard team1Combined > 0 && team2Combined > 0 else { return 0 }
        return abs(team1Combined - team2Combined)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: GolfConstants.ParManagement.parForHole(hole), yards: GolfConstants.ParManagement.service.getYardageForHole(hole))
                
                // Team 1
                VegasTeamCard(
                    teamName: "Team 1",
                    players: team1,
                    scores: team1Scores,
                    combinedScore: team1Combined,
                    color: .blue,
                    onScoreChange: { player, score in
                        team1Scores[player] = score
                        checkForFlip()
                    }
                )
                
                // VS Indicator
                HStack {
                    Spacer()
                    Text("VS")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                // Team 2
                VegasTeamCard(
                    teamName: "Team 2",
                    players: team2,
                    scores: team2Scores,
                    combinedScore: team2Combined,
                    color: .orange,
                    onScoreChange: { player, score in
                        team2Scores[player] = score
                        checkForFlip()
                    }
                )
                
                // Points Display
                if pointDifference > 0 {
                    VStack(spacing: 10) {
                        Text("Point Difference")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("\(pointDifference) points")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(team1Combined < team2Combined ? .blue : .orange)
                        
                        if flipped {
                            Label("FLIPPED!", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Flip Rule Toggle
                if configuration.scoringRules.vegasFlipRule {
                    Toggle("Birdie Flip Rule Active", isOn: .constant(true))
                        .disabled(true)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: saveHoleScore) {
                    Text("Save Hole \(hole)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
    
    func hasBirdie(team: Int) -> Bool {
        let scores = team == 1 ? team1.compactMap { team1Scores[$0.id] } : team2.compactMap { team2Scores[$0.id] }
        let holePar = GolfConstants.ParManagement.parForHole(hole)
        return scores.contains { $0 < holePar }
    }
    
    func checkForFlip() {
        if configuration.scoringRules.vegasFlipRule {
            flipped = hasBirdie(team: 1) || hasBirdie(team: 2)
        }
    }
    
    func saveHoleScore() {
        // Save all scores
        for player in team1 {
            if let score = team1Scores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
        
        for player in team2 {
            if let score = team2Scores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
        
        gameState.vegasFlips[hole] = flipped
    }
}

struct VegasTeamCard: View {
    let teamName: String
    let players: [Player]
    let scores: [UUID: Int]
    let combinedScore: Int
    let color: Color
    let onScoreChange: (UUID, Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(teamName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                
                Spacer()
                
                if combinedScore > 0 {
                    Text("Combined: \(combinedScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }
            }
            
            ForEach(players) { player in
                HStack {
                    Text(player.name)
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            let current = scores[player.id] ?? 0
                            if current > 0 {
                                onScoreChange(player.id, current - 1)
                            }
                        }) {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                        }
                        
                        Text("\(scores[player.id] ?? 0)")
                            .font(.system(size: 20, weight: .bold))
                            .frame(minWidth: 30)
                        
                        Button(action: {
                            let current = scores[player.id] ?? 0
                            onScoreChange(player.id, current + 1)
                        }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

// MARK: - Stats Cards

struct AdvancedOverallScoreCard: View {
    let gameState: GameState
    let configuration: GameConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overall Scores")
                .font(.system(size: 18, weight: .bold))
            
            // Calculate and display totals for each player
            ForEach(configuration.players.filter { $0.isActive }) { player in
                HStack {
                    Text(player.name)
                    Spacer()
                    Text("\(calculateTotal(for: player.id))")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    func calculateTotal(for playerId: UUID) -> Int {
        var total = 0
        for (_, scores) in gameState.scores {
            total += scores[playerId] ?? 0
        }
        return total
    }
}

struct AdvancedPlayerStatsCard: View {
    let player: Player
    let gameState: GameState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(player.name)
                .font(.system(size: 16, weight: .bold))
            
            HStack {
                StatItem(label: "Score", value: "\(calculateScore())")
                Spacer()
                StatItem(label: "Putts", value: "\(calculatePutts())")
                Spacer()
                StatItem(label: "FIR", value: "\(calculateFairways())%")
                Spacer()
                StatItem(label: "GIR", value: "\(calculateGreens())%")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
    
    func calculateScore() -> Int {
        var total = 0
        for (_, scores) in gameState.scores {
            total += scores[player.id] ?? 0
        }
        return total
    }
    
    func calculatePutts() -> Int {
        var total = 0
        for (_, putts) in gameState.putts {
            total += putts[player.id] ?? 0
        }
        return total
    }
    
    func calculateFairways() -> Int {
        let hits = gameState.fairwayHits.values.compactMap { $0[player.id] }.filter { $0 }.count
        let total = gameState.fairwayHits.count
        return total > 0 ? (hits * 100) / total : 0
    }
    
    func calculateGreens() -> Int {
        let hits = gameState.greensInRegulation.values.compactMap { $0[player.id] }.filter { $0 }.count
        let total = gameState.greensInRegulation.count
        return total > 0 ? (hits * 100) / total : 0
    }
}

struct AdvancedStatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
    }
}

struct AdvancedSkinsStatsCard: View {
    let gameState: GameState
    
    var skinsWonByPlayer: [UUID: Int] {
        var result: [UUID: Int] = [:]
        for (_, playerId) in gameState.skinsWon {
            result[playerId, default: 0] += 1
        }
        return result
    }
    
    var totalValue: Int {
        gameState.skinValues.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skins Summary")
                .font(.system(size: 18, weight: .bold))
            
            ForEach(Array(skinsWonByPlayer.keys), id: \.self) { playerId in
                HStack {
                    Text("Player") // Should get player name
                    Spacer()
                    Text("\(skinsWonByPlayer[playerId] ?? 0) skins")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            
            Divider()
            
            HStack {
                Text("Total Value")
                Spacer()
                Text("$\(totalValue)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}