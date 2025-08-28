import SwiftUI

struct GolfFormatHomeView: View {
    @State private var numberOfGolfers = 4
    @State private var selectedFilter: String? = nil
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showRandomFormat = false
    @State private var randomFormat: EnhancedGolfFormat?
    @State private var selectedFormat: EnhancedGolfFormat?
    @State private var showFormatDetail = false
    @State private var animateHeader = false
    @State private var animateCards = false
    @StateObject private var formatDataService = FormatDataService.shared
    
    let filterOptions = ["Casual", "Competitive", "Team Play", "Fast Play", "Traditional"]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var filteredFormats: [EnhancedGolfFormat] {
        formatDataService.formats.filter { format in
            let matchesSearch = searchText.isEmpty || 
                format.name.localizedCaseInsensitiveContains(searchText) ||
                format.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter = selectedFilter == nil || {
                switch selectedFilter {
                case "Casual":
                    return format.difficulty == "Easy"
                case "Competitive":
                    return format.difficulty == "Hard"
                case "Team Play":
                    return format.idealGroupSize.contains(4)
                case "Fast Play":
                    return format.difficulty == "Easy"
                case "Traditional":
                    return ["Stroke Play", "Match Play", "Stableford", "Nassau"].contains(format.name)
                default:
                    return true
                }
            }()
            
            return matchesSearch && matchesFilter
        }
    }
    
