# Format Finder - Complete Project Documentation

## Project Overview
**Format Finder** is a comprehensive iOS golf companion app that helps players understand and play 12 different golf game formats. The app features interactive tutorials, real-time scorecards, and AI-powered assistance.

**Developer:** Connor Murphy  
**Platform:** iOS 17.0+  
**Language:** Swift 5  
**Framework:** SwiftUI  
**Bundle ID:** com.formatfinder.FormatFinder  

---

## Core Features

### 1. **12 Golf Game Formats**
Complete implementations with rules, scoring, and strategies:
- **Scramble** - Team format with best ball selection tracking
- **Best Ball** - Individual play, team's best score counts
- **Match Play** - Hole-by-hole competition
- **Skins** - Monetary game with carryover tracking
- **Stableford** - Point-based scoring system
- **Four-Ball** - Two-team competition
- **Alternate Shot** - Partners alternate shots
- **Nassau** - Three separate matches (Front 9, Back 9, Overall)
- **Bingo Bango Bongo** - Three points per hole system
- **Wolf** - Rotating captain with partner selection
- **Chapman** - Complex partner format
- **Vegas** - Team score combinations with flip rules

### 2. **Scorecard System**
- **Custom Scorecards** for each format
- **Ball Selection Tracking** (Scramble)
- **Match Status** (Match Play)
- **Skins Carryover** calculation
- **Point Systems** (Stableford, BBB)
- **Partner Selection** (Wolf)
- **Team Score Combinations** (Vegas)
- **Real-time Statistics**
- **Export Functionality** (PDF, CSV, Image, Text)

### 3. **Interactive Learning**
- **Animated Diagrams** for each format
- **Step-by-step Tutorials**
- **Strategy Tips**
- **Visual Examples**
- **Slide-based Presentations**

### 4. **Smart Caddie (AI Assistant)**
- **Club Recommendations**
- **Wind Adjustments**
- **Elevation Calculations**
- **Shot Strategy**
- **Course Management Tips**

### 5. **Modern UI/UX**
- **Light Theme** with soft greens and whites
- **Card-based Layouts** with shadows
- **Glass Morphism** effects
- **Smooth Animations**
- **Tab Navigation** (Browse, Saved, Play)
- **Dark/Light Mode** support ready

---

## Project Structure

```
Format Finder/
├── FormatFinder.xcodeproj          # Xcode project file
├── FormatFinder/                   # Main source directory
│   ├── Core App Files
│   │   ├── FormatFinderApp.swift   # App entry point, main navigation
│   │   ├── ColorTheme.swift        # Color system, light theme definitions
│   │   ├── AppIconView.swift       # App icon design generator
│   │   ├── AppIcon.swift           # Icon helper functions
│   │   └── GenerateAppIcon.swift   # Icon generation utilities
│   │
│   ├── Scorecard System
│   │   ├── GameModeSelector.swift  # Format selection & configuration
│   │   ├── ScorecardContainer.swift # Scorecard framework & navigation
│   │   ├── FormatScorecards.swift  # Scramble, Best Ball, Match Play, Skins
│   │   ├── AdvancedScorecards.swift # Stableford, Nassau, Wolf, Vegas
│   │   ├── RemainingFormatScorecards.swift # Four-Ball, Alt Shot, BBB, Chapman
│   │   └── StatsAndExport.swift    # Statistics dashboard & export
│   │
│   ├── Features
│   │   ├── EnhancedDiagrams.swift  # Interactive format diagrams
│   │   ├── DiagramSlides.swift     # Slide presentations for tutorials
│   │   ├── EnhancedApp.swift       # Enhanced navigation features
│   │   └── SmartCaddie.swift       # AI caddie recommendations
│   │
│   └── Assets.xcassets/            # Images, colors, app icon
│
├── Supporting Files
│   ├── deploy_to_phone.sh          # Deployment script
│   ├── add_theme_files.rb          # Ruby script for adding files
│   └── CONSOLIDATION_SUMMARY.md    # Project consolidation notes
│
└── Documentation
    ├── PROJECT_WIKI.md             # This file
    └── README.md                    # Basic project info
```

