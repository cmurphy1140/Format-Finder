import SwiftUI

// MARK: - Diagram Slideshow Container

struct FormatDiagramSlideshow: View {
    let format: GolfFormat
    @Binding var isPresented: Bool
    @State private var currentSlide = 0
    
    init(format: GolfFormat, isPresented: Binding<Bool>) {
        self.format = format
        self._isPresented = isPresented
    }
    
    // Overload for backward compatibility
    init(formatName: String) {
        self.format = GolfFormat.allFormats.first { $0.name == formatName } ?? GolfFormat.allFormats[0]
        self._isPresented = .constant(true)
    }
    
    var formatName: String { format.name }
    
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
        case "Chapman":
            return ChapmanSlides.slides
        case "Four-Ball":
            return FourBallSlides.slides
        default:
            return [AnyView(DefaultDiagramSlide(title: formatName))]
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.2),
                    Color(red: 0.05, green: 0.25, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("\(formatName) Tutorial")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                
                // Slide content with click navigation
                ZStack {
                    TabView(selection: $currentSlide) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            slides[index]
                                .tag(index)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if currentSlide < slides.count - 1 {
                                            currentSlide += 1
                                        } else {
                                            isPresented = false
                                        }
                                    }
                                }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Navigation hint overlay
                    VStack {
                        Spacer()
                        HStack {
                            if currentSlide > 0 {
                                Image(systemName: "chevron.left")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading)
                            }
                            Spacer()
                            if currentSlide < slides.count - 1 {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.trailing)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
                .frame(height: 400)
            
                
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
                
                // Click instruction
                Text(currentSlide == slides.count - 1 ? "Tap to close" : "Tap anywhere to continue")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)
                    .padding(.bottom, 20)
            }
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

// MARK: - Match Play Format Slides

struct MatchPlaySlides {
    static var slides: [AnyView] {
        [
            AnyView(MatchPlaySetupSlide()),
            AnyView(MatchPlayScoringSlide()),
            AnyView(MatchPlayStatusSlide()),
            AnyView(MatchPlayStrategySlide()),
            AnyView(MatchPlayEndgameSlide())
        ]
    }
}

struct MatchPlaySetupSlide: View {
    @State private var showPlayers = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "MATCH PLAY - Setup",
            subtitle: "Head-to-Head Competition"
        ) {
            VStack(spacing: 25) {
                // VS Display
                HStack(spacing: 40) {
                    PlayerIcon(color: .blue, label: "Player/Team A", number: "1")
                        .scaleEffect(showPlayers ? 1 : 0)
                        .animation(.spring(response: 0.5), value: showPlayers)
                    
                    Text("VS")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.yellow)
                        .scaleEffect(showPlayers ? 1.2 : 0)
                        .animation(.spring(response: 0.5).delay(0.3), value: showPlayers)
                    
                    PlayerIcon(color: .red, label: "Player/Team B", number: "2")
                        .scaleEffect(showPlayers ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.2), value: showPlayers)
                }
                
                Text("Win holes, not strokes")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                    )
                    .opacity(showPlayers ? 1 : 0)
                    .animation(.easeIn.delay(0.5), value: showPlayers)
            }
            .onAppear { showPlayers = true }
        }
    }
}

struct MatchPlayScoringSlide: View {
    @State private var showScores = false
    @State private var winner: Int? = nil
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring Each Hole",
            subtitle: "Lowest score wins the hole"
        ) {
            VStack(spacing: 20) {
                // Hole example
                Text("Hole 5 - Par 4")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 50) {
                    VStack {
                        Text("Player A")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("4")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                            .scaleEffect(showScores ? 1 : 0)
                            .animation(.spring().delay(0.3), value: showScores)
                    }
                    
                    Image(systemName: winner == 0 ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                        .scaleEffect(winner == 0 ? 1.2 : 1)
                        .animation(.spring(), value: winner)
                    
                    VStack {
                        Text("Player B")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("5")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.red)
                            .scaleEffect(showScores ? 1 : 0)
                            .animation(.spring().delay(0.5), value: showScores)
                    }
                }
                
                Text("Player A wins hole")
                    .font(.headline)
                    .foregroundColor(.green)
                    .opacity(winner == 0 ? 1 : 0)
                    .animation(.easeIn, value: winner)
            }
            .onAppear {
                showScores = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    winner = 0
                }
            }
        }
    }
}

struct MatchPlayStatusSlide: View {
    @State private var status = 0
    let statuses = ["All Square", "1 Up", "2 Up", "3 Up"]
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Match Status",
            subtitle: "Track who's ahead"
        ) {
            VStack(spacing: 25) {
                // Status display
                Text(statuses[status])
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.yellow)
                    .animation(.spring(), value: status)
                
                // Visual representation
                HStack(spacing: 8) {
                    ForEach(0..<9) { hole in
                        Circle()
                            .fill(hole < status ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 25, height: 25)
                            .overlay(
                                Text("\(hole + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                Text("Holes remaining: \(9 - status)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    withAnimation {
                        status = (status + 1) % 4
                    }
                    if status == 3 {
                        timer.invalidate()
                    }
                }
            }
        }
    }
}

struct MatchPlayStrategySlide: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Tactical considerations"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                StrategyPoint(
                    icon: "lightbulb.fill",
                    text: "Play the opponent, not the course",
                    color: .yellow
                )
                .opacity(showTips ? 1 : 0)
                .animation(.easeIn, value: showTips)
                
                StrategyPoint(
                    icon: "flag.fill",
                    text: "Be aggressive when down",
                    color: .orange
                )
                .opacity(showTips ? 1 : 0)
                .animation(.easeIn.delay(0.2), value: showTips)
                
                StrategyPoint(
                    icon: "shield.fill",
                    text: "Play safe when ahead",
                    color: .green
                )
                .opacity(showTips ? 1 : 0)
                .animation(.easeIn.delay(0.4), value: showTips)
            }
            .onAppear { showTips = true }
        }
    }
}

