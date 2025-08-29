import SwiftUI
import Combine

// MARK: - Swipeable Format Cards View
struct SwipeableFormatCards: View {
    @StateObject private var viewModel = FormatCardsViewModel()
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var activeCard: Int? = 0
    @State private var expandedCard: String? = nil
    @State private var searchText = ""
    @State private var filterCriteria = FilterCriteria()
    @State private var selectedFormatForDemo: GolfFormat? = nil
    @State private var showFormatDemo = false
    
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme
    
    let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var filteredFormats: [EnhancedGolfFormat] {
        viewModel.formats.filter { format in
            let matchesSearch = searchText.isEmpty || 
                format.name.localizedCaseInsensitiveContains(searchText) ||
                format.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesGroupSize = filterCriteria.groupSize == nil ||
                format.idealGroupSize.contains(filterCriteria.groupSize!)
            
            let matchesDifficulty = filterCriteria.difficulty == nil ||
                format.difficulty == filterCriteria.difficulty
            
            return matchesSearch && matchesGroupSize && matchesDifficulty
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "F0F7F2"), // Light green
                    Color(hex: "FFFFFF")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search and Filter Bar
                searchFilterBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                
                // Swipeable Cards
                GeometryReader { geometry in
                    ZStack {
                        ForEach(Array(filteredFormats.enumerated()), id: \.element.id) { index, format in
                            if index >= currentIndex - 2 && index <= currentIndex + 2 {
                                FormatCard(
                                    format: format,
                                    geometry: geometry,
                                    index: index,
                                    currentIndex: $currentIndex,
                                    dragOffset: $dragOffset,
                                    isExpanded: expandedCard == format.id,
                                    namespace: animation,
                                    selectedFormatForDemo: $selectedFormatForDemo,
                                    showFormatDemo: $showFormatDemo,
                                    onTap: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            if expandedCard == format.id {
                                                expandedCard = nil
                                            } else {
                                                expandedCard = format.id
                                            }
                                        }
                                    },
                                    onSwipe: { direction in
                                        handleSwipe(direction: direction, totalCount: filteredFormats.count)
                                    }
                                )
                                .zIndex(Double(filteredFormats.count - abs(index - currentIndex)))
                                .offset(x: cardOffset(for: index, in: geometry))
                                .scaleEffect(cardScale(for: index))
                                .opacity(cardOpacity(for: index))
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentIndex)
                                .animation(.spring(response: 0.3, dampingFraction: 0.9), value: dragOffset)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Card Navigation Dots
                cardNavigationDots
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            viewModel.loadFormats()
        }
        .sheet(isPresented: $showFormatDemo) {
            if let format = selectedFormatForDemo {
                FormatDemonstrationView(format: format)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Golf Formats")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1C1C1E"))
                    
                    Text("Swipe to discover • Tap for details")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
                
                // Info Button
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "006747"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
        }
        .background(
            Color.white
                .ignoresSafeArea(edges: .top)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
    
    // MARK: - Search Filter Bar
    private var searchFilterBar: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search formats...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            
            // Filter Button
            Menu {
                Section("Group Size") {
                    ForEach(2...4, id: \.self) { size in
                        Button(action: { filterCriteria.groupSize = size }) {
                            Label("\(size) Players", systemImage: filterCriteria.groupSize == size ? "checkmark" : "")
                        }
                    }
                    Button("Any Size") { filterCriteria.groupSize = nil }
                }
                
                Section("Difficulty") {
                    ForEach(["Easy", "Medium", "Hard"], id: \.self) { difficulty in
                        Button(action: { filterCriteria.difficulty = difficulty }) {
                            Label(difficulty, systemImage: filterCriteria.difficulty == difficulty ? "checkmark" : "")
                        }
                    }
                    Button("Any Difficulty") { filterCriteria.difficulty = nil }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "006747"))
                    .padding(10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Card Navigation Dots
    private var cardNavigationDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<filteredFormats.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color(hex: "006747") : Color.gray.opacity(0.3))
                    .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                    .animation(.spring(response: 0.3), value: currentIndex)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Helper Methods
    private func cardOffset(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let difference = CGFloat(index - currentIndex)
        let baseOffset = difference * 30
        
        if index == currentIndex {
            return dragOffset.width
        }
        
        return baseOffset
    }
    
    private func cardScale(for index: Int) -> CGFloat {
        let difference = abs(currentIndex - index)
        if difference == 0 {
            return 1.0 - abs(dragOffset.width) / 1000
        }
        return max(0.85, 1.0 - CGFloat(difference) * 0.05)
    }
    
    private func cardOpacity(for index: Int) -> Double {
        let difference = abs(currentIndex - index)
        if difference == 0 { return 1.0 }
        if difference == 1 { return 0.8 }
        return 0.5
    }
    
    private func handleSwipe(direction: SwipeDirection, totalCount: Int) {
        hapticFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch direction {
            case .left:
                currentIndex = min(currentIndex + 1, totalCount - 1)
            case .right:
                currentIndex = max(currentIndex - 1, 0)
            }
            dragOffset = .zero
        }
    }
}

