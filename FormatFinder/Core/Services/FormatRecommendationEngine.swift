import Foundation
import SwiftUI

// MARK: - Format Recommendation Engine
/// Analyzes group composition and recommends appropriate golf formats
final class FormatRecommendationEngine {
    
    // MARK: - Recommendation Model
    struct FormatRecommendation: Identifiable {
        let id = UUID()
        let format: GolfFormat
        let confidence: Double // 0.0 to 1.0
        let reason: String
        let pros: [String]
        let considerations: [String]?
        
        var isHighlyRecommended: Bool {
            confidence >= 0.8
        }
    }
    
    // MARK: - Group Analysis
    struct GroupAnalysis {
        let playerCount: Int
        let handicapSpread: Int
        let averageHandicap: Double
        let skillDistribution: SkillDistribution
        let hasBeginners: Bool
        let hasAdvanced: Bool
        let isMixedSkill: Bool
    }
    
    enum SkillDistribution {
        case uniform        // All similar skill levels
        case bimodal        // Two distinct skill groups
        case scattered      // Wide range of skills
        case skewedLow      // Mostly low handicappers
        case skewedHigh     // Mostly high handicappers
    }
    
    // MARK: - Main Recommendation Function
    static func recommendFormats(
        for players: [Player],
        preferences: FormatPreferences = FormatPreferences()
    ) -> [FormatRecommendation] {
        guard !players.isEmpty else { return [] }
        
        // Analyze group composition
        let analysis = analyzeGroup(players)
        
        // Generate recommendations
        var recommendations: [FormatRecommendation] = []
        
        // Scramble recommendation
        recommendations.append(contentsOf: evaluateScramble(analysis, preferences))
        
        // Match Play recommendation
        recommendations.append(contentsOf: evaluateMatchPlay(analysis, preferences))
        
        // Best Ball recommendation
        recommendations.append(contentsOf: evaluateBestBall(analysis, preferences))
        
        // Stableford recommendation
        recommendations.append(contentsOf: evaluateStableford(analysis, preferences))
        
        // Skins recommendation
        recommendations.append(contentsOf: evaluateSkins(analysis, preferences))
        
        // Nassau recommendation
        recommendations.append(contentsOf: evaluateNassau(analysis, preferences))
        
        // Alternate Shot recommendation
        recommendations.append(contentsOf: evaluateAlternateShot(analysis, preferences))
        
        // Wolf recommendation
        recommendations.append(contentsOf: evaluateWolf(analysis, preferences))
        
        // Sort by confidence
        return recommendations.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Group Analysis
    private static func analyzeGroup(_ players: [Player]) -> GroupAnalysis {
        let handicaps = players.map { $0.handicap }
        let minHandicap = handicaps.min() ?? 0
        let maxHandicap = handicaps.max() ?? 0
        let handicapSpread = maxHandicap - minHandicap
        let averageHandicap = Double(handicaps.reduce(0, +)) / Double(players.count)
        
        // Determine skill distribution
        let distribution: SkillDistribution = {
            if handicapSpread <= 5 {
                return .uniform
            } else if handicapSpread > 20 {
                return .scattered
            } else {
                let lowCount = handicaps.filter { $0 <= 10 }.count
                let highCount = handicaps.filter { $0 >= 20 }.count
                let midCount = handicaps.filter { $0 > 10 && $0 < 20 }.count
                
                if midCount <= 1 && lowCount > 0 && highCount > 0 {
                    return .bimodal
                } else if lowCount > highCount * 2 {
                    return .skewedLow
                } else if highCount > lowCount * 2 {
                    return .skewedHigh
                } else {
                    return .scattered
                }
            }
        }()
        
        return GroupAnalysis(
            playerCount: players.count,
            handicapSpread: handicapSpread,
            averageHandicap: averageHandicap,
            skillDistribution: distribution,
            hasBeginners: handicaps.contains(where: { $0 >= 25 }),
            hasAdvanced: handicaps.contains(where: { $0 <= 5 }),
            isMixedSkill: handicapSpread > 10
        )
    }
    
    // MARK: - Format Evaluations
    
    private static func evaluateScramble(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Scramble" }) else { return [] }
        guard analysis.playerCount >= 2 && analysis.playerCount <= 4 else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        var considerations: [String]? = nil
        
        // High handicap spread strongly suggests scramble
        if analysis.handicapSpread >= 15 {
            confidence = 0.95
            reason = "Perfect for your group! The large skill difference (spread of \(analysis.handicapSpread) strokes) makes scramble ideal - everyone contributes and has fun."
            pros = [
                "Keeps all players engaged regardless of skill",
                "Faster pace of play",
                "Less pressure on individual shots"
            ]
        } else if analysis.hasBeginners {
            confidence = 0.9
            reason = "Great choice for beginners in your group. Scramble format reduces pressure and helps new players learn."
            pros = [
                "Beginners can contribute without pressure",
                "Experienced players can guide shot selection",
                "Team success over individual struggle"
            ]
        } else if preferences.preferTeamPlay {
            confidence = 0.8
            reason = "Excellent team format that encourages collaboration and strategy."
            pros = [
                "True team experience",
                "Strategic shot selection",
                "Builds camaraderie"
            ]
        } else if analysis.playerCount == 4 {
            confidence = 0.7
            reason = "Classic format for a foursome that keeps the game moving."
            pros = [
                "Optimal for 4 players",
                "Balanced team dynamics",
                "Fun for all skill levels"
            ]
        } else {
            confidence = 0.6
            reason = "Solid team format option for your group."
            pros = ["Team collaboration", "Reduced pressure", "Faster play"]
        }
        
        if analysis.skillDistribution == .uniform && !preferences.preferTeamPlay {
            confidence *= 0.7
            considerations = ["Similar skill levels might prefer individual competition"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: considerations
        )]
    }
    
    private static func evaluateMatchPlay(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Match Play" }) else { return [] }
        guard analysis.playerCount == 2 || analysis.playerCount == 4 else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        var considerations: [String]? = nil
        
        if analysis.playerCount == 2 && analysis.handicapSpread <= 8 {
            confidence = 0.9
            reason = "Ideal for head-to-head competition! Your similar skill levels (within \(analysis.handicapSpread) strokes) will create exciting hole-by-hole battles."
            pros = [
                "Pure competition format",
                "Every hole is a fresh start",
                "Strategic risk/reward decisions"
            ]
        } else if preferences.preferCompetitive && analysis.handicapSpread <= 12 {
            confidence = 0.85
            reason = "Great competitive format that can use handicaps to level the playing field."
            pros = [
                "Handicap strokes balance competition",
                "Hole-by-hole excitement",
                "Bad holes don't ruin the match"
            ]
        } else if analysis.playerCount == 4 && analysis.skillDistribution == .bimodal {
            confidence = 0.75
            reason = "Four-ball match play works well with your skill distribution - pair stronger with weaker players."
            pros = [
                "Natural team pairings",
                "Balanced competition",
                "Team strategy elements"
            ]
        } else {
            confidence = 0.6
            reason = "Classic competitive format for your group."
            pros = ["Hole-by-hole competition", "Strategic play", "Traditional format"]
        }
        
        if analysis.handicapSpread > 15 {
            confidence *= 0.6
            considerations = ["Large skill gap might make matches one-sided even with handicaps"]
        }
        
        if analysis.hasBeginners {
            confidence *= 0.7
            considerations = (considerations ?? []) + ["Beginners might feel pressure in direct competition"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: considerations
        )]
    }
    
    private static func evaluateBestBall(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Best Ball" }) else { return [] }
        guard analysis.playerCount >= 2 && analysis.playerCount <= 4 else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        
        if analysis.isMixedSkill && preferences.preferIndividualPlay {
            confidence = 0.85
            reason = "Perfect balance! Everyone plays their own ball while contributing to team success. Great for mixed skills."
            pros = [
                "Individual play with team scoring",
                "No pressure to perform every shot",
                "Natural handicap balancing"
            ]
        } else if analysis.playerCount == 4 && analysis.skillDistribution == .scattered {
            confidence = 0.8
            reason = "Ideal for your diverse skill levels - everyone can contribute their good holes."
            pros = [
                "Everyone plays at their pace",
                "Team benefits from good individual holes",
                "Less pressure than scramble"
            ]
        } else if preferences.preferTeamPlay && preferences.preferIndividualPlay {
            confidence = 0.75
            reason = "Best of both worlds - play your own game while supporting the team."
            pros = [
                "Hybrid format appeals to all",
                "Maintains individual rhythm",
                "Team camaraderie without dependence"
            ]
        } else {
            confidence = 0.65
            reason = "Good team format that maintains individual play."
            pros = ["Play your own ball", "Team scoring", "Flexible format"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: nil
        )]
    }
    
    private static func evaluateStableford(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Stableford" }) else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        
        if analysis.averageHandicap >= 18 {
            confidence = 0.85
            reason = "Excellent for higher handicappers! The point system rewards good holes and minimizes damage from bad ones."
            pros = [
                "Bad holes don't destroy your round",
                "Encourages aggressive play",
                "Speeds up play (pick up when out of points)"
            ]
        } else if analysis.hasBeginners || preferences.preferFastPlay {
            confidence = 0.8
            reason = "Great format that keeps pace moving and reduces frustration from high scores."
            pros = [
                "Can pick up after double bogey",
                "Focus on scoring opportunities",
                "Less math than stroke play"
            ]
        } else if analysis.skillDistribution == .skewedHigh {
            confidence = 0.75
            reason = "Point system works well for your group's skill level."
            pros = [
                "Rewards good play",
                "Minimizes blow-up holes",
                "Clear scoring system"
            ]
        } else {
            confidence = 0.6
            reason = "Alternative scoring format that rewards aggressive play."
            pros = ["Different scoring dynamic", "Rewards birdies", "Strategic decisions"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: nil
        )]
    }
    
    private static func evaluateSkins(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Skins" }) else { return [] }
        guard analysis.playerCount >= 2 && analysis.playerCount <= 4 else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        var considerations: [String]? = nil
        
        if analysis.skillDistribution == .uniform && preferences.preferCompetitive {
            confidence = 0.85
            reason = "Perfect for your evenly matched group! Every hole becomes a mini-tournament with carryovers adding excitement."
            pros = [
                "High excitement on every hole",
                "Carryovers create big moments",
                "Simple format everyone understands"
            ]
        } else if preferences.preferBetting && analysis.handicapSpread <= 10 {
            confidence = 0.8
            reason = "Great betting game for your group with manageable skill differences."
            pros = [
                "Natural betting format",
                "Dramatic moments",
                "Can use handicaps for fairness"
            ]
        } else if analysis.playerCount == 3 {
            confidence = 0.75
            reason = "Skins works particularly well with three players."
            pros = [
                "Perfect for threesome",
                "Every hole matters",
                "Exciting finishes"
            ]
        } else {
            confidence = 0.65
            reason = "Classic competitive format with built-in excitement."
            pros = ["Simple rules", "Exciting carryovers", "Every hole counts"]
        }
        
        if analysis.handicapSpread > 15 {
            considerations = ["Better players might dominate without proper handicapping"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: considerations
        )]
    }
    
    private static func evaluateNassau(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Nassau" }) else { return [] }
        guard analysis.playerCount == 2 || analysis.playerCount == 4 else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        
        if preferences.preferBetting && analysis.skillDistribution == .uniform {
            confidence = 0.85
            reason = "The classic betting game! Three matches in one keeps everyone engaged throughout the round."
            pros = [
                "Multiple chances to win",
                "Automatic press options",
                "Traditional betting format"
            ]
        } else if analysis.playerCount == 2 && preferences.preferCompetitive {
            confidence = 0.75
            reason = "Three separate competitions keep the match interesting even if one nine goes poorly."
            pros = [
                "Fresh start on back nine",
                "Multiple winning opportunities",
                "Strategic press decisions"
            ]
        } else {
            confidence = 0.65
            reason = "Popular format with three built-in matches."
            pros = ["Front, back, and total", "Press opportunities", "Classic format"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: nil
        )]
    }
    
    private static func evaluateAlternateShot(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Alternate Shot" }) else { return [] }
        guard analysis.playerCount == 2 || analysis.playerCount == 4 else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        var considerations: [String]? = nil
        
        if analysis.playerCount == 4 && analysis.skillDistribution == .bimodal {
            confidence = 0.75
            reason = "Great for pairing stronger and weaker players - creates balanced teams and learning opportunities."
            pros = [
                "True partnership golf",
                "Strategic team play",
                "Unique challenge"
            ]
        } else if preferences.preferTeamPlay && !analysis.hasBeginners {
            confidence = 0.7
            reason = "Ultimate team format requiring trust and strategy."
            pros = [
                "Builds partnerships",
                "Different strategic decisions",
                "Fast pace of play"
            ]
        } else {
            confidence = 0.5
            reason = "Challenging format for experienced players."
            pros = ["True teamwork", "Unique format", "Strategic play"]
        }
        
        if analysis.hasBeginners {
            confidence *= 0.5
            considerations = ["Very challenging for beginners", "Requires good communication"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: considerations
        )]
    }
    
    private static func evaluateWolf(
        _ analysis: GroupAnalysis,
        _ preferences: FormatPreferences
    ) -> [FormatRecommendation] {
        guard let format = GolfFormat.allFormats.first(where: { $0.name == "Wolf" }) else { return [] }
        guard analysis.playerCount == 4 else { return [] }
        
        var confidence: Double = 0.5
        var reason = ""
        var pros: [String] = []
        var considerations: [String]? = nil
        
        if !analysis.hasBeginners && preferences.preferCompetitive {
            confidence = 0.75
            reason = "Strategic format perfect for experienced foursomes who want variety."
            pros = [
                "Different partnerships each hole",
                "Strategic captain decisions",
                "Risk/reward elements"
            ]
        } else if analysis.skillDistribution == .uniform {
            confidence = 0.7
            reason = "Interesting format with rotating partnerships and strategic decisions."
            pros = [
                "Changing dynamics",
                "Captain strategy",
                "Lone wolf options"
            ]
        } else {
            confidence = 0.5
            reason = "Complex but engaging format for foursomes."
            pros = ["Variety each hole", "Strategic depth", "Unique format"]
        }
        
        if analysis.hasBeginners {
            confidence *= 0.4
            considerations = ["Complex rules for beginners", "Requires understanding of strategy"]
        }
        
        return [FormatRecommendation(
            format: format,
            confidence: confidence,
            reason: reason,
            pros: pros,
            considerations: considerations
        )]
    }
}

// MARK: - Format Preferences
struct FormatPreferences {
    var preferTeamPlay: Bool = false
    var preferIndividualPlay: Bool = false
    var preferCompetitive: Bool = true
    var preferBetting: Bool = false
    var preferFastPlay: Bool = false
    var avoidComplexRules: Bool = false
}