import Foundation
import SwiftUI
import CoreML

// MARK: - Gesture Score Service
// Interprets swipe gestures and predicts intended scores based on player behavior

@MainActor
final class GestureScoreService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isCalibrating = false
    @Published private(set) var currentProfile: GestureProfile?
    @Published private(set) var scorePredictions: ScoreProbabilityDistribution?
    
    // MARK: - Private Properties
    
    private var playerProfiles: [UUID: GestureProfile] = [:]
    private var gestureHistory: [UUID: [GestureRecord]] = [:]
    private let defaultProfile = GestureProfile.standard
    
    // MARK: - Singleton
    
    static let shared = GestureScoreService()
    
    private init() {
        loadStoredProfiles()
    }
    
    // MARK: - Public Methods
    
    /// Interpret a swipe gesture and return the intended score change
    func interpretGesture(_ swipe: SwipeData, for player: Player) -> ScoreChange {
        let profile = playerProfiles[player.id] ?? defaultProfile
        
        // Calculate base score change from distance
        let baseChange = calculateBaseChange(
            distance: swipe.distance,
            sensitivity: profile.sensitivity
        )
        
        // Apply velocity multiplier for faster swipes
        let velocityMultiplier = calculateVelocityMultiplier(
            velocity: swipe.velocity,
            style: profile.swipeStyle
        )
        
        // Determine final score change
        let finalChange = Int(round(Double(baseChange) * velocityMultiplier))
        
        // Calculate confidence based on gesture clarity
        let confidence = calculateGestureConfidence(swipe, profile: profile)
        
        // Record gesture for learning
        recordGesture(swipe, player: player, scoreChange: finalChange)
        
        return ScoreChange(
            value: finalChange,
            direction: swipe.direction,
            confidence: confidence,
            animationStyle: determineAnimationStyle(swipe)
        )
    }
    
    /// Pre-calculate score probabilities for a player on a specific hole
    func preCalculateProbabilities(for player: Player, hole: Int, holePar: Int? = nil) -> ScoreProbabilityDistribution {
        let holePar = holePar ?? GolfConstants.ParManagement.holeParForHole(hole)
        // Fetch player's scoring history
        let history = fetchScoringHistory(for: player, holePar: holePar)
        
        // Calculate current form (last 3-5 holes)
        let recentForm = calculateRecentForm(for: player, holesBack: 5)
        
        // Generate probability distribution
        let distribution = generateProbabilityDistribution(
            history: history,
            recentForm: recentForm,
            holePar: holePar
        )
        
        // Cache the predictions
        self.scorePredictions = distribution
        
        return distribution
    }
    
    /// Calibrate gesture profile for a player
    func calibrateProfile(for player: Player, with samples: [SwipeData]) {
        isCalibrating = true
        
        Task {
            let profile = await buildProfile(from: samples, playerId: player.id)
            
            await MainActor.run {
                self.playerProfiles[player.id] = profile
                self.currentProfile = profile
                self.isCalibrating = false
                self.saveProfiles()
            }
        }
    }
    
    /// Get or create profile for player
    func getProfile(for player: Player) -> GestureProfile {
        if let profile = playerProfiles[player.id] {
            return profile
        } else {
            let newProfile = createDefaultProfile(for: player)
            playerProfiles[player.id] = newProfile
            saveProfiles()
            return newProfile
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateBaseChange(distance: Double, sensitivity: Double) -> Int {
        // Map swipe distance to score change
        // Short swipe: 1 stroke, Medium: 2-3, Long: 4+
        let normalizedDistance = distance * sensitivity
        
        switch normalizedDistance {
        case 0..<50:
            return 1
        case 50..<100:
            return 2
        case 100..<150:
            return 3
        case 150..<200:
            return 4
        case 200..<250:
            return 5
        default:
            return min(6, Int(normalizedDistance / 50))
        }
    }
    
    private func calculateVelocityMultiplier(velocity: Double, style: SwipeStyle) -> Double {
        // Fast swipes amplify the change for aggressive swipers
        let normalizedVelocity = velocity / 1000.0 // pixels/second to normalized
        
        switch style {
        case .gentle:
            // Gentle swipers need more velocity for multiplier
            return 1.0 + (normalizedVelocity * 0.2)
        case .moderate:
            // Standard velocity curve
            return 1.0 + (normalizedVelocity * 0.4)
        case .aggressive:
            // Aggressive swipers get higher multipliers
            return 1.0 + (normalizedVelocity * 0.6)
        }
    }
    
    private func calculateGestureConfidence(_ swipe: SwipeData, profile: GestureProfile) -> Double {
        var confidence = 0.0
        
        // Straight swipes are more confident
        let straightness = abs(swipe.endX - swipe.startX) / swipe.distance
        confidence += (1.0 - straightness) * 0.4
        
        // Consistent velocity is more confident
        let velocityConsistency = 1.0 - (swipe.velocityVariance / swipe.velocity)
        confidence += velocityConsistency * 0.3
        
        // Duration in sweet spot (not too fast, not too slow)
        let idealDuration = 0.3 // seconds
        let durationScore = 1.0 - abs(swipe.duration - idealDuration) / idealDuration
        confidence += max(0, durationScore) * 0.3
        
        return min(1.0, confidence)
    }
    
    private func determineAnimationStyle(_ swipe: SwipeData) -> AnimationStyle {
        // Choose animation based on gesture characteristics
        if swipe.velocity > 2000 {
            return .bounce
        } else if swipe.distance > 200 {
            return .smooth
        } else {
            return .quick
        }
    }
    
    private func recordGesture(_ swipe: SwipeData, player: Player, scoreChange: Int) {
        let record = GestureRecord(
            timestamp: Date(),
            swipeData: swipe,
            resultingScoreChange: scoreChange,
            playerId: player.id
        )
        
        if gestureHistory[player.id] == nil {
            gestureHistory[player.id] = []
        }
        gestureHistory[player.id]?.append(record)
        
        // Keep only last 100 gestures per player
        if let count = gestureHistory[player.id]?.count, count > 100 {
            gestureHistory[player.id]?.removeFirst(count - 100)
        }
    }
    
    private func fetchScoringHistory(for player: Player, holePar: Int) -> ScoringHistory {
        // In a real app, this would fetch from Core Data
        // For now, return mock data based on handicap
        let avgScore = Double(holePar) + Double(player.handicap) / 18.0
        
        return ScoringHistory(
            averageScore: avgScore,
            standardDeviation: 1.2,
            scoreCounts: [
                holePar - 2: 2,
                holePar - 1: 8,
                holePar: 35,
                holePar + 1: 30,
                holePar + 2: 15,
                holePar + 3: 7,
                holePar + 4: 3
            ]
        )
    }
    
    private func calculateRecentForm(for player: Player, holesBack: Int) -> RecentForm {
        // In a real app, fetch from game state
        // For now, return estimated form
        return RecentForm(
            trend: .steady,
            lastScores: [],
            confidence: 0.75
        )
    }
    
    private func generateProbabilityDistribution(
        history: ScoringHistory,
        recentForm: RecentForm,
        holePar: Int
    ) -> ScoreProbabilityDistribution {
        
        var probabilities: [Int: Double] = [:]
        let mostLikely = Int(round(history.averageScore))
        
        // Generate bell curve around average
        for score in (holePar - 3)...(holePar + 5) {
            let distance = Double(score) - history.averageScore
            let probability = gaussianProbability(
                x: Double(score),
                mean: history.averageScore,
                stdDev: history.standardDeviation
            )
            probabilities[score] = probability
        }
        
        // Normalize probabilities to sum to 1.0
        let sum = probabilities.values.reduce(0, +)
        for (score, prob) in probabilities {
            probabilities[score] = prob / sum
        }
        
        return ScoreProbabilityDistribution(
            mostLikely: mostLikely,
            distribution: probabilities,
            preloadRange: (holePar - 2)...(holePar + 4),
            confidence: recentForm.confidence
        )
    }
    
    private func gaussianProbability(x: Double, mean: Double, stdDev: Double) -> Double {
        let exponent = -pow(x - mean, 2) / (2 * pow(stdDev, 2))
        return exp(exponent) / (stdDev * sqrt(2 * .pi))
    }
    
    private func buildProfile(from samples: [SwipeData], playerId: UUID) async -> GestureProfile {
        // Analyze samples to determine swipe style
        let avgVelocity = samples.map { $0.velocity }.reduce(0, +) / Double(samples.count)
        let avgDistance = samples.map { $0.distance }.reduce(0, +) / Double(samples.count)
        
        let style: SwipeStyle
        if avgVelocity < 800 {
            style = .gentle
        } else if avgVelocity < 1500 {
            style = .moderate
        } else {
            style = .aggressive
        }
        
        // Calculate sensitivity based on average distance for single score change
        let sensitivity = 100.0 / avgDistance
        
        return GestureProfile(
            playerId: playerId,
            swipeStyle: style,
            sensitivity: sensitivity,
            preferredHand: .right, // Could be detected from swipe patterns
            calibrationDate: Date()
        )
    }
    
    private func createDefaultProfile(for player: Player) -> GestureProfile {
        // Create profile based on player characteristics
        // Younger or lower handicap players might prefer aggressive style
        let style: SwipeStyle = player.handicap < 10 ? .aggressive : .moderate
        
        return GestureProfile(
            playerId: player.id,
            swipeStyle: style,
            sensitivity: 1.0,
            preferredHand: .right,
            calibrationDate: Date()
        )
    }
    
    // MARK: - Persistence
    
    private func loadStoredProfiles() {
        guard let data = UserDefaults.standard.data(forKey: "GestureProfiles"),
              let profiles = try? JSONDecoder().decode([UUID: GestureProfile].self, from: data) else {
            return
        }
        self.playerProfiles = profiles
    }
    
    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(playerProfiles) else { return }
        UserDefaults.standard.set(data, forKey: "GestureProfiles")
    }
}

