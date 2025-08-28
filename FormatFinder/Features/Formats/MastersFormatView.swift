import SwiftUI

// MARK: - Masters-Inspired Format Selection View
struct MastersFormatView: View {
    @State private var selectedTab = 1
    @State private var selectedFormat: GolfFormat?
    @State private var showingScorecard = false
    @State private var showingGuide = false
    @State private var showingAnalytics = false
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    
    let formats = GolfFormat.allFormats
    
    var body: some View {
        ZStack {
            // Professional background
            MastersColors.magnoliaLane
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content Area
                formatsContent
                
                // Tab Bar
                MastersTabBar(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showingScorecard) {
            if let format = selectedFormat {
                MastersScorecardView(format: format)
            }
        }
        .sheet(isPresented: $showingGuide) {
            if let format = selectedFormat {
                MastersFormatGuideView(format: format)
            }
        }
        .sheet(isPresented: $showingAnalytics) {
            FormatComparisonVisualizer()
        }
    }
    
    // MARK: - Formats Content
    private var formatsContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header
                    heroHeader
                    
                    // Featured Formats Section
                    featuredFormatsSection
                        .padding(.top, MastersLayout.largeSpacing)
                    
                    // All Formats Grid
                    allFormatsSection
                        .padding(.top, MastersLayout.xLargeSpacing)
                    
                    // Bottom Padding
                    Color.clear
                        .frame(height: MastersLayout.heroSpacing)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: MastersLayout.smallSpacing) {
            // Analytics Button
            HStack {
                Spacer()
                Button(action: { showingAnalytics = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Compare Formats")
                            .font(MastersTypography.captionText())
                            .fontWeight(.medium)
                    }
                    .foregroundColor(MastersColors.mastersGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(MastersColors.mastersGreen.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(MastersColors.mastersGreen.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, MastersLayout.largeSpacing)
            .padding(.top, MastersLayout.largeSpacing)
            
            // Logo Area
            Image(systemName: "flag.fill")
                .font(.system(size: 48))
                .foregroundColor(MastersColors.mastersGreen)
            
            Text("Format Finder")
                .font(MastersTypography.heroTitle())
                .foregroundColor(MastersColors.graphite)
            
            Text("Professional Golf Formats")
                .font(MastersTypography.bodyText())
                .foregroundColor(MastersColors.silver)
                .italic()
            
            // Search Field
            HStack(spacing: MastersLayout.smallSpacing) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(MastersColors.silver)
                
                TextField("Search formats...", text: $searchText)
                    .font(MastersTypography.bodyText())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(MastersColors.fog)
                    }
                }
            }
            .padding(MastersLayout.smallSpacing)
            .background(
                RoundedRectangle(cornerRadius: MastersLayout.standardRadius)
                    .fill(MastersColors.azaleaWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: MastersLayout.standardRadius)
                            .stroke(MastersColors.pearl, lineWidth: 1)
                    )
            )
            .padding(.horizontal, MastersLayout.largeSpacing)
            .padding(.top, MastersLayout.mediumSpacing)
        }
        .padding(.bottom, MastersLayout.largeSpacing)
        .background(
            LinearGradient(
                colors: [
                    MastersColors.fairwayMist,
                    MastersColors.magnoliaLane
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Featured Formats Section
    private var featuredFormatsSection: some View {
        VStack(alignment: .leading, spacing: MastersLayout.standardSpacing) {
            Text("FEATURED FORMATS")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
                .padding(.horizontal, MastersLayout.largeSpacing)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MastersLayout.standardSpacing) {
                    ForEach(featuredFormats) { format in
                        FeaturedFormatCard(
                            format: format,
                            onSelect: {
                                selectedFormat = format
                                showingScorecard = true
                            }
                        )
                    }
                }
                .padding(.horizontal, MastersLayout.largeSpacing)
            }
        }
    }
    
    // MARK: - All Formats Section
    private var allFormatsSection: some View {
        VStack(alignment: .leading, spacing: MastersLayout.standardSpacing) {
            HStack {
                Text("ALL FORMATS")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
                
                Spacer()
                
                Text("\(filteredFormats.count) AVAILABLE")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.fog)
            }
            .padding(.horizontal, MastersLayout.largeSpacing)
            
            VStack(spacing: 1) {
                ForEach(filteredFormats) { format in
                    FormatListRow(
                        format: format,
                        onSelect: {
                            selectedFormat = format
                            showingScorecard = true
                        },
                        onGuide: {
                            selectedFormat = format
                            showingGuide = true
                        }
                    )
                }
            }
            .background(MastersColors.pearl)
        }
    }
    
