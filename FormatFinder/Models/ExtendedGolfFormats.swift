import SwiftUI

// MARK: - Extended Golf Formats

extension GolfFormat {
    static let extendedFormats: [GolfFormat] = [
        // Existing formats are in allFormats, these are additional
        
        GolfFormat(
            name: "Texas Scramble",
            icon: "star.circle.fill",
            color: .orange,
            description: "Scramble with handicap adjustments - each player must contribute 4 drives",
            tagline: "Fair scramble for all",
            players: "2-4 per team",
            difficulty: "Intermediate",
            isTeamFormat: true,
            overview: [
                "Modified scramble with handicap allowances",
                "Each player must contribute minimum drives",
                "Fairer for mixed ability teams"
            ],
            rules: [
                "Standard scramble format applies",
                "Each player must contribute 4 drives minimum",
                "Team handicap is calculated (usually 10-25% of combined)",
                "Best shot selected after each stroke",
                "All players hit from selected position"
            ],
            strategy: [
                "Track whose drives have been used",
                "Save weaker player drives for easier holes",
                "Use strongest player's drive on difficult holes"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Foursomes",
            icon: "arrow.triangle.2.circlepath",
            color: .cyan,
            description: "True alternate shot - partners share one ball and alternate every shot",
            tagline: "Ultimate partnership test",
            players: "2 per team",
            difficulty: "Expert",
            isTeamFormat: true,
            overview: [
                "Most challenging team format",
                "One ball per team",
                "Requires perfect coordination"
            ],
            rules: [
                "Partners play alternate shots with same ball",
                "Player A tees off odd holes (1,3,5...)",
                "Player B tees off even holes (2,4,6...)",
                "Continue alternating including putts",
                "Penalties don't change the rotation"
            ],
            strategy: [
                "Choose tee shot order based on hole layouts",
                "Leave partner in comfortable positions",
                "Communicate constantly about preferred shots"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Greensome",
            icon: "leaf.fill",
            color: .green,
            description: "Both players tee off, select best drive, then play alternate shot",
            tagline: "Best of both worlds",
            players: "2 per team",
            difficulty: "Intermediate",
            isTeamFormat: true,
            overview: [
                "Hybrid of scramble and foursomes",
                "Less pressure than pure alternate shot",
                "Strategic format selection"
            ],
            rules: [
                "Both players tee off every hole",
                "Select best drive",
                "Player whose drive wasn't selected hits second shot",
                "Continue alternating shots until holed",
                "One score per team"
            ],
            strategy: [
                "Consider who should hit approach shots",
                "Sometimes take worse drive for better position",
                "Plan based on each player's strengths"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Vegas",
            icon: "suit.diamond.fill",
            color: .red,
            description: "Team scores combined to make 2-digit number, lowest number wins",
            tagline: "High stakes format",
            players: "4 (2v2)",
            difficulty: "Advanced",
            isTeamFormat: true,
            overview: [
                "Unique scoring creates big swings",
                "Birdies can flip scores dramatically",
                "Exciting gambling format"
            ],
            rules: [
                "Two teams of two players",
                "Combine scores to make lowest 2-digit number",
                "Example: 4 and 5 = 45, not 54",
                "If someone makes birdie, opponents' score flips",
                "Example: Birdie flips 45 to 54"
            ],
            strategy: [
                "Aggressive play rewarded with birdie flips",
                "Avoid big numbers at all costs",
                "Partner coordination crucial"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Rabbit",
            icon: "hare.fill",
            color: .brown,
            description: "Player who wins hole holds the 'rabbit' - wins if holding at 9th and 18th",
            tagline: "Catch and keep",
            players: "3-4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Dynamic format with changing leader",
                "Two chances to win per round",
                "Encourages aggressive play"
            ],
            rules: [
                "Winner of hole gets the 'rabbit'",
                "If tie, rabbit stays with current holder",
                "Player holding rabbit on hole 9 wins front nine",
                "Player holding rabbit on hole 18 wins back nine",
                "Can be played for points or stakes"
            ],
            strategy: [
                "Time aggressive plays near holes 9 and 18",
                "Protect the rabbit when you have it",
                "Force ties when opponent has rabbit"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Defender",
            icon: "shield.fill",
            color: .blue,
            description: "Designated defender plays against other three - points for successful defense",
            tagline: "One versus all",
            players: "4",
            difficulty: "Advanced",
            isTeamFormat: false,
            overview: [
                "Rotating defender role",
                "Multiple scoring opportunities",
                "Tests individual skill"
            ],
            rules: [
                "One player is defender each hole (rotates)",
                "Defender plays against best ball of three",
                "Defender wins: 3 points",
                "Tie: 1 point to defender",
                "Loss: 1 point to each opponent",
                "Most points after 18 wins"
            ],
            strategy: [
                "Play conservatively as defender",
                "Gang up on defender when not defending",
                "Track points to know when to gamble"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Ghost",
            icon: "eye.slash.fill",
            color: .gray,
            description: "Play against an invisible opponent who always makes par",
            tagline: "Beat the course",
            players: "1+",
            difficulty: "Beginner",
            isTeamFormat: false,
            overview: [
                "Great for practice rounds",
                "Clear target on every hole",
                "Can play alone or in groups"
            ],
            rules: [
                "Ghost always scores par on every hole",
                "Beat ghost's score to win hole",
                "Tie with ghost halves the hole",
                "Match play scoring against ghost",
                "Winner has best record against ghost"
            ],
            strategy: [
                "Focus on making pars",
                "Birdies give you cushion",
                "Avoid big numbers to stay in match"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Dots",
            icon: "circle.grid.3x3.fill",
            color: .mint,
            description: "Earn dots for achievements - most dots wins",
            tagline: "Achievement hunting",
            players: "2-4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Multiple ways to score",
                "Rewards all aspects of game",
                "Keeps everyone engaged"
            ],
            rules: [
                "Earn dots for achievements:",
                "• First on green = 1 dot",
                "• Closest to pin = 1 dot",
                "• Birdie = 2 dots",
                "• Sandy (up-and-down from bunker) = 1 dot",
                "• No 3-putts on hole = 1 dot"
            ],
            strategy: [
                "Go for every scoring opportunity",
                "Track what dots are still available",
                "Balance risk for birdie dots"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "String",
            icon: "ruler.fill",
            color: .indigo,
            description: "Each player gets string length based on handicap - use to improve lies",
            tagline: "Strategic advantages",
            players: "Any",
            difficulty: "Beginner",
            isTeamFormat: false,
            overview: [
                "Unique handicap system",
                "Strategic decision making",
                "Fun for all skill levels"
            ],
            rules: [
                "Each player gets string (1 foot per handicap stroke)",
                "Use string to move ball (cut off length used)",
                "Can move ball out of hazards, improve lie, or extend putts",
                "Once string is gone, play normally",
                "Cannot add to score, only improve position"
            ],
            strategy: [
                "Save string for crucial moments",
                "Use on potential penalty shots",
                "Short putts vs difficult lies decision"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Quota",
            icon: "target",
            color: .purple,
            description: "Each player has point quota based on handicap - beat quota to win",
            tagline: "Personal target",
            players: "Any",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Handicap-based point targets",
                "Modified Stableford scoring",
                "Fair for all abilities"
            ],
            rules: [
                "Quota = 36 - handicap",
                "Points: Bogey=1, Par=2, Birdie=4, Eagle=8",
                "Score points minus quota",
                "Positive score means exceeded quota",
                "Highest plus score wins"
            ],
            strategy: [
                "Know your quota before starting",
                "Track points throughout round",
                "Go aggressive when behind quota"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Yellows",
            icon: "flag.2.crossed.fill",
            color: .yellow,
            description: "Two flags per green - regular and yellow (harder) - extra points for yellow",
            tagline: "Risk and reward",
            players: "Any",
            difficulty: "Advanced",
            isTeamFormat: false,
            overview: [
                "Choose your target each hole",
                "Risk/reward on every approach",
                "Tests course management"
            ],
            rules: [
                "Two flags on each green",
                "Regular flag = normal scoring",
                "Yellow flag (tucked position) = double points",
                "Must declare target before approach shot",
                "Missing green on yellow = lose a point"
            ],
            strategy: [
                "Assess pin positions during practice",
                "Go for yellow when confident",
                "Consider match situation"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Bridges",
            icon: "road.lanes.curved.right",
            color: .brown,
            description: "Connect holes with same score to build 'bridges' - longest bridge wins",
            tagline: "Consistency pays",
            players: "Any",
            difficulty: "Beginner",
            isTeamFormat: false,
            overview: [
                "Rewards consistent scoring",
                "Simple to track",
                "Fun visualization of round"
            ],
            rules: [
                "Make same score on consecutive holes to build bridge",
                "Example: Par-Par-Par = 3-hole bridge",
                "Bridge breaks when score changes",
                "Track longest bridge of round",
                "Winner has longest bridge"
            ],
            strategy: [
                "Play for consistency over hero shots",
                "Safe play to extend bridges",
                "Know when to protect your bridge"
            ],
            hasDiagramSlides: false
        )
    ]
    
    // Combine all formats
    static var completeFormatList: [GolfFormat] {
        allFormats + extendedFormats
    }
}

// MARK: - Format Icons as SVG-style components

struct FormatIconView: View {
    let format: GolfFormat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(format.color.opacity(0.15))
                .frame(width: size, height: size)
            
            Group {
                if ["Vegas", "Rabbit", "String", "Bridges", "Dots"].contains(format.name) {
                    customFormatIcon(for: format.name)
                        .frame(width: size * 0.6, height: size * 0.6)
                } else {
                    Image(systemName: format.icon)
                        .font(.system(size: size * 0.5))
                        .foregroundColor(format.color)
                }
            }
        }
    }
    
    @ViewBuilder
    func customFormatIcon(for name: String) -> some View {
        switch name {
        case "Vegas":
            VegasIcon(color: format.color)
        case "Rabbit":
            RabbitIcon(color: format.color)
        case "String":
            StringIcon(color: format.color)
        case "Bridges":
            BridgesIcon(color: format.color)
        case "Dots":
            DotsIcon(color: format.color)
        default:
            EmptyView()
        }
    }
}

// Custom SVG-style icons
struct VegasIcon: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Dice representation
            RoundedRectangle(cornerRadius: 4)
                .stroke(color, lineWidth: 2)
                .aspectRatio(1, contentMode: .fit)
            
            // Dots pattern
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Circle().fill(color).frame(width: 4, height: 4)
                    Circle().fill(color).frame(width: 4, height: 4)
                }
                Circle().fill(color).frame(width: 4, height: 4)
                HStack(spacing: 4) {
                    Circle().fill(color).frame(width: 4, height: 4)
                    Circle().fill(color).frame(width: 4, height: 4)
                }
            }
        }
    }
}

struct RabbitIcon: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Simplified rabbit silhouette
            Ellipse()
                .fill(color)
                .frame(width: 20, height: 25)
            