struct MatchPlayEndgameSlide: View {
    @State private var showResult = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Winning the Match",
            subtitle: "Match ends when mathematically decided"
        ) {
            VStack(spacing: 20) {
                Text("3 & 2")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.yellow)
                    .scaleEffect(showResult ? 1 : 0)
                    .animation(.spring(), value: showResult)
                
                Text("3 holes up with 2 to play")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(showResult ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showResult)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                    .scaleEffect(showResult ? 1 : 0)
                    .animation(.spring().delay(0.5), value: showResult)
            }
            .onAppear { showResult = true }
        }
    }
}

// MARK: - Skins Format Slides

struct SkinsSlides {
    static var slides: [AnyView] {
        [
            AnyView(SkinsSetupSlide()),
            AnyView(SkinsBasicRulesSlide()),
            AnyView(SkinsCarryoverSlide()),
            AnyView(SkinsValidationSlide()),
            AnyView(SkinsPayoutSlide())
        ]
    }
}

struct SkinsSetupSlide: View {
    @State private var showElements = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "SKINS - Setup",
            subtitle: "Monetary game format"
        ) {
            VStack(spacing: 25) {
                // Money pot visual
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .scaleEffect(showElements ? 1 : 0)
                    .animation(.spring(), value: showElements)
                
                Text("Each hole worth a 'skin'")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(showElements ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showElements)
                
                HStack(spacing: 30) {
                    ForEach(0..<4) { i in
                        VStack {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 30))
                                .foregroundColor(playerColors[i])
                            Text("$5/hole")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .scaleEffect(showElements ? 1 : 0)
                        .animation(.spring().delay(Double(i) * 0.1 + 0.5), value: showElements)
                    }
                }
            }
            .onAppear { showElements = true }
        }
    }
}

struct SkinsBasicRulesSlide: View {
    @State private var showRules = false
    @State private var winner: Int? = nil
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Basic Rules",
            subtitle: "Lowest score wins the skin"
        ) {
            VStack(spacing: 20) {
                Text("Hole 3 Results")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    ForEach(0..<4) { i in
                        VStack {
                            Circle()
                                .fill(i == 1 ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(i == 1 ? "3" : i == 0 ? "4" : "5")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                                .scaleEffect(showRules ? 1 : 0)
                                .animation(.spring().delay(Double(i) * 0.1), value: showRules)
                            
                            Text("P\(i + 1)")
                                .font(.caption)
                                .foregroundColor(playerColors[i])
                        }
                    }
                }
                
                if winner == 1 {
                    Text("Player 2 wins the skin!")
                        .font(.headline)
                        .foregroundColor(.green)
                        .transition(.scale)
                }
            }
            .onAppear { 
                showRules = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { winner = 1 }
                }
            }
        }
    }
}

struct SkinsCarryoverSlide: View {
    @State private var carryover = 0
    @State private var showExplanation = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Carryovers",
            subtitle: "Ties carry value forward"
        ) {
            VStack(spacing: 20) {
                // Visual carryover
                HStack(spacing: 15) {
                    ForEach(0..<3) { hole in
                        VStack {
                            Text("Hole \(hole + 4)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(hole < 2 ? Color.orange : Color.green)
                                .frame(width: 60, height: 40)
                                .overlay(
                                    Text(hole < 2 ? "TIE" : "WIN")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                )
                            
                            Text("$\(hole < 2 ? 5 : 15)")
                                .font(.caption.bold())
                                .foregroundColor(hole < 2 ? .orange : .green)
                        }
                        .opacity(Double(hole + 1) <= Double(carryover) ? 1 : 0.3)
                        .scaleEffect(Double(hole + 1) <= Double(carryover) ? 1 : 0.8)
                        .animation(.spring().delay(Double(hole) * 0.3), value: carryover)
                    }
                }
                
                if showExplanation {
                    Text("2 ties = 3 skins on hole 6!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .transition(.scale)
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                    withAnimation {
                        carryover += 1
                        if carryover == 3 {
                            showExplanation = true
                            timer.invalidate()
                        }
                    }
                }
            }
        }
    }
}

struct SkinsValidationSlide: View {
    @State private var showValidation = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Validation Rules",
            subtitle: "Protect the field"
        ) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .scaleEffect(showValidation ? 1 : 0)
                    .animation(.spring(), value: showValidation)
                
                VStack(alignment: .leading, spacing: 15) {
                    StrategyPoint(
                        icon: "xmark.circle",
                        text: "No gimmes on skin holes",
                        color: .red
                    )
                    
                    StrategyPoint(
                        icon: "flag.2.crossed",
                        text: "Must hole out for validation",
                        color: .orange
                    )
                    
                    StrategyPoint(
                        icon: "checkmark.circle",
                        text: "All players verify winner",
                        color: .green
                    )
                }
                .opacity(showValidation ? 1 : 0)
                .animation(.easeIn.delay(0.3), value: showValidation)
            }
            .onAppear { showValidation = true }
        }
    }
}

struct SkinsPayoutSlide: View {
    @State private var showPayout = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Payout",
            subtitle: "End of round settlement"
        ) {
            VStack(spacing: 20) {
                Text("18 Holes Complete")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    ForEach(0..<4) { i in
                        HStack {
                            Text("Player \(i + 1)")
                                .foregroundColor(playerColors[i])
                            Spacer()
                            Text("\(i == 0 ? 6 : i == 1 ? 8 : i == 2 ? 3 : 1) skins")
                            Spacer()
                            Text("$\(i == 0 ? 30 : i == 1 ? 40 : i == 2 ? 15 : 5)")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                        .opacity(showPayout ? 1 : 0)
                        .offset(x: showPayout ? 0 : -20)
                        .animation(.easeOut.delay(Double(i) * 0.1), value: showPayout)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
            }
            .onAppear { showPayout = true }
        }
    }
}

// MARK: - Nassau Format Slides

struct NassauSlides {
    static var slides: [AnyView] {
        [
            AnyView(NassauSetupSlide()),
            AnyView(NassauThreeMatchesSlide()),
            AnyView(NassauScoringSlide()),
            AnyView(NassauPressSlide()),
            AnyView(NassauPayoutSlide())
        ]
    }
}

