import SwiftUI
import UIKit

// MARK: - Scroll Configuration
enum ScrollConfig {
    
    // MARK: - Layout Constants
    enum Layout {
        static let headerMaxHeight: CGFloat = 250
        static let headerMinHeight: CGFloat = 100
        static let headerCompressionRange: CGFloat = headerMaxHeight - headerMinHeight
        
        static let iconMaxSize: CGFloat = 80
        static let iconMinSize: CGFloat = 40
        
        static let sectionSpacing: CGFloat = 48
        static let contentPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 16
        
        static let safeAreaPadding: CGFloat = 20
    }
    
    // MARK: - Animation Configuration
    enum Animation {
        static let headerCompressionCurve = UnitCurve.easeInOut
        static let fadeOutThreshold: CGFloat = 50
        static let fadeInThreshold: CGFloat = 100
        
        static let defaultDuration: Double = 0.3
        static let longDuration: Double = 0.6
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.8
        
        static let parallaxMultiplier: CGFloat = 0.5
        static let blurMaxRadius: CGFloat = 20
    }
    
    // MARK: - Color Scheme (Dark Theme)
    enum Colors {
        static let background = Color(hex: "0A0E0A")  // Very dark green-black
        static let surface = Color(hex: "1A1F1A")     // Dark surface
        static let cardBackground = Color(hex: "141814") // Slightly lighter than background
        
        static let primaryText = Color(hex: "E8E8E8")   // Light gray text
        static let secondaryText = Color(hex: "A0A0A0") // Medium gray text
        static let tertiaryText = Color(hex: "707070")  // Darker gray
        
        static let accent = Color(hex: "2D5A2D")       // Dark green
        static let accentBorder = Color(hex: "1F3D1F") // Darker green for borders
        static let highlight = Color(hex: "4A7C4A")    // Brighter green for hover/active
        
        static let divider = Color.white.opacity(0.08)
        static let shadow = Color.black.opacity(0.5)
    }
    
    // MARK: - Scroll Thresholds
    enum Thresholds {
        static let taglineFadeStart: CGFloat = 20
        static let taglineFadeEnd: CGFloat = 50
        
        static let welcomeFadeStart: CGFloat = 80
        static let welcomeFadeEnd: CGFloat = 120
        
        static let sectionActivationOffset: CGFloat = -100
        static let parallaxMaxOffset: CGFloat = 100
        
        static let velocityThreshold: CGFloat = 2.0
    }
    
    // MARK: - Typography
    enum Typography {
        static let heroTitleSize: CGFloat = 42
        static let compressedTitleSize: CGFloat = 24
        
        static let sectionHeaderSize: CGFloat = 28
        static let bodyTextSize: CGFloat = 16
        static let captionSize: CGFloat = 14
        
        static let headerFont = Font.system(size: heroTitleSize, weight: .thin, design: .serif)
        static let sectionFont = Font.system(size: sectionHeaderSize, weight: .light, design: .default)
        static let bodyFont = Font.system(size: bodyTextSize, weight: .light, design: .default)
    }
}

// MARK: - Scroll State Model
struct ScrollState: Equatable {
    var offset: CGFloat = 0
    var velocity: CGFloat = 0
    var direction: ScrollDirection = .idle
    var progress: CGFloat = 0 // 0-1 normalized
    var headerProgress: CGFloat = 0 // 0-1 for header compression
    var isScrolling: Bool = false
    
    enum ScrollDirection {
        case up, down, idle
    }
    
    // Computed properties for common states
    var isHeaderCompressed: Bool {
        headerProgress >= 1.0
    }
    
    var isNearTop: Bool {
        offset < 50
    }
    
    var taglineOpacity: CGFloat {
        let fadeRange = ScrollConfig.Thresholds.taglineFadeEnd - ScrollConfig.Thresholds.taglineFadeStart
        let fadeProgress = (offset - ScrollConfig.Thresholds.taglineFadeStart) / fadeRange
        return 1.0 - min(max(fadeProgress, 0), 1)
    }
}

// MARK: - Section Anchor
struct SectionAnchor: Identifiable {
    let id = UUID()
    let name: String
    let offset: CGFloat
    var isActive: Bool = false
}

// MARK: - Easing Functions
extension ScrollConfig {
    static func easeInOutQuad(_ t: CGFloat) -> CGFloat {
        let clampedT = min(max(t, 0), 1)
        if clampedT < 0.5 {
            return 2 * clampedT * clampedT
        } else {
            return -1 + (4 - 2 * clampedT) * clampedT
        }
    }
    
    static func parallaxOffset(for scrollOffset: CGFloat) -> CGFloat {
        return scrollOffset * Animation.parallaxMultiplier
    }
    
    static func blurRadius(for headerProgress: CGFloat) -> CGFloat {
        return headerProgress * Animation.blurMaxRadius
    }
}