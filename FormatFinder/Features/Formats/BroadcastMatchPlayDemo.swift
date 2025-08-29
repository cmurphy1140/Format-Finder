import SwiftUI
import CoreGraphics
import Combine

// MARK: - ESPN/Masters Style Match Play Demonstration
struct BroadcastMatchPlayDemo: View {
    @StateObject private var viewModel = MatchPlayDemoViewModel()
    @State private var showIntro = true
    @State private var currentHole = 1
    
    var body: some View {
        ZStack {
            // Broadcast-style background
            BroadcastBackground()
            
            if showIntro {
                MatchPlayIntroAnimation(showIntro: $showIntro)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                VStack(spacing: 0) {
                    // ESPN-style header
                    BroadcastHeader(viewModel: viewModel)
                    
                    // Main broadcast view
                    GeometryReader { geometry in
                        ZStack {
                            // Golf course visualization
                            CourseVisualization(
                                hole: viewModel.currentHole,
                                geometry: geometry
                            )
                            
                            // Player positions and ball flights
                            PlayerTrackingOverlay(
                                viewModel: viewModel,
                                geometry: geometry
                            )
                            
                            // Live scoring overlay
                            VStack {
                                Spacer()
                                LiveScoringOverlay(viewModel: viewModel)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                    
                    // Control panel
                    BroadcastControlPanel(viewModel: viewModel)
                        .frame(height: 100)
                }
            }
        }
        .onAppear {
            viewModel.startDemo()
        }
    }
}

// MARK: - Broadcast Background
struct BroadcastBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Masters-inspired gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.3, blue: 0.15),
                    Color(red: 0.0, green: 0.2, blue: 0.1),
                    Color.black
                ],
                startPoint: animateGradient ? .topLeading : .topTrailing,
                endPoint: animateGradient ? .bottomTrailing : .bottomLeading
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Subtle pattern overlay
            GeometryReader { geo in
                ForEach(0..<5) { row in
                    ForEach(0..<8) { col in
                        Circle()
                            .fill(Color.white.opacity(0.02))
                            .frame(width: 100, height: 100)
                            .position(
                                x: CGFloat(col) * 150 + 75,
                                y: CGFloat(row) * 200 + 100
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Match Play Intro Animation
struct MatchPlayIntroAnimation: View {
    @Binding var showIntro: Bool
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var textOffset: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // ESPN-style logo animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.6),
                                    Color.green.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 20)
                    
                    // Main icon
                    Image(systemName: "person.2.square.stack")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.green.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // Title text with broadcast styling
                VStack(spacing: 10) {
                    Text("MATCH PLAY")
                        .font(.system(size: 48, weight: .heavy, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.gray],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black, radius: 10, x: 0, y: 5)
                    
                    Text("HEAD TO HEAD COMPETITION")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.green.opacity(0.9))
                        .tracking(3)
                }
                .offset(y: textOffset)
                .opacity(opacity)
                
                // Start button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showIntro = false
                    }
                }) {
                    HStack {
                        Text("BEGIN DEMONSTRATION")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "play.fill")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.green.opacity(0.5), radius: 20, x: 0, y: 10)
                }
                .scaleEffect(scale)
                .opacity(opacity > 0.5 ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                scale = 1
                opacity = 1
                textOffset = 0
            }
        }
    }
}

