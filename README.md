# Format Finder 🏌️

A comprehensive iOS app for discovering and playing various golf game formats. Features interactive tutorials, real-time scoring, and beautiful visualizations for 12+ different golf formats.

## Features

- **12+ Golf Formats**: Stroke Play, Match Play, Stableford, Skins, Nassau, Best Ball, Scramble, Chapman, Four-Ball, Vegas, Wolf, and Bingo Bango Bongo
- **Interactive Tutorials**: Learn each format with animated diagrams and drag-and-drop interactions
- **Modern Scorecards**: Fluid gesture-based scoring with haptic feedback
- **Dynamic Themes**: 8 beautiful themes that change with time of day
- **Physics-Based Animations**: Realistic ball flight trajectories
- **Glassmorphism UI**: Modern visual effects with blur and transparency

## Project Structure

```
Format Finder/
├── FormatFinder/          # iOS app source code
│   ├── App/              # App entry point
│   ├── Core/             # Business logic & data layer
│   ├── Features/         # Feature modules
│   ├── UI/               # UI components & themes
│   ├── Utils/            # Utilities
│   └── Resources/        # App resources
├── FormatFinderTests/     # Unit tests
├── FormatFinderUITests/   # UI tests
├── scripts/              # Automation scripts
│   ├── deployment/       # Build & deploy scripts
│   ├── xcode/           # Xcode management
│   └── utilities/       # Utility scripts
├── docs/                 # Documentation
└── Assets/              # Design assets

```

## Getting Started

### Prerequisites

- Xcode 15.4+
- iOS 17.0+
- macOS Sonoma 14.0+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/cmurphy1140/Format-Finder.git
cd Format-Finder
```

2. Open in Xcode:
```bash
open FormatFinder.xcodeproj
```

3. Select your target device and press ⌘R to run

### Deployment

Deploy to a connected iPhone:
```bash
./scripts/deployment/deploy_to_phone.sh
```

## Development

### Scripts

- **Deployment**: `scripts/deployment/` - Build and deploy scripts
- **Xcode Management**: `scripts/xcode/` - Project file management
- **Utilities**: `scripts/utilities/` - Helper scripts

See [scripts documentation](scripts/README.md) for details.

### Documentation

- [Project Wiki](docs/PROJECT_WIKI.md)
- [Refactoring Guide](docs/REFACTORING_SUMMARY.md)
- [Architecture Overview](docs/CONSOLIDATION_SUMMARY.md)

## Technologies

- **SwiftUI** - Modern declarative UI framework
- **SpriteKit** - Interactive animations and physics
- **Core Haptics** - Tactile feedback
- **Combine** - Reactive programming
- **Core Data** - Data persistence

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests
4. Submit a pull request

## License

Copyright © 2024 Connor Murphy. All rights reserved.

## Contact

Connor Murphy - cmurphy1140@gmail.com

Project Link: [https://github.com/cmurphy1140/Format-Finder](https://github.com/cmurphy1140/Format-Finder)