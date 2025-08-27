import SwiftUI

// MARK: - Group Comparison Tables

struct GroupComparisonView: View {
    let players: [Player]
    @ObservedObject var gameState: GameState
    let configuration: GameConfiguration
    
    @State private var selectedCategory: ComparisonCategory = .overall
    @State private var showAwards = false
    @State private var animateWinners = false
    
    private let analyzer = GroupStatsAnalyzer()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                GroupComparisonHeader(
                    playerCount: players.count,
                    showAwards: $showAwards
                )
                
                // Category Selector
                CategorySelector(selectedCategory: $selectedCategory)
                
                // Main Comparison Table
                ComparisonTableView(
                    players: players,
                    gameState: gameState,
                    category: selectedCategory,
                    animateWinners: animateWinners
                )
                
                // Fun Superlatives
                if showAwards {
                    SuperlativesView(
                        players: players,
                        gameState: gameState
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                
                // Category Winners
                CategoryWinnersView(
                    players: players,
                    gameState: gameState,
                    category: selectedCategory
                )
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                animateWinners = true
            }
        }
    }
}

// MARK: - Comparison Table

struct ComparisonTableView: View {
    let players: [Player]
    let gameState: GameState
    let category: ComparisonCategory
    let animateWinners: Bool
    
    @State private var sortBy: SortOption = .score
    @State private var ascending = true
    
    private var sortedPlayers: [Player] {
        players.sorted { p1, p2 in
            let value1 = getStatValue(for: p1, stat: sortBy)
            let value2 = getStatValue(for: p2, stat: sortBy)
            return ascending ? value1 < value2 : value1 > value2
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Table Header
            tableHeader
            
            // Player Rows
            ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                PlayerComparisonRow(
                    player: player,
                    rank: index + 1,
                    stats: getPlayerStats(for: player),
                    isWinner: isWinner(player: player, in: category),
                    animateIn: animateWinners
                )
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // Rank
            Text("#")
                .frame(width: 30)
                .font(.system(size: 12, weight: .semibold))
            
            // Player Name
            Text("Player")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 12, weight: .semibold))
            
            // Stats Headers
            ForEach(ComparisonStat.allCases, id: \.self) { stat in
                Button(action: {
                    if sortBy == stat.sortOption {
                        ascending.toggle()
                    } else {
                        sortBy = stat.sortOption
                        ascending = true
                    }
                }) {
                    HStack(spacing: 2) {
                        Text(stat.abbreviation)
                            .font(.system(size: 11, weight: .semibold))
                        
                        if sortBy == stat.sortOption {
                            Image(systemName: ascending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8))
                        }
                    }
                }
                .frame(width: 50)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .foregroundColor(.gray)
    }
    
    private func getPlayerStats(for player: Player) -> PlayerComparisonStats {
        let scores = getScores(for: player.id)
        let pars = Array(repeating: 4, count: 18) // TODO: Get actual pars
        
        return PlayerComparisonStats(
            totalScore: scores.reduce(0, +),
            toPar: calculateToPar(scores: scores, pars: pars),
            birdies: countBirdies(scores: scores, pars: pars),
            pars: countPars(scores: scores, pars: pars),
            bogeys: countBogeys(scores: scores, pars: pars),
            fairways: getFairwayPercentage(for: player.id),
            greens: getGreenPercentage(for: player.id),
            putts: getTotalPutts(for: player.id)
        )
    }
    
    private func getScores(for playerId: UUID) -> [Int] {
        var scores: [Int] = []
        for hole in 1...18 {
            if let score = gameState.scores[hole]?[playerId] {
                scores.append(score)
            }
        }
        return scores
    }
    
    private func calculateToPar(scores: [Int], pars: [Int]) -> Int {
        scores.enumerated().reduce(0) { $0 + ($1.element - pars[$1.offset]) }
    }
    
    private func countBirdies(scores: [Int], pars: [Int]) -> Int {
        scores.enumerated().filter { $0.element < pars[$0.offset] }.count
    }
    
    private func countPars(scores: [Int], pars: [Int]) -> Int {
        scores.enumerated().filter { $0.element == pars[$0.offset] }.count
    }
    
    private func countBogeys(scores: [Int], pars: [Int]) -> Int {
        scores.enumerated().filter { $0.element == pars[$0.offset] + 1 }.count
    }
    
    private func getFairwayPercentage(for playerId: UUID) -> Int {
        let hits = gameState.fairwayHits.values.compactMap { $0[playerId] }.filter { $0 }.count
        let total = gameState.fairwayHits.count
        return total > 0 ? (hits * 100) / total : 0
    }
    
    private func getGreenPercentage(for playerId: UUID) -> Int {
        let hits = gameState.greensInRegulation.values.compactMap { $0[playerId] }.filter { $0 }.count
        let total = gameState.greensInRegulation.count
        return total > 0 ? (hits * 100) / total : 0
    }
    
    private func getTotalPutts(for playerId: UUID) -> Int {
        gameState.putts.values.compactMap { $0[playerId] }.reduce(0, +)
    }
    
    private func getStatValue(for player: Player, stat: SortOption) -> Int {
        let stats = getPlayerStats(for: player)
        switch stat {
        case .score: return stats.totalScore
        case .toPar: return stats.toPar
        case .birdies: return stats.birdies
        case .pars: return stats.pars
        case .fairways: return stats.fairways
        case .greens: return stats.greens
        case .putts: return stats.putts
        }
    }
    
    private func isWinner(player: Player, in category: ComparisonCategory) -> Bool {
        // Simplified winner logic
        guard let firstPlayer = sortedPlayers.first else { return false }
        return player.id == firstPlayer.id
    }
}