// MARK: - Broadcast Header
struct BroadcastHeader: View {
    @ObservedObject var viewModel: MatchPlayDemoViewModel
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [Color.black, Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            HStack {
                // Tournament branding
                VStack(alignment: .leading, spacing: 4) {
                    Text("FORMAT FINDER")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.green)
                        .tracking(1)
                    
                    Text("MATCH PLAY")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Current match status
                MatchStatusIndicator(viewModel: viewModel)
                
                Spacer()
                
                // Hole information
                VStack(alignment: .trailing, spacing: 4) {
                    Text("HOLE \(viewModel.currentHole.number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.currentHole.yards) YDS • PAR \(viewModel.currentHole.par)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .frame(height: 80)
    }
}

// MARK: - Match Status Indicator
struct MatchStatusIndicator: View {
    @ObservedObject var viewModel: MatchPlayDemoViewModel
    
    var statusText: String {
        if viewModel.matchStatus.holesUp == 0 {
            return "ALL SQUARE"
        } else {
            return "\(viewModel.matchStatus.leader) \(viewModel.matchStatus.holesUp) UP"
        }
    }
    
    var statusColor: Color {
        if viewModel.matchStatus.holesUp == 0 {
            return .yellow
        } else if viewModel.matchStatus.leader == "PLAYER 1" {
            return .blue
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(statusText)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(statusColor)
            
            if viewModel.matchStatus.holesRemaining < 18 {
                Text("\(viewModel.matchStatus.holesRemaining) TO PLAY")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Course Visualization
struct CourseVisualization: View {
    let hole: HoleData
    let geometry: GeometryProxy
    @State private var animateFlag = false
    
    var body: some View {
        ZStack {
            // Fairway
            FairwayShape(hole: hole)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.5, blue: 0.2),
                            Color(red: 0.15, green: 0.4, blue: 0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    FairwayShape(hole: hole)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
            
            // Hazards
            ForEach(hole.hazards) { hazard in
                HazardView(hazard: hazard, geometry: geometry)
            }
            
            // Green
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.1, green: 0.6, blue: 0.1),
                            Color(red: 0.15, green: 0.45, blue: 0.15)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .position(hole.greenPosition(in: geometry.size))
                .overlay(
                    // Flag
                    Image(systemName: "flag.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                        .position(hole.greenPosition(in: geometry.size))
                        .rotationEffect(.degrees(animateFlag ? 10 : -10))
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: animateFlag
                        )
                )
            
            // Tee box
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.brown.opacity(0.8))
                .frame(width: 60, height: 40)
                .position(hole.teePosition(in: geometry.size))
        }
        .onAppear {
            animateFlag = true
        }
    }
}

// MARK: - Player Tracking Overlay
struct PlayerTrackingOverlay: View {
    @ObservedObject var viewModel: MatchPlayDemoViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            ForEach(viewModel.players) { player in
                PlayerVisualization(
                    player: player,
                    currentShot: viewModel.currentShots[player.id],
                    geometry: geometry
                )
            }
            
            // Ball flight animations
            ForEach(viewModel.activeBallFlights) { flight in
                BallFlightAnimation(
                    flight: flight,
                    geometry: geometry
                )
            }
        }
    }
}

// MARK: - Ball Flight Animation
struct BallFlightAnimation: View {
    let flight: BallFlight
    let geometry: GeometryProxy
    @State private var progress: CGFloat = 0
    @State private var trailPoints: [CGPoint] = []
    
    var currentPosition: CGPoint {
        let start = flight.startPosition(in: geometry.size)
        let end = flight.endPosition(in: geometry.size)
        let control = flight.controlPoint(in: geometry.size)
        
        // Quadratic Bezier curve
        let t = progress
        let x = pow(1 - t, 2) * start.x + 2 * (1 - t) * t * control.x + pow(t, 2) * end.x
        let y = pow(1 - t, 2) * start.y + 2 * (1 - t) * t * control.y + pow(t, 2) * end.y
        
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        ZStack {
            // Ball trail
            Path { path in
                guard !trailPoints.isEmpty else { return }
                path.move(to: trailPoints[0])
                for point in trailPoints.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
            
            // Golf ball
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .position(currentPosition)
        }
        .onAppear {
            animateFlight()
        }
    }
    
    private func animateFlight() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            withAnimation(.linear(duration: 0.02)) {
                progress += 0.02
                
                // Add current position to trail
                if trailPoints.count > 20 {
                    trailPoints.removeFirst()
                }
                trailPoints.append(currentPosition)
                
                if progress >= 1.0 {
                    timer.invalidate()
                    // Clear trail after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            trailPoints.removeAll()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Live Scoring Overlay
struct LiveScoringOverlay: View {
    @ObservedObject var viewModel: MatchPlayDemoViewModel
    @State private var showScoreAnimation = false
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(viewModel.players) { player in
                PlayerScoreCard(
                    player: player,
                    currentScore: viewModel.currentScores[player.id] ?? 0,
                    isLeading: viewModel.isLeading(player: player)
                )
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
        .background(
            BlurView(style: .systemUltraThinMaterialDark)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Player Score Card
struct PlayerScoreCard: View {
    let player: MatchPlayer
    let currentScore: Int
    let isLeading: Bool
    @State private var animateScore = false
    
    var scoreColor: Color {
        if currentScore < 0 { return .green }
        else if currentScore > 0 { return .red }
        else { return .white }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Player avatar
            ZStack {
                Circle()
                    .fill(player.color)
                    .frame(width: 50, height: 50)
                
                Text(player.initials)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(isLeading ? Color.yellow : Color.clear, lineWidth: 3)
            )
            
            // Player name
            Text(player.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            // Score display
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 80, height: 36)
                
                HStack(spacing: 4) {
                    if currentScore != 0 {
                        Text(currentScore > 0 ? "+" : "")
                            .font(.system(size: 18, weight: .bold))
                        Text("\(abs(currentScore))")
                            .font(.system(size: 22, weight: .black))
                    } else {
                        Text("E")
                            .font(.system(size: 22, weight: .black))
                    }
                }
                .foregroundColor(scoreColor)
                .scaleEffect(animateScore ? 1.2 : 1.0)
            }
        }
        .onChange(of: currentScore) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateScore = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateScore = false
            }
        }
    }
}

// MARK: - Control Panel
struct BroadcastControlPanel: View {
    @ObservedObject var viewModel: MatchPlayDemoViewModel
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            
            HStack(spacing: 30) {
                // Play controls
                HStack(spacing: 20) {
                    Button(action: { viewModel.previousHole() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .disabled(viewModel.currentHole.number == 1)
                    
                    Button(action: { viewModel.togglePlayPause() }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                    
                    Button(action: { viewModel.nextHole() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .disabled(viewModel.currentHole.number == 18)
                }
                
                Divider()
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.3))
                
                // Speed control
                VStack(spacing: 4) {
                    Text("SPEED")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Picker("Speed", selection: $viewModel.playbackSpeed) {
                        Text("0.5x").tag(0.5)
                        Text("1x").tag(1.0)
                        Text("2x").tag(2.0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                }
                
                Divider()
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.3))
                
                // Shot info
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT SHOT")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(viewModel.currentShotDescription)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Supporting Views
struct FairwayShape: Shape {
    let hole: HoleData
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            // Create a curved fairway path
            let startPoint = hole.teePosition(in: rect.size)
            let endPoint = hole.greenPosition(in: rect.size)
            
            path.move(to: CGPoint(x: startPoint.x - 30, y: startPoint.y))
            
            // Create bezier curves for fairway edges
            let control1 = CGPoint(x: rect.width * 0.3, y: rect.height * 0.4)
            let control2 = CGPoint(x: rect.width * 0.7, y: rect.height * 0.6)
            
            path.addCurve(
                to: CGPoint(x: endPoint.x - 40, y: endPoint.y),
                control1: control1,
                control2: control2
            )
            
            path.addLine(to: CGPoint(x: endPoint.x + 40, y: endPoint.y))
            
            path.addCurve(
                to: CGPoint(x: startPoint.x + 30, y: startPoint.y),
                control1: CGPoint(x: control2.x + 60, y: control2.y),
                control2: CGPoint(x: control1.x + 60, y: control1.y)
            )
            
            path.closeSubpath()
        }
    }
}

struct HazardView: View {
    let hazard: Hazard
    let geometry: GeometryProxy
    
    var body: some View {
        Group {
            if hazard.type == .bunker {
                Ellipse()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: hazard.size.width, height: hazard.size.height)
                    .position(hazard.position(in: geometry.size))
            } else if hazard.type == .water {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: hazard.size.width, height: hazard.size.height)
                    .position(hazard.position(in: geometry.size))
            }
        }
    }
}

struct PlayerVisualization: View {
    let player: MatchPlayer
    let currentShot: ShotData?
    let geometry: GeometryProxy
    
    var body: some View {
        if let shot = currentShot {
            ZStack {
                // Player marker
                Circle()
                    .fill(player.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .position(shot.currentPosition(in: geometry.size))
                
                // Player label
                Text(player.initials)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .position(shot.currentPosition(in: geometry.size))
            }
        }
    }
}

// MARK: - Blur View for Glass Morphism
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - View Model
@MainActor
class MatchPlayDemoViewModel: ObservableObject {
    @Published var players: [MatchPlayer] = []
    @Published var currentHole: HoleData = HoleData.sampleHole(number: 1)
    @Published var matchStatus = MatchStatus()
    @Published var currentShots: [String: ShotData] = [:]
    @Published var currentScores: [String: Int] = [:]
    @Published var activeBallFlights: [BallFlight] = []
    @Published var isPlaying = false
    @Published var playbackSpeed: Double = 1.0
    @Published var currentShotDescription = "Tee Shot"
    
    private var animationTimer: Timer?
    
    init() {
        setupPlayers()
    }
    
    private func setupPlayers() {
        players = [
            MatchPlayer(id: "p1", name: "PLAYER 1", initials: "P1", color: .blue),
            MatchPlayer(id: "p2", name: "PLAYER 2", initials: "P2", color: .red)
        ]
        
        // Initialize scores
        players.forEach { player in
            currentScores[player.id] = 0
            currentShots[player.id] = ShotData(
                position: currentHole.teePosition(in: CGSize(width: 400, height: 600))
            )
        }
    }
    
    func startDemo() {
        isPlaying = true
        animateHole()
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            animateHole()
        } else {
            animationTimer?.invalidate()
        }
    }
    
    func nextHole() {
        guard currentHole.number < 18 else { return }
        currentHole = HoleData.sampleHole(number: currentHole.number + 1)
        resetHole()
        if isPlaying {
            animateHole()
        }
    }
    
    func previousHole() {
        guard currentHole.number > 1 else { return }
        currentHole = HoleData.sampleHole(number: currentHole.number - 1)
        resetHole()
        if isPlaying {
            animateHole()
        }
    }
    
    private func resetHole() {
        players.forEach { player in
            currentShots[player.id] = ShotData(
                position: currentHole.teePosition(in: CGSize(width: 400, height: 600))
            )
        }
        activeBallFlights.removeAll()
    }
    
    private func animateHole() {
        // Simulate shots for this hole
        var shotSequence: [(player: MatchPlayer, type: String, delay: Double)] = []
        
        // Tee shots
        shotSequence.append((players[0], "Tee Shot", 0))
        shotSequence.append((players[1], "Tee Shot", 2.0 / playbackSpeed))
        
        // Approach shots
        shotSequence.append((players[0], "Approach", 4.0 / playbackSpeed))
        shotSequence.append((players[1], "Approach", 6.0 / playbackSpeed))
        
        // Putts
        shotSequence.append((players[0], "Putt", 8.0 / playbackSpeed))
        shotSequence.append((players[1], "Putt", 10.0 / playbackSpeed))
        
        for shot in shotSequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + shot.delay) {
                self.simulateShot(for: shot.player, type: shot.type)
            }
        }
        
        // Update scores after all shots
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0 / playbackSpeed) {
            self.updateHoleResult()
        }
    }
    
    private func simulateShot(for player: MatchPlayer, type: String) {
        currentShotDescription = "\(player.name) - \(type)"
        
        // Create ball flight
        let flight = BallFlight(
            id: UUID().uuidString,
            playerId: player.id,
            shotType: type,
            startPosition: { size in
                self.currentShots[player.id]?.position ?? CGPoint(x: size.width / 2, y: size.height - 50)
            },
            endPosition: { size in
                switch type {
                case "Tee Shot":
                    return CGPoint(x: size.width / 2 + CGFloat.random(in: -50...50), y: size.height / 2)
                case "Approach":
                    return self.currentHole.greenPosition(in: size).applying(
                        CGAffineTransform(translationX: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20))
                    )
                case "Putt":
                    return self.currentHole.greenPosition(in: size)
                default:
                    return self.currentHole.greenPosition(in: size)
                }
            },
            controlPoint: { size in
                let start = self.currentShots[player.id]?.position ?? CGPoint(x: size.width / 2, y: size.height - 50)
                let end = self.currentHole.greenPosition(in: size)
                return CGPoint(
                    x: (start.x + end.x) / 2 + CGFloat.random(in: -30...30),
                    y: min(start.y, end.y) - 100
                )
            }
        )
        
        activeBallFlights.append(flight)
        
        // Remove flight after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.activeBallFlights.removeAll { $0.id == flight.id }
            
            // Update player position
            if let shot = self.currentShots[player.id] {
                self.currentShots[player.id] = ShotData(
                    position: flight.endPosition(in: CGSize(width: 400, height: 600))
                )
            }
        }
    }
    
    private func updateHoleResult() {
        // Simulate hole winner
        let winner = Int.random(in: 0...2)
        
        switch winner {
        case 0: // Player 1 wins
            matchStatus.holesUp += 1
            matchStatus.leader = "PLAYER 1"
            currentScores["p1"] = (currentScores["p1"] ?? 0) - 1
        case 1: // Player 2 wins
            if matchStatus.holesUp > 0 {
                matchStatus.holesUp -= 1
            } else {
                matchStatus.holesUp = 1
                matchStatus.leader = "PLAYER 2"
            }
            currentScores["p2"] = (currentScores["p2"] ?? 0) - 1
        default: // Halved
            break
        }
        
        matchStatus.holesRemaining = 18 - currentHole.number
    }
    
    func isLeading(player: MatchPlayer) -> Bool {
        if matchStatus.holesUp == 0 { return false }
        return (player.id == "p1" && matchStatus.leader == "PLAYER 1") ||
               (player.id == "p2" && matchStatus.leader == "PLAYER 2")
    }
}

// MARK: - Data Models
struct MatchPlayer: Identifiable {
    let id: String
    let name: String
    let initials: String
    let color: Color
}

struct MatchStatus {
    var holesUp: Int = 0
    var leader: String = ""
    var holesRemaining: Int = 18
}

struct HoleData {
    let number: Int
    let par: Int
    let yards: Int
    let hazards: [Hazard]
    
    func teePosition(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: size.height - 50)
    }
    
    func greenPosition(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: 100)
    }
    
    static func sampleHole(number: Int) -> HoleData {
        HoleData(
            number: number,
            par: [3, 4, 5].randomElement()!,
            yards: Int.random(in: 150...550),
            hazards: [
                Hazard(type: .bunker, size: CGSize(width: 60, height: 40)),
                Hazard(type: .water, size: CGSize(width: 100, height: 80))
            ]
        )
    }
}

struct Hazard: Identifiable {
    let id = UUID()
    let type: HazardType
    let size: CGSize
    
    enum HazardType {
        case bunker, water, trees
    }
    
    func position(in size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 100...(size.width - 100)),
            y: CGFloat.random(in: 200...(size.height - 200))
        )
    }
}

struct ShotData {
    let position: CGPoint
    
    func currentPosition(in size: CGSize) -> CGPoint {
        position
    }
}

struct BallFlight: Identifiable {
    let id: String
    let playerId: String
    let shotType: String
    let startPosition: (CGSize) -> CGPoint
    let endPosition: (CGSize) -> CGPoint
    let controlPoint: (CGSize) -> CGPoint
}