    var formatOfTheDay: EnhancedGolfFormat? {
        formatDataService.formats.randomElement()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Animated Header
                        animatedHeaderSection
                            .padding(.top, showSearch ? 0 : -40)
                        
                        // Search Bar (slides down when active)
                        if showSearch {
                            searchBarSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        VStack(spacing: 24) {
                            // Quick Setup Card
                            quickSetupCard
                                .scaleEffect(animateCards ? 1 : 0.9)
                                .opacity(animateCards ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: animateCards)
                            
                            // Filter Chips
                            filterChipsSection
                                .opacity(animateCards ? 1 : 0)
                                .animation(.easeInOut(duration: 0.4).delay(0.3), value: animateCards)
                            
                            // Format of the Day
                            if let todayFormat = formatOfTheDay {
                                formatOfTheDayCard(format: todayFormat)
                                    .scaleEffect(animateCards ? 1 : 0.9)
                                    .opacity(animateCards ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: animateCards)
                            }
                            
                            // Popular Formats Grid
                            popularFormatsSection
                                .opacity(animateCards ? 1 : 0)
                                .animation(.easeInOut(duration: 0.4).delay(0.5), value: animateCards)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for floating button
                    }
                }
                
                // Floating Random Format Button
                floatingRandomButton
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
            }
            .sheet(isPresented: $showFormatDetail) {
                if let format = selectedFormat {
                    NavigationView {
                        VStack(spacing: 20) {
                            // Format header
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(format.name)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    Text(format.tagline)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            
                            // Quick info
                            HStack(spacing: 30) {
                                VStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundColor(MastersColors.mastersGreen)
                                    Text("\(format.idealGroupSize.lowerBound)-\(format.idealGroupSize.upperBound) Players")
                                        .font(.caption)
                                }
                                
                                VStack {
                                    Image(systemName: "speedometer")
                                        .font(.title2)
                                        .foregroundColor(MastersColors.mastersGreen)
                                    Text(format.difficulty)
                                        .font(.caption)
                                }
                            }
                            
                            // Description
                            Text(format.description)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            
                            // Rules
                            VStack(alignment: .leading, spacing: 10) {
                                Text("How to Play")
                                    .font(.headline)
                                ForEach(format.quickRules, id: \.self) { rule in
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text(rule)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            
                            Spacer()
                            
                            Button(action: {
                                showFormatDetail = false
                            }) {
                                Text("Got it!")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(MastersColors.mastersGreen)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                        .navigationBarItems(trailing: Button("Close") {
                            showFormatDetail = false
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Components
    
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.8), // Golf course green
                Color(red: 0.5, green: 0.7, blue: 0.9) // Sky blue
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    var animatedHeaderSection: some View {
        ZStack(alignment: .top) {
            // Animated golf course waves
            ForEach(0..<3) { index in
                Wave(amplitude: 30, frequency: 0.01, phase: Double(index) * 0.5)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 150)
                    .offset(y: CGFloat(index * 20))
                    .animation(
                        Animation.easeInOut(duration: 3 + Double(index))
                            .repeatForever(autoreverses: true),
                        value: animateHeader
                    )
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Discover")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your Perfect Golf Format")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Button(action: { withAnimation { showSearch.toggle() } }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
            }
        }
        .frame(height: 200)
    }
    
    var searchBarSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MastersColors.textSecondary)
            
            TextField("Search formats...", text: $searchText)
                .font(MastersTypography.bodyText())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MastersColors.textSecondary)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    var quickSetupCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "figure.golf")
                    .font(.system(size: 24))
                    .foregroundColor(MastersColors.mastersGreen)
                
                Text("How many golfers today?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MastersColors.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                Button(action: { if numberOfGolfers > 1 { numberOfGolfers -= 1 } }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(numberOfGolfers > 1 ? MastersColors.mastersGreen : Color.gray)
                }
                .disabled(numberOfGolfers <= 1)
                
                Text("\(numberOfGolfers)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(MastersColors.textPrimary)
                    .frame(minWidth: 60)
                    .animation(.spring(response: 0.3), value: numberOfGolfers)
                
                Button(action: { if numberOfGolfers < 12 { numberOfGolfers += 1 } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(numberOfGolfers < 12 ? MastersColors.mastersGreen : Color.gray)
                }
                .disabled(numberOfGolfers >= 12)
            }
            
            Text("Golfers")
                .font(.system(size: 14))
                .foregroundColor(MastersColors.textSecondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filterOptions, id: \.self) { option in
                    FilterChip(
                        title: option,
                        isSelected: selectedFilter == option,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = selectedFilter == option ? nil : option
                            }
                        }
                    )
                }
            }
        }
    }
    
    func formatOfTheDayCard(format: EnhancedGolfFormat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MastersColors.augustaGold, MastersColors.eagleGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(animateHeader ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 20)
                                .repeatForever(autoreverses: false),
                            value: animateHeader
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Format of the Day")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MastersColors.augustaGold)
                    
                    Text(format.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(MastersColors.textPrimary)
                }
                
                Spacer()
                
                // Animated golf ball
                Image(systemName: "circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .offset(y: animateHeader ? -10 : 0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: animateHeader
                    )
            }
            
            Text(format.description)
                .font(.system(size: 14))
                .foregroundColor(MastersColors.textSecondary)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                Label("\(format.idealGroupSize.lowerBound)-\(format.idealGroupSize.upperBound) players", systemImage: "person.2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(MastersColors.textSecondary)
                
                Label("4-5h", systemImage: "clock")
                    .font(.system(size: 12))
                    .foregroundColor(MastersColors.textSecondary)
                
                DifficultyIndicator(difficulty: format.difficulty)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "F8F9FA")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .shadow(color: MastersColors.augustaGold.opacity(0.2), radius: 15, x: 0, y: 5)
    }
    
    var popularFormatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Formats")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(MastersColors.textPrimary)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredFormats.prefix(8)) { format in
                    FormatGridCard(format: format) {
                        selectedFormat = format
                        showFormatDetail = true
                    }
                    .scaleEffect(animateCards ? 1 : 0.8)
                    .opacity(animateCards ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(filteredFormats.firstIndex(where: { $0.id == format.id }) ?? 0) * 0.05 + 0.6),
                        value: animateCards
                    )
                }
            }
        }
    }
    
    var floatingRandomButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: randomFormatAction) {
                    HStack(spacing: 12) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 20))
                            .rotationEffect(.degrees(showRandomFormat ? 720 : 0))
                        
                        Text("Random Format")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [MastersColors.mastersGreen, MastersColors.shadowGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: MastersColors.mastersGreen.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .scaleEffect(showRandomFormat ? 1.1 : 1.0)
                
                Spacer()
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Actions
    
    func startAnimations() {
        withAnimation {
            animateHeader = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                animateCards = true
            }
        }
    }
    
    func randomFormatAction() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showRandomFormat = true
            randomFormat = formatDataService.formats.randomElement()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showRandomFormat = false
            if let format = randomFormat {
                selectedFormat = format
                showFormatDetail = true
            }
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : MastersColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    AnyView(
                        LinearGradient(
                            colors: [MastersColors.mastersGreen, MastersColors.shadowGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ) :
                    AnyView(Color.white)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: isSelected ? MastersColors.mastersGreen.opacity(0.3) : Color.black.opacity(0.05),
                       radius: isSelected ? 8 : 4,
                       x: 0,
                       y: isSelected ? 4 : 2)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct FormatGridCard: View {
    let format: EnhancedGolfFormat
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: getFormatIcon(format.name))
                        .font(.system(size: 24))
                        .foregroundColor(MastersColors.mastersGreen)
                    
                    Spacer()
                    
                    // Player count badge
                    Text(getPlayerCount(format))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MastersColors.mastersGreen)
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MastersColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Time estimate
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("4-5h")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(MastersColors.textSecondary)
                        
                        // Difficulty dots
                        DifficultyDots(difficulty: format.difficulty)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MastersColors.mastersGreen.opacity(isPressed ? 0.5 : 0), lineWidth: 2)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    func getPlayerCount(_ format: EnhancedGolfFormat) -> String {
        if format.idealGroupSize.lowerBound == format.idealGroupSize.upperBound {
            return "\(format.idealGroupSize.lowerBound)P"
        } else {
            return "\(format.idealGroupSize.lowerBound)-\(format.idealGroupSize.upperBound)"
        }
    }
    
    func getFormatIcon(_ name: String) -> String {
        switch name {
        case "Scramble": return "arrow.triangle.merge"
        case "Best Ball": return "star.circle.fill"
        case "Match Play": return "person.2.square.stack"
        case "Skins": return "dollarsign.circle.fill"
        case "Stableford": return "chart.line.uptrend.xyaxis"
        case "Nassau": return "flag.2.crossed"
        case "Wolf": return "hare.fill"
        case "Bingo Bango Bongo": return "target"
        default: return "flag.fill"
        }
    }
}

struct DifficultyDots: View {
    let difficulty: String
    
    var filledDots: Int {
        switch difficulty {
        case "Easy": return 1
        case "Medium": return 3
        case "Hard": return 5
        default: return 2
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { dot in
                Circle()
                    .fill(dot <= filledDots ? difficultyColor : Color.gray.opacity(0.2))
                    .frame(width: 4, height: 4)
            }
        }
    }
    
    var difficultyColor: Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
}

struct DifficultyIndicator: View {
    let difficulty: String
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { level in
                Circle()
                    .fill(level <= difficultyLevel ? difficultyColor : Color.gray.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
            
            Text(difficulty)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(difficultyColor)
        }
    }
    
    var difficultyLevel: Int {
        switch difficulty {
        case "Easy": return 1
        case "Medium": return 2
        case "Hard": return 3
        default: return 1
        }
    }
    
    var difficultyColor: Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .gray
        }
    }
}

struct Wave: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let y = sin(2 * .pi * frequency * relativeX + phase) * amplitude + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}


// MARK: - Preview
struct GolfFormatHomeView_Previews: PreviewProvider {
    static var previews: some View {
        GolfFormatHomeView()
    }
}