struct NassauSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "NASSAU - Setup",
            subtitle: "Three matches in one"
        ) {
            VStack(spacing: 25) {
                // Three match visualization
                HStack(spacing: 20) {
                    ForEach(["Front 9", "Back 9", "Overall"], id: \.self) { match in
                        VStack {
                            Image(systemName: match == "Overall" ? "flag.checkered" : "flag.fill")
                                .font(.system(size: 35))
                                .foregroundColor(match == "Front 9" ? .blue : match == "Back 9" ? .green : .orange)
                            
                            Text(match)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .scaleEffect(showSetup ? 1 : 0)
                        .animation(.spring().delay(match == "Front 9" ? 0 : match == "Back 9" ? 0.2 : 0.4), value: showSetup)
                    }
                }
                
                Text("$2-$2-$2 Nassau")
                    .font(.headline)
                    .foregroundColor(.yellow)
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: showSetup)
            }
            .onAppear { showSetup = true }
        }
    }
}

struct NassauThreeMatchesSlide: View {
    @State private var highlightMatch = 0
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Three Separate Bets",
            subtitle: "Win, lose, or tie each"
        ) {
            VStack(spacing: 20) {
                // Holes visualization
                VStack(spacing: 15) {
                    // Front 9
                    HStack {
                        Text("Front:")
                            .foregroundColor(.white)
                            .frame(width: 50)
                        ForEach(1...9, id: \.self) { hole in
                            Circle()
                                .fill(highlightMatch == 0 ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Text("\(hole)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // Back 9
                    HStack {
                        Text("Back:")
                            .foregroundColor(.white)
                            .frame(width: 50)
                        ForEach(10...18, id: \.self) { hole in
                            Circle()
                                .fill(highlightMatch == 1 ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Text("\(hole)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // Overall indicator
                    RoundedRectangle(cornerRadius: 8)
                        .fill(highlightMatch == 2 ? Color.orange : Color.gray.opacity(0.3))
                        .frame(height: 30)
                        .overlay(
                            Text("Overall: All 18 Holes")
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    withAnimation {
                        highlightMatch = (highlightMatch + 1) % 3
                    }
                }
            }
        }
    }
}

struct NassauScoringSlide: View {
    @State private var showScores = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Match Play Scoring",
            subtitle: "Track each match separately"
        ) {
            VStack(spacing: 20) {
                // Score tracking
                VStack(spacing: 15) {
                    ScoreRow(label: "Front 9", scoreA: "2 UP", scoreB: "2 DN", color: .blue, show: showScores)
                    ScoreRow(label: "Back 9", scoreA: "AS", scoreB: "AS", color: .green, show: showScores)
                    ScoreRow(label: "Overall", scoreA: "1 UP", scoreB: "1 DN", color: .orange, show: showScores)
                }
                
                Text("Can win 0, 1, 2, or all 3 matches")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showScores ? 1 : 0)
                    .animation(.easeIn.delay(0.5), value: showScores)
            }
            .onAppear { showScores = true }
        }
    }
}

struct NassauPressSlide: View {
    @State private var showPress = false
    @State private var pressCount = 0
    
    var body: some View {
        DiagramSlideTemplate(
            title: "The Press",
            subtitle: "Double down when losing"
        ) {
            VStack(spacing: 20) {
                Text("Down 2 holes?")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button(action: {}) {
                    Text("PRESS!")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red)
                        )
                }
                .scaleEffect(showPress ? 1.2 : 1)
                .animation(.spring(), value: showPress)
                
                Text("Starts new $2 match from current hole")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                // Press indicators
                HStack {
                    ForEach(0..<pressCount, id: \.self) { i in
                        Text("Press #\(i + 1)")
                            .font(.caption)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red.opacity(0.3))
                            )
                            .foregroundColor(.white)
                            .transition(.scale)
                    }
                }
            }
            .onAppear { 
                showPress = true
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    withAnimation {
                        pressCount += 1
                        if pressCount >= 3 {
                            timer.invalidate()
                        }
                    }
                }
            }
        }
    }
}

struct NassauPayoutSlide: View {
    @State private var showPayout = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Final Payout",
            subtitle: "Add up all matches"
        ) {
            VStack(spacing: 15) {
                Text("Player A vs Player B")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 10) {
                    PayoutRow(label: "Front 9:", result: "A wins", value: "+$2", show: showPayout, delay: 0)
                    PayoutRow(label: "Back 9:", result: "B wins", value: "-$2", show: showPayout, delay: 0.1)
                    PayoutRow(label: "Overall:", result: "Tied", value: "$0", show: showPayout, delay: 0.2)
                    PayoutRow(label: "Press 1:", result: "A wins", value: "+$2", show: showPayout, delay: 0.3)
                    PayoutRow(label: "Press 2:", result: "A wins", value: "+$2", show: showPayout, delay: 0.4)
                    
                    Divider().background(Color.white.opacity(0.3))
                    
                    HStack {
                        Text("Total:")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("+$4")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .opacity(showPayout ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: showPayout)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
            }
            .onAppear { showPayout = true }
        }
    }
}

// MARK: - Vegas Format Slides

struct VegasSlides {
    static var slides: [AnyView] {
        [
            AnyView(VegasSetupSlide()),
            AnyView(VegasScoringSlide()),
            AnyView(VegasFlipRuleSlide()),
            AnyView(VegasStrategySlide()),
            AnyView(VegasExampleSlide())
        ]
    }
}

