import SwiftUI

// MARK: - Diagram Slideshow Container

struct FormatDiagramSlideshow: View {
    let formatName: String
    @State private var currentSlide = 0
    
    var slides: [AnyView] {
        switch formatName {
        case "Scramble":
            return ScrambleSlides.slides
        case "Best Ball":
            return BestBallSlides.slides
        case "Stableford":
            return StablefordSlides.slides
        case "Alternate Shot":
            return AlternateShotSlides.slides
        case "Match Play":
            return MatchPlaySlides.slides
        case "Skins":
            return SkinsSlides.slides
        case "Nassau":
            return NassauSlides.slides
        case "Vegas":
            return VegasSlides.slides
        case "Wolf":
            return WolfSlides.slides
        case "Bingo Bango Bongo":
            return BingoBangoBongoSlides.slides
        default:
            return [AnyView(DefaultDiagramSlide(title: formatName))]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Slide content
            TabView(selection: $currentSlide) {
                ForEach(0..<slides.count, id: \.self) { index in
                    slides[index]
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
            
            // Custom page indicators
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(currentSlide == index ? 
                            Color(red: 46/255, green: 125/255, blue: 50/255) : 
                            Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentSlide == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentSlide)
                }
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Scramble Format Slides

struct ScrambleSlides {
    static var slides: [AnyView] {
        [
            AnyView(ScrambleSetupSlide()),
            AnyView(ScrambleTeeShots()),
            AnyView(ScrambleBestShot()),
            AnyView(ScrambleScoring()),
            AnyView(ScrambleProTips())
        ]
    }
}

struct ScrambleSetupSlide: View {
    @State private var showPlayers = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "SCRAMBLE - Setup",
            subtitle: "2-4 Players per Team"
        ) {
            VStack(spacing: 20) {
                // Team formation visual
                HStack(spacing: 30) {
                    ForEach(0..<4) { index in
                        VStack {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 40))
                                .foregroundColor(playerColors[index])
                                .scaleEffect(showPlayers ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5)
                                    .delay(Double(index) * 0.1),
                                    value: showPlayers
                                )
                            
                            Text("Player \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .opacity(showPlayers ? 1 : 0)
                                .animation(
                                    .easeIn(duration: 0.3)
                                    .delay(Double(index) * 0.1 + 0.2),
                                    value: showPlayers
                                )
                        }
                    }
                }
                
                Text("All players on same team")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                    )
            }
            .onAppear {
                showPlayers = true
            }
        }
    }
}

struct ScrambleTeeShots: View {
    @State private var animateShots = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Step 1: Everyone Tees Off",
            subtitle: "All players hit their drive"
        ) {
            ZStack {
                // Golf hole visualization
                GolfHoleView()
                
                // Animated shot paths
                ForEach(0..<4) { index in
                    ShotPath(
                        startX: 50,
                        startY: 200,
                        endX: shotEndpoints[index].x,
                        endY: shotEndpoints[index].y,
                        color: playerColors[index],
                        animate: animateShots,
                        delay: Double(index) * 0.2
                    )
                }
                
                // Ball positions
                ForEach(0..<4) { index in
                    Circle()
                        .fill(playerColors[index])
                        .frame(width: 12, height: 12)
                        .position(
                            x: animateShots ? shotEndpoints[index].x : 50,
                            y: animateShots ? shotEndpoints[index].y : 200
                        )
                        .animation(
                            .easeOut(duration: 0.8)
                            .delay(Double(index) * 0.2),
                            value: animateShots
                        )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateShots = true
                }
            }
        }
    }
    
    var shotEndpoints: [CGPoint] {
        [
            CGPoint(x: 180, y: 120),
            CGPoint(x: 200, y: 100),  // Best shot
            CGPoint(x: 160, y: 110),
            CGPoint(x: 190, y: 130)
        ]
    }
}

