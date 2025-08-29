import SwiftUI

struct GameResultsView: View {
    let session: GameSession
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Winner Card
                if let winner = getWinner() {
                    WinnerCard(player: winner, session: session)
                }
                
                // Final Leaderboard
                FinalLeaderboard(session: session)
                
                // Game Statistics
                GameSummaryStats(session: session)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // Play again with same format
                        appState.navigateToGameSetup(format: session.format)
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Play Again")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        appState.navigateHome()
                    }) {
                        Text("Return Home")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Game Results")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
    }
    
    private func getWinner() -> Player? {
        // Get player with lowest score
        let playerScores = session.players.map { player in
            let total = session.scores
                .filter { $0.playerId == player.id }
                .reduce(0) { $0 + $1.strokes }
            return (player, total)
        }
        
        return playerScores.min { $0.1 < $1.1 }?.0
    }
}

struct WinnerCard: View {
    let player: Player
    let session: GameSession
    
    var totalScore: Int {
        session.scores
            .filter { $0.playerId == player.id }
            .reduce(0) { $0 + $1.strokes }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Winner!")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(player.color.color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(player.name.prefix(2)))
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text(player.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Score: \(totalScore)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

struct FinalLeaderboard: View {
    let session: GameSession
    
    var leaderboard: [(player: Player, score: Int)] {
        session.players.map { player in
            let total = session.scores
                .filter { $0.playerId == player.id }
                .reduce(0) { $0 + $1.strokes }
            return (player, total)
        }.sorted { $0.score < $1.score }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Final Leaderboard")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(Array(leaderboard.enumerated()), id: \.1.player.id) { index, entry in
                    FinalScoreRow(
                        position: index + 1,
                        player: entry.player,
                        score: entry.score
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FinalScoreRow: View {
    let position: Int
    let player: Player
    let score: Int
    
    var positionIcon: String {
        switch position {
        case 1: return "1.circle.fill"
        case 2: return "2.circle.fill"
        case 3: return "3.circle.fill"
        default: return "\(position).circle"
        }
    }
    
    var positionColor: Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: positionIcon)
                .font(.title2)
                .foregroundColor(positionColor)
                .frame(width: 30)
            
            Circle()
                .fill(player.color.color)
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(player.name.prefix(1)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(player.name)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(score)")
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct GameSummaryStats: View {
    let session: GameSession
    
    var duration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: session.duration) ?? "N/A"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Summary")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                StatBox(
                    title: "Format",
                    value: session.format.name,
                    icon: "flag.fill"
                )
                
                StatBox(
                    title: "Duration",
                    value: duration,
                    icon: "clock.fill"
                )
                
                StatBox(
                    title: "Holes",
                    value: "18",
                    icon: "circle.grid.3x3.fill"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            
            Text(value)
                .font(.headline)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}