import SwiftUI
import SpriteKit
import CoreHaptics

// MARK: - Interactive Format Learning View
struct InteractiveFormatView: View {
    let format: GolfFormat
    @State private var currentScenario = 0
    @State private var isPlaying = false
    @State private var playbackSpeed: Double = 1.0
    @State private var showWhatIf = false
    @GestureState private var dragState = DragState.inactive
    @State private var viewState = CGSize.zero
    @State private var hapticEngine: CHHapticEngine?
    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Interactive Scene
            ZStack {
                InteractiveGolfScene(
                    format: format,
                    scenario: currentScenario,
                    isPlaying: $isPlaying,
                    dragState: dragState,
                    viewState: $viewState
                )
                .frame(height: 350)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                
                // Drag indicator
                if dragState.translation != .zero {
                    DragIndicatorView(translation: dragState.translation)
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        state = .dragging(translation: value.translation)
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            viewState = value.translation
                            // Trigger haptic feedback
                            impactFeedback(.medium)
                        }
                        
                        // Reset after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.spring()) {
                                viewState = .zero
                            }
                        }
                    }
            )
            
            // Playback Controls
            PlaybackControlsView(
                isPlaying: $isPlaying,
                playbackSpeed: $playbackSpeed,
                currentScenario: $currentScenario,
                totalScenarios: getScenarios(for: format).count,
                onPrevious: previousScenario,
                onNext: nextScenario,
                onRestart: restartScenario
            )
            .padding(.vertical, 20)
            
            // Scenario Description
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScenarioDescriptionView(
                        format: format,
                        scenario: getScenarios(for: format)[currentScenario]
                    )
                    
                    // What-If Mode Toggle
                    Button(action: {
                        withAnimation(.spring()) {
                            showWhatIf.toggle()
                            impactFeedback(.light)
                        }
                    }) {
                        HStack {
                            Image(systemName: showWhatIf ? "questionmark.circle.fill" : "questionmark.circle")
                            Text("What If Mode")
                            Spacer()
                            Text(showWhatIf ? "ON" : "OFF")
                                .font(.caption)
                                .foregroundColor(showWhatIf ? .green : .gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if showWhatIf {
                        WhatIfScenariosView(format: format, currentScenario: currentScenario)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                    
                    // Achievement Progress
                    AchievementProgressView(format: format)
                        .padding(.top)
                }
                .padding()
            }
        }
        .onAppear {
            prepareHaptics()
        }
    }
    
    func getScenarios(for format: GolfFormat) -> [FormatScenario] {
        // Return format-specific scenarios
        switch format.name {
        case "Scramble":
            return ScrambleScenarios.all
        case "Best Ball":
            return BestBallScenarios.all
        case "Match Play":
            return MatchPlayScenarios.all
        case "Skins":
            return SkinsScenarios.all
        default:
            return [FormatScenario.default]
        }
    }
    
    func previousScenario() {
        withAnimation(.spring()) {
            currentScenario = max(0, currentScenario - 1)
            impactFeedback(.light)
        }
    }
    
    func nextScenario() {
        let scenarios = getScenarios(for: format)
        withAnimation(.spring()) {
            currentScenario = min(scenarios.count - 1, currentScenario + 1)
            impactFeedback(.light)
        }
    }
    
    func restartScenario() {
        withAnimation(.spring()) {
            isPlaying = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPlaying = true
            }
            impactFeedback(.medium)
        }
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }
    
    func impactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Interactive Golf Scene (SpriteKit Integration)
struct InteractiveGolfScene: UIViewRepresentable {
    let format: GolfFormat
    let scenario: Int
    @Binding var isPlaying: Bool
    let dragState: InteractiveFormatView.DragState
    @Binding var viewState: CGSize
    
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        
        let scene = GolfGameScene(size: CGSize(width: 400, height: 350))
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        scene.formatType = format.name
        scene.scenarioIndex = scenario
        
        skView.presentScene(scene)
        
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        guard let scene = uiView.scene as? GolfGameScene else { return }
        
        scene.isPlaying = isPlaying
        scene.updateScenario(scenario)
        scene.handleDrag(dragState.translation)
        
        if viewState != .zero {
            scene.applyImpact(viewState)
        }
    }
}

// MARK: - SpriteKit Golf Game Scene
class GolfGameScene: SKScene {
    var formatType: String = ""
    var scenarioIndex: Int = 0
    var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private var ballNodes: [SKShapeNode] = []
    private var playerNodes: [SKSpriteNode] = []
    private var fairwayNode: SKShapeNode?
    private var greenNode: SKShapeNode?
    private var flagNode: SKSpriteNode?
    