// MARK: - Format Card Component
struct FormatCard: View {
    let format: EnhancedGolfFormat
    let geometry: GeometryProxy
    let index: Int
    @Binding var currentIndex: Int
    @Binding var dragOffset: CGSize
    let isExpanded: Bool
    let namespace: Namespace.ID
    @Binding var selectedFormatForDemo: GolfFormat?
    @Binding var showFormatDemo: Bool
    let onTap: () -> Void
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var animationPhase: Double = 0
    @State private var showFullRules = false
    
    var isActive: Bool {
        index == currentIndex
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
            } else {
                compactView
            }
        }
        .frame(width: geometry.size.width * 0.85)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(
                    color: .black.opacity(isActive ? 0.15 : 0.1),
                    radius: isActive ? 20 : 10,
                    y: isActive ? 10 : 5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isActive ? Color(hex: "006747").opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .offset(y: isActive ? -20 : 0)
        .gesture(
            isActive ? DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    if abs(value.translation.width) > threshold {
                        if value.translation.width > 0 {
                            onSwipe(.right)
                        } else {
                            onSwipe(.left)
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                } : nil
        )
        .onTapGesture {
            if isActive {
                onTap()
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
    }
    
    // MARK: - Compact View
    private var compactView: some View {
        VStack(spacing: 0) {
            // Header
            formatHeader
                .padding(20)
            
            // Animated Diagram
            AnimatedFormatDiagram(
                format: format,
                animationPhase: animationPhase,
                isPlaying: isActive
            )
            .frame(height: 200)
            .padding(.horizontal, 20)
            
            // Quick Info
            VStack(alignment: .leading, spacing: 12) {
                // Bullet Points
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(format.quickRules.prefix(3), id: \.self) { rule in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color(hex: "006747"))
                                .frame(width: 6, height: 6)
                                .offset(y: 6)
                            
                            Text(rule)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // How to Score
                VStack(alignment: .leading, spacing: 4) {
                    Text("HOW TO SCORE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(format.scoringMethod)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
                .padding(.top, 8)
            }
            .padding(20)
            
            // Footer
            HStack {
                // Group Size
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                    Text("\(format.idealGroupSize.lowerBound)-\(format.idealGroupSize.upperBound) Players")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Tap for Details
                if isActive {
                    Text("TAP FOR DETAILS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "006747"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "006747").opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Expanded View
    private var expandedView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                formatHeader
                    .padding(20)
                
                // Animated Diagram
                AnimatedFormatDiagram(
                    format: format,
                    animationPhase: animationPhase,
                    isPlaying: true
                )
                .frame(height: 250)
                .padding(.horizontal, 20)
                
                // Watch Demo Button
                Button(action: {
                    // Convert EnhancedGolfFormat to GolfFormat for demo
                    let golfFormat = GolfFormat(
                        id: format.id,
                        name: format.name,
                        description: format.description,
                        players: "\(format.idealGroupSize.first ?? 2)-\(format.idealGroupSize.last ?? 4) Players",
                        difficulty: format.difficulty.rawValue,
                        pace: format.pace.rawValue,
                        scoring: format.scoringType.rawValue,
                        teamBased: format.isTeamFormat,
                        handicapFriendly: format.isHandicapFriendly,
                        strategy: format.strategy,
                        funFactor: format.funFactor
                    )
                    selectedFormatForDemo = golfFormat
                    showFormatDemo = true
                }) {
                    HStack {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 16))
                        Text("Watch Broadcast Demo")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.5, blue: 0.25),
                                Color(red: 0.0, green: 0.4, blue: 0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 16)
                
                // Full Rules Section
                VStack(alignment: .leading, spacing: 16) {
                    // Description
                    Text(format.description)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    
                    // Complete Rules
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COMPLETE RULES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(format.completeRules.enumerated()), id: \.offset) { index, rule in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1).")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "006747"))
                                    .frame(width: 20, alignment: .trailing)
                                
                                Text(rule)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    
                    // Scoring Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SCORING DETAILS")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(format.detailedScoring)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    
                    // Pro Tips
                    if !format.proTips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRO TIPS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            ForEach(format.proTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "FFD700"))
                                    
                                    Text(tip)
                                        .font(.system(size: 13))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                
                // Close Button
                Button(action: onTap) {
                    Text("CLOSE")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "006747"))
                        .cornerRadius(12)
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Format Header
    private var formatHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(format.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Difficulty Badge
                FormatDifficultyBadge(difficulty: format.difficulty)
            }
            
            Text(format.tagline)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Animation
    private func startAnimation() {
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            animationPhase = 1
        }
    }
}

// MARK: - Animated Format Diagram
struct AnimatedFormatDiagram: View {
    let format: EnhancedGolfFormat
    let animationPhase: Double
    let isPlaying: Bool
    
    @State private var localPhase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Golf Course Background
                GolfCourseCanvas(size: geometry.size)
                
                // Format-specific animation
                switch format.name {
                case "Scramble":
                    ScrambleAnimation(
                        phase: isPlaying ? localPhase : 0,
                        size: geometry.size
                    )
                case "Best Ball":
                    BestBallAnimation(
                        phase: isPlaying ? localPhase : 0,
                        size: geometry.size
                    )
                case "Match Play":
                    MatchPlayAnimation(
                        phase: isPlaying ? localPhase : 0,
                        size: geometry.size
                    )
                case "Skins":
                    SkinsAnimation(
                        phase: isPlaying ? localPhase : 0,
                        size: geometry.size
                    )
                case "Stableford":
                    StablefordAnimation(
                        phase: isPlaying ? localPhase : 0,
                        size: geometry.size
                    )
                default:
                    DefaultFormatAnimation(
                        phase: isPlaying ? localPhase : 0,
                        size: geometry.size
                    )
                }
            }
        }
        .onAppear {
            if isPlaying {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    localPhase = 1
                }
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    localPhase = 1
                }
            } else {
                withAnimation(.linear(duration: 0.3)) {
                    localPhase = 0
                }
            }
        }
    }
}

