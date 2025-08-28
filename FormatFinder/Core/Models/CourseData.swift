import Foundation

// MARK: - Course Data Models

/// Represents a single hole's information
public struct HoleInfo: Codable, Equatable, Identifiable {
    public let id = UUID()
    public let holeNumber: Int
    public let par: Int
    public let yardage: Int
    public let handicapRank: Int
    public let name: String?
    
    public init(holeNumber: Int, par: Int, yardage: Int, handicapRank: Int, name: String? = nil) {
        self.holeNumber = holeNumber
        self.par = par
        self.yardage = yardage
        self.handicapRank = handicapRank
        self.name = name
    }
}

/// Represents a complete golf course
public struct Course: Codable, Equatable, Identifiable {
    public let id = UUID()
    public let name: String
    public let holes: [HoleInfo]
    public let totalPar: Int
    public let totalYardage: Int
    
    public init(name: String, holes: [HoleInfo]) {
        self.name = name
        self.holes = holes
        self.totalPar = holes.reduce(0) { $0 + $1.par }
        self.totalYardage = holes.reduce(0) { $0 + $1.yardage }
    }
}

// MARK: - Par Management Service

/// Centralized service for managing par values throughout the application
public class ParManagementService: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = ParManagementService()
    private init() {}
    
    // MARK: - Properties
    @Published public private(set) var currentCourse: Course?
    @Published public private(set) var isUsingGenericCourse: Bool = true
    
    // MARK: - Default Course Data
    /// Standard 18-hole par layout used when no specific course is loaded
    private let standardPars = [4, 4, 3, 5, 4, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5]
    private let standardYardages = [380, 420, 165, 520, 385, 405, 175, 390, 495, 375, 410, 155, 510, 385, 395, 410, 170, 535]
    private let standardHandicaps = [7, 1, 17, 3, 13, 5, 15, 9, 11, 8, 2, 18, 4, 14, 6, 10, 16, 12]
    
    /// Generic course used as fallback
    private lazy var genericCourse: Course = {
        let holes = (1...18).map { hole in
            HoleInfo(
                holeNumber: hole,
                par: standardPars[hole - 1],
                yardage: standardYardages[hole - 1],
                handicapRank: standardHandicaps[hole - 1],
                name: "Hole \(hole)"
            )
        }
        return Course(name: "Standard Course", holes: holes)
    }()
    
    // MARK: - Public Methods
    
    /// Get par for a specific hole
    public func getParForHole(_ hole: Int) -> Int {
        guard hole >= 1 && hole <= 18 else { return 4 }
        
        let course = currentCourse ?? genericCourse
        if let holeInfo = course.holes.first(where: { $0.holeNumber == hole }) {
            return holeInfo.par
        }
        
        // Fallback to standard pars if hole not found
        let index = (hole - 1) % standardPars.count
        return standardPars[index]
    }
    
    /// Get all par values for the current course
    public func getAllPars() -> [Int] {
        let course = currentCourse ?? genericCourse
        return course.holes.sorted { $0.holeNumber < $1.holeNumber }.map { $0.par }
    }
    
    /// Get par values for a specific range of holes
    public func getPars(for holes: Range<Int>) -> [Int] {
        return holes.map { getParForHole($0) }
    }
    
    /// Get yardage for a specific hole
    public func getYardageForHole(_ hole: Int) -> Int {
        guard hole >= 1 && hole <= 18 else { return 385 }
        
        let course = currentCourse ?? genericCourse
        if let holeInfo = course.holes.first(where: { $0.holeNumber == hole }) {
            return holeInfo.yardage
        }
        
        let index = (hole - 1) % standardYardages.count
        return standardYardages[index]
    }
    
    /// Get handicap rank for a specific hole
    public func getHandicapRankForHole(_ hole: Int) -> Int {
        guard hole >= 1 && hole <= 18 else { return hole }
        
        let course = currentCourse ?? genericCourse
        if let holeInfo = course.holes.first(where: { $0.holeNumber == hole }) {
            return holeInfo.handicapRank
        }
        
        let index = (hole - 1) % standardHandicaps.count
        return standardHandicaps[index]
    }
    
    /// Get complete hole information
    public func getHoleInfo(_ hole: Int) -> HoleInfo? {
        let course = currentCourse ?? genericCourse
        return course.holes.first(where: { $0.holeNumber == hole })
    }
    
    /// Calculate total par for a range of holes
    public func calculateTotalPar(from startHole: Int, to endHole: Int) -> Int {
        return (startHole...endHole).reduce(0) { $0 + getParForHole($1) }
    }
    
    /// Set a custom course
    public func setCourse(_ course: Course) {
        currentCourse = course
        isUsingGenericCourse = false
    }
    
    /// Reset to generic course
    public func useGenericCourse() {
        currentCourse = nil
        isUsingGenericCourse = true
    }
    
    /// Load course from JSON data
    public func loadCourse(from data: Data) throws {
        let course = try JSONDecoder().decode(Course.self, from: data)
        setCourse(course)
    }
    
    /// Check if current hole setup is valid
    public func validateHoleSetup() -> Bool {
        let course = currentCourse ?? genericCourse
        return course.holes.count == 18 && 
               course.holes.allSatisfy { $0.par >= 3 && $0.par <= 5 }
    }
}

// MARK: - Par Management Extensions

extension ParManagementService {
    
    /// Get scoring context for a hole (par + yardage + handicap)
    public func getScoringContext(for hole: Int) -> (par: Int, yardage: Int, handicap: Int) {
        return (
            par: getParForHole(hole),
            yardage: getYardageForHole(hole),
            handicap: getHandicapRankForHole(hole)
        )
    }
    
    /// Determine score name relative to par
    public func getScoreName(score: Int, hole: Int) -> String {
        let par = getParForHole(hole)
        let scoreToPar = score - par
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
    
    /// Check if score needs confirmation based on par
    public func shouldConfirmScore(_ score: Int, hole: Int) -> Bool {
        let par = getParForHole(hole)
        let scoreToPar = score - par
        
        // Confirm exceptional scores
        return scoreToPar <= -2 || scoreToPar >= 3
    }
}

// MARK: - Par Management Constants

/// Default values used when course data is unavailable
public enum ParDefaults {
    public static let defaultPar: Int = 4
    public static let defaultYardage: Int = 385
    public static let frontNinePar: Int = 36
    public static let backNinePar: Int = 36
    public static let standardRoundPar: Int = 72
}