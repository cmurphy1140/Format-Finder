import SwiftUI

// MARK: - Stick Figure Golf Animations

struct StickFigureGolfAnimation: View {
    let format: GolfFormat
    @State private var animationStep = 0
    @State private var ballPositions: [CGPoint] = []
    @State private var playerActions: [PlayerAction] = []
    @State private var explanationText = ""
    @State private var isPlaying = false
    @State private var showTrajectories = false
    
    let holeLayout = HoleLayout()
    
    var body: some View {
        VStack(spacing: 0) {
            // Golf hole with stick figures
            ZStack {
                // Golf hole background
                GolfHoleCanvas()
                
                // Players and animations
                ForEach(0..<4) { playerIndex in
                    StickFigurePlayer(
                        playerNumber: playerIndex + 1,
                        position: playerPosition(for: playerIndex),
                        action: currentAction(for: playerIndex),
                        color: stickFigurePlayerColors[playerIndex],
                        isActive: isPlayerActive(playerIndex)
                    )
                }
                
                // Ball trajectories
                if showTrajectories {
                    ForEach(Array(ballPositions.enumerated()), id: \.offset) { index, position in
                        AnimatedGolfBallView(
                            position: position,
                            color: ballColor(for: index),
                            isAnimating: true
                        )
                    }
                }
                
                // Current step indicator
                VStack {
                    HStack {
                        FormatBadge(format: format)
                        Spacer()
                        StepIndicator(currentStep: animationStep, totalSteps: totalSteps)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .frame(height: 400)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 134/255, green: 204/255, blue: 134/255),
                        Color(red: 104/255, green: 174/255, blue: 104/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
            .padding()
            
            // Explanation text
            VStack(alignment: .leading, spacing: 10) {
                Text("Step \(animationStep + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(format.color)
                
                Text(explanationText)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut, value: explanationText)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(15)
            .padding(.horizontal)
            
            // Control buttons
            HStack(spacing: 20) {
                Button(action: previousStep) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(animationStep > 0 ? format.color : .gray)
                }
                .disabled(animationStep == 0)
                
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(format.color)
                        .clipShape(Circle())
                }
                
                Button(action: nextStep) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(animationStep < totalSteps - 1 ? format.color : .gray)
                }
                .disabled(animationStep >= totalSteps - 1)
                
                Spacer()
                
                Button(action: resetAnimation) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 18))
                        .foregroundColor(format.color)
                }
            }
            .padding()
        }
        .onAppear {
            setupAnimation()
            startAutoPlay()
        }
    }
    
    // MARK: - Animation Logic
    
    var totalSteps: Int {
        switch format.name {
        case "Scramble": return 5
        case "Best Ball": return 4
        case "Alternate Shot": return 6
        case "Match Play": return 4
        case "Skins": return 4
        case "Stableford": return 3
        case "Wolf": return 5
        case "Nassau": return 3
        case "Chapman": return 5
        case "Four-Ball": return 4
        case "Foursomes": return 6
        case "Texas Scramble": return 5
        case "Greensome": return 5
        case "Vegas": return 4
        case "Rabbit": return 4
        case "Defender": return 4
        case "Ghost": return 3
        case "Dots": return 5
        case "String": return 4
        case "Quota": return 3
        case "Yellows": return 4
        case "Bridges": return 3
        case "Bingo Bango Bongo": return 5
        default: return 3
        }
    }
    
    func setupAnimation() {
        updateAnimationForCurrentStep()
    }
    
    func updateAnimationForCurrentStep() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            switch format.name {
            case "Scramble":
                animateScramble()
            case "Best Ball":
                animateBestBall()
            case "Alternate Shot":
                animateAlternateShot()
            case "Match Play":
                animateMatchPlay()
            case "Skins":
                animateSkins()
            case "Stableford":
                animateStableford()
            case "Wolf":
                animateWolf()
            case "Nassau":
                animateNassau()
            case "Chapman":
                animateChapman()
            case "Four-Ball":
                animateFourBall()
            case "Foursomes":
                animateFoursomes()
            case "Texas Scramble":
                animateTexasScramble()
            case "Greensome":
                animateGreensome()
            case "Vegas":
                animateVegas()
            case "Rabbit":
                animateRabbit()
            case "Defender":
                animateDefender()
            case "Ghost":
                animateGhost()
            case "Dots":
                animateDots()
            case "String":
                animateString()
            case "Quota":
                animateQuota()
            case "Yellows":
                animateYellows()
            case "Bridges":
                animateBridges()
            case "Bingo Bango Bongo":
                animateBingoBangoBongo()
            default:
                animateGeneric()
            }
        }
    }
    
    // MARK: - Format-Specific Animations
    
    func animateScramble() {
        switch animationStep {
        case 0:
            explanationText = "All 4 players tee off from the tee box"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
            showTrajectories = true
            ballPositions = [
                CGPoint(x: 150, y: 200),
                CGPoint(x: 170, y: 190),
                CGPoint(x: 160, y: 210),
                CGPoint(x: 180, y: 195)
            ]
        case 1:
            explanationText = "The team selects the best tee shot (Player 3's ball)"
            playerActions = [.walking, .walking, .pointing, .walking]
            ballPositions = [CGPoint(x: 180, y: 195)]
        case 2:
            explanationText = "All players move to the selected ball position"
            playerActions = [.walking, .walking, .walking, .walking]
        case 3:
            explanationText = "Everyone hits from the same spot"
            playerActions = [.swinging, .swinging, .swinging, .swinging]
            ballPositions = [
                CGPoint(x: 250, y: 150),
                CGPoint(x: 260, y: 145),
                CGPoint(x: 255, y: 155),
                CGPoint(x: 265, y: 150)
            ]
        case 4:
            explanationText = "Continue selecting best shot until the ball is holed"
            playerActions = [.putting, .watching, .watching, .watching]
            ballPositions = [CGPoint(x: 300, y: 100)]
        default:
            break
        }
    }
    
    func animateBestBall() {
        switch animationStep {
        case 0:
            explanationText = "All 4 players tee off with their own balls"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
            showTrajectories = true
            ballPositions = [
                CGPoint(x: 150, y: 200),
                CGPoint(x: 170, y: 190),
                CGPoint(x: 160, y: 210),
                CGPoint(x: 180, y: 195)
            ]
        case 1:
            explanationText = "Each player plays their own ball throughout the hole"
            playerActions = [.swinging, .swinging, .swinging, .swinging]
        case 2:
            explanationText = "Players finish with scores: 4, 5, 4, 6"
            playerActions = [.celebrating, .walking, .walking, .walking]
        case 3:
            explanationText = "Team takes the best score (4) for the hole"
            playerActions = [.celebrating, .watching, .celebrating, .watching]
        default:
            break
        }
    }
    
    func animateAlternateShot() {
        switch animationStep {
        case 0:
            explanationText = "Player 1 tees off on odd holes (this is hole 1)"
            playerActions = [.teeing, .watching, .watching, .watching]
            ballPositions = [CGPoint(x: 160, y: 200)]
        case 1:
            explanationText = "Player 2 hits the second shot"
            playerActions = [.watching, .swinging, .watching, .watching]
            ballPositions = [CGPoint(x: 220, y: 160)]
        case 2:
            explanationText = "Player 1 hits the third shot"
            playerActions = [.swinging, .watching, .watching, .watching]
            ballPositions = [CGPoint(x: 270, y: 120)]
        case 3:
            explanationText = "Player 2 putts"
            playerActions = [.watching, .putting, .watching, .watching]
        case 4:
            explanationText = "Partners 3 & 4 play the same way"
            playerActions = [.watching, .watching, .swinging, .watching]
        case 5:
            explanationText = "Continue alternating until both teams finish"
            playerActions = [.watching, .watching, .watching, .putting]
        default:
            break
        }
    }
    
    func animateMatchPlay() {
        switch animationStep {
        case 0:
            explanationText = "Player 1 vs Player 2 - both tee off"
            playerActions = [.teeing, .teeing, .watching, .watching]
            ballPositions = [
                CGPoint(x: 170, y: 190),
                CGPoint(x: 160, y: 200)
            ]
        case 1:
            explanationText = "Player 1 scores 4, Player 2 scores 5"
            playerActions = [.celebrating, .walking, .watching, .watching]
        case 2:
            explanationText = "Player 1 wins the hole and goes 1 UP"
            playerActions = [.celebrating, .watching, .watching, .watching]
        case 3:
            explanationText = "Match continues hole by hole until decided"
            playerActions = [.walking, .walking, .watching, .watching]
        default:
            break
        }
    }
    
    func animateSkins() {
        switch animationStep {
        case 0:
            explanationText = "All players compete for the 'skin' on each hole"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
            showTrajectories = true
        case 1:
            explanationText = "Players score: 4, 5, 4, 6"
            playerActions = [.putting, .walking, .putting, .walking]
        case 2:
            explanationText = "Tie! Players 1 & 3 both scored 4 - skin carries over"
            playerActions = [.watching, .watching, .watching, .watching]
        case 3:
            explanationText = "Next hole is now worth 2 skins!"
            playerActions = [.walking, .walking, .walking, .walking]
        default:
            break
        }
    }
    
    func animateWolf() {
        switch animationStep {
        case 0:
            explanationText = "Player 1 is the 'Wolf' this hole - watches others tee off"
            playerActions = [.watching, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Wolf watches Player 2's drive..."
            playerActions = [.thinking, .standing, .waiting, .waiting]
        case 2:
            explanationText = "Wolf chooses Player 2 as partner after seeing good drive!"
            playerActions = [.pointing, .celebrating, .watching, .watching]
        case 3:
            explanationText = "Team 1&2 vs Team 3&4 for this hole"
            playerActions = [.swinging, .swinging, .swinging, .swinging]
        case 4:
            explanationText = "Or Wolf could go 'Lone Wolf' for double points!"
            playerActions = [.celebrating, .watching, .watching, .watching]
        default:
            break
        }
    }
    
    func animateStableford() {
        switch animationStep {
        case 0:
            explanationText = "Players earn points based on their score"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Par = 2 pts, Birdie = 3 pts, Eagle = 4 pts, Bogey = 1 pt"
            playerActions = [.swinging, .swinging, .swinging, .swinging]
        case 2:
            explanationText = "Player 1 makes birdie (3 pts), Player 2 makes par (2 pts)"
            playerActions = [.celebrating, .walking, .walking, .walking]
        default:
            break
        }
    }
    
    func animateNassau() {
        switch animationStep {
        case 0:
            explanationText = "Three separate matches: Front 9, Back 9, and Total 18"
            playerActions = [.standing, .standing, .standing, .standing]
        case 1:
            explanationText = "Currently on hole 5 - Player 1 is 2 UP on front nine"
            playerActions = [.celebrating, .walking, .walking, .walking]
        case 2:
            explanationText = "Can 'press' when down by 2 to start a new bet"
            playerActions = [.thinking, .pointing, .watching, .watching]
        default:
            break
        }
    }
    
    func animateChapman() {
        switch animationStep {
        case 0:
            explanationText = "Both partners tee off"
            playerActions = [.teeing, .teeing, .watching, .watching]
            ballPositions = [
                CGPoint(x: 160, y: 200),
                CGPoint(x: 180, y: 195)
            ]
        case 1:
            explanationText = "Partners switch balls for second shot"
            playerActions = [.walking, .walking, .watching, .watching]
        case 2:
            explanationText = "Player 1 hits Player 2's ball, Player 2 hits Player 1's ball"
            playerActions = [.swinging, .swinging, .watching, .watching]
        case 3:
            explanationText = "After second shots, choose one ball to continue"
            playerActions = [.pointing, .watching, .watching, .watching]
        case 4:
            explanationText = "Alternate shots until holed"
            playerActions = [.putting, .watching, .watching, .watching]
        default:
            break
        }
    }
    
    func animateFourBall() {
        switch animationStep {
        case 0:
            explanationText = "Two teams of two - everyone plays their own ball"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Team 1: Players 1 & 2, Team 2: Players 3 & 4"
            playerActions = [.swinging, .swinging, .swinging, .swinging]
        case 2:
            explanationText = "Scores: P1=4, P2=5, P3=4, P4=6"
            playerActions = [.putting, .walking, .putting, .walking]
        case 3:
            explanationText = "Team 1 scores 4, Team 2 scores 4 - Hole is tied"
            playerActions = [.standing, .standing, .standing, .standing]
        default:
            break
        }
    }
    
    func animateFoursomes() {
        switch animationStep {
        case 0:
            explanationText = "True alternate shot from the start - Player 1 tees off odd holes"
            playerActions = [.teeing, .watching, .watching, .watching]
        case 1:
            explanationText = "Player 2 must hit second shot wherever it lies"
            playerActions = [.watching, .swinging, .watching, .watching]
        case 2:
            explanationText = "Player 1 hits third shot"
            playerActions = [.swinging, .watching, .watching, .watching]
        case 3:
            explanationText = "Continue alternating including putts"
            playerActions = [.watching, .putting, .watching, .watching]
        case 4:
            explanationText = "Team 2 (Players 3 & 4) play the same format"
            playerActions = [.watching, .watching, .teeing, .watching]
        case 5:
            explanationText = "Most difficult team format - requires perfect teamwork"
            playerActions = [.standing, .standing, .standing, .standing]
        default:
            break
        }
    }
    
    func animateTexasScramble() {
        switch animationStep {
        case 0:
            explanationText = "Like regular scramble but each player must contribute 4 drives"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Team selects best drive - tracking whose drives are used"
            playerActions = [.pointing, .watching, .watching, .watching]
        case 2:
            explanationText = "Player 1 has used 2 drives, Player 4 has used 0 so far"
            playerActions = [.standing, .standing, .standing, .thinking]
        case 3:
            explanationText = "Must strategically use weaker player's drives on easier holes"
            playerActions = [.walking, .walking, .walking, .teeing]
        case 4:
            explanationText = "Team handicap applied at end (10-25% of combined)"
            playerActions = [.celebrating, .celebrating, .celebrating, .celebrating]
        default:
            break
        }
    }
    
    func animateGreensome() {
        switch animationStep {
        case 0:
            explanationText = "Both partners tee off"
            playerActions = [.teeing, .teeing, .watching, .watching]
        case 1:
            explanationText = "Choose the best tee shot"
            playerActions = [.pointing, .watching, .watching, .watching]
        case 2:
            explanationText = "Partner whose ball wasn't chosen plays next shot"
            playerActions = [.watching, .swinging, .watching, .watching]
        case 3:
            explanationText = "Continue alternating shots from there"
            playerActions = [.swinging, .watching, .watching, .watching]
        case 4:
            explanationText = "Combines scramble start with alternate shot finish"
            playerActions = [.watching, .putting, .watching, .watching]
        default:
            break
        }
    }
    
    func animateVegas() {
        switch animationStep {
        case 0:
            explanationText = "Team 1 (P1 & P2) vs Team 2 (P3 & P4)"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Team 1 scores: 4 and 5 = 45 (lowest digit first)"
            playerActions = [.putting, .putting, .watching, .watching]
        case 2:
            explanationText = "Team 2 scores: 3 and 6 = 36"
            playerActions = [.watching, .watching, .celebrating, .putting]
        case 3:
            explanationText = "But wait! Player 3's birdie flips Team 1's score to 54! Team 2 wins big!"
            playerActions = [.watching, .watching, .celebrating, .celebrating]
        default:
            break
        }
    }
    
    func animateRabbit() {
        switch animationStep {
        case 0:
            explanationText = "All players compete - winner of hole gets the 'Rabbit'"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Player 2 wins this hole and takes the Rabbit"
            playerActions = [.watching, .celebrating, .watching, .watching]
        case 2:
            explanationText = "Player 2 holds the Rabbit - must defend it"
            playerActions = [.swinging, .swinging, .swinging, .swinging]
        case 3:
            explanationText = "Whoever has Rabbit on holes 9 & 18 wins!"
            playerActions = [.watching, .standing, .watching, .watching]
        default:
            break
        }
    }
    
    func animateDefender() {
        switch animationStep {
        case 0:
            explanationText = "Player 1 is the Defender this hole - plays alone vs other 3"
            playerActions = [.teeing, .watching, .watching, .watching]
        case 1:
            explanationText = "Other 3 players try to beat the Defender"
            playerActions = [.watching, .teeing, .teeing, .teeing]
        case 2:
            explanationText = "Best score of the 3 counts against Defender"
            playerActions = [.putting, .watching, .watching, .watching]
        case 3:
            explanationText = "Defender wins = 3 pts, Tie = 1 pt, Loss = 1 pt each to opponents"
            playerActions = [.celebrating, .watching, .watching, .watching]
        default:
            break
        }
    }
    
    func animateGhost() {
        switch animationStep {
        case 0:
            explanationText = "Playing against 'Ghost' who always makes par"
            playerActions = [.teeing, .standing, .standing, .standing]
        case 1:
            explanationText = "This is a par 4 - Ghost automatically scores 4"
            playerActions = [.swinging, .watching, .watching, .watching]
        case 2:
            explanationText = "Player makes 5 - Ghost wins this hole!"
            playerActions = [.walking, .standing, .standing, .standing]
        default:
            break
        }
    }
    
    func animateDots() {
        switch animationStep {
        case 0:
            explanationText = "Players earn 'dots' for various achievements"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Player 1 is first on green = 1 dot"
            playerActions = [.celebrating, .walking, .walking, .walking]
        case 2:
            explanationText = "Player 3 is closest to pin = 1 dot"
            playerActions = [.watching, .watching, .pointing, .watching]
        case 3:
            explanationText = "Player 2 makes birdie = 2 dots"
            playerActions = [.watching, .celebrating, .watching, .watching]
        case 4:
            explanationText = "Most dots at end wins!"
            playerActions = [.standing, .standing, .standing, .standing]
        default:
            break
        }
    }
    
    func animateString() {
        switch animationStep {
        case 0:
            explanationText = "Each player gets string based on handicap (1 foot per stroke)"
            playerActions = [.standing, .standing, .standing, .standing]
        case 1:
            explanationText = "Player 1 uses 6 inches to move ball from bad lie"
            playerActions = [.pointing, .watching, .watching, .watching]
        case 2:
            explanationText = "String is cut by amount used - strategic resource"
            playerActions = [.thinking, .watching, .watching, .watching]
        case 3:
            explanationText = "Can save string for crucial putts or hazard escapes"
            playerActions = [.putting, .watching, .watching, .watching]
        default:
            break
        }
    }
    
    func animateQuota() {
        switch animationStep {
        case 0:
            explanationText = "Each player has point quota (36 - handicap)"
            playerActions = [.standing, .standing, .standing, .standing]
        case 1:
            explanationText = "Points: Bogey=1, Par=2, Birdie=4, Eagle=8"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 2:
            explanationText = "Player 1 (15 handicap) needs 21 points to meet quota"
            playerActions = [.swinging, .watching, .watching, .watching]
        default:
            break
        }
    }
    
    func animateYellows() {
        switch animationStep {
        case 0:
            explanationText = "Two flags on green - regular and yellow (harder position)"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "Player 1 declares going for yellow flag - double points if successful"
            playerActions = [.pointing, .watching, .watching, .watching]
        case 2:
            explanationText = "Player 1 hits green near yellow = double points!"
            playerActions = [.celebrating, .watching, .watching, .watching]
        case 3:
            explanationText = "Risk/reward - missing green on yellow costs points"
            playerActions = [.standing, .standing, .standing, .standing]
        default:
            break
        }
    }
    
    func animateBridges() {
        switch animationStep {
        case 0:
            explanationText = "Make same score on consecutive holes to build 'bridges'"
            playerActions = [.putting, .watching, .watching, .watching]
        case 1:
            explanationText = "Player 1: Par-Par-Par = 3-hole bridge!"
            playerActions = [.celebrating, .watching, .watching, .watching]
        case 2:
            explanationText = "Longest bridge of the round wins"
            playerActions = [.standing, .standing, .standing, .standing]
        default:
            break
        }
    }
    
    func animateBingoBangoBongo() {
        switch animationStep {
        case 0:
            explanationText = "Three points available on each hole"
            playerActions = [.teeing, .teeing, .teeing, .teeing]
        case 1:
            explanationText = "BINGO: Player 2 is first on green = 1 point"
            playerActions = [.walking, .celebrating, .walking, .walking]
        case 2:
            explanationText = "BANGO: Player 4 is closest to pin once all on green = 1 point"
            playerActions = [.watching, .watching, .watching, .pointing]
        case 3:
            explanationText = "BONGO: Player 1 is first in hole = 1 point"
            playerActions = [.celebrating, .watching, .watching, .watching]
        case 4:
            explanationText = "Must play in proper order - furthest away plays first"
            playerActions = [.standing, .standing, .standing, .standing]
        default:
            break
        }
    }
    
    func animateGeneric() {
        explanationText = "Players compete according to \(format.name) rules"
        playerActions = [.swinging, .swinging, .swinging, .swinging]
    }
    
    // MARK: - Helper Functions
    
    func playerPosition(for index: Int) -> CGPoint {
        let baseY: CGFloat = 300
        let spacing: CGFloat = 60
        let startX: CGFloat = 100
        
        return CGPoint(
            x: startX + CGFloat(index) * spacing,
            y: baseY
        )
    }
    
    func currentAction(for playerIndex: Int) -> PlayerAction {
        guard playerIndex < playerActions.count else { return .standing }
        return playerActions[playerIndex]
    }
    
    func isPlayerActive(_ index: Int) -> Bool {
        guard index < playerActions.count else { return false }
        return playerActions[index] != .watching && playerActions[index] != .waiting
    }
    
    func ballColor(for index: Int) -> Color {
        if index < stickFigurePlayerColors.count {
            return stickFigurePlayerColors[index]
        }
        return .white
    }
    
    func nextStep() {
        if animationStep < totalSteps - 1 {
            animationStep += 1
            updateAnimationForCurrentStep()
        }
    }
    
    func previousStep() {
        if animationStep > 0 {
            animationStep -= 1
            updateAnimationForCurrentStep()
        }
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            startAutoPlay()
        }
    }
    
    func resetAnimation() {
        animationStep = 0
        isPlaying = false
        updateAnimationForCurrentStep()
    }
    
    func startAutoPlay() {
        guard isPlaying else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.isPlaying {
                if self.animationStep < self.totalSteps - 1 {
                    self.nextStep()
                    self.startAutoPlay()
                } else {
                    self.isPlaying = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StickFigurePlayer: View {
    let playerNumber: Int
    let position: CGPoint
    let action: PlayerAction
    let color: Color
    let isActive: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Player number badge
            Text("\(playerNumber)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(color)
                .clipShape(Circle())
                .offset(x: -15, y: -35)
            
            // Stick figure
            StickFigureShape(action: action, animationPhase: animationPhase)
                .stroke(isActive ? color : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 40, height: 50)
                .scaleEffect(isActive ? 1.1 : 1.0)
        }
        .position(position)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                animationPhase = 1
            }
        }
    }
}

