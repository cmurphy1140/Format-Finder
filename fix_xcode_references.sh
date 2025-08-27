#!/bin/bash

echo "===================================="
echo "   Fix Xcode File References"
echo "===================================="
echo ""
echo "This will help sync your Xcode project with the new file structure."
echo ""

# Check if we're in the right directory
if [ ! -f "FormatFinder.xcodeproj/project.pbxproj" ]; then
    echo "Error: Please run this from the Format Finder directory"
    exit 1
fi

echo "Current file structure:"
echo ""
echo "📁 FormatFinder/"
echo "  📁 App/ - Main app entry point"
echo "  📁 Core/ - Core business logic"
echo "    📁 DataLayer/ - Data persistence"
echo "    📁 GameEngine/ - Game formats and protocols"
echo "    📁 Services/ - App services"
echo "  📁 Features/ - Feature modules"
echo "    📁 GameModes/ - Game mode selection"
echo "    📁 Scorecards/ - Scorecard views"
echo "    📁 Statistics/ - Stats and export"
echo "    📁 Tutorials/ - Interactive tutorials"
echo "  📁 UI/ - User interface"
echo "    📁 Effects/ - Visual effects"
echo "    📁 Theme/ - Theming system"
echo "  📁 Utils/ - Utility classes"
echo "  📁 Resources/ - App resources"
echo ""

echo "To fix in Xcode:"
echo "1. In Xcode, select the FormatFinder folder in the navigator"
echo "2. Right-click and choose 'Delete' > 'Remove References'"
echo "3. Right-click the FormatFinder project and choose 'Add Files to FormatFinder'"
echo "4. Navigate to Desktop/Format Finder/FormatFinder"
echo "5. Select all folders (App, Core, Features, UI, Utils, Resources)"
echo "6. Make sure 'Create groups' is selected"
echo "7. Click 'Add'"
echo ""
echo "Alternatively, close Xcode and run:"
echo "rm -rf ~/Library/Developer/Xcode/DerivedData/FormatFinder-*"
echo "Then reopen the project."
echo ""

# List the old files that should be removed from Xcode
echo "Old files to remove from Xcode (if shown):"
find . -maxdepth 2 -name "*.swift" -not -path "./FormatFinder/App/*" \
    -not -path "./FormatFinder/Core/*" \
    -not -path "./FormatFinder/Features/*" \
    -not -path "./FormatFinder/UI/*" \
    -not -path "./FormatFinder/Utils/*" \
    -not -path "./FormatFinder/Resources/*" \
    -not -path "./FormatFinderTests/*" \
    -not -path "./FormatFinderUITests/*" 2>/dev/null | sed 's|^./||'

echo ""
echo "Press Enter to open the project in Finder..."
read

open .