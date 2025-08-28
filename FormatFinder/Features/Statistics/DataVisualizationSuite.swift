import SwiftUI
import CoreGraphics

// MARK: - Data Visualization Suite

struct DataVisualizationSuite: View {
    @ObservedObject var gameState: GameState
    let configuration: GameConfiguration
    let players: [Player]
    
    @State private var selectedVisualization: VisualizationType = .scoreFlow
    @State private var selectedPlayer: Player?
    @State private var animateTransition = false
    @State private var showHeatMap = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Visualization Selector
            VisualizationSelector(
                selectedType: $selectedVisualization,
                animateTransition: $animateTransition
            )
            
            // Main Visualization Area
            GeometryReader { geometry in
                ZStack {
                    switch selectedVisualization {
                    case .scoreFlow:
                        ScoreFlowVisualization(
                            scores: getPlayerScores(),
                            pars: getPars(),
                            size: geometry.size
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        
                    case .radialAnalyzer:
                        RadialHoleAnalyzer(
                            scores: getPlayerScores(),
                            pars: getPars(),
                            size: geometry.size
                        )
                        .transition(.asymmetric(
                            insertion: .rotation.combined(with: .opacity),
                            removal: .opacity
                        ))
                        
                    case .timeline:
                        EmotionalTimelineView(
                            scores: getPlayerScores(),
                            pars: getPars(),
                            size: geometry.size
                        )
                        .transition(.asymmetric(
                            insertion: .slide,
                            removal: .opacity
                        ))
                        
                    case .comparison:
                        ComparisonLayersView(
                            rounds: getMockRounds(),
                            size: geometry.size
                        )
                        .transition(.opacity)
                        
                    case .heatMap:
                        CourseHeatMapView(
                            roundHistory: getMockRounds(),
                            size: geometry.size
                        )
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .scale
                        ))
                    }
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: selectedVisualization)
            }
            .padding()
            
            // Controls
            VisualizationControls(
                selectedPlayer: $selectedPlayer,
                players: players,
                showHeatMap: $showHeatMap
            )
        }
        .background(Color.gray.opacity(0.05))
    }
    
    private func getPlayerScores() -> [Int] {
        guard let player = selectedPlayer ?? players.first else { return [] }
        var scores: [Int] = []
        for hole in 1...18 {
            if let score = gameState.scores[hole]?[player.id] {
                scores.append(score)
            }
        }
        return scores.isEmpty ? (1...9).map { _ in Int.random(in: 3...6) } : scores // Mock data fallback
    }
    
    private func getPars() -> [Int] {
        return GolfConstants.ParManagement.service.getAllPars()
    }
    
    private func getMockRounds() -> [Round] {
        // TODO: Fetch from storage
        return [
            Round(id: UUID(), course: "Pebble Beach", date: Date(), players: ["John"], scores: [1: 4, 2: 5, 3: 3]),
            Round(id: UUID(), course: "Pebble Beach", date: Date().addingTimeInterval(-86400), players: ["John"], scores: [1: 5, 2: 4, 3: 4])
        ]
    }
}

// MARK: - Score Flow Visualization

struct ScoreFlowVisualization: View {
    let scores: [Int]
    let pars: [Int]
    let size: CGSize
    
    @State private var animateFlow = false
    @State private var wavePhase: CGFloat = 0
    
    private var flowPath: Path {
        var path = Path()
        let width = size.width
        let height = size.height
        let centerY = height / 2
        
        guard !scores.isEmpty else { return path }
        
        let segmentWidth = width / CGFloat(scores.count)
        
        path.move(to: CGPoint(x: 0, y: centerY))
        
        for (index, score) in scores.enumerated() {
            let par = index < pars.count ? pars[index] : GolfConstants.ParManagement.parForHole(index + 1)
            let diff = score - par
            
            // River width based on score relative to par
            let riverWidth = 30 + abs(CGFloat(diff)) * 15
            
            // Y position based on cumulative score
            let yOffset = CGFloat(diff) * 20
            let x = CGFloat(index) * segmentWidth
            let nextX = CGFloat(index + 1) * segmentWidth
            
            // Create flowing curve
            let controlPoint1 = CGPoint(
                x: x + segmentWidth * 0.3,
                y: centerY + yOffset + sin(wavePhase + CGFloat(index)) * 10
            )
            let controlPoint2 = CGPoint(
                x: x + segmentWidth * 0.7,
                y: centerY + yOffset - sin(wavePhase + CGFloat(index) + 0.5) * 10
            )
            
            path.addCurve(
                to: CGPoint(x: nextX, y: centerY + yOffset),
                control1: controlPoint1,
                control2: controlPoint2
            )
        }
        
        return path
    }
    
