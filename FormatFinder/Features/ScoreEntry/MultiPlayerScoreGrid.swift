import SwiftUI

// MARK: - Multi-Player Score Grid

struct MultiPlayerScoreGrid: View {
    let players: [Player]
    let holes: Range<Int>
    @ObservedObject var gameState: GameState
    let configuration: GameConfiguration
    
    // Grid state
    @State private var selectedCell: GridCell? = nil
    @State private var editingCell: GridCell? = nil
    @State private var multiSelectMode = false
    @State private var selectedCells: Set<GridCell> = []
    @State private var zoomLevel: CGFloat = 1.0
    @State private var lastEditedCell: GridCell? = nil
    
    // Navigation pattern learning
    @State private var navigationPattern: NavigationPattern = .automatic
    @AppStorage("scoreGridNavPattern") private var savedNavPattern = "automatic"
    
    // Score prediction
    private let predictionService = MockScorePredictionService()
    
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 2.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ScoreGridToolbar(
                multiSelectMode: $multiSelectMode,
                selectedCount: selectedCells.count,
                zoomLevel: $zoomLevel,
                navigationPattern: $navigationPattern,
                onBatchEntry: handleBatchEntry,
                onClearSelection: clearSelection
            )
            
            // Main Grid
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 0) {
                        // Header Row (Player Names)
                        HStack(spacing: 0) {
                            // Hole number column header
                            Text("Hole")
                                .font(.system(size: 14 * zoomLevel, weight: .semibold))
                                .frame(width: 60 * zoomLevel, height: 40 * zoomLevel)
                                .background(Color.gray.opacity(0.2))
                                .border(Color.gray.opacity(0.3), width: 0.5)
                            
                            // Player names
                            ForEach(players) { player in
                                PlayerHeaderCell(
                                    player: player,
                                    zoomLevel: zoomLevel
                                )
                            }
                        }
                        
                        // Score Rows
                        ForEach(holes, id: \.self) { hole in
                            HStack(spacing: 0) {
                                // Hole number and par
                                HoleInfoCell(
                                    hole: hole,
                                    par: getParForHole(hole),
                                    zoomLevel: zoomLevel
                                )
                                
                                // Score cells for each player
                                ForEach(players) { player in
                                    ScoreGridCell(
                                        hole: hole,
                                        player: player,
                                        score: gameState.getScore(hole: hole, player: player.id),
                                        predictedScore: predictionService.predictScore(
                                            for: player,
                                            hole: Hole(number: hole, par: getParForHole(hole), yards: 380, handicapIndex: 7)
                                        ),
                                        par: getParForHole(hole),
                                        isSelected: selectedCell == GridCell(hole: hole, playerId: player.id),
                                        isEditing: editingCell == GridCell(hole: hole, playerId: player.id),
                                        isMultiSelected: selectedCells.contains(GridCell(hole: hole, playerId: player.id)),
                                        multiSelectMode: multiSelectMode,
                                        zoomLevel: zoomLevel,
                                        onTap: {
                                            handleCellTap(hole: hole, player: player)
                                        },
                                        onLongPress: {
                                            handleCellLongPress(hole: hole, player: player)
                                        },
                                        onScoreChange: { newScore in
                                            handleScoreChange(hole: hole, player: player, score: newScore)
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Totals Row
                        HStack(spacing: 0) {
                            Text("Total")
                                .font(.system(size: 14 * zoomLevel, weight: .bold))
                                .frame(width: 60 * zoomLevel, height: 40 * zoomLevel)
                                .background(Color.blue.opacity(0.2))
                                .border(Color.gray.opacity(0.3), width: 0.5)
                            
                            ForEach(players) { player in
                                TotalScoreCell(
                                    player: player,
                                    total: calculateTotal(for: player.id),
                                    par: calculateTotalPar(),
                                    zoomLevel: zoomLevel
                                )
                            }
                        }
                    }
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newZoom = zoomLevel * value
                            zoomLevel = max(minZoom, min(maxZoom, newZoom))
                        }
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getParForHole(_ hole: Int) -> Int {
        // TODO: Get from course data
        return 4
    }
    
    private func calculateTotal(for playerId: UUID) -> Int {
        var total = 0
        for hole in holes {
            total += gameState.getScore(hole: hole, player: playerId)
        }
        return total
    }
    
    private func calculateTotalPar() -> Int {
        holes.count * 4 // TODO: Calculate from actual pars
    }
    
    // MARK: - Cell Interaction Handlers
    
    private func handleCellTap(hole: Int, player: Player) {
        if multiSelectMode {
            let cell = GridCell(hole: hole, playerId: player.id)
            if selectedCells.contains(cell) {
                selectedCells.remove(cell)
            } else {
                selectedCells.insert(cell)
            }
        } else {
            selectedCell = GridCell(hole: hole, playerId: player.id)
            editingCell = GridCell(hole: hole, playerId: player.id)
        }
    }
    
    private func handleCellLongPress(hole: Int, player: Player) {
        if !multiSelectMode {
            multiSelectMode = true
            selectedCells.insert(GridCell(hole: hole, playerId: player.id))
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    private func handleScoreChange(hole: Int, player: Player, score: Int) {
        gameState.setScore(hole: hole, player: player.id, score: score)
        
        // Update prediction model
        let predicted = predictionService.predictScore(
            for: player,
            hole: Hole(number: hole, par: getParForHole(hole), yards: 380, handicapIndex: 7)
        )
        predictionService.updatePredictionModel(actual: score, predicted: predicted)
        
        // Navigate to next cell based on pattern
        navigateToNextCell(from: GridCell(hole: hole, playerId: player.id))
        
        // Track last edited for pattern learning
        lastEditedCell = GridCell(hole: hole, playerId: player.id)
    }
    
    private func navigateToNextCell(from currentCell: GridCell) {
        guard let playerIndex = players.firstIndex(where: { $0.id == currentCell.playerId }) else { return }
        
        switch navigationPattern {
        case .byHole:
            // Move to next player on same hole
            if playerIndex < players.count - 1 {
                let nextPlayer = players[playerIndex + 1]
                editingCell = GridCell(hole: currentCell.hole, playerId: nextPlayer.id)
                selectedCell = editingCell
            } else if currentCell.hole < holes.upperBound - 1 {
                // Move to first player on next hole
                editingCell = GridCell(hole: currentCell.hole + 1, playerId: players[0].id)
                selectedCell = editingCell
            }
            
        case .byPlayer:
            // Move to next hole for same player
            if currentCell.hole < holes.upperBound - 1 {
                editingCell = GridCell(hole: currentCell.hole + 1, playerId: currentCell.playerId)
                selectedCell = editingCell
            } else if playerIndex < players.count - 1 {
                // Move to next player's first hole
                let nextPlayer = players[playerIndex + 1]
                editingCell = GridCell(hole: holes.lowerBound, playerId: nextPlayer.id)
                selectedCell = editingCell
            }
            
        case .automatic:
            // Learn from user behavior and adapt
            // For now, default to by-hole
            navigateByHole(from: currentCell, playerIndex: playerIndex)
            
        case .none:
            // Don't navigate automatically
            break
        }
    }
    
    private func navigateByHole(from currentCell: GridCell, playerIndex: Int) {
        if playerIndex < players.count - 1 {
            let nextPlayer = players[playerIndex + 1]
            editingCell = GridCell(hole: currentCell.hole, playerId: nextPlayer.id)
            selectedCell = editingCell
        }
    }
    
    // MARK: - Batch Operations
    
    private func handleBatchEntry() {
        guard !selectedCells.isEmpty else { return }
        
        // Show batch entry dialog
        // For now, just set all selected cells to par
        for cell in selectedCells {
            gameState.setScore(hole: cell.hole, player: cell.playerId, score: getParForHole(cell.hole))
        }
        
        clearSelection()
    }
    
    private func clearSelection() {
        selectedCells.removeAll()
        multiSelectMode = false
    }
}

// MARK: - Grid Cell Components

struct ScoreGridCell: View {
    let hole: Int
    let player: Player
    let score: Int
    let predictedScore: Int
    let par: Int
    let isSelected: Bool
    let isEditing: Bool
    let isMultiSelected: Bool
    let multiSelectMode: Bool
    let zoomLevel: CGFloat
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onScoreChange: (Int) -> Void
    
    @State private var tempScore: String = ""
    @FocusState private var isFocused: Bool
    
    private var scoreColor: Color {
        guard score > 0 else { return .gray }
        if score < par { return .green }
        if score == par { return .blue }
        if score == par + 1 { return .orange }
        return .red
    }
    
    private var displayText: String {
        if score > 0 {
            return "\(score)"
        } else if !isEditing {
            return "\(predictedScore)"
        } else {
            return ""
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(
                    isMultiSelected ? Color.blue.opacity(0.2) :
                    isSelected ? Color.blue.opacity(0.1) :
                    score > 0 ? scoreColor.opacity(0.05) :
                    Color.clear
                )
                .border(
                    isSelected ? Color.blue :
                    isMultiSelected ? Color.blue.opacity(0.5) :
                    Color.gray.opacity(0.3),
                    width: isSelected || isMultiSelected ? 2 : 0.5
                )
            
            // Content
            if isEditing {
                TextField("", text: $tempScore)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16 * zoomLevel, weight: .bold))
                    .foregroundColor(scoreColor)
                    .focused($isFocused)
                    .onAppear {
                        tempScore = score > 0 ? "\(score)" : ""
                        isFocused = true
                    }
                    .onSubmit {
                        if let newScore = Int(tempScore), newScore > 0 {
                            onScoreChange(newScore)
                        }
                        isFocused = false
                    }
            } else {
                Text(displayText)
                    .font(.system(size: 16 * zoomLevel, weight: score > 0 ? .bold : .regular))
                    .foregroundColor(score > 0 ? scoreColor : .gray.opacity(0.5))
                    .opacity(score > 0 ? 1.0 : 0.6)
            }
            
            // Multi-select indicator
            if multiSelectMode && isMultiSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12 * zoomLevel))
                    .foregroundColor(.blue)
                    .position(x: 8 * zoomLevel, y: 8 * zoomLevel)
            }
        }
        .frame(width: 60 * zoomLevel, height: 40 * zoomLevel)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

struct PlayerHeaderCell: View {
    let player: Player
    let zoomLevel: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            Text(player.name)
                .font(.system(size: 12 * zoomLevel, weight: .semibold))
                .lineLimit(1)
            
            if player.handicap > 0 {
                Text("HCP \(player.handicap)")
                    .font(.system(size: 10 * zoomLevel))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 60 * zoomLevel, height: 40 * zoomLevel)
        .background(Color.blue.opacity(0.1))
        .border(Color.gray.opacity(0.3), width: 0.5)
    }
}

struct HoleInfoCell: View {
    let hole: Int
    let par: Int
    let zoomLevel: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(hole)")
                .font(.system(size: 14 * zoomLevel, weight: .bold))
            Text("Par \(par)")
                .font(.system(size: 10 * zoomLevel))
                .foregroundColor(.gray)
        }
        .frame(width: 60 * zoomLevel, height: 40 * zoomLevel)
        .background(Color.gray.opacity(0.1))
        .border(Color.gray.opacity(0.3), width: 0.5)
    }
}

