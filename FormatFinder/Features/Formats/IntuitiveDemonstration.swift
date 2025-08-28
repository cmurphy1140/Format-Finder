import SwiftUI

// MARK: - Intuitive Format Demonstration

struct IntuitiveFormatDemonstration: View {
    let format: GolfFormat
    @State private var currentStep = 0
    @State private var isAnimating = false
    @State private var showExplanation = true
    @Environment(\.dismiss) var dismiss
    
    var demonstration: FormatDemonstration {
        FormatDemonstration.getDemonstration(for: format)
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.98, blue: 0.95),
                    Color(red: 0.90, green: 0.95, blue: 0.90)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DemoHeader(format: format, onDismiss: { dismiss() })
                
                // Main demonstration area
                GeometryReader { geometry in
                    VStack(spacing: 20) {
                        // Visual demonstration
                        DemoVisualization(
                            demonstration: demonstration,
                            currentStep: currentStep,
                            isAnimating: isAnimating,
                            size: geometry.size
                        )
                        .frame(height: geometry.size.height * 0.6)
                        
                        // Step explanation
                        if showExplanation {
                            StepExplanation(
                                step: demonstration.steps[min(currentStep, demonstration.steps.count - 1)],
                                stepNumber: currentStep + 1,
                                totalSteps: demonstration.steps.count
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                        
                        Spacer()
                        
                        // Controls
                        DemoControls(
                            currentStep: $currentStep,
                            isAnimating: $isAnimating,
                            totalSteps: demonstration.steps.count,
                            format: format
                        )
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Demo Header

struct DemoHeader: View {
    let format: GolfFormat
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            // Format info
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(format.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: format.icon)
                        .font(.system(size: 20))
                        .foregroundColor(format.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(format.tagline)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding()
        .background(
            Color.white.opacity(0.95)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

// MARK: - Demo Visualization

struct DemoVisualization: View {
    let demonstration: FormatDemonstration
    let currentStep: Int
    let isAnimating: Bool
    let size: CGSize
    
    var currentStepData: DemoStep {
        demonstration.steps[min(currentStep, demonstration.steps.count - 1)]
    }
    
    var body: some View {
        ZStack {
            // Golf course view
            GolfCourseVisualization(size: size)
            
            // Player positions and actions
            ForEach(currentStepData.playerStates.indices, id: \.self) { index in
                PlayerVisualization(
                    state: currentStepData.playerStates[index],
                    playerNumber: index + 1,
                    isAnimating: isAnimating,
                    courseSize: size
                )
            }
            
            // Ball positions
            ForEach(Array(currentStepData.ballPositions.enumerated()), id: \.offset) { index, position in
                BallVisualization(
                    position: position,
                    playerNumber: position.playerNumber,
                    isAnimating: isAnimating,
                    courseSize: size
                )
            }
            
            // Visual indicators (arrows, highlights, etc.)
            ForEach(currentStepData.visualIndicators, id: \.id) { indicator in
                VisualIndicator(
                    indicator: indicator,
                    isAnimating: isAnimating,
                    courseSize: size
                )
            }
            
            // Score display if needed
            if let scores = currentStepData.scores {
                ScoreDisplay(scores: scores)
                    .position(x: size.width - 80, y: 40)
            }
        }
        .frame(width: size.width, height: size.height * 0.6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

// MARK: - Golf Course Visualization

struct GolfCourseVisualization: View {
    let size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Draw fairway
            let fairwayPath = Path { path in
                path.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.9))
                path.addQuadCurve(
                    to: CGPoint(x: size.width * 0.85, y: size.height * 0.2),
                    control: CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                )
                path.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.25))
                path.addQuadCurve(
                    to: CGPoint(x: size.width * 0.2, y: size.height * 0.95),
                    control: CGPoint(x: size.width * 0.55, y: size.height * 0.6)
                )
                path.closeSubpath()
            }
            
            context.fill(
                fairwayPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.5, green: 0.7, blue: 0.3),
                        Color(red: 0.4, green: 0.6, blue: 0.25)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
            
            // Draw tee box
            let teeBox = Path(
                roundedRect: CGRect(
                    x: size.width * 0.12,
                    y: size.height * 0.85,
                    width: size.width * 0.12,
                    height: size.height * 0.08
                ),
                cornerRadius: 5
            )
            context.fill(teeBox, with: .color(Color(red: 0.3, green: 0.5, blue: 0.2)))
            
            // Draw green
            let green = Path(
                ellipseIn: CGRect(
                    x: size.width * 0.75,
                    y: size.height * 0.15,
                    width: size.width * 0.15,
                    height: size.height * 0.12
                )
            )
            context.fill(green, with: .color(Color(red: 0.3, green: 0.55, blue: 0.25)))
            
            // Draw hole
            let hole = Path(
                ellipseIn: CGRect(
                    x: size.width * 0.815,
                    y: size.height * 0.195,
                    width: size.width * 0.02,
                    height: size.height * 0.015
                )
            )
            context.fill(hole, with: .color(.black))
            
            // Draw flag
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.825, y: size.height * 0.20))
                    path.addLine(to: CGPoint(x: size.width * 0.825, y: size.height * 0.12))
                },
                with: .color(.white),
                lineWidth: 2
            )
            
            let flag = Path { path in
                path.move(to: CGPoint(x: size.width * 0.825, y: size.height * 0.12))
                path.addLine(to: CGPoint(x: size.width * 0.87, y: size.height * 0.14))
                path.addLine(to: CGPoint(x: size.width * 0.825, y: size.height * 0.16))
                path.closeSubpath()
            }
            context.fill(flag, with: .color(.red))
            
            // Draw bunkers
            let bunker1 = Path(
                ellipseIn: CGRect(
                    x: size.width * 0.65,
                    y: size.height * 0.25,
                    width: size.width * 0.08,
                    height: size.height * 0.05
                )
            )
            context.fill(bunker1, with: .color(Color(red: 0.9, green: 0.8, blue: 0.6)))
            
            let bunker2 = Path(
                ellipseIn: CGRect(
                    x: size.width * 0.4,
                    y: size.height * 0.5,
                    width: size.width * 0.07,
                    height: size.height * 0.04
                )
            )
            context.fill(bunker2, with: .color(Color(red: 0.9, green: 0.8, blue: 0.6)))
        }
    }
}

// MARK: - Player Visualization

struct PlayerVisualization: View {
    let state: PlayerState
    let playerNumber: Int
    let isAnimating: Bool
    let courseSize: CGSize
    
