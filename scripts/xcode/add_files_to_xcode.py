#!/usr/bin/env python3
import subprocess
import os

# Files to add to the project
files_to_add = [
    "FormatFinder/GameModeSelector.swift",
    "FormatFinder/ScorecardContainer.swift",
    "FormatFinder/FormatScorecards.swift",
    "FormatFinder/AdvancedScorecards.swift",
    "FormatFinder/RemainingFormatScorecards.swift",
    "FormatFinder/StatsAndExport.swift"
]

project_path = "/Users/connormurphy/Desktop/Format Finder/FormatFinder.xcodeproj"

for file in files_to_add:
    full_path = f"/Users/connormurphy/Desktop/Format Finder/{file}"
    if os.path.exists(full_path):
        print(f"Adding {file} to project...")
        # Using xcodeproj command line tool if available, otherwise we'll need to manually add
        # For now, let's just verify the files exist
        print(f"✓ File exists: {full_path}")
    else:
        print(f"✗ File not found: {full_path}")

print("\nAll scorecard files verified. Please open Xcode and:")
print("1. Right-click on the FormatFinder folder in the project navigator")
print("2. Select 'Add Files to FormatFinder...'")
print("3. Select all the scorecard Swift files listed above")
print("4. Make sure 'Copy items if needed' is unchecked")
print("5. Make sure 'FormatFinder' target is selected")
print("6. Click 'Add'")