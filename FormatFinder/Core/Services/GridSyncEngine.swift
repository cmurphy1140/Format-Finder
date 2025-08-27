import Foundation
import SwiftUI
import Combine

// MARK: - Grid Sync Engine
// Real-time synchronization engine for multi-player score grid editing

@MainActor
final class GridSyncEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var gridState = ScoreGrid()
    @Published private(set) var activeLocks: [CellID: LockInfo] = [:]
    @Published private(set) var pendingUpdates: [CellUpdate] = []
    @Published private(set) var conflictCells: Set<CellID> = []
    @Published private(set) var optimisticUpdates: [CellID: OptimisticUpdate] = [:]
    
    // MARK: - Private Properties
    
    private var updateQueue = DispatchQueue(label: "com.formatfinder.gridsync", qos: .userInteractive)
    private var lockTimers: [CellID: Timer] = [:]
    private var conflictResolutionTimers: [CellID: Timer] = [:]
    private var deltaBuffer: [DeltaUpdate] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let lockDuration: TimeInterval = 0.5 // 500ms
    private let conflictDisplayDuration: TimeInterval = 1.5
    private let batchInterval: TimeInterval = 0.05 // 50ms for faster sync
    
    // Device and user tracking
    private let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private var scorekeeperID: UUID?
    
    // MARK: - Singleton
    
    static let shared = GridSyncEngine()
    
    private init() {
        setupBatchProcessing()
    }
    
    // MARK: - Public Methods
    
    /// Request to edit a cell, returns token if lock acquired
    func requestCellEdit(_ cellID: CellID, editor: Player) -> EditToken? {
        // Check for existing lock
        if let existingLock = activeLocks[cellID] {
            if Date().timeIntervalSince(existingLock.timestamp) < lockDuration {
                // Cell is locked by another user
                if existingLock.editor.id != editor.id {
                    // Show conflict indicator
                    showLockConflict(cellID, requestor: editor, holder: existingLock.editor)
                    return nil
                }
                // Same user, extend lock
                return extendLock(cellID, editor: editor)
            }
        }
        
        // Create new lock
        let token = EditToken(
            id: UUID(),
            cellID: cellID,
            editor: editor,
            deviceID: deviceID,
            timestamp: Date()
        )
        
        let lockInfo = LockInfo(
            editor: editor,
            timestamp: Date(),
            deviceID: deviceID,
            color: getEditorColor(for: editor)
        )
        
        activeLocks[cellID] = lockInfo
        
        // Auto-release lock after duration
        scheduleLockRelease(cellID)
        
        // Broadcast lock to other devices
        broadcastLockStatus(cellID, lockInfo: lockInfo, acquired: true)
        
        return token
    }
    
    /// Submit a cell update with optimistic application
    func submitUpdate(_ update: CellUpdate) {
        // Apply optimistically
        applyOptimisticUpdate(update)
        
        // Queue for processing
        updateQueue.async { [weak self] in
            self?.pendingUpdates.append(update)
        }
        
        // Process in next batch
        scheduleImmediateBatch()
    }
    
    /// Process batch of updates with conflict resolution
    func processBatchUpdate(_ updates: [CellUpdate]) -> GridSyncResult {
        let conflicts = detectConflicts(updates)
        let resolved = resolveConflicts(conflicts, originalUpdates: updates)
        let finalUpdates = applyResolutions(resolved, updates: updates)
        
        // Generate and broadcast deltas
        let deltas = generateDeltas(finalUpdates)
        broadcastDeltas(deltas)
        
        // Update grid state
        for update in finalUpdates {
            gridState.setValue(update.value, for: update.cellID)
            
            // Clear optimistic update if it matches
            if let optimistic = optimisticUpdates[update.cellID],
               optimistic.update.timestamp == update.timestamp {
                optimisticUpdates.removeValue(forKey: update.cellID)
            }
        }
        
        return GridSyncResult(
            applied: finalUpdates,
            conflicts: conflicts,
            rollbacks: getRollbacks(conflicts, updates: updates)
        )
    }
    
    /// Set designated scorekeeper for conflict resolution priority
    func setScorekeeper(_ player: Player) {
        scorekeeperID = player.id
    }
    
    /// Get current value for a cell (including optimistic updates)
    func getValue(for cellID: CellID) -> Int? {
        // Check optimistic updates first
        if let optimistic = optimisticUpdates[cellID] {
            return optimistic.update.value
        }
        // Fall back to confirmed state
        return gridState.getValue(for: cellID)
    }
    
    /// Check if a cell is currently locked
    func isLocked(_ cellID: CellID, by editor: Player? = nil) -> Bool {
        guard let lock = activeLocks[cellID] else { return false }
        
        if Date().timeIntervalSince(lock.timestamp) >= lockDuration {
            // Lock expired
            activeLocks.removeValue(forKey: cellID)
            return false
        }
        
        if let editor = editor {
            return lock.editor.id != editor.id
        }
        
        return true
    }
    
    /// Get lock info for visual display
    func getLockInfo(for cellID: CellID) -> LockInfo? {
        guard let lock = activeLocks[cellID] else { return nil }
        
        if Date().timeIntervalSince(lock.timestamp) >= lockDuration {
            activeLocks.removeValue(forKey: cellID)
            return nil
        }
        
        return lock
    }
    
    // MARK: - Private Methods
    
    private func applyOptimisticUpdate(_ update: CellUpdate) {
        let optimistic = OptimisticUpdate(
            update: update,
            previousValue: gridState.getValue(for: update.cellID),
            appliedAt: Date()
        )
        
        optimisticUpdates[update.cellID] = optimistic
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    private func detectConflicts(_ updates: [CellUpdate]) -> [UpdateConflict] {
        var conflicts: [UpdateConflict] = []
        var cellGroups: [CellID: [CellUpdate]] = [:]
        
        // Group updates by cell
        for update in updates {
            cellGroups[update.cellID, default: []].append(update)
        }
        
        // Find conflicts (multiple updates to same cell within 500ms)
        for (cellID, cellUpdates) in cellGroups where cellUpdates.count > 1 {
            let sortedUpdates = cellUpdates.sorted { $0.timestamp < $1.timestamp }
            
            for i in 0..<sortedUpdates.count - 1 {
                let timeDiff = sortedUpdates[i + 1].timestamp.timeIntervalSince(sortedUpdates[i].timestamp)
                
                if timeDiff <= 0.5 {
                    // Conflict detected
                    let conflict = UpdateConflict(
                        cellID: cellID,
                        updates: [sortedUpdates[i], sortedUpdates[i + 1]],
                        type: determineConflictType(sortedUpdates[i], sortedUpdates[i + 1])
                    )
                    conflicts.append(conflict)
                    
                    // Mark cell as conflicted for visual feedback
                    conflictCells.insert(cellID)
                    scheduleConflictClear(cellID)
                }
            }
        }
        
        return conflicts
    }
    
    private func determineConflictType(_ update1: CellUpdate, _ update2: CellUpdate) -> ConflictType {
        if update1.editor.id == update2.editor.id {
            return .samePlayer
        } else if update1.deviceID == update2.deviceID {
            return .sameDevice
        } else {
            return .differentUsers
        }
    }
    
    private func resolveConflicts(_ conflicts: [UpdateConflict], originalUpdates: [CellUpdate]) -> [ConflictResolution] {
        var resolutions: [ConflictResolution] = []
        
        for conflict in conflicts {
            let resolution = resolveConflict(conflict)
            resolutions.append(resolution)
            
            // Show conflict visually
            showConflictResolution(conflict, resolution: resolution)
        }
        
        return resolutions
    }
    
    private func resolveConflict(_ conflict: UpdateConflict) -> ConflictResolution {
        let updates = conflict.updates
        
        // Resolution priority:
        // 1. Player's own score takes precedence
        // 2. Designated scorekeeper
        // 3. Most recent timestamp
        
        // Check if any update is from the player themselves
        if let cellID = CellID(rawValue: conflict.cellID.rawValue),
           let playerID = extractPlayerID(from: cellID) {
            if let ownUpdate = updates.first(where: { $0.editor.id == playerID }) {
                return ConflictResolution(
                    conflict: conflict,
                    winner: ownUpdate,
                    reason: .ownScore
                )
            }
        }
        
        // Check for scorekeeper
        if let scorekeeperID = scorekeeperID,
           let scorekeeperUpdate = updates.first(where: { $0.editor.id == scorekeeperID }) {
            return ConflictResolution(
                conflict: conflict,
                winner: scorekeeperUpdate,
                reason: .scorekeeper
            )
        }
        
        // Default to most recent
        let mostRecent = updates.max { $0.timestamp < $1.timestamp }!
        return ConflictResolution(
            conflict: conflict,
            winner: mostRecent,
            reason: .mostRecent
        )
    }
    
    private func applyResolutions(_ resolutions: [ConflictResolution], updates: [CellUpdate]) -> [CellUpdate] {
        var finalUpdates = updates
        let conflictedCells = Set(resolutions.map { $0.conflict.cellID })
        
        // Remove conflicted updates and replace with winners
        finalUpdates = finalUpdates.filter { !conflictedCells.contains($0.cellID) }
        finalUpdates.append(contentsOf: resolutions.map { $0.winner })
        
        return finalUpdates
    }
    
    private func generateDeltas(_ updates: [CellUpdate]) -> [DeltaUpdate] {
        return updates.map { update in
            DeltaUpdate(
                cellID: update.cellID,
                oldValue: gridState.getValue(for: update.cellID),
                newValue: update.value,
                editor: update.editor,
                timestamp: update.timestamp,
                deviceID: update.deviceID
            )
        }
    }
    
    private func broadcastDeltas(_ deltas: [DeltaUpdate]) {
        // In production, this would send to network
        // For now, post notification for other components
        NotificationCenter.default.post(
            name: .gridDeltasAvailable,
            object: nil,
            userInfo: ["deltas": deltas]
        )
    }
    
    private func broadcastLockStatus(_ cellID: CellID, lockInfo: LockInfo, acquired: Bool) {
        NotificationCenter.default.post(
            name: .cellLockStatusChanged,
            object: nil,
            userInfo: [
                "cellID": cellID,
                "lockInfo": lockInfo,
                "acquired": acquired
            ]
        )
    }
    
    private func showLockConflict(_ cellID: CellID, requestor: Player, holder: Player) {
        // Visual feedback for lock conflict
        NotificationCenter.default.post(
            name: .lockConflictDetected,
            object: nil,
            userInfo: [
                "cellID": cellID,
                "requestor": requestor,
                "holder": holder
            ]
        )
    }
    
    private func showConflictResolution(_ conflict: UpdateConflict, resolution: ConflictResolution) {
        // Show both values briefly before resolving
        NotificationCenter.default.post(
            name: .conflictResolutionShown,
            object: nil,
            userInfo: [
                "conflict": conflict,
                "resolution": resolution
            ]
        )
    }
    
    private func getRollbacks(_ conflicts: [UpdateConflict], updates: [CellUpdate]) -> [CellUpdate] {
        var rollbacks: [CellUpdate] = []
        
        for conflict in conflicts {
            // Find updates that need to be rolled back
            let losers = conflict.updates.filter { update in
                !conflicts.contains { $0.updates.contains { $0 === update } }
            }
            rollbacks.append(contentsOf: losers)
        }
        
        return rollbacks
    }
    
    private func extendLock(_ cellID: CellID, editor: Player) -> EditToken {
        let token = EditToken(
            id: UUID(),
            cellID: cellID,
            editor: editor,
            deviceID: deviceID,
            timestamp: Date()
        )
        
        // Update lock timestamp
        if var lock = activeLocks[cellID] {
            lock.timestamp = Date()
            activeLocks[cellID] = lock
        }
        
        // Reschedule release
        scheduleLockRelease(cellID)
        
        return token
    }
    
    private func scheduleLockRelease(_ cellID: CellID) {
        // Cancel existing timer
        lockTimers[cellID]?.invalidate()
        
        // Schedule new release
        lockTimers[cellID] = Timer.scheduledTimer(withTimeInterval: lockDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.activeLocks.removeValue(forKey: cellID)
                self?.lockTimers.removeValue(forKey: cellID)
                self?.broadcastLockStatus(cellID, lockInfo: LockInfo(editor: Player(id: UUID(), name: "", handicap: 0), timestamp: Date(), deviceID: "", color: .clear), acquired: false)
            }
        }
    }
    
    private func scheduleConflictClear(_ cellID: CellID) {
        conflictResolutionTimers[cellID]?.invalidate()
        
        conflictResolutionTimers[cellID] = Timer.scheduledTimer(withTimeInterval: conflictDisplayDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.conflictCells.remove(cellID)
                self?.conflictResolutionTimers.removeValue(forKey: cellID)
            }
        }
    }
    
    private func scheduleImmediateBatch() {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(batchInterval * 1_000_000_000))
            await processPendingUpdates()
        }
    }
    
    private func setupBatchProcessing() {
        Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.processPendingUpdates()
            }
        }
    }
    
    private func processPendingUpdates() async {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        
        let result = processBatchUpdate(updates)
        
        // Handle rollbacks
        for rollback in result.rollbacks {
            if let optimistic = optimisticUpdates[rollback.cellID] {
                // Rollback to previous value
                gridState.setValue(optimistic.previousValue ?? 0, for: rollback.cellID)
                optimisticUpdates.removeValue(forKey: rollback.cellID)
            }
        }
    }
    
    private func getEditorColor(for player: Player) -> Color {
        // Generate consistent color based on player ID
        let hash = player.id.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
    
    private func extractPlayerID(from cellID: CellID) -> UUID? {
        // Parse player ID from cell ID format: "player_[UUID]_hole_[Int]"
        let components = cellID.rawValue.split(separator: "_")
        guard components.count >= 4,
              components[0] == "player",
              let uuidString = components[1..<(components.count - 2)].joined(separator: "_").uuidString else {
            return nil
        }
        return UUID(uuidString: String(uuidString))
    }
}

