import SwiftUI

// MARK: - Enhanced Multi-Player Score Grid

struct EnhancedScoreGrid: View {
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
    @State private var showBatchEntry = false
    @State private var batchScore = ""
    
    // Smart navigation
    @State private var navigationPattern: NavigationPattern = .byHole
    @State private var userNavigationHistory: [NavigationMove] = []
    @State private var adaptiveNavigation = true
    
    // Swipe gesture
    @State private var swipeStartCell: GridCell? = nil
    @State private var swipeCurrentValue = 3
    @State private var isSwipeSequencing = false
    
    // Backend sync
    @State private var syncQueue: [ScoreUpdate] = []
    @State private var conflictResolution: ConflictResolution? = nil
    
    private let minZoom: CGFloat = 0.6
    private let maxZoom: CGFloat = 2.0
    private let cellWidth: CGFloat = 80
    private let cellHeight: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced toolbar
            EnhancedGridToolbar(
                multiSelectMode: $multiSelectMode,
                selectedCount: selectedCells.count,
                zoomLevel: $zoomLevel,
                navigationPattern: $navigationPattern,
                adaptiveNavigation: $adaptiveNavigation,
                onBatchEntry: { showBatchEntry = true },
                onClearSelection: clearSelection,
                onZoomFit: fitToScreen
            )
            
            // Main grid with pinch-to-zoom
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        // Grid content
                        VStack(spacing: 0) {
                            // Header row
                            headerRow
                            
                            // Score rows
                            ForEach(holes, id: \.self) { hole in
                                scoreRow(for: hole)
                            }
                            
                            // Totals row
                            totalsRow
                        }
                        
