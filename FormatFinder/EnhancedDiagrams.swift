import SwiftUI

// MARK: - Complete Interactive Guides for All 12 Formats

// MARK: - Match Play Slides
struct MatchPlaySlides {
    static var slides: [AnyView] {
        [
            AnyView(MatchPlaySlide1()),
            AnyView(MatchPlaySlide2()),
            AnyView(MatchPlaySlide3()),
            AnyView(MatchPlaySlide4()),
            AnyView(MatchPlaySlide5())
        ]
    }
}

struct MatchPlaySlide1: View {
    @State private var animateMatch = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Match Play - Head to Head")
                .font(.system(size: 24, weight: .bold))
            
            ZStack {
                // Golf course hole representation
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.green.opacity(0.3))
                    .frame(height: 200)
                
                HStack(spacing: 40) {
                    VStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(Text("P1").foregroundColor(.white).bold())
                            .scaleEffect(animateMatch ? 1.1 : 1.0)
                        Text("4 strokes")
                            .font(.caption)
                    }
                    
                    Image(systemName: "flag.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                    
                    VStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 60, height: 60)
                            .overlay(Text("P2").foregroundColor(.white).bold())
                            .scaleEffect(!animateMatch ? 1.1 : 1.0)
                        Text("5 strokes")
                            .font(.caption)
                    }
                }
            }
            
            Text("Player 1 wins the hole")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.blue)
            
            Text("Each hole is a separate competition. Win by winning more holes than your opponent.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateMatch = true
            }
        }
    }
}

struct MatchPlaySlide2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Scoring System")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                ScoreRow(result: "Win hole", points: "Go 1 UP", color: .green)
                ScoreRow(result: "Lose hole", points: "Go 1 DOWN", color: .red)
                ScoreRow(result: "Tie hole", points: "Stay ALL SQUARE", color: .gray)
            }
            
            Divider()
            
            VStack(spacing: 10) {
                Text("Match Status Examples:")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    StatusBadge(text: "2 UP", color: .green)
                    StatusBadge(text: "ALL SQUARE", color: .gray)
                    StatusBadge(text: "3 DOWN", color: .red)
                }
            }
            
            Text("Match ends when a player is up by more holes than remain")
                .font(.system(size: 14))
                .italic()
                .padding(.top)
        }
        .padding()
    }
}

struct MatchPlaySlide3: View {
    @State private var currentHole = 1
    @State private var player1Score = 0
    @State private var player2Score = 0
    
    var matchStatus: String {
        if player1Score == player2Score {
            return "ALL SQUARE"
        } else if player1Score > player2Score {
            return "\(player1Score - player2Score) UP"
        } else {
            return "\(player2Score - player1Score) DOWN"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Live Match Simulation")
                .font(.system(size: 24, weight: .bold))
            
            HStack(spacing: 30) {
                VStack {
                    Text("Player 1")
                        .font(.headline)
                    Text("\(player1Score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("Hole \(currentHole)")
                        .font(.caption)
                    Text(matchStatus)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(player1Score > player2Score ? .green : player1Score < player2Score ? .red : .gray)
                }
                
                VStack {
                    Text("Player 2")
                        .font(.headline)
                    Text("\(player2Score)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            
            Button(action: simulateHole) {
                Label("Play Next Hole", systemImage: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            if currentHole > 9 {
                Button("Reset Match") {
                    currentHole = 1
                    player1Score = 0
                    player2Score = 0
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    func simulateHole() {
        if currentHole <= 18 {
            let winner = Int.random(in: 0...2)
            if winner == 0 {
                player1Score += 1
            } else if winner == 1 {
                player2Score += 1
            }
            currentHole += 1
        }
    }
}

struct MatchPlaySlide4: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Concessions & Strategy")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                StrategyPoint(
                    icon: "hand.raised.fill",
                    title: "Concessions",
                    description: "You can concede a putt to your opponent at any time"
                )
                
                StrategyPoint(
                    icon: "brain",
                    title: "Mental Game",
                    description: "Apply pressure by making your putts first"
                )
                
                StrategyPoint(
                    icon: "flag.2.crossed",
                    title: "Dormie",
                    description: "When you're up by the number of holes remaining"
                )
                
                StrategyPoint(
                    icon: "trophy.fill",
                    title: "Closing Out",
                    description: "Example: Win 4&3 means 4 holes up with 3 to play"
                )
            }
        }
        .padding()
    }
}

struct MatchPlaySlide5: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Pro Tips")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                ProTip(
                    number: "1",
                    tip: "Play the opponent, not the course - take calculated risks"
                )
                
                ProTip(
                    number: "2",
                    tip: "Never give up - matches can turn quickly"
                )
                
                ProTip(
                    number: "3",
                    tip: "Watch your opponent's putt to learn the break"
                )
                
                ProTip(
                    number: "4",
                    tip: "Stay aggressive when ahead, don't play defensively"
                )
            }
        }
        .padding()
    }
}

