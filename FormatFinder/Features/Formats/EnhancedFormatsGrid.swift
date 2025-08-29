import SwiftUI

// MARK: - Enhanced Formats Grid View

struct EnhancedFormatsGrid: View {
    @State private var selectedFormat: GolfFormat? = nil
    @State private var showFormatExplainer = false
    @State private var showGameConfiguration = false
    @State private var animateIn = false
    @State private var scrollOffset: CGFloat = 0
    @State private var quickStartScale: CGFloat = 1.0
    @StateObject private var animationOrchestrator = AnimationOrchestrator.shared
    @StateObject private var timeService = TimeEnvironmentService.shared
    
    let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    // Get all formats
    var allFormats: [GolfFormat] {
        GolfFormat.completeFormatList
    }
    
    var body: some View {
        ZStack {
            // Dynamic background based on time
            TimeAwareBackground()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Sticky Quick Start Section
                        GeometryReader { geometry in
                            QuickStartSection(
                                scrollOffset: scrollOffset,
                                onTap: {
                                    withAnimation(.spring()) {
                                        showGameConfiguration = true
                                    }
                                }
                            )
                            .frame(width: geometry.size.width)
                            .background(GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        scrollOffset = geo.frame(in: .global).minY
                                    }
                                    .onChange(of: geo.frame(in: .global).minY) { newValue in
                                        scrollOffset = newValue
                                    }
                            })
                        }
                        .frame(height: 180)
                        .zIndex(1)
                        
                        // Formats Grid
                        VStack(spacing: 20) {
                            // Section Header
                            HStack {
                                Text("Choose Your Format")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(allFormats.count) Formats")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            
                            // Animated Grid
                            LazyVGrid(columns: columns, spacing: 15) {
                                ForEach(Array(allFormats.enumerated()), id: \.element.id) { index, format in
                                    FormatGridCard(
                                        format: format,
                                        index: index,
                                        action: {
                                            selectedFormat = format
                                            showFormatExplainer = true
                                        }
                                    )
                                    .opacity(animateIn ? 1 : 0)
                                    .scaleEffect(animateIn ? 1 : 0.8)
                                    .animation(
                                        .spring()
                                            .delay(Double(index) * 0.05),
                                        value: animateIn
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -10)
                        )
                        .offset(y: -30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateIn = true
            }
        }
        .sheet(item: $selectedFormat) { format in
            AnimatedFormatExplainer(format: format)
        }
        .sheet(isPresented: $showGameConfiguration) {
            QuickStartConfiguration()
        }
    }
}

// MARK: - Quick Start Section (Sticky)

struct QuickStartSection: View {
    let scrollOffset: CGFloat
    let onTap: () -> Void
    @State private var pulseAnimation = false
    
    var stickyOffset: CGFloat {
        scrollOffset < -100 ? -scrollOffset - 100 : 0
    }
    
    var scale: CGFloat {
        scrollOffset < -100 ? 0.9 : 1.0
    }
    
    var opacity: Double {
        scrollOffset < -200 ? 0.7 : 1.0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content container
            VStack(spacing: 15) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGreen.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.primaryGreen)
                }
                
                Text("Quick Start")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Jump into a game with smart defaults")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Button(action: onTap) {
                    HStack {
                        Text("Start Playing")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.primaryGreen,
                                AppColors.darkGreen
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: AppColors.primaryGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(stickyOffset > 0 ? 0.15 : 0.05),
                        radius: stickyOffset > 0 ? 15 : 5,
                        x: 0,
                        y: stickyOffset > 0 ? 10 : 2
                    )
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: stickyOffset)
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Format Grid Card

