import Foundation
import CloudKit
import CoreData

// MARK: - CloudKit Sync Service

final class CloudKitSyncService {
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let syncQueue: OperationQueue
    private let coreDataStack: CoreDataStack
    
    // Offline queue for pending operations
    private var pendingOperations: [CKOperation] = []
    private let pendingOperationsKey = "pending_cloudkit_operations"
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase
        self.syncQueue = OperationQueue()
        self.syncQueue.maxConcurrentOperationCount = 1
        self.syncQueue.name = "CloudKitSyncQueue"
        self.coreDataStack = coreDataStack
        
        loadPendingOperations()
        setupReachability()
    }
    
    // MARK: - Main Sync Method
    
    func sync(state: GameAppState) async throws {
        // Check CloudKit availability
        let accountStatus = try await container.accountStatus()
        guard accountStatus == .available else {
            throw SyncError.iCloudNotAvailable
        }
        
        // Perform sync operations
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.uploadLocalChanges(state: state)
            }
            
            group.addTask {
                try await self.downloadRemoteChanges()
            }
            
            try await group.waitForAll()
        }
        
        // Process pending operations if online
        if isOnline() {
            await processPendingOperations()
        }
    }
    
    // MARK: - Upload Local Changes
    
    private func uploadLocalChanges(state: GameAppState) async throws {
        guard let round = state.currentRound else { return }
        
        let record = CKRecord(recordType: "Round")
        record["id"] = round.id.uuidString
        record["format"] = round.format.rawValue
        record["startTime"] = round.startTime
        record["currentHole"] = round.currentHole
        record["isCompleted"] = round.isCompleted
        
        // Serialize scores
        if let scoresData = try? JSONEncoder().encode(round.scores) {
            record["scores"] = scoresData
        }
        
        // Serialize metadata
        if let metadataData = try? JSONEncoder().encode(round.metadata) {
            record["metadata"] = metadataData
        }
        
        // Add players
        let playerRecords = state.players.map { player -> CKRecord in
            let playerRecord = CKRecord(recordType: "Player")
            playerRecord["id"] = player.id.uuidString
            playerRecord["name"] = player.name
            playerRecord["handicap"] = player.handicap
            return playerRecord
        }
        
        // Create references
        let playerReferences = playerRecords.map { CKRecord.Reference(record: $0, action: .none) }
        record["players"] = playerReferences
        
        // Save to CloudKit
        do {
            let modifyOperation = CKModifyRecordsOperation(
                recordsToSave: [record] + playerRecords,
                recordIDsToDelete: nil
            )
            
            modifyOperation.savePolicy = .changedKeys
            modifyOperation.qualityOfService = .userInitiated
            
            if !isOnline() {
                queueOfflineOperation(modifyOperation)
                return
            }
            
            try await withCheckedThrowingContinuation { continuation in
                modifyOperation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                privateDatabase.add(modifyOperation)
            }
        } catch {
            throw SyncError.uploadFailed(error)
        }
    }
    
    // MARK: - Download Remote Changes
    
    private func downloadRemoteChanges() async throws {
        let query = CKQuery(recordType: "Round", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            let records = try await privateDatabase.records(matching: query)
            
            for record in records.matchResults {
                if case .success(let recordResult) = record.1 {
                    try await processRemoteRecord(recordResult)
                }
            }
        } catch {
            throw SyncError.downloadFailed(error)
        }
    }
    
    private func processRemoteRecord(_ record: CKRecord) async throws {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let formatString = record["format"] as? String,
              let format = FormatType(rawValue: formatString) else {
            return
        }
        
        // Check if record exists locally
        let repository = RoundRepository()
        let existingRound = try await repository.fetch(id: id)
        
        // Conflict resolution: Last write wins
        let remoteModificationDate = record.modificationDate ?? Date.distantPast
        let localModificationDate = existingRound?.startTime ?? Date.distantPast
        
        if remoteModificationDate > localModificationDate {
            // Update local with remote data
            var scores: [Int: [PlayerIdentifier: Int]] = [:]
            if let scoresData = record["scores"] as? Data,
               let decodedScores = try? JSONDecoder().decode([Int: [PlayerIdentifier: Int]].self, from: scoresData) {
                scores = decodedScores
            }
            
            var metadata = RoundMetadata(
                scrambleSelections: [:],
                matchPlayStatus: nil,
                skinsCarryover: 0,
                wolfSelections: [:],
                nassauMatches: nil
            )
            
            if let metadataData = record["metadata"] as? Data,
               let decodedMetadata = try? JSONDecoder().decode(RoundMetadata.self, from: metadataData) {
                metadata = decodedMetadata
            }
            
            let roundState = RoundState(
                id: id,
                format: format,
                startTime: record["startTime"] as? Date ?? Date(),
                currentHole: record["currentHole"] as? Int ?? 1,
                scores: scores,
                isCompleted: record["isCompleted"] as? Bool ?? false,
                metadata: metadata
            )
            
            try await repository.update(round: roundState)
        }
    }
    
    // MARK: - Offline Support
    
    private func queueOfflineOperation(_ operation: CKOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    private func processPendingOperations() async {
        let operations = pendingOperations
        pendingOperations.removeAll()
        
        // Execute operations - using completion handler approach
        for operation in operations {
            if let dbOperation = operation as? CKDatabaseOperation {
                privateDatabase.add(dbOperation)
            }
        }
        
        savePendingOperations()
    }
    
    private func savePendingOperations() {
        // Serialize and save to UserDefaults
        // In production, use a more robust storage mechanism
    }
    
    private func loadPendingOperations() {
        // Load serialized operations from storage
    }
    
    // MARK: - Reachability
    
    private func setupReachability() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reachabilityChanged),
            name: .CKAccountChanged,
            object: nil
        )
    }
    
    @objc private func reachabilityChanged() {
        if isOnline() {
            Task {
                await processPendingOperations()
            }
        }
    }
    
    private func isOnline() -> Bool {
        // Check network reachability
        // This is a simplified version - use a proper reachability library
        return true
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict(local: RoundState, remote: RoundState) -> RoundState {
        // Implement conflict resolution strategy
        // Options: Last write wins, merge, or user choice
        
        // For now, using last write wins
        if remote.startTime > local.startTime {
            return remote
        } else {
            return local
        }
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case iCloudNotAvailable
    case uploadFailed(Error)
    case downloadFailed(Error)
    case conflictResolutionFailed
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please check your settings."
        case .uploadFailed(let error):
            return "Failed to upload data: \(error.localizedDescription)"
        case .downloadFailed(let error):
            return "Failed to download data: \(error.localizedDescription)"
        case .conflictResolutionFailed:
            return "Failed to resolve sync conflict"
        case .networkUnavailable:
            return "Network is unavailable. Changes will sync when online."
        }
    }
}