struct ScrambleBestShot: View {
    @State private var selectBest = false
    @State private var moveToSpot = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Step 2: Choose Best Shot",
            subtitle: "Team selects optimal position"
        ) {
            VStack(spacing: 20) {
                ZStack {
                    GolfHoleView()
                    
                    // Show all ball positions
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == 1 ? Color.yellow : playerColors[index].opacity(0.3))
                            .frame(width: index == 1 && selectBest ? 20 : 12)
                            .position(shotEndpoints[index])
                            .overlay(
                                index == 1 && selectBest ?
                                Text("BEST")
                                    .font(.caption2.bold())
                                    .foregroundColor(.black)
                                    .position(shotEndpoints[index])
                                : nil
                            )
                    }
                    
                    // Arrow pointing to best shot
                    if selectBest {
                        Image(systemName: "arrow.down")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .position(x: shotEndpoints[1].x, y: shotEndpoints[1].y - 30)
                            .transition(.scale)
                    }
                    
                    // All players at best shot
                    if moveToSpot {
                        ForEach(0..<4) { index in
                            Image(systemName: "figure.golf")
                                .font(.caption)
                                .foregroundColor(playerColors[index])
                                .position(
                                    x: shotEndpoints[1].x + CGFloat(index - 2) * 15,
                                    y: shotEndpoints[1].y + 20
                                )
                                .transition(.scale)
                        }
                    }
                }
                
                Text(moveToSpot ? "Everyone plays from here!" : "Team discusses best option")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .animation(.easeInOut, value: moveToSpot)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { selectBest = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { moveToSpot = true }
                    }
                }
            }
        }
    }
    
    var shotEndpoints: [CGPoint] {
        [
            CGPoint(x: 180, y: 120),
            CGPoint(x: 200, y: 100),  // Best shot
            CGPoint(x: 160, y: 110),
            CGPoint(x: 190, y: 130)
        ]
    }
}

struct ScrambleScoring: View {
    @State private var showScore = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring",
            subtitle: "One score for the team"
        ) {
            VStack(spacing: 30) {
                // Scorecard visual
                VStack(spacing: 15) {
                    HStack {
                        Text("Hole")
                        Spacer()
                        Text("Par")
                        Spacer()
                        Text("Team Score")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    
                    HStack {
                        Text("1")
                        Spacer()
                        Text("4")
                        Spacer()
                        Text(showScore ? "3" : "-")
                            .font(.title2.bold())
                            .foregroundColor(showScore ? .green : .gray)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                if showScore {
                    Label("Birdie! Great teamwork!", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.spring()) {
                        showScore = true
                    }
                }
            }
        }
    }
}

struct ScrambleProTips: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Pro Tips",
            subtitle: "Strategy for success"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                ForEach(scrambleTips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                            .opacity(showTips ? 1 : 0)
                            .scaleEffect(showTips ? 1 : 0.5)
                            .animation(
                                .spring()
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                        
                        Text(scrambleTips[index])
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(showTips ? 1 : 0)
                            .offset(x: showTips ? 0 : -20)
                            .animation(
                                .easeOut(duration: 0.5)
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                    }
                }
            }
            .padding(.horizontal)
            .onAppear {
                showTips = true
            }
        }
    }
    
    var scrambleTips: [String] {
        [
            "Have at least one consistent player for safety",
            "Let big hitters go for distance",
            "Save your best putter for pressure putts",
            "Communicate about best angles and lies"
        ]
    }
}

// MARK: - Best Ball Format Slides

struct BestBallSlides {
    static var slides: [AnyView] {
        [
            AnyView(BestBallSetupSlide()),
            AnyView(BestBallGameplay()),
            AnyView(BestBallScoring()),
            AnyView(BestBallStrategy())
        ]
    }
}

struct BestBallSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "BEST BALL - Setup",
            subtitle: "Each player plays own ball"
        ) {
            VStack(spacing: 25) {
                // Show players with their own balls
                HStack(spacing: 40) {
                    ForEach(0..<3) { index in
                        VStack(spacing: 10) {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 35))
                                .foregroundColor(playerColors[index])
                            
                            Circle()
                                .fill(playerColors[index])
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                )
                            
                            Text("Own Ball")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .opacity(showSetup ? 1 : 0)
                        .offset(y: showSetup ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.5)
                            .delay(Double(index) * 0.15),
                            value: showSetup
                        )
                    }
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 30)
                
                Text("Everyone plays independently")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.5), value: showSetup)
            }
            .onAppear { showSetup = true }
        }
    }
}

