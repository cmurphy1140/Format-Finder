import SwiftUI

// MARK: - Scramble Scorecard (with ball tracking)

struct ScrambleScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var teamScore = 0
    @State private var selectedPlayer: UUID? = nil
    @State private var shotSelections: [ShotSelection] = []
    @State private var currentShot = 1
    
    var activePlayers: [Player] {
        configuration.players.filter { $0.isActive }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hole Information
                HoleInfoHeader(hole: hole, par: 4, yards: 380)
                
                // Shot Tracking
                VStack(alignment: .leading, spacing: 15) {
                    Text("Shot \(currentShot)")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Whose ball did the team use?")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    // Player Selection Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(activePlayers) { player in
                            PlayerSelectionCard(
                                player: player,
                                isSelected: selectedPlayer == player.id,
                                shotNumber: currentShot,
                                action: {
                                    selectedPlayer = player.id
                                    recordShotSelection(player: player)
                                }
                            )
                        }
                    }
                    
                    // Shot History
                    if !shotSelections.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Shot History")
                                .font(.system(size: 16, weight: .semibold))
                            
                            ForEach(shotSelections) { selection in
                                HStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.3))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text("\(selection.shotNumber)")
                                                .font(.system(size: 14, weight: .bold))
                                        )
                                    
                                    Text(selection.playerName)
                                        .font(.system(size: 14))
                                    
                                    Spacer()
                                    
                                    Text(selection.shotType)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                Divider()
                
                // Team Score Entry
                VStack(alignment: .leading, spacing: 15) {
                    Text("Team Score")
                        .font(.system(size: 18, weight: .semibold))
                    
                    HStack(spacing: 20) {
                        Button(action: { if teamScore > 0 { teamScore -= 1 } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                        }
                        
                        Text("\(teamScore)")
                            .font(.system(size: 48, weight: .bold))
                            .frame(minWidth: 80)
                        
                        Button(action: { teamScore += 1 }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Quick Score Buttons
                    HStack(spacing: 10) {
                        ForEach([3, 4, 5, 6], id: \.self) { score in
                            Button(action: { teamScore = score }) {
                                Text("\(score)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(teamScore == score ? .white : .black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(teamScore == score ? Color.blue : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                
                // Ball Usage Statistics
                ScrambleStatsCard(shotSelections: shotSelections, players: activePlayers)
                
                // Save Hole Button
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
    
    func recordShotSelection(player: Player) {
        let shotType = getShotType(for: currentShot)
        let selection = ShotSelection(
            shotNumber: currentShot,
            playerName: player.name,
            playerId: player.id,
            shotType: shotType
        )
        shotSelections.append(selection)
        currentShot += 1
    }
    
    func getShotType(for shot: Int) -> String {
        switch shot {
        case 1: return "Tee Shot"
        case 2: return "Approach"
        case 3: return "Chip/Pitch"
        default: return "Putt"
        }
    }
    
    func saveHoleScore() {
        // Save score and ball selections to game state
        activePlayers.forEach { player in
            gameState.setScore(hole: hole, player: player.id, score: teamScore)
        }
        
        // Save scramble selections
        if let firstPlayer = shotSelections.first {
            gameState.scrambleSelections[hole] = firstPlayer.playerId
        }
    }
}

struct ShotSelection: Identifiable {
    let id = UUID()
    let shotNumber: Int
    let playerName: String
    let playerId: UUID
    let shotType: String
}

struct PlayerSelectionCard: View {
    let player: Player
    let isSelected: Bool
    let shotNumber: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .green : .gray)
                
                Text(player.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                
                if player.handicap > 0 {
                    Text("HCP: \(player.handicap)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
}

struct ScrambleStatsCard: View {
    let shotSelections: [ShotSelection]
    let players: [Player]
    
    var ballUsageStats: [(String, Int)] {
        var stats: [String: Int] = [:]
        for player in players {
            stats[player.name] = shotSelections.filter { $0.playerId == player.id }.count
        }
        return stats.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        if !shotSelections.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ball Usage")
                    .font(.system(size: 16, weight: .semibold))
                
                ForEach(ballUsageStats, id: \.0) { stat in
                    HStack {
                        Text(stat.0)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        Text("\(stat.1) shot\(stat.1 == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

// MARK: - Best Ball Scorecard

struct BestBallScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var playerScores: [UUID: Int] = [:]
    
    var activePlayers: [Player] {
        configuration.players.filter { $0.isActive }
    }
    
    var bestScore: Int? {
        playerScores.values.filter { $0 > 0 }.min()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: 4, yards: 380)
                
                // Individual Scores
                VStack(alignment: .leading, spacing: 15) {
                    Text("Individual Scores")
                        .font(.system(size: 20, weight: .bold))
                    
                    ForEach(activePlayers) { player in
                        PlayerScoreRow(
                            player: player,
                            score: playerScores[player.id] ?? 0,
                            isBestScore: playerScores[player.id] == bestScore && bestScore != nil,
                            onScoreChange: { newScore in
                                playerScores[player.id] = newScore
                            }
                        )
                    }
                }
                .padding()
                
                // Best Score Display
                if let best = bestScore {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Team Score: \(best)")
                            .font(.system(size: 24, weight: .bold))
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
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
        for player in activePlayers {
            if let score = playerScores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
    }
}

// MARK: - Match Play Scorecard

struct MatchPlayScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var player1Score = 0
    @State private var player2Score = 0
    @State private var holeWinner: UUID? = nil
    
    var players: [Player] {
        Array(configuration.players.filter { $0.isActive }.prefix(2))
    }
    
    var matchStatus: String {
        let p1Wins = gameState.matchPlayStatus.holesWon[players[0].id] ?? 0
        let p2Wins = gameState.matchPlayStatus.holesWon[players[1].id] ?? 0
        
        if p1Wins == p2Wins {
            return "All Square"
        } else if p1Wins > p2Wins {
            return "\(p1Wins - p2Wins) UP"
        } else {
            return "\(p2Wins - p1Wins) DOWN"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: 4, yards: 380)
                
                // Match Status
                VStack(spacing: 10) {
                    Text("Match Status")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(matchStatus)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Player Scores
                VStack(spacing: 20) {
                    ForEach(players.indices, id: \.self) { index in
                        MatchPlayPlayerCard(
                            player: players[index],
                            score: index == 0 ? player1Score : player2Score,
                            isWinner: holeWinner == players[index].id,
                            onScoreChange: { newScore in
                                if index == 0 {
                                    player1Score = newScore
                                } else {
                                    player2Score = newScore
                                }
                                determineHoleWinner()
                            }
                        )
                    }
                }
                .padding()
                
                // Hole Result
                if holeWinner != nil {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.yellow)
                        Text("\(players.first { $0.id == holeWinner }?.name ?? "") wins the hole!")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
                } else if player1Score > 0 && player2Score > 0 && player1Score == player2Score {
                    Text("Hole Halved")
                        .font(.system(size: 18, weight: .semibold))
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
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
    
    func determineHoleWinner() {
        guard player1Score > 0 && player2Score > 0 else {
            holeWinner = nil
            return
        }
        
        if player1Score < player2Score {
            holeWinner = players[0].id
        } else if player2Score < player1Score {
            holeWinner = players[1].id
        } else {
            holeWinner = nil // Halved
        }
    }
    
    func saveHoleScore() {
        gameState.setScore(hole: hole, player: players[0].id, score: player1Score)
        gameState.setScore(hole: hole, player: players[1].id, score: player2Score)
        
        if let winner = holeWinner {
            if gameState.matchPlayStatus.holesWon[winner] == nil {
                gameState.matchPlayStatus.holesWon[winner] = 0
            }
            gameState.matchPlayStatus.holesWon[winner]! += 1
        }
    }
}

// MARK: - Skins Scorecard

struct SkinsScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var playerScores: [UUID: Int] = [:]
    @State private var skinValue = 10
    @State private var isValidated = true
    
    var activePlayers: [Player] {
        configuration.players.filter { $0.isActive }
    }
    
    var skinWinner: Player? {
        let scores = playerScores.filter { $0.value > 0 }
        guard !scores.isEmpty else { return nil }
        
        let minScore = scores.values.min()!
        let winners = scores.filter { $0.value == minScore }
        
        // Only one winner for a skin
        if winners.count == 1, let winnerId = winners.first?.key {
            return activePlayers.first { $0.id == winnerId }
        }
        
        return nil
    }
    
    var carryoverValue: Int {
        // Calculate carryover from previous holes
        var total = skinValue
        for h in 1..<hole {
            if gameState.skinsWon[h] == nil {
                total += gameState.skinValues[h] ?? skinValue
            }
        }
        return total
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: 4, yards: 380)
                
                // Skin Value Display
                VStack(spacing: 10) {
                    Text("Skin Value")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.yellow)
                        
                        Text("$\(carryoverValue)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    if carryoverValue > skinValue {
                        Text("(Includes $\(carryoverValue - skinValue) carryover)")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                
                // Player Scores
                VStack(alignment: .leading, spacing: 15) {
                    Text("Player Scores")
                        .font(.system(size: 20, weight: .bold))
                    
                    ForEach(activePlayers) { player in
                        PlayerScoreRow(
                            player: player,
                            score: playerScores[player.id] ?? 0,
                            isBestScore: player.id == skinWinner?.id,
                            onScoreChange: { newScore in
                                playerScores[player.id] = newScore
                            }
                        )
                    }
                }
                .padding()
                
                // Skin Winner
                if let winner = skinWinner {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading) {
                            Text("\(winner.name) wins the skin!")
                                .font(.system(size: 18, weight: .semibold))
                            Text("$\(carryoverValue)")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
                } else if playerScores.values.filter({ $0 > 0 }).count >= 2 {
                    // Check for tie
                    let scores = playerScores.values.filter { $0 > 0 }
                    let minScore = scores.min()
                    let tiedCount = scores.filter { $0 == minScore }.count
                    
                    if tiedCount > 1 {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            
                            Text("Skin carries over to next hole")
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                
                // Validation Toggle (if enabled in settings)
                if configuration.scoringRules.skinsValidation {
                    Toggle("Validated", isOn: $isValidated)
                        .padding()
                        .background(Color.gray.opacity(0.1))
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
    
    func saveHoleScore() {
        // Save scores
        for player in activePlayers {
            if let score = playerScores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
        
        // Save skin winner
        if let winner = skinWinner {
            gameState.skinsWon[hole] = winner.id
        }
        
        // Save skin value
        gameState.skinValues[hole] = carryoverValue
    }
}

// MARK: - Helper Views

struct HoleInfoHeader: View {
    let hole: Int
    let par: Int
    let yards: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("HOLE \(hole)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("Par \(par)")
                    .font(.system(size: 24, weight: .bold))
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(yards) yards")
                    .font(.system(size: 16, weight: .medium))
                
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14))
                    Text("Stroke Index: 7")
                        .font(.system(size: 12))
                }
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PlayerScoreRow: View {
    let player: Player
    let score: Int
    let isBestScore: Bool
    let onScoreChange: (Int) -> Void
    
    var body: some View {
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
            
            HStack(spacing: 15) {
                Button(action: { if score > 0 { onScoreChange(score - 1) } }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
                
                Text("\(score)")
                    .font(.system(size: 24, weight: .bold))
                    .frame(minWidth: 40)
                    .foregroundColor(isBestScore ? .green : .black)
                
                Button(action: { onScoreChange(score + 1) }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isBestScore ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isBestScore ? Color.green : Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct MatchPlayPlayerCard: View {
    let player: Player
    let score: Int
    let isWinner: Bool
    let onScoreChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(player.name)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                if isWinner {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack(spacing: 20) {
                Button(action: { if score > 0 { onScoreChange(score - 1) } }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.red)
                }
                
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold))
                    .frame(minWidth: 60)
                
                Button(action: { onScoreChange(score + 1) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWinner ? Color.green.opacity(0.2) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWinner ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(radius: isWinner ? 5 : 2)
    }
}

// MARK: - Generic Scorecard (for other formats)

struct GenericScorecardView: View {
    let hole: Int
    let configuration: GameConfiguration
    let gameState: GameState
    @State private var playerScores: [UUID: Int] = [:]
    
    var activePlayers: [Player] {
        configuration.players.filter { $0.isActive }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HoleInfoHeader(hole: hole, par: 4, yards: 380)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Player Scores")
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
        for player in activePlayers {
            if let score = playerScores[player.id], score > 0 {
                gameState.setScore(hole: hole, player: player.id, score: score)
            }
        }
    }
}