// MARK: - Extensions for Codable Support

extension RoundMetadata: Codable {
    enum CodingKeys: String, CodingKey {
        case scrambleSelections
        case matchPlayStatus
        case skinsCarryover
        case wolfSelections
        case nassauMatches
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scrambleSelections = try container.decode([Int: PlayerIdentifier].self, forKey: .scrambleSelections)
        matchPlayStatus = try container.decodeIfPresent(MatchPlayStatus.self, forKey: .matchPlayStatus)
        skinsCarryover = try container.decode(Double.self, forKey: .skinsCarryover)
        wolfSelections = try container.decode([Int: WolfSelection].self, forKey: .wolfSelections)
        nassauMatches = try container.decodeIfPresent(NassauMatches.self, forKey: .nassauMatches)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scrambleSelections, forKey: .scrambleSelections)
        try container.encodeIfPresent(matchPlayStatus, forKey: .matchPlayStatus)
        try container.encode(skinsCarryover, forKey: .skinsCarryover)
        try container.encode(wolfSelections, forKey: .wolfSelections)
        try container.encodeIfPresent(nassauMatches, forKey: .nassauMatches)
    }
}

extension WolfSelection: Codable {
    enum CodingKeys: String, CodingKey {
        case wolf, partner, isLoneWolf, isBlindWolf
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        wolf = try container.decode(UUID.self, forKey: .wolf)
        partner = try container.decodeIfPresent(UUID.self, forKey: .partner)
        isLoneWolf = try container.decode(Bool.self, forKey: .isLoneWolf)
        isBlindWolf = try container.decode(Bool.self, forKey: .isBlindWolf)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wolf, forKey: .wolf)
        try container.encodeIfPresent(partner, forKey: .partner)
        try container.encode(isLoneWolf, forKey: .isLoneWolf)
        try container.encode(isBlindWolf, forKey: .isBlindWolf)
    }
}