// MARK: - Supporting Types

struct SwipeData {
    let velocity: Double
    let distance: Double
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
    let duration: TimeInterval
    let velocityVariance: Double
    let direction: SwipeDirection
    
    init(
        velocity: Double,
        distance: Double,
        startPoint: CGPoint,
        endPoint: CGPoint,
        duration: TimeInterval,
        velocityVariance: Double = 0
    ) {
        self.velocity = velocity
        self.distance = distance
        self.startX = startPoint.x
        self.startY = startPoint.y
        self.endX = endPoint.x
        self.endY = endPoint.y
        self.duration = duration
        self.velocityVariance = velocityVariance
        
        // Determine direction
        let deltaY = endPoint.y - startPoint.y
        self.direction = deltaY < 0 ? .up : .down
    }
}

enum SwipeDirection {
    case up
    case down
}

struct ScoreChange {
    let value: Int
    let direction: SwipeDirection
    let confidence: Double
    let animationStyle: AnimationStyle
}

enum AnimationStyle {
    case quick
    case smooth
    case bounce
}

struct GestureProfile: Codable {
    let playerId: UUID
    let swipeStyle: SwipeStyle
    let sensitivity: Double
    let preferredHand: Hand
    let calibrationDate: Date
    
    static let standard = GestureProfile(
        playerId: UUID(),
        swipeStyle: .moderate,
        sensitivity: 1.0,
        preferredHand: .right,
        calibrationDate: Date()
    )
}

enum SwipeStyle: String, Codable {
    case gentle
    case moderate
    case aggressive
}

enum Hand: String, Codable {
    case left
    case right
}

struct GestureRecord {
    let timestamp: Date
    let swipeData: SwipeData
    let resultingScoreChange: Int
    let playerId: UUID
}

struct ScoreProbabilityDistribution {
    let mostLikely: Int
    let distribution: [Int: Double]
    let preloadRange: ClosedRange<Int>
    let confidence: Double
}

struct ScoringHistory {
    let averageScore: Double
    let standardDeviation: Double
    let scoreCounts: [Int: Int]
}

struct RecentForm {
    let trend: FormTrend
    let lastScores: [Int]
    let confidence: Double
}

enum FormTrend {
    case improving
    case steady
    case declining
}