struct VegasSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "VEGAS - Setup",
            subtitle: "Team score combinations"
        ) {
            VStack(spacing: 25) {
                // Teams display
                HStack(spacing: 40) {
                    VStack {
                        Text("Team A")
                            .font(.headline)
                            .foregroundColor(.blue)
                        HStack {
                            Image(systemName: "figure.golf")
                                .foregroundColor(.blue)
                            Image(systemName: "figure.golf")
                                .foregroundColor(.blue)
                        }
                        .font(.system(size: 30))
                    }
                    .scaleEffect(showSetup ? 1 : 0)
                    .animation(.spring(), value: showSetup)
                    
                    Text("VS")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                        .scaleEffect(showSetup ? 1 : 0)
                        .animation(.spring().delay(0.2), value: showSetup)
                    
                    VStack {
                        Text("Team B")
                            .font(.headline)
                            .foregroundColor(.red)
                        HStack {
                            Image(systemName: "figure.golf")
                                .foregroundColor(.red)
                            Image(systemName: "figure.golf")
                                .foregroundColor(.red)
                        }
                        .font(.system(size: 30))
                    }
                    .scaleEffect(showSetup ? 1 : 0)
                    .animation(.spring().delay(0.1), value: showSetup)
                }
                
                Text("Combine scores for team total")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn.delay(0.4), value: showSetup)
            }
            .onAppear { showSetup = true }
        }
    }
}

struct VegasScoringSlide: View {
    @State private var showScoring = false
    @State private var showResult = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Score Combination",
            subtitle: "Low score first, high second"
        ) {
            VStack(spacing: 20) {
                // Team A scores
                VStack {
                    Text("Team A")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 20) {
                        Text("4")
                            .font(.largeTitle.bold())
                            .foregroundColor(.blue)
                        Text("+")
                            .foregroundColor(.white)
                        Text("5")
                            .font(.largeTitle.bold())
                            .foregroundColor(.blue)
                        Text("=")
                            .foregroundColor(.white)
                        Text(showResult ? "45" : "??")
                            .font(.largeTitle.bold())
                            .foregroundColor(.yellow)
                    }
                }
                .opacity(showScoring ? 1 : 0)
                .animation(.easeIn, value: showScoring)
                
                // Team B scores
                VStack {
                    Text("Team B")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 20) {
                        Text("3")
                            .font(.largeTitle.bold())
                            .foregroundColor(.red)
                        Text("+")
                            .foregroundColor(.white)
                        Text("6")
                            .font(.largeTitle.bold())
                            .foregroundColor(.red)
                        Text("=")
                            .foregroundColor(.white)
                        Text(showResult ? "36" : "??")
                            .font(.largeTitle.bold())
                            .foregroundColor(.yellow)
                    }
                }
                .opacity(showScoring ? 1 : 0)
                .animation(.easeIn.delay(0.3), value: showScoring)
                
                if showResult {
                    Text("Team B wins 9 points (45-36)")
                        .font(.headline)
                        .foregroundColor(.green)
                        .transition(.scale)
                }
            }
            .onAppear {
                showScoring = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showResult = true }
                }
            }
        }
    }
}

struct VegasFlipRuleSlide: View {
    @State private var showFlip = false
    @State private var flipped = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "The Flip Rule",
            subtitle: "Birdie flips opponent's score"
        ) {
            VStack(spacing: 25) {
                Text("Team A makes birdie!")
                    .font(.headline)
                    .foregroundColor(.green)
                
                // Normal scoring
                VStack {
                    Text("Normal: 3 + 6 = 36")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.down")
                        .font(.title)
                        .foregroundColor(.yellow)
                        .opacity(showFlip ? 1 : 0)
                        .animation(.easeIn.delay(0.5), value: showFlip)
                    
                    Text(flipped ? "FLIPPED: 6 + 3 = 63" : "")
                        .font(.headline.bold())
                        .foregroundColor(.red)
                        .scaleEffect(flipped ? 1.2 : 1)
                        .animation(.spring(), value: flipped)
                }
                
                if flipped {
                    Text("27 point swing! (63-36)")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .transition(.scale)
                }
            }
            .onAppear {
                showFlip = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { flipped = true }
                }
            }
        }
    }
}

struct VegasStrategySlide: View {
    @State private var showStrategy = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "High risk, high reward"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                StrategyPoint(
                    icon: "sparkles",
                    text: "Birdies are powerful weapons",
                    color: .yellow
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn, value: showStrategy)
                
                StrategyPoint(
                    icon: "exclamationmark.triangle",
                    text: "Big numbers hurt badly",
                    color: .orange
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.2), value: showStrategy)
                
                StrategyPoint(
                    icon: "person.2.fill",
                    text: "Partner consistency is key",
                    color: .green
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.4), value: showStrategy)
            }
            .onAppear { showStrategy = true }
        }
    }
}

struct VegasExampleSlide: View {
    @State private var showExample = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring Example",
            subtitle: "Full hole breakdown"
        ) {
            VStack(spacing: 15) {
                Text("Par 4 - Hole 7")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team A")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                        Text("P1: 3 (birdie)")
                            .font(.caption)
                        Text("P2: 5")
                            .font(.caption)
                        Text("Score: 35")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Team B")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                        Text("P3: 4")
                            .font(.caption)
                        Text("P4: 7")
                            .font(.caption)
                        Text("Score: 74 (flipped!)")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.3))
                )
                .opacity(showExample ? 1 : 0)
                .animation(.easeIn, value: showExample)
                
                Text("Team A wins 39 points!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .opacity(showExample ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showExample)
            }
            .onAppear { showExample = true }
        }
    }
}

// MARK: - Wolf Format Slides

struct WolfSlides {
    static var slides: [AnyView] {
        [
            AnyView(WolfSetupSlide()),
            AnyView(WolfRotationSlide()),
            AnyView(WolfSelectionSlide()),
            AnyView(WolfLoneWolfSlide()),
            AnyView(WolfScoringSlide())
        ]
    }
}

