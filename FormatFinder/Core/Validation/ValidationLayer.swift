import Foundation

// MARK: - Validation Layer
/// Comprehensive validation layer for data integrity and safe operations
public final class ValidationLayer {
    
    // MARK: - Validation Results
    
    /// Result of a validation operation
    public enum ValidationResult<T> {
        case valid(T)
        case invalid(ValidationError)
        case needsConfirmation(T, String)
        
        var isValid: Bool {
            switch self {
            case .valid:
                return true
            case .invalid, .needsConfirmation:
                return false
            }
        }
        
        func getValue() -> T? {
            switch self {
            case .valid(let value), .needsConfirmation(let value, _):
                return value
            case .invalid:
                return nil
            }
        }
    }
    
    /// Validation errors
    public enum ValidationError: LocalizedError {
        case invalidScore(Int)
        case missingData(String)
        case duplicateEntry(String)
        case invalidHandicap(Int)
        case invalidPlayerCount(Int, String)
        case inconsistentData(String)
        case invalidCourse(String)
        case invalidDate
        case outOfRange(String, Any, Any)
        
        public var errorDescription: String? {
            switch self {
            case .invalidScore(let score):
                return "Invalid score: \(score). \(GolfConstants.ErrorMessages.invalidScore)"
            case .missingData(let field):
                return "Missing required data: \(field)"
            case .duplicateEntry(let identifier):
                return "Duplicate entry found: \(identifier)"
            case .invalidHandicap(let handicap):
                return "Invalid handicap: \(handicap). \(GolfConstants.ErrorMessages.invalidHandicap)"
            case .invalidPlayerCount(let count, let format):
                return "Invalid player count (\(count)) for \(format) format"
            case .inconsistentData(let message):
                return "Data inconsistency: \(message)"
            case .invalidCourse(let message):
                return "Invalid course data: \(message)"
            case .invalidDate:
                return "Invalid date provided"
            case .outOfRange(let field, let value, let range):
                return "\(field) value \(value) is out of valid range: \(range)"
            }
        }
    }
    
    // MARK: - Score Validation
    
    /// Validate a single score
    /// - Parameter score: Score to validate
    /// - Returns: Validation result
    public static func validateScore(_ score: Int) -> ValidationResult<Int> {
        guard score >= GolfConstants.ScoreValidation.minimumScore else {
            return .invalid(.invalidScore(score))
        }
        
        guard score <= GolfConstants.ScoreValidation.maximumScore else {
            return .invalid(.invalidScore(score))
        }
        
        if score >= GolfConstants.ScoreValidation.suspiciousHighScore {
            return .needsConfirmation(score, "High score of \(score) entered. Please confirm.")
        }
        
        return .valid(score)
    }
    
    /// Validate score with par context
    /// - Parameters:
    ///   - score: Score to validate
    ///   - par: Par for the hole
    /// - Returns: Validation result with contextual messages
    public static func validateScoreForPar(_ score: Int, par: Int) -> ValidationResult<Int> {
        let baseValidation = validateScore(score)
        
        switch baseValidation {
        case .invalid:
            return baseValidation
        case .valid(let validScore), .needsConfirmation(let validScore, _):
            // Check for exceptional scores
            if score == GolfConstants.ScoreValidation.aceScorePar3 && par == 3 {
                return .needsConfirmation(validScore, GolfConstants.ConfirmationMessages.holeInOne(holeName: "this hole"))
            }
            
            if score == GolfConstants.ScoreValidation.albatrossScorePar4 && par == 4 {
                return .needsConfirmation(validScore, GolfConstants.ConfirmationMessages.albatross(holeName: "this hole"))
            }
            
            if score == GolfConstants.ScoreValidation.doubleEagleScorePar5 && par == 5 {
                return .needsConfirmation(validScore, GolfConstants.ConfirmationMessages.albatross(holeName: "this hole"))
            }
            
            let scoreToPar = score - par
            if scoreToPar >= 5 {
                return .needsConfirmation(validScore, GolfConstants.ConfirmationMessages.suspiciousScore(score: score, par: par))
            }
            
            if scoreToPar <= -3 {
                return .needsConfirmation(validScore, GolfConstants.ConfirmationMessages.exceptionalScore(score: score, par: par))
            }
            
            return .valid(validScore)
        }
    }
    
