import SwiftUI

// MARK: - Phase 3 Production-Ready View
struct Phase3ProductionView: View {
    @StateObject private var scrollState = ScrollState()
    @StateObject private var config = FormatFinderConfig.shared
    @StateObject private var colorSystem = AdaptiveColorSystem.shared
    @StateObject private var accessibility = AccessibilityManager.shared
    @StateObject private var loadingState = LoadingStateManager()
    @StateObject private var optimizer = PerformanceOptimizer.shared
    
    @State private var isRefreshing = false
    @State private var formats: [GolfFormat] = []
    @State private var showConfig = false
    
    private let sections = [
        ScrollProgressIndicator.ScrollSection(id: "featured", title: "Featured", offset: 0, color: .blue),
        ScrollProgressIndicator.ScrollSection(id: "popular", title: "Popular", offset: 400, color: .green),
        ScrollProgressIndicator.ScrollSection(id: "team", title: "Team Formats", offset: 800, color: .purple),
        ScrollProgressIndicator.ScrollSection(id: "individual", title: "Individual", offset: 1200, color: .orange),
        ScrollProgressIndicator.ScrollSection(id: "advanced", title: "Advanced", offset: 1600, color: .red)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                colorSystem.backgroundGradient
                    .ignoresSafeArea()
                
                // Main content
                contentView
                    .adaptiveBackground(
                        scrollOffset: scrollState.offset,
                        maxOffset: 2000
                    )
                
                // Overlays
                if config.floatingButtonEnabled {
                    FloatingQuickStartButton(scrollState: scrollState) {
                        startQuickGame()
                    }
                }
                
                if config.scrollIndicatorEnabled {
                    ScrollProgressIndicator(
                        scrollState: scrollState,
                        sections: sections
                    )
                }
                
                if config.debugMode {
                    debugOverlay
                }
            }
            .navigationTitle("Format Finder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showConfig.toggle() }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showConfig) {
                ConfigurationView()
            }
        }
        .onAppear {
            loadFormats()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch loadingState.state {
        case .loading:
            loadingView
        case .loaded:
            loadedContentView
        case .error(let error):
            ErrorStateView(error: error) {
                loadFormats()
            }
        case .empty:
            EmptyStateView(
                title: "No Formats Available",
                message: "Check back later for new golf formats!",
                systemImage: "sportscourt"
            )
        case .idle:
            Color.clear
                .onAppear { loadFormats() }
        }
    }
    
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<5) { _ in
                    CardSkeleton()
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var loadedContentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Parallax Header
                if config.parallaxEnabled {
                    ParallaxHeaderView(
                        scrollState: scrollState,
                        title: "Golf Format Finder",
                        subtitle: "Discover Your Perfect Game"
                    )
                }
                
                // Pull to refresh
                if config.pullToRefreshEnabled {
                    Color.clear
                        .frame(height: 0)
                        .golfBallPullToRefresh {
                            await refreshContent()
                        }
                }
                
                // Content sections with responsive layout
                ResponsiveGridView(items: formats) { format in
                    formatCard(for: format)
                }
                .interactiveFeedback(scrollOffset: scrollState.offset)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            handleScroll(offset: offset)
        }
    }
    
    @ViewBuilder
    private func formatCard(for format: GolfFormat) -> some View {
        if config.animationsEnabled {
            FormatCard3D(format: format)
                .animatedReveal(
                    delay: Double(formats.firstIndex(where: { $0.id == format.id }) ?? 0) * 0.1
                )
                .accessibleAnimation()
                .highContrastBorder()
        } else {
            // Simplified card for reduced motion
            SimpleFormatCard(format: format)
        }
    }
    
    private var debugOverlay: some View {
        VStack {
            HStack {
                AnimationDebugPanel()
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadFormats() {
        loadingState.startLoading()
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.formats = GolfFormat.sampleFormats
            loadingState.finishLoading(isEmpty: formats.isEmpty)
        }
    }
    
    private func refreshContent() async -> Bool {
        // Simulate network request with max 2 attempts (as per your instruction)
        for attempt in 1...2 {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                await MainActor.run {
                    self.formats = GolfFormat.sampleFormats.shuffled()
                }
                return true
            } catch {
                if attempt >= 2 {
                    return false
                }
            }
        }
        return false
    }
    
    private func handleScroll(offset: CGFloat) {
        scrollState.offset = offset
        
        // Update optimizer
        optimizer.handleScroll(offset)
        
        // Track scroll patterns
        config.trackScrollPattern(offset: offset, velocity: scrollState.velocity)
        
        // Announce section changes for VoiceOver
        if accessibility.isVoiceOverRunning {
            let currentSection = sections.first { $0.offset <= offset }
            if let section = currentSection {
                accessibility.announceSection(section.title)
            }
        }
    }
    
    private func startQuickGame() {
        // Navigate to quick start
        print("Starting quick game...")
    }
}