struct WolfSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "WOLF - Setup",
            subtitle: "Rotating captain format"
        ) {
            VStack(spacing: 25) {
                // Wolf icon
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(showSetup ? 0 : -45))
                    .scaleEffect(showSetup ? 1 : 0)
                    .animation(.spring(), value: showSetup)
                
                Text("One player is the 'Wolf' each hole")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showSetup)
                
                // Players
                HStack(spacing: 25) {
                    ForEach(0..<4) { i in
                        VStack {
                            Image(systemName: i == 0 ? "crown.fill" : "figure.golf")
                                .font(.system(size: 30))
                                .foregroundColor(i == 0 ? .orange : playerColors[i])
                            Text(i == 0 ? "Wolf" : "P\(i + 1)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .scaleEffect(showSetup ? 1 : 0)
                        .animation(.spring().delay(Double(i) * 0.1 + 0.4), value: showSetup)
                    }
                }
            }
            .onAppear { showSetup = true }
        }
    }
}

struct WolfRotationSlide: View {
    @State private var wolfIndex = 0
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Wolf Rotation",
            subtitle: "Changes every hole"
        ) {
            VStack(spacing: 25) {
                Text("Hole \(wolfIndex + 1)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 25) {
                    ForEach(0..<4) { i in
                        VStack {
                            Image(systemName: i == wolfIndex ? "crown.fill" : "figure.golf")
                                .font(.system(size: 35))
                                .foregroundColor(i == wolfIndex ? .orange : playerColors[i])
                                .animation(.spring(), value: wolfIndex)
                            
                            Text("P\(i + 1)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Text("Rotates in order 1-2-3-4")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    withAnimation {
                        wolfIndex = (wolfIndex + 1) % 4
                    }
                }
            }
        }
    }
}

struct WolfSelectionSlide: View {
    @State private var showSelection = false
    @State private var selectedPartner: Int? = nil
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Partner Selection",
            subtitle: "Wolf chooses after each tee shot"
        ) {
            VStack(spacing: 20) {
                Text("Watch tee shots...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    ForEach(0..<3) { i in
                        VStack {
                            Circle()
                                .fill(i == selectedPartner ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "figure.golf")
                                        .foregroundColor(playerColors[i + 1])
                                )
                            
                            Text("P\(i + 2)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .scaleEffect(showSelection ? 1 : 0)
                        .animation(.spring().delay(Double(i) * 0.3), value: showSelection)
                    }
                }
                
                if selectedPartner != nil {
                    Text("Wolf picks Player \(selectedPartner! + 2)")
                        .font(.headline)
                        .foregroundColor(.green)
                        .transition(.scale)
                }
            }
            .onAppear {
                showSelection = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { selectedPartner = 1 }
                }
            }
        }
    }
}

struct WolfLoneWolfSlide: View {
    @State private var showLoneWolf = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Lone Wolf",
            subtitle: "Go alone for double points"
        ) {
            VStack(spacing: 25) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .scaleEffect(showLoneWolf ? 1.2 : 0)
                    .animation(.spring(), value: showLoneWolf)
                
                Text("1 vs 3")
                    .font(.largeTitle.bold())
                    .foregroundColor(.yellow)
                    .opacity(showLoneWolf ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showLoneWolf)
                
                VStack(spacing: 10) {
                    Text("Double points if Wolf wins")
                        .foregroundColor(.green)
                    Text("Triple points for 'Blind Wolf'")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                .opacity(showLoneWolf ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: showLoneWolf)
            }
            .onAppear { showLoneWolf = true }
        }
    }
}

struct WolfScoringSlide: View {
    @State private var showScoring = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring",
            subtitle: "Points based on format"
        ) {
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 12) {
                    ScoringRow(icon: "person.2", label: "2v2:", points: "1 point", show: showScoring, delay: 0)
                    ScoringRow(icon: "person", label: "Lone Wolf:", points: "2 points", show: showScoring, delay: 0.2)
                    ScoringRow(icon: "eyes", label: "Blind Wolf:", points: "3 points", show: showScoring, delay: 0.4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
                
                Text("Low net score wins hole")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showScoring ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: showScoring)
            }
            .onAppear { showScoring = true }
        }
    }
}

// MARK: - Bingo Bango Bongo Slides

struct BingoBangoBongoSlides {
    static var slides: [AnyView] {
        [
            AnyView(BBBSetupSlide()),
            AnyView(BBBThreePointsSlide()),
            AnyView(BBBOrderMattersSlide()),
            AnyView(BBBScoringSlide()),
            AnyView(BBBStrategySlide())
        ]
    }
}

struct BBBSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "BINGO BANGO BONGO",
            subtitle: "Three points per hole"
        ) {
            VStack(spacing: 25) {
                HStack(spacing: 30) {
                    ForEach(["BINGO", "BANGO", "BONGO"], id: \.self) { word in
                        Text(word)
                            .font(.headline.bold())
                            .foregroundColor(word == "BINGO" ? .blue : word == "BANGO" ? .green : .orange)
                            .scaleEffect(showSetup ? 1 : 0)
                            .animation(.spring().delay(word == "BINGO" ? 0 : word == "BANGO" ? 0.2 : 0.4), value: showSetup)
                    }
                }
                
                Text("Points for achievements, not score")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: showSetup)
            }
            .onAppear { showSetup = true }
        }
    }
}

struct BBBThreePointsSlide: View {
    @State private var showPoints = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Three Points Available",
            subtitle: "Different achievements"
        ) {
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    PointRow(
                        title: "BINGO",
                        subtitle: "First on green",
                        color: .blue,
                        icon: "flag.fill",
                        show: showPoints,
                        delay: 0
                    )
                    
                    PointRow(
                        title: "BANGO",
                        subtitle: "Closest to pin (on green)",
                        color: .green,
                        icon: "target",
                        show: showPoints,
                        delay: 0.2
                    )
                    
                    PointRow(
                        title: "BONGO",
                        subtitle: "First to hole out",
                        color: .orange,
                        icon: "checkmark.circle.fill",
                        show: showPoints,
                        delay: 0.4
                    )
                }
            }
            .onAppear { showPoints = true }
        }
    }
}

