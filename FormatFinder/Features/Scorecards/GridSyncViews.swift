import SwiftUI

// MARK: - Synchronized Grid Cell View
// Shows cell with lock indicators, conflict animations, and optimistic updates

struct SyncedGridCell: View {
    let cellID: CellID
    let player: Player
    let hole: Int
    @Binding var score: Int
    
    @StateObject private var syncEngine = GridSyncEngine.shared
    @State private var editToken: EditToken?
    @State private var isEditing = false
    @State private var showConflict = false
    @State private var conflictValue: Int?
    @State private var lockPulse = false
    
    private var lockInfo: LockInfo? {
        syncEngine.getLockInfo(for: cellID)
    }
    
    private var isLocked: Bool {
        syncEngine.isLocked(cellID, by: player)
    }
    
    private var hasConflict: Bool {
        syncEngine.conflictCells.contains(cellID)
    }
    
    private var displayValue: Int {
        syncEngine.getValue(for: cellID) ?? score
    }
    
    var body: some View {
        ZStack {
            // Background with lock indicator
            RoundedRectangle(cornerRadius: 10)
                .fill(cellBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(lockBorder, lineWidth: lockBorderWidth)
                )
                .scaleEffect(lockPulse ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatCount(isLocked ? .max : 0), value: lockPulse)
            
            VStack(spacing: 8) {
                // Player name with lock indicator
                HStack {
                    Text(player.name)
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    if let lockInfo = lockInfo {
                        LockIndicator(lockInfo: lockInfo, isOwner: lockInfo.editor.id == player.id)
                    }
                }
                
                // Score display with conflict animation
                ZStack {
                    // Main score
                    Text("\(displayValue)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(scoreColor)
                        .opacity(showConflict ? 0.5 : 1.0)
                    
                    // Conflict value overlay
                    if showConflict, let conflictValue = conflictValue {
                        HStack(spacing: 4) {
                            Text("\(displayValue)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            
                            Text("\(conflictValue)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.red)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Edit controls
                HStack(spacing: 12) {
                    Button(action: { adjustScore(-1) }) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    .disabled(isLocked)
                    .opacity(isLocked ? 0.3 : 1.0)
                    
                    Spacer()
                    
                    Button(action: { adjustScore(1) }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                    .disabled(isLocked)
                    .opacity(isLocked ? 0.3 : 1.0)
                }
            }
            .padding(12)
            
            // Optimistic update indicator
            if syncEngine.optimisticUpdates[cellID] != nil {
                OptimisticIndicator()
                    .position(x: 10, y: 10)
            }
        }
        .onTapGesture {
            requestEdit()
        }
        .onChange(of: isLocked) { locked in
            withAnimation(.spring()) {
                lockPulse = locked
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .conflictResolutionShown)) { notification in
            handleConflictNotification(notification)
        }
    }
    
    // MARK: - Computed Properties
    
    private var cellBackground: Color {
        if hasConflict {
            return Color.orange.opacity(0.1)
        } else if isLocked {
            return Color.red.opacity(0.05)
        } else if isEditing {
            return Color.blue.opacity(0.05)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    private var lockBorder: Color {
        if let lockInfo = lockInfo {
            return lockInfo.color.opacity(0.6)
        } else if hasConflict {
            return Color.orange
        } else {
            return Color.clear
        }
    }
    
    private var lockBorderWidth: CGFloat {
        if lockInfo != nil {
            return 2.0
        } else if hasConflict {
            return 1.5
        } else {
            return 0
        }
    }
    
    private var scoreColor: Color {
        let par = GolfConstants.ParManagement.parForHole(hole)
        let diff = displayValue - par
        
        switch diff {
        case ..<(-1): return .purple
        case -1: return .blue
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }
    
    // MARK: - Methods
    
    private func requestEdit() {
        guard !isLocked else {
            showLockFeedback()
            return
        }
        
        editToken = syncEngine.requestCellEdit(cellID, editor: player)
        
        if editToken != nil {
            withAnimation(.spring()) {
                isEditing = true
            }
            
            // Auto-release after interaction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.releaseEdit()
            }
        }
    }
    
    private func releaseEdit() {
        withAnimation(.spring()) {
            isEditing = false
        }
        editToken = nil
    }
    
    private func adjustScore(_ delta: Int) {
        guard !isLocked else { return }
        
        // Request edit token first
        if editToken == nil {
            editToken = syncEngine.requestCellEdit(cellID, editor: player)
            guard editToken != nil else { return }
        }
        
        let newScore = max(1, displayValue + delta)
        
        // Create update
        let update = CellUpdate(
            cellID: cellID,
            value: newScore,
            editor: player,
            timestamp: Date(),
            deviceID: UIDevice.current.identifierForVendor?.uuidString ?? ""
        )
        
        // Submit with optimistic update
        syncEngine.submitUpdate(update)
        
        // Update local binding
        score = newScore
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func showLockFeedback() {
        // Haptic feedback for lock
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
        
        // Visual pulse
        withAnimation(.spring()) {
            lockPulse = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.lockPulse = false
        }
    }
    
    private func handleConflictNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let conflict = userInfo["conflict"] as? UpdateConflict,
              conflict.cellID == cellID else { return }
        
        // Show conflict animation
        if conflict.updates.count > 1 {
            conflictValue = conflict.updates.last?.value
            
            withAnimation(.spring()) {
                showConflict = true
            }
            
            // Auto-resolve after display duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring()) {
                    self.showConflict = false
                    self.conflictValue = nil
                }
            }
        }
    }
}

// MARK: - Lock Indicator View

struct LockIndicator: View {
    let lockInfo: LockInfo
    let isOwner: Bool
    
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(lockInfo.color)
                .frame(width: 8, height: 8)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: pulse)
            
            if isOwner {
                Text("Editing")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(lockInfo.color)
            } else {
                Text(lockInfo.editor.name)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(lockInfo.color.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(lockInfo.color.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - Optimistic Update Indicator

struct OptimisticIndicator: View {
    @State private var rotation = 0.0
    
    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 12))
            .foregroundColor(.blue)
            .rotationEffect(.degrees(rotation))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotation)
            .onAppear {
                rotation = 360
            }
    }
}

// MARK: - Conflict Resolution View

struct ConflictResolutionView: View {
    let conflict: UpdateConflict
    let resolution: ConflictResolution
    
    @State private var showResolution = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Conflict Detected")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.orange)
            
            HStack(spacing: 12) {
                ForEach(conflict.updates, id: \.timestamp) { update in
                    VStack(spacing: 4) {
                        Text(update.editor.name)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Text("\(update.value)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(update == resolution.winner ? .green : .red)
                            .opacity(showResolution && update != resolution.winner ? 0.3 : 1.0)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(
                                        update == resolution.winner ? Color.green : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                    )
                }
            }
            
            if showResolution {
                Text(resolutionReasonText)
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring().delay(0.5)) {
                showResolution = true
            }
        }
    }
    
    private var resolutionReasonText: String {
        switch resolution.reason {
        case .ownScore:
            return "Player's own score takes precedence"
        case .scorekeeper:
            return "Scorekeeper's entry accepted"
        case .mostRecent:
            return "Most recent update accepted"
        }
    }
}

// MARK: - Synchronized Multi-Player Grid

struct SynchronizedScoreGrid: View {
    let players: [Player]
    let hole: Int
    @State private var scores: [UUID: Int] = [:]
    @StateObject private var syncEngine = GridSyncEngine.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Hole \(hole)")
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                    
                    SyncStatusIndicator()
                }
                .padding(.horizontal)
                
                // Player grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(players) { player in
                        SyncedGridCell(
                            cellID: CellID(playerId: player.id, hole: hole),
                            player: player,
                            hole: hole,
                            score: binding(for: player)
                        )
                        .frame(height: 120)
                    }
                }
                .padding()
            }
        }
    }
    