    override func didMove(to view: SKView) {
        setupCourse()
        setupPlayers()
    }
    
    func setupCourse() {
        // Fairway
        let fairway = SKShapeNode()
        let fairwayPath = UIBezierPath()
        fairwayPath.move(to: CGPoint(x: 50, y: 250))
        fairwayPath.addQuadCurve(to: CGPoint(x: 350, y: 150), controlPoint: CGPoint(x: 200, y: 200))
        fairwayPath.addLine(to: CGPoint(x: 350, y: 100))
        fairwayPath.addQuadCurve(to: CGPoint(x: 50, y: 200), controlPoint: CGPoint(x: 200, y: 150))
        fairwayPath.close()
        
        fairway.path = fairwayPath.cgPath
        fairway.fillColor = UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 0.8)
        fairway.strokeColor = .clear
        fairway.position = CGPoint(x: 0, y: 0)
        addChild(fairway)
        fairwayNode = fairway
        
        // Green
        let green = SKShapeNode(circleOfRadius: 30)
        green.fillColor = UIColor(red: 0/255, green: 100/255, blue: 0/255, alpha: 0.9)
        green.strokeColor = .clear
        green.position = CGPoint(x: 320, y: 125)
        addChild(green)
        greenNode = green
        
        // Flag
        let flag = SKSpriteNode(systemName: "flag.fill")
        flag.size = CGSize(width: 20, height: 30)
        flag.position = CGPoint(x: 320, y: 125)
        flag.color = .red
        addChild(flag)
        flagNode = flag
    }
    
    func setupPlayers() {
        // Create players based on format
        let playerCount = getPlayerCount()
        
        for i in 0..<playerCount {
            let player = SKSpriteNode(systemName: "figure.golf")
            player.size = CGSize(width: 30, height: 30)
            player.position = CGPoint(x: 60 + CGFloat(i * 20), y: 225)
            player.color = playerColors[i]
            player.name = "player_\(i)"
            addChild(player)
            playerNodes.append(player)
            
            // Add ball for each player
            let ball = SKShapeNode(circleOfRadius: 4)
            ball.fillColor = .white
            ball.strokeColor = playerColors[i]
            ball.lineWidth = 1
            ball.position = player.position
            ball.name = "ball_\(i)"
            addChild(ball)
            ballNodes.append(ball)
        }
    }
    
    func getPlayerCount() -> Int {
        switch formatType {
        case "Scramble", "Best Ball":
            return 4
        case "Match Play", "Alternate Shot":
            return 2
        case "Skins":
            return 3
        default:
            return 2
        }
    }
    
    func updateScenario(_ index: Int) {
        scenarioIndex = index
        resetScene()
    }
    
    func handleDrag(_ translation: CGSize) {
        // Move selected ball based on drag
        if let selectedBall = ballNodes.first {
            let newPosition = CGPoint(
                x: selectedBall.position.x + translation.width * 0.1,
                y: selectedBall.position.y - translation.height * 0.1
            )
            
            // Constrain to fairway bounds
            let constrainedPosition = constrainPosition(newPosition)
            
            let moveAction = SKAction.move(to: constrainedPosition, duration: 0.1)
            selectedBall.run(moveAction)
        }
    }
    
    func applyImpact(_ translation: CGSize) {
        // Apply physics-based movement to balls
        ballNodes.forEach { ball in
            let impulse = CGVector(
                dx: translation.width * 0.5,
                dy: -translation.height * 0.5
            )
            
            if ball.physicsBody == nil {
                ball.physicsBody = SKPhysicsBody(circleOfRadius: 4)
                ball.physicsBody?.isDynamic = true
                ball.physicsBody?.restitution = 0.5
                ball.physicsBody?.friction = 0.3
            }
            
            ball.physicsBody?.applyImpulse(impulse)
        }
    }
    
    func constrainPosition(_ position: CGPoint) -> CGPoint {
        let minX: CGFloat = 50
        let maxX: CGFloat = 350
        let minY: CGFloat = 50
        let maxY: CGFloat = 300
        
        return CGPoint(
            x: max(minX, min(maxX, position.x)),
            y: max(minY, min(maxY, position.y))
        )
    }
    
    func startAnimation() {
        animateScenario()
    }
    
    func stopAnimation() {
        removeAllActions()
        ballNodes.forEach { $0.removeAllActions() }
        playerNodes.forEach { $0.removeAllActions() }
    }
    
    func animateScenario() {
        switch formatType {
        case "Scramble":
            animateScrambleScenario()
        case "Best Ball":
            animateBestBallScenario()
        case "Match Play":
            animateMatchPlayScenario()
        default:
            animateDefaultScenario()
        }
    }
    
    func animateScrambleScenario() {
        // All players hit, then move to best shot
        for (index, ball) in ballNodes.enumerated() {
            let targetPosition = CGPoint(
                x: 200 + CGFloat.random(in: -30...30),
                y: 150 + CGFloat.random(in: -20...20)
            )
            
            let waitAction = SKAction.wait(forDuration: Double(index) * 0.3)
            let moveAction = SKAction.move(to: targetPosition, duration: 1.0)
            let sequence = SKAction.sequence([waitAction, moveAction])
            
            ball.run(sequence)
        }
        
        // After all balls land, highlight best shot
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let bestBall = self.ballNodes.randomElement() {
                let scaleUp = SKAction.scale(to: 2.0, duration: 0.3)
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
                let pulse = SKAction.sequence([scaleUp, scaleDown])
                bestBall.run(SKAction.repeat(pulse, count: 3))
            }
        }
    }
    
    func animateBestBallScenario() {
        // Each player plays their own ball
        for (index, ball) in ballNodes.enumerated() {
            let targetPosition = CGPoint(
                x: 320 + CGFloat.random(in: -20...20),
                y: 125 + CGFloat.random(in: -15...15)
            )
            
            let waitAction = SKAction.wait(forDuration: Double(index) * 0.5)
            let moveAction = SKAction.move(to: targetPosition, duration: 1.5)
            let sequence = SKAction.sequence([waitAction, moveAction])
            
            ball.run(sequence)
        }
    }
    
    func animateMatchPlayScenario() {
        // Head-to-head competition
        guard ballNodes.count >= 2 else { return }
        
        let ball1 = ballNodes[0]
        let ball2 = ballNodes[1]
        
        let target1 = CGPoint(x: 310, y: 130)
        let target2 = CGPoint(x: 330, y: 120)
        
        ball1.run(SKAction.move(to: target1, duration: 1.2))
        ball2.run(SKAction.move(to: target2, duration: 1.4))
        
        // Show winner
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let winnerLabel = SKLabelNode(text: "Player 1 Wins Hole!")
            winnerLabel.fontSize = 16
            winnerLabel.fontColor = .yellow
            winnerLabel.position = CGPoint(x: 200, y: 50)
            self.addChild(winnerLabel)
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let wait = SKAction.wait(forDuration: 1.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            
            winnerLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
        }
    }
    
    func animateDefaultScenario() {
        // Generic animation for other formats
        ballNodes.forEach { ball in
            let randomTarget = CGPoint(
                x: CGFloat.random(in: 200...340),
                y: CGFloat.random(in: 100...150)
            )
            
            ball.run(SKAction.move(to: randomTarget, duration: 1.5))
        }
    }
    
    func resetScene() {
        // Reset all positions
        for (index, player) in playerNodes.enumerated() {
            player.position = CGPoint(x: 60 + CGFloat(index * 20), y: 225)
        }
        
        for (index, ball) in ballNodes.enumerated() {
            ball.position = playerNodes[index].position
            ball.removeAllActions()
        }
    }
    
    private let playerColors: [UIColor] = [
        UIColor.systemBlue,
        UIColor.systemRed,
        UIColor.systemGreen,
        UIColor.systemOrange
    ]
}