---

## Design System

### Color Palette
```swift
// Primary Colors
primaryGreen: RGB(76, 175, 80)      // #4CAF50
lightGreen: RGB(129, 199, 132)      // #81C784
darkGreen: RGB(56, 142, 60)         // #388E3C

// Background Colors  
backgroundPrimary: RGB(248, 250, 252)  // #F8FAFC
backgroundSecondary: White             // #FFFFFF
backgroundTertiary: RGB(245, 247, 250) // #F5F7FA

// Text Colors
textPrimary: RGB(33, 37, 41)        // #212529
textSecondary: RGB(108, 117, 125)   // #6C757D
textTertiary: RGB(173, 181, 189)    // #ADB5BD

// Accent Colors
accentBlue: RGB(33, 150, 243)       // #2196F3
accentOrange: RGB(255, 152, 0)      // #FF9800
accentPurple: RGB(156, 39, 176)     // #9C27B0
```

### Typography
- **Primary Font:** SF Pro Display (iOS system)
- **Sizes:** 12, 14, 16, 18, 20, 24, 32, 36pt
- **Weights:** Regular (400), Medium (500), Semibold (600), Bold (700)

### Components
- **Cards:** 16px corner radius, 8px shadow
- **Buttons:** Primary green gradient, white text
- **Navigation:** Tab bar with 3 tabs
- **Animations:** 0.3-0.6s duration, ease-in-out

---

## Technical Implementation

### Key Technologies
- **SwiftUI** - Declarative UI framework
- **Combine** - Reactive programming
- **@StateObject** - State management
- **@EnvironmentObject** - Dependency injection
- **TabView** - Navigation structure
- **GeometryReader** - Responsive layouts
- **Charts** framework - Statistics visualization

### Data Models
```swift
// Golf Format
struct GolfFormat {
    let name: String
    let category: String      // Tournament, Betting
    let players: String        // Player requirements
    let difficulty: String     // Easy, Medium, Hard
    let description: String
    let howToPlay: [String]
    let example: String
}

// Player
struct Player {
    let id: UUID
    var name: String
    var handicap: Int
    var isActive: Bool
}

// Game State
class GameState: ObservableObject {
    @Published var scores: [Int: [UUID: Int]]
    @Published var scrambleSelections: [Int: UUID]
    @Published var matchPlayStatus: MatchPlayStatus
    @Published var skinsWon: [Int: UUID]
    // ... format-specific states
}

// Configuration
struct GameConfiguration {
    var selectedFormat: GolfFormat?
    var players: [Player]
    var numberOfHoles: Int
    var courseRating: Double
    var slopeRating: Int
    var scoringRules: ScoringRules
}
```

### Architecture Patterns
- **MVVM** - Model-View-ViewModel pattern
- **Repository Pattern** - Data access layer
- **Coordinator Pattern** - Navigation flow
- **Factory Pattern** - Scorecard creation
- **Observer Pattern** - State updates

---

## Deployment

### Requirements
- **Xcode:** 16.0+
- **iOS Deployment Target:** 17.0
- **Development Team:** 9LDVUD49X7
- **Code Signing:** Automatic

### Build Commands
```bash
# Clean build
xcodebuild -project FormatFinder.xcodeproj clean

# Build for device
xcodebuild -project FormatFinder.xcodeproj \
  -scheme FormatFinder \
  -destination 'generic/platform=iOS' \
  build

# Create archive
xcodebuild -project FormatFinder.xcodeproj \
  -scheme FormatFinder \
  -archivePath ~/Desktop/FormatFinder.xcarchive \
  archive
```

### Deployment Script
```bash
# Run deployment script
./deploy_to_phone.sh
```

---

## Git Workflow

