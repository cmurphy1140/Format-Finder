import SwiftUI

@main
struct FormatFinderApp: App {
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}

struct MainContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    Label("Browse", systemImage: "square.grid.2x2")
                }
                .tag(0)
            
            BookmarksScreen()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(1)
        }
        .tint(Color(red: 46/255, green: 125/255, blue: 50/255))
    }
}

// Simple data model
struct SimpleFormat: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let players: String
    let difficulty: String
    let description: String
    let howToPlay: [String]
    let example: String
}

// Home Screen
struct HomeScreen: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var selectedFormat: SimpleFormat?
    
    let filters = ["All", "Tournament", "Betting"]
    
    let formats = [
        SimpleFormat(
            name: "Scramble",
            category: "Tournament",
            players: "2-4 players",
            difficulty: "Easy",
            description: "All players hit from the best shot",
            howToPlay: [
                "Everyone tees off",
                "Choose the best drive",
                "All play from that spot",
                "Repeat until holed"
            ],
            example: "Team uses best drive, then best approach, best putt. Score: 4"
        ),
        SimpleFormat(
            name: "Best Ball",
            category: "Tournament",
            players: "2-4 players",
            difficulty: "Easy",
            description: "Count the best individual score",
            howToPlay: [
                "Everyone plays own ball",
                "Record individual scores",
                "Use lowest score for team"
            ],
            example: "Player A: 5, Player B: 4, Player C: 6. Team score: 4"
        ),
        SimpleFormat(
            name: "Skins",
            category: "Betting",
            players: "2-4 players",
            difficulty: "Easy",
            description: "Win holes outright for money",
            howToPlay: [
                "Each hole worth a 'skin'",
                "Lowest score wins the skin",
                "Ties carry to next hole"
            ],
            example: "Hole 1: Tie. Hole 2: Tie. Hole 3: Player A wins 3 skins"
        ),
        SimpleFormat(
            name: "Nassau",
            category: "Betting",
            players: "2-4 players",
            difficulty: "Medium",
            description: "Three bets: front 9, back 9, overall",
            howToPlay: [
                "Front 9 is one bet",
                "Back 9 is another bet",
                "Overall 18 is third bet"
            ],
            example: "Win front 9, lose back 9, tie overall = break even"
        )
    ]
    
    var filteredFormats: [SimpleFormat] {
        formats.filter { format in
            let matchesSearch = searchText.isEmpty || 
                              format.name.localizedCaseInsensitiveContains(searchText) ||
                              format.description.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilter == "All" || format.category == selectedFilter
            return matchesSearch && matchesFilter
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search formats...", text: $searchText)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter ? 
                                        Color(red: 46/255, green: 125/255, blue: 50/255) : 
                                        Color.gray.opacity(0.1)
                                    )
                                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Format grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredFormats) { format in
                            FormatCard(format: format)
                                .onTapGesture {
                                    selectedFormat = format
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Golf Formats")
            .sheet(item: $selectedFormat) { format in
                FormatDetailSheet(format: format)
            }
        }
    }
}

// Format Card
struct FormatCard: View {
    let format: SimpleFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: format.category == "Tournament" ? "trophy.fill" : "dollarsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 46/255, green: 125/255, blue: 50/255))
                
                Spacer()
                
                Text(format.difficulty)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            Text(format.name)
                .font(.headline)
            
            Text(format.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(format.players)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    var difficultyColor: Color {
        switch format.difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        default: return .red
        }
    }
}

// Detail View
struct FormatDetailSheet: View {
    let format: SimpleFormat
    @Environment(\.dismiss) var dismiss
    @AppStorage("bookmarks") private var bookmarkData = Data()
    @State private var isBookmarked = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Label(format.players, systemImage: "person.2.fill")
                            .font(.caption)
                        
                        Text(format.difficulty)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(difficultyColor)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text(format.description)
                        .font(.body)
                    
                    // Visual placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.green.opacity(0.3))
                                Text("Format Diagram")
                                    .font(.caption)
                            }
                        )
                    
                    // How to Play
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Play")
                            .font(.headline)
                        
                        ForEach(Array(format.howToPlay.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                                Text(step)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Example
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.headline)
                        Text(format.example)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle(format.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isBookmarked.toggle() }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .onAppear {
            loadBookmarkStatus()
        }
    }
    
    var difficultyColor: Color {
        switch format.difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        default: return .red
        }
    }
    
    func loadBookmarkStatus() {
        if let bookmarks = try? JSONDecoder().decode([String].self, from: bookmarkData) {
            isBookmarked = bookmarks.contains(format.name)
        }
    }
}

// Bookmarks Screen
struct BookmarksScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "bookmark")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("No saved formats yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the bookmark icon on any format to save it here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .navigationTitle("Saved Formats")
        }
    }
}