// MARK: - Golf Course Canvas
struct GolfCourseCanvas: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Fairway
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.9))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.9, y: size.height * 0.1),
                    control1: CGPoint(x: size.width * 0.3, y: size.height * 0.7),
                    control2: CGPoint(x: size.width * 0.7, y: size.height * 0.3)
                )
                path.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.3))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.1, y: size.height),
                    control1: CGPoint(x: size.width * 0.6, y: size.height * 0.5),
                    control2: CGPoint(x: size.width * 0.4, y: size.height * 0.8)
                )
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "7CB342"),
                        Color(hex: "689F38")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Tee Box
            Circle()
                .fill(Color(hex: "4CAF50"))
                .frame(width: 30, height: 30)
                .position(x: size.width * 0.15, y: size.height * 0.85)
            
            // Green
            Circle()
                .fill(Color(hex: "2E7D32"))
                .frame(width: 50, height: 50)
                .position(x: size.width * 0.85, y: size.height * 0.2)
            
            // Flag
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.85, y: size.height * 0.2))
                path.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.05))
            }
            .stroke(Color.white, lineWidth: 2)
            
            // Flag Triangle
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.85, y: size.height * 0.05))
                path.addLine(to: CGPoint(x: size.width * 0.92, y: size.height * 0.08))
                path.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.11))
                path.closeSubpath()
            }
            .fill(Color.red)
        }
    }
}