// MARK: - Skins Slides
struct SkinsSlides {
    static var slides: [AnyView] {
        [
            AnyView(SkinsSlide1()),
            AnyView(SkinsSlide2()),
            AnyView(SkinsSlide3()),
            AnyView(SkinsSlide4())
        ]
    }
}

struct SkinsSlide1: View {
    @State private var potValue = 100
    @State private var animatePot = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Skins - Win the Hole, Win the Pot")
                .font(.system(size: 24, weight: .bold))
            
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 150, height: 150)
                    .scaleEffect(animatePot ? 1.1 : 1.0)
                
                VStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    
                    Text("$\(potValue)")
                        .font(.system(size: 28, weight: .bold))
                }
            }
            
            Text("Each hole has a value")
                .font(.system(size: 18))
            
            HStack(spacing: 30) {
                VStack {
                    Text("Hole Tied")
                        .font(.caption)
                    Text("Skin Carries")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                VStack {
                    Text("Hole Won")
                        .font(.caption)
                    Text("Win Skin!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePot = true
            }
            
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                withAnimation {
                    potValue += 100
                    if potValue > 500 { potValue = 100 }
                }
            }
        }
    }
}

struct SkinsSlide2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Carryover Rules")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                HoleResult(hole: 1, result: "Player A wins", value: "$10", color: .green)
                HoleResult(hole: 2, result: "Tied - Carries", value: "$20", color: .orange)
                HoleResult(hole: 3, result: "Tied - Carries", value: "$30", color: .orange)
                HoleResult(hole: 4, result: "Player B wins", value: "$40", color: .green)
            }
            
            Text("When holes are tied, the skin value carries to the next hole, creating bigger pots!")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

struct SkinsSlide3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Validation Rules")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                ValidationRule(
                    icon: "checkmark.shield",
                    rule: "Must win hole outright - no ties"
                )
                
                ValidationRule(
                    icon: "xmark.circle",
                    rule: "Some play with validation - if someone ties your score on a later hole, you lose the skin"
                )
                
                ValidationRule(
                    icon: "arrow.triangle.2.circlepath",
                    rule: "Carryovers can create huge pots on final holes"
                )
            }
            
            Text("Agree on rules before starting!")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.top)
        }
        .padding()
    }
}

struct SkinsSlide4: View {
    @State private var currentPot = 10
    @State private var holes: [(String, Int)] = [
        ("Hole 1", 10),
        ("Hole 2", 10),
        ("Hole 3", 10)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Strategy Tips")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 12) {
                StrategyTip(tip: "Be aggressive when big carryovers are at stake")
                StrategyTip(tip: "Consider pressing (doubling) the bet on back nine")
                StrategyTip(tip: "Play more conservatively with validation rules")
                StrategyTip(tip: "Track carryovers carefully to know the stakes")
            }
            
            Spacer()
            
            Text("Great for adding excitement to any round!")
                .font(.system(size: 16))
                .italic()
        }
        .padding()
    }
}

