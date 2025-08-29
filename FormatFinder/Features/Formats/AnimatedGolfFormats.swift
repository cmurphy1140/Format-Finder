import SwiftUI
import Combine

// MARK: - Enhanced Golf Format System with Animations
struct AnimatedGolfFormatsView: View {
    @State private var selectedFormat: AnimatedGolfFormat?
    @State private var showingTutorial = false
    @State private var animationPhase: Double = 0
    @Namespace private var formatNamespace
    
    let enhancedFormats = AnimatedGolfFormat.allFormats
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with animated golf ball
                    AnimatedHeaderView()
                    
                    // Format Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(enhancedFormats) { format in
                            AnimatedFormatCard(
                                format: format,
                                namespace: formatNamespace,
                                onTap: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        selectedFormat = format
                                        showingTutorial = true
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Golf Formats")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedFormat) { format in
            FormatTutorialView(format: format)
        }
    }
}

// MARK: - Enhanced Golf Format Model
// Note: Using a different name to avoid conflict with SwipeableFormatCards
struct AnimatedGolfFormat: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let primaryColor: Color
    let secondaryColor: Color
    let description: String
    let playerCount: String
    let difficulty: Difficulty
    let animationType: AnimationType
    let rules: [Rule]
    let scoringMethod: String
    let strategy: String
    
    enum Difficulty: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }
    
    enum AnimationType {
        case wolf
        case bingoBangoBongo
        case chapman
        case vegas
        case defender
        case rabbit
        case closeout
        case hammer
    }
    
    struct Rule {
        let title: String
        let description: String
        let animationKey: String
    }
    
    static let allFormats: [AnimatedGolfFormat] = [
        // Wolf Format
        AnimatedGolfFormat(
            name: "Wolf",
            icon: "person.3.fill",
            primaryColor: Color(hex: "4A5568"),
            secondaryColor: Color(hex: "718096"),
            description: "A rotating captain format where the 'Wolf' chooses partners or plays alone",
            playerCount: "4 Players",
            difficulty: .advanced,
            animationType: .wolf,
            rules: [
                Rule(title: "Wolf Selection", description: "Players rotate being the Wolf each hole", animationKey: "wolf_rotate"),
                Rule(title: "Partner Choice", description: "Wolf can choose a partner after each tee shot or go 'Lone Wolf'", animationKey: "wolf_choose"),
                Rule(title: "Scoring", description: "Lone Wolf earns triple points, partnerships split points", animationKey: "wolf_score")
            ],
            scoringMethod: "Points per hole: 1 point for team win, 3 points for Lone Wolf win",
            strategy: "Balance risk vs reward - going alone multiplies both wins and losses"
        ),
        
        // Bingo Bango Bongo
        AnimatedGolfFormat(
            name: "Bingo Bango Bongo",
            icon: "target",
            primaryColor: Color(hex: "F56565"),
            secondaryColor: Color(hex: "FC8181"),
            description: "Points for three achievements: first on green, closest to pin, first in hole",
            playerCount: "2-4 Players",
            difficulty: .beginner,
            animationType: .bingoBangoBongo,
            rules: [
                Rule(title: "Bingo", description: "First ball on the green earns 1 point", animationKey: "bingo"),
                Rule(title: "Bango", description: "Closest to the pin once all on green earns 1 point", animationKey: "bango"),
                Rule(title: "Bongo", description: "First ball in the hole earns 1 point", animationKey: "bongo")
            ],
            scoringMethod: "3 points available per hole, most total points wins",
            strategy: "Rewards good approach shots and putting, not just low scores"
        ),
        
        // Chapman (Pinehurst)
        AnimatedGolfFormat(
            name: "Chapman",
            icon: "arrow.triangle.swap",
            primaryColor: Color(hex: "48BB78"),
            secondaryColor: Color(hex: "68D391"),
            description: "Partners hit each other's drives, then choose best ball and alternate shots",
            playerCount: "2 Teams of 2",
            difficulty: .intermediate,
            animationType: .chapman,
            rules: [
                Rule(title: "Both Drive", description: "Both partners tee off", animationKey: "chapman_drive"),
                Rule(title: "Switch Balls", description: "Each player hits partner's drive for second shot", animationKey: "chapman_switch"),
                Rule(title: "Select & Alternate", description: "Choose best ball after second shots, then alternate", animationKey: "chapman_alternate")
            ],
            scoringMethod: "Team score vs team score, match or stroke play",
            strategy: "Requires teamwork and strategic ball selection"
        ),
        
        // Vegas
        AnimatedGolfFormat(
            name: "Vegas",
            icon: "die.face.6.fill",
            primaryColor: Color(hex: "805AD5"),
            secondaryColor: Color(hex: "9F7AEA"),
            description: "Team scores combined into two-digit numbers, like rolling dice",
            playerCount: "2 Teams of 2",
            difficulty: .intermediate,
            animationType: .vegas,
            rules: [
                Rule(title: "Combine Scores", description: "Lower score goes first (3 and 5 becomes 35)", animationKey: "vegas_combine"),
                Rule(title: "Flip Rule", description: "Birdie flips opponent's score (35 becomes 53)", animationKey: "vegas_flip"),
                Rule(title: "Points", description: "Difference between team scores becomes points", animationKey: "vegas_points")
            ],
            scoringMethod: "Point difference between combined scores",
            strategy: "Birdies become weapons, doubles can be devastating"
        ),
        
        // Defender
        AnimatedGolfFormat(
            name: "Defender",
            icon: "shield.fill",
            primaryColor: Color(hex: "38B2AC"),
            secondaryColor: Color(hex: "4FD1C5"),
            description: "One player defends points against the field each hole",
            playerCount: "3-4 Players",
            difficulty: .intermediate,
            animationType: .defender,
            rules: [
                Rule(title: "Defender Role", description: "Lowest score on previous hole becomes Defender", animationKey: "defender_role"),
                Rule(title: "Point Defense", description: "Defender earns 3 points if they win the hole", animationKey: "defender_points"),
                Rule(title: "Steal Points", description: "Others earn 1 point each if they beat Defender", animationKey: "defender_steal")
            ],
            scoringMethod: "Defenders earn 3 points for winning, others earn 1 for beating defender",
            strategy: "Pressure intensifies when defending, momentum shifts are key"
        ),
        
        // Rabbit
        AnimatedGolfFormat(
            name: "Rabbit",
            icon: "hare.fill",
            primaryColor: Color(hex: "ED8936"),
            secondaryColor: Color(hex: "F6AD55"),
            description: "The 'Rabbit' runs free until someone catches it by winning a hole",
            playerCount: "3-4 Players",
            difficulty: .beginner,
            animationType: .rabbit,
            rules: [
                Rule(title: "Release", description: "Rabbit is free at the start", animationKey: "rabbit_release"),
                Rule(title: "Capture", description: "Win a hole to capture the Rabbit", animationKey: "rabbit_capture"),
                Rule(title: "Hold & Score", description: "Hold the Rabbit for 1 point per hole", animationKey: "rabbit_hold")
            ],
            scoringMethod: "1 point per hole while holding the Rabbit",
            strategy: "Timing your capture and maintaining possession is crucial"
        ),
        
        // Closeout
        AnimatedGolfFormat(
            name: "Closeout",
            icon: "target",
            primaryColor: Color(hex: "E53E3E"),
            secondaryColor: Color(hex: "FC8181"),
            description: "Match play where you must win by exact margin to close out",
            playerCount: "2 Players/Teams",
            difficulty: .expert,
            animationType: .closeout,
            rules: [
                Rule(title: "Target Margin", description: "Set winning margin (e.g., 3&2)", animationKey: "closeout_target"),
                Rule(title: "Exact Win", description: "Must win by exact margin to close", animationKey: "closeout_exact"),
                Rule(title: "Continue Play", description: "If ahead by more, play continues", animationKey: "closeout_continue")
            ],
            scoringMethod: "First to reach exact target margin wins",
            strategy: "Strategic hole management, sometimes losing tactically"
        ),
        
        // Hammer
        AnimatedGolfFormat(
            name: "Hammer",
            icon: "hammer.fill",
            primaryColor: Color(hex: "DD6B20"),
            secondaryColor: Color(hex: "ED8936"),
            description: "Pass the 'Hammer' to double the stakes, pressure intensifies",
            playerCount: "2-4 Players/Teams",
            difficulty: .advanced,
            animationType: .hammer,
            rules: [
                Rule(title: "Hammer Pass", description: "Pass hammer to double current hole value", animationKey: "hammer_pass"),
                Rule(title: "Accept/Decline", description: "Recipient must accept or forfeit hole", animationKey: "hammer_accept"),
                Rule(title: "Escalation", description: "Hammer can be passed multiple times", animationKey: "hammer_escalate")
            ],
            scoringMethod: "Points double each time hammer is passed",
            strategy: "Psychological warfare - know when to apply pressure"
        )
    ]
}

