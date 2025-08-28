import Foundation

// MARK: - Golf Constants
/// Centralized constants for the entire golf scoring system
public enum GolfConstants {
    
    // MARK: - Par Estimation
    public enum ParEstimation {
        /// Maximum distance in yards for a par 3
        public static let par3MaxDistance: Double = 250
        
        /// Maximum distance in yards for a par 4
        public static let par4MaxDistance: Double = 470
        
        /// Minimum distance typically for a par 3
        public static let par3MinDistance: Double = 100
        
        /// Typical par 4 minimum distance
        public static let par4MinDistance: Double = 250
        
        /// Typical par 5 minimum distance
        public static let par5MinDistance: Double = 470
    }
    
    // MARK: - Score Validation
    public enum ScoreValidation {
        /// Minimum valid score for a hole
        public static let minimumScore: Int = 1
        
        /// Maximum reasonable score for a hole
        public static let maximumScore: Int = 20
        
        /// Maximum score considered suspicious (needs confirmation)
        public static let suspiciousHighScore: Int = 10
        
        /// Score that triggers hole-in-one confirmation on par 3
        public static let aceScorePar3: Int = 1
        
        /// Score that triggers albatross confirmation on par 4
        public static let albatrossScorePar4: Int = 1
        
        /// Score that triggers double-eagle confirmation on par 5
        public static let doubleEagleScorePar5: Int = 2
    }
    
    // MARK: - Handicap Recommendations
    public enum HandicapRecommendations {
        /// Maximum handicap difference for competitive match play
        public static let matchPlayMaxDifference: Int = 8
        
        /// Maximum handicap difference for stroke play
        public static let strokePlayMaxDifference: Int = 12
        
        /// Minimum handicap difference to recommend scramble
        public static let scrambleRecommendedDifference: Int = 15
        
        /// Handicap difference for best ball recommendation
        public static let bestBallRecommendedDifference: Int = 10
    }
    
    // MARK: - Statistical Analysis
    public enum Statistics {
        /// Minimum rounds needed for trend analysis
        public static let minimumRoundsForTrend: Int = 3
        
        /// Number of recent rounds to consider for trends
        public static let recentRoundsWindow: Int = 10
        
        /// Percentage change to indicate improving trend
        public static let improvingTrendThreshold: Double = -2.0
        
        /// Percentage change to indicate declining trend
        public static let decliningTrendThreshold: Double = 2.0
        
        /// Minimum hole plays to identify as trouble hole
        public static let minimumPlaysForTroubleHole: Int = 5
        
        /// Score above average to mark as trouble hole
        public static let troubleHoleThreshold: Double = 1.5
        
        /// Score below average to mark as good hole
        public static let goodHoleThreshold: Double = -0.5
    }
    
    // MARK: - Game Formats
    public enum GameFormats {
        /// Default skin value
        public static let defaultSkinValue: Int = 1
        
        /// Default Nassau points per match
        public static let defaultNassauPoints: Int = 1
        
        /// Maximum players for match play
        public static let matchPlayMaxPlayers: Int = 2
        
        /// Minimum players for scramble
        public static let scrambleMinPlayers: Int = 2
        
        /// Maximum players for scramble
        public static let scrambleMaxPlayers: Int = 4
        
        /// Default number of holes
        public static let standardRoundHoles: Int = 18
        
        /// Front nine holes
        public static let frontNineHoles: Int = 9
        
        /// Back nine start hole
        public static let backNineStartHole: Int = 10
    }
    
    // MARK: - Stableford Points
    public enum StablefordPoints {
        public static let albatross: Int = 5
        public static let eagle: Int = 4
        public static let birdie: Int = 3
        public static let par: Int = 2
        public static let bogey: Int = 1
        public static let doubleBogeyOrWorse: Int = 0
    }
    
    // MARK: - Score Names
    public enum ScoreNames {
        public static func name(forScoreToPar scoreToPar: Int) -> String {
            switch scoreToPar {
            case ...(-4): return "Condor"
            case -3: return "Albatross"
            case -2: return "Eagle"
            case -1: return "Birdie"
            case 0: return "Par"
            case 1: return "Bogey"
            case 2: return "Double Bogey"
            case 3: return "Triple Bogey"
            default: return "+\(scoreToPar)"
            }
        }
    }
    
    // MARK: - Error Messages
    public enum ErrorMessages {
        public static let invalidScore = "Score must be between 1 and 20"
        public static let missingHoleData = "Missing score data for hole"
        public static let duplicateHoleEntry = "Duplicate entry for hole"
        public static let insufficientPlayers = "Not enough players for this format"
        public static let invalidHandicap = "Handicap must be between 0 and 54"
        public static let noDataAvailable = "No data available for analysis"
        public static let calculationError = "Error calculating score"
    }
    
    // MARK: - Par Management Integration
    public enum ParManagement {
        /// Get par service instance
        public static var service: ParManagementService {
            return ParManagementService.shared
        }
        
        /// Quick access to par for hole
        public static func parForHole(_ hole: Int) -> Int {
            return service.getParForHole(hole)
        }
        
        /// Quick access to scoring context
        public static func scoringContext(for hole: Int) -> (par: Int, yardage: Int, handicap: Int) {
            return service.getScoringContext(for: hole)
        }
    }
    
    // MARK: - Par Defaults
    public enum ParDefaults {
        public static let defaultPar: Int = 4
        public static let defaultYardage: Int = 385
        public static let frontNinePar: Int = 36
        public static let backNinePar: Int = 36
        public static let standardRoundPar: Int = 72
    }
    
    // MARK: - Confirmation Messages
    public enum ConfirmationMessages {
        public static func suspiciousScore(score: Int, par: Int) -> String {
            let scoreName = ScoreNames.name(forScoreToPar: score - par)
            return "You entered a \(score) on a par \(par) (\(scoreName)). Is this correct?"
        }
        
        public static func holeInOne(holeName: String) -> String {
            return "Hole in one on \(holeName)! Congratulations! Please confirm."
        }
        
        public static func albatross(holeName: String) -> String {
            return "Albatross on \(holeName)! Amazing shot! Please confirm."
        }
        
        public static func exceptionalScore(score: Int, par: Int) -> String {
            return "Exceptional score! \(score) on a par \(par). Please confirm."
        }
        
        /// Enhanced confirmation using par service
        public static func suspiciousScore(score: Int, hole: Int) -> String {
            let par = ParManagement.parForHole(hole)
            return suspiciousScore(score: score, par: par)
        }
        
        public static func exceptionalScore(score: Int, hole: Int) -> String {
            let par = ParManagement.parForHole(hole)
            return exceptionalScore(score: score, par: par)
        }
    }
}