// MARK: - Four-Ball Slides
struct FourBallSlides {
    static var slides: [AnyView] {
        [
            AnyView(FourBallSlide1()),
            AnyView(FourBallSlide2()),
            AnyView(FourBallSlide3()),
            AnyView(FourBallSlide4())
        ]
    }
}

struct FourBallSlide1: View {
    @State private var showBestScore = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Four-Ball - Best Ball Partners")
                .font(.system(size: 24, weight: .bold))
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.green.opacity(0.2))
                    .frame(height: 250)
                
                VStack {
                    HStack(spacing: 40) {
                        TeamView(
                            team: "Team A",
                            player1: ("A1", 4, Color.blue),
                            player2: ("A2", 5, Color.blue.opacity(0.5)),
                            bestScore: 4,
                            highlight: showBestScore
                        )
                        
                        TeamView(
                            team: "Team B",
                            player1: ("B1", 6, Color.red.opacity(0.5)),
                            player2: ("B2", 5, Color.red),
                            bestScore: 5,
                            highlight: showBestScore
                        )
                    }
                }
            }
            
            if showBestScore {
                Text("Team A wins hole: 4 vs 5")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            Button("Show Best Scores") {
                withAnimation {
                    showBestScore.toggle()
                }
            }
            .buttonStyle(GreenButtonStyle())
        }
        .padding()
    }
}

struct FourBallSlide2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("How It Works")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                RuleRow(
                    number: "1",
                    text: "Each player plays their own ball"
                )
                
                RuleRow(
                    number: "2",
                    text: "Team score = best score of the two partners"
                )
                
                RuleRow(
                    number: "3",
                    text: "Can play match play or stroke play"
                )
                
                RuleRow(
                    number: "4",
                    text: "Partners can help with advice and strategy"
                )
            }
        }
        .padding()
    }
}

struct FourBallSlide3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Strategy & Teamwork")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                TeamworkTip(
                    icon: "person.2.fill",
                    tip: "One plays safe, one plays aggressive"
                )
                
                TeamworkTip(
                    icon: "target",
                    tip: "Help partner read putts"
                )
                
                TeamworkTip(
                    icon: "flag.fill",
                    tip: "Tend the flag for your partner"
                )
                
                TeamworkTip(
                    icon: "bubble.left.and.bubble.right",
                    tip: "Communicate on club selection"
                )
            }
        }
        .padding()
    }
}

struct FourBallSlide4: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Scoring Example")
                .font(.system(size: 24, weight: .bold))
            
            ScoreCard()
            
            Text("Team's best score counts on each hole")
                .font(.system(size: 16))
                .italic()
        }
        .padding()
    }
}

// MARK: - Nassau Slides
struct NassauSlides {
    static var slides: [AnyView] {
        [
            AnyView(NassauSlide1()),
            AnyView(NassauSlide2()),
            AnyView(NassauSlide3()),
            AnyView(NassauSlide4())
        ]
    }
}

struct NassauSlide1: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Nassau - Three Bets in One")
                .font(.system(size: 24, weight: .bold))
            
            HStack(spacing: 20) {
                BetCard(title: "Front 9", holes: "Holes 1-9", color: .blue)
                BetCard(title: "Back 9", holes: "Holes 10-18", color: .orange)
                BetCard(title: "Total 18", holes: "All Holes", color: .purple)
            }
            
            Text("Each nine and overall match are separate bets")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

struct NassauSlide2: View {
    @State private var front9Winner = ""
    @State private var back9Winner = ""
    @State private var overallWinner = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Scoring Breakdown")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                NassauScore(
                    bet: "Front 9",
                    playerA: "2 UP",
                    playerB: "2 DOWN",
                    winner: "Player A",
                    color: .blue
                )
                
                NassauScore(
                    bet: "Back 9",
                    playerA: "1 DOWN",
                    playerB: "1 UP",
                    winner: "Player B",
                    color: .orange
                )
                
                NassauScore(
                    bet: "Overall",
                    playerA: "1 UP",
                    playerB: "1 DOWN",
                    winner: "Player A",
                    color: .purple
                )
            }
            
            Text("Player A wins 2 of 3 bets")
                .font(.system(size: 18, weight: .semibold))
        }
        .padding()
    }
}

