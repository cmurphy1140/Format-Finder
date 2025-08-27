import SwiftUI

// MARK: - Enhanced Golf-Themed App
@main
struct EnhancedGolfApp: App {
    @StateObject private var themeManager = GolfThemeManager()
    @State private var showLaunchScreen = true
    @State private var showMainApp = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showMainApp {
                    EnhancedGolfContentView()
                        .environmentObject(themeManager)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                if showLaunchScreen {
                    GolfLoadingScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                    withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                        showMainApp = true
                    }
                }
            }
        }
    }
}

// MARK: - Golf Theme Manager
class GolfThemeManager: ObservableObject {
    @Published var currentTheme: GolfThemeStyle = .morning
    @Published var isDynamicTheme = true
    
    enum GolfThemeStyle: String, CaseIterable {
        case morning = "Morning Tee"
        case afternoon = "Afternoon Round"
        case sunset = "Sunset Play"
        case tournament = "Tournament"
        
        var gradient: LinearGradient {
            switch self {
            case .morning:
                return GolfColors.morningGradient
            case .afternoon:
                return LinearGradient(
                    colors: [GolfColors.skyBlue, GolfColors.fairwayGreen],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .sunset:
                return GolfColors.sunsetGradient
            case .tournament:
                return LinearGradient(
                    colors: [GolfColors.deepGreen, GolfColors.trophyGold.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        
        var cardColors: [Color] {
            switch self {
            case .morning:
                return [GolfColors.fairwayGreen, GolfColors.skyBlue, GolfColors.grassGreen]
            case .afternoon:
                return [GolfColors.deepGreen, GolfColors.waterBlue, GolfColors.limeGreen]
            case .sunset:
                return [GolfColors.flagRed, GolfColors.goldenSand, GolfColors.earthBrown]
            case .tournament:
                return [GolfColors.trophyGold, GolfColors.deepGreen, GolfColors.flagRed]
            }
        }
    }
    
    init() {
        updateThemeBasedOnTime()
        
        // Auto-update theme based on time if dynamic theme is enabled
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            if self.isDynamicTheme {
                self.updateThemeBasedOnTime()
            }
        }
    }
    
    func updateThemeBasedOnTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            currentTheme = .morning
        case 12..<17:
            currentTheme = .afternoon
        case 17..<20:
            currentTheme = .sunset
        default:
            currentTheme = .tournament
        }
    }
}

// MARK: - Enhanced Content View
struct EnhancedGolfContentView: View {
    @EnvironmentObject var themeManager: GolfThemeManager
    @State private var selectedTab = 0
    @State private var showFormatDetail = false
    @State private var selectedFormat: GolfFormat?
    @State private var searchText = ""
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            // Dynamic themed background
            themeManager.currentTheme.gradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1), value: themeManager.currentTheme)
            
