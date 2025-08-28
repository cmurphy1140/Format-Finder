import Foundation
import CoreData
import os.log

// MARK: - Middleware Protocol

protocol Middleware {
    func process(action: GameAction, state: GameAppState, dispatch: @escaping (GameAction) -> Void) async
}

// MARK: - Logging Middleware

final class LoggingMiddleware: Middleware {
    private let logger = Logger(subsystem: "com.formatfinder", category: "GameStore")
    
    func process(action: GameAction, state: GameAppState, dispatch: @escaping (GameAction) -> Void) async {
        let timestamp = Date()
        let actionDescription = String(describing: action)
        
        logger.info("[\(timestamp)] Action: \(actionDescription)")
        
        // Log state changes for debugging
        #if DEBUG
        if let currentHole = state.currentRound?.currentHole {
            logger.debug("Current Hole: \(currentHole)")
        }
        if let scores = state.currentRound?.scores {
            logger.debug("Scores: \(scores.count) holes recorded")
        }
        #endif
    }
}

// MARK: - Persistence Middleware

final class PersistenceMiddleware: Middleware {
    private let repository = RoundRepository()
    
    func process(action: GameAction, state: GameAppState, dispatch: @escaping (GameAction) -> Void) async {
        switch action {
        case .saveRound:
            await saveCurrentRound(state: state)
            
        case .endRound:
            await saveCurrentRound(state: state)
            await calculateAndSaveStatistics(state: state)
            
        case .updateScore, .updateBulkScores:
            // Debounced auto-save
            await autoSave(state: state)
            
        default:
            break
        }
    }
    
    private func saveCurrentRound(state: GameAppState) async {
        guard let round = state.currentRound else { return }
        
        do {
            try await repository.save(round: round, players: state.players)
            print("[Persistence] Round saved successfully")
        } catch {
            print("[Persistence] Failed to save round: \(error)")
        }
    }
    
    private func autoSave(state: GameAppState) async {
        // Implement debounced auto-save
        // This would use a timer to save after a period of inactivity
    }
    
    private func calculateAndSaveStatistics(state: GameAppState) async {
        guard let round = state.currentRound else { return }
        
        let statsCalculator = StatisticsCalculator()
        let stats = await statsCalculator.calculate(for: round)
        
        // Save statistics to Core Data
        do {
            try await repository.saveStatistics(stats, for: round.id)
        } catch {
            print("[Persistence] Failed to save statistics: \(error)")
        }
    }
}

// MARK: - Analytics Middleware

final class AnalyticsMiddleware: Middleware {
    private var eventQueue: [AnalyticsEvent] = []
    private let maxQueueSize = 100
    
    func process(action: GameAction, state: GameAppState, dispatch: @escaping (GameAction) -> Void) async {
        let event = createAnalyticsEvent(for: action, state: state)
        
        if let event = event {
            await queueEvent(event)
            
            // Flush queue if needed
            if eventQueue.count >= maxQueueSize {
                await flushEvents()
            }
        }
    }
    
    private func createAnalyticsEvent(for action: GameAction, state: GameAppState) -> AnalyticsEvent? {
        switch action {
        case .startRound:
            return AnalyticsEvent(
                name: "round_started",
                parameters: [
                    "format": state.currentRound?.format.rawValue ?? "",
                    "players": state.players.count,
                    "holes": state.gameConfiguration?.numberOfHoles ?? 18
                ]
            )
            
        case .endRound:
            return AnalyticsEvent(
                name: "round_completed",
                parameters: [
                    "format": state.currentRound?.format.rawValue ?? "",
                    "duration": Date().timeIntervalSince(state.currentRound?.startTime ?? Date()),
                    "holes_played": state.currentRound?.scores.count ?? 0
                ]
            )
            
        case let .updateScore(hole, _, score):
            return AnalyticsEvent(
                name: "score_entered",
                parameters: [
                    "hole": hole,
                    "score": score
                ]
            )
            
        default:
            return nil
        }
    }
    
    private func queueEvent(_ event: AnalyticsEvent) async {
        eventQueue.append(event)
    }
    
    private func flushEvents() async {
        // In a real implementation, this would send events to an analytics service
        // For now, we'll just save them locally
        let events = eventQueue
        eventQueue.removeAll()
        
        // Save to UserDefaults or local database
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: "analytics_events")
        }
    }
}

// MARK: - Sync Middleware

final class SyncMiddleware: Middleware {
    private let syncService = CloudKitSyncService()
    
    func process(action: GameAction, state: GameAppState, dispatch: @escaping (GameAction) -> Void) async {
        switch action {
        case .startSync:
            await performSync(state: state, dispatch: dispatch)
            
        case .saveRound, .endRound:
            // Queue for sync
            dispatch(.updatePendingChanges(state.sync.pendingChanges + 1))
            
        case .updateScore, .updateBulkScores:
            // Increment pending changes
            dispatch(.updatePendingChanges(state.sync.pendingChanges + 1))
            
        default:
            break
        }
    }
    
    private func performSync(state: GameAppState, dispatch: @escaping (GameAction) -> Void) async {
        do {
            // Sync with CloudKit
            try await syncService.sync(state: state)
            dispatch(.syncCompleted(Date()))
        } catch {
            dispatch(.syncFailed(error.localizedDescription))
        }
    }
}

// MARK: - Supporting Types

struct AnalyticsEvent: Codable {
    let name: String
    let parameters: [String: Any]
    let timestamp: Date
    
    init(name: String, parameters: [String: Any]) {
        self.name = name
        self.parameters = parameters
        self.timestamp = Date()
    }
    
    // Custom encoding/decoding for Any type
    enum CodingKeys: String, CodingKey {
        case name, parameters, timestamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timestamp, forKey: .timestamp)
        
        // Convert parameters to Data
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters) {
            let jsonString = String(data: jsonData, encoding: .utf8)
            try container.encode(jsonString, forKey: .parameters)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        if let jsonString = try? container.decode(String.self, forKey: .parameters),
           let jsonData = jsonString.data(using: .utf8),
           let params = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            parameters = params
        } else {
            parameters = [:]
        }
    }
}

// MARK: - Statistics Calculator

final class StatisticsCalculator {
    func calculate(for round: RoundState) async -> RoundStatistics {
        var totalStrokes = 0
        var birdies = 0
        var pars = 0
        var bogeys = 0
        var bestHole: Int?
        var worstHole: Int?
        var bestScore = Int.max
        var worstScore = 0
        
        for (hole, scores) in round.scores {
            if let holeTotal = scores.values.reduce(0, +) as Int? {
                totalStrokes += holeTotal
                
                let averageScore = holeTotal / scores.count
                let par = getParForHole(hole)
                
                if averageScore < par {
                    birdies += 1
                } else if averageScore == par {
                    pars += 1
                } else {
                    bogeys += 1
                }
                
                if averageScore < bestScore {
                    bestScore = averageScore
                    bestHole = hole
                }
                
                if averageScore > worstScore {
                    worstScore = averageScore
                    worstHole = hole
                }
            }
        }
        
        let holesPlayed = round.scores.count
        let averageScore = holesPlayed > 0 ? Double(totalStrokes) / Double(holesPlayed) : 0
        
        return RoundStatistics(
            totalStrokes: totalStrokes,
            birdies: birdies,
            pars: pars,
            bogeys: bogeys,
            averageScore: averageScore,
            bestHole: bestHole,
            worstHole: worstHole
        )
    }
    
    private func getParForHole(_ hole: Int) -> Int {
        // Mock par - would come from course data
        let pars = GolfConstants.ParManagement.service.getAllPars()
        return pars[(hole - 1) % 18]
    }
}