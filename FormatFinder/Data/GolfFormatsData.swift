import Foundation
import SwiftUI

// MARK: - Additional Golf Formats Data

let golfFormats = GolfFormat.allFormats

// Extension to add category property
extension GolfFormat {
    var category: String {
        switch name {
        case "Scramble", "Best Ball", "Alternate Shot", "Four-Ball", "Chapman":
            return "Tournament"
        case "Skins", "Nassau", "Bingo Bango Bongo", "Wolf", "Vegas":
            return "Betting"
        case "Match Play", "Stableford":
            return "Tournament"
        default:
            return "Other"
        }
    }
    
    var type: String {
        isTeamFormat ? "Team" : "Individual"
    }
    
    var howToPlay: [String] {
        return rules
    }
    
    var example: String {
        switch name {
        case "Scramble":
            return "Team of 4: All tee off, choose John's drive. All hit from John's ball position."
        case "Best Ball":
            return "Hole 1: Player A scores 4, Player B scores 5. Team score is 4."
        case "Match Play":
            return "Player A wins 3 holes, Player B wins 2, 4 holes halved. Player A wins 3&2."
        case "Skins":
            return "Hole 1 ($10): Players tie, carries to Hole 2 ($20 total). Player C wins with birdie."
        case "Stableford":
            return "Par 4: Score 3 (birdie) = 3 points. Score 4 (par) = 2 points."
        default:
            return description
        }
    }
}