    let playerColors = [Color.blue, Color.green, Color.orange, Color.purple]
    
    var position: CGPoint {
        CGPoint(
            x: courseSize.width * state.position.x,
            y: courseSize.height * state.position.y
        )
    }
    
    var body: some View {
        ZStack {
            // Player figure
            PlayerFigure(
                action: state.action,
                color: playerColors[min(playerNumber - 1, 3)],
                isActive: state.isActive,
                hasClub: state.action == .teeing || state.action == .swinging || state.action == .putting
            )
            .frame(width: 40, height: 50)
            
            // Player number badge
            Text("\(playerNumber)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(playerColors[min(playerNumber - 1, 3)])
                .clipShape(Circle())
                .offset(x: -12, y: -20)
            
            // Action indicator
            if state.isActive {
                Circle()
                    .stroke(playerColors[min(playerNumber - 1, 3)], lineWidth: 2)
                    .frame(width: 50, height: 50)
                    .scaleEffect(isAnimating ? 1.2 : 1)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
        }
        .position(position)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: position)
    }
}

// MARK: - Player Figure

struct PlayerFigure: View {
    let action: PlayerAction
    let color: Color
    let isActive: Bool
    let hasClub: Bool
    
    var body: some View {
        ZStack {
            // Simple stylized figure
            VStack(spacing: 0) {
                // Head
                Circle()
                    .fill(isActive ? color : Color.gray.opacity(0.5))
                    .frame(width: 12, height: 12)
                
                // Body with arms
                ZStack {
                    // Body
                    Rectangle()
                        .fill(isActive ? color : Color.gray.opacity(0.5))
                        .frame(width: 3, height: 18)
                    
                    // Arms based on action
                    if action == .swinging || action == .teeing {
                        // Arms up in swing
                        Rectangle()
                            .fill(isActive ? color : Color.gray.opacity(0.5))
                            .frame(width: 20, height: 2)
                            .rotationEffect(.degrees(-30))
                            .offset(y: -5)
                    } else if action == .putting {
                        // Arms down for putting
                        Rectangle()
                            .fill(isActive ? color : Color.gray.opacity(0.5))
                            .frame(width: 16, height: 2)
                            .offset(y: 5)
                    } else if action == .celebrating {
                        // Arms up celebrating
                        Rectangle()
                            .fill(isActive ? color : Color.gray.opacity(0.5))
                            .frame(width: 20, height: 2)
                            .rotationEffect(.degrees(-60))
                            .offset(y: -5)
                    }
                    
                    // Club if needed
                    if hasClub {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 1, height: 25)
                            .rotationEffect(.degrees(action == .putting ? 0 : -20))
                            .offset(x: action == .putting ? 0 : 8, y: action == .putting ? 10 : 0)
                    }
                }
                
                // Legs
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(isActive ? color : Color.gray.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .rotationEffect(.degrees(-10))
                    Rectangle()
                        .fill(isActive ? color : Color.gray.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .rotationEffect(.degrees(10))
                }
            }
        }
    }
}

// MARK: - Ball Visualization

struct BallVisualization: View {
    let position: BallPosition
    let playerNumber: Int
    let isAnimating: Bool
    let courseSize: CGSize
    