### Branches
- **main** - Production-ready code
- **feature/scorecards** - Scorecard system development
- **feature/ui-redesign** - UI/UX improvements

### Key Commits
```
6da8c64 - Consolidated Format Finder codebase
e5b8fed - Complete scorecard system integration
af98e4c - All 12 formats with custom scorecards
101c6a7 - Resolve build issues and code signing
```

---

## Features by Version

### Current Version (1.0)
- [x] All 12 golf formats
- [x] Interactive scorecards
- [x] Format tutorials
- [x] Smart Caddie
- [x] Statistics tracking
- [x] Export functionality
- [x] Light theme
- [x] Custom app icon

### Planned Features (2.0)
- [ ] Cloud sync (iCloud)
- [ ] Multiplayer support
- [ ] GPS rangefinder
- [ ] Apple Watch app
- [ ] Course database
- [ ] Historical stats
- [ ] Social sharing
- [ ] Tournaments

---

## App Navigation

### Tab Structure
1. **Browse Tab**
   - Format grid view
   - Search functionality
   - Filter by category
   - Format details
   - Interactive diagrams
   - Bookmarking

2. **Saved Tab**
   - Bookmarked formats
   - Quick access
   - Recent games

3. **Play Tab**
   - Start new game
   - Game mode selector
   - Player configuration
   - Scorecard entry
   - Statistics view
   - Export options

### User Flow
```
Launch → Browse Formats → Learn Format → Play Tab → 
Select Format → Configure Game → Enter Scores → 
View Stats → Export Results
```

---

## Scorecard Features

### Scramble
- Track whose ball is selected for each shot
- Shot type indicators (Tee, Fairway, Approach, Putt)
- Team score calculation

### Match Play
- Hole-by-hole status
- Running match score
- Concession options
- Press functionality

### Skins
- Carryover tracking
- Validation rules
- Skin values
- Winner display

### Nassau
- Three separate matches
- Press options
- Front/Back/Overall tracking
- Automatic calculations

### Wolf
- Wolf rotation
- Partner selection
- Blind wolf option
- Point multipliers

### Vegas
- Team score combinations
- Flip rule implementation
- Automatic scoring
- Point calculations

---

## Troubleshooting

### Common Issues

#### Trust Developer Certificate
```
Settings → General → VPN & Device Management → 
Developer App → Trust
```

#### Build Failures
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/FormatFinder-*

# Reset provisioning
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
```

#### Bundle ID Conflicts
Change in Xcode:
- Target → Signing & Capabilities
- Bundle Identifier: com.yourname.FormatFinder

---

## Performance Metrics

- **App Size:** ~15 MB
- **Launch Time:** <1 second
- **Memory Usage:** ~50 MB average
- **Battery Impact:** Low
- **Network:** Offline capable

---

## Privacy & Security

- **No Personal Data Collection**
- **Local Storage Only**
- **No Analytics/Tracking**
- **No Network Requests**
- **No Third-party SDKs**

---

## Code Standards

### Naming Conventions
- **Types:** PascalCase (FormatFinderApp)
- **Variables:** camelCase (selectedFormat)
- **Constants:** camelCase (primaryGreen)
- **Files:** PascalCase.swift

### Code Organization
- Group by feature, not file type
- Maximum 50 lines per function
- Use MARK comments for sections
- Prefer composition over inheritance

### SwiftUI Best Practices
- Extract complex views
- Use @ViewBuilder for conditional views
- Minimize @State usage
- Prefer computed properties
- Use environment objects wisely

---

## Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

### Golf Rules
- [USGA Rules](https://www.usga.org/rules)
- [R&A Rules](https://www.randa.org/rules)

---

## Contact

**Developer:** Connor Murphy  
**Email:** cmurphy1140@gmail.com  
**Bundle ID:** com.formatfinder.FormatFinder  
**Copyright:** (c) 2024 Format Finder. All rights reserved.

---

## License

This project is proprietary software. All rights reserved.

---

*Last Updated: August 27, 2024*