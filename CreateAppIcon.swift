#!/usr/bin/swift
import Foundation
import CoreGraphics
import AppKit

// Function to create an app icon
func createAppIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    // Background gradient
    let context = NSGraphicsContext.current?.cgContext
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor(red: 46/255, green: 125/255, blue: 50/255, alpha: 1).cgColor,
        NSColor(red: 102/255, green: 187/255, blue: 106/255, alpha: 1).cgColor
    ] as CFArray
    
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil) {
        context?.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size, y: size),
            options: []
        )
    }
    
    // Golf green circle
    let greenPath = NSBezierPath(ovalIn: NSRect(
        x: size/2 - size*0.35,
        y: size/2 - size*0.35,
        width: size*0.7,
        height: size*0.7
    ))
    NSColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 0.8).setFill()
    greenPath.fill()
    
    // Hole
    let holePath = NSBezierPath(ovalIn: NSRect(
        x: size/2 - size*0.04,
        y: size/2 - size*0.08 - size*0.04,
        width: size*0.08,
        height: size*0.08
    ))
    NSColor.black.setFill()
    holePath.fill()
    
    // Flag pole
    let polePath = NSBezierPath(rect: NSRect(
        x: size/2 - 2,
        y: size/2 - size*0.25,
        width: 4,
        height: size*0.3
    ))
    NSColor.white.setFill()
    polePath.fill()
    
    // Flag
    let flagPath = NSBezierPath()
    flagPath.move(to: NSPoint(x: size/2 + 2, y: size/2 - size*0.25))
    flagPath.line(to: NSPoint(x: size/2 + size*0.1, y: size/2 - size*0.21))
    flagPath.line(to: NSPoint(x: size/2 + 2, y: size/2 - size*0.17))
    flagPath.close()
    NSColor.red.setFill()
    flagPath.fill()
    
    // Add FF text for larger icons
    if size >= 256 {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.15, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let text = "FF"
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: size/2 - textSize.width/2,
            y: size*0.15,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
    }
    
    image.unlockFocus()
    return image
}

// Create all required icon sizes
let iconSizes = [
    20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024
]

let outputDir = "FormatFinder/Assets.xcassets/AppIcon.appiconset/"

// Create directory if it doesn't exist
try? FileManager.default.createDirectory(
    atPath: outputDir,
    withIntermediateDirectories: true,
    attributes: nil
)

// Generate icons
for size in iconSizes {
    let icon = createAppIcon(size: size)
    if let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        if let data = bitmap.representation(using: .png, properties: [:]) {
            let filename = "\(outputDir)icon-\(size).png"
            try? data.write(to: URL(fileURLWithPath: filename))
            print("Created \(filename)")
        }
    }
}

// Create Contents.json
let contentsJSON = """
{
  "images" : [
    {
      "filename" : "icon-40.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-60.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-58.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-87.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-80.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-120.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-120.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-180.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-20.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-40.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-29.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-58.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-40.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-80.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "icon-152.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "icon-167.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

try? contentsJSON.write(
    to: URL(fileURLWithPath: "\(outputDir)Contents.json"),
    atomically: true,
    encoding: .utf8
)

print("Created Contents.json")
print("App icons generated successfully!")