    private func binding(for player: Player) -> Binding<Int> {
        Binding(
            get: { scores[player.id] ?? 0 },
            set: { scores[player.id] = $0 }
        )
    }
}

// MARK: - Sync Status Indicator

struct SyncStatusIndicator: View {
    @StateObject private var syncEngine = GridSyncEngine.shared
    @State private var syncPulse = false
    
    var hasPendingUpdates: Bool {
        !syncEngine.pendingUpdates.isEmpty
    }
    
    var hasConflicts: Bool {
        !syncEngine.conflictCells.isEmpty
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 14))
                .foregroundColor(statusColor)
                .scaleEffect(syncPulse ? 1.2 : 1.0)
            
            Text(statusText)
                .font(.system(size: 12))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: syncPulse)
        .onAppear {
            if hasPendingUpdates {
                syncPulse = true
            }
        }
        .onChange(of: hasPendingUpdates) { pending in
            syncPulse = pending
        }
    }
    
    private var statusIcon: String {
        if hasConflicts {
            return "exclamationmark.triangle"
        } else if hasPendingUpdates {
            return "arrow.triangle.2.circlepath"
        } else {
            return "checkmark.circle"
        }
    }
    
    private var statusColor: Color {
        if hasConflicts {
            return .orange
        } else if hasPendingUpdates {
            return .blue
        } else {
            return .green
        }
    }
    
    private var statusText: String {
        if hasConflicts {
            return "Resolving"
        } else if hasPendingUpdates {
            return "Syncing"
        } else {
            return "Synced"
        }
    }
}