            VStack(spacing: 0) {
                // Enhanced Header
                EnhancedGolfHeader(searchText: $searchText)
                    .environmentObject(themeManager)
                
                // Main Content
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(filteredFormats.enumerated()), id: \.element.id) { index, format in
                            GolfFormatCard(
                                format: format,
                                cardColor: themeManager.currentTheme.cardColors[index % 3],
                                delay: Double(index) * 0.1
                            )
                            .onTapGesture {
                                selectedFormat = format
                                showFormatDetail = true
                            }
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                                value: animateCards
                            )
                        }
                    }
                    .padding()
                }
                
                // Enhanced Tab Bar
                EnhancedGolfTabBar(selectedTab: $selectedTab)
                    .environmentObject(themeManager)
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    GolfFloatingButton(icon: "plus") {
                        // Add new game action
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedFormat) { format in
            GolfFormatDetailView(format: format)
                .environmentObject(themeManager)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateCards = true
            }
        }
    }
    
    var filteredFormats: [GolfFormat] {
        if searchText.isEmpty {
            return golfFormats
        } else {
            return golfFormats.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Enhanced Golf Header
struct EnhancedGolfHeader: View {
    @EnvironmentObject var themeManager: GolfThemeManager
    @Binding var searchText: String
    @State private var showThemeSelector = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section with Logo and Theme Selector
            HStack {
                // Animated Logo
                HStack(spacing: 10) {
                    AnimatedGolfBall()
                        .frame(width: 35, height: 35)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FORMAT")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, GolfColors.scorecardWhite],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("FINDER")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(GolfColors.trophyGold)
                    }
                }
                
                Spacer()
                
                // Theme Selector Button
                Button(action: { showThemeSelector.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.currentTheme.cardColors[0].opacity(0.8),
                                        themeManager.currentTheme.cardColors[1].opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 45, height: 45)
                        
                        Image(systemName: themeIcon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(pulseAnimation ? 15 : -15))
                    }
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 2)
                    .scaleEffect(pulseAnimation ? 1.1 : 1)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }
            }
            .padding()
            
            // Search Bar with Golf Theme
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GolfColors.fairwayGreen)
                
                TextField("Search golf formats...", text: $searchText)
                    .foregroundColor(GolfColors.deepGreen)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(GolfColors.fairwayGreen.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(GolfColors.fairwayGreen.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .padding(.bottom)
            
            // Theme Selector Sheet
            .sheet(isPresented: $showThemeSelector) {
                ThemeSelectorView()
                    .environmentObject(themeManager)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    GolfColors.deepGreen.opacity(0.9),
                    GolfColors.fairwayGreen.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    var themeIcon: String {
        switch themeManager.currentTheme {
        case .morning:
            return "sunrise.fill"
        case .afternoon:
            return "sun.max.fill"
        case .sunset:
            return "sunset.fill"
        case .tournament:
            return "trophy.fill"
        }
    }
}

// MARK: - Golf Format Card
struct GolfFormatCard: View {
    let format: GolfFormat
    let cardColor: Color
    let delay: Double
    @State private var isHovered = false
    @State private var showGolfBall = false
    
    var body: some View {
        ZStack {
            // Card Background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            cardColor,
                            cardColor.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Animated Golf Elements
            if showGolfBall {
                AnimatedGolfBall()
                    .frame(width: 30, height: 30)
                    .position(x: 150, y: 20)
                    .transition(.scale.combined(with: .opacity))
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: formatIcon(format.name))
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isHovered ? 10 : 0))
                    
                    Spacer()
                    
                    // Difficulty Badge
                    DifficultyBadgeEnhanced(difficulty: format.difficulty)
                }
                
                Text(format.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(format.description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                HStack {
                    Label(format.players, systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    WavingFlag()
                        .frame(width: 25, height: 25)
                }
            }
            .padding()
        }
        .frame(height: 160)
        .scaleEffect(isHovered ? 1.05 : 1)
        .shadow(
            color: cardColor.opacity(0.4),
            radius: isHovered ? 15 : 10,
            x: 0,
            y: isHovered ? 8 : 5
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.4)) {
                isHovered = hovering
                showGolfBall = hovering
            }
        }
    }
    
    func formatIcon(_ name: String) -> String {
        switch name {
        case "Scramble": return "arrow.triangle.merge"
        case "Best Ball": return "star.circle.fill"
        case "Match Play": return "person.2.circle.fill"
        case "Skins": return "dollarsign.circle.fill"
        case "Stableford": return "chart.line.uptrend.xyaxis"
        case "Four-Ball": return "circle.grid.2x2.fill"
        case "Alternate Shot": return "arrow.left.arrow.right"
        case "Nassau": return "divide.circle.fill"
        case "Bingo Bango Bongo": return "target"
        case "Wolf": return "pawprint.fill"
        case "Chapman": return "arrow.triangle.branch"
        case "Vegas": return "die.face.6.fill"
        default: return "flag.fill"
        }
    }
}

// MARK: - Enhanced Difficulty Badge
struct DifficultyBadgeEnhanced: View {
    let difficulty: String
    @State private var pulse = false
    
    var badgeColor: Color {
        switch difficulty {
        case "Easy": return GolfColors.limeGreen
        case "Medium": return GolfColors.goldenSand
        case "Hard": return GolfColors.flagRed
        default: return .gray
        }
    }
    