                        // Swipe overlay for sequential entry
                        if isSwipeSequencing {
                            swipeSequenceOverlay
                        }
                    }
                }
                .scaleEffect(zoomLevel)
                .gesture(
                    SimultaneousGesture(
                        // Pinch to zoom
                        MagnificationGesture()
                            .onChanged { value in
                                let newZoom = zoomLevel * value
                                zoomLevel = max(minZoom, min(maxZoom, newZoom))
                            },
                        
                        // Pan gesture for multi-cell selection
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                handlePanGesture(value, in: geometry)
                            }
                            .onEnded { _ in
                                endPanGesture()
                            }
                    )
                )
            }
        }
        .sheet(isPresented: $showBatchEntry) {
            BatchEntryView(
                selectedCells: selectedCells,
                onApply: applyBatchScore,
                onDismiss: { showBatchEntry = false }
            )
        }
        .alert("Conflict Detected", isPresented: .constant(conflictResolution != nil)) {
            Button("Keep Mine") {
                resolveConflict(keepLocal: true)
            }
            Button("Use Theirs") {
                resolveConflict(keepLocal: false)
            }
            Button("Merge") {
                mergeConflict()
            }
        } message: {
            if let conflict = conflictResolution {
                Text("Score for Hole \(conflict.hole) differs. Local: \(conflict.localScore), Remote: \(conflict.remoteScore)")
            }
        }
    }
    
    // MARK: - Grid Components
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Hole header
            Text("Hole")
                .headerCellStyle(width: cellWidth * zoomLevel, height: cellHeight * zoomLevel)
                .background(Color.gray.opacity(0.3))
            
            // Player headers
            ForEach(players) { player in
                PlayerHeaderCell(
                    player: player,
                    width: cellWidth * zoomLevel,
                    height: cellHeight * zoomLevel
                )
            }
        }
    }
    
    private func scoreRow(for hole: Int) -> some View {
        HStack(spacing: 0) {
            // Hole info
            HoleInfoCell(
                hole: hole,
                par: getParForHole(hole),
                width: cellWidth * zoomLevel,
                height: cellHeight * zoomLevel
            )
            
            // Score cells
            ForEach(players) { player in
                EnhancedScoreCell(
                    hole: hole,
                    player: player,
                    score: gameState.getScore(hole: hole, player: player.id),
                    par: getParForHole(hole),
                    isSelected: selectedCell == GridCell(hole: hole, playerId: player.id),
                    isEditing: editingCell == GridCell(hole: hole, playerId: player.id),
                    isMultiSelected: selectedCells.contains(GridCell(hole: hole, playerId: player.id)),
                    multiSelectMode: multiSelectMode,
                    width: cellWidth * zoomLevel,
                    height: cellHeight * zoomLevel,
                    onTap: { handleCellTap(hole: hole, player: player) },
                    onLongPress: { handleCellLongPress(hole: hole, player: player) },
                    onScoreChange: { newScore in
                        handleScoreChange(hole: hole, player: player, score: newScore)
                    },
                    onSwipeStart: { startSwipeSequence(from: GridCell(hole: hole, playerId: player.id)) },
                    onSwipeMove: { handleSwipeMove(to: GridCell(hole: hole, playerId: player.id)) }
                )
            }
        }
    }
    
    private var totalsRow: some View {
        HStack(spacing: 0) {
            Text("Total")
                .headerCellStyle(width: cellWidth * zoomLevel, height: cellHeight * zoomLevel)
                .background(Color.blue.opacity(0.2))
            
            ForEach(players) { player in
                TotalCell(
                    player: player,
                    total: calculateTotal(for: player.id),
                    par: calculateTotalPar(),
                    width: cellWidth * zoomLevel,
                    height: cellHeight * zoomLevel
                )
            }
        }
    }
    
    private var swipeSequenceOverlay: some View {
        VStack {
            HStack {
                Text("Swipe Entry Mode")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button("Done") {
                    endSwipeSequence()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
            .shadow(radius: 3)
            
            Spacer()
            
            // Score picker
            HStack {
                ForEach([3, 4, 5, 6, 7], id: \.self) { score in
                    Button("\(score)") {
                        swipeCurrentValue = score
                    }
                    .font(.system(size: 18, weight: swipeCurrentValue == score ? .bold : .medium))
                    .foregroundColor(swipeCurrentValue == score ? .white : .black)
                    .frame(width: 40, height: 40)
                    .background(swipeCurrentValue == score ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 3)
        }
        .padding()
    }
    
    // MARK: - Gesture Handlers
    
    private func handleCellTap(hole: Int, player: Player) {
        let cell = GridCell(hole: hole, playerId: player.id)
        
        if multiSelectMode {
            toggleCellSelection(cell)
        } else {
            selectCell(cell)
            trackNavigation(from: selectedCell, to: cell)
        }
    }
    
    private func handleCellLongPress(hole: Int, player: Player) {
        let cell = GridCell(hole: hole, playerId: player.id)
        
        if !multiSelectMode {
            enableMultiSelectMode()
            selectCell(cell)
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func handlePanGesture(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        guard multiSelectMode else { return }
        
        // Convert pan location to grid coordinates
        let location = value.location
        if let cell = cellAtLocation(location, geometry: geometry) {
            selectedCells.insert(cell)
        }
    }
    
    private func endPanGesture() {
        // Pan gesture ended
    }
    
    private func startSwipeSequence(from cell: GridCell) {
        swipeStartCell = cell
        isSwipeSequencing = true
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func handleSwipeMove(to cell: GridCell) {
        guard isSwipeSequencing else { return }
        
        // Apply current value to swiped cell
        if let hole = holes.first(where: { $0 == cell.hole }),
           let player = players.first(where: { $0.id == cell.playerId }) {
            handleScoreChange(hole: hole, player: player, score: swipeCurrentValue)
        }
    }
    
    private func endSwipeSequence() {
        isSwipeSequencing = false
        swipeStartCell = nil
    }
    
    // MARK: - Cell Selection
    
    private func selectCell(_ cell: GridCell) {
        selectedCell = cell
        editingCell = cell
    }
    
    private func toggleCellSelection(_ cell: GridCell) {
        if selectedCells.contains(cell) {
            selectedCells.remove(cell)
        } else {
            selectedCells.insert(cell)
        }
    }
    
    private func enableMultiSelectMode() {
        multiSelectMode = true
        selectedCell = nil
        editingCell = nil
    }
    
    private func clearSelection() {
        selectedCells.removeAll()
        multiSelectMode = false
        selectedCell = nil
        editingCell = nil
    }
    
    // MARK: - Score Handling
    
    private func handleScoreChange(hole: Int, player: Player, score: Int) {
        let oldScore = gameState.getScore(hole: hole, player: player.id)
        
        // Optimistic update
        gameState.setScore(hole: hole, player: player.id, score: score)
        
        // Queue for backend sync
        let update = ScoreUpdate(
            hole: hole,
            playerId: player.id,
            score: score,
            previousScore: oldScore,
            timestamp: Date(),
            source: .user
        )
        
        queueScoreUpdate(update)
        
        // Smart navigation
        if !multiSelectMode {
            navigateToNextCell(from: GridCell(hole: hole, playerId: player.id))
        }
    }
    
    private func navigateToNextCell(from currentCell: GridCell) {
        guard let playerIndex = players.firstIndex(where: { $0.id == currentCell.playerId }) else { return }
        
        let pattern = adaptiveNavigation ? learnedNavigationPattern() : navigationPattern
        
        switch pattern {
        case .byHole:
            navigateByHole(from: currentCell, playerIndex: playerIndex)
        case .byPlayer:
            navigateByPlayer(from: currentCell)
        case .smart:
            navigateSmartly(from: currentCell, playerIndex: playerIndex)
        }
    }
    
    private func navigateByHole(from cell: GridCell, playerIndex: Int) {
        if playerIndex < players.count - 1 {
            let nextPlayer = players[playerIndex + 1]
            selectCell(GridCell(hole: cell.hole, playerId: nextPlayer.id))
        } else if cell.hole < holes.upperBound - 1 {
            selectCell(GridCell(hole: cell.hole + 1, playerId: players[0].id))
        }
    }
    
    private func navigateByPlayer(from cell: GridCell) {
        if cell.hole < holes.upperBound - 1 {
            selectCell(GridCell(hole: cell.hole + 1, playerId: cell.playerId))
        }
    }
    
    private func navigateSmartly(from cell: GridCell, playerIndex: Int) {
        // Use learned pattern or default to by-hole
        navigateByHole(from: cell, playerIndex: playerIndex)
    }
    
    // MARK: - Learning System
    
    private func trackNavigation(from: GridCell?, to: GridCell) {
        guard let from = from else { return }
        
        let move = NavigationMove(
            from: from,
            to: to,
            timestamp: Date(),
            pattern: determinePattern(from: from, to: to)
        )
        
        userNavigationHistory.append(move)
        
        // Keep only recent history
        if userNavigationHistory.count > 50 {
            userNavigationHistory.removeFirst()
        }
    }
    
    private func learnedNavigationPattern() -> NavigationPattern {
        let recentMoves = userNavigationHistory.suffix(10)
        let byHoleMoves = recentMoves.filter { $0.pattern == .byHole }.count
        let byPlayerMoves = recentMoves.filter { $0.pattern == .byPlayer }.count
        
        if byHoleMoves > byPlayerMoves {
            return .byHole
        } else if byPlayerMoves > byHoleMoves {
            return .byPlayer
        } else {
            return .smart
        }
    }
    
    private func determinePattern(from: GridCell, to: GridCell) -> NavigationPattern {
        if from.hole == to.hole && from.playerId != to.playerId {
            return .byHole
        } else if from.playerId == to.playerId && from.hole != to.hole {
            return .byPlayer
        } else {
            return .smart
        }
    }
    
    // MARK: - Batch Operations
    
    private func applyBatchScore(_ scoreText: String) {
        guard let score = Int(scoreText) else { return }
        
        for cell in selectedCells {
            if let player = players.first(where: { $0.id == cell.playerId }) {
                handleScoreChange(hole: cell.hole, player: player, score: score)
            }
        }
        
        clearSelection()
        showBatchEntry = false
    }
    
    // MARK: - Backend Sync
    
    private func queueScoreUpdate(_ update: ScoreUpdate) {
        syncQueue.append(update)
        
        // Attempt immediate sync if online
        Task {
            await syncScoreUpdates()
        }
    }
    
    private func syncScoreUpdates() async {
        guard !syncQueue.isEmpty else { return }
        
        let updates = syncQueue
        syncQueue.removeAll()
        
        do {
            try await BackendService.shared.batchSaveScores(updates.map { Score(hole: $0.hole, value: $0.score, timestamp: $0.timestamp) })
        } catch {
            // Re-queue failed updates
            syncQueue.append(contentsOf: updates)
            handleSyncError(error)
        }
    }
    
    private func handleSyncError(_ error: Error) {
        // Show sync error indicator
        print("Sync failed: \(error)")
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(keepLocal: Bool) {
        guard let conflict = conflictResolution else { return }
        
        if keepLocal {
            // Keep local version, mark as resolved
        } else {
            // Accept remote version
            gameState.setScore(hole: conflict.hole, player: conflict.playerId, score: conflict.remoteScore)
        }
        
        conflictResolution = nil
    }
    
    private func mergeConflict() {
        guard let conflict = conflictResolution else { return }
        
        // Show merge options or use average
        let mergedScore = (conflict.localScore + conflict.remoteScore) / 2
        gameState.setScore(hole: conflict.hole, player: conflict.playerId, score: mergedScore)
        
        conflictResolution = nil
    }
    
    // MARK: - Utility Functions
    
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
    
    private func fitToScreen() {
        zoomLevel = 0.8 // Fit to show all content
    }
    
    private func cellAtLocation(_ location: CGPoint, geometry: GeometryProxy) -> GridCell? {
        // Convert screen location to grid coordinates
        let col = Int(location.x / (cellWidth * zoomLevel))
        let row = Int(location.y / (cellHeight * zoomLevel))
        
        if col > 0, col <= players.count, row > 0, row <= holes.count {
            let player = players[col - 1]
            let hole = holes.lowerBound + row - 1
            return GridCell(hole: hole, playerId: player.id)
        }
        
        return nil
    }
}

// MARK: - Enhanced Score Cell

struct EnhancedScoreCell: View {
    let hole: Int
    let player: Player
    let score: Int
    let par: Int
    let isSelected: Bool
    let isEditing: Bool
    let isMultiSelected: Bool
    let multiSelectMode: Bool
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onScoreChange: (Int) -> Void
    let onSwipeStart: () -> Void
    let onSwipeMove: () -> Void
    
    @State private var tempScore = ""
    @FocusState private var isFocused: Bool
    @State private var dragOffset: CGSize = .zero
    
    private var scoreQuality: ScoreQuality {
        guard score > 0 else { return .none }
        let diff = score - par
        if diff <= -2 { return .eagle }
        if diff == -1 { return .birdie }
        if diff == 0 { return .par }
        if diff == 1 { return .bogey }
        return .worse
    }
    
    var body: some View {
        ZStack {
            // Background with quality color
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
            
            // Content
            if isEditing && !multiSelectMode {
                TextField("", text: $tempScore)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: fontSize, weight: .semibold))
                    .focused($isFocused)
                    .onAppear {
                        tempScore = score > 0 ? "\(score)" : ""
                        isFocused = true
                    }
                    .onSubmit {
                        submitScore()
                    }
            } else {
                Text(displayText)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundColor(textColor)
                    .opacity(score > 0 ? 1.0 : 0.6)
            }
            
            // Multi-select indicator
            if multiSelectMode && isMultiSelected {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
            }
            
            // Sync indicator
            if false { // TODO: Show when syncing
                VStack {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .frame(width: width, height: height)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .offset(dragOffset)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    dragOffset = value.translation
                    if abs(value.translation.x) > 20 || abs(value.translation.y) > 20 {
                        onSwipeStart()
                    }
                    onSwipeMove()
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private var displayText: String {
        score > 0 ? "\(score)" : ""
    }
    
    private var backgroundColor: Color {
        if isMultiSelected {
            return Color.blue.opacity(0.3)
        }
        if isSelected {
            return Color.blue.opacity(0.2)
        }
        return scoreQuality.backgroundColor
    }
    
    private var textColor: Color {
        if isSelected || isMultiSelected {
            return .black
        }
        return scoreQuality.textColor
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        }
        if isMultiSelected {
            return .blue.opacity(0.7)
        }
        return scoreQuality.borderColor
    }
    
    private var borderWidth: CGFloat {
        (isSelected || isMultiSelected) ? 2 : 0.5
    }
    
    private var fontSize: CGFloat {
        min(width * 0.3, height * 0.4)
    }
    
    private func submitScore() {
        if let newScore = Int(tempScore), newScore > 0 {
            onScoreChange(newScore)
        }
        isFocused = false
    }
}

// MARK: - Enhanced Grid Toolbar

struct EnhancedGridToolbar: View {
    @Binding var multiSelectMode: Bool
    let selectedCount: Int
    @Binding var zoomLevel: CGFloat
    @Binding var navigationPattern: NavigationPattern
    @Binding var adaptiveNavigation: Bool
    let onBatchEntry: () -> Void
    let onClearSelection: () -> Void
    let onZoomFit: () -> Void
    
    var body: some View {
        HStack {
            if multiSelectMode {
                // Multi-select toolbar
                Text("\(selectedCount) selected")
                    .font(.system(size: 14, weight: .medium))
                
                Button("Batch Entry") {
                    onBatchEntry()
                }
                .font(.system(size: 14))
                .disabled(selectedCount == 0)
                
                Button("Clear") {
                    onClearSelection()
                }
                .font(.system(size: 14))
                
            } else {
                // Normal toolbar
                Menu {
                    ForEach(NavigationPattern.allCases, id: \.self) { pattern in
                        Button(action: {
                            navigationPattern = pattern
                        }) {
                            HStack {
                                Text(pattern.displayName)
                                if navigationPattern == pattern {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Toggle("Adaptive Navigation", isOn: $adaptiveNavigation)
                } label: {
                    Label("Navigation", systemImage: "arrow.right.square")
                        .font(.system(size: 14))
                }
            }
            
            Spacer()
            
            // Zoom controls
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        zoomLevel = max(0.6, zoomLevel - 0.2)
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 14))
                }
                
                Button(action: onZoomFit) {
                    Text("Fit")
                        .font(.system(size: 12))
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        zoomLevel = min(2.0, zoomLevel + 0.2)
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Batch Entry View

struct BatchEntryView: View {
    let selectedCells: Set<GridCell>
    let onApply: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var scoreText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Batch Score Entry")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Enter score for \(selectedCells.count) selected cells")
                    .foregroundColor(.gray)
                
                TextField("Score", text: $scoreText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                
                // Quick score buttons
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach([3, 4, 5, 6, 7, 8], id: \.self) { score in
                        Button("\(score)") {
                            scoreText = "\(score)"
                        }
                        .font(.system(size: 18, weight: .medium))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(scoreText)
                    }
                    .disabled(scoreText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ScoreQuality {
    case none, eagle, birdie, par, bogey, worse
    
    var backgroundColor: Color {
        switch self {
        case .none: return .clear
        case .eagle: return .purple.opacity(0.2)
        case .birdie: return .green.opacity(0.2)
        case .par: return .blue.opacity(0.1)
        case .bogey: return .orange.opacity(0.2)
        case .worse: return .red.opacity(0.2)
        }
    }
    
    var textColor: Color {
        switch self {
        case .none: return .gray
        case .eagle: return .purple
        case .birdie: return .green
        case .par: return .blue
        case .bogey: return .orange
        case .worse: return .red
        }
    }
    
    var borderColor: Color {
        switch self {
        case .none: return .gray.opacity(0.3)
        case .eagle: return .purple.opacity(0.5)
        case .birdie: return .green.opacity(0.5)
        case .par: return .blue.opacity(0.3)
        case .bogey: return .orange.opacity(0.5)
        case .worse: return .red.opacity(0.5)
        }
    }
}

enum NavigationPattern: CaseIterable {
    case byHole, byPlayer, smart
    
    var displayName: String {
        switch self {
        case .byHole: return "By Hole (→ next player)"
        case .byPlayer: return "By Player (↓ next hole)"
        case .smart: return "Smart (learned)"
        }
    }
}

struct NavigationMove {
    let from: GridCell
    let to: GridCell
    let timestamp: Date
    let pattern: NavigationPattern
}

struct ScoreUpdate {
    let hole: Int
    let playerId: UUID
    let score: Int
    let previousScore: Int
    let timestamp: Date
    let source: UpdateSource
}

enum UpdateSource {
    case user, sync, batch
}

struct ConflictResolution {
    let hole: Int
    let playerId: UUID
    let localScore: Int
    let remoteScore: Int
}

// MARK: - View Extensions

extension Text {
    func headerCellStyle(width: CGFloat, height: CGFloat) -> some View {
        self
            .font(.system(size: min(width * 0.15, height * 0.25), weight: .semibold))
            .frame(width: width, height: height)
            .border(Color.gray.opacity(0.3), width: 0.5)
    }
}