// MARK: - Supporting Views

struct DragIndicatorView: View {
    let translation: CGSize
    
    var body: some View {
        VStack {
            Image(systemName: "hand.draw")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .shadow(radius: 5)
            
            Text("Drag to move ball")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
        }
        .offset(translation)
        .opacity(0.8)
    }
}

struct PlaybackControlsView: View {
    @Binding var isPlaying: Bool
    @Binding var playbackSpeed: Double
    @Binding var currentScenario: Int
    let totalScenarios: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress indicator
            HStack(spacing: 6) {
                ForEach(0..<totalScenarios, id: \.self) { index in
                    Circle()
                        .fill(index == currentScenario ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Playback controls
            HStack(spacing: 30) {
                Button(action: onPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                }
                .disabled(currentScenario == 0)
                
                Button(action: {
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Color.green))
                        .foregroundColor(.white)
                }
                
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                }
                .disabled(currentScenario == totalScenarios - 1)
            }
            
            // Speed control
            HStack {
                Text("Speed:")
                    .font(.caption)
                
                Slider(value: $playbackSpeed, in: 0.5...2.0, step: 0.5)
                    .frame(width: 150)
                
                Text("\(playbackSpeed, specifier: "%.1f")x")
                    .font(.caption)
                    .frame(width: 30)
            }
            
            // Restart button
            Button(action: onRestart) {
                Label("Restart", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ScenarioDescriptionView: View {
    let format: GolfFormat
    let scenario: FormatScenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(scenario.title)
                .font(.title2.bold())
            
            Text(scenario.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if !scenario.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Points:")
                        .font(.headline)
                    
                    ForEach(scenario.keyPoints, id: \.self) { point in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(point)
                                .font(.callout)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct WhatIfScenariosView: View {
    let format: GolfFormat
    let currentScenario: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What If Scenarios")
                .font(.headline)
            
            ForEach(getWhatIfScenarios(), id: \.self) { whatIf in
                HStack(alignment: .top) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(whatIf.question)
                            .font(.callout.bold())
                        
                        Text(whatIf.answer)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    func getWhatIfScenarios() -> [WhatIfScenario] {
        // Return format-specific what-if scenarios
        switch format.name {
        case "Scramble":
            return [
                WhatIfScenario(
                    question: "What if no one reaches the green?",
                    answer: "Continue playing from the best available shot until someone reaches the green."
                ),
                WhatIfScenario(
                    question: "What if a ball goes out of bounds?",
                    answer: "That shot is eliminated from selection, choose from remaining balls."
                )
            ]
        default:
            return []
        }
    }
}

struct AchievementProgressView: View {
    let format: GolfFormat
    @State private var unlockedAchievements: Set<String> = []
    
    var achievements: [FormatAchievement] {
        [
            FormatAchievement(id: "first_play", name: "First Timer", icon: "star"),
            FormatAchievement(id: "complete_tutorial", name: "Tutorial Master", icon: "graduationcap"),
            FormatAchievement(id: "try_whatif", name: "Curious Mind", icon: "questionmark.circle"),
            FormatAchievement(id: "master_format", name: "Format Expert", icon: "crown")
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementBadge(
                        achievement: achievement,
                        isUnlocked: unlockedAchievements.contains(achievement.id)
                    )
                }
            }
        }
    }
}

struct AchievementBadge: View {
    let achievement: FormatAchievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? .yellow : .gray)
            
            Text(achievement.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundColor(isUnlocked ? .primary : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isUnlocked ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Data Models

struct FormatScenario {
    let title: String
    let description: String
    let keyPoints: [String]
    
    static let `default` = FormatScenario(
        title: "Basic Play",
        description: "Standard format rules apply",
        keyPoints: []
    )
}

struct ScrambleScenarios {
    static let all = [
        FormatScenario(
            title: "Tee Shot Selection",
            description: "All players tee off, then the team selects the best drive",
            keyPoints: [
                "Consider position over distance",
                "Factor in lie and angle to green",
                "Team discussion is crucial"
            ]
        ),
        FormatScenario(
            title: "Approach Strategy",
            description: "Everyone plays from the selected spot",
            keyPoints: [
                "Order matters - best putter goes last",
                "Safe play first, aggressive last",
                "Read the green together"
            ]
        )
    ]
}

struct BestBallScenarios {
    static let all = [
        FormatScenario(
            title: "Individual Play",
            description: "Each player plays their own ball throughout the hole",
            keyPoints: [
                "No pressure - one bad shot doesn't hurt team",
                "Play your normal game",
                "Support teammates"
            ]
        )
    ]
}

struct MatchPlayScenarios {
    static let all = [
        FormatScenario(
            title: "Hole-by-Hole Competition",
            description: "Win individual holes, not total strokes",
            keyPoints: [
                "Each hole is a separate competition",
                "Ties (halves) are common",
                "Strategy changes based on match status"
            ]
        )
    ]
}

struct SkinsScenarios {
    static let all = [
        FormatScenario(
            title: "Winner Takes All",
            description: "Lowest score on each hole wins the skin",
            keyPoints: [
                "Ties carry skins to next hole",
                "Pressure builds with carryovers",
                "Every hole is an opportunity"
            ]
        )
    ]
}

struct WhatIfScenario: Hashable {
    let question: String
    let answer: String
}

struct FormatAchievement {
    let id: String
    let name: String
    let icon: String
}

// MARK: - UIKit Extensions for SpriteKit
extension SKSpriteNode {
    convenience init(systemName: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 30)
        let image = UIImage(systemName: systemName, withConfiguration: config)
        let texture = SKTexture(image: image ?? UIImage())
        self.init(texture: texture)
    }
}