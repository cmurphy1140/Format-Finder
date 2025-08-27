import Foundation
import CoreData

// MARK: - Round Repository

final class RoundRepository {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - CRUD Operations
    
    func create(round: RoundState, players: [PlayerIdentifier]) async throws -> NSManagedObjectID {
        try await coreDataStack.performBackgroundTask { context in
            let roundEntity = NSEntityDescription.entity(forEntityName: "Round", in: context)!
            let newRound = NSManagedObject(entity: roundEntity, insertInto: context)
            
            newRound.setValue(round.id, forKey: "id")
            newRound.setValue(round.startTime, forKey: "date")
            newRound.setValue(round.format.rawValue, forKey: "formatName")
            newRound.setValue(round.currentHole, forKey: "numberOfHoles")
            newRound.setValue(round.isCompleted, forKey: "isCompleted")
            newRound.setValue(Date(), forKey: "createdAt")
            newRound.setValue(Date(), forKey: "updatedAt")
            
            // Add players
            for player in players {
                let playerRound = self.createPlayerRound(player: player, in: context)
                newRound.mutableSetValue(forKey: "players").add(playerRound)
            }
            
            // Add scores
            for (hole, playerScores) in round.scores {
                for (player, score) in playerScores {
                    let scoreEntity = self.createScore(
                        hole: hole,
                        player: player,
                        strokes: score,
                        in: context
                    )
                    newRound.mutableSetValue(forKey: "scores").add(scoreEntity)
                }
            }
            
            try context.save()
            return newRound.objectID
        }
    }
    
    func fetch(id: UUID) async throws -> RoundState? {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        guard let round = try context.fetch(request).first else {
            return nil
        }
        
        return mapToRoundState(round)
    }
    