struct FormatGridCard: View {
    let format: GolfFormat
    let index: Int
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon container
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            format.color.opacity(0.3),
                            format.color.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 50, height: 50)
                    .cornerRadius(12)
                    
                    // Format icon
                    FormatIconView(format: format, size: 35)
                }
                .scaleEffect(isPressed ? 0.9 : isHovered ? 1.1 : 1.0)
                .rotationEffect(.degrees(isHovered ? 5 : 0))
                
                // Format name
                Text(format.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                // Quick description
                Text(quickDescription(for: format))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 5)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 2)
                
                // Bottom info row
                HStack(spacing: 8) {
                    // Difficulty indicator
                    HStack(spacing: 1) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i < difficultyLevel(format.difficulty) ? 
                                      difficultyColor(format.difficulty) : 
                                      Color.gray.opacity(0.2))
                                .frame(width: 3, height: 3)
                        }
                    }
                    
                    // Team/Individual badge
                    Text(format.isTeamFormat ? "TEAM" : "SOLO")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(format.isTeamFormat ? .blue : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(format.isTeamFormat ? 
                                      Color.blue.opacity(0.1) : 
                                      Color.orange.opacity(0.1))
                        )
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(
                        color: isHovered ? 
                               format.color.opacity(0.3) : 
                               Color.gray.opacity(0.1),
                        radius: isHovered ? 10 : 5,
                        x: 0,
                        y: isHovered ? 5 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isHovered ? format.color.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
    
    func difficultyLevel(_ difficulty: String) -> Int {
        switch difficulty {
        case "Beginner": return 1
        case "Intermediate": return 2
        case "Advanced", "Expert": return 3
        default: return 1
        }
    }
    
    func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Beginner": return .green
        case "Intermediate": return .orange
        case "Advanced", "Expert": return .red
        default: return .gray
        }
    }
    
    func quickDescription(for format: GolfFormat) -> String {
        switch format.name {
        case "Scramble":
            return "All tee off, play best shot"
        case "Best Ball":
            return "Play own ball, take best score"
        case "Alternate Shot":
            return "Partners alternate every shot"
        case "Stableford":
            return "Points for scores, not strokes"
        case "Skins":
            return "Win hole outright for the pot"
        case "Wolf":
            return "Captain picks partner each hole"
        case "Nassau":
            return "Three bets: front, back, total"
        case "Match Play":
            return "Win holes, not total score"
        case "Chapman":
            return "Switch balls, then choose one"
        case "Bingo Bango Bongo":
            return "Points for first on, closest, first in"
        case "Texas Scramble":
            return "Scramble with required drives"
        case "Foursomes":
            return "True alternate shot from tee"
        case "Greensome":
            return "Both tee off, then alternate"
        case "Vegas":
            return "Combine scores, birdie flips"
        case "Rabbit":
            return "Hold the rabbit at 9 & 18 to win"
        case "Defender":
            return "One vs three each hole"
        case "Ghost":
            return "Play against par every hole"
        case "Dots":
            return "Points for achievements"
        case "String":
            return "Use string to improve lies"
        case "Quota":
            return "Beat your point target"
        case "Yellows":
            return "Double points for hard pins"
        case "Bridges":
            return "Connect same scores"
        case "Four-Ball":
            return "Two vs two, best scores"
        default:
            return format.tagline
        }
    }
}

// MARK: - Time-Aware Background

struct TimeAwareBackground: View {
    @StateObject private var timeService = TimeEnvironmentService.shared
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: backgroundColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1), value: timeService.currentTimeContext)
    }
    
    var backgroundColors: [Color] {
        switch timeService.currentTimeContext {
        case .dawn, .sunrise, .morning:
            return [
                Color(red: 255/255, green: 239/255, blue: 213/255).opacity(0.5),
                Color(red: 255/255, green: 218/255, blue: 185/255).opacity(0.3)
            ]
        case .day, .afternoon:
            return [
                AppColors.fairwayGreen.opacity(0.2),
                AppColors.primaryGreen.opacity(0.1)
            ]
        case .goldenHour, .sunset, .dusk, .evening:
            return [
                Color(red: 255/255, green: 168/255, blue: 87/255).opacity(0.3),
                Color(red: 255/255, green: 143/255, blue: 87/255).opacity(0.2)
            ]
        case .night, .lateNight, .midnight:
            return [
                Color(red: 25/255, green: 39/255, blue: 52/255).opacity(0.4),
                Color(red: 44/255, green: 62/255, blue: 80/255).opacity(0.3)
            ]
        }
    }
}

// MARK: - Quick Start Configuration

struct QuickStartConfiguration: View {
    @Environment(\.dismiss) var dismiss
    @State private var playerCount = 4
    @State private var selectedFormat = GolfFormat.completeFormatList.first { $0.name == "Best Ball" }
    @State private var showScorecard = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Header
                Text("Quick Game Setup")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Smart defaults
                VStack(alignment: .leading, spacing: 20) {
                    // Players
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Players")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Picker("Players", selection: $playerCount) {
                            ForEach(1...4, id: \.self) { count in
                                Text("\(count) \(count == 1 ? "Player" : "Players")")
                                    .tag(count)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Suggested format
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommended Format")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if let format = selectedFormat {
                            HStack {
                                FormatIconView(format: format, size: 40)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.name)
                                        .font(.system(size: 18, weight: .semibold))
                                    Text(format.tagline)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Change") {
                                    // Show format picker
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.primaryGreen)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(15)
                        }
                    }
                    
                    // Course settings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Course")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "flag.fill")
                                .foregroundColor(AppColors.primaryGreen)
                            Text("18 Holes")
                                .font(.system(size: 16))
                            Spacer()
                            Text("Par 72")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(15)
                    }
                }
                .padding()
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: {
                        showScorecard = true
                    }) {
                        Text("Start Game")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.primaryGreen,
                                        AppColors.darkGreen
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showScorecard) {
            if let format = selectedFormat {
                EnhancedScorecardView(
                    format: format,
                    configuration: GameConfiguration(
                        selectedFormat: format,
                        numberOfHoles: 18
                    )
                )
            }
        }
    }
}