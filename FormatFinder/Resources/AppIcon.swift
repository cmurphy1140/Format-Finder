import SwiftUI
import CoreGraphics

struct BasicAppIconGenerator {
    static func generateIcon(size: CGFloat) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            
            // Background gradient
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = rect
            gradientLayer.colors = [
                UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1).cgColor,
                UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            
            // Draw background with rounded corners
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size * 0.18)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.clip()
            
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1).cgColor,
                    UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1).cgColor
                ] as CFArray,
                locations: [0, 1]
            ) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint.zero,
                    end: CGPoint(x: size, y: size),
                    options: []
                )
            }
            
            // Draw golf ball
            let centerX = size / 2
            let centerY = size * 0.45
            let ballRadius = size * 0.28
            
            // Ball shadow
            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
            context.cgContext.fillEllipse(in: CGRect(
                x: centerX - ballRadius + 2,
                y: centerY - ballRadius + 4,
                width: ballRadius * 2,
                height: ballRadius * 2
            ))
            
            // Ball
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(
                x: centerX - ballRadius,
                y: centerY - ballRadius,
                width: ballRadius * 2,
                height: ballRadius * 2
            ))
            
            // Dimples on ball
            context.cgContext.setFillColor(UIColor(white: 0.94, alpha: 1).cgColor)
            let dimpleSize = size * 0.015
            let dimpleSpacing = size * 0.04
            
            for angle in stride(from: 0, to: 360, by: 30) {
                for radius in stride(from: dimpleSpacing, to: ballRadius - dimpleSpacing, by: dimpleSpacing) {
                    let x = centerX + radius * cos(CGFloat(angle) * .pi / 180)
                    let y = centerY + radius * sin(CGFloat(angle) * .pi / 180)
                    
                    let distance = sqrt(pow(x - centerX, 2) + pow(y - centerY, 2))
                    if distance < ballRadius - dimpleSize * 2 {
                        context.cgContext.fillEllipse(in: CGRect(
                            x: x - dimpleSize,
                            y: y - dimpleSize,
                            width: dimpleSize * 2,
                            height: dimpleSize * 2
                        ))
                    }
                }
            }
            
            // Draw magnifying glass
            let glassRadius = size * 0.18
            let glassX = centerX + ballRadius * 0.45
            let glassY = centerY - ballRadius * 0.45
            
            // Glass lens
            context.cgContext.setStrokeColor(UIColor(red: 30/255, green: 100/255, blue: 30/255, alpha: 1).cgColor)
            context.cgContext.setLineWidth(size * 0.025)
            context.cgContext.strokeEllipse(in: CGRect(
                x: glassX - glassRadius,
                y: glassY - glassRadius,
                width: glassRadius * 2,
                height: glassRadius * 2
            ))
            
            // Glass fill
            context.cgContext.setFillColor(UIColor(white: 1, alpha: 0.1).cgColor)
            context.cgContext.fillEllipse(in: CGRect(
                x: glassX - glassRadius + size * 0.01,
                y: glassY - glassRadius + size * 0.01,
                width: (glassRadius - size * 0.01) * 2,
                height: (glassRadius - size * 0.01) * 2
            ))
            
            // Glass handle
            let handleStart = CGPoint(x: glassX + glassRadius * 0.7, y: glassY + glassRadius * 0.7)
            let handleEnd = CGPoint(x: glassX + glassRadius * 1.6, y: glassY + glassRadius * 1.6)
            
            context.cgContext.setStrokeColor(UIColor(red: 30/255, green: 100/255, blue: 30/255, alpha: 1).cgColor)
            context.cgContext.setLineWidth(size * 0.025)
            context.cgContext.move(to: handleStart)
            context.cgContext.addLine(to: handleEnd)
            context.cgContext.strokePath()
            
            // Add "F" lettermark for larger sizes
            if size >= 120 {
                let letterSize = size * 0.15
                let letterX = centerX
                let letterY = size * 0.75
                
                context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
                context.cgContext.setLineWidth(size * 0.02)
                
                // F vertical
                context.cgContext.move(to: CGPoint(x: letterX - letterSize/2, y: letterY - letterSize/2))
                context.cgContext.addLine(to: CGPoint(x: letterX - letterSize/2, y: letterY + letterSize/2))
                
                // F top horizontal
                context.cgContext.move(to: CGPoint(x: letterX - letterSize/2, y: letterY - letterSize/2))
                context.cgContext.addLine(to: CGPoint(x: letterX + letterSize/3, y: letterY - letterSize/2))
                
                // F middle horizontal
                context.cgContext.move(to: CGPoint(x: letterX - letterSize/2, y: letterY))
                context.cgContext.addLine(to: CGPoint(x: letterX + letterSize/4, y: letterY))
                
                context.cgContext.strokePath()
            }
        }
    }
}