    let playerColors = [Color.blue, Color.green, Color.orange, Color.purple]
    
    var ballPosition: CGPoint {
        CGPoint(
            x: courseSize.width * position.x,
            y: courseSize.height * position.y
        )
    }
    
    var body: some View {
        ZStack {
            // Ball
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(playerNumber > 0 ? playerColors[min(playerNumber - 1, 3)] : Color.gray, lineWidth: 2)
                )
            
            // Trajectory line if moving
            if position.showTrajectory {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: -30, y: 10))
                }
                .stroke(
                    playerNumber > 0 ? playerColors[min(playerNumber - 1, 3)].opacity(0.5) : Color.gray.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                )
            }
        }
        .position(ballPosition)
        .scaleEffect(isAnimating && position.isHighlighted ? 1.3 : 1)
        .animation(.spring(response: 0.3), value: isAnimating)
    }
}

// MARK: - Visual Indicator

struct VisualIndicator: View {
    let indicator: Indicator
    let isAnimating: Bool
    let courseSize: CGSize
    
    var position: CGPoint {
        CGPoint(
            x: courseSize.width * indicator.position.x,
            y: courseSize.height * indicator.position.y
        )
    }
    
    var body: some View {
        Group {
            switch indicator.type {
            case .arrow:
                ArrowIndicator(
                    direction: indicator.direction ?? .right,
                    color: indicator.color,
                    size: indicator.size
                )
                
            case .highlight:
                Circle()
                    .stroke(indicator.color, lineWidth: 3)
                    .frame(width: indicator.size, height: indicator.size)
                    .scaleEffect(isAnimating ? 1.2 : 1)
                    .opacity(isAnimating ? 0.5 : 1)
                    
            case .text:
                Text(indicator.text ?? "")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(indicator.color)
                    .padding(6)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    
            case .line:
                Path { path in
                    path.move(to: CGPoint.zero)
                    if let endPosition = indicator.endPosition {
                        path.addLine(to: CGPoint(
                            x: (endPosition.x - indicator.position.x) * courseSize.width,
                            y: (endPosition.y - indicator.position.y) * courseSize.height
                        ))
                    }
                }
                .stroke(indicator.color, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
            }
        }
        .position(position)
        .animation(.easeInOut(duration: 0.5), value: isAnimating)
    }
}

struct ArrowIndicator: View {
    let direction: Direction
    let color: Color
    let size: CGFloat
    
    var rotation: Double {
        switch direction {
        case .up: return -90
        case .down: return 90
        case .left: return 180
        case .right: return 0
        }
    }
    
    var body: some View {
        Image(systemName: "arrow.right.circle.fill")
            .font(.system(size: size))
            .foregroundColor(color)
            .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Score Display

struct ScoreDisplay: View {
    let scores: [PlayerScore]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ForEach(scores, id: \.playerNumber) { score in
                HStack(spacing: 4) {
                    Text("P\(score.playerNumber):")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(score.score)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(scoreColor(score.score))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.9))
                .cornerRadius(6)
            }
        }
    }
    
    func scoreColor(_ score: Int) -> Color {
        switch score {
        case ...3: return .green
        case 4: return .blue
        case 5: return .orange
        default: return .red
        }
    }
}

// MARK: - Step Explanation