    func fetchAll() async throws -> [RoundState] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let rounds = try context.fetch(request)
        return rounds.compactMap { mapToRoundState($0) }
    }
    
    func fetchRecent(limit: Int = 10) async throws -> [RoundState] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = limit
        
        let rounds = try context.fetch(request)
        return rounds.compactMap { mapToRoundState($0) }
    }
    
    func update(round: RoundState) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
            request.predicate = NSPredicate(format: "id == %@", round.id as CVarArg)
            request.fetchLimit = 1
            
            guard let existingRound = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            existingRound.setValue(round.currentHole, forKey: "numberOfHoles")
            existingRound.setValue(round.isCompleted, forKey: "isCompleted")
            existingRound.setValue(Date(), forKey: "updatedAt")
            
            // Update scores
            let scoresSet = existingRound.mutableSetValue(forKey: "scores")
            scoresSet.removeAllObjects()
            
            for (hole, playerScores) in round.scores {
                for (player, score) in playerScores {
                    let scoreEntity = self.createScore(
                        hole: hole,
                        player: player,
                        strokes: score,
                        in: context
                    )
                    scoresSet.add(scoreEntity)
                }
            }
            
            try context.save()
        }
    }
    
    func delete(id: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            guard let round = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            context.delete(round)
            try context.save()
        }
    }
    
    // MARK: - Specialized Queries
    
    func fetchByFormat(_ format: FormatType) async throws -> [RoundState] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
        request.predicate = NSPredicate(format: "formatName == %@", format.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let rounds = try context.fetch(request)
        return rounds.compactMap { mapToRoundState($0) }
    }
    
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [RoundState] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as CVarArg,
            endDate as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let rounds = try context.fetch(request)
        return rounds.compactMap { mapToRoundState($0) }
    }
    
    func fetchIncompleteRounds() async throws -> [RoundState] {
        let context = coreDataStack.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
        request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: false))
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let rounds = try context.fetch(request)
        return rounds.compactMap { mapToRoundState($0) }
    }
    
    // MARK: - Statistics
    
    func saveStatistics(_ stats: RoundStatistics, for roundId: UUID) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: "Round")
            request.predicate = NSPredicate(format: "id == %@", roundId as CVarArg)
            request.fetchLimit = 1
            
            guard let round = try context.fetch(request).first else {
                throw RepositoryError.notFound
            }
            
            // Store statistics as binary data
            let encoder = JSONEncoder()
            let statsData = try encoder.encode(stats)
            
            // You might want to create a separate Statistics entity
            // For now, storing in metadata
            round.setValue(statsData, forKey: "metadata")
            
            try context.save()
        }
    }
    
    // MARK: - Helper Methods
    
    func save(round: RoundState, players: [PlayerIdentifier]) async throws {
        if try await fetch(id: round.id) != nil {
            try await update(round: round)
        } else {
            _ = try await create(round: round, players: players)
        }
    }
    
    private func createPlayerRound(player: PlayerIdentifier, in context: NSManagedObjectContext) -> NSManagedObject {
        let playerRoundEntity = NSEntityDescription.entity(forEntityName: "PlayerRound", in: context)!
        let playerRound = NSManagedObject(entity: playerRoundEntity, insertInto: context)
        
        // Find or create player
        let playerEntity = findOrCreatePlayer(player, in: context)
        playerRound.setValue(playerEntity, forKey: "player")
        playerRound.setValue(true, forKey: "isActive")
        
        return playerRound
    }
    
    private func findOrCreatePlayer(_ player: PlayerIdentifier, in context: NSManagedObjectContext) -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Player")
        request.predicate = NSPredicate(format: "id == %@", player.id as CVarArg)
        request.fetchLimit = 1
        
        if let existingPlayer = try? context.fetch(request).first {
            return existingPlayer
        }
        
        let playerEntity = NSEntityDescription.entity(forEntityName: "Player", in: context)!
        let newPlayer = NSManagedObject(entity: playerEntity, insertInto: context)
        
        newPlayer.setValue(player.id, forKey: "id")
        newPlayer.setValue(player.name, forKey: "name")
        newPlayer.setValue(player.handicap, forKey: "handicap")
        newPlayer.setValue(Date(), forKey: "createdAt")
        newPlayer.setValue(Date(), forKey: "updatedAt")
        
        return newPlayer
    }
    
    private func createScore(hole: Int, player: PlayerIdentifier, strokes: Int, in context: NSManagedObjectContext) -> NSManagedObject {
        let scoreEntity = NSEntityDescription.entity(forEntityName: "Score", in: context)!
        let score = NSManagedObject(entity: scoreEntity, insertInto: context)
        
        score.setValue(hole, forKey: "hole")
        score.setValue(strokes, forKey: "strokes")
        score.setValue(Date(), forKey: "createdAt")
        
        let playerEntity = findOrCreatePlayer(player, in: context)
        score.setValue(playerEntity, forKey: "player")
        
        return score
    }
    
    private func mapToRoundState(_ managedObject: NSManagedObject) -> RoundState? {
        guard let id = managedObject.value(forKey: "id") as? UUID,
              let formatName = managedObject.value(forKey: "formatName") as? String,
              let format = FormatType(rawValue: formatName),
              let date = managedObject.value(forKey: "date") as? Date else {
            return nil
        }
        
        let currentHole = managedObject.value(forKey: "numberOfHoles") as? Int ?? 1
        let isCompleted = managedObject.value(forKey: "isCompleted") as? Bool ?? false
        
        // Map scores
        var scores: [Int: [PlayerIdentifier: Int]] = [:]
        if let scoreSet = managedObject.value(forKey: "scores") as? NSSet {
            for scoreObject in scoreSet {
                if let score = scoreObject as? NSManagedObject,
                   let hole = score.value(forKey: "hole") as? Int,
                   let strokes = score.value(forKey: "strokes") as? Int,
                   let playerObject = score.value(forKey: "player") as? NSManagedObject,
                   let playerId = playerObject.value(forKey: "id") as? UUID,
                   let playerName = playerObject.value(forKey: "name") as? String,
                   let handicap = playerObject.value(forKey: "handicap") as? Int {
                    
                    let player = PlayerIdentifier(id: playerId, name: playerName, handicap: handicap)
                    
                    if scores[hole] == nil {
                        scores[hole] = [:]
                    }
                    scores[hole]?[player] = strokes
                }
            }
        }
        
        return RoundState(
            id: id,
            format: format,
            startTime: date,
            currentHole: currentHole,
            scores: scores,
            isCompleted: isCompleted,
            metadata: RoundMetadata(
                scrambleSelections: [:],
                matchPlayStatus: nil,
                skinsCarryover: 0,
                wolfSelections: [:],
                nassauMatches: nil
            )
        )
    }
}

// MARK: - Repository Error

enum RepositoryError: LocalizedError {
    case notFound
    case invalidData
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested item was not found"
        case .invalidData:
            return "The data is invalid or corrupted"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}