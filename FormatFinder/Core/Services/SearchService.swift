import Foundation
import SwiftUI

// MARK: - Search Service
/// Enhanced search with fuzzy matching, recent searches, and alternate names
final class SearchService: ObservableObject {
    
    // MARK: - Properties
    @Published var recentSearches: [String] = []
    @Published var recentlyPlayed: [String] = []
    private let maxRecentSearches = 5
    private let maxRecentlyPlayed = 3
    
    // User defaults keys
    private let recentSearchesKey = "RecentSearches"
    private let recentlyPlayedKey = "RecentlyPlayed"
    
    // Format alternate names mapping
    private let alternateNames: [String: [String]] = [
        "Scramble": ["Texas Scramble", "Florida Scramble", "Team Scramble"],
        "Best Ball": ["Four Ball", "Better Ball", "Fourball"],
        "Match Play": ["Head to Head", "Hole by Hole", "Match"],
        "Skins": ["Skins Game", "Skin Game"],
        "Stableford": ["Modified Stableford", "Points", "Point System"],
        "Nassau": ["2-2-2", "Three Way", "Front Back Total"],
        "Alternate Shot": ["Foursomes", "Scotch Foursomes", "Alternate"],
        "Vegas": ["Las Vegas", "Team Vegas"],
        "Wolf": ["Lone Wolf", "Wolf Game"],
        "Bingo Bango Bongo": ["BBB", "Three Points", "Bingo"]
    ]
    
    // MARK: - Initialization
    init() {
        loadRecentSearches()
        loadRecentlyPlayed()
    }
    
    // MARK: - Search Functions
    
    /// Search formats with fuzzy matching and alternate names
    func searchFormats(_ query: String, in formats: [GolfFormat]) -> [GolfFormat] {
        guard !query.isEmpty else {
            // Return formats sorted by recently played
            return sortByRecency(formats)
        }
        
        let lowercaseQuery = query.lowercased()
        var matchedFormats: [(format: GolfFormat, score: Double)] = []
        
        for format in formats {
            var bestScore: Double = 0
            
            // Check main name
            let nameScore = fuzzyMatch(query: lowercaseQuery, target: format.name.lowercased())
            bestScore = max(bestScore, nameScore)
            
            // Check alternate names
            if let alternates = alternateNames[format.name] {
                for alternate in alternates {
                    let altScore = fuzzyMatch(query: lowercaseQuery, target: alternate.lowercased())
                    bestScore = max(bestScore, altScore)
                }
            }
            
            // Check description
            let descScore = fuzzyMatch(query: lowercaseQuery, target: format.description.lowercased()) * 0.5
            bestScore = max(bestScore, descScore)
            
            // Check if query matches difficulty or player count
            if format.difficulty.lowercased().contains(lowercaseQuery) {
                bestScore = max(bestScore, 0.6)
            }
            if format.players.lowercased().contains(lowercaseQuery) {
                bestScore = max(bestScore, 0.6)
            }
            
            // Add to results if score is high enough
            if bestScore > 0.3 {
                matchedFormats.append((format: format, score: bestScore))
            }
        }
        
        // Sort by score and return
        return matchedFormats
            .sorted { $0.score > $1.score }
            .map { $0.format }
    }
    
    /// Fuzzy string matching algorithm
    private func fuzzyMatch(query: String, target: String) -> Double {
        // Exact match
        if target == query {
            return 1.0
        }
        
        // Contains match
        if target.contains(query) {
            let lengthRatio = Double(query.count) / Double(target.count)
            return 0.8 + (0.2 * lengthRatio)
        }
        
        // Starts with match
        if target.hasPrefix(query) {
            return 0.9
        }
        
        // Levenshtein distance for typos
        let distance = levenshteinDistance(query, target)
        let maxLength = max(query.count, target.count)
        if maxLength == 0 { return 0 }
        
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        
        // Only consider if similarity is reasonable
        if similarity > 0.6 {
            return similarity * 0.7
        }
        
        // Check if all query characters exist in target (any order)
        let queryChars = Set(query)
        let targetChars = Set(target)
        let intersection = queryChars.intersection(targetChars)
        if intersection.count == queryChars.count {
            return 0.4
        }
        
        return 0
    }
    
    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        if s1Array.isEmpty { return s2Array.count }
        if s2Array.isEmpty { return s1Array.count }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)
        
        for i in 0...s1Array.count {
            matrix[i][0] = i
        }
        
        for j in 0...s2Array.count {
            matrix[0][j] = j
        }
        
        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                if s1Array[i-1] == s2Array[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = min(
                        matrix[i-1][j] + 1,    // deletion
                        matrix[i][j-1] + 1,    // insertion
                        matrix[i-1][j-1] + 1   // substitution
                    )
                }
            }
        }
        
        return matrix[s1Array.count][s2Array.count]
    }
    
    /// Sort formats by recently played
    private func sortByRecency(_ formats: [GolfFormat]) -> [GolfFormat] {
        return formats.sorted { format1, format2 in
            let index1 = recentlyPlayed.firstIndex(of: format1.name) ?? Int.max
            let index2 = recentlyPlayed.firstIndex(of: format2.name) ?? Int.max
            return index1 < index2
        }
    }
    
    // MARK: - Recent Searches Management
    
    /// Add a search query to recent searches
    func addRecentSearch(_ query: String) {
        guard !query.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0 == query }
        
        // Add to front
        recentSearches.insert(query, at: 0)
        
        // Trim to max
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearches()
    }
    
    /// Clear all recent searches
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }
    
    /// Remove a specific recent search
    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearches()
    }
    
    // MARK: - Recently Played Management
    
    /// Add a format to recently played
    func addRecentlyPlayed(_ formatName: String) {
        // Remove if already exists
        recentlyPlayed.removeAll { $0 == formatName }
        
        // Add to front
        recentlyPlayed.insert(formatName, at: 0)
        
        // Trim to max
        if recentlyPlayed.count > maxRecentlyPlayed {
            recentlyPlayed = Array(recentlyPlayed.prefix(maxRecentlyPlayed))
        }
        
        saveRecentlyPlayed()
    }
    
    // MARK: - Persistence
    
    private func loadRecentSearches() {
        if let searches = UserDefaults.standard.array(forKey: recentSearchesKey) as? [String] {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
    
    private func loadRecentlyPlayed() {
        if let played = UserDefaults.standard.array(forKey: recentlyPlayedKey) as? [String] {
            recentlyPlayed = played
        }
    }
    
    private func saveRecentlyPlayed() {
        UserDefaults.standard.set(recentlyPlayed, forKey: recentlyPlayedKey)
    }
    
    // MARK: - Search Suggestions
    
    /// Get search suggestions based on partial query
    func getSuggestions(for query: String, limit: Int = 5) -> [String] {
        guard !query.isEmpty else { return recentSearches }
        
        let lowercaseQuery = query.lowercased()
        var suggestions: Set<String> = []
        
        // Add matching format names
        for format in GolfFormat.allFormats {
            if format.name.lowercased().hasPrefix(lowercaseQuery) {
                suggestions.insert(format.name)
            }
        }
        
        // Add matching alternate names
        for (formatName, alternates) in alternateNames {
            for alternate in alternates {
                if alternate.lowercased().hasPrefix(lowercaseQuery) {
                    suggestions.insert(formatName)
                }
            }
        }
        
        // Add matching recent searches
        for recent in recentSearches {
            if recent.lowercased().hasPrefix(lowercaseQuery) {
                suggestions.insert(recent)
            }
        }
        
        return Array(suggestions.prefix(limit))
    }
}