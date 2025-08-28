#!/usr/bin/env python3
import re

# Read the file
with open('FormatFinder/Features/Formats/IntuitiveDemonstration.swift', 'r') as f:
    content = f.read()

# Pattern to find Indicator with text before color
pattern = r'Indicator\(type: \.text, position: ([^,]+), text: ([^,]+), color: ([^\)]+)\)'
replacement = r'Indicator(type: .text, position: \1, color: \3, text: \2)'

# Replace all occurrences
content = re.sub(pattern, replacement, content)

# Write back
with open('FormatFinder/Features/Formats/IntuitiveDemonstration.swift', 'w') as f:
    f.write(content)

print("Fixed all Indicator parameter orders")