struct TotalScoreCell: View {
    let player: Player
    let total: Int
    let par: Int
    let zoomLevel: CGFloat
    
    private var differential: Int {
        total - par
    }
    
    private var differentialText: String {
        if differential == 0 { return "E" }
        if differential > 0 { return "+\(differential)" }
        return "\(differential)"
    }
    
    private var scoreColor: Color {
        if differential < 0 { return .green }
        if differential == 0 { return .blue }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(total)")
                .font(.system(size: 16 * zoomLevel, weight: .bold))
                .foregroundColor(scoreColor)
            
            Text(differentialText)
                .font(.system(size: 12 * zoomLevel))
                .foregroundColor(scoreColor.opacity(0.8))
        }
        .frame(width: 60 * zoomLevel, height: 40 * zoomLevel)
        .background(scoreColor.opacity(0.1))
        .border(Color.gray.opacity(0.3), width: 0.5)
    }
}

// MARK: - Toolbar

struct ScoreGridToolbar: View {
    @Binding var multiSelectMode: Bool
    let selectedCount: Int
    @Binding var zoomLevel: CGFloat
    @Binding var navigationPattern: NavigationPattern
    let onBatchEntry: () -> Void
    let onClearSelection: () -> Void
    
    var body: some View {
        HStack {
            if multiSelectMode {
                Text("\(selectedCount) selected")
                    .font(.system(size: 14, weight: .medium))
                
                Button("Clear") {
                    onClearSelection()
                }
                .font(.system(size: 14))
                
                Button("Batch Entry") {
                    onBatchEntry()
                }
                .font(.system(size: 14, weight: .semibold))
            } else {
                Menu {
                    ForEach(NavigationPattern.allCases, id: \.self) { pattern in
                        Button(action: {
                            navigationPattern = pattern
                        }) {
                            Label(
                                pattern.rawValue,
                                systemImage: navigationPattern == pattern ? "checkmark" : ""
                            )
                        }
                    }
                } label: {
                    Label("Navigation", systemImage: "arrow.right.square")
                        .font(.system(size: 14))
                }
            }
            
            Spacer()
            
            // Zoom controls
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation {
                        zoomLevel = max(0.5, zoomLevel - 0.25)
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                
                Text("\(Int(zoomLevel * 100))%")
                    .font(.system(size: 12))
                    .frame(width: 40)
                
                Button(action: {
                    withAnimation {
                        zoomLevel = min(2.0, zoomLevel + 0.25)
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Supporting Types

struct GridCell: Hashable {
    let hole: Int
    let playerId: UUID
}

enum NavigationPattern: String, CaseIterable {
    case byHole = "By Hole"
    case byPlayer = "By Player"
    case automatic = "Smart"
    case none = "Manual"
}

// MARK: - Score Update for Backend Sync

struct ScoreUpdate {
    let hole: Int
    let playerId: UUID
    let score: Int
    let timestamp: Date
    
    // Placeholder for backend sync
    var syncStatus: SyncStatus = .pending
}

enum SyncStatus {
    case pending
    case syncing
    case synced
    case failed
}

struct ScoreGridSync {
    // Placeholder for backend sync
    var syncQueue: [ScoreUpdate] = []
    
    mutating func batchUpdate(_ scores: [ScoreUpdate]) {
        // TODO: Implement conflict resolution
        // TODO: Add optimistic updates with rollback
        syncQueue.append(contentsOf: scores)
    }
}