    private func colorForScore(_ score: Int, par: Int) -> Color {
        let diff = score - par
        if diff < 0 { return .blue }
        if diff == 0 { return .cyan }
        if diff == 1 { return .orange }
        return .red
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Flow river
            ForEach(0..<scores.count, id: \.self) { index in
                let score = scores[index]
                let par = index < pars.count ? pars[index] : GolfConstants.ParManagement.parForHole(index + 1)
                
                FlowSegment(
                    score: score,
                    par: par,
                    index: index,
                    totalHoles: scores.count,
                    size: size,
                    wavePhase: wavePhase
                )
            }
            
            // Overlay with hole numbers
            HStack(spacing: 0) {
                ForEach(0..<scores.count, id: \.self) { index in
                    VStack {
                        Spacer()
                        Text("\(index + 1)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }
}

struct FlowSegment: View {
    let score: Int
    let par: Int
    let index: Int
    let totalHoles: Int
    let size: CGSize
    let wavePhase: CGFloat
    
    private var diff: Int { score - par }
    
    private var riverWidth: CGFloat {
        30 + abs(CGFloat(diff)) * 15
    }
    
    private var riverColor: Color {
        if diff < 0 { return .blue }
        if diff == 0 { return .cyan }
        if diff == 1 { return .orange }
        return .red
    }
    
    var body: some View {
        let segmentWidth = size.width / CGFloat(totalHoles)
        let x = CGFloat(index) * segmentWidth
        let centerY = size.height / 2
        let yOffset = CGFloat(diff) * 20
        
        // River segment with gradient
        RoundedRectangle(cornerRadius: riverWidth / 2)
            .fill(
                LinearGradient(
                    colors: [
                        riverColor.opacity(0.3),
                        riverColor.opacity(0.6),
                        riverColor.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: segmentWidth, height: riverWidth)
            .position(
                x: x + segmentWidth / 2,
                y: centerY + yOffset + sin(wavePhase + CGFloat(index)) * 5
            )
            .blur(radius: 1)
        
        // Flow particles
        ForEach(0..<3) { particle in
            Circle()
                .fill(riverColor.opacity(0.8))
                .frame(width: 4, height: 4)
                .position(
                    x: x + segmentWidth * (0.2 + CGFloat(particle) * 0.3),
                    y: centerY + yOffset + sin(wavePhase * 2 + CGFloat(index) + CGFloat(particle)) * riverWidth / 3
                )
        }
    }
}

// MARK: - Radial Hole Analyzer

struct RadialHoleAnalyzer: View {
    let scores: [Int]
    let pars: [Int]
    let size: CGSize
    
    @State private var animateIn = false
    @State private var selectedHole: Int? = nil
    
    private let maxRadius: CGFloat = 150
    private let minRadius: CGFloat = 50
    
    private func angleForHole(_ hole: Int) -> Angle {
        let totalHoles = max(scores.count, 18)
        return .degrees(Double(hole) * 360.0 / Double(totalHoles) - 90)
    }
    
    private func radiusForScore(_ score: Int, par: Int) -> CGFloat {
        let diff = score - par
        let base = minRadius + (maxRadius - minRadius) / 2
        return base + CGFloat(diff) * 20
    }
    
    var body: some View {
        ZStack {
            // Background circles (par reference)
            ForEach([minRadius, minRadius + (maxRadius - minRadius) / 2, maxRadius], id: \.self) { radius in
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)
            }
            
            // Par circle highlighted
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                .frame(width: (minRadius + (maxRadius - minRadius) / 2) * 2,
                       height: (minRadius + (maxRadius - minRadius) / 2) * 2)
            
            // Score spikes
            ForEach(0..<scores.count, id: \.self) { index in
                let score = scores[index]
                let par = index < pars.count ? pars[index] : GolfConstants.ParManagement.parForHole(index + 1)
                let angle = angleForHole(index)
                let radius = radiusForScore(score, par: par)
                
                ScoreSpike(
                    hole: index + 1,
                    score: score,
                    par: par,
                    angle: angle,
                    radius: animateIn ? radius : minRadius,
                    isSelected: selectedHole == index,
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedHole = selectedHole == index ? nil : index
                        }
                    }
                )
            }
            
            // Center info
            if let selected = selectedHole, selected < scores.count {
                VStack(spacing: 4) {
                    Text("Hole \(selected + 1)")
                        .font(.system(size: 14, weight: .bold))
                    Text("Score: \(scores[selected])")
                        .font(.system(size: 12))
                    Text("Par: \(selected < pars.count ? pars[selected] : GolfConstants.ParManagement.parForHole(selected + 1))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.white.opacity(0.9))
                .cornerRadius(8)
                .transition(.scale)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                animateIn = true
            }
        }
    }
}

struct ScoreSpike: View {
    let hole: Int
    let score: Int
    let par: Int
    let angle: Angle
    let radius: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    private var spikeColor: Color {
        let diff = score - par
        if diff < -1 { return .purple }
        if diff < 0 { return .green }
        if diff == 0 { return .blue }
        if diff == 1 { return .orange }
        return .red
    }
    
    var body: some View {
        ZStack {
            // Spike line
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: radius, y: 0))
            }
            .stroke(
                LinearGradient(
                    colors: [spikeColor.opacity(0.3), spikeColor],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: isSelected ? 4 : 2, lineCap: .round)
            )
            .rotationEffect(angle)
            
            // End circle
            Circle()
                .fill(spikeColor)
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                .offset(x: radius)
                .rotationEffect(angle)
                .onTapGesture(perform: onTap)
            
            // Hole label
            Text("\(hole)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(spikeColor)
                .offset(x: radius + 20)
                .rotationEffect(angle)
        }
    }
}

// MARK: - Emotional Timeline

struct EmotionalTimelineView: View {
    let scores: [Int]
    let pars: [Int]
    let size: CGSize
    
    @State private var currentHole = 0
    @State private var emotionPath = Path()
    
    private func emotionForScore(_ score: Int, par: Int) -> (emoji: String, color: Color, intensity: CGFloat) {
        let diff = score - par
        switch diff {
        case ..<(-1): return ("star.fill", .purple, 1.0)
        case -1: return ("star", .green, 0.8)
        case 0: return ("checkmark.circle", .blue, 0.6)
        case 1: return ("exclamationmark.triangle", .orange, 0.7)
        default: return ("xmark.circle", .red, 0.9)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Timeline
            GeometryReader { geometry in
                ZStack {
                    // Background line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    
                    // Emotion curve
                    Path { path in
                        guard !scores.isEmpty else { return }
                        
                        let segmentWidth = geometry.size.width / CGFloat(scores.count - 1)
                        let centerY = geometry.size.height / 2
                        
                        path.move(to: CGPoint(x: 0, y: centerY))
                        
                        for (index, score) in scores.enumerated() {
                            let par = index < pars.count ? pars[index] : GolfConstants.ParManagement.parForHole(index + 1)
                            let emotion = emotionForScore(score, par: par)
                            let x = CGFloat(index) * segmentWidth
                            let y = centerY - (emotion.intensity - 0.5) * 100
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                let prevX = CGFloat(index - 1) * segmentWidth
                                let prevScore = scores[index - 1]
                                let prevPar = (index - 1) < pars.count ? pars[index - 1] : 4
                                let prevEmotion = emotionForScore(prevScore, par: prevPar)
                                let prevY = centerY - (prevEmotion.intensity - 0.5) * 100
                                
                                path.addCurve(
                                    to: CGPoint(x: x, y: y),
                                    control1: CGPoint(x: prevX + segmentWidth * 0.5, y: prevY),
                                    control2: CGPoint(x: x - segmentWidth * 0.5, y: y)
                                )
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.green, .blue, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    
                    // Emotion markers
                    ForEach(0..<scores.count, id: \.self) { index in
                        let score = scores[index]
                        let par = index < pars.count ? pars[index] : GolfConstants.ParManagement.parForHole(index + 1)
                        let emotion = emotionForScore(score, par: par)
                        let segmentWidth = geometry.size.width / CGFloat(scores.count - 1)
                        let x = CGFloat(index) * segmentWidth
                        let centerY = geometry.size.height / 2
                        let y = centerY - (emotion.intensity - 0.5) * 100
                        
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .shadow(color: emotion.color.opacity(0.3), radius: 3)
                            
                            Image(systemName: emotion.emoji)
                                .font(.system(size: 14))
                                .foregroundColor(emotion.color)
                        }
                        .position(x: x, y: y)
                        .scaleEffect(currentHole == index ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3), value: currentHole)
                        .onTapGesture {
                            withAnimation {
                                currentHole = index
                            }
                        }
                    }
                }
            }
            .frame(height: 200)
            
            // Emotion legend
            HStack(spacing: 20) {
                ForEach([(diff: -2, label: "Eagle"), (diff: -1, label: "Birdie"),
                         (diff: 0, label: "Par"), (diff: 1, label: "Bogey"),
                         (diff: 2, label: "Double")], id: \.diff) { item in
                    let emotion = emotionForScore(GolfConstants.ParDefaults.defaultPar + item.diff, par: GolfConstants.ParDefaults.defaultPar)
                    HStack(spacing: 4) {
                        Image(systemName: emotion.emoji)
                            .font(.system(size: 12))
                            .foregroundColor(emotion.color)
                        Text(item.label)
                            .font(.system(size: 10))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 5)
        )
    }
}

// MARK: - Comparison Layers

struct ComparisonLayersView: View {
    let rounds: [Round]
    let size: CGSize
    
    @State private var visibleRounds: Set<UUID> = []
    
    var body: some View {
        VStack {
            // Round selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(rounds) { round in
                        RoundChip(
                            round: round,
                            isVisible: visibleRounds.contains(round.id),
                            toggle: {
                                withAnimation(.spring(response: 0.3)) {
                                    if visibleRounds.contains(round.id) {
                                        visibleRounds.remove(round.id)
                                    } else {
                                        visibleRounds.insert(round.id)
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Layered visualization
            ZStack {
                ForEach(rounds) { round in
                    if visibleRounds.contains(round.id) {
                        RoundLayer(
                            round: round,
                            size: CGSize(width: size.width, height: size.height - 60),
                            opacity: 0.6
                        )
                        .transition(.opacity)
                    }
                }
            }
        }
    }
}

struct RoundLayer: View {
    let round: Round
    let size: CGSize
    let opacity: Double
    
    private var scores: [Int] {
        (1...18).compactMap { round.scores[$0] }
    }
    
    var body: some View {
        Canvas { context, size in
            guard !scores.isEmpty else { return }
            
            let segmentWidth = size.width / CGFloat(scores.count - 1)
            var path = Path()
            
            for (index, score) in scores.enumerated() {
                let x = CGFloat(index) * segmentWidth
                let par = GolfConstants.ParManagement.parForHole(index + 1)
                let diff = score - par
                let y = size.height / 2 - CGFloat(diff) * 20
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            context.stroke(
                path,
                with: .color(.blue.opacity(opacity)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

// MARK: - Course Heat Map

struct CourseHeatMapView: View {
    let roundHistory: [Round]
    let size: CGSize
    
    @State private var animateGradient = false
    @State private var selectedTimeFilter: TimeFilter = .allTime
    
    private func heatIntensity(for hole: Int) -> Double {
        // Calculate average score relative to par
        var totalDiff = 0
        var count = 0
        
        for round in roundHistory {
            if let score = round.scores[hole] {
                totalDiff += score - GolfConstants.ParManagement.parForHole(hole)
                count += 1
            }
        }
        
        guard count > 0 else { return 0 }
        let avgDiff = Double(totalDiff) / Double(count)
        
        // Normalize to 0-1 range
        return max(0, min(1, (avgDiff + 2) / 4))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Time filter
            Picker("Time Period", selection: $selectedTimeFilter) {
                ForEach(TimeFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Heat map grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                ForEach(1...18, id: \.self) { hole in
                    HoleHeatCell(
                        hole: hole,
                        intensity: heatIntensity(for: hole),
                        isAnimating: animateGradient
                    )
                }
            }
            .padding()
            
            // Legend
            HStack {
                Text("Performs Well")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                
                LinearGradient(
                    colors: [.green, .yellow, .orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 4)
                .cornerRadius(2)
                
                Text("Struggles")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

struct HoleHeatCell: View {
    let hole: Int
    let intensity: Double
    let isAnimating: Bool
    
    private var heatColor: Color {
        if intensity < 0.25 { return .green }
        if intensity < 0.5 { return .yellow }
        if intensity < 0.75 { return .orange }
        return .red
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    RadialGradient(
                        colors: [
                            heatColor,
                            heatColor.opacity(0.5)
                        ],
                        center: .center,
                        startRadius: isAnimating ? 0 : 20,
                        endRadius: 30
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(heatColor.opacity(0.3), lineWidth: 1)
                )
            
            VStack(spacing: 2) {
                Text("\(hole)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(String(format: "%.1f", 4 + intensity * 2))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(width: 60, height: 60)
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
    }
}

// MARK: - Supporting Components

struct VisualizationSelector: View {
    @Binding var selectedType: VisualizationType
    @Binding var animateTransition: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VisualizationType.allCases, id: \.self) { type in
                    VisualizationTypeButton(
                        type: type,
                        isSelected: selectedType == type,
                        action: {
                            animateTransition = true
                            withAnimation(.spring(response: 0.5)) {
                                selectedType = type
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .background(Color.white)
        .shadow(radius: 2)
    }
}

struct VisualizationTypeButton: View {
    let type: VisualizationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                
                Text(type.title)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

struct VisualizationControls: View {
    @Binding var selectedPlayer: Player?
    let players: [Player]
    @Binding var showHeatMap: Bool
    
    var body: some View {
        HStack {
            Menu {
                ForEach(players) { player in
                    Button(player.name) {
                        selectedPlayer = player
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "person.circle")
                    Text(selectedPlayer?.name ?? "Select Player")
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            Toggle("Heat Map", isOn: $showHeatMap)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding()
    }
}

struct RoundChip: View {
    let round: Round
    let isVisible: Bool
    let toggle: () -> Void
    
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                Image(systemName: isVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 12))
                
                Text(round.course)
                    .font(.system(size: 12))
                
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isVisible ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isVisible ? .white : .primary)
        }
    }
}

// MARK: - Supporting Types

enum VisualizationType: CaseIterable {
    case scoreFlow
    case radialAnalyzer
    case timeline
    case comparison
    case heatMap
    
    var title: String {
        switch self {
        case .scoreFlow: return "Flow"
        case .radialAnalyzer: return "Radial"
        case .timeline: return "Timeline"
        case .comparison: return "Compare"
        case .heatMap: return "Heat Map"
        }
    }
    
    var icon: String {
        switch self {
        case .scoreFlow: return "waveform.path"
        case .radialAnalyzer: return "chart.pie"
        case .timeline: return "chart.line.uptrend.xyaxis"
        case .comparison: return "square.stack.3d.up"
        case .heatMap: return "square.grid.3x3.fill.square"
        }
    }
}

enum TimeFilter: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case allTime = "All Time"
}

// MARK: - Visualization Protocols

protocol VisualizationRenderer {
    func renderScoreFlow(_ scores: [Score]) -> Path
    func generateHeatMap(_ roundHistory: [Round]) -> CGImage?
    func animateTransition(from: VisualizationType, to: VisualizationType)
}

struct ScoreFlowConfig {
    var flowIntensity: Double = 1.0
    var colorGradient: Gradient = Gradient(colors: [.blue, .cyan, .orange, .red])
    var waveAmplitude: Double = 10.0
    var particleCount: Int = 3
}

struct Score {
    let hole: Int
    let value: Int
    let timestamp: Date
}