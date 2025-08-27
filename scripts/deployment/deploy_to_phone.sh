#!/bin/bash

echo "======================================"
echo "   Format Finder - Deploy to iPhone   "
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if iPhone is connected
echo -e "${BLUE}Checking for connected devices...${NC}"
DEVICE_INFO=$(xcrun devicectl list devices | grep -i "connor\|iphone" | grep "connected")

if [ -z "$DEVICE_INFO" ]; then
    echo -e "${RED}Error: No iPhone connected. Please connect your iPhone and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found device: $(echo $DEVICE_INFO | cut -d' ' -f1-2)${NC}"
echo ""

# Clean build folder
echo -e "${BLUE}Cleaning build folder...${NC}"
xcodebuild -project FormatFinder.xcodeproj -scheme FormatFinder clean -quiet

# Build for device
echo -e "${BLUE}Building app for iPhone...${NC}"
xcodebuild -project FormatFinder.xcodeproj \
    -scheme FormatFinder \
    -configuration Debug \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build \
    build 2>&1 | grep -E "^\*\*|error:" || true

# Check if build succeeded
if [ -d "build/Build/Products/Debug-iphoneos/FormatFinder.app" ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo ""
    
    # Open in Xcode for deployment
    echo -e "${BLUE}Opening in Xcode for deployment...${NC}"
    open FormatFinder.xcodeproj
    
    echo ""
    echo -e "${GREEN}======================================"
    echo "   READY TO DEPLOY!"
    echo "======================================"
    echo ""
    echo "In Xcode:"
    echo "1. Select your iPhone from the device dropdown (top toolbar)"
    echo "2. Click the Run button (▶️) or press Cmd+R"
    echo ""
    echo "The app will install and launch on your phone!"
    echo ""
    
else
    echo -e "${RED}✗ Build failed. Please check the errors above.${NC}"
    exit 1
fi