struct NassauSlide3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Press Rules")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                PressRule(
                    title: "Automatic Press",
                    description: "New bet starts when 2 holes down"
                )
                
                PressRule(
                    title: "Manual Press",
                    description: "Losing player can press to double the bet"
                )
                
                PressRule(
                    title: "Re-Press",
                    description: "Press the press for even more action"
                )
            }
            
            Text("Presses can quickly multiply the stakes!")
                .font(.system(size: 14))
                .foregroundColor(.red)
                .padding(.top)
        }
        .padding()
    }
}

struct NassauSlide4: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Nassau Strategy")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 12) {
                StrategyPoint(
                    icon: "gamecontroller",
                    title: "Momentum",
                    description: "Win front 9 to apply pressure"
                )
                
                StrategyPoint(
                    icon: "arrow.counterclockwise",
                    title: "Comeback",
                    description: "New nine = fresh start"
                )
                
                StrategyPoint(
                    icon: "flame",
                    title: "Press Timing",
                    description: "Press when confident, not desperate"
                )
            }
        }
        .padding()
    }
}

// MARK: - Bingo Bango Bongo Slides
struct BingoBangoBongoSlides {
    static var slides: [AnyView] {
        [
            AnyView(BingoBangoBongoSlide1()),
            AnyView(BingoBangoBongoSlide2()),
            AnyView(BingoBangoBongoSlide3()),
            AnyView(BingoBangoBongoSlide4())
        ]
    }
}

struct BingoBangoBongoSlide1: View {
    @State private var currentPoint = 0
    let points = ["BINGO!", "BANGO!", "BONGO!"]
    let descriptions = [
        "First on the green",
        "Closest to the pin",
        "First in the hole"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bingo Bango Bongo")
                .font(.system(size: 24, weight: .bold))
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 200, height: 200)
                
                VStack {
                    Text(points[currentPoint])
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text(descriptions[currentPoint])
                        .font(.system(size: 16))
                }
            }
            
            HStack(spacing: 30) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPoint == index ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text("Three ways to score on every hole!")
                .font(.system(size: 16))
                .italic()
        }
        .padding()
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                withAnimation {
                    currentPoint = (currentPoint + 1) % 3
                }
            }
        }
    }
}

struct BingoBangoBongoSlide2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Point System")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                PointCard(
                    title: "BINGO",
                    description: "First ball on the green",
                    points: 1,
                    color: .blue
                )
                
                PointCard(
                    title: "BANGO",
                    description: "Closest to pin once all on green",
                    points: 1,
                    color: .orange
                )
                
                PointCard(
                    title: "BONGO",
                    description: "First to hole out",
                    points: 1,
                    color: .purple
                )
            }
            
            Text("3 points available per hole")
                .font(.system(size: 16, weight: .semibold))
        }
        .padding()
    }
}

struct BingoBangoBongoSlide3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Order of Play")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                OrderRule(
                    number: "1",
                    rule: "Honors must be strictly observed"
                )
                
                OrderRule(
                    number: "2",
                    rule: "Farthest from hole plays first"
                )
                
                OrderRule(
                    number: "3",
                    rule: "Wait for everyone on green before putting"
                )
                
                OrderRule(
                    number: "4",
                    rule: "Great equalizer for different skill levels"
                )
            }
        }
        .padding()
    }
}

