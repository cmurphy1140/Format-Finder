import SwiftUI

struct GolfFormat: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let description: String
    let tagline: String
    let players: String
    let difficulty: String
    let isTeamFormat: Bool
    let overview: [String]
    let rules: [String]
    let strategy: [String]
    let hasDiagramSlides: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(icon)
    }
    
    static func == (lhs: GolfFormat, rhs: GolfFormat) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    static let allFormats: [GolfFormat] = [
        GolfFormat(
            name: "Scramble",
            icon: "flag.fill",
            color: .green,
            description: "All players tee off, choose the best shot, and everyone plays from there",
            tagline: "Teamwork at its finest",
            players: "2-4 per team",
            difficulty: "Beginner",
            isTeamFormat: true,
            overview: [
                "Perfect for charity tournaments and casual play",
                "Reduces pressure on individual players",
                "Speeds up play significantly"
            ],
            rules: [
                "All team members tee off on each hole",
                "The team selects the best shot",
                "All players hit from that spot",
                "Continue until the ball is holed",
                "Record one score for the team"
            ],
            strategy: [
                "Put your longest hitter first to set up good drives",
                "Save your best putter for last",
                "Use each player's strengths strategically"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Best Ball",
            icon: "star.fill",
            color: .blue,
            description: "Each player plays their own ball, team takes the best score on each hole",
            tagline: "Play your game, help your team",
            players: "2-4 per team",
            difficulty: "Intermediate",
            isTeamFormat: true,
            overview: [
                "Each player plays their own ball throughout",
                "Team score is the lowest individual score",
                "Great for mixed skill levels"
            ],
            rules: [
                "Everyone plays their own ball",
                "Record each player's score",
                "Team score is the lowest score on each hole",
                "Can be played as stroke or match play",
                "Handicaps can be applied individually"
            ],
            strategy: [
                "Play aggressively - your partner has your back",
                "Focus on your strengths",
                "Support struggling partners mentally"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Alternate Shot",
            icon: "arrow.left.arrow.right",
            color: .purple,
            description: "Partners alternate hitting the same ball until holed",
            tagline: "True partnership golf",
            players: "2 per team",
            difficulty: "Advanced",
            isTeamFormat: true,
            overview: [
                "Ultimate test of partnership",
                "Requires great communication",
                "Used in Ryder Cup and Presidents Cup"
            ],
            rules: [
                "Partners alternate shots with the same ball",
                "Player A tees off odd holes, Player B even holes",
                "Continue alternating until holed",
                "Penalties don't affect the rotation",
                "One score per team per hole"
            ],
            strategy: [
                "Know your partner's strengths and weaknesses",
                "Leave comfortable shots for your partner",
                "Stay positive after poor shots"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Stableford",
            icon: "chart.bar.fill",
            color: .orange,
            description: "Point-based scoring that rewards aggressive play",
            tagline: "Go for broke!",
            players: "Any",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Points awarded based on score relative to par",
                "Higher points for better scores",
                "Bad holes don't kill your round"
            ],
            rules: [
                "Eagle or better: 4+ points",
                "Birdie: 3 points",
                "Par: 2 points",
                "Bogey: 1 point",
                "Double bogey or worse: 0 points",
                "Modified versions can adjust point values"
            ],
            strategy: [
                "Be aggressive - no penalty for big numbers",
                "Go for birdies and eagles",
                "Pick up after double bogey to speed play"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Skins",
            icon: "dollarsign.circle.fill",
            color: .yellow,
            description: "Win a hole outright to win the 'skin' - ties carry over",
            tagline: "Winner takes all",
            players: "2-4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Each hole is worth a 'skin'",
                "Must win hole outright",
                "Tied holes carry over value"
            ],
            rules: [
                "Each hole has a value (skin)",
                "Lowest score wins the skin",
                "Ties carry skin to next hole",
                "Carried skins accumulate",
                "Can play with or without handicaps"
            ],
            strategy: [
                "Stay aggressive when skins carry over",
                "Know when to play safe vs risk",
                "Pressure builds on carried holes"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Wolf",
            icon: "moon.fill",
            color: .indigo,
            description: "Rotating captain chooses to play alone or with a partner",
            tagline: "Hunt alone or with the pack",
            players: "4",
            difficulty: "Advanced",
            isTeamFormat: false,
            overview: [
                "Rotating 'Wolf' chooses partners",
                "Can go 'Lone Wolf' for double points",
                "Strategic partnership selection"
            ],
            rules: [
                "Players rotate being the 'Wolf'",
                "Wolf watches others tee off",
                "Can choose partner after their shot",
                "Or go 'Lone Wolf' before teeing off",
                "Points: 1 for team win, 2 for Lone Wolf win, 3 for beating Lone Wolf"
            ],
            strategy: [
                "Watch tee shots before choosing partners",
                "Go Lone Wolf on your strongest holes",
                "Track points to know when to gamble"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Nassau",
            icon: "divide.circle.fill",
            color: .teal,
            description: "Three separate bets: front nine, back nine, and overall 18",
            tagline: "Three matches in one",
            players: "2-4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Three separate competitions",
                "Front 9, Back 9, and Total 18",
                "Can press bets when down"
            ],
            rules: [
                "Three separate matches scored simultaneously",
                "Front nine (holes 1-9)",
                "Back nine (holes 10-18)",
                "Overall 18 holes",
                "Can 'press' to start new bet when down 2"
            ],
            strategy: [
                "Manage three matches mentally",
                "Know when to press bets",
                "Stay focused even if losing one segment"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Match Play",
            icon: "flag.2.crossed.fill",
            color: .red,
            description: "Hole-by-hole competition, win by winning more holes",
            tagline: "Every hole is a new battle",
            players: "2 or 4",
            difficulty: "Intermediate",
            isTeamFormat: false,
            overview: [
                "Win individual holes, not total strokes",
                "Match decided by holes won",
                "Can concede holes or putts"
            ],
            rules: [
                "Win hole with lowest score",
                "Tied holes are 'halved'",
                "Match score: 2-up, 1-down, All Square, etc.",
                "Match ends when mathematically decided",
                "Concessions are part of the game"
            ],
            strategy: [
                "Play the opponent, not the course",
                "Know when to be aggressive",
                "Mental game is crucial"
            ],
            hasDiagramSlides: true
        ),
        
        GolfFormat(
            name: "Chapman",
            icon: "person.2.fill",
            color: .mint,
            description: "Both players tee off, switch balls for second shot, then choose one to finish",
            tagline: "Strategic partner play",
            players: "2 per team",
            difficulty: "Advanced",
            isTeamFormat: true,
            overview: [
                "Unique format mixing strategies",
                "Tests all aspects of partnership",
                "Used in USGA championships"
            ],
            rules: [
                "Both players tee off",
                "Players switch balls for second shot",
                "After second shots, choose one ball",
                "Alternate shots until holed",
                "Strategic format requiring thought"
            ],
            strategy: [
                "Consider partner's strengths on tee shots",
                "Leave good angles for second shots",
                "Choose ball based on position and who's next"
            ],
            hasDiagramSlides: false
        ),
        
        GolfFormat(
            name: "Bingo Bango Bongo",
            icon: "target",
            color: .brown,
            description: "Points for first on green, closest to pin, and first in hole",
            tagline: "Three ways to score",
            players: "2-4",
            difficulty: "Beginner",
            isTeamFormat: false,
            overview: [
                "Three points available per hole",
                "Rewards different achievements",
                "Keeps everyone engaged"
            ],
            rules: [
                "Bingo: First ball on green (1 point)",
                "Bango: Closest to pin once all on green (1 point)",
                "Bongo: First ball in hole (1 point)",
                "Must play in proper order",
                "Furthest from hole plays first"
            ],
            strategy: [
                "Accuracy rewarded over distance",
                "Smart course management pays off",
                "Stay ready when others struggle"
            ],
            hasDiagramSlides: false
        )
    ]
}