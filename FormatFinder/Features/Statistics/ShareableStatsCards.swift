import SwiftUI
import UIKit

// MARK: - Shareable Statistics Cards

struct ShareableStatsView: View {
    let round: Round
    let player: Player
    let gameState: GameState
    
    @State private var selectedCardStyle: CardStyle = .wrapped
    @State private var isGeneratingCard = false
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false
    
    private let generator = ShareableStatsGenerator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Card Style Selector
                CardStyleSelector(selectedStyle: $selectedCardStyle)
                
                // Preview Card
                ShareableCardPreview(
                    round: round,
                    player: player,
                    style: selectedCardStyle,
                    stats: calculateRoundStats()
                )
                .scaleEffect(0.9)
                .shadow(radius: 10)
                
                // Quick Stats for Card
                QuickShareStats(stats: calculateRoundStats())
                
                // Share Actions
                ShareActionsBar(
                    isGenerating: isGeneratingCard,
                    onShare: shareCard,
                    onSaveToPhotos: saveToPhotos,
                    onShareToStory: shareToStory
                )
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    private func calculateRoundStats() -> RoundStatistics {
        // Calculate comprehensive stats
        let scores = getScores()
        let pars = getPars()
        
        return RoundStatistics(
            totalScore: scores.reduce(0, +),
            toPar: calculateToPar(scores: scores, pars: pars),
            birdies: countBirdies(scores: scores, pars: pars),
            pars: countPars(scores: scores, pars: pars),
            bogeys: countBogeys(scores: scores, pars: pars),
            bestHole: findBestHole(scores: scores, pars: pars),
            worstHole: findWorstHole(scores: scores, pars: pars),
            longestStreak: findLongestStreak(scores: scores, pars: pars),
            signature: generateSignature(scores: scores)
        )
    }
    
    private func shareCard() {
        isGeneratingCard = true
        
        Task {
            let image = await generator.generateStatsCard(
                for: round,
                player: player,
                style: selectedCardStyle,
                stats: calculateRoundStats()
            )
            
            await MainActor.run {
                shareImage = image
                showShareSheet = true
                isGeneratingCard = false
            }
        }
    }
    
    private func saveToPhotos() {
        // Save to photo library
    }
    
    private func shareToStory() {
        // Share to Instagram/Facebook story
    }
    
    // Helper functions
    private func getScores() -> [Int] {
        var scores: [Int] = []
        for hole in 1...18 {
            if let score = gameState.scores[hole]?[player.id] {
                scores.append(score)
            }
        }
        return scores
    }
    
    private func getPars() -> [Int] {
        // TODO: Get from course data
        return Array(repeating: 4, count: 18)
    }
    
    private func calculateToPar(scores: [Int], pars: [Int]) -> Int {
        return scores.enumerated().reduce(0) { $0 + ($1.element - pars[$1.offset]) }
    }
    
    private func countBirdies(scores: [Int], pars: [Int]) -> Int {
        return scores.enumerated().filter { $0.element < pars[$0.offset] }.count
    }
    
    private func countPars(scores: [Int], pars: [Int]) -> Int {
        return scores.enumerated().filter { $0.element == pars[$0.offset] }.count
    }
    
    private func countBogeys(scores: [Int], pars: [Int]) -> Int {
        return scores.enumerated().filter { $0.element == pars[$0.offset] + 1 }.count
    }
    
    private func findBestHole(scores: [Int], pars: [Int]) -> (hole: Int, score: Int)? {
        guard !scores.isEmpty else { return nil }
        let diffs = scores.enumerated().map { ($0.offset + 1, $0.element - pars[$0.offset]) }
        let best = diffs.min { $0.1 < $1.1 }
        if let best = best, let score = scores[safe: best.0 - 1] {
            return (best.0, score)
        }
        return nil
    }
    
    private func findWorstHole(scores: [Int], pars: [Int]) -> (hole: Int, score: Int)? {
        guard !scores.isEmpty else { return nil }
        let diffs = scores.enumerated().map { ($0.offset + 1, $0.element - pars[$0.offset]) }
        let worst = diffs.max { $0.1 < $1.1 }
        if let worst = worst, let score = scores[safe: worst.0 - 1] {
            return (worst.0, score)
        }
        return nil
    }
    