struct BingoBangoBongoSlide4: View {
    @State private var scores = [
        ("Player 1", 12),
        ("Player 2", 15),
        ("Player 3", 14),
        ("Player 4", 13)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Final Scorecard")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 10) {
                ForEach(scores.sorted(by: { $0.1 > $1.1 }), id: \.0) { player, score in
                    HStack {
                        Text(player)
                            .font(.system(size: 16))
                        Spacer()
                        Text("\(score) points")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Text("Perfect for groups with varying handicaps!")
                .font(.system(size: 14))
                .italic()
        }
        .padding()
    }
}

// MARK: - Wolf Slides
struct WolfSlides {
    static var slides: [AnyView] {
        [
            AnyView(WolfSlide1()),
            AnyView(WolfSlide2()),
            AnyView(WolfSlide3()),
            AnyView(WolfSlide4()),
            AnyView(WolfSlide5())
        ]
    }
}

struct WolfSlide1: View {
    @State private var currentWolf = 0
    let players = ["P1", "P2", "P3", "P4"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Wolf - Strategic Partner Selection")
                .font(.system(size: 24, weight: .bold))
            
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index == currentWolf ? Color.orange : Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(players[index])
                                .foregroundColor(.white)
                                .bold()
                        )
                        .offset(
                            x: cos(CGFloat(index) * .pi / 2) * 70,
                            y: sin(CGFloat(index) * .pi / 2) * 70
                        )
                }
                
                if currentWolf < 4 {
                    Text("WOLF")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            
            Text("Wolf rotates each hole")
                .font(.system(size: 16))
            
            Text("Current Wolf: \(players[currentWolf])")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.orange)
        }
        .padding()
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                withAnimation {
                    currentWolf = (currentWolf + 1) % 4
                }
            }
        }
    }
}

struct WolfSlide2: View {
    @State private var selectedPartner: String? = nil
    @State private var goingLone = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Wolf's Decision")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                Text("After watching tee shots:")
                    .font(.system(size: 16))
                
                HStack(spacing: 20) {
                    DecisionCard(
                        title: "Pick Partner",
                        description: "2 vs 2",
                        points: "1 point each",
                        color: .blue,
                        selected: selectedPartner != nil && !goingLone
                    ) {
                        selectedPartner = "Player 2"
                        goingLone = false
                    }
                    
                    DecisionCard(
                        title: "Go Lone Wolf",
                        description: "1 vs 3",
                        points: "2-3 points",
                        color: .orange,
                        selected: goingLone
                    ) {
                        goingLone = true
                        selectedPartner = nil
                    }
                }
                
                if goingLone {
                    Text("High risk, high reward!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                } else if selectedPartner != nil {
                    Text("Smart partnership!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }
}

struct WolfSlide3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Scoring System")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                ScoringRow(
                    scenario: "Wolf & Partner Win",
                    points: "1 point each",
                    color: .green
                )
                
                ScoringRow(
                    scenario: "Wolf & Partner Lose",
                    points: "-1 point each",
                    color: .red
                )
                
                Divider()
                
                ScoringRow(
                    scenario: "Lone Wolf Wins",
                    points: "2-3 points",
                    color: .orange
                )
                
                ScoringRow(
                    scenario: "Lone Wolf Loses",
                    points: "-2-3 points",
                    color: .red
                )
            }
        }
        .padding()
    }
}

struct WolfSlide4: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Blind Wolf Option")
                .font(.system(size: 24, weight: .bold))
            
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("Declare Lone Wolf BEFORE anyone tees off")
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
            
            Text("Double the points!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.purple)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Win")
                        .font(.caption)
                    Text("+4 points")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("Lose")
                        .font(.caption)
                    Text("-4 points")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}

struct WolfSlide5: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Wolf Strategy")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                WolfTip(
                    icon: "eye",
                    tip: "Watch tee shots carefully before deciding"
                )
                
                WolfTip(
                    icon: "person.2",
                    tip: "Pick partners who complement your game"
                )
                
                WolfTip(
                    icon: "flame",
                    tip: "Go lone on holes that suit your strengths"
                )
                
                WolfTip(
                    icon: "chart.line.uptrend.xyaxis",
                    tip: "Track points to know when to take risks"
                )
            }
        }
        .padding()
    }
}

// MARK: - Chapman Slides
struct ChapmanSlides {
    static var slides: [AnyView] {
        [
            AnyView(ChapmanSlide1()),
            AnyView(ChapmanSlide2()),
            AnyView(ChapmanSlide3()),
            AnyView(ChapmanSlide4())
        ]
    }
}