// MARK: - Animated Header
struct AnimatedHeaderView: View {
    @State private var ballRotation: Double = 0
    @State private var ballPosition: CGFloat = 0
    @State private var trailOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "10B981").opacity(0.3),
                    Color(hex: "3B82F6").opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 120)
            .cornerRadius(20)
            
            HStack(spacing: 20) {
                // Animated golf ball
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                        .overlay(
                            // Golf ball dimples
                            ForEach(0..<6) { i in
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 8, height: 8)
                                    .offset(
                                        x: cos(Double(i) * .pi / 3) * 20,
                                        y: sin(Double(i) * .pi / 3) * 20
                                    )
                            }
                        )
                        .rotation3DEffect(
                            .degrees(ballRotation),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .offset(x: ballPosition)
                    
                    // Motion trail
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white.opacity(trailOpacity * (0.3 - Double(i) * 0.1)))
                            .frame(width: 60 - CGFloat(i * 10), height: 60 - CGFloat(i * 10))
                            .offset(x: ballPosition - CGFloat(i * 20))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover New Formats")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("8 exciting ways to play")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                ballRotation = 360
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                ballPosition = 30
                trailOpacity = 1
            }
        }
    }
}

// MARK: - Animated Format Card
struct AnimatedFormatCard: View {
    let format: AnimatedGolfFormat
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var iconScale: CGFloat = 1
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with animation
            ZStack {
                Circle()
                    .fill(format.primaryColor.gradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(format.secondaryColor, lineWidth: 3)
                            .scaleEffect(iconScale)
                            .opacity(glowOpacity)
                    )
                
                Text(format.icon)
                    .font(.system(size: 40))
                    .scaleEffect(iconScale)
            }
            .matchedGeometryEffect(id: "icon-\(format.id)", in: namespace)
            