// MARK: - Supporting Types

struct CellID: Hashable, RawRepresentable {
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    init(playerId: UUID, hole: Int) {
        self.rawValue = "player_\(playerId.uuidString)_hole_\(hole)"
    }
}

struct EditToken {
    let id: UUID
    let cellID: CellID
    let editor: Player
    let deviceID: String
    let timestamp: Date
}

struct LockInfo {
    var editor: Player
    var timestamp: Date
    let deviceID: String
    let color: Color
}

struct CellUpdate {
    let cellID: CellID
    let value: Int
    let editor: Player
    let timestamp: Date
    let deviceID: String
}

struct OptimisticUpdate {
    let update: CellUpdate
    let previousValue: Int?
    let appliedAt: Date
}

struct UpdateConflict {
    let cellID: CellID
    let updates: [CellUpdate]
    let type: ConflictType
}

enum ConflictType {
    case samePlayer
    case sameDevice
    case differentUsers
}

struct ConflictResolution {
    let conflict: UpdateConflict
    let winner: CellUpdate
    let reason: ResolutionReason
}

enum ResolutionReason {
    case ownScore
    case scorekeeper
    case mostRecent
}

struct DeltaUpdate: Codable {
    let cellID: String
    let oldValue: Int?
    let newValue: Int
    let editor: PlayerDTO
    let timestamp: Date
    let deviceID: String
    
