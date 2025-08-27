#!/bin/bash

# Build the app
echo "Building Format Finder..."
xcodebuild -project FormatFinder.xcodeproj \
           -scheme FormatFinder \
           -sdk iphonesimulator \
           -configuration Debug \
           -derivedDataPath ./build \
           build

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build succeeded!"
echo ""
echo "To run the app:"
echo "1. Open Xcode: open FormatFinder.xcodeproj"
echo "2. Select any iPhone simulator from the device menu"
echo "3. Press Cmd+R or click the Play button"
echo ""
echo "The app is ready to run with these features:"
echo "- 4 golf formats (Scramble, Best Ball, Skins, Nassau)"
echo "- Search and filter functionality"
echo "- Detailed format explanations"
echo "- Bookmark system"
echo "- Clean green golf theme"