struct StickFigureShape: Shape {
    let action: PlayerAction
    let animationPhase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let headRadius: CGFloat = 8
        let bodyLength: CGFloat = 20
        let armLength: CGFloat = 12
        let legLength: CGFloat = 15
        
        let centerX = rect.midX
        let headY = rect.minY + headRadius
        let bodyStartY = headY + headRadius
        let bodyEndY = bodyStartY + bodyLength
        
        // Head
        path.addEllipse(in: CGRect(
            x: centerX - headRadius,
            y: headY - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        ))
        
        // Body
        path.move(to: CGPoint(x: centerX, y: bodyStartY))
        path.addLine(to: CGPoint(x: centerX, y: bodyEndY))
        
        // Arms and legs based on action
        switch action {
        case .standing, .watching, .waiting:
            // Arms down
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX - armLength, y: bodyStartY + 15))
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX + armLength, y: bodyStartY + 15))
            
            // Legs straight
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX - 8, y: bodyEndY + legLength))
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX + 8, y: bodyEndY + legLength))
            
        case .teeing, .swinging:
            // Arms in swing position
            let swingAngle = animationPhase * .pi / 6
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(
                x: centerX - armLength * cos(swingAngle),
                y: bodyStartY + 5 - armLength * sin(swingAngle)
            ))
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(
                x: centerX + armLength * cos(swingAngle),
                y: bodyStartY + 5 - armLength * sin(swingAngle)
            ))
            
            // Club
            path.move(to: CGPoint(
                x: centerX + armLength * cos(swingAngle),
                y: bodyStartY + 5 - armLength * sin(swingAngle)
            ))
            path.addLine(to: CGPoint(
                x: centerX + armLength * cos(swingAngle) + 10,
                y: bodyStartY + 5 - armLength * sin(swingAngle) + 5
            ))
            
            // Legs in stance
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX - 10, y: bodyEndY + legLength))
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX + 10, y: bodyEndY + legLength))
            
        case .putting:
            // Arms in putting position
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX - 5, y: bodyStartY + 12))
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX + 5, y: bodyStartY + 12))
            
            // Putter
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 12))
            path.addLine(to: CGPoint(x: centerX, y: bodyEndY + 10))
            
            // Legs close together
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX - 5, y: bodyEndY + legLength))
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX + 5, y: bodyEndY + legLength))
            
        case .walking:
            // Arms swinging
            let walkPhase = animationPhase * .pi / 8
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(
                x: centerX - armLength * sin(walkPhase),
                y: bodyStartY + 15
            ))
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(
                x: centerX + armLength * sin(walkPhase),
                y: bodyStartY + 15
            ))
            
            // Legs walking
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(
                x: centerX - 8 - 5 * sin(walkPhase),
                y: bodyEndY + legLength
            ))
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(
                x: centerX + 8 + 5 * sin(walkPhase),
                y: bodyEndY + legLength
            ))
            
        case .celebrating:
            // Arms up
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX - armLength, y: bodyStartY - 5))
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX + armLength, y: bodyStartY - 5))
            
            // Legs jumping
            let jumpHeight = 3 * animationPhase
            path.move(to: CGPoint(x: centerX, y: bodyEndY - jumpHeight))
            path.addLine(to: CGPoint(x: centerX - 8, y: bodyEndY + legLength - jumpHeight))
            path.move(to: CGPoint(x: centerX, y: bodyEndY - jumpHeight))
            path.addLine(to: CGPoint(x: centerX + 8, y: bodyEndY + legLength - jumpHeight))
            
        case .pointing:
            // One arm pointing
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX - armLength, y: bodyStartY + 15))
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX + armLength + 5, y: bodyStartY + 2))
            
            // Legs normal
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX - 8, y: bodyEndY + legLength))
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX + 8, y: bodyEndY + legLength))
            
        case .thinking:
            // Hand on chin
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX - armLength, y: bodyStartY))
            path.addLine(to: CGPoint(x: centerX - 5, y: headY))
            path.move(to: CGPoint(x: centerX, y: bodyStartY + 5))
            path.addLine(to: CGPoint(x: centerX + armLength, y: bodyStartY + 15))
            
            // Legs normal
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX - 8, y: bodyEndY + legLength))
            path.move(to: CGPoint(x: centerX, y: bodyEndY))
            path.addLine(to: CGPoint(x: centerX + 8, y: bodyEndY + legLength))
        }
        
        return path
    }
}