struct ChapmanSlide1: View {
    @State private var step = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chapman - Strategic Partnership")
                .font(.system(size: 24, weight: .bold))
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.green.opacity(0.2))
                    .frame(height: 200)
                
                VStack {
                    if step == 0 {
                        Text("Both players tee off")
                            .font(.system(size: 18, weight: .semibold))
                    } else if step == 1 {
                        Text("Switch balls for second shot")
                            .font(.system(size: 18, weight: .semibold))
                    } else if step == 2 {
                        Text("Select best ball after second shot")
                            .font(.system(size: 18, weight: .semibold))
                    } else {
                        Text("Alternate shots to finish")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    HStack(spacing: 20) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index <= step ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 15, height: 15)
                        }
                    }
                    .padding(.top)
                }
            }
            
            Button("Next Step") {
                withAnimation {
                    step = (step + 1) % 4
                }
            }
            .buttonStyle(GreenButtonStyle())
        }
        .padding()
    }
}

struct ChapmanSlide2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Shot Sequence")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                ChapmanStep(
                    number: "1",
                    action: "Both tee off",
                    detail: "Two balls in play"
                )
                
                ChapmanStep(
                    number: "2",
                    action: "Switch balls",
                    detail: "Play partner's drive"
                )
                
                ChapmanStep(
                    number: "3",
                    action: "Choose best",
                    detail: "After both second shots"
                )
                
                ChapmanStep(
                    number: "4",
                    action: "Alternate",
                    detail: "Until holed out"
                )
            }
        }
        .padding()
    }
}

struct ChapmanSlide3: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Strategy Points")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                StrategyCard(
                    title: "Tee Shots",
                    tip: "Both aim for fairway - no hero shots",
                    color: .blue
                )
                
                StrategyCard(
                    title: "Second Shots",
                    tip: "One aggressive, one safe to the green",
                    color: .orange
                )
                
                StrategyCard(
                    title: "Ball Selection",
                    tip: "Consider who's better at short game",
                    color: .purple
                )
            }
        }
        .padding()
    }
}

struct ChapmanSlide4: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Chapman vs Other Formats")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 12) {
                ComparisonRow(
                    format: "vs Scramble",
                    difference: "Less forgiving, more strategic"
                )
                
                ComparisonRow(
                    format: "vs Best Ball",
                    difference: "More teamwork required"
                )
                
                ComparisonRow(
                    format: "vs Alternate Shot",
                    difference: "More opportunities to recover"
                )
            }
            
            Text("Perfect balance of individual and team play!")
                .font(.system(size: 14))
                .italic()
                .padding(.top)
        }
        .padding()
    }
}

// MARK: - Vegas Slides
struct VegasSlides {
    static var slides: [AnyView] {
        [
            AnyView(VegasSlide1()),
            AnyView(VegasSlide2()),
            AnyView(VegasSlide3()),
            AnyView(VegasSlide4())
        ]
    }
}

struct VegasSlide1: View {
    @State private var team1Score1 = 4
    @State private var team1Score2 = 5
    @State private var team2Score1 = 3
    @State private var team2Score2 = 6
    
    var team1Combined: Int {
        min(team1Score1, team1Score2) * 10 + max(team1Score1, team1Score2)
    }
    