    /// Validate an array of scores
    /// - Parameter scores: Array of scores to validate
    /// - Returns: Validation result with all scores or first error
    public static func validateScores(_ scores: [Int]) -> ValidationResult<[Int]> {
        var validatedScores: [Int] = []
        
        for score in scores {
            let result = validateScore(score)
            switch result {
            case .valid(let validScore):
                validatedScores.append(validScore)
            case .invalid(let error):
                return .invalid(error)
            case .needsConfirmation(let score, _):
                // For batch validation, include suspicious scores but flag the array
                validatedScores.append(score)
            }
        }
        
        // Check if any scores need confirmation
        let suspiciousCount = scores.filter { $0 >= GolfConstants.ScoreValidation.suspiciousHighScore }.count
        if suspiciousCount > 0 {
            return .needsConfirmation(validatedScores, "\(suspiciousCount) score(s) may need review")
        }
        
        return .valid(validatedScores)
    }
    
    // MARK: - Handicap Validation
    
    /// Validate handicap value
    /// - Parameter handicap: Handicap to validate
    /// - Returns: Validation result
    public static func validateHandicap(_ handicap: Int) -> ValidationResult<Int> {
        guard handicap >= 0 && handicap <= 54 else {
            return .invalid(.invalidHandicap(handicap))
        }
        return .valid(handicap)
    }
    
    // MARK: - Player Count Validation
    
    /// Validate player count for a specific format
    /// - Parameters:
    ///   - playerCount: Number of players
    ///   - format: Game format
    /// - Returns: Validation result
    public static func validatePlayerCount(_ playerCount: Int, for format: String) -> ValidationResult<Int> {
        switch format.lowercased() {
        case "scramble":
            guard playerCount >= GolfConstants.GameFormats.scrambleMinPlayers &&
                  playerCount <= GolfConstants.GameFormats.scrambleMaxPlayers else {
                return .invalid(.invalidPlayerCount(playerCount, format))
            }
        case "match play", "matchplay":
            guard playerCount == GolfConstants.GameFormats.matchPlayMaxPlayers else {
                return .invalid(.invalidPlayerCount(playerCount, format))
            }
        case "skins", "nassau", "best ball", "bestball":
            guard playerCount >= 2 && playerCount <= 4 else {
                return .invalid(.invalidPlayerCount(playerCount, format))
            }
        case "stroke play", "strokeplay", "stableford":
            guard playerCount >= 1 else {
                return .invalid(.invalidPlayerCount(playerCount, format))
            }
        default:
            // Unknown format, allow any reasonable player count
            guard playerCount >= 1 && playerCount <= 8 else {
                return .invalid(.invalidPlayerCount(playerCount, format))
            }
        }
        
        return .valid(playerCount)
    }
    
    // MARK: - Course Validation
    
    /// Validate course data
    /// - Parameters:
    ///   - pars: Array of par values for each hole
    ///   - distances: Optional array of distances for each hole
    /// - Returns: Validation result
    public static func validateCourse(pars: [Int], distances: [Double]? = nil) -> ValidationResult<(pars: [Int], distances: [Double]?)> {
        // Check hole count
        guard pars.count == 9 || pars.count == 18 else {
            return .invalid(.invalidCourse("Course must have 9 or 18 holes"))
        }
        
        // Validate par values
        for (index, par) in pars.enumerated() {
            guard par >= 3 && par <= 5 else {
                return .invalid(.invalidCourse("Invalid par \(par) for hole \(index + 1)"))
            }
        }
        
        // Validate distances if provided
        if let distances = distances {
            guard distances.count == pars.count else {
                return .invalid(.invalidCourse("Distance count doesn't match hole count"))
            }
            
            for (index, distance) in distances.enumerated() {
                guard distance > 0 && distance < 700 else {
                    return .invalid(.invalidCourse("Invalid distance \(distance) for hole \(index + 1)"))
                }
            }
        }
        
        return .valid((pars: pars, distances: distances))
    }
    
    // MARK: - Round Validation
    
    /// Complete round validation
    public struct RoundValidation {
        let scores: [Int]
        let pars: [Int]
        let date: Date
        let playerId: String
        let courseId: String
        let handicap: Int?
        