// MARK: - Format-Specific Animations

struct ScrambleAnimation: View {
    let phase: Double
    let size: CGSize
    
    var body: some View {
        ZStack {
            // All players' balls at tee
            ForEach(0..<4) { player in
                Circle()
                    .fill(playerColor(for: player))
                    .frame(width: 8, height: 8)
                    .position(
                        x: size.width * 0.15 + CGFloat(player * 5),
                        y: size.height * 0.85
                    )
                    .opacity(phase < 0.25 ? 1 : 0)
            }
            
            // Balls flying to different positions
            ForEach(0..<4) { player in
                if phase >= 0.25 && phase < 0.5 {
                    Circle()
                        .fill(playerColor(for: player))
                        .frame(width: 8, height: 8)
                        .position(ballPosition(for: player, at: (phase - 0.25) * 4))
                }
            }
            
            // Best ball selection indicator
            if phase >= 0.5 && phase < 0.75 {
                Circle()
                    .stroke(Color(hex: "FFD700"), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .position(ballPosition(for: 1, at: 1)) // Best ball
                    .scaleEffect(1 + sin(phase * .pi * 8) * 0.2)
                
                Text("BEST")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
                    .position(
                        x: ballPosition(for: 1, at: 1).x,
                        y: ballPosition(for: 1, at: 1).y - 20
                    )
            }
            
            // All players play from best position
            if phase >= 0.75 {
                ForEach(0..<4) { player in
                    Circle()
                        .fill(playerColor(for: player).opacity(0.8))
                        .frame(width: 8, height: 8)
                        .position(
                            x: ballPosition(for: 1, at: 1).x,
                            y: ballPosition(for: 1, at: 1).y
                        )
                        .offset(x: CGFloat(player - 2) * 10)
                }
            }
        }
    }
    
    private func ballPosition(for player: Int, at progress: Double) -> CGPoint {
        let startX = size.width * 0.15
        let startY = size.height * 0.85
        let endX = size.width * (0.4 + Double(player) * 0.1)
        let endY = size.height * (0.5 + Double(player % 2) * 0.1)
        
        let x = startX + (endX - startX) * progress
        let y = startY + (endY - startY) * progress - sin(progress * .pi) * 30
        
        return CGPoint(x: x, y: y)
    }
    
    private func playerColor(for player: Int) -> Color {
        [Color.blue, Color.green, Color.orange, Color.purple][player]
    }
}

struct BestBallAnimation: View {
    let phase: Double
    let size: CGSize
    
    var body: some View {
        ZStack {
            ForEach(0..<4) { player in
                // Player paths
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.85))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width * 0.85, y: size.height * 0.2),
                        control: CGPoint(
                            x: size.width * (0.3 + Double(player) * 0.15),
                            y: size.height * (0.4 + Double(player % 2) * 0.2)
                        )
                    )
                }
                .trim(from: 0, to: phase)
                .stroke(playerColor(for: player).opacity(0.5), lineWidth: 2)
                
                // Player balls
                Circle()
                    .fill(playerColor(for: player))
                    .frame(width: 10, height: 10)
                    .position(ballPosition(for: player, at: phase))
                
                // Score indicators
                if phase > 0.8 {
                    Text("\(4 + player)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(playerColor(for: player))
                        .position(
                            x: size.width * 0.85 + CGFloat(player - 2) * 20,
                            y: size.height * 0.35
                        )
                }
            }
            
            // Best score highlight
            if phase > 0.9 {
                Text("BEST: 4")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(radius: 4)
                    )
                    .position(x: size.width * 0.5, y: size.height * 0.5)
            }
        }
    }
    
    private func ballPosition(for player: Int, at progress: Double) -> CGPoint {
        let path = CGPoint(
            x: size.width * 0.15 + (size.width * 0.7) * progress,
            y: size.height * 0.85 - (size.height * 0.65) * progress + sin(progress * .pi) * 30
        )
        return path
    }
    
    private func playerColor(for player: Int) -> Color {
        [Color.blue, Color.green, Color.orange, Color.purple][player]
    }
}

