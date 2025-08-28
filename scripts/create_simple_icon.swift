#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Create a simple 1024x1024 placeholder app icon
func createPlaceholderIcon(at path: String) {
    let size = 1024
    
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return }
    
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return }
    
    // Draw background gradient (golf green)
    let colors = [
        CGColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0),
        CGColor(red: 56/255, green: 142/255, blue: 60/255, alpha: 1.0)
    ]
    
    let locations: [CGFloat] = [0.0, 1.0]
    
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size, y: size),
            options: []
        )
    }
    
    // Draw a simple golf ball shape in center
    context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    let ballSize = CGFloat(size) * 0.4
    let ballRect = CGRect(
        x: (CGFloat(size) - ballSize) / 2,
        y: (CGFloat(size) - ballSize) / 2,
        width: ballSize,
        height: ballSize
    )
    context.fillEllipse(in: ballRect)
    
    // Add some dimples to the golf ball
    context.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
    let dimpleSize = ballSize * 0.05
    let dimpleSpacing = ballSize * 0.15
    
    for row in 0..<5 {
        for col in 0..<5 {
            let x = ballRect.minX + ballSize * 0.2 + CGFloat(col) * dimpleSpacing
            let y = ballRect.minY + ballSize * 0.2 + CGFloat(row) * dimpleSpacing
            
            if pow(x - ballRect.midX, 2) + pow(y - ballRect.midY, 2) < pow(ballSize * 0.45, 2) {
                let dimpleRect = CGRect(x: x, y: y, width: dimpleSize, height: dimpleSize)
                context.fillEllipse(in: dimpleRect)
            }
        }
    }
    
    // Save the image
    if let image = context.makeImage() {
        let url = URL(fileURLWithPath: path)
        if let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, image, nil)
            CGImageDestinationFinalize(destination)
            print("Created icon at: \(path)")
        }
    }
}

// Create icons for all variants
let basePath = "/Users/connormurphy/Desktop/Format Finder/FormatFinder/Assets.xcassets/AppIcon.appiconset/"

// Remove old files
let fileManager = FileManager.default
let oldFiles = [
    "Screenshot 2025-08-28 at 12.36.29 PM.png",
    "Screenshot 2025-08-28 at 12.36.29 PM 1.png",
    "Screenshot 2025-08-28 at 12.36.29 PM 2.png"
]

for file in oldFiles {
    try? fileManager.removeItem(atPath: basePath + file)
}

// Create new icon
createPlaceholderIcon(at: basePath + "AppIcon.png")

// Update Contents.json
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsPath = basePath + "Contents.json"
try? contentsJSON.write(toFile: contentsPath, atomically: true, encoding: .utf8)

print("AppIcon fixed successfully!")