struct BestBallGameplay: View {
    @State private var playShots = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Gameplay",
            subtitle: "Each player completes the hole"
        ) {
            ZStack {
                GolfHoleView()
                
                // Three separate paths for each player
                ForEach(0..<3) { index in
                    ShotPath(
                        startX: 50,
                        startY: 200,
                        endX: 250,
                        endY: 100,
                        color: playerColors[index],
                        animate: playShots,
                        delay: Double(index) * 0.3,
                        curved: true,
                        curveFactor: CGFloat(index - 1) * 30
                    )
                }
                
                // Show scores at the hole
                if playShots {
                    VStack {
                        ForEach(0..<3) { index in
                            HStack {
                                Circle()
                                    .fill(playerColors[index])
                                    .frame(width: 16, height: 16)
                                Text("Score: \(playerScores[index])")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .position(x: 250, y: 160)
                    .transition(.scale)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        playShots = true
                    }
                }
            }
        }
    }
    
    var playerScores: [Int] { [5, 4, 6] }
}

struct BestBallScoring: View {
    @State private var highlightBest = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring",
            subtitle: "Count only the best score"
        ) {
            VStack(spacing: 20) {
                // Score comparison
                HStack(spacing: 30) {
                    ForEach(0..<3) { index in
                        VStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(playerColors[index])
                            
                            ZStack {
                                Circle()
                                    .fill(index == 1 && highlightBest ? 
                                        Color.green : 
                                        playerColors[index].opacity(0.3))
                                    .frame(width: 50, height: 50)
                                
                                Text("\(playerScores[index])")
                                    .font(.title2.bold())
                                    .foregroundColor(index == 1 && highlightBest ? 
                                        .white : 
                                        playerColors[index])
                            }
                            .scaleEffect(index == 1 && highlightBest ? 1.2 : 1.0)
                            .animation(.spring(), value: highlightBest)
                        }
                    }
                }
                
                Image(systemName: "arrow.down")
                    .font(.title)
                    .foregroundColor(.white)
                    .opacity(highlightBest ? 1 : 0)
                
                if highlightBest {
                    Text("Team Score: 4")
                        .font(.title.bold())
                        .foregroundColor(.green)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        )
                        .transition(.scale)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { highlightBest = true }
                }
            }
        }
    }
    
    var playerScores: [Int] { [5, 4, 6] }
}

struct BestBallStrategy: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Tips for Best Ball success"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                ForEach(bestBallTips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: strategIcons[index])
                            .foregroundColor(.cyan)
                            .font(.system(size: 18))
                            .frame(width: 24)
                            .opacity(showTips ? 1 : 0)
                            .scaleEffect(showTips ? 1 : 0.5)
                            .animation(
                                .spring()
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                        
                        Text(bestBallTips[index])
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(showTips ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.5)
                                .delay(Double(index) * 0.2),
                                value: showTips
                            )
                    }
                }
            }
            .padding(.horizontal)
            .onAppear { showTips = true }
        }
    }
    
    var bestBallTips: [String] {
        [
            "Play your normal game - no pressure!",
            "One bad hole doesn't hurt the team",
            "Support teammates even when struggling",
            "Aggressive play can pay off"
        ]
    }
    
    var strategIcons: [String] {
        ["checkmark.circle", "xmark.shield", "person.2", "flame"]
    }
}

// MARK: - Reusable Components

struct DiagramSlideTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 10)
            
            // Content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 46/255, green: 125/255, blue: 50/255),
                    Color(red: 76/255, green: 175/255, blue: 80/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct GolfHoleView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fairway
                Path { path in
                    path.move(to: CGPoint(x: 30, y: 220))
                    path.addQuadCurve(
                        to: CGPoint(x: 270, y: 100),
                        control: CGPoint(x: 150, y: 150)
                    )
                    path.addLine(to: CGPoint(x: 270, y: 120))
                    path.addQuadCurve(
                        to: CGPoint(x: 30, y: 240),
                        control: CGPoint(x: 150, y: 170)
                    )
                    path.closeSubpath()
                }
                .fill(Color(red: 139/255, green: 195/255, blue: 74/255).opacity(0.6))
                
                // Tee box
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 93/255, green: 64/255, blue: 55/255))
                    .frame(width: 30, height: 30)
                    .position(x: 50, y: 200)
                
                // Green
                Circle()
                    .fill(Color(red: 76/255, green: 175/255, blue: 80/255))
                    .frame(width: 60, height: 60)
                    .position(x: 250, y: 100)
                
                // Hole
                Circle()
                    .fill(Color.black)
                    .frame(width: 8, height: 8)
                    .position(x: 250, y: 100)
                
                // Flag
                Path { path in
                    path.move(to: CGPoint(x: 250, y: 100))
                    path.addLine(to: CGPoint(x: 250, y: 70))
                }
                .stroke(Color.white, lineWidth: 2)
                
                Path { path in
                    path.move(to: CGPoint(x: 250, y: 70))
                    path.addLine(to: CGPoint(x: 250, y: 80))
                    path.addLine(to: CGPoint(x: 265, y: 75))
                    path.closeSubpath()
                }
                .fill(Color.red)
            }
        }
    }
}