struct BBBOrderMattersSlide: View {
    @State private var animateOrder = false
    @State private var currentStep = 0
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Order Matters!",
            subtitle: "Farthest away plays first"
        ) {
            VStack(spacing: 20) {
                // Golf green visualization
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 180, height: 180)
                    
                    // Flag
                    Image(systemName: "flag.fill")
                        .foregroundColor(.yellow)
                        .position(x: 90, y: 90)
                    
                    // Player positions
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(playerColors[i])
                            .frame(width: 20, height: 20)
                            .position(
                                x: i == 0 ? 50 : i == 1 ? 130 : 90,
                                y: i == 0 ? 140 : i == 1 ? 120 : 40
                            )
                            .overlay(
                                Text("\(i + 1)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(currentStep == i ? 1.3 : 1)
                            .animation(.spring(), value: currentStep)
                    }
                }
                
                Text(currentStep == 0 ? "P1 putts first (farthest)" :
                     currentStep == 1 ? "P2 putts second" :
                     "P3 putts last (closest)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .animation(.easeIn, value: currentStep)
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    withAnimation {
                        currentStep = (currentStep + 1) % 3
                    }
                }
            }
        }
    }
}

struct BBBScoringSlide: View {
    @State private var showScoring = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Scoring Example",
            subtitle: "Hole 5 - Par 4"
        ) {
            VStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.blue)
                        Text("BINGO: Player 2")
                            .foregroundColor(.white)
                        Spacer()
                        Text("+1")
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.green)
                        Text("BANGO: Player 4")
                            .foregroundColor(.white)
                        Spacer()
                        Text("+1")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("BONGO: Player 1")
                            .foregroundColor(.white)
                        Spacer()
                        Text("+1")
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
                .opacity(showScoring ? 1 : 0)
                .offset(y: showScoring ? 0 : 20)
                .animation(.easeOut, value: showScoring)
                
                Text("3 different winners possible!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showScoring ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showScoring)
            }
            .onAppear { showScoring = true }
        }
    }
}

struct BBBStrategySlide: View {
    @State private var showStrategy = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Different from stroke play"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                StrategyPoint(
                    icon: "arrow.up.forward",
                    text: "Lay up for better angle",
                    color: .blue
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn, value: showStrategy)
                
                StrategyPoint(
                    icon: "clock.fill",
                    text: "Play quickly when ahead",
                    color: .orange
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.2), value: showStrategy)
                
                StrategyPoint(
                    icon: "flag.2.crossed",
                    text: "Position matters more than score",
                    color: .green
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.4), value: showStrategy)
            }
            .onAppear { showStrategy = true }
        }
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

// MARK: - Additional Helper Components

struct ScoreRow: View {
    let label: String
    let scoreA: String
    let scoreB: String
    let color: Color
    let show: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(color)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(scoreA)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("vs")
                .foregroundColor(.white.opacity(0.5))
            
            Text(scoreB)
                .font(.headline)
                .foregroundColor(.red)
        }
        .padding(.horizontal)
        .opacity(show ? 1 : 0)
        .animation(.easeIn, value: show)
    }
}

struct PayoutRow: View {
    let label: String
    let result: String
    let value: String
    let show: Bool
    let delay: Double
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(result)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(value.contains("+") ? .green : value.contains("-") ? .red : .white)
        }
        .opacity(show ? 1 : 0)
        .animation(.easeIn.delay(delay), value: show)
    }
}

struct ScoringRow: View {
    let icon: String
    let label: String
    let points: String
    let show: Bool
    let delay: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            Text(label)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(points)
                .font(.headline)
                .foregroundColor(.green)
        }
        .opacity(show ? 1 : 0)
        .animation(.easeIn.delay(delay), value: show)
    }
}

struct PointRow: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let show: Bool
    let delay: Double
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .opacity(show ? 1 : 0)
        .offset(x: show ? 0 : -20)
        .animation(.easeOut.delay(delay), value: show)
    }
}

// MARK: - Chapman Format Slides

struct ChapmanSlides {
    static var slides: [AnyView] {
        [
            AnyView(ChapmanSetupSlide()),
            AnyView(ChapmanBothDriveSlide()),
            AnyView(ChapmanSwitchBallsSlide()),
            AnyView(ChapmanAlternateSlide()),
            AnyView(ChapmanStrategySlide())
        ]
    }
}

struct ChapmanSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "CHAPMAN - Setup",
            subtitle: "Complex partner format"
        ) {
            VStack(spacing: 25) {
                Text("2-Person Teams")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 50) {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                            Image(systemName: "figure.golf")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        Text("Team A")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(showSetup ? 1 : 0)
                    .animation(.spring(), value: showSetup)
                    
                    Text("VS")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                        .scaleEffect(showSetup ? 1 : 0)
                        .animation(.spring().delay(0.2), value: showSetup)
                    
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                            Image(systemName: "figure.golf")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                        }
                        Text("Team B")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(showSetup ? 1 : 0)
                    .animation(.spring().delay(0.1), value: showSetup)
                }
                
                Text("Mix of scramble and alternate shot")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn.delay(0.4), value: showSetup)
            }
            .onAppear { showSetup = true }
        }
    }
}

struct ChapmanBothDriveSlide: View {
    @State private var showDrives = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Step 1: Both Drive",
            subtitle: "Each partner hits tee shot"
        ) {
            VStack(spacing: 20) {
                // Visual representation of both drives
                ZStack {
                    // Fairway
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 200, height: 250)
                    
                    // Tee box
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 100, height: 30)
                        .position(x: 100, y: 230)
                    
                    // Partner A drive
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .position(x: showDrives ? 70 : 100, y: showDrives ? 100 : 230)
                        .animation(.easeOut(duration: 0.8), value: showDrives)
                    
                    // Partner B drive
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 12, height: 12)
                        .position(x: showDrives ? 130 : 100, y: showDrives ? 80 : 230)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: showDrives)
                    
                    // Labels
                    if showDrives {
                        Text("A")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .position(x: 70, y: 100)
                        
                        Text("B")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .position(x: 130, y: 80)
                    }
                }
                
                Text("Both partners tee off")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(showDrives ? 1 : 0)
                    .animation(.easeIn.delay(1), value: showDrives)
            }
            .onAppear { 
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showDrives = true
                }
            }
        }
    }
}