            VStack(spacing: 4) {
                Text(format.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .matchedGeometryEffect(id: "title-\(format.id)", in: namespace)
                
                Text(format.playerCount)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                AnimatedDifficultyBadge(difficulty: format.difficulty)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: isHovered ? format.primaryColor.opacity(0.3) : .gray.opacity(0.2),
                    radius: isHovered ? 12 : 6,
                    x: 0,
                    y: isHovered ? 8 : 4
                )
        )
        .scaleEffect(isHovered ? 1.05 : 1)
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
                iconScale = hovering ? 1.1 : 1
                glowOpacity = hovering ? 0.6 : 0
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowOpacity = 0.3
            }
        }
    }
}

// MARK: - Difficulty Badge
struct AnimatedDifficultyBadge: View {
    let difficulty: AnimatedGolfFormat.Difficulty
    
    var difficultyColor: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { i in
                Circle()
                    .fill(i < difficultyLevel ? difficultyColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(difficultyColor.opacity(0.1))
        )
    }
    
    var difficultyLevel: Int {
        switch difficulty {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

// MARK: - Format Tutorial View
struct FormatTutorialView: View {
    let format: AnimatedGolfFormat
    @Environment(\.dismiss) var dismiss
    @State private var currentRuleIndex = 0
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Format Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(format.primaryColor.gradient)
                                .frame(width: 100, height: 100)
                            
                            Text(format.icon)
                                .font(.system(size: 50))
                        }
                        
                        Text(format.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(format.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Animated Visual Explanation
                    AnimatedExplanationView(
                        format: format,
                        currentRuleIndex: $currentRuleIndex,
                        animationProgress: animationProgress
                    )
                    .frame(height: 300)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Rules Carousel
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How to Play")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        TabView(selection: $currentRuleIndex) {
                            ForEach(format.rules.indices, id: \.self) { index in
                                AnimatedRuleCard(rule: format.rules[index])
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 150)
                    }
                    
                    // Scoring & Strategy
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            title: "Scoring",
                            content: format.scoringMethod,
                            icon: "number.circle.fill",
                            color: format.primaryColor
                        )
                        
                        InfoSection(
                            title: "Strategy",
                            content: format.strategy,
                            icon: "lightbulb.fill",
                            color: format.secondaryColor
                        )
                    }
                    .padding(.horizontal)
                    
                    // Start Playing Button
                    Button(action: {
                        dismiss()
                    }) {
                        Label("Start Playing", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(format.primaryColor.gradient)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Rule Card
struct AnimatedRuleCard: View {
    let rule: AnimatedGolfFormat.Rule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text(rule.title)
                    .font(.headline)
            }
            
            Text(rule.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Info Section
struct InfoSection: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Animated Explanation View
struct AnimatedExplanationView: View {
    let format: AnimatedGolfFormat
    @Binding var currentRuleIndex: Int
    let animationProgress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch format.animationType {
                case .wolf:
                    WolfAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                case .bingoBangoBongo:
                    BingoBangoBongoAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                case .chapman:
                    ChapmanAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                case .vegas:
                    VegasAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                case .defender:
                    DefenderAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                case .rabbit:
                    RabbitAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                case .closeout:
                    CloseoutAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                case .hammer:
                    HammerAnimationView(progress: animationProgress, ruleIndex: currentRuleIndex)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Wolf Animation
struct WolfAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    @State private var wolfPosition: CGFloat = 0
    @State private var packPositions: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        ZStack {
            // Golf course background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.green.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Players
            HStack(spacing: 40) {
                ForEach(0..<4) { index in
                    VStack {
                        if index == Int(wolfPosition) {
                            // Wolf
                            ZStack {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 50, height: 50)
                                
                                Text("🐺")
                                    .font(.system(size: 30))
                                    .rotationEffect(.degrees(progress * 360))
                            }
                            Text("Wolf")
                                .font(.caption)
                                .fontWeight(.bold)
                        } else {
                            // Regular players
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("P\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .offset(y: packPositions[min(index, 2)])
                }
            }
            
            // Rule explanation
            VStack {
                Spacer()
                Text(ruleText)
                    .font(.subheadline)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .padding()
            }
        }
        .onAppear {
            animateWolf()
        }
    }
    
    var ruleText: String {
        switch ruleIndex {
        case 0: return "The Wolf rotates each hole"
        case 1: return "Wolf chooses partner or goes alone"
        case 2: return "Lone Wolf earns triple points!"
        default: return ""
        }
    }
    
    func animateWolf() {
        withAnimation(.easeInOut(duration: 4).repeatForever()) {
            wolfPosition = 3
        }
        
        for i in 0..<3 {
            withAnimation(.easeInOut(duration: 2).repeatForever().delay(Double(i) * 0.3)) {
                packPositions[i] = -10
            }
        }
    }
}

// MARK: - Bingo Bango Bongo Animation
struct BingoBangoBongoAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    
    @State private var ballPositions: [CGPoint] = [
        CGPoint(x: 50, y: 200),
        CGPoint(x: 100, y: 200),
        CGPoint(x: 150, y: 200),
        CGPoint(x: 200, y: 200)
    ]
    @State private var achievements: [Bool] = [false, false, false]
    
    var body: some View {
        ZStack {
            // Green
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 150, height: 150)
                .position(x: 180, y: 100)
            
            // Pin
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 20, height: 8)
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 30)
            }
            .position(x: 180, y: 100)
            
            // Balls
            ForEach(0..<4) { index in
                Circle()
                    .fill(index == 0 ? Color.yellow : Color.white)
                    .frame(width: 20, height: 20)
                    .position(ballPositions[index])
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: ballPositions[index])
            }
            
            // Achievement badges
            HStack(spacing: 20) {
                ForEach(0..<3) { index in
                    VStack {
                        ZStack {
                            Circle()
                                .fill(achievements[index] ? Color.yellow : Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: achievementIcon(index))
                                .foregroundColor(achievements[index] ? .white : .gray)
                        }
                        .scaleEffect(achievements[index] ? 1.2 : 1)
                        .animation(.spring(), value: achievements[index])
                        
                        Text(achievementName(index))
                            .font(.caption2)
                    }
                }
            }
            .position(x: 180, y: 250)
        }
        .onAppear {
            animateBingoBangoBongo()
        }
    }
    
    func achievementIcon(_ index: Int) -> String {
        switch index {
        case 0: return "flag.fill"
        case 1: return "target"
        case 2: return "checkmark.circle.fill"
        default: return ""
        }
    }
    
    func achievementName(_ index: Int) -> String {
        switch index {
        case 0: return "Bingo"
        case 1: return "Bango"
        case 2: return "Bongo"
        default: return ""
        }
    }
    
    func animateBingoBangoBongo() {
        // Animate balls to green
        withAnimation(.easeOut(duration: 1).delay(0.5)) {
            ballPositions[0] = CGPoint(x: 150, y: 100)
            achievements[0] = true
        }
        
        withAnimation(.easeOut(duration: 1).delay(1.5)) {
            ballPositions[1] = CGPoint(x: 170, y: 90)
            ballPositions[2] = CGPoint(x: 190, y: 110)
            ballPositions[3] = CGPoint(x: 160, y: 120)
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(2.5)) {
            achievements[1] = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(3.5)) {
            ballPositions[1] = CGPoint(x: 180, y: 100)
            achievements[2] = true
        }
    }
}

// MARK: - Chapman Animation
struct ChapmanAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    
    @State private var ballPaths: [Path] = []
    @State private var showPaths = false
    @State private var selectedBall = 0
    