    var team2Combined: Int {
        min(team2Score1, team2Score2) * 10 + max(team2Score1, team2Score2)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Vegas - Combined Scores")
                .font(.system(size: 24, weight: .bold))
            
            HStack(spacing: 30) {
                VStack {
                    Text("Team 1")
                        .font(.headline)
                    HStack {
                        ScoreTile(score: team1Score1)
                        ScoreTile(score: team1Score2)
                    }
                    Text("= \(team1Combined)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack {
                    Text("Team 2")
                        .font(.headline)
                    HStack {
                        ScoreTile(score: team2Score1)
                        ScoreTile(score: team2Score2)
                    }
                    Text("= \(team2Combined)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            
            Text("Lower combined score wins!")
                .font(.system(size: 16))
            
            Text("Difference: \(abs(team1Combined - team2Combined)) points")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(team1Combined < team2Combined ? .blue : .orange)
        }
        .padding()
    }
}

struct VegasSlide2: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Scoring Rules")
                .font(.system(size: 24, weight: .bold))
            
            VStack(alignment: .leading, spacing: 15) {
                VegasRule(
                    rule: "Low score goes first",
                    example: "4 and 6 = 46, not 64"
                )
                
                VegasRule(
                    rule: "Difference in points",
                    example: "45 vs 56 = 11 point swing"
                )
                
                VegasRule(
                    rule: "Birdies can flip",
                    example: "Opponent's score reversed!"
                )
                
                VegasRule(
                    rule: "Eagles double",
                    example: "Double the point difference"
                )
            }
        }
        .padding()
    }
}

struct VegasSlide3: View {
    @State private var showFlip = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("The Flip Rule")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 20) {
                Text("When you make a birdie:")
                    .font(.system(size: 18))
                
                HStack(spacing: 40) {
                    VStack {
                        Text("Normal")
                        Text("36")
                            .font(.system(size: 30, weight: .bold))
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24))
                    
                    VStack {
                        Text("Flipped!")
                        Text(showFlip ? "63" : "36")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(showFlip ? .red : .black)
                    }
                }
                
                Button("Show Flip") {
                    withAnimation {
                        showFlip.toggle()
                    }
                }
                .buttonStyle(GreenButtonStyle())
                
                Text("Huge swings possible!")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}

struct VegasSlide4: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Vegas Strategy")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 15) {
                VegasTip(
                    tip: "Partner with similar skill level",
                    reason: "Avoid big numbers"
                )
                
                VegasTip(
                    tip: "Play conservative on flip holes",
                    reason: "Prevent huge swings"
                )
                
                VegasTip(
                    tip: "Track running total carefully",
                    reason: "Points add up fast!"
                )
            }
            
            Text("Can create massive point swings - play carefully!")
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .padding(.top)
        }
        .padding()
    }
}

// MARK: - Helper Views for Diagrams

struct ScoreRow: View {
    let result: String
    let points: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(result)
                .font(.system(size: 16))
            Spacer()
            Text(points)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(15)
    }
}

struct StrategyPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ProTip: View {
    let number: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.green)
                .frame(width: 30, height: 30)
                .overlay(
                    Text(number)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                )
            
            Text(tip)
                .font(.system(size: 15))
        }
    }
}

struct HoleResult: View {
    let hole: Int
    let result: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text("Hole \(hole)")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 60, alignment: .leading)
            
            Text(result)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal)
    }
}

struct ValidationRule: View {
    let icon: String
    let rule: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            Text(rule)
                .font(.system(size: 14))
        }
    }
}

struct StrategyTip: View {
    let tip: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16))
                .foregroundColor(.yellow)
            
            Text(tip)
                .font(.system(size: 14))
        }
    }
}

struct TeamView: View {
    let team: String
    let player1: (String, Int, Color)
    let player2: (String, Int, Color)
    let bestScore: Int
    let highlight: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text(team)
                .font(.system(size: 16, weight: .semibold))
            
            VStack(spacing: 8) {
                PlayerScore(
                    name: player1.0,
                    score: player1.1,
                    color: player1.2,
                    isBest: highlight && player1.1 == bestScore
                )
                
                PlayerScore(
                    name: player2.0,
                    score: player2.1,
                    color: player2.2,
                    isBest: highlight && player2.1 == bestScore
                )
            }
            
            if highlight {
                Text("Best: \(bestScore)")
                    .font(.system(size: 14, weight: .bold))
            }
        }
    }
}

struct PlayerScore: View {
    let name: String
    let score: Int
    let color: Color
    let isBest: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.white)
                )
            
            Text("\(score)")
                .font(.system(size: 16, weight: isBest ? .bold : .regular))
                .foregroundColor(isBest ? color : .gray)
        }
        .scaleEffect(isBest ? 1.1 : 1.0)
        .animation(.easeInOut, value: isBest)
    }
}