// Default animation for other formats
struct DefaultFormatAnimation: View {
    let phase: Double
    let size: CGSize
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 10, height: 10)
            .position(
                x: size.width * (0.15 + 0.7 * phase),
                y: size.height * (0.85 - 0.65 * phase)
            )
    }
}

struct MatchPlayAnimation: View {
    let phase: Double
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Player 1 vs Player 2 indicator
            if phase < 0.5 {
                HStack(spacing: 20) {
                    PlayerAvatar(color: .blue, number: "1")
                    Text("VS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "006747"))
                    PlayerAvatar(color: .red, number: "2")
                }
                .position(x: size.width * 0.5, y: size.height * 0.5)
                .scaleEffect(1 + sin(phase * .pi * 4) * 0.1)
            }
            
            // Hole winner indication
            if phase >= 0.5 {
                VStack(spacing: 12) {
                    Text("HOLE 1")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            PlayerAvatar(color: .blue, number: "1")
                            Text("4")
                                .font(.system(size: 14, weight: .bold))
                        }
                        
                        VStack(spacing: 4) {
                            PlayerAvatar(color: .red, number: "2")
                            Text("5")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    
                    Text("Player 1 Wins")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "006747"))
                        .opacity((phase - 0.5) * 2)
                }
                .position(x: size.width * 0.5, y: size.height * 0.5)
            }
        }
    }
}

struct SkinsAnimation: View {
    let phase: Double
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Money pot indicator
            VStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "FFD700"))
                    .scaleEffect(1 + sin(phase * .pi * 4) * 0.1)
                
                Text("$10 SKIN")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "006747"))
            }
            .position(x: size.width * 0.5, y: size.height * 0.3)
            
            // Players competing
            HStack(spacing: 15) {
                ForEach(0..<4) { player in
                    PlayerAvatar(
                        color: [Color.blue, Color.green, Color.orange, Color.purple][player],
                        number: "\(player + 1)"
                    )
                    .scaleEffect(phase > 0.5 && player == 1 ? 1.2 : 1.0)
                }
            }
            .position(x: size.width * 0.5, y: size.height * 0.6)
            
            // Winner indication
            if phase > 0.7 {
                Text("Player 2 Wins!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "FFD700"))
                    .position(x: size.width * 0.5, y: size.height * 0.8)
                    .opacity((phase - 0.7) * 3)
            }
        }
    }
}

struct StablefordAnimation: View {
    let phase: Double
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Points system display
            VStack(alignment: .leading, spacing: 6) {
                StablefordPointRow(score: "Eagle", points: 4, highlight: phase > 0.2)
                StablefordPointRow(score: "Birdie", points: 3, highlight: phase > 0.4)
                StablefordPointRow(score: "Par", points: 2, highlight: phase > 0.6)
                StablefordPointRow(score: "Bogey", points: 1, highlight: phase > 0.8)
                StablefordPointRow(score: "Double+", points: 0, highlight: false)
            }
            .position(x: size.width * 0.3, y: size.height * 0.5)
            
            // Score accumulation
            if phase > 0.5 {
                VStack(spacing: 8) {
                    Text("Total Points")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(phase * 36))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "006747"))
                }
                .position(x: size.width * 0.7, y: size.height * 0.5)
            }
        }
    }
}

