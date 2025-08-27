import SwiftUI
import UIKit

// This file generates the app icon as an image
struct AppIconGenerator {
    
    static func generateIcon(size: CGFloat) -> UIImage {
        let view = AppIconView(size: size)
        
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: size, height: size)
        controller.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let image = renderer.image { context in
            controller.view.layer.render(in: context.cgContext)
        }
        
        return image
    }
    
    static func saveIconToAssets() {
        // Generate all required sizes
        let sizes: [(name: String, size: CGFloat)] = [
            ("AppIcon-20@2x", 40),
            ("AppIcon-20@3x", 60),
            ("AppIcon-29@2x", 58),
            ("AppIcon-29@3x", 87),
            ("AppIcon-40@2x", 80),
            ("AppIcon-40@3x", 120),
            ("AppIcon-60@2x", 120),
            ("AppIcon-60@3x", 180),
            ("AppIcon-1024", 1024)
        ]
        
        for iconSize in sizes {
            let image = generateIcon(size: iconSize.size)
            // In a real implementation, you would save this to the file system
            print("Generated icon: \(iconSize.name) at \(iconSize.size)x\(iconSize.size)")
        }
    }
}