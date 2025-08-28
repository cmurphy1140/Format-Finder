import SwiftUI

// MARK: - Animated Format Explainer

struct AnimatedFormatExplainer: View {
    let format: GolfFormat
    @State private var currentSlide = 0
    @State private var animationPhase = 0.0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @Environment(\.dismiss) var dismiss
    
    var totalSlides: Int {
        3 + (format.hasDiagramSlides ? 2 : 0)
    }
    
    var body: some View {
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
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text(format.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Format icon
                    Image(systemName: format.icon)
                        .font(.system(size: 30))
                        .foregroundColor(format.color)
                }
                .padding()
                .background(
                    Color.white.opacity(0.95)
                        .blur(radius: 10)
                )
                
                // Slide indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalSlides, id: \.self) { index in
                        Capsule()
                            .fill(currentSlide == index ? format.color : Color.gray.opacity(0.3))
                            .frame(width: currentSlide == index ? 30 : 10, height: 10)
                            .animation(.spring(), value: currentSlide)
                    }
                }
                .padding(.vertical, 10)
                
                // Content area with gesture support
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(0..<totalSlides, id: \.self) { index in
                            slideContent(for: index)
                                .frame(width: geometry.size.width)
                        }
                    }
                    .offset(x: -CGFloat(currentSlide) * geometry.size.width + dragOffset.width)
                    .animation(!isDragging ? .spring() : nil, value: currentSlide)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                isDragging = false
                                let threshold: CGFloat = 50
                                
                                if value.translation.width > threshold && currentSlide > 0 {
                                    currentSlide -= 1
                                } else if value.translation.width < -threshold && currentSlide < totalSlides - 1 {
                                    currentSlide += 1
                                }
                                
                                dragOffset = .zero
                            }
                    )
                }
                
                // Navigation buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if currentSlide > 0 {
                            currentSlide -= 1
                        }
                    }) {
                        Label("Previous", systemImage: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                format.color.opacity(currentSlide > 0 ? 1 : 0.3)
                            )
                            .cornerRadius(25)
                    }
                    .disabled(currentSlide == 0)
                    
                    Button(action: {
                        if currentSlide < totalSlides - 1 {
                            currentSlide += 1
                        } else {
                            dismiss()
                        }
                    }) {
                        Label(
                            currentSlide < totalSlides - 1 ? "Next" : "Done",
                            systemImage: currentSlide < totalSlides - 1 ? "chevron.right" : "checkmark"
                        )
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(format.color)
                        .cornerRadius(25)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
    
    @ViewBuilder
    func slideContent(for index: Int) -> some View {
        switch index {
        case 0:
            OverviewSlide(format: format, animationPhase: animationPhase)
        case 1:
            // Use intuitive demonstration for rules
            IntuitiveFormatDemonstration(format: format)
        case 2:
            StrategySlide(format: format, animationPhase: animationPhase)
        case 3 where format.hasDiagramSlides:
            DiagramSlide(format: format, animationPhase: animationPhase, slideNumber: 1)
        case 4 where format.hasDiagramSlides:
            DiagramSlide(format: format, animationPhase: animationPhase, slideNumber: 2)
        default:
            EmptyView()
        }
    }
}

// MARK: - Overview Slide

struct OverviewSlide: View {
    let format: GolfFormat
    let animationPhase: Double
    @State private var showElements = [false, false, false, false]
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(format.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + animationPhase * 0.1)
                
                Image(systemName: format.icon)
                    .font(.system(size: 60))
                    .foregroundColor(format.color)
                    .rotationEffect(.degrees(animationPhase * 360))
            }
            .padding(.top, 20)
            
            // Format tagline
            Text(format.tagline)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .opacity(showElements[0] ? 1 : 0)
                .offset(y: showElements[0] ? 0 : 20)
            
            // Key info cards
            VStack(spacing: 15) {
                InfoCard(
                    icon: "person.2.fill",
                    title: "Players",
                    value: format.players,
                    color: .blue
                )
                .opacity(showElements[1] ? 1 : 0)
                .offset(x: showElements[1] ? 0 : -50)
                
                InfoCard(
                    icon: "speedometer",
                    title: "Difficulty",
                    value: format.difficulty,
                    color: difficultyColor(format.difficulty)
                )
                .opacity(showElements[2] ? 1 : 0)
                .offset(x: showElements[2] ? 0 : 50)
                
                InfoCard(
                    icon: format.isTeamFormat ? "person.3.fill" : "person.fill",
                    title: "Format",
                    value: format.isTeamFormat ? "Team" : "Individual",
                    color: .purple
                )
                .opacity(showElements[3] ? 1 : 0)
                .offset(y: showElements[3] ? 0 : 20)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .onAppear {
            for i in 0..<4 {
                withAnimation(.spring().delay(Double(i) * 0.2)) {
                    showElements[i] = true
                }
            }
        }
    }
    
    func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Beginner": return .green
        case "Intermediate": return .orange
        case "Advanced": return .red
        default: return .gray
        }
    }
}