struct ChapmanSwitchBallsSlide: View {
    @State private var showSwitch = false
    @State private var ballsSwapped = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Step 2: Switch Balls",
            subtitle: "Each plays partner's drive"
        ) {
            VStack(spacing: 25) {
                HStack(spacing: 60) {
                    VStack {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 35))
                            .foregroundColor(.blue)
                        
                        Image(systemName: ballsSwapped ? "b.circle.fill" : "a.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ballsSwapped ? .blue.opacity(0.6) : .blue)
                            .animation(.spring(), value: ballsSwapped)
                        
                        Text("Player A")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Swap arrows
                    if showSwitch {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 30))
                            .foregroundColor(.yellow)
                            .scaleEffect(ballsSwapped ? 1.2 : 1)
                            .animation(.spring(), value: ballsSwapped)
                    }
                    
                    VStack {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 35))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        Image(systemName: ballsSwapped ? "a.circle.fill" : "b.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ballsSwapped ? .blue : .blue.opacity(0.6))
                            .animation(.spring(), value: ballsSwapped)
                        
                        Text("Player B")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .opacity(showSwitch ? 1 : 0)
                .animation(.easeIn, value: showSwitch)
                
                Text(ballsSwapped ? "Partners play each other's ball" : "Each plays their own ball")
                    .font(.headline)
                    .foregroundColor(.white)
                    .animation(.easeIn, value: ballsSwapped)
            }
            .onAppear {
                showSwitch = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    ballsSwapped = true
                }
            }
        }
    }
}

struct ChapmanAlternateSlide: View {
    @State private var showAlternate = false
    @State private var currentPlayer = 0
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Step 3: Choose & Alternate",
            subtitle: "Select best ball, then alternate"
        ) {
            VStack(spacing: 20) {
                // Best ball selection
                HStack(spacing: 20) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                        .overlay(Text("A").foregroundColor(.white))
                        .opacity(showAlternate ? 0.3 : 1)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .overlay(Text("B").foregroundColor(.white))
                        .scaleEffect(showAlternate ? 1.2 : 1)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 3)
                                .scaleEffect(showAlternate ? 1.3 : 0)
                        )
                }
                .animation(.spring(), value: showAlternate)
                
                Text("Choose best 2nd shot")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Divider().background(Color.white.opacity(0.3))
                
                // Alternate shots
                VStack(spacing: 10) {
                    ForEach(0..<3) { shot in
                        HStack {
                            Text("Shot \(shot + 3):")
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 60, alignment: .leading)
                            
                            Image(systemName: "figure.golf")
                                .foregroundColor(shot % 2 == 0 ? .blue : .blue.opacity(0.6))
                                .scaleEffect(currentPlayer == shot ? 1.2 : 1)
                                .animation(.spring(), value: currentPlayer)
                            
                            Text(shot % 2 == 0 ? "Player A" : "Player B")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .opacity(showAlternate && shot <= currentPlayer ? 1 : 0.3)
                        .animation(.easeIn.delay(Double(shot) * 0.3), value: currentPlayer)
                    }
                }
            }
            .onAppear {
                showAlternate = true
                Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                    withAnimation {
                        if currentPlayer < 2 {
                            currentPlayer += 1
                        } else {
                            timer.invalidate()
                        }
                    }
                }
            }
        }
    }
}

struct ChapmanStrategySlide: View {
    @State private var showStrategy = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Partner coordination is key"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                StrategyPoint(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Set up your partner's shot",
                    color: .blue
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn, value: showStrategy)
                
                StrategyPoint(
                    icon: "person.2.fill",
                    text: "Know partner's strengths",
                    color: .green
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.2), value: showStrategy)
                
                StrategyPoint(
                    icon: "target",
                    text: "Strategic second shot selection",
                    color: .orange
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.4), value: showStrategy)
            }
            .onAppear { showStrategy = true }
        }
    }
}

// MARK: - Four-Ball Format Slides

struct FourBallSlides {
    static var slides: [AnyView] {
        [
            AnyView(FourBallSetupSlide()),
            AnyView(FourBallPlaySlide()),
            AnyView(FourBallScoringSlide()),
            AnyView(FourBallStrategySlide()),
            AnyView(FourBallExampleSlide()),
            AnyView(FourBallTipsSlide())
        ]
    }
}

struct FourBallSetupSlide: View {
    @State private var showSetup = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "FOUR-BALL - Setup",
            subtitle: "Team best ball format"
        ) {
            VStack(spacing: 25) {
                Text("2 vs 2 Teams")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 40) {
                    VStack {
                        HStack(spacing: 10) {
                            ForEach(0..<2) { _ in
                                Image(systemName: "figure.golf")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                            }
                        }
                        Text("Team A")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(showSetup ? 1 : 0)
                    .animation(.spring(), value: showSetup)
                    
                    Text("VS")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                        .scaleEffect(showSetup ? 1 : 0)
                        .animation(.spring().delay(0.2), value: showSetup)
                    
                    VStack {
                        HStack(spacing: 10) {
                            ForEach(0..<2) { _ in
                                Image(systemName: "figure.golf")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                            }
                        }
                        Text("Team B")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(showSetup ? 1 : 0)
                    .animation(.spring().delay(0.1), value: showSetup)
                }
                
                Text("Each plays own ball")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showSetup ? 1 : 0)
                    .animation(.easeIn.delay(0.4), value: showSetup)
            }
            .onAppear { showSetup = true }
        }
    }
}