struct GolfHoleCanvas: View {
    var body: some View {
        ZStack {
            // Fairway
            Path { path in
                path.move(to: CGPoint(x: 50, y: 350))
                path.addQuadCurve(
                    to: CGPoint(x: 350, y: 100),
                    control: CGPoint(x: 200, y: 200)
                )
                path.addLine(to: CGPoint(x: 380, y: 120))
                path.addQuadCurve(
                    to: CGPoint(x: 80, y: 370),
                    control: CGPoint(x: 230, y: 240)
                )
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 124/255, green: 179/255, blue: 66/255),
                        Color(red: 104/255, green: 159/255, blue: 56/255)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Tee box
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 84/255, green: 139/255, blue: 84/255))
                .frame(width: 80, height: 40)
                .position(x: 65, y: 340)
            
            // Green
            Ellipse()
                .fill(Color(red: 74/255, green: 129/255, blue: 74/255))
                .frame(width: 100, height: 80)
                .position(x: 340, y: 110)
            
            // Hole
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
                .position(x: 340, y: 110)
            
            // Flag
            ZStack {
                // Flag pole
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 40)
                
                // Flag
                Path { path in
                    path.move(to: CGPoint(x: 2, y: 0))
                    path.addLine(to: CGPoint(x: 20, y: 5))
                    path.addLine(to: CGPoint(x: 2, y: 10))
                    path.closeSubpath()
                }
                .fill(Color.red)
                .offset(y: -15)
            }
            .position(x: 340, y: 90)
            
            // Bunkers
            Ellipse()
                .fill(Color(red: 238/255, green: 203/255, blue: 173/255))
                .frame(width: 40, height: 30)
                .position(x: 280, y: 130)
            
            Ellipse()
                .fill(Color(red: 238/255, green: 203/255, blue: 173/255))
                .frame(width: 35, height: 25)
                .position(x: 180, y: 220)
            
            // Trees
            ForEach(0..<5) { i in
                TreeView()
                    .position(
                        x: CGFloat(100 + i * 60),
                        y: CGFloat(50 + i * 10)
                    )
            }
        }
    }
}