    var body: some View {
        ZStack {
            // Fairway
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.2), Color.green.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Ball paths
            if showPaths {
                ForEach(0..<2) { index in
                    Path { path in
                        path.move(to: CGPoint(x: 50, y: 150))
                        path.addQuadCurve(
                            to: CGPoint(x: 250, y: index == 0 ? 80 : 120),
                            control: CGPoint(x: 150, y: index == 0 ? 50 : 100)
                        )
                    }
                    .stroke(
                        index == 0 ? Color.blue : Color.orange,
                        style: StrokeStyle(lineWidth: 3, dash: [5, 5])
                    )
                    .opacity(showPaths ? 1 : 0)
                    .animation(.easeIn(duration: 1), value: showPaths)
                }
            }
            
            // Step indicator
            VStack {
                HStack(spacing: 30) {
                    ForEach(0..<3) { step in
                        VStack {
                            Circle()
                                .fill(ruleIndex >= step ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text("\(step + 1)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                            
                            Text(stepName(step))
                                .font(.caption2)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            animateChapman()
        }
    }
    
    func stepName(_ step: Int) -> String {
        switch step {
        case 0: return "Both Drive"
        case 1: return "Switch"
        case 2: return "Alternate"
        default: return ""
        }
    }
    
    func animateChapman() {
        withAnimation(.easeOut(duration: 1).delay(0.5)) {
            showPaths = true
        }
    }
}

// MARK: - Vegas Animation
struct VegasAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    
    @State private var dice1: Int = 3
    @State private var dice2: Int = 5
    @State private var diceRotation: Double = 0
    @State private var showFlip = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Team scores
            HStack(spacing: 60) {
                // Team 1
                VStack {
                    Text("Team 1")
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        DiceView(value: dice1, rotation: diceRotation)
                        DiceView(value: dice2, rotation: diceRotation)
                    }
                    
                    Text("\(combinedScore)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // VS
                Text("VS")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Team 2
                VStack {
                    Text("Team 2")
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        DiceView(value: 4, rotation: diceRotation)
                        DiceView(value: 6, rotation: diceRotation)
                    }
                    
                    Text("\(showFlip ? "64" : "46")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .rotationEffect(.degrees(showFlip ? 180 : 0))
                }
            }
            
            // Explanation
            Text(ruleIndex == 0 ? "Lower score goes first: \(dice1) and \(dice2) = \(combinedScore)" :
                 ruleIndex == 1 ? "Birdie flips opponent's score!" :
                 "Point difference: \(abs(combinedScore - 46))")
                .font(.subheadline)
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
        }
        .onAppear {
            animateVegas()
        }
    }
    
    var combinedScore: Int {
        min(dice1, dice2) * 10 + max(dice1, dice2)
    }
    
    func animateVegas() {
        withAnimation(.easeInOut(duration: 1).repeatForever()) {
            diceRotation = 360
        }
        
        if ruleIndex == 1 {
            withAnimation(.spring().delay(1)) {
                showFlip = true
            }
        }
    }
}

// MARK: - Dice View
struct DiceView: View {
    let value: Int
    let rotation: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(radius: 3)
            
            // Dice dots
            dicePattern(for: value)
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 1, y: 1, z: 0)
        )
    }
    