struct ShotPath: View {
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let color: Color
    let animate: Bool
    let delay: Double
    var curved: Bool = false
    var curveFactor: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: startX, y: startY))
            
            if curved {
                let controlX = (startX + endX) / 2 + curveFactor
                let controlY = (startY + endY) / 2 - 30
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: controlX, y: controlY)
                )
            } else {
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: (startX + endX) / 2, y: min(startY, endY) - 40)
                )
            }
        }
        .trim(from: 0, to: animate ? 1 : 0)
        .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
        .animation(
            .easeOut(duration: 0.8)
            .delay(delay),
            value: animate
        )
    }
}

struct DefaultDiagramSlide: View {
    let title: String
    
    var body: some View {
        DiagramSlideTemplate(title: title.uppercased(), subtitle: "Golf Format") {
            Image(systemName: "figure.golf")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Additional Format Slides (Stableford)

struct StablefordSlides {
    static var slides: [AnyView] {
        [
            AnyView(StablefordScoringSystem()),
            AnyView(StablefordExample()),
            AnyView(StablefordStrategy())
        ]
    }
}

struct StablefordScoringSystem: View {
    @State private var showPoints = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "STABLEFORD",
            subtitle: "Points-based scoring"
        ) {
            VStack(spacing: 15) {
                ForEach(stablefordPoints.indices, id: \.self) { index in
                    HStack {
                        Text(stablefordPoints[index].score)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 100, alignment: .leading)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(stablefordPoints[index].color.opacity(0.3))
                                .frame(width: 60, height: 30)
                            
                            Text("\(stablefordPoints[index].points) pts")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(stablefordPoints[index].color)
                        }
                        .scaleEffect(showPoints ? 1 : 0)
                        .animation(
                            .spring()
                            .delay(Double(index) * 0.1),
                            value: showPoints
                        )
                    }
                    .padding(.horizontal, 30)
                }
            }
            .onAppear { showPoints = true }
        }
    }
    
    var stablefordPoints: [(score: String, points: Int, color: Color)] {
        [
            ("Eagle or better", 4, .yellow),
            ("Birdie", 3, .green),
            ("Par", 2, .blue),
            ("Bogey", 1, .orange),
            ("Double Bogey+", 0, .red)
        ]
    }
}

