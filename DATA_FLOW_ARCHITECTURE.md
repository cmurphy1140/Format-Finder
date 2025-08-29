# Format Finder Data Flow Architecture

## 📊 Complete Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         USER ACTION                          │
│                    (Tap, Swipe, Input)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      1. UI LAYER                             │
│                                                              │
│  SwiftUI Views ─────► @EnvironmentObject ────► AppState     │
│  (FormatCard)         (Reactive Binding)      (Shared)      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   2. STATE MANAGEMENT                        │
│                                                              │
│  AppState ──► Combine Publishers ──► Business Logic         │
│     │              │                      │                  │
│     └── @Published properties ────────────┘                 │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   3. SERVICE LAYER                           │
│                                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Format    │  │   Scoring    │  │  Statistics  │      │
│  │   Service   │  │    Engine    │  │   Manager    │      │
│  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                │                  │               │
│         └────────────────┴──────────────────┘               │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   4. DATA LAYER                              │
│                                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Core Data  │  │  CloudKit    │  │ UserDefaults │      │
│  │  (Local)    │  │   (Cloud)    │  │  (Settings)  │      │
│  └──────┬──────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                │                  │               │
│         └────────────────┴──────────────────┘               │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   5. BACKEND RESPONSE                        │
│                                                              │
│  Data Processing ──► Model Updates ──► State Changes        │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   6. UI UPDATE                               │
│                                                              │
│  State Changes ──► SwiftUI Rerender ──► View Updates        │
│                                                              │
│  User sees: • Updated scores                                │
│             • New achievements                               │
│             • Refreshed statistics                           │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Detailed Flow Examples

### Example 1: User Starts a New Game

```swift
USER ACTION: Taps "New Game" button
    ↓
VIEW: QuickActionButton.action()
    ↓
APPSTATE: startNewGame(format: Scramble, players: [4])
    ↓
SERVICES: 
    - FormatDataService.validateFormat()
    - GameSession.create()
    - CoreDataStack.save()
    ↓
BACKEND:
    - CloudKit.createRecord()
    - Analytics.trackGameStart()
    ↓
RESPONSE:
    - GameSession saved with ID
    - Navigation updated
    ↓
UI UPDATE:
    - Navigate to ActiveGameView
    - Show current hole (1)
    - Display player scorecards
```

### Example 2: User Records a Score

```swift
USER ACTION: Enters score "4" for Hole 1
    ↓
VIEW: ScoreEntryView.submitScore()
    ↓
APPSTATE: recordScore(hole: 1, player: John, strokes: 4)
    ↓
SERVICES:
    - ScoringEngine.calculateScore()
    - StatisticsManager.updateStats()
    - AchievementDetector.check()
    ↓
BACKEND:
    - CoreData.updateHoleScore()
    - CloudKit.syncScore()
    - Calculate running totals
    ↓
RESPONSE:
    - Score saved
    - Stats updated
    - Achievement unlocked (if applicable)
    ↓
UI UPDATE:
    - Score displayed on card
    - Running total updated
    - Achievement celebration shown
    - Haptic feedback triggered
```

### Example 3: User Views Statistics

```swift
USER ACTION: Taps "Stats" tab
    ↓
VIEW: StatisticsView.onAppear()
    ↓
APPSTATE: loadStatistics()
    ↓
SERVICES:
    - StatisticsManager.fetchAllStats()
    - CoreDataStack.query()
    ↓
BACKEND:
    - Aggregate scores
    - Calculate averages
    - Generate trends
    ↓
RESPONSE:
    - PlayerStatistics object
    - FormatStatistics dictionary
    - Recent rounds array
    ↓
UI UPDATE:
    - Charts rendered
    - Averages displayed
    - Achievements shown
    - Trends visualized
```

## 🔄 Real-Time Sync Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Device A   │────►│   CloudKit   │◄────│   Device B   │
│              │     │              │     │              │
│  User plays  │     │  Sync Data   │     │  See updates │
│    Hole 1    │     │              │     │   in real    │
│              │     │              │     │    time      │
└──────────────┘     └──────────────┘     └──────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
   Local Save          Cloud Save           Remote Update
   Core Data           CKRecord             Core Data
```

## 🎮 Key Components Interaction

### 1. AppState (Central Hub)
```swift
class AppState {
    // Receives user actions
    func handleUserAction() → Service Call
    
    // Manages data flow
    @Published properties → Trigger UI updates
    
    // Coordinates services
    Services.perform() → Backend operations
}
```

### 2. Service Layer (Business Logic)
```swift
FormatDataService {
    fetchFormats() → [GolfFormat]
    saveFormat() → Success/Failure
}

ScoringEngine {
    calculateScore() → Score
    validateScore() → Bool
}

StatisticsManager {
    updateStats() → Stats
    getAverages() → Numbers
}
```

### 3. Data Persistence
```swift
CoreDataStack {
    Local storage → Offline capability
    Fast access → Immediate UI updates
}

CloudKitSync {
    Remote backup → Data safety
    Multi-device → Sync across devices
}
```

## 📱 State Update Propagation

```
1. User Action
   └─► AppState.function()
       └─► @Published property changes
           └─► Combine publisher fires
               └─► All subscribed views update
                   └─► SwiftUI re-renders affected UI
```

## 🔍 Debug Flow Tracking

To trace data flow in the app:

```swift
// Enable in FormatFinderConfig
debugMode = true
showDataFlow = true

// Logs will show:
[UI] Button tapped: New Game
[STATE] startNewGame called
[SERVICE] FormatDataService.validate
[BACKEND] CoreData.save
[CLOUD] CloudKit.sync
[RESPONSE] Success: GameID-123
[UI] Navigation to GameView
```

## 🚀 Performance Optimizations

1. **Debouncing**: Score updates debounced by 2 seconds
2. **Caching**: Recent formats cached in memory
3. **Lazy Loading**: Statistics loaded on demand
4. **Batch Updates**: Multiple scores sent together
5. **Background Sync**: CloudKit syncs in background

## 📊 Data Flow Metrics

- User Action → UI Update: ~100ms
- Local Save: ~10ms
- Cloud Sync: ~500ms-2s
- Statistics Calculation: ~50ms
- Achievement Detection: ~20ms

---

This architecture ensures:
- ✅ Responsive UI (immediate local updates)
- ✅ Data consistency (single source of truth)
- ✅ Offline capability (Core Data)
- ✅ Multi-device sync (CloudKit)
- ✅ Testability (separated concerns)