struct StablefordPointRow: View {
    let score: String
    let points: Int
    let highlight: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text(score)
                .font(.system(size: 12))
                .foregroundColor(highlight ? .primary : .secondary)
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(0..<points, id: \.self) { _ in
                    Circle()
                        .fill(highlight ? Color(hex: "FFD700") : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(width: 100)
        .scaleEffect(highlight ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: highlight)
    }
}

// MARK: - Supporting Components

struct PlayerAvatar: View {
    let color: Color
    let number: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct FormatDifficultyBadge: View {
    let difficulty: String
    
    var difficultyColor: Color {
        switch difficulty {
        case "Easy": return Color.green
        case "Medium": return Color.orange
        case "Hard": return Color.red
        default: return Color.gray
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < difficultyLevel ? difficultyColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            
            Text(difficulty.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(difficultyColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(difficultyColor.opacity(0.1))
        )
    }
    
    private var difficultyLevel: Int {
        switch difficulty {
        case "Easy": return 1
        case "Medium": return 2
        case "Hard": return 3
        default: return 1
        }
    }
}

// MARK: - Data Models

struct EnhancedGolfFormat: Identifiable, Codable {
    let id = UUID().uuidString
    let name: String
    let tagline: String
    let difficulty: String
    let description: String
    let quickRules: [String]
    let completeRules: [String]
    let scoringMethod: String
    let detailedScoring: String
    let idealGroupSize: ClosedRange<Int>
    let proTips: [String]
    let animationType: FormatAnimationType
    
    var isCompetitive: Bool {
        ["Match Play", "Skins", "Nassau", "Wolf", "Vegas"].contains(name)
    }
    
    var popularityScore: Double {
        switch name {
        case "Scramble": return 0.95
        case "Best Ball": return 0.85
        case "Match Play": return 0.75
        case "Skins": return 0.70
        case "Stableford": return 0.65
        default: return 0.50
        }
    }
}

enum FormatAnimationType: Codable {
    case scramble
    case bestBall
    case matchPlay
    case skins
    case stableford
    case alternateShot
    case nassau
    case wolf
    case custom(String)
    
    private enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .custom(let value):
            try container.encode("custom", forKey: .type)
            try container.encode(value, forKey: .value)
        default:
            try container.encode(String(describing: self), forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "scramble": self = .scramble
        case "bestBall": self = .bestBall
        case "matchPlay": self = .matchPlay
        case "skins": self = .skins
        case "stableford": self = .stableford
        case "alternateShot": self = .alternateShot
        case "nassau": self = .nassau
        case "wolf": self = .wolf
        case "custom":
            let value = try container.decode(String.self, forKey: .value)
            self = .custom(value)
        default:
            self = .custom(type)
        }
    }
}

enum SwipeDirection {
    case left
    case right
}

struct FilterCriteria {
    var groupSize: Int?
    var difficulty: String?
    var playStyle: String?
}

// MARK: - View Model

class FormatCardsViewModel: ObservableObject {
    @Published var formats: [EnhancedGolfFormat] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let formatService = FormatDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFormats()
    }
    
    func loadFormats() {
        // For now, load static data. This will be connected to backend
        formats = Self.sampleFormats
        
        // TODO: Connect to actual backend
        // backendService.fetchFormats()
        //     .sink(
        //         receiveCompletion: { completion in
        //             if case .failure(let error) = completion {
        //                 self.error = error.localizedDescription
        //             }
        //         },
        //         receiveValue: { formats in
        //             self.formats = formats
        //         }
        //     )
        //     .store(in: &cancellables)
    }
    
    static let sampleFormats: [EnhancedGolfFormat] = [
        EnhancedGolfFormat(
            name: "Scramble",
            tagline: "Team plays best shot",
            difficulty: "Easy",
            description: "All players tee off, then the team selects the best shot and everyone plays from that spot. Perfect for mixed skill levels.",
            quickRules: [
                "Everyone tees off on each hole",
                "Team picks the best shot",
                "All play from that spot"
            ],
            completeRules: [
                "All team members tee off",
                "The team decides which shot is best",
                "All players pick up their balls and play from the chosen spot",
                "Continue this process until the ball is holed",
                "Record the team's total strokes for the hole",
                "Handicap strokes are typically divided among team members"
            ],
            scoringMethod: "Count total team strokes",
            detailedScoring: "The team records a single score for each hole. In tournament play, teams often must use a minimum number of drives from each player (e.g., 3 drives per player for 18 holes).",
            idealGroupSize: 2...4,
            proTips: [
                "Let the longest hitter tee off last for strategic advantage",
                "Save the best putter's shots around the green",
                "Don't always choose the longest drive - position matters"
            ],
            animationType: .scramble
        ),
        
        EnhancedGolfFormat(
            name: "Best Ball",
            tagline: "Play your own, count the best",
            difficulty: "Easy",
            description: "Each player plays their own ball throughout the hole. The team score is the lowest individual score.",
            quickRules: [
                "Everyone plays their own ball",
                "Take the best individual score",
                "Other scores don't count"
            ],
            completeRules: [
                "Each player plays their own ball from tee to green",
                "Players complete the hole with their own ball",
                "The lowest score among teammates becomes the team score",
                "If Player A scores 4 and Player B scores 5, team scores 4",
                "Can be played with 2, 3, or 4 person teams",
                "Full handicaps typically apply"
            ],
            scoringMethod: "Lowest individual score per hole",
            detailedScoring: "Record each player's score, but only the best score counts toward the team total. In stroke play, add up the best scores from each hole. In match play, compare best balls hole by hole.",
            idealGroupSize: 2...4,
            proTips: [
                "Play aggressively when partner is safe",
                "Support your partner on difficult holes",
                "Know when to pick up and save time"
            ],
            animationType: .bestBall
        ),
        
        EnhancedGolfFormat(
            name: "Match Play",
            tagline: "Win holes, not strokes",
            difficulty: "Medium",
            description: "Compete hole-by-hole rather than total strokes. Win a hole by having the lowest score. Most holes won wins the match.",
            quickRules: [
                "Lowest score wins the hole",
                "Track holes won, not total strokes",
                "Match ends when mathematically decided"
            ],
            completeRules: [
                "Players compete to win individual holes",
                "The player with the lowest score on a hole wins that hole",
                "Tied holes are 'halved' (no one wins)",
                "Track match status: 2 UP means leading by 2 holes",
                "Match can end before 18 holes if one player can't catch up",
                "Example: 3&2 means winner was 3 holes up with 2 to play"
            ],
            scoringMethod: "Holes won vs. holes lost",
            detailedScoring: "Track as 'up', 'down', or 'all square'. Matches can be won 1 up, 2&1, 3&2, etc. In team match play, each match is worth one point to the winning team.",
            idealGroupSize: 2...4,
            proTips: [
                "Play the hole, not your total score",
                "Take risks when you're down",
                "Concede short putts to maintain pace"
            ],
            animationType: .matchPlay
        ),
        
        EnhancedGolfFormat(
            name: "Skins",
            tagline: "Win the hole, win the pot",
            difficulty: "Medium",
            description: "Each hole has a value (skin). To win the skin, you must win the hole outright. Ties carry over to the next hole.",
            quickRules: [
                "Each hole is worth a set value",
                "Must win hole outright (no ties)",
                "Tied holes carry over value"
            ],
            completeRules: [
                "Assign a value to each hole (e.g., $10)",
                "The player with the lowest score wins the skin",
                "If players tie, the skin carries to the next hole",
                "Carried skins accumulate (next hole worth $20, etc.)",
                "Process continues until someone wins a hole outright",
                "Can play with automatic presses or validation requirements"
            ],
            scoringMethod: "Track skins won and their values",
            detailedScoring: "Keep a running tally of each player's skin wins and total value. Some groups play 'validation' where a skin must be validated by winning or tying the next hole.",
            idealGroupSize: 2...4,
            proTips: [
                "Be aggressive when skins carry over",
                "Know when to play safe vs. risk",
                "Track the money to know when to press"
            ],
            animationType: .skins
        ),
        
        EnhancedGolfFormat(
            name: "Stableford",
            tagline: "Points reward good holes",
            difficulty: "Easy",
            description: "Score points based on your score relative to par. More points for better scores. Highest point total wins.",
            quickRules: [
                "Eagle = 4 points, Birdie = 3 points",
                "Par = 2 points, Bogey = 1 point",
                "Double bogey or worse = 0 points"
            ],
            completeRules: [
                "Points based on score relative to par",
                "Eagle or better: 4 points",
                "Birdie: 3 points",
                "Par: 2 points",
                "Bogey: 1 point",
                "Double bogey or worse: 0 points",
                "Modified Stableford may use different point values",
                "Highest total points wins"
            ],
            scoringMethod: "Accumulate points, highest wins",
            detailedScoring: "Add up points from each hole for total score. Modified Stableford might award 8 for eagle, 5 for birdie, 2 for par, 0 for bogey, -1 for double, -3 for triple or worse.",
            idealGroupSize: 1...4,
            proTips: [
                "Be aggressive - no penalty for blow-up holes",
                "Focus on scoring opportunities",
                "Pick up after double bogey to save time"
            ],
            animationType: .stableford
        )
    ]
}

#Preview {
    SwipeableFormatCards()
}