struct FourBallPlaySlide: View {
    @State private var showBalls = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Everyone Plays",
            subtitle: "Four balls in play"
        ) {
            VStack(spacing: 25) {
                // Golf hole with 4 balls
                ZStack {
                    // Green
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 200, height: 200)
                    
                    // Flag
                    Image(systemName: "flag.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                    
                    // Team A balls
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 15, height: 15)
                        .position(x: 80, y: 90)
                        .opacity(showBalls ? 1 : 0)
                        .animation(.spring(), value: showBalls)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 15, height: 15)
                        .position(x: 110, y: 120)
                        .opacity(showBalls ? 1 : 0)
                        .animation(.spring().delay(0.1), value: showBalls)
                    
                    // Team B balls
                    Circle()
                        .fill(Color.red)
                        .frame(width: 15, height: 15)
                        .position(x: 95, y: 85)
                        .opacity(showBalls ? 1 : 0)
                        .animation(.spring().delay(0.2), value: showBalls)
                    
                    Circle()
                        .fill(Color.red.opacity(0.6))
                        .frame(width: 15, height: 15)
                        .position(x: 125, y: 100)
                        .opacity(showBalls ? 1 : 0)
                        .animation(.spring().delay(0.3), value: showBalls)
                }
                
                Text("All 4 players play every shot")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(showBalls ? 1 : 0)
                    .animation(.easeIn.delay(0.5), value: showBalls)
            }
            .onAppear { 
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showBalls = true
                }
            }
        }
    }
}

struct FourBallScoringSlide: View {
    @State private var showScoring = false
    @State private var showResult = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Best Score Counts",
            subtitle: "Lower of two partner scores"
        ) {
            VStack(spacing: 20) {
                Text("Hole 7 - Par 4")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 40) {
                    // Team A scores
                    VStack(spacing: 10) {
                        Text("Team A")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                        
                        HStack(spacing: 15) {
                            VStack {
                                Text("4")
                                    .font(.title2.bold())
                                    .foregroundColor(.blue)
                                Text("P1")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .scaleEffect(showResult ? 1.2 : 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                                    .scaleEffect(showResult ? 1.3 : 0)
                            )
                            
                            VStack {
                                Text("5")
                                    .font(.title2)
                                    .foregroundColor(.blue.opacity(0.6))
                                Text("P2")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .opacity(showResult ? 0.5 : 1)
                        }
                        
                        if showResult {
                            Text("Best: 4")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                    .opacity(showScoring ? 1 : 0)
                    .animation(.easeIn, value: showScoring)
                    
                    // Team B scores
                    VStack(spacing: 10) {
                        Text("Team B")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                        
                        HStack(spacing: 15) {
                            VStack {
                                Text("5")
                                    .font(.title2)
                                    .foregroundColor(.red.opacity(0.6))
                                Text("P3")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .opacity(showResult ? 0.5 : 1)
                            
                            VStack {
                                Text("6")
                                    .font(.title2)
                                    .foregroundColor(.red.opacity(0.6))
                                Text("P4")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .opacity(showResult ? 0.5 : 1)
                        }
                        
                        if showResult {
                            Text("Best: 5")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                    .opacity(showScoring ? 1 : 0)
                    .animation(.easeIn.delay(0.2), value: showScoring)
                }
                
                if showResult {
                    Text("Team A wins hole!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .transition(.scale)
                }
            }
            .onAppear {
                showScoring = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { showResult = true }
                }
            }
        }
    }
}

struct FourBallStrategySlide: View {
    @State private var showStrategy = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Strategy",
            subtitle: "Partner coordination"
        ) {
            VStack(alignment: .leading, spacing: 15) {
                StrategyPoint(
                    icon: "flag.fill",
                    text: "One plays safe, one attacks",
                    color: .blue
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn, value: showStrategy)
                
                StrategyPoint(
                    icon: "shield.fill",
                    text: "Secure par before risk",
                    color: .green
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.2), value: showStrategy)
                
                StrategyPoint(
                    icon: "sparkles",
                    text: "Free up partner for birdie",
                    color: .yellow
                )
                .opacity(showStrategy ? 1 : 0)
                .animation(.easeIn.delay(0.4), value: showStrategy)
            }
            .onAppear { showStrategy = true }
        }
    }
}

struct FourBallExampleSlide: View {
    @State private var showExample = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Match Play Scoring",
            subtitle: "Hole-by-hole competition"
        ) {
            VStack(spacing: 15) {
                // Scorecard example
                VStack(spacing: 8) {
                    ForEach(0..<3) { hole in
                        HStack {
                            Text("Hole \(hole + 1)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 60, alignment: .leading)
                            
                            Spacer()
                            
                            Text(hole == 0 ? "A wins" : hole == 1 ? "Halved" : "B wins")
                                .font(.caption.bold())
                                .foregroundColor(hole == 0 ? .blue : hole == 1 ? .white : .red)
                            
                            Spacer()
                            
                            Text(hole == 0 ? "A: 1UP" : hole == 1 ? "A: 1UP" : "AS")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.2))
                        )
                        .opacity(showExample ? 1 : 0)
                        .offset(y: showExample ? 0 : 10)
                        .animation(.easeOut.delay(Double(hole) * 0.2), value: showExample)
                    }
                }
                
                Text("Match decided by holes won")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showExample ? 1 : 0)
                    .animation(.easeIn.delay(0.6), value: showExample)
            }
            .padding()
            .onAppear { showExample = true }
        }
    }
}

struct FourBallTipsSlide: View {
    @State private var showTips = false
    
    var body: some View {
        DiagramSlideTemplate(
            title: "Pro Tips",
            subtitle: "Winning strategies"
        ) {
            VStack(alignment: .leading, spacing: 20) {
                TipRow(
                    icon: "lightbulb.fill",
                    text: "Communication is key",
                    color: .yellow
                )
                .opacity(showTips ? 1 : 0)
                .animation(.easeIn, value: showTips)
                
                TipRow(
                    icon: "target",
                    text: "Plan shots together",
                    color: .orange
                )
                .opacity(showTips ? 1 : 0)
                .animation(.easeIn.delay(0.2), value: showTips)
                
                TipRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Know partner's strengths",
                    color: .green
                )
                .opacity(showTips ? 1 : 0)
                .animation(.easeIn.delay(0.4), value: showTips)
                
                TipRow(
                    icon: "flag.checkered",
                    text: "Stay aggressive late",
                    color: .red
                )
                .opacity(showTips ? 1 : 0)
                .animation(.easeIn.delay(0.6), value: showTips)
            }
            .onAppear { showTips = true }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
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