struct TreeView: View {
    var body: some View {
        ZStack {
            // Trunk
            Rectangle()
                .fill(Color(red: 101/255, green: 67/255, blue: 33/255))
                .frame(width: 6, height: 15)
                .offset(y: 7)
            
            // Foliage
            Circle()
                .fill(Color(red: 34/255, green: 139/255, blue: 34/255))
                .frame(width: 25, height: 25)
        }
    }
}

struct AnimatedGolfBallView: View {
    let position: CGPoint
    let color: Color
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 2)
                )
            
            if isAnimating {
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 1)
                    .frame(width: 15, height: 15)
                    .scaleEffect(isAnimating ? 1.5 : 1)
                    .opacity(isAnimating ? 0 : 1)
            }
        }
        .position(position)
    }
}

struct FormatBadge: View {
    let format: GolfFormat
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: format.icon)
                .font(.system(size: 16))
            Text(format.name)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(format.color)
        .cornerRadius(20)
    }
}

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
    }
}

// MARK: - Player Actions

enum PlayerAction {
    case standing
    case walking
    case teeing
    case swinging
    case putting
    case watching
    case celebrating
    case pointing
    case thinking
    case waiting
}

// MARK: - Hole Layout

struct HoleLayout {
    let teeBox = CGPoint(x: 65, y: 340)
    let fairway = CGPoint(x: 200, y: 225)
    let green = CGPoint(x: 340, y: 110)
    let hole = CGPoint(x: 340, y: 110)
}

// Player colors for stick figure animations
let stickFigurePlayerColors: [Color] = [
    .blue,
    .green,
    .orange,
    .purple
]