    // MARK: - Helper Properties
    private var featuredFormats: [GolfFormat] {
        Array(formats.filter { 
            ["Scramble", "Best Ball", "Match Play", "Skins", "Nassau"].contains($0.name) 
        }.prefix(5))
    }
    
    private var filteredFormats: [GolfFormat] {
        if searchText.isEmpty {
            return formats
        }
        return formats.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Featured Format Card
struct FeaturedFormatCard: View {
    let format: GolfFormat
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
                // Icon Section
                HStack {
                    Image(systemName: formatIcon)
                        .font(.system(size: 32))
                        .foregroundColor(MastersColors.mastersGreen)
                    
                    Spacer()
                    
                    formatBadge
                }
                
                VStack(alignment: .leading, spacing: MastersLayout.microSpacing) {
                    Text(format.name.uppercased())
                        .font(MastersTypography.cardTitle())
                        .foregroundColor(MastersColors.graphite)
                    
                    Text(shortDescription)
                        .font(MastersTypography.captionText())
                        .foregroundColor(MastersColors.silver)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                HStack(spacing: MastersLayout.tinySpacing) {
                    playerCountBadge
                    Spacer()
                    difficultyIndicator
                }
            }
            .padding(MastersLayout.standardSpacing)
            .frame(width: 280, height: 160)
            .background(MastersColors.azaleaWhite)
            .cornerRadius(MastersLayout.cardRadius)
            .shadow(
                color: MastersLayout.cardShadow.color,
                radius: MastersLayout.cardShadow.radius,
                x: MastersLayout.cardShadow.x,
                y: MastersLayout.cardShadow.y
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formatIcon: String {
        switch format.name {
        case "Scramble": return "arrow.triangle.merge"
        case "Best Ball": return "star.circle"
        case "Match Play": return "person.2.square.stack"
        case "Skins": return "dollarsign.circle"
        case "Nassau": return "flag.2.crossed"
        default: return "flag"
        }
    }
    
    private var formatBadge: some View {
        Group {
            if ["Scramble", "Best Ball"].contains(format.name) {
                Text("POPULAR")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.augustaGold)
                    .padding(.horizontal, MastersLayout.tinySpacing)
                    .padding(.vertical, MastersLayout.microSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: MastersLayout.smallRadius)
                            .fill(MastersColors.augustaGold.opacity(0.15))
                    )
            }
        }
    }
    
    private var playerCountBadge: some View {
        HStack(spacing: MastersLayout.microSpacing) {
            Image(systemName: "person.2")
                .font(.system(size: 12))
            Text(format.players)
                .font(MastersTypography.microText())
        }
        .foregroundColor(MastersColors.silver)
    }
    
    private var difficultyIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < difficultyLevel ? MastersColors.mastersGreen : MastersColors.pearl)
                    .frame(width: 6, height: 6)
            }
            Text(format.difficulty.uppercased())
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
        }
    }
    
    private var difficultyLevel: Int {
        switch format.difficulty {
        case "Easy": return 1
        case "Medium": return 2
        case "Hard": return 3
        default: return 1
        }
    }
    
    private var shortDescription: String {
        switch format.name {
        case "Scramble": return "Team plays best shot each time"
        case "Best Ball": return "Best individual score counts"
        case "Match Play": return "Win holes, not total strokes"
        case "Skins": return "Win hole outright for the pot"
        case "Nassau": return "Three bets in one round"
        default: return String(format.description.prefix(50))
        }
    }
}