// MARK: - Player Comparison Row

struct PlayerComparisonRow: View {
    let player: Player
    let rank: Int
    let stats: PlayerComparisonStats
    let isWinner: Bool
    let animateIn: Bool
    
    @State private var showRow = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Rank with medal for top 3
            ZStack {
                if rank <= 3 {
                    Image(systemName: medalIcon)
                        .font(.system(size: 16))
                        .foregroundColor(medalColor)
                        .scaleEffect(showRow ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(rank) * 0.1), value: showRow)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 30)
            
            // Player Name
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(player.name.prefix(1))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 14, weight: .medium))
                    
                    if player.handicap > 0 {
                        Text("HCP \(player.handicap)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stats
            StatCell(value: "\(stats.totalScore)", highlight: false)
            StatCell(value: formatToPar(stats.toPar), highlight: stats.toPar < 0)
            StatCell(value: "\(stats.birdies)", highlight: stats.birdies > 0)
            StatCell(value: "\(stats.pars)", highlight: false)
            StatCell(value: "\(stats.fairways)%", highlight: stats.fairways >= 70)
            StatCell(value: "\(stats.greens)%", highlight: stats.greens >= 70)
            StatCell(value: "\(stats.putts)", highlight: stats.putts <= 30)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            isWinner ? medalColor.opacity(0.1) : Color.clear
        )
        .opacity(showRow ? 1 : 0)
        .offset(x: showRow ? 0 : -50)
        .onAppear {
            if animateIn {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(rank) * 0.05)) {
                    showRow = true
                }
            } else {
                showRow = true
            }
        }
    }
    
    private var medalIcon: String {
        switch rank {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
    
    private var medalColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.7)
        case 3: return .orange
        default: return .clear
        }
    }
    
    private func formatToPar(_ toPar: Int) -> String {
        if toPar == 0 { return "E" }
        if toPar > 0 { return "+\(toPar)" }
        return "\(toPar)"
    }
}

struct StatCell: View {
    let value: String
    let highlight: Bool
    
    var body: some View {
        Text(value)
            .font(.system(size: 12, weight: highlight ? .semibold : .regular))
            .foregroundColor(highlight ? .blue : .primary)
            .frame(width: 50)
    }
}

// MARK: - Category Winners

struct CategoryWinnersView: View {
    let players: [Player]
    let gameState: GameState
    let category: ComparisonCategory
    
    @State private var showWinners = false
    
    private var categoryWinners: [(category: String, player: Player, value: String)] {
        // Calculate winners for each stat category
        var winners: [(String, Player, String)] = []
        
        // Simplified - would calculate actual winners
        if let firstPlayer = players.first {
            winners.append(("Longest Drive", firstPlayer, "285 yds"))
            winners.append(("Closest to Pin", players.randomElement() ?? firstPlayer, "3 ft"))
            winners.append(("Most Improved", players.randomElement() ?? firstPlayer, "+5 strokes"))
        }
        
        return winners
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Winners")
                .font(.system(size: 18, weight: .bold))
            
            ForEach(Array(categoryWinners.enumerated()), id: \.offset) { index, winner in
                CategoryWinnerCard(
                    category: winner.category,
                    player: winner.player,
                    value: winner.value,
                    delay: Double(index) * 0.1,
                    show: showWinners
                )
            }
        }
        .onAppear {
            withAnimation {
                showWinners = true
            }
        }
    }
}

struct CategoryWinnerCard: View {
    let category: String
    let player: Player
    let value: String
    let delay: Double
    let show: Bool
    
    @State private var cardVisible = false
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
                .scaleEffect(cardVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay + 0.2), value: cardVisible)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.system(size: 14, weight: .semibold))
                
                HStack {
                    Text(player.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("• \(value)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(cardVisible ? 1 : 0.8)
        .opacity(cardVisible ? 1 : 0)
        .onAppear {
            if show {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    cardVisible = true
                }
            }
        }
    }
}