    private func findLongestStreak(scores: [Int], pars: [Int]) -> StreakType {
        // Find longest streak of pars or better
        var currentStreak = 0
        var maxStreak = 0
        var streakType = StreakType.pars
        
        for (index, score) in scores.enumerated() {
            if score <= pars[index] {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return StreakType.pars // Simplified
    }
    
    private func generateSignature(scores: [Int]) -> String {
        // Generate unique visual signature for the round
        return scores.map { "\($0)" }.joined()
    }
}

// MARK: - Shareable Card Preview

struct ShareableCardPreview: View {
    let round: Round
    let player: Player
    let style: CardStyle
    let stats: RoundStatistics
    
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Background gradient based on performance
            backgroundGradient
            
            VStack(spacing: 0) {
                // Header
                cardHeader
                
                // Main Stats Display
                mainStatsDisplay
                
                // Visual Signature
                roundSignature
                
                // Footer
                cardFooter
            }
            .padding()
        }
        .frame(width: 350, height: 600)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(animateIn ? 1 : 0.9)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateIn = true
            }
        }
    }
    
    private var backgroundGradient: some View {
        Group {
            switch style {
            case .wrapped:
                LinearGradient(
                    colors: performanceColors(),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
            case .minimal:
                Color.white
                
            case .vibrant:
                MeshGradient(
                    colors: vibrantColors(),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
            case .dark:
                LinearGradient(
                    colors: [.black, Color(white: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
    
    private var cardHeader: some View {
        VStack(spacing: 8) {
            Text(round.course)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(headerTextColor)
            
            Text(round.date.formatted(date: .long, time: .omitted))
                .font(.system(size: 14))
                .foregroundColor(headerTextColor.opacity(0.8))
            
            Text(player.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(headerTextColor)
        }
        .padding(.vertical, 20)
    }
    
    private var mainStatsDisplay: some View {
        VStack(spacing: 24) {
            // Big Score
            VStack(spacing: 4) {
                Text("\(stats.totalScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
                
                Text(formatToPar(stats.toPar))
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(scoreColor.opacity(0.8))
            }
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatBadge(value: "\(stats.birdies)", label: "Birdies", color: .green)
                StatBadge(value: "\(stats.pars)", label: "Pars", color: .blue)
                StatBadge(value: "\(stats.bogeys)", label: "Bogeys", color: .orange)
            }
            
            // Highlights
            if let bestHole = stats.bestHole {
                HighlightBadge(
                    title: "Best Hole",
                    value: "Hole \(bestHole.hole): \(bestHole.score)",
                    icon: "star.fill",
                    color: .yellow
                )
            }
            
            if stats.longestStreak == .birdies && stats.birdies >= 2 {
                HighlightBadge(
                    title: "On Fire!",
                    value: "\(stats.birdies) birdies",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding(.vertical, 20)
    }
    
    private var roundSignature: some View {
        HStack(spacing: 2) {
            ForEach(0..<18, id: \.self) { hole in
                RoundedRectangle(cornerRadius: 2)
                    .fill(signatureColor(for: hole))
                    .frame(width: 15, height: 40)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var cardFooter: some View {
        HStack {
            Image(systemName: "flag.fill")
                .font(.system(size: 20))
                .foregroundColor(headerTextColor.opacity(0.6))
            
            Text("Format Finder")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(headerTextColor.opacity(0.6))
            
            Spacer()
            
            Text("#MyGolfRound")
                .font(.system(size: 14))
                .foregroundColor(headerTextColor.opacity(0.6))
        }
        .padding(.vertical, 12)
    }
    
    // Helper computed properties
    private var headerTextColor: Color {
        style == .minimal ? .black : .white
    }
    
    private var scoreColor: Color {
        if stats.toPar < 0 { return style == .minimal ? .green : .white }
        if stats.toPar == 0 { return style == .minimal ? .blue : .white }
        return style == .minimal ? .red : .white
    }
    
    private func performanceColors() -> [Color] {
        if stats.toPar < 0 {
            return [Color(hex: "1DB954"), Color(hex: "191414")] // Spotify-like green
        } else if stats.toPar < 5 {
            return [Color(hex: "509BF5"), Color(hex: "1E3264")] // Blue theme
        } else {
            return [Color(hex: "E22134"), Color(hex: "450B0B")] // Red theme
        }
    }
    
    private func vibrantColors() -> [Color] {
        [.purple, .pink, .orange, .yellow]
    }
    
    private func signatureColor(for hole: Int) -> Color {
        // Generate color based on score relative to par
        guard hole < 18 else { return .gray }
        // Simplified - would use actual scores
        return [.green, .blue, .orange, .red].randomElement() ?? .gray
    }
    
    private func formatToPar(_ toPar: Int) -> String {
        if toPar == 0 { return "Even" }
        if toPar > 0 { return "+\(toPar)" }
        return "\(toPar)"
    }
}

// MARK: - Stat Badge Components

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.3))
        .cornerRadius(12)
    }
}

struct HighlightBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Share Actions

struct ShareActionsBar: View {
    let isGenerating: Bool
    let onShare: () -> Void
    let onSaveToPhotos: () -> Void
    let onShareToStory: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onShare) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Text(isGenerating ? "Generating..." : "Share Card")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isGenerating)
            
            HStack(spacing: 12) {
                Button(action: onSaveToPhotos) {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: onShareToStory) {
                    Label("Story", systemImage: "camera.fill")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Card Style Selector

struct CardStyleSelector: View {
    @Binding var selectedStyle: CardStyle
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CardStyle.allCases, id: \.self) { style in
                    CardStyleButton(
                        style: style,
                        isSelected: selectedStyle == style,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedStyle = style
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CardStyleButton: View {
    let style: CardStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(style.previewGradient)
                    .frame(width: 60, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                Text(style.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

// MARK: - Quick Share Stats

struct QuickShareStats: View {
    let stats: RoundStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Round Highlights")
                .font(.system(size: 16, weight: .semibold))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickStatItem(icon: "flag", value: "\(stats.totalScore)", label: "Total")
                QuickStatItem(icon: "chart.line.uptrend.xyaxis", value: formatToPar(stats.toPar), label: "To Par")
                QuickStatItem(icon: "star", value: "\(stats.birdies)", label: "Birdies")
                QuickStatItem(icon: "checkmark.circle", value: "\(stats.pars)", label: "Pars")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatToPar(_ toPar: Int) -> String {
        if toPar == 0 { return "E" }
        if toPar > 0 { return "+\(toPar)" }
        return "\(toPar)"
    }
}

struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

enum CardStyle: String, CaseIterable {
    case wrapped = "Wrapped"
    case minimal = "Minimal"
    case vibrant = "Vibrant"
    case dark = "Dark"
    
    var previewGradient: LinearGradient {
        switch self {
        case .wrapped:
            return LinearGradient(colors: [.green, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .minimal:
            return LinearGradient(colors: [.white, .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
        case .vibrant:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct RoundStatistics {
    let totalScore: Int
    let toPar: Int
    let birdies: Int
    let pars: Int
    let bogeys: Int
    let bestHole: (hole: Int, score: Int)?
    let worstHole: (hole: Int, score: Int)?
    let longestStreak: StreakType
    let signature: String
}

enum StreakType {
    case birdies
    case pars
    case bogeys
}

// MARK: - Shareable Stats Generator

class ShareableStatsGenerator {
    func generateStatsCard(
        for round: Round,
        player: Player,
        style: CardStyle,
        stats: RoundStatistics
    ) async -> UIImage {
        // Create SwiftUI view
        let cardView = ShareableCardPreview(
            round: round,
            player: player,
            style: style,
            stats: stats
        )
        
        // Convert to UIImage
        let controller = UIHostingController(rootView: cardView)
        controller.view.frame = CGRect(x: 0, y: 0, width: 350, height: 600)
        
        let renderer = UIGraphicsImageRenderer(size: controller.view.frame.size)
        let image = renderer.image { context in
            controller.view.layer.render(in: context.cgContext)
        }
        
        return image
    }
    
    func createComparisonTable(_ players: [Player]) -> ComparisonData {
        // TODO: Calculate category winners
        return ComparisonData(winners: [:], superlatives: [])
    }
}

struct ComparisonData {
    let winners: [String: Player]
    let superlatives: [Superlative]
}

struct Superlative {
    let title: String
    let player: Player
    let value: String
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Helpers

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


// Mesh gradient placeholder (iOS 18+)
struct MeshGradient: View {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    
    var body: some View {
        LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
    }
}