    init(cellID: CellID, oldValue: Int?, newValue: Int, editor: Player, timestamp: Date, deviceID: String) {
        self.cellID = cellID.rawValue
        self.oldValue = oldValue
        self.newValue = newValue
        self.editor = PlayerDTO(id: editor.id, name: editor.name, handicap: editor.handicap)
        self.timestamp = timestamp
        self.deviceID = deviceID
    }
}

struct PlayerDTO: Codable {
    let id: UUID
    let name: String
    let handicap: Int
}

struct GridSyncResult {
    let applied: [CellUpdate]
    let conflicts: [UpdateConflict]
    let rollbacks: [CellUpdate]
}

struct ScoreGrid {
    private var cells: [CellID: Int] = [:]
    
    mutating func setValue(_ value: Int, for cellID: CellID) {
        cells[cellID] = value
    }
    
    func getValue(for cellID: CellID) -> Int? {
        cells[cellID]
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let gridDeltasAvailable = Notification.Name("gridDeltasAvailable")
    static let cellLockStatusChanged = Notification.Name("cellLockStatusChanged")
    static let lockConflictDetected = Notification.Name("lockConflictDetected")
    static let conflictResolutionShown = Notification.Name("conflictResolutionShown")
}

// MARK: - String Extension

extension String {
    var uuidString: String? {
        UUID(uuidString: self) != nil ? self : nil
    }
}