// MARK: - Format List Row
struct FormatListRow: View {
    let format: GolfFormat
    let onSelect: () -> Void
    let onGuide: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: MastersLayout.standardSpacing) {
                // Format Icon
                Image(systemName: formatIcon)
                    .font(.system(size: 24))
                    .foregroundColor(MastersColors.mastersGreen)
                    .frame(width: 40)
                
                // Format Info
                VStack(alignment: .leading, spacing: MastersLayout.microSpacing) {
                    Text(format.name)
                        .font(MastersTypography.dataLabel())
                        .foregroundColor(MastersColors.slate)
                    
                    HStack(spacing: MastersLayout.tinySpacing) {
                        Text(format.players)
                            .font(MastersTypography.captionText())
                            .foregroundColor(MastersColors.silver)
                        
                        Text("•")
                            .foregroundColor(MastersColors.fog)
                        
                        Text(format.difficulty)
                            .font(MastersTypography.captionText())
                            .foregroundColor(MastersColors.silver)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: MastersLayout.smallSpacing) {
                    Button(action: onGuide) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(MastersColors.silver)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MastersColors.fog)
                }
            }
            .padding(.horizontal, MastersLayout.largeSpacing)
            .padding(.vertical, MastersLayout.standardSpacing)
            .background(MastersColors.azaleaWhite)
            .background(isPressed ? MastersColors.fairwayMist : MastersColors.azaleaWhite)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var formatIcon: String {
        switch format.name {
        case "Scramble": return "arrow.triangle.merge"
        case "Best Ball": return "star.circle"
        case "Match Play": return "person.2.square.stack"
        case "Skins": return "dollarsign.circle"
        case "Stableford": return "chart.line.uptrend.xyaxis"
        case "Four-Ball": return "circle.grid.2x2"
        case "Alternate Shot": return "arrow.left.arrow.right.circle"
        case "Nassau": return "flag.2.crossed"
        case "Wolf": return "pawprint"
        case "Vegas": return "die.face.6"
        default: return "flag"
        }
    }
}