// MARK: - Rules Animation Slide

struct RulesAnimationSlide: View {
    let format: GolfFormat
    let animationPhase: Double
    @State private var currentRule = 0
    @State private var animateRule = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How to Play")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top)
            
            // Animated rule display
            ZStack {
                ForEach(format.rules.indices, id: \.self) { index in
                    RuleCard(
                        rule: format.rules[index],
                        number: index + 1,
                        isActive: currentRule == index,
                        format: format
                    )
                    .opacity(currentRule == index ? 1 : 0)
                    .scaleEffect(currentRule == index ? 1 : 0.8)
                    .rotationEffect(.degrees(currentRule == index ? 0 : currentRule > index ? -10 : 10))
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 200)
            
            // Rule navigation dots
            HStack(spacing: 10) {
                ForEach(format.rules.indices, id: \.self) { index in
                    Circle()
                        .fill(currentRule == index ? format.color : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                currentRule = index
                            }
                        }
                }
            }
            
            // Auto-advance timer
            ProgressView(value: Double(currentRule) / Double(format.rules.count - 1))
                .progressViewStyle(LinearProgressViewStyle(tint: format.color))
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                withAnimation(.spring()) {
                    currentRule = (currentRule + 1) % format.rules.count
                }
            }
        }
    }
}

// MARK: - Strategy Slide

struct StrategySlide: View {
    let format: GolfFormat
    let animationPhase: Double
    @State private var expandedStrategy: Int? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Winning Strategy")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(format.strategy.indices, id: \.self) { index in
                        StrategyCard(
                            strategy: format.strategy[index],
                            number: index + 1,
                            isExpanded: expandedStrategy == index,
                            color: format.color,
                            action: {
                                withAnimation(.spring()) {
                                    expandedStrategy = expandedStrategy == index ? nil : index
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Diagram Slide

struct DiagramSlide: View {
    let format: GolfFormat
    let animationPhase: Double
    let slideNumber: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text(slideNumber == 1 ? "Visual Example" : "Advanced Scenario")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top)
            
            // Format-specific animated diagrams
            if format.name == "Scramble" {
                ScrambleDiagram(animationPhase: animationPhase, slideNumber: slideNumber)
            } else if format.name == "Best Ball" {
                BestBallDiagram(animationPhase: animationPhase, slideNumber: slideNumber)
            } else if format.name == "Alternate Shot" {
                AlternateShotDiagram(animationPhase: animationPhase, slideNumber: slideNumber)
            } else if format.name == "Match Play" {
                MatchPlayDiagram(animationPhase: animationPhase, slideNumber: slideNumber)
            } else {
                GenericDiagram(format: format, animationPhase: animationPhase)
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Components

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct RuleCard: View {
    let rule: String
    let number: Int
    let isActive: Bool
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(number)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(format.color)
                    .clipShape(Circle())
                
                Spacer()
            }
            
            Text(rule)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 200)
        .background(Color.white.opacity(0.95))
        .cornerRadius(20)
        .shadow(color: format.color.opacity(0.3), radius: 10, x: 0, y: 5)
        .animation(.spring(), value: isActive)
    }
}

struct StrategyCard: View {
    let strategy: String
    let number: Int
    let isExpanded: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(color)
                    .clipShape(Circle())
                
                Text(strategy)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isExpanded ? nil : 2)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(color)
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Format-Specific Diagrams

struct ScrambleDiagram: View {
    let animationPhase: Double
    let slideNumber: Int
    
    var body: some View {
        ZStack {
            // Golf hole visualization
            AnimatedGolfHoleView()
            
            if slideNumber == 1 {
                // Show all players teeing off
                ForEach(0..<4) { i in
                    GolfBallAnimation(
                        startPoint: CGPoint(x: 100, y: 300),
                        endPoint: CGPoint(x: 200 + Double(i) * 30, y: 150),
                        delay: Double(i) * 0.2,
                        color: animatedPlayerColors[i]
                    )
                }
                
                // Best shot indicator
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .position(x: 230, y: 150)
                    .opacity(animationPhase > 0.5 ? 1 : 0)
            } else {
                // Show all players hitting from best shot
                ForEach(0..<4) { i in
                    GolfBallAnimation(
                        startPoint: CGPoint(x: 230, y: 150),
                        endPoint: CGPoint(x: 280, y: 80),
                        delay: 0.5 + Double(i) * 0.1,
                        color: animatedPlayerColors[i]
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.2),
                    Color.green.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct BestBallDiagram: View {
    let animationPhase: Double
    let slideNumber: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Each player plays their own ball")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            // Scorecard visualization
            HStack(spacing: 20) {
                ForEach(0..<4) { i in
                    VStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(playerColors[i])
                            .font(.system(size: 30))
                        
                        Text("Player \(i + 1)")
                            .font(.caption)
                        
                        Text("\(4 + i)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(i == 0 ? .green : .primary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(i == 0 ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(i == 0 ? Color.green : Color.clear, lineWidth: 2)
                            )
                    )
                    .scaleEffect(i == 0 && animationPhase > 0.5 ? 1.1 : 1)
                }
            }
            
            Text("Team Score: 4")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
        }
        .padding()
    }
}

struct AlternateShotDiagram: View {
    let animationPhase: Double
    let slideNumber: Int
    @State private var currentPlayer = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Player indicator
            HStack(spacing: 40) {
                PlayerIndicator(number: 1, isActive: currentPlayer == 0, color: .blue)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                PlayerIndicator(number: 2, isActive: currentPlayer == 1, color: .purple)
            }
            
            // Shot progression
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 50, y: 200))
                    path.addCurve(
                        to: CGPoint(x: 300, y: 50),
                        control1: CGPoint(x: 150, y: 150),
                        control2: CGPoint(x: 250, y: 100)
                    )
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, dash: [10, 5])
                )
                
