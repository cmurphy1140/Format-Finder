import SwiftUI

// MARK: - Connected Formats List View
struct FormatsListView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedDifficulty: String? = nil
    @State private var showFavoritesOnly = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filter Bar
                FilterBarView(
                    selectedDifficulty: $selectedDifficulty,
                    showFavoritesOnly: $showFavoritesOnly
                )
                
                // Formats Grid
                if filteredFormats.isEmpty {
                    EmptyStateView(
                        title: "No Formats Found",
                        message: "Try adjusting your filters",
                        systemImage: "magnifyingglass"
                    )
                    .padding(.top, 50)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredFormats) { format in
                            ConnectedFormatCard(format: format)
                                .onTapGesture {
                                    handleFormatTap(format)
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Golf Formats")
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { /* Sort by name */ }) {
                        Label("Name", systemImage: "textformat")
                    }
                    Button(action: { /* Sort by difficulty */ }) {
                        Label("Difficulty", systemImage: "speedometer")
                    }
                    Button(action: { /* Sort by popularity */ }) {
                        Label("Popularity", systemImage: "star")
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
        }
        .refreshable {
            await refreshFormats()
        }
    }
    
    private var filteredFormats: [GolfFormat] {
        var formats = appState.availableFormats
        
        // Filter by search
        if !searchText.isEmpty {
            formats = formats.filter { format in
                format.name.localizedCaseInsensitiveContains(searchText) ||
                format.shortDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            formats = formats.filter { $0.difficulty == difficulty }
        }
        
        // Filter by favorites
        if showFavoritesOnly {
            formats = formats.filter { appState.favoriteFormats.contains($0.id) }
        }
        
        return formats
    }
    
    private func handleFormatTap(_ format: GolfFormat) {
        // Track usage
        appState.recordFormatUsage(format)
        
        // Navigate
        appState.navigateToFormat(format)
        
        // Haptic
        appState.hapticManager.impact(style: .light)
    }
    
    private func refreshFormats() async {
        await appState.loadInitialData()
    }
}

// MARK: - Connected Format Card
struct ConnectedFormatCard: View {
    let format: GolfFormat
    @EnvironmentObject var appState: AppState
    @State private var isFlipped = false
    @State private var isPressed = false
    
    var isFavorite: Bool {
        appState.favoriteFormats.contains(format.id)
    }
    
    var hasBeenPlayed: Bool {
        appState.sessionHistory.contains { $0.format.id == format.id }
    }
    
    var timesPlayed: Int {
        appState.sessionHistory.filter { $0.format.id == format.id }.count
    }
    
    var body: some View {
        ZStack {
            // Back of card - Details
            if isFlipped {
                FormatCardBack(format: format)
            } else {
                // Front of card - Overview
                FormatCardFront(
                    format: format,
                    isFavorite: isFavorite,
                    hasBeenPlayed: hasBeenPlayed,
                    timesPlayed: timesPlayed
                )
            }
        }
        .frame(height: 200)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isFlipped)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            // Quick tap to flip
            withAnimation {
                isFlipped.toggle()
            }
            appState.hapticManager.impact(style: .light)
        }
        .onLongPressGesture(
            minimumDuration: 0.5,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {
                // Long press to start game
                appState.navigateToGameSetup(format: format)
                appState.hapticManager.impact(style: .medium)
            }
        )
        .contextMenu {
            Button(action: {
                appState.toggleFavoriteFormat(format)
            }) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }
            
            Button(action: {
                appState.navigateToGameSetup(format: format)
            }) {
                Label("Start Game", systemImage: "play.circle")
            }
            
            Button(action: {
                shareFormat(format)
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private func shareFormat(_ format: GolfFormat) {
        // Implement sharing
    }
}

// MARK: - Format Card Front
struct FormatCardFront: View {
    let format: GolfFormat
    let isFavorite: Bool
    let hasBeenPlayed: Bool
    let timesPlayed: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: format.icon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                    
                    if hasBeenPlayed {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("\(timesPlayed)")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            
            // Title & Description
            VStack(alignment: .leading, spacing: 4) {
                Text(format.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(format.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Footer
            HStack {
                // Difficulty Badge
                Text(format.difficulty)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(difficultyColor.opacity(0.3))
                    )
                    .foregroundColor(.white)
                
                Spacer()
                
                // Player Count
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                    Text(format.playerRange)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                    Text(format.duration)
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(radius: 5)
    }
    
    private var difficultyColor: Color {
        switch format.difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
    
    private var gradientColors: [Color] {
        if isFavorite {
            return [Color.red.opacity(0.7), Color.pink.opacity(0.7)]
        } else if hasBeenPlayed {
            return [Color.green.opacity(0.7), Color.blue.opacity(0.7)]
        } else {
            return [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]
        }
    }
}

// MARK: - Format Card Back
struct FormatCardBack: View {
    let format: GolfFormat
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("How to Play")
                .font(.headline)
                .foregroundColor(.white)
            
            // Rules
            VStack(alignment: .leading, spacing: 8) {
                ForEach(format.rules.prefix(4), id: \.self) { rule in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .offset(y: 2)
                        
                        Text(rule)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    appState.navigateToFormat(format)
                }) {
                    Label("Learn More", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    appState.navigateToGameSetup(format: format)
                }) {
                    Label("Play Now", systemImage: "play.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .rotation3DEffect(
            .degrees(180),
            axis: (x: 0, y: 1, z: 0)
        )
        .shadow(radius: 5)
    }
}

// MARK: - Filter Bar
struct FilterBarView: View {
    @Binding var selectedDifficulty: String?
    @Binding var showFavoritesOnly: Bool
    
    let difficulties = ["Easy", "Medium", "Hard"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Favorites Toggle
                FilterChip(
                    title: "Favorites",
                    isSelected: showFavoritesOnly,
                    icon: "heart.fill"
                ) {
                    showFavoritesOnly.toggle()
                }
                
                Divider()
                    .frame(height: 20)
                
                // Difficulty Filters
                ForEach(difficulties, id: \.self) { difficulty in
                    FilterChip(
                        title: difficulty,
                        isSelected: selectedDifficulty == difficulty,
                        color: difficultyColor(difficulty)
                    ) {
                        if selectedDifficulty == difficulty {
                            selectedDifficulty = nil
                        } else {
                            selectedDifficulty = difficulty
                        }
                    }
                }
            }
        }
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? color : Color(.secondarySystemBackground)
            )
            .foregroundColor(
                isSelected ? .white : .primary
            )
            .cornerRadius(20)
        }
    }
}