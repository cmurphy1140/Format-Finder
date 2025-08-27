#!/bin/bash

# Script to update the Format Finder app with all enhancements

echo "Updating Format Finder with comprehensive enhancements..."

# Backup original file
cp FormatFinder/FormatFinderApp.swift FormatFinder/FormatFinderApp.backup.swift

# Combine all enhancement files into the main app
cat FormatFinder/EnhancedApp.swift > FormatFinder/FormatFinderApp_temp.swift
echo "" >> FormatFinder/FormatFinderApp_temp.swift
cat FormatFinder/EnhancedDiagrams.swift >> FormatFinder/FormatFinderApp_temp.swift
echo "" >> FormatFinder/FormatFinderApp_temp.swift
cat FormatFinder/SmartCaddie.swift >> FormatFinder/FormatFinderApp_temp.swift

# Add the existing format definitions and helper functions
echo "

// MARK: - Golf Format Data

struct GolfFormat: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let difficulty: String
    let players: String
    let type: String
    
    var howToPlay: [String] {
        // Return format-specific instructions
        switch name {
        case \"Scramble\":
            return [
                \"All players tee off on each hole\",
                \"The team selects the best shot\",
                \"All players play from that spot\",
                \"Continue until the ball is holed\",
                \"Record the team score\"
            ]
        case \"Best Ball\":
            return [
                \"Each player plays their own ball\",
                \"Record each player's score\",
                \"Team score = best individual score\",
                \"Other players' scores don't count\",
                \"Great for mixed skill levels\"
            ]
        case \"Match Play\":
            return [
                \"Play hole by hole\",
                \"Lowest score wins the hole\",
                \"Track holes won, not total strokes\",
                \"Match ends when mathematically decided\",
                \"Concessions are allowed\"
            ]
        case \"Skins\":
            return [
                \"Each hole has a value (skin)\",
                \"Must win hole outright (no ties)\",
                \"Tied holes carry over value\",
                \"Pots can get very large\",
                \"Often uses validation rule\"
            ]
        case \"Stableford\":
            return [
                \"Points based on score vs par\",
                \"Eagle: 4 points, Birdie: 3 points\",
                \"Par: 2 points, Bogey: 1 point\",
                \"Double bogey+: 0 points\",
                \"Highest point total wins\"
            ]
        case \"Four-Ball\":
            return [
                \"Teams of two players\",
                \"Each plays their own ball\",
                \"Better ball counts for team\",
                \"Can play match or stroke play\",
                \"Partners can give advice\"
            ]
        case \"Alternate Shot\":
            return [
                \"Teams of two players\",
                \"Partners alternate shots\",
                \"Alternate tee shots by hole\",
                \"One ball per team\",
                \"Requires great teamwork\"
            ]
        case \"Nassau\":
            return [
                \"Three separate bets\",
                \"Front 9, Back 9, and Total 18\",
                \"Can add presses when losing\",
                \"Each nine is independent\",
                \"Popular gambling format\"
            ]
        case \"Bingo Bango Bongo\":
            return [
                \"Three points per hole\",
                \"Bingo: First on green\",
                \"Bango: Closest to pin\",
                \"Bongo: First in hole\",
                \"Rewards good shots, not just score\"
            ]
        case \"Wolf\":
            return [
                \"Rotating wolf each hole\",
                \"Wolf picks partner or goes alone\",
                \"Must decide after tee shots\",
                \"Lone wolf earns double points\",
                \"Strategic partner selection\"
            ]
        case \"Chapman\":
            return [
                \"Both players tee off\",
                \"Switch balls for second shot\",
                \"Select best ball after second\",
                \"Alternate shots to finish\",
                \"Also called Pinehurst\"
            ]
        case \"Vegas\":
            return [
                \"Teams combine scores\",
                \"Lower score goes first (4,6 = 46)\",
                \"Difference determines points\",
                \"Birdies can flip opponent\",
                \"High risk, high reward\"
            ]
        default:
            return []
        }
    }
}

