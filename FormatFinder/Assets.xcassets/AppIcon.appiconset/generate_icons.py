#!/usr/bin/env python3
import json
import os

# Create a simple Contents.json for the app icons
# The actual PNG files will need to be generated separately

icon_sizes = [
    {"size": "20x20", "idiom": "iphone", "scale": "2x", "filename": "icon-40.png"},
    {"size": "20x20", "idiom": "iphone", "scale": "3x", "filename": "icon-60.png"},
    {"size": "29x29", "idiom": "iphone", "scale": "2x", "filename": "icon-58.png"},
    {"size": "29x29", "idiom": "iphone", "scale": "3x", "filename": "icon-87.png"},
    {"size": "40x40", "idiom": "iphone", "scale": "2x", "filename": "icon-80.png"},
    {"size": "40x40", "idiom": "iphone", "scale": "3x", "filename": "icon-120.png"},
    {"size": "60x60", "idiom": "iphone", "scale": "2x", "filename": "icon-120-1.png"},
    {"size": "60x60", "idiom": "iphone", "scale": "3x", "filename": "icon-180.png"},
    {"size": "20x20", "idiom": "ipad", "scale": "1x", "filename": "icon-20.png"},
    {"size": "20x20", "idiom": "ipad", "scale": "2x", "filename": "icon-40-1.png"},
    {"size": "29x29", "idiom": "ipad", "scale": "1x", "filename": "icon-29.png"},
    {"size": "29x29", "idiom": "ipad", "scale": "2x", "filename": "icon-58-1.png"},
    {"size": "40x40", "idiom": "ipad", "scale": "1x", "filename": "icon-40-2.png"},
    {"size": "40x40", "idiom": "ipad", "scale": "2x", "filename": "icon-80-1.png"},
    {"size": "76x76", "idiom": "ipad", "scale": "1x", "filename": "icon-76.png"},
    {"size": "76x76", "idiom": "ipad", "scale": "2x", "filename": "icon-152.png"},
    {"size": "83.5x83.5", "idiom": "ipad", "scale": "2x", "filename": "icon-167.png"},
    {"size": "1024x1024", "idiom": "ios-marketing", "scale": "1x", "filename": "icon-1024.png"}
]

contents = {
    "images": icon_sizes,
    "info": {
        "author": "xcode",
        "version": 1
    }
}

# Write Contents.json
with open("Contents.json", "w") as f:
    json.dump(contents, f, indent=2)

print("Created Contents.json")
print("Now you need to generate PNG files at these sizes:")
for icon in icon_sizes:
    size_parts = icon["size"].split("x")
    scale = int(icon["scale"].replace("x", ""))
    actual_size = int(float(size_parts[0]) * scale)
    print(f"  {icon['filename']}: {actual_size}x{actual_size}px")