struct StablefordExample: View {
    @State private var currentHole = 0
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Example Round",
            subtitle: "9 holes played"
        ) {
            VStack(spacing: 20) {
                // Scorecard grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(0..<9) { hole in
                            VStack(spacing: 8) {
                                Text("H\(hole + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Text(holeScores[hole])
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    Circle()
                                        .fill(pointColors[hole])
                                        .frame(width: 30, height: 30)
                                    
                                    Text("\(holePoints[hole])")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(currentHole >= hole ? 1 : 0)
                                .animation(
                                    .spring()
                                    .delay(Double(hole) * 0.1),
                                    value: currentHole
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Total
                HStack {
                    Text("Total Points:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(currentHole > 0 ? holePoints[0...min(currentHole-1, 8)].reduce(0, +) : 0)")
                        .font(.title2.bold())
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
                    if currentHole < 9 {
                        currentHole += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    var holeScores: [String] {
        ["Par", "Bogey", "Birdie", "Par", "Eagle", "Bogey", "Par", "Double", "Par"]
    }
    
    var holePoints: [Int] {
        [2, 1, 3, 2, 4, 1, 2, 0, 2]
    }
    
    var pointColors: [Color] {
        [.blue, .orange, .green, .blue, .yellow, .orange, .blue, .red, .blue]
    }
}

struct StablefordStrategy: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Maximize your points"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                ForEach(stablefordTips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 30, height: 30)
                            
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.purple)
                        }
                        .opacity(showTips ? 1 : 0)
                        .scaleEffect(showTips ? 1 : 0.5)
                        .animation(
                            .spring()
                            .delay(Double(index) * 0.15),
                            value: showTips
                        )
                        
                        Text(stablefordTips[index])
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(showTips ? 1 : 0)
                            .animation(
                                .easeOut(duration: 0.5)
                                .delay(Double(index) * 0.15),
                                value: showTips
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .onAppear { showTips = true }
        }
    }
    
    var stablefordTips: [String] {
        [
            "Pick up after double bogey - no points anyway",
            "Be aggressive on par 5s - eagle is 4 points!",
            "Steady play wins - pars add up quickly",
            "Don't chase lost balls - save time and energy"
        ]
    }
}

// MARK: - Other Format Slides (simplified for brevity)

struct AlternateShotSlides {
    static var slides: [AnyView] {
        [
            AnyView(AlternateShotSetup()),
            AnyView(AlternateShotGameplay()),
            AnyView(AlternateShotStrategy())
        ]
    }
}

struct AlternateShotSetup: View {
    var body: some View {
        DiagramSlideTemplate(title: "ALTERNATE SHOT", subtitle: "Partners take turns") {
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    PlayerIcon(color: .blue, label: "Player A", number: "1")
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title)
                        .foregroundColor(.white)
                    PlayerIcon(color: .orange, label: "Player B", number: "2")
                }
                
                Text("One ball, alternating shots")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

struct AlternateShotGameplay: View {
    @State private var currentShot = 0
    
    var body: some View {
        DiagramSlideTemplate(title: "Shot Sequence", subtitle: "Taking turns") {
            VStack(spacing: 15) {
                ForEach(0..<5) { shot in
                    HStack {
                        Image(systemName: shotIcons[shot])
                            .frame(width: 30)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(shotDescriptions[shot])
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Circle()
                            .fill(shot % 2 == 0 ? Color.blue : Color.orange)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(shot % 2 == 0 ? "A" : "B")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            )
                            .opacity(currentShot >= shot ? 1 : 0.3)
                            .scaleEffect(currentShot == shot ? 1.2 : 1)
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(), value: currentShot)
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                    if currentShot < 4 {
                        currentShot += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    var shotIcons: [String] {
        ["figure.golf", "arrow.up.right", "sportscourt", "target", "flag.fill"]
    }
    
    var shotDescriptions: [String] {
        ["Tee shot", "Approach", "Chip", "First putt", "Tap in"]
    }
}

struct AlternateShotStrategy: View {
    var body: some View {
        DiagramSlideTemplate(title: "Key Strategy", subtitle: "Work as a team") {
            VStack(alignment: .leading, spacing: 20) {
                StrategyPoint(
                    icon: "person.2.fill",
                    text: "Consider who tees off on par 3s",
                    color: .blue
                )
                StrategyPoint(
                    icon: "target",
                    text: "Leave makeable putts for partner",
                    color: .green
                )
                StrategyPoint(
                    icon: "checkmark.shield",
                    text: "Play safe when partner is struggling",
                    color: .orange
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// Additional format slides structures
struct MatchPlaySlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Match Play"))]
    }
}

struct SkinsSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Skins"))]
    }
}

struct NassauSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Nassau"))]
    }
}

struct VegasSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Vegas"))]
    }
}

struct WolfSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Wolf"))]
    }
}

struct BingoBangoBongoSlides {
    static var slides: [AnyView] {
        [AnyView(DefaultDiagramSlide(title: "Bingo Bango Bongo"))]
    }
}

// MARK: - Helper Components

struct PlayerIcon: View {
    let color: Color
    let label: String
    let number: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.golf")
                .font(.system(size: 35))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

struct StrategyPoint: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Constants

let playerColors: [Color] = [
    .blue,
    .green,
    .orange,
    .purple
]