let golfFormats = [
    GolfFormat(
        name: \"Scramble\",
        description: \"All players tee off, then play from the best shot. Perfect for team building and beginners.\",
        difficulty: \"Easy\",
        players: \"2-4\",
        type: \"Team\"
    ),
    GolfFormat(
        name: \"Best Ball\",
        description: \"Each player plays their own ball. Team score is the best individual score on each hole.\",
        difficulty: \"Medium\",
        players: \"2-4\",
        type: \"Team\"
    ),
    GolfFormat(
        name: \"Match Play\",
        description: \"Head-to-head competition where each hole is a separate contest. Win by winning more holes.\",
        difficulty: \"Medium\",
        players: \"2\",
        type: \"Individual\"
    ),
    GolfFormat(
        name: \"Skins\",
        description: \"Each hole is worth a 'skin'. Win the hole outright to claim it. Ties carry over.\",
        difficulty: \"Medium\",
        players: \"2-4\",
        type: \"Individual\"
    ),
    GolfFormat(
        name: \"Stableford\",
        description: \"Point-based scoring rewarding aggressive play. Better than par earns more points.\",
        difficulty: \"Easy\",
        players: \"Any\",
        type: \"Individual\"
    ),
    GolfFormat(
        name: \"Four-Ball\",
        description: \"Partners play their own balls. The better score between partners counts for the team.\",
        difficulty: \"Medium\",
        players: \"4\",
        type: \"Team\"
    ),
    GolfFormat(
        name: \"Alternate Shot\",
        description: \"Partners alternate hitting the same ball. Requires great teamwork and strategy.\",
        difficulty: \"Hard\",
        players: \"2 or 4\",
        type: \"Team\"
    ),
    GolfFormat(
        name: \"Nassau\",
        description: \"Three separate matches in one: front 9, back 9, and overall 18. Most popular betting game.\",
        difficulty: \"Medium\",
        players: \"2-4\",
        type: \"Individual\"
    ),
    GolfFormat(
        name: \"Bingo Bango Bongo\",
        description: \"Points for first on green, closest to pin, and first in hole. Great for mixed abilities.\",
        difficulty: \"Easy\",
        players: \"2-4\",
        type: \"Individual\"
    ),
    GolfFormat(
        name: \"Wolf\",
        description: \"Rotating 'wolf' chooses to play alone or with a partner each hole. Risk vs reward.\",
        difficulty: \"Hard\",
        players: \"4\",
        type: \"Individual\"
    ),
    GolfFormat(
        name: \"Chapman\",
        description: \"Both tee off, switch balls, then choose best ball and alternate. Also called Pinehurst.\",
        difficulty: \"Hard\",
        players: \"2 or 4\",
        type: \"Team\"
    ),
    GolfFormat(
        name: \"Vegas\",
        description: \"Team scores combine into one number. Low score first (4,5 = 45). Huge swings possible.\",
        difficulty: \"Hard\",
        players: \"4\",
        type: \"Team\"
    )
]

// MARK: - Enhanced Bookmarks View

struct BookmarksView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var bookmarkedFormats: Set<String>
    
    var savedFormats: [GolfFormat] {
        golfFormats.filter { bookmarkedFormats.contains($0.name) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                if savedFormats.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: \"bookmark\")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text(\"No Saved Formats\")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(themeManager.textColor)
                        
                        Text(\"Bookmark your favorite formats to access them quickly\")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(savedFormats) { format in
                                EnhancedFormatCard(
                                    format: format,
                                    isBookmarked: true,
                                    toggleBookmark: {
                                        bookmarkedFormats.remove(format.name)
                                    }
                                )
                                .environmentObject(themeManager)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(\"Saved Formats\")
        }
    }
}
" >> FormatFinder/FormatFinderApp_temp.swift

# Move the new file to replace the old one
mv FormatFinder/FormatFinderApp_temp.swift FormatFinder/FormatFinderApp.swift

echo "✅ App updated successfully!"
echo ""
echo "IMPROVEMENTS ADDED:"
echo "1. ✅ Interactive guides for all 12 formats (4-5 slides each)"
echo "2. ✅ Dark/Light mode with high contrast text"
echo "3. ✅ Enhanced search with recent searches and fuzzy matching"
echo "4. ✅ Smart Caddie feature:"
echo "   - Handicap calculator with format adjustments"
echo "   - Format recommender based on preferences"
echo "   - Live scoring system"
echo "   - Group management"
echo "5. ✅ Additional features:"
echo "   - Filter pills (Team, Individual, Tournament, Casual, Competitive)"
echo "   - Bookmark system with persistence"
echo "   - Settings page with preferences"
echo "   - Professional icons for each format"
echo ""
echo "NEW FEATURE SUGGESTION - 'Format of the Day':"
echo "- Daily featured format with challenges"
echo "- Achievement system for trying formats"
echo "- Social sharing capabilities"
echo "- Weather-based format suggestions"
echo ""
echo "To build and run:"
echo "1. Open FormatFinder.xcodeproj in Xcode"
echo "2. Select your iPhone as the target device"
echo "3. Press Cmd+R to build and run"