        /// Perform complete validation
        public func validate() -> ValidationResult<RoundValidation> {
            // Validate scores
            let scoresResult = ValidationLayer.validateScores(scores)
            guard case .valid = scoresResult else {
                return scoresResult.map { _ in self }
            }
            
            // Validate course
            let courseResult = ValidationLayer.validateCourse(pars: pars)
            guard case .valid = courseResult else {
                return courseResult.map { _ in self }
            }
            
            // Validate score count matches par count
            guard scores.count == pars.count else {
                return .invalid(.inconsistentData("Score count doesn't match hole count"))
            }
            
            // Validate handicap if provided
            if let handicap = handicap {
                let handicapResult = ValidationLayer.validateHandicap(handicap)
                guard case .valid = handicapResult else {
                    return handicapResult.map { _ in self }
                }
            }
            
            // Validate date (not in future)
            guard date <= Date() else {
                return .invalid(.invalidDate)
            }
            
            // Check for suspicious scores in context
            var needsReview = false
            var reviewMessages: [String] = []
            
            for (index, (score, par)) in zip(scores, pars).enumerated() {
                let contextResult = ValidationLayer.validateScoreForPar(score, par: par)
                if case .needsConfirmation(_, let message) = contextResult {
                    needsReview = true
                    reviewMessages.append("Hole \(index + 1): \(message)")
                }
            }
            
            if needsReview {
                return .needsConfirmation(self, reviewMessages.joined(separator: "\n"))
            }
            
            return .valid(self)
        }
    }
    
    // MARK: - Safe Unwrapping Helpers
    
    /// Safely unwrap optional with default value
    /// - Parameters:
    ///   - optional: Optional value to unwrap
    ///   - defaultValue: Default value if nil
    /// - Returns: Unwrapped value or default
    public static func unwrapOr<T>(_ optional: T?, default defaultValue: T) -> T {
        return optional ?? defaultValue
    }
    
    /// Safely unwrap optional with validation
    /// - Parameters:
    ///   - optional: Optional value to unwrap
    ///   - fieldName: Name of field for error message
    /// - Returns: Validation result
    public static func unwrapRequired<T>(_ optional: T?, fieldName: String) -> ValidationResult<T> {
        guard let value = optional else {
            return .invalid(.missingData(fieldName))
        }
        return .valid(value)
    }
    
    /// Safely unwrap array of optionals, filtering nils
    /// - Parameter optionals: Array of optional values
    /// - Returns: Array of non-nil values
    public static func compactUnwrap<T>(_ optionals: [T?]) -> [T] {
        return optionals.compactMap { $0 }
    }
    
    // MARK: - Data Integrity Checks
    
    /// Check for duplicate entries
    /// - Parameters:
    ///   - items: Array of items to check
    ///   - keyPath: Key path to identifier property
    /// - Returns: Validation result
    public static func checkDuplicates<T, ID: Hashable>(
        in items: [T],
        by keyPath: KeyPath<T, ID>
    ) -> ValidationResult<[T]> {
        var seen = Set<ID>()
        
        for item in items {
            let id = item[keyPath: keyPath]
            if seen.contains(id) {
                return .invalid(.duplicateEntry(String(describing: id)))
            }
            seen.insert(id)
        }
        
        return .valid(items)
    }
    
    /// Validate data consistency across related objects
    /// - Parameters:
    ///   - primaryCount: Count of primary items
    ///   - relatedCount: Count of related items
    ///   - relationship: Description of relationship
    /// - Returns: Validation result
    public static func validateConsistency(
        primaryCount: Int,
        relatedCount: Int,
        relationship: String
    ) -> ValidationResult<Bool> {
        guard primaryCount == relatedCount else {
            return .invalid(.inconsistentData("\(relationship): expected \(primaryCount), got \(relatedCount)"))
        }
        return .valid(true)
    }
    
    // MARK: - Batch Validation
    
    /// Perform multiple validations and collect all errors
    /// - Parameter validations: Array of validation closures
    /// - Returns: Combined validation result
    public static func batchValidate(_ validations: [() -> ValidationResult<Any>]) -> ValidationResult<[Any]> {
        var results: [Any] = []
        var errors: [ValidationError] = []
        var confirmations: [String] = []
        
        for validation in validations {
            let result = validation()
            switch result {
            case .valid(let value):
                results.append(value)
            case .invalid(let error):
                errors.append(error)
            case .needsConfirmation(let value, let message):
                results.append(value)
                confirmations.append(message)
            }
        }
        
        if !errors.isEmpty {
            // Return first error
            return .invalid(errors.first!)
        }
        
        if !confirmations.isEmpty {
            return .needsConfirmation(results, confirmations.joined(separator: "\n"))
        }
        
        return .valid(results)
    }
}