// MARK: - Simple Format Card (for reduced motion)
struct SimpleFormatCard: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: format.icon)
                    .font(.title2)
                Text(format.name)
                    .font(.headline)
                Spacer()
            }
            
            Text(format.shortDescription)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Label(format.playerRange, systemImage: "person.2")
                Spacer()
                Label(format.duration, systemImage: "clock")
            }
            .font(.caption)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .transition(.opacity)
    }
}

// MARK: - Golf Format Model Extension
extension GolfFormat {
    static var sampleFormats: [GolfFormat] {
        [
            GolfFormat(
                id: "scramble",
                name: "Scramble",
                shortDescription: "Team format where everyone plays from the best shot",
                icon: "person.3.fill",
                difficulty: "Easy",
                playerRange: "2-4",
                duration: "4 hours",
                tags: ["Team", "Fun", "Beginner"],
                rules: [
                    "All players tee off",
                    "Team selects best shot",
                    "Everyone plays from that spot"
                ]
            ),
            GolfFormat(
                id: "bestball",
                name: "Best Ball",
                shortDescription: "Each player plays their own ball, best score counts",
                icon: "star.fill",
                difficulty: "Medium",
                playerRange: "2-4",
                duration: "4.5 hours",
                tags: ["Team", "Competitive"],
                rules: [
                    "Everyone plays own ball",
                    "Best individual score per hole",
                    "No shot sharing"
                ]
            ),
            GolfFormat(
                id: "skins",
                name: "Skins",
                shortDescription: "Win holes outright to collect skins",
                icon: "dollarsign.circle.fill",
                difficulty: "Hard",
                playerRange: "2-4",
                duration: "4 hours",
                tags: ["Gambling", "Competitive"],
                rules: [
                    "Lowest score wins the hole",
                    "Ties carry over",
                    "Winner takes accumulated skins"
                ]
            ),
            GolfFormat(
                id: "stableford",
                name: "Stableford",
                shortDescription: "Point-based scoring system",
                icon: "chart.bar.fill",
                difficulty: "Medium",
                playerRange: "1-4",
                duration: "4 hours",
                tags: ["Points", "Individual"],
                rules: [
                    "Points based on score vs par",
                    "Higher points win",
                    "Encourages aggressive play"
                ]
            ),
            GolfFormat(
                id: "match-play",
                name: "Match Play",
                shortDescription: "Hole-by-hole competition",
                icon: "flag.fill",
                difficulty: "Medium",
                playerRange: "2",
                duration: "4 hours",
                tags: ["Head-to-head", "Classic"],
                rules: [
                    "Win individual holes",
                    "Most holes won wins match",
                    "Can end before 18"
                ]
            )
        ]
    }
}

// MARK: - Preview
struct Phase3ProductionView_Previews: PreviewProvider {
    static var previews: some View {
        Phase3ProductionView()
    }
}