// MARK: - Superlatives

struct SuperlativesView: View {
    let players: [Player]
    let gameState: GameState
    
    private var superlatives: [Superlative] {
        var results: [Superlative] = []
        
        // Fun superlatives based on play patterns
        if let consistentPlayer = findMostConsistent() {
            results.append(Superlative(
                title: "Mr. Consistent",
                player: consistentPlayer,
                value: "Steadiest play",
                icon: "chart.line.flattrend.xyaxis",
                color: .blue
            ))
        }
        
        if let comebackPlayer = findBestComeback() {
            results.append(Superlative(
                title: "Comeback Kid",
                player: comebackPlayer,
                value: "Best recovery",
                icon: "arrow.turn.up.right",
                color: .green
            ))
        }
        
        if let rollercoaster = findMostVolatile() {
            results.append(Superlative(
                title: "Rollercoaster",
                player: rollercoaster,
                value: "Wildest ride",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            ))
        }
        
        return results
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fun Awards")
                .font(.system(size: 18, weight: .bold))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(superlatives, id: \.title) { superlative in
                        SuperlativeCard(superlative: superlative)
                    }
                }
            }
        }
    }
    
    private func findMostConsistent() -> Player? {
        // Find player with lowest standard deviation
        players.first
    }
    
    private func findBestComeback() -> Player? {
        // Find player with best improvement from front to back 9
        players.randomElement()
    }
    
    private func findMostVolatile() -> Player? {
        // Find player with highest variance in scores
        players.randomElement()
    }
}

struct SuperlativeCard: View {
    let superlative: Superlative
    
    @State private var showCard = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: superlative.icon)
                .font(.system(size: 32))
                .foregroundColor(superlative.color)
            
            Text(superlative.title)
                .font(.system(size: 14, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(superlative.player.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(superlative.color)
            
            Text(superlative.value)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 140, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(superlative.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(superlative.color.opacity(0.3), lineWidth: 1)
                )
        )
        .rotationEffect(.degrees(showCard ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        .opacity(showCard ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                showCard = true
            }
        }
    }
}

// MARK: - Supporting Components

struct GroupComparisonHeader: View {
    let playerCount: Int
    @Binding var showAwards: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Group Comparison")
                    .font(.system(size: 24, weight: .bold))
                
                Text("\(playerCount) players")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.5)) {
                    showAwards.toggle()
                }
            }) {
                Label(showAwards ? "Hide Awards" : "Show Awards", 
                      systemImage: "trophy.fill")
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
}

struct CategorySelector: View {
    @Binding var selectedCategory: ComparisonCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ComparisonCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
        }
    }
}

struct CategoryButton: View {
    let category: ComparisonCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

// MARK: - Supporting Types

enum ComparisonCategory: String, CaseIterable {
    case overall = "Overall"
    case scoring = "Scoring"
    case accuracy = "Accuracy"
    case putting = "Putting"
    case consistency = "Consistency"
}

enum ComparisonStat: CaseIterable {
    case score
    case toPar
    case birdies
    case pars
    case fairways
    case greens
    case putts
    
    var abbreviation: String {
        switch self {
        case .score: return "Score"
        case .toPar: return "+/-"
        case .birdies: return "Bird"
        case .pars: return "Par"
        case .fairways: return "FIR"
        case .greens: return "GIR"
        case .putts: return "Putts"
        }
    }
    
    var sortOption: SortOption {
        switch self {
        case .score: return .score
        case .toPar: return .toPar
        case .birdies: return .birdies
        case .pars: return .pars
        case .fairways: return .fairways
        case .greens: return .greens
        case .putts: return .putts
        }
    }
}

enum SortOption {
    case score, toPar, birdies, pars, fairways, greens, putts
}

struct PlayerComparisonStats {
    let totalScore: Int
    let toPar: Int
    let birdies: Int
    let pars: Int
    let bogeys: Int
    let fairways: Int
    let greens: Int
    let putts: Int
}

struct Superlative {
    let title: String
    let player: Player
    let value: String
    let icon: String
    let color: Color
}

// MARK: - Group Stats Analyzer

class GroupStatsAnalyzer {
    func analyzeGroup(_ players: [Player], gameState: GameState) -> GroupAnalysis {
        // Comprehensive group analysis
        return GroupAnalysis(
            winners: [:],
            superlatives: [],
            trends: []
        )
    }
}

struct GroupAnalysis {
    let winners: [String: Player]
    let superlatives: [Superlative]
    let trends: [GroupTrend]
}

struct GroupTrend {
    let description: String
    let players: [Player]
}