import UIKit
import CoreHaptics

// MARK: - Haptic Manager
/// Centralized haptic feedback manager with intelligent patterns
public final class HapticManager {
    
    // MARK: - Properties
    private static var engine: CHHapticEngine?
    private static var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    // MARK: - Initialization
    public static func prepare() {
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }
    
    // MARK: - Basic Haptic Patterns
    
    /// Light impact feedback
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard supportsHaptics else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Selection feedback
    public static func selection() {
        guard supportsHaptics else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// Notification feedback
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard supportsHaptics else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Golf-Specific Haptic Patterns
    
    /// Score entry haptic feedback
    public static func scoreEntry(type: ScoreType, par: Int) {
        guard supportsHaptics else { return }
        
        switch type {
        case .ace, .albatross:
            // Special achievement - strong celebration
            complexCelebration(intensity: 1.0)
        case .eagle:
            // Great shot - medium celebration
            complexCelebration(intensity: 0.8)
        case .birdie:
            // Good shot - light celebration
            notification(.success)
        case .par:
            // Standard - medium tap
            impact(.medium)
        case .bogey:
            // Over par - light warning
            impact(.light)
        case .doubleBogey, .other:
            // Well over par - soft warning
            notification(.warning)
        }
    }
    
    /// Score increment haptic pattern
    public static func scoreIncrement(currentScore: Int, par: Int) {
        guard supportsHaptics else { return }
        
        if currentScore == par {
            // Reaching par - stronger feedback
            impact(.medium)
        } else if currentScore < par {
            // Under par - positive light tap
            impact(.light)
        } else {
            // Over par - softer tap
            impact(.soft)
        }
    }
    
    /// Hole navigation haptic
    public static func holeNavigation(direction: NavigationDirection) {
        guard supportsHaptics else { return }
        
        switch direction {
        case .next:
            // Forward navigation - light tap
            impact(.light)
        case .previous:
            // Backward navigation - slightly stronger
            impact(.medium)
        case .jump:
            // Jump to specific hole - selection feedback
            selection()
        }
    }
    
    /// Achievement unlock haptic
    public static func achievementUnlocked(level: AchievementLevel) {
        guard supportsHaptics else { return }
        
        switch level {
        case .bronze:
            notification(.success)
        case .silver:
            complexCelebration(intensity: 0.6)
        case .gold:
            complexCelebration(intensity: 1.0)
        }
    }
    
    // MARK: - Complex Haptic Patterns
    
    /// Complex celebration pattern for special scores
    private static func complexCelebration(intensity: Float) {
        guard supportsHaptics, let engine = engine else {
            // Fallback to simple notification
            notification(.success)
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Create a series of taps with decreasing intensity
            let initialIntensity = intensity
            let sharpness: Float = 0.5
            
            // First strong tap
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: initialIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            ))
            
            // Follow-up taps with decreasing intensity
            for i in 1...3 {
                let time = TimeInterval(i) * 0.1
                let tapIntensity = initialIntensity * (1 - Float(i) * 0.25)
                
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: tapIntensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness * 0.8)
                    ],
                    relativeTime: time
                ))
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fallback to simple notification
            notification(.success)
        }
    }
    
    /// Rhythmic pattern for score counting
    public static func countingPattern(count: Int) {
        guard supportsHaptics, let engine = engine, count > 0 else { return }
        
        do {
            var events: [CHHapticEvent] = []
            
            for i in 0..<count {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: TimeInterval(i) * 0.15
                ))
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fallback to simple taps
            for _ in 0..<count {
                impact(.light)
                Thread.sleep(forTimeInterval: 0.15)
            }
        }
    }
    
    // MARK: - Accessibility Support
    
    /// Check if haptics are enabled in accessibility settings
    public static func hapticsEnabled() -> Bool {
        // Check system settings and user preferences
        guard supportsHaptics else { return false }
        
        // Check if reduce motion is enabled (some users may want haptics off)
        if UIAccessibility.isReduceMotionEnabled {
            // Could check user preference here
            return UserDefaults.standard.bool(forKey: "hapticsEnabledWithReduceMotion")
        }
        
        return true
    }
    
    /// Configure haptic intensity based on user preferences
    public static func configureIntensity(_ level: HapticIntensityLevel) {
        UserDefaults.standard.set(level.rawValue, forKey: "hapticIntensityLevel")
    }
}

// MARK: - Supporting Types

public enum NavigationDirection {
    case next
    case previous
    case jump
}

public enum AchievementLevel {
    case bronze
    case silver
    case gold
}

public enum HapticIntensityLevel: String {
    case light = "light"
    case medium = "medium"
    case strong = "strong"
    case disabled = "disabled"
    
    var multiplier: Float {
        switch self {
        case .light: return 0.5
        case .medium: return 0.75
        case .strong: return 1.0
        case .disabled: return 0.0
        }
    }
}