    var badgeIcon: String {
        switch difficulty {
        case "Easy": return "checkmark.circle.fill"
        case "Medium": return "exclamationmark.circle.fill"
        case "Hard": return "flame.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeIcon)
                .font(.system(size: 10))
            
            Text(difficulty)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(badgeColor)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(pulse ? 1.1 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Enhanced Tab Bar
struct EnhancedGolfTabBar: View {
    @EnvironmentObject var themeManager: GolfThemeManager
    @Binding var selectedTab: Int
    
    let tabs = [
        ("house.fill", "Home"),
        ("figure.golf", "Play"),
        ("chart.bar.fill", "Stats"),
        ("person.crop.circle", "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabBarButton(
                    icon: tabs[index].0,
                    title: tabs[index].1,
                    isSelected: selectedTab == index,
                    color: themeManager.currentTheme.cardColors[index % 3]
                ) {
                    withAnimation(.spring()) {
                        selectedTab = index
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    GolfColors.deepGreen.opacity(0.95),
                    GolfColors.fairwayGreen.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? color : .white.opacity(0.6))
                    .scaleEffect(isSelected ? 1.2 : 1)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? color : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                isSelected ?
                    AnyView(
                        Capsule()
                            .fill(color.opacity(0.15))
                            .padding(.horizontal, 8)
                    ) :
                    AnyView(Color.clear)
            )
        }
    }
}

// MARK: - Theme Selector View
struct ThemeSelectorView: View {
    @EnvironmentObject var themeManager: GolfThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                GolfColors.morningGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Toggle("Dynamic Theme (Time-based)", isOn: $themeManager.isDynamicTheme)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(15)
                    
                    if !themeManager.isDynamicTheme {
                        ForEach(GolfThemeManager.GolfThemeStyle.allCases, id: \.self) { theme in
                            ThemeOptionCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme
                            ) {
                                withAnimation(.spring()) {
                                    themeManager.currentTheme = theme
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Theme Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(GolfColors.deepGreen)
            )
        }
    }
}

struct ThemeOptionCard: View {
    let theme: GolfThemeManager.GolfThemeStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(theme.rawValue)
                        .font(.headline)
                        .foregroundColor(GolfColors.deepGreen)
                    
                    HStack(spacing: 8) {
                        ForEach(theme.cardColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(GolfColors.fairwayGreen)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isSelected ? GolfColors.fairwayGreen : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
    }
}

// MARK: - Format Detail View
struct GolfFormatDetailView: View {
    let format: GolfFormat
    @EnvironmentObject var themeManager: GolfThemeManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.gradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Section with Animation
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            GolfColors.fairwayGreen,
                                            GolfColors.deepGreen
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 200)
                            
                            VStack {
                                SwingingGolfClub()
                                    .frame(width: 80, height: 80)
                                
                                Text(format.name)
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Interactive Guide Section
                        if hasInteractiveGuide(format.name) {
                            FormatDiagramSlideshow(formatName: format.name)
                                .frame(height: 350)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.95))
                                )
                                .padding(.horizontal)
                        }
                        
                        // Info Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            InfoCardEnhanced(
                                icon: "person.2.fill",
                                title: "Players",
                                value: format.players,
                                color: GolfColors.waterBlue
                            )
                            
                            InfoCardEnhanced(
                                icon: "gauge",
                                title: "Difficulty",
                                value: format.difficulty,
                                color: difficultyColor(format.difficulty)
                            )
                            
                            InfoCardEnhanced(
                                icon: "flag.fill",
                                title: "Type",
                                value: format.type,
                                color: GolfColors.flagRed
                            )
                            
                            InfoCardEnhanced(
                                icon: "clock.fill",
                                title: "Duration",
                                value: "3-4 hours",
                                color: GolfColors.goldenSand
                            )
                        }
                        .padding(.horizontal)
                        
                        // Play Button
                        Button(action: {
                            // Start game action
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                
                                Text("Start Playing")
                                    .font(.title3.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(GolfColors.fairwayGradient)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(GolfColors.deepGreen)
            )
            .navigationBarHidden(true)
        }
    }
    
    func hasInteractiveGuide(_ name: String) -> Bool {
        ["Scramble", "Best Ball", "Stableford", "Alternate Shot"].contains(name)
    }
    
    func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Easy": return GolfColors.limeGreen
        case "Medium": return GolfColors.goldenSand
        case "Hard": return GolfColors.flagRed
        default: return .gray
        }
    }
}

struct InfoCardEnhanced: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(GolfColors.deepGreen)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}