struct StepExplanation: View {
    let step: DemoStep
    let stepNumber: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Step header
            HStack {
                Text("Step \(stepNumber) of \(totalSteps)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Progress dots
                HStack(spacing: 4) {
                    ForEach(1...totalSteps, id: \.self) { num in
                        Circle()
                            .fill(num <= stepNumber ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            // Main explanation
            Text(step.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(step.explanation)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Key points if any
            if !step.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(step.keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                                .offset(y: 2)
                            Text(point)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

// MARK: - Demo Controls

struct DemoControls: View {
    @Binding var currentStep: Int
    @Binding var isAnimating: Bool
    let totalSteps: Int
    let format: GolfFormat
    
    var body: some View {
        HStack(spacing: 20) {
            // Previous
            Button(action: {
                if currentStep > 0 {
                    currentStep -= 1
                    triggerAnimation()
                }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(currentStep > 0 ? format.color : Color.gray.opacity(0.3))
            }
            .disabled(currentStep == 0)
            
            // Play/Pause
            Button(action: {
                if currentStep < totalSteps - 1 {
                    autoPlay()
                } else {
                    currentStep = 0
                    autoPlay()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(format.color)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: currentStep < totalSteps - 1 ? "play.fill" : "arrow.clockwise")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            // Next
            Button(action: {
                if currentStep < totalSteps - 1 {
                    currentStep += 1
                    triggerAnimation()
                }
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(currentStep < totalSteps - 1 ? format.color : Color.gray.opacity(0.3))
            }
            .disabled(currentStep >= totalSteps - 1)
            
            Spacer()
            
            // Quick tips
            Button(action: {}) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    func autoPlay() {
        guard currentStep < totalSteps - 1 else { return }
        
        triggerAnimation()
        currentStep += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if currentStep < totalSteps - 1 {
                autoPlay()
            }
        }
    }
    
    func triggerAnimation() {
        withAnimation(.spring()) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                isAnimating = false
            }
        }
    }
}

// MARK: - Data Models

struct FormatDemonstration {
    let format: GolfFormat
    let steps: [DemoStep]
    
    static func getDemonstration(for format: GolfFormat) -> FormatDemonstration {
        switch format.name {
        case "Scramble":
            return scrambleDemonstration(format)
        case "Best Ball":
            return bestBallDemonstration(format)
        case "Alternate Shot":
            return alternateShotDemonstration(format)
        case "Match Play":
            return matchPlayDemonstration(format)
        case "Skins":
            return skinsDemonstration(format)
        case "Stableford":
            return stablefordDemonstration(format)
        default:
            return genericDemonstration(format)
        }
    }
    
    static func scrambleDemonstration(_ format: GolfFormat) -> FormatDemonstration {
        FormatDemonstration(
            format: format,
            steps: [
                DemoStep(
                    title: "Everyone Tees Off",
                    explanation: "All 4 team members hit their tee shots from the tee box.",
                    keyPoints: ["Each player uses their own ball", "All shots count as attempts"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.15, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.88), action: .teeing, isActive: true)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.4, y: 0.6, playerNumber: 1),
                        BallPosition(x: 0.45, y: 0.55, playerNumber: 2),
                        BallPosition(x: 0.5, y: 0.5, playerNumber: 3, isHighlighted: true),
                        BallPosition(x: 0.42, y: 0.62, playerNumber: 4)
                    ],
                    visualIndicators: [
                        Indicator(type: .arrow, position: CGPoint(x: 0.18, y: 0.75), direction: .up, color: .blue, size: 20)
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Select Best Shot",
                    explanation: "The team chooses the best positioned ball (Player 3's in this case).",
                    keyPoints: ["Consider distance and lie", "Team decision"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.48, y: 0.52), action: .walking, isActive: false),
                        PlayerState(position: CGPoint(x: 0.49, y: 0.51), action: .walking, isActive: false),
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .pointing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.51, y: 0.51), action: .walking, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.5, y: 0.5, playerNumber: 3, isHighlighted: true)
                    ],
                    visualIndicators: [
                        Indicator(type: .highlight, position: CGPoint(x: 0.5, y: 0.5), color: .green, size: 40),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.45), color: .green, text: "BEST")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "All Play From Best Ball",
                    explanation: "Everyone picks up their ball and plays from the selected position.",
                    keyPoints: ["All hit from same spot", "Order can be strategic"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .swinging, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.52), action: .waiting, isActive: false),
                        PlayerState(position: CGPoint(x: 0.48, y: 0.52), action: .waiting, isActive: false),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.48), action: .waiting, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.75, y: 0.25, playerNumber: 1, showTrajectory: true),
                        BallPosition(x: 0.78, y: 0.23, playerNumber: 2),
                        BallPosition(x: 0.8, y: 0.22, playerNumber: 3),
                        BallPosition(x: 0.77, y: 0.26, playerNumber: 4)
                    ],
                    visualIndicators: [],
                    scores: nil
                ),
                DemoStep(
                    title: "Continue Until Holed",
                    explanation: "Repeat the process: select best ball, all play from there, until someone holes out.",
                    keyPoints: ["One team score per hole", "Typically lower scores than individual play"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.8, y: 0.22), action: .putting, isActive: true),
                        PlayerState(position: CGPoint(x: 0.82, y: 0.24), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.78, y: 0.24), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.8, y: 0.26), action: .watching, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.825, y: 0.20, playerNumber: 0, isHighlighted: true)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.825, y: 0.15), color: .green, text: "TEAM: 4")
                    ],
                    scores: [PlayerScore(playerNumber: 0, score: 4)]
                )
            ]
        )
    }
    
    static func bestBallDemonstration(_ format: GolfFormat) -> FormatDemonstration {
        FormatDemonstration(
            format: format,
            steps: [
                DemoStep(
                    title: "Everyone Plays Own Ball",
                    explanation: "Each player plays their own ball for the entire hole.",
                    keyPoints: ["Individual play", "No sharing balls"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.15, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.88), action: .teeing, isActive: true)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.4, y: 0.6, playerNumber: 1),
                        BallPosition(x: 0.45, y: 0.55, playerNumber: 2),
                        BallPosition(x: 0.38, y: 0.65, playerNumber: 3),
                        BallPosition(x: 0.5, y: 0.5, playerNumber: 4)
                    ],
                    visualIndicators: [],
                    scores: nil
                ),
                DemoStep(
                    title: "Continue Individual Play",
                    explanation: "Each player continues playing their own ball to the green.",
                    keyPoints: ["Track each score", "No interference between players"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.4, y: 0.6), action: .swinging, isActive: true),
                        PlayerState(position: CGPoint(x: 0.45, y: 0.55), action: .swinging, isActive: true),
                        PlayerState(position: CGPoint(x: 0.38, y: 0.65), action: .swinging, isActive: true),
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .swinging, isActive: true)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.75, y: 0.25, playerNumber: 1),
                        BallPosition(x: 0.8, y: 0.22, playerNumber: 2),
                        BallPosition(x: 0.73, y: 0.28, playerNumber: 3),
                        BallPosition(x: 0.82, y: 0.21, playerNumber: 4)
                    ],
                    visualIndicators: [],
                    scores: nil
                ),
                DemoStep(
                    title: "Record Individual Scores",
                    explanation: "Each player completes the hole with their own score.",
                    keyPoints: ["P1: 4, P2: 5, P3: 6, P4: 4"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.82, y: 0.21), action: .celebrating, isActive: true),
                        PlayerState(position: CGPoint(x: 0.8, y: 0.23), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.78, y: 0.25), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.84, y: 0.23), action: .celebrating, isActive: true)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.5), color: .blue, text: "Individual Scores")
                    ],
                    scores: [
                        PlayerScore(playerNumber: 1, score: 4),
                        PlayerScore(playerNumber: 2, score: 5),
                        PlayerScore(playerNumber: 3, score: 6),
                        PlayerScore(playerNumber: 4, score: 4)
                    ]
                ),
                DemoStep(
                    title: "Team Takes Best Score",
                    explanation: "The team score is the lowest individual score (4 in this case).",
                    keyPoints: ["Best of 4 scores", "Team benefits from best player"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .celebrating, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.5), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.48, y: 0.5), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.5, y: 0.52), action: .celebrating, isActive: true)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.4), color: .green, size: 50, text: "TEAM SCORE: 4")
                    ],
                    scores: [PlayerScore(playerNumber: 0, score: 4)]
                )
            ]
        )
    }
    
    static func alternateShotDemonstration(_ format: GolfFormat) -> FormatDemonstration {
        FormatDemonstration(
            format: format,
            steps: [
                DemoStep(
                    title: "Player A Tees Off (Odd Hole)",
                    explanation: "On odd numbered holes, Player A hits the tee shot.",
                    keyPoints: ["Partners alternate tee duty", "Player B tees on even holes"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.15, y: 0.85), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.85), action: .standing, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.45, y: 0.55, playerNumber: 1, showTrajectory: true)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.18, y: 0.8), color: .blue, text: "A")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Player B Hits Second Shot",
                    explanation: "Partner B must play the ball wherever A's shot landed.",
                    keyPoints: ["No improving lie", "True alternation"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.43, y: 0.57), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.45, y: 0.55), action: .swinging, isActive: true),
                        PlayerState(position: CGPoint(x: 0.4, y: 0.5), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .standing, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.7, y: 0.3, playerNumber: 2, showTrajectory: true)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.45, y: 0.48), color: .green, text: "B"),
                        Indicator(type: .line, position: CGPoint(x: 0.45, y: 0.55), color: .gray, endPosition: CGPoint(x: 0.7, y: 0.3))
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Continue Alternating",
                    explanation: "Players continue alternating shots until the ball is holed.",
                    keyPoints: ["Includes putts", "One ball per team"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.7, y: 0.3), action: .swinging, isActive: true),
                        PlayerState(position: CGPoint(x: 0.72, y: 0.32), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.65, y: 0.35), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.75, y: 0.35), action: .standing, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.82, y: 0.21, playerNumber: 1)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.7, y: 0.25), color: .blue, text: "A")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Partner Completes Hole",
                    explanation: "The alternation continues through putting until holed.",
                    keyPoints: ["Team score recorded", "Challenging format"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.8, y: 0.23), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.82, y: 0.21), action: .putting, isActive: true),
                        PlayerState(position: CGPoint(x: 0.78, y: 0.25), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.84, y: 0.25), action: .standing, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.825, y: 0.20, playerNumber: 0, isHighlighted: true)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.82, y: 0.15), color: .green, text: "B HOLES OUT"),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.1), color: .blue, text: "TEAM: 5")
                    ],
                    scores: [PlayerScore(playerNumber: 0, score: 5)]
                )
            ]
        )
    }
    
    static func matchPlayDemonstration(_ format: GolfFormat) -> FormatDemonstration {
        FormatDemonstration(
            format: format,
            steps: [
                DemoStep(
                    title: "Hole-by-Hole Competition",
                    explanation: "Players compete to win individual holes, not total strokes.",
                    keyPoints: ["Win hole with lower score", "Ties are 'halved'"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.15, y: 0.85), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.85), action: .standing, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.45, y: 0.55, playerNumber: 1),
                        BallPosition(x: 0.5, y: 0.5, playerNumber: 2)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.8), color: .blue, text: "HOLE 1")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Complete the Hole",
                    explanation: "Both players finish the hole with their scores.",
                    keyPoints: ["Player 1 scores 4", "Player 2 scores 5"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.82, y: 0.21), action: .celebrating, isActive: true),
                        PlayerState(position: CGPoint(x: 0.8, y: 0.23), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.78, y: 0.19), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.84, y: 0.19), action: .standing, isActive: false)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.4, y: 0.5), color: .green, text: "P1: 4"),
                        Indicator(type: .text, position: CGPoint(x: 0.6, y: 0.5), color: .red, text: "P2: 5")
                    ],
                    scores: [
                        PlayerScore(playerNumber: 1, score: 4),
                        PlayerScore(playerNumber: 2, score: 5)
                    ]
                ),
                DemoStep(
                    title: "Player 1 Wins Hole",
                    explanation: "Player 1 wins the hole with the lower score and goes '1 UP'.",
                    keyPoints: ["Match score: 1 UP", "Not stroke difference"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .celebrating, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.52), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.48, y: 0.48), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.54, y: 0.48), action: .standing, isActive: false)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.3), color: .green, size: 60, text: "P1 WINS HOLE"),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.4), color: .blue, text: "MATCH: 1 UP")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Continue Match",
                    explanation: "The match continues hole by hole until one player can't be caught.",
                    keyPoints: ["Can end before 18", "Example: 3&2 = Won by 3 with 2 to play"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .walking, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .walking, isActive: true),
                        PlayerState(position: CGPoint(x: 0.15, y: 0.85), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.85), action: .standing, isActive: false)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.5), color: .blue, text: "NEXT HOLE"),
                        Indicator(type: .arrow, position: CGPoint(x: 0.3, y: 0.7), direction: .right, color: .gray, size: 30)
                    ],
                    scores: nil
                )
            ]
        )
    }
    
    static func skinsDemonstration(_ format: GolfFormat) -> FormatDemonstration {
        FormatDemonstration(
            format: format,
            steps: [
                DemoStep(
                    title: "Compete for the 'Skin'",
                    explanation: "Each hole has a value (skin) that goes to the outright winner.",
                    keyPoints: ["Must win hole alone", "No ties"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.15, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .teeing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.88), action: .teeing, isActive: true)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.4, y: 0.6, playerNumber: 1),
                        BallPosition(x: 0.45, y: 0.55, playerNumber: 2),
                        BallPosition(x: 0.43, y: 0.58, playerNumber: 3),
                        BallPosition(x: 0.5, y: 0.5, playerNumber: 4)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.8), color: .yellow, text: "$10 SKIN")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Players Score",
                    explanation: "All players complete the hole with their scores.",
                    keyPoints: ["P1: 4, P2: 5, P3: 4, P4: 6"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.8, y: 0.22), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.82, y: 0.24), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.78, y: 0.24), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.84, y: 0.24), action: .standing, isActive: false)
                    ],
                    ballPositions: [],
                    visualIndicators: [],
                    scores: [
                        PlayerScore(playerNumber: 1, score: 4),
                        PlayerScore(playerNumber: 2, score: 5),
                        PlayerScore(playerNumber: 3, score: 4),
                        PlayerScore(playerNumber: 4, score: 6)
                    ]
                ),
                DemoStep(
                    title: "Tie! Skin Carries Over",
                    explanation: "P1 and P3 both scored 4 - the skin carries to the next hole.",
                    keyPoints: ["No winner this hole", "Next hole worth $20"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.52), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.48, y: 0.52), action: .standing, isActive: false),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.48), action: .standing, isActive: false)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.3), color: .orange, size: 60, text: "TIE!"),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.4), color: .gray, text: "CARRIES TO NEXT"),
                        Indicator(type: .arrow, position: CGPoint(x: 0.5, y: 0.6), direction: .right, color: .yellow, size: 40)
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Next Hole Worth More",
                    explanation: "The carried over skin adds to the next hole's value.",
                    keyPoints: ["Pressure builds", "Big payoffs possible"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.15, y: 0.88), action: .walking, isActive: true),
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .walking, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .walking, isActive: true),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.88), action: .walking, isActive: true)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.5), color: .yellow, size: 50, text: "$20 SKIN!"),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.6), color: .blue, text: "HOLE 2")
                    ],
                    scores: nil
                )
            ]
        )
    }
    
    static func stablefordDemonstration(_ format: GolfFormat) -> FormatDemonstration {
        FormatDemonstration(
            format: format,
            steps: [
                DemoStep(
                    title: "Point-Based Scoring",
                    explanation: "Earn points based on your score relative to par.",
                    keyPoints: ["Higher points = better", "No penalty for bad holes"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.52), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.48, y: 0.52), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.48), action: .standing, isActive: true)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.2, y: 0.3), color: .green, text: "Eagle: 4pts"),
                        Indicator(type: .text, position: CGPoint(x: 0.2, y: 0.4), color: .green, text: "Birdie: 3pts"),
                        Indicator(type: .text, position: CGPoint(x: 0.2, y: 0.5), color: .blue, text: "Par: 2pts"),
                        Indicator(type: .text, position: CGPoint(x: 0.2, y: 0.6), color: .orange, text: "Bogey: 1pt"),
                        Indicator(type: .text, position: CGPoint(x: 0.2, y: 0.7), color: .red, text: "Double+: 0pts")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Play for Points",
                    explanation: "Players complete holes trying to maximize points.",
                    keyPoints: ["Par 4 hole example"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.8, y: 0.22), action: .putting, isActive: true),
                        PlayerState(position: CGPoint(x: 0.82, y: 0.24), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.78, y: 0.24), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.84, y: 0.24), action: .standing, isActive: true)
                    ],
                    ballPositions: [],
                    visualIndicators: [],
                    scores: [
                        PlayerScore(playerNumber: 1, score: 3),
                        PlayerScore(playerNumber: 2, score: 4),
                        PlayerScore(playerNumber: 3, score: 5),
                        PlayerScore(playerNumber: 4, score: 7)
                    ]
                ),
                DemoStep(
                    title: "Convert to Points",
                    explanation: "Scores are converted to points based on the system.",
                    keyPoints: ["P1 birdie = 3pts", "P2 par = 2pts", "P3 bogey = 1pt", "P4 triple = 0pts"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.45, y: 0.5), action: .celebrating, isActive: true),
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.55, y: 0.5), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.5, y: 0.55), action: .standing, isActive: false)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.3, y: 0.3), color: .green, text: "P1: 3 POINTS"),
                        Indicator(type: .text, position: CGPoint(x: 0.7, y: 0.3), color: .blue, text: "P2: 2 POINTS"),
                        Indicator(type: .text, position: CGPoint(x: 0.3, y: 0.7), color: .orange, text: "P3: 1 POINT"),
                        Indicator(type: .text, position: CGPoint(x: 0.7, y: 0.7), color: .red, text: "P4: 0 POINTS")
                    ],
                    scores: nil
                ),
                DemoStep(
                    title: "Accumulate Points",
                    explanation: "Points accumulate over 18 holes. Most points wins!",
                    keyPoints: ["Rewards aggressive play", "Bad holes don't ruin round"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.52), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.48, y: 0.52), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.48), action: .standing, isActive: true)
                    ],
                    ballPositions: [],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.3), color: .blue, size: 40, text: "TOTAL AFTER 9"),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.45), color: .green, text: "P1: 24 pts"),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.55), color: .blue, text: "P2: 18 pts"),
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.65), color: .orange, text: "P3: 15 pts")
                    ],
                    scores: nil
                )
            ]
        )
    }
    
    static func genericDemonstration(_ format: GolfFormat) -> FormatDemonstration {
        FormatDemonstration(
            format: format,
            steps: [
                DemoStep(
                    title: "Format Setup",
                    explanation: format.description,
                    keyPoints: format.rules.prefix(3).map { String($0) },
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.15, y: 0.88), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.18, y: 0.88), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.21, y: 0.88), action: .standing, isActive: true),
                        PlayerState(position: CGPoint(x: 0.24, y: 0.88), action: .standing, isActive: true)
                    ],
                    ballPositions: [],
                    visualIndicators: [],
                    scores: nil
                ),
                DemoStep(
                    title: "Gameplay",
                    explanation: "Follow the format-specific rules throughout the round.",
                    keyPoints: Array(format.strategy.prefix(2)),
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.5, y: 0.5), action: .swinging, isActive: true),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.52), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.48, y: 0.52), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.52, y: 0.48), action: .watching, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.7, y: 0.3, playerNumber: 1, showTrajectory: true)
                    ],
                    visualIndicators: [],
                    scores: nil
                ),
                DemoStep(
                    title: "Scoring",
                    explanation: "Track scores according to the format rules.",
                    keyPoints: ["See full rules for details"],
                    playerStates: [
                        PlayerState(position: CGPoint(x: 0.82, y: 0.21), action: .putting, isActive: true),
                        PlayerState(position: CGPoint(x: 0.8, y: 0.23), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.78, y: 0.23), action: .watching, isActive: false),
                        PlayerState(position: CGPoint(x: 0.84, y: 0.23), action: .watching, isActive: false)
                    ],
                    ballPositions: [
                        BallPosition(x: 0.825, y: 0.20, playerNumber: 0, isHighlighted: true)
                    ],
                    visualIndicators: [
                        Indicator(type: .text, position: CGPoint(x: 0.5, y: 0.5), color: format.color, text: format.tagline)
                    ],
                    scores: nil
                )
            ]
        )
    }
}

// MARK: - Supporting Data Types

struct DemoStep {
    let title: String
    let explanation: String
    let keyPoints: [String]
    let playerStates: [PlayerState]
    let ballPositions: [BallPosition]
    let visualIndicators: [Indicator]
    let scores: [PlayerScore]?
}

struct PlayerState {
    let position: CGPoint  // Normalized 0-1
    let action: PlayerAction
    let isActive: Bool
}

enum PlayerAction {
    case standing, walking, teeing, swinging, putting
    case watching, celebrating, pointing, waiting
}

struct BallPosition {
    let x: Double  // Normalized 0-1
    let y: Double  // Normalized 0-1
    let playerNumber: Int  // 0 for neutral
    var isHighlighted: Bool = false
    var showTrajectory: Bool = false
}

struct Indicator {
    let id = UUID()
    let type: IndicatorType
    let position: CGPoint  // Normalized 0-1
    var direction: Direction?
    var color: Color
    var size: CGFloat = 30
    var text: String?
    var endPosition: CGPoint?
}

enum IndicatorType {
    case arrow, highlight, text, line
}

enum Direction {
    case up, down, left, right
}

struct PlayerScore {
    let playerNumber: Int  // 0 for team score
    let score: Int
}