// MARK: - Scorecard View
struct MastersScorecardView: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    @State private var currentHole = 1
    @State private var scores: [Int: String] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                MastersColors.magnoliaLane
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation Header
                    navigationHeader
                    
                    // Scorecard Content
                    ScrollView {
                        VStack(spacing: MastersLayout.standardSpacing) {
                            // Hole Navigator
                            holeNavigator
                                .padding(.horizontal, MastersLayout.largeSpacing)
                                .padding(.top, MastersLayout.standardSpacing)
                            
                            // Score Entry
                            scoreEntryCard
                                .padding(.horizontal, MastersLayout.largeSpacing)
                            
                            // Format-Specific Info
                            formatInfoCard
                                .padding(.horizontal, MastersLayout.largeSpacing)
                            
                            // Leaderboard Preview
                            if ["Match Play", "Skins", "Nassau"].contains(format.name) {
                                leaderboardCard
                                    .padding(.horizontal, MastersLayout.largeSpacing)
                            }
                        }
                        .padding(.bottom, MastersLayout.heroSpacing)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var navigationHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: MastersLayout.tinySpacing) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Formats")
                        .font(MastersTypography.dataLabel())
                }
                .foregroundColor(MastersColors.mastersGreen)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(format.name.uppercased())
                    .font(MastersTypography.cardTitle())
                    .foregroundColor(MastersColors.graphite)
                Text("SCORECARD")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(MastersColors.mastersGreen)
            }
        }
        .padding(.horizontal, MastersLayout.largeSpacing)
        .padding(.vertical, MastersLayout.standardSpacing)
        .background(
            MastersColors.azaleaWhite
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        )
    }
    
    private var holeNavigator: some View {
        VStack(spacing: MastersLayout.smallSpacing) {
            HStack {
                Button(action: {
                    if currentHole > 1 {
                        currentHole -= 1
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(currentHole > 1 ? MastersColors.mastersGreen : MastersColors.fog)
                }
                .disabled(currentHole == 1)
                
                Spacer()
                
                VStack(spacing: MastersLayout.microSpacing) {
                    Text("HOLE")
                        .font(MastersTypography.microText())
                        .foregroundColor(MastersColors.silver)
                    Text("\(currentHole)")
                        .font(MastersTypography.heroTitle())
                        .foregroundColor(MastersColors.graphite)
                    Text("PAR 4 • 425 YDS")
                        .font(MastersTypography.captionText())
                        .foregroundColor(MastersColors.silver)
                }
                
                Spacer()
                
                Button(action: {
                    if currentHole < 18 {
                        currentHole += 1
                    }
                }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(currentHole < 18 ? MastersColors.mastersGreen : MastersColors.fog)
                }
                .disabled(currentHole == 18)
            }
            
            // Hole Progress Dots
            HStack(spacing: 6) {
                ForEach(1...18, id: \.self) { hole in
                    Circle()
                        .fill(holeColor(for: hole))
                        .frame(width: hole == currentHole ? 8 : 6, height: hole == currentHole ? 8 : 6)
                }
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
    
    private func holeColor(for hole: Int) -> Color {
        if hole == currentHole { return MastersColors.mastersGreen }
        else if scores[hole] != nil { return MastersColors.augustaGold }
        else { return MastersColors.pearl }
    }
    
    private var scoreEntryCard: some View {
        VStack(spacing: MastersLayout.standardSpacing) {
            Text("SCORE ENTRY")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(1...4, id: \.self) { player in
                MastersPlayerScoreRow(
                    playerNumber: player,
                    playerName: "Player \(player)",
                    score: binding(for: player)
                )
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
    
    private func binding(for player: Int) -> Binding<String> {
        Binding(
            get: { scores[player] ?? "" },
            set: { scores[player] = $0 }
        )
    }
    
    private var formatInfoCard: some View {
        VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
            Text("FORMAT RULES")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            Text(format.description)
                .font(MastersTypography.bodyText())
                .foregroundColor(MastersColors.graphite)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
    
    private var leaderboardCard: some View {
        VStack(spacing: MastersLayout.smallSpacing) {
            HStack {
                Text("CURRENT STANDINGS")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
                Spacer()
            }
            
            ForEach(1...4, id: \.self) { position in
                MastersLeaderboardRow(
                    position: position,
                    player: "Player \(position)",
                    score: position == 1 ? "-3" : position == 2 ? "-1" : position == 3 ? "E" : "+2",
                    thru: "\(currentHole - 1)",
                    isLeader: position == 1
                )
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
}

// MARK: - Player Score Row
struct MastersPlayerScoreRow: View {
    let playerNumber: Int
    let playerName: String
    @Binding var score: String
    
    var playerColor: Color {
        [MastersColors.mastersGreen, MastersColors.augustaGold, MastersColors.scoreRed, MastersColors.par][playerNumber - 1]
    }
    
    var body: some View {
        HStack(spacing: MastersLayout.standardSpacing) {
            // Player Badge
            Circle()
                .fill(playerColor.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Text("\(playerNumber)")
                        .font(MastersTypography.dataLabel())
                        .foregroundColor(playerColor)
                )
            
            // Player Name
            Text(playerName)
                .font(MastersTypography.dataLabel())
                .foregroundColor(MastersColors.graphite)
            
            Spacer()
            
            // Score Input
            HStack(spacing: MastersLayout.tinySpacing) {
                Button(action: {
                    if let currentScore = Int(score), currentScore > 1 {
                        score = "\(currentScore - 1)"
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(MastersColors.silver)
                }
                
                TextField("—", text: $score)
                    .font(MastersTypography.scoreDisplay())
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .padding(.vertical, MastersLayout.tinySpacing)
                    .background(
                        RoundedRectangle(cornerRadius: MastersLayout.smallRadius)
                            .fill(MastersColors.fairwayMist)
                            .overlay(
                                RoundedRectangle(cornerRadius: MastersLayout.smallRadius)
                                    .stroke(MastersColors.pearl, lineWidth: 1)
                            )
                    )
                    .keyboardType(.numberPad)
                
                Button(action: {
                    let currentScore = Int(score) ?? 0
                    score = "\(currentScore + 1)"
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(MastersColors.silver)
                }
            }
        }
    }
}

// MARK: - Format Guide View
struct MastersFormatGuideView: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                MastersColors.magnoliaLane
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: MastersLayout.largeSpacing) {
                        // Format Header
                        formatHeader
                        
                        // Rules Section
                        rulesSection
                            .padding(.horizontal, MastersLayout.largeSpacing)
                        
                        // How to Play Section
                        howToPlaySection
                            .padding(.horizontal, MastersLayout.largeSpacing)
                        
                        // Tips Section
                        tipsSection
                            .padding(.horizontal, MastersLayout.largeSpacing)
                    }
                    .padding(.vertical, MastersLayout.largeSpacing)
                }
            }
            .navigationBarHidden(true)
            .overlay(
                closeButton,
                alignment: .topTrailing
            )
        }
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(MastersColors.silver)
                .background(
                    Circle()
                        .fill(MastersColors.azaleaWhite)
                )
        }
        .padding(MastersLayout.largeSpacing)
    }
    
    private var formatHeader: some View {
        VStack(spacing: MastersLayout.smallSpacing) {
            Image(systemName: formatIcon)
                .font(.system(size: 64))
                .foregroundColor(MastersColors.mastersGreen)
            
            Text(format.name.uppercased())
                .font(MastersTypography.displayTitle())
                .foregroundColor(MastersColors.graphite)
            
            Text(format.players)
                .font(MastersTypography.bodyText())
                .foregroundColor(MastersColors.silver)
        }
        .padding(.top, MastersLayout.heroSpacing)
    }
    
    private var formatIcon: String {
        switch format.name {
        case "Scramble": return "arrow.triangle.merge"
        case "Best Ball": return "star.circle"
        case "Match Play": return "person.2.square.stack"
        case "Skins": return "dollarsign.circle"
        default: return "flag"
        }
    }
    
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: MastersLayout.standardSpacing) {
            Text("RULES")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
                ForEach(Array(format.rules.enumerated()), id: \.offset) { index, rule in
                    HStack(alignment: .top, spacing: MastersLayout.smallSpacing) {
                        Text("\(index + 1).")
                            .font(MastersTypography.dataLabel())
                            .foregroundColor(MastersColors.mastersGreen)
                            .frame(width: 24, alignment: .trailing)
                        
                        Text(rule)
                            .font(MastersTypography.bodyText())
                            .foregroundColor(MastersColors.graphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(MastersLayout.standardSpacing)
            .mastersCard()
        }
    }
    
    private var howToPlaySection: some View {
        VStack(alignment: .leading, spacing: MastersLayout.standardSpacing) {
            Text("HOW TO PLAY")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
                Text(format.description)
                    .font(MastersTypography.bodyText())
                    .foregroundColor(MastersColors.graphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(MastersLayout.standardSpacing)
            .mastersCard()
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: MastersLayout.standardSpacing) {
            Text("PRO TIPS")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
                ForEach(getTips(for: format.name), id: \.self) { tip in
                    HStack(alignment: .top, spacing: MastersLayout.smallSpacing) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 14))
                            .foregroundColor(MastersColors.augustaGold)
                        
                        Text(tip)
                            .font(MastersTypography.captionText())
                            .foregroundColor(MastersColors.graphite)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(MastersLayout.standardSpacing)
            .mastersCard()
        }
    }
    
    private func getTips(for formatName: String) -> [String] {
        switch formatName {
        case "Scramble":
            return [
                "Let each player use their strengths - long hitters tee off, good putters handle the greens",
                "Don't always choose the longest drive - position matters more than distance",
                "Save your mulligans for critical moments"
            ]
        case "Match Play":
            return [
                "Play the hole, not your total score",
                "Take calculated risks when down in the match",
                "Concede short putts to maintain pace and sportsmanship"
            ]
        case "Skins":
            return [
                "Be aggressive when skins carry over - the pot grows quickly",
                "Focus on winning holes outright, ties mean no winner",
                "Consider strategic play on holes where opponents are struggling"
            ]
        default:
            return [
                "Know the format rules before starting",
                "Communicate clearly with your partners",
                "Keep accurate scores throughout the round"
            ]
        }
    }
}

// MARK: - Masters Tab Bar
struct MastersTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...4, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(for: tab))
                            .font(.system(size: 22))
                        Text(tabTitle(for: tab))
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? MastersColors.mastersGreen : MastersColors.silver)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(MastersColors.magnoliaLane)
        .overlay(
            Rectangle()
                .fill(MastersColors.divider.opacity(0.3))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    private func tabIcon(for tab: Int) -> String {
        switch tab {
        case 1: return "square.grid.2x2"
        case 2: return "star.fill"
        case 3: return "chart.bar.fill"
        case 4: return "gear"
        default: return "circle"
        }
    }
    
    private func tabTitle(for tab: Int) -> String {
        switch tab {
        case 1: return "Formats"
        case 2: return "Featured"
        case 3: return "Stats"
        case 4: return "Settings"
        default: return "Tab"
        }
    }
}

// MARK: - Masters Leaderboard Row
struct MastersLeaderboardRow: View {
    let position: Int
    let playerName: String
    let score: Int
    let parDiff: String
    
    var body: some View {
        HStack {
            Text("\(position)")
                .font(.headline)
                .foregroundColor(MastersColors.mastersGreen)
                .frame(width: 30)
            
            Text(playerName)
                .font(.body)
            
            Spacer()
            
            Text(parDiff)
                .font(.headline)
                .foregroundColor(scoreColor)
            
            Text("\(score)")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var scoreColor: Color {
        if parDiff.starts(with: "-") {
            return MastersColors.mastersGreen
        } else if parDiff == "E" {
            return MastersColors.graphite
        } else {
            return MastersColors.scoreRed
        }
    }
}

// MARK: - View Extensions
extension View {
    func mastersCard() -> some View {
        self
            .background(MastersColors.azaleaWhite)
            .cornerRadius(MastersLayout.cardRadius)
            .shadow(
                color: MastersColors.shadow,
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

#Preview {
    MastersFormatView()
}