            // Ears
            Ellipse()
                .fill(color)
                .frame(width: 6, height: 15)
                .offset(x: -5, y: -15)
            Ellipse()
                .fill(color)
                .frame(width: 6, height: 15)
                .offset(x: 5, y: -15)
            
            // Tail
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .offset(x: 12, y: 5)
        }
    }
}

struct StringIcon: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // String/rope visualization
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                path.addCurve(
                    to: CGPoint(x: 30, y: 10),
                    control1: CGPoint(x: 10, y: 0),
                    control2: CGPoint(x: 20, y: 20)
                )
            }
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

struct BridgesIcon: View {
    let color: Color
    
    var body: some View {
        ZStack {
            // Bridge arches
            Path { path in
                path.move(to: CGPoint(x: 0, y: 20))
                path.addQuadCurve(
                    to: CGPoint(x: 15, y: 20),
                    control: CGPoint(x: 7.5, y: 10)
                )
                path.move(to: CGPoint(x: 15, y: 20))
                path.addQuadCurve(
                    to: CGPoint(x: 30, y: 20),
                    control: CGPoint(x: 22.5, y: 10)
                )
            }
            .stroke(color, lineWidth: 2)
            
            // Bridge supports
            Rectangle()
                .fill(color)
                .frame(width: 2, height: 10)
                .offset(x: -15, y: 15)
            Rectangle()
                .fill(color)
                .frame(width: 2, height: 10)
                .offset(x: 0, y: 15)
            Rectangle()
                .fill(color)
                .frame(width: 2, height: 10)
                .offset(x: 15, y: 15)
        }
    }
}

struct DotsIcon: View {
    let color: Color
    
    var body: some View {
        // Grid of dots
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Circle().fill(color).frame(width: 6, height: 6)
                Circle().fill(color).frame(width: 6, height: 6)
            }
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Circle().fill(color.opacity(0.5)).frame(width: 6, height: 6)
                Circle().fill(color).frame(width: 6, height: 6)
            }
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 6, height: 6)
                Circle().fill(color).frame(width: 6, height: 6)
                Circle().fill(color).frame(width: 6, height: 6)
            }
        }
    }
}