    @ViewBuilder
    func dicePattern(for value: Int) -> some View {
        let dotPositions = getDotPositions(for: value)
        ForEach(dotPositions, id: \.x) { position in
            Circle()
                .fill(Color.black)
                .frame(width: 8, height: 8)
                .offset(x: position.x * 12, y: position.y * 12)
        }
    }
    
    func getDotPositions(for value: Int) -> [CGPoint] {
        switch value {
        case 1: return [CGPoint(x: 0, y: 0)]
        case 2: return [CGPoint(x: -1, y: -1), CGPoint(x: 1, y: 1)]
        case 3: return [CGPoint(x: -1, y: -1), CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)]
        case 4: return [CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1), CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1)]
        case 5: return [CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1), CGPoint(x: 0, y: 0), CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1)]
        case 6: return [CGPoint(x: -1, y: -1), CGPoint(x: 1, y: -1), CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: -1, y: 1), CGPoint(x: 1, y: 1)]
        default: return []
        }
    }
}

// MARK: - Defender Animation
struct DefenderAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    
    @State private var shieldScale: CGFloat = 1
    @State private var attackerPositions: [CGFloat] = [-100, -100, -100]
    @State private var shieldGlow = false
    
    var body: some View {
        ZStack {
            // Defender with shield
            VStack {
                ZStack {
                    // Shield
                    Image(systemName: "shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .scaleEffect(shieldScale)
                        .shadow(color: shieldGlow ? .blue : .clear, radius: shieldGlow ? 10 : 0)
                    
                    Text("3")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("Defender")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            // Attackers
            ForEach(0..<3) { index in
                VStack {
                    Circle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                    
                    Text("P\(index + 2)")
                        .font(.caption2)
                }
                .offset(x: attackerPositions[index], y: CGFloat(index - 1) * 60)
            }
            
            // Points display
            VStack {
                Spacer()
                Text(ruleIndex == 0 ? "Lowest score becomes Defender" :
                     ruleIndex == 1 ? "Defender earns 3 points for winning" :
                     "Others earn 1 point for beating Defender")
                    .font(.subheadline)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            animateDefender()
        }
    }
    
    func animateDefender() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
            shieldScale = 1.1
            shieldGlow.toggle()
        }
        
        for i in 0..<3 {
            withAnimation(.easeOut(duration: 1).delay(Double(i) * 0.3)) {
                attackerPositions[i] = 80
            }
        }
    }
}

// MARK: - Rabbit Animation
struct RabbitAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    
    @State private var rabbitPosition: CGPoint = CGPoint(x: 100, y: 150)
    @State private var rabbitHops = false
    @State private var currentHolder = -1
    
    var body: some View {
        ZStack {
            // Players
            ForEach(0..<4) { index in
                VStack {
                    Circle()
                        .fill(currentHolder == index ? Color.green : Color.blue.opacity(0.7))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("P\(index + 1)")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                    
                    if currentHolder == index {
                        Text("+1 pt/hole")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .position(playerPosition(index))
            }
            
            // Rabbit
            Text("🐰")
                .font(.system(size: 40))
                .position(rabbitPosition)
                .offset(y: rabbitHops ? -10 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5).repeatForever(), value: rabbitHops)
            
            // Rule display
            VStack {
                Spacer()
                Text(ruleIndex == 0 ? "Rabbit starts free" :
                     ruleIndex == 1 ? "Win a hole to capture" :
                     "Hold for 1 point per hole")
                    .font(.subheadline)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            animateRabbit()
        }
    }
    
    func playerPosition(_ index: Int) -> CGPoint {
        let angle = Double(index) * .pi / 2
        return CGPoint(
            x: 180 + cos(angle) * 80,
            y: 150 + sin(angle) * 80
        )
    }
    
    func animateRabbit() {
        rabbitHops = true
        
        // Rabbit movement animation
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            withAnimation(.spring()) {
                currentHolder = (currentHolder + 1) % 4
                if currentHolder >= 0 {
                    rabbitPosition = playerPosition(currentHolder)
                }
            }
        }
    }
}

// MARK: - Closeout Animation
struct CloseoutAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    
    @State private var holesWon = 0
    @State private var targetMargin = 3
    @State private var holesRemaining = 5
    
    var body: some View {
        VStack(spacing: 30) {
            // Match status
            VStack {
                Text("Match Play Status")
                    .font(.headline)
                
                HStack(spacing: 40) {
                    VStack {
                        Text("You")
                            .font(.caption)
                        Text("\(holesWon)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Text("UP")
                        .font(.caption)
                    
                    VStack {
                        Text("Opponent")
                            .font(.caption)
                        Text("0")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Progress bar
            VStack(alignment: .leading) {
                Text("Target: \(targetMargin) & \(targetMargin - 1)")
                    .font(.caption)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 30)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(holesWon == targetMargin ? Color.green : Color.blue)
                        .frame(width: CGFloat(holesWon) / CGFloat(targetMargin) * 200, height: 30)
                        .animation(.spring(), value: holesWon)
                    
                    if holesWon == targetMargin {
                        Text("EXACT WIN!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.leading, 8)
                    }
                }
                .frame(width: 200)
            }
            
            // Holes remaining
            HStack {
                ForEach(0..<holesRemaining) { _ in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }
            
            // Rule explanation
            Text(ruleIndex == 0 ? "Set target margin (e.g., 3&2)" :
                 ruleIndex == 1 ? "Must win by exact margin" :
                 "If ahead by more, play continues")
                .font(.subheadline)
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
        }
        .onAppear {
            animateCloseout()
        }
    }
    
    func animateCloseout() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            withAnimation {
                if holesWon < targetMargin {
                    holesWon += 1
                    holesRemaining -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - Hammer Animation
struct HammerAnimationView: View {
    let progress: CGFloat
    let ruleIndex: Int
    
    @State private var hammerHolder = 0
    @State private var hammerRotation: Double = 0
    @State private var hammerScale: CGFloat = 1
    @State private var pointValue = 1
    @State private var showPressure = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Point value
            Text("Hole Value: \(pointValue) points")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(pointValue > 2 ? .red : .blue)
                .scaleEffect(pointValue > 2 ? 1.2 : 1)
                .animation(.spring(), value: pointValue)
            
            // Players with hammer
            HStack(spacing: 60) {
                ForEach(0..<2) { index in
                    VStack {
                        if hammerHolder == index {
                            // Hammer
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                                .rotationEffect(.degrees(hammerRotation))
                                .scaleEffect(hammerScale)
                                .shadow(color: .orange.opacity(0.5), radius: showPressure ? 10 : 0)
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 50, height: 50)
                        }
                        
                        Text("Player \(index + 1)")
                            .font(.caption)
                        
                        if hammerHolder != index && showPressure {
                            Text("PRESSURE!")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .scaleEffect(showPressure ? 1.2 : 1)
                        }
                    }
                }
            }
            
            // Action buttons
            if ruleIndex == 1 {
                HStack(spacing: 20) {
                    Button("Accept") {
                        withAnimation {
                            pointValue *= 2
                            hammerHolder = 1 - hammerHolder
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Decline") {
                        // Forfeit hole
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            
            // Rule explanation
            Text(ruleIndex == 0 ? "Pass hammer to double stakes" :
                 ruleIndex == 1 ? "Accept the pressure or forfeit" :
                 "Stakes can escalate quickly!")
                .font(.subheadline)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
        }
        .onAppear {
            animateHammer()
        }
    }
    
    func animateHammer() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            hammerRotation = -20
            hammerScale = 1.1
        }
        
        if ruleIndex > 0 {
            withAnimation(.easeIn.delay(1)) {
                showPressure = true
            }
        }
    }
}

// MARK: - Color Extension
// Using Color(hex:) extension from ThemeEngine.swift