struct RuleRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 25, height: 25)
                .overlay(
                    Text(number)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                )
            
            Text(text)
                .font(.system(size: 15))
        }
    }
}

struct TeamworkTip: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 30)
            
            Text(tip)
                .font(.system(size: 15))
        }
        .padding(.horizontal)
    }
}

struct ScoreCard: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Hole")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 40)
                ForEach(1...9, id: \.self) { hole in
                    Text("\(hole)")
                        .font(.system(size: 12))
                        .frame(width: 25)
                }
            }
            
            Divider()
            
            HStack {
                Text("P1")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 40)
                ForEach([5,4,6,3,5,4,4,5,4], id: \.self) { score in
                    Text("\(score)")
                        .font(.system(size: 12))
                        .frame(width: 25)
                }
            }
            
            HStack {
                Text("P2")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 40)
                ForEach([4,5,5,4,6,3,5,4,5], id: \.self) { score in
                    Text("\(score)")
                        .font(.system(size: 12))
                        .frame(width: 25)
                }
            }
            
            Divider()
            
            HStack {
                Text("Team")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                    .frame(width: 40)
                ForEach([4,4,5,3,5,3,4,4,4], id: \.self) { score in
                    Text("\(score)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 25)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct BetCard: View {
    let title: String
    let holes: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(holes)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(width: 100, height: 100)
        .background(color)
        .cornerRadius(15)
    }
}

struct NassauScore: View {
    let bet: String
    let playerA: String
    let playerB: String
    let winner: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(bet)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 80, alignment: .leading)
            
            HStack(spacing: 20) {
                Text(playerA)
                    .font(.system(size: 14))
                    .foregroundColor(winner == "Player A" ? .green : .red)
                
                Text("vs")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(playerB)
                    .font(.system(size: 14))
                    .foregroundColor(winner == "Player B" ? .green : .red)
            }
            
            Spacer()
            
            Text(winner)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct PressRule: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

struct PointCard: View {
    let title: String
    let description: String
    let points: Int
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("\(points) pt")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct OrderRule: View {
    let number: String
    let rule: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 25, height: 25)
                .background(Circle().fill(Color.orange))
            
            Text(rule)
                .font(.system(size: 15))
        }
    }
}

struct DecisionCard: View {
    let title: String
    let description: String
    let points: String
    let color: Color
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                
                Text(description)
                    .font(.system(size: 14))
                
                Text(points)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .foregroundColor(selected ? .white : color)
            .frame(width: 140, height: 120)
            .background(selected ? color : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color, lineWidth: selected ? 3 : 1)
            )
            .cornerRadius(10)
        }
    }
}

struct ScoringRow: View {
    let scenario: String
    let points: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(scenario)
                .font(.system(size: 15))
            
            Spacer()
            
            Text(points)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal)
    }
}

struct WolfTip: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .frame(width: 30)
            
            Text(tip)
                .font(.system(size: 15))
        }
    }
}

struct ChapmanStep: View {
    let number: String
    let action: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Circle()
                .fill(Color.green)
                .frame(width: 30, height: 30)
                .overlay(
                    Text(number)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(action)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct StrategyCard: View {
    let title: String
    let tip: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(tip)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ComparisonRow: View {
    let format: String
    let difference: String
    
    var body: some View {
        HStack {
            Text(format)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 100, alignment: .leading)
            
            Text(difference)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

struct ScoreTile: View {
    let score: Int
    
    var body: some View {
        Text("\(score)")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Color.gray)
            .cornerRadius(8)
    }
}

struct VegasRule: View {
    let rule: String
    let example: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(rule)
                .font(.system(size: 16, weight: .semibold))
            
            Text(example)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .italic()
        }
    }
}

struct VegasTip: View {
    let tip: String
    let reason: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("• \(tip)")
                .font(.system(size: 15, weight: .semibold))
            
            Text(reason)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.leading)
        }
    }
}

struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}