                // Animated ball
                Circle()
                    .fill(currentPlayer == 0 ? Color.blue : Color.purple)
                    .frame(width: 20, height: 20)
                    .offset(x: -150 + animationPhase * 250, y: -75 - animationPhase * 75)
            }
            .frame(height: 250)
            
            Text(currentPlayer == 0 ? "Player 1's Shot" : "Player 2's Shot")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                withAnimation {
                    currentPlayer = (currentPlayer + 1) % 2
                }
            }
        }
        .padding()
    }
}

struct MatchPlayDiagram: View {
    let animationPhase: Double
    let slideNumber: Int
    
    var body: some View {
        VStack(spacing: 25) {
            // Match status
            HStack(spacing: 30) {
                VStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Player A")
                        .font(.caption)
                    Text("2 UP")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Text("vs")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                
                VStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text("Player B")
                        .font(.caption)
                    Text("2 DOWN")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
            // Holes won visualization
            HStack(spacing: 5) {
                ForEach(1...9, id: \.self) { hole in
                    VStack(spacing: 2) {
                        Text("\(hole)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Circle()
                            .fill(holeWinner(hole))
                            .frame(width: 25, height: 25)
                            .overlay(
                                Image(systemName: holeStatus(hole))
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            
            Text("Through 9 holes")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    func holeWinner(_ hole: Int) -> Color {
        switch hole {
        case 1, 3, 5: return .blue
        case 4: return .red
        default: return .gray.opacity(0.3)
        }
    }
    
    func holeStatus(_ hole: Int) -> String {
        switch hole {
        case 1, 3, 5: return "checkmark"
        case 4: return "xmark"
        default: return "equal"
        }
    }
}

struct GenericDiagram: View {
    let format: GolfFormat
    let animationPhase: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: format.icon)
                .font(.system(size: 80))
                .foregroundColor(format.color)
                .rotationEffect(.degrees(animationPhase * 360))
            
            Text(format.description)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding()
    }
}

// MARK: - Helper Components

struct AnimatedGolfHoleView: View {
    var body: some View {
        ZStack {
            // Fairway
            Ellipse()
                .fill(Color.green.opacity(0.3))
                .frame(width: 300, height: 400)
            
            // Tee box
            Rectangle()
                .fill(Color.green.opacity(0.5))
                .frame(width: 60, height: 40)
                .position(x: 100, y: 300)
            
            // Green
            Circle()
                .fill(Color.green.opacity(0.6))
                .frame(width: 80, height: 80)
                .position(x: 280, y: 80)
            
            // Flag
            VStack(spacing: 0) {
                Triangle()
                    .fill(Color.red)
                    .frame(width: 20, height: 15)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 2, height: 30)
            }
            .position(x: 280, y: 80)
        }
    }
}

struct GolfBallAnimation: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let delay: Double
    let color: Color
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 15, height: 15)
            .position(animate ? endPoint : startPoint)
            .onAppear {
                withAnimation(.easeOut(duration: 1).delay(delay)) {
                    animate = true
                }
            }
    }
}

struct PlayerIndicator: View {
    let number: Int
    let isActive: Bool
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: "person.fill")
                .font(.system(size: 30))
                .foregroundColor(isActive ? color : .gray)
            Text("Player \(number)")
                .font(.caption)
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .scaleEffect(isActive ? 1.1 : 1)
        .animation(.spring(), value: isActive)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// Player colors for animations
let animatedPlayerColors: [Color] = [.blue, .green, .orange, .purple]