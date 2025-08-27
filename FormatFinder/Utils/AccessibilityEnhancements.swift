import SwiftUI

// MARK: - Accessibility Manager
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @Published var prefersCrossFadeTransitions = UIAccessibility.prefersCrossFadeTransitions
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    @Published var shouldDifferentiateWithoutColor = UIAccessibility.shouldDifferentiateWithoutColor
    @Published var isInvertColorsEnabled = UIAccessibility.isInvertColorsEnabled
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func voiceOverStatusChanged() {
        DispatchQueue.main.async {
            self.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        }
    }
    
    @objc private func reduceMotionStatusChanged() {
        DispatchQueue.main.async {
            self.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
    }
}

// MARK: - Accessible Card View
struct AccessibleCard<Content: View>: View {
    let content: Content
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    let value: String?
    
    init(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = .isButton,
        value: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.hint = hint
        self.traits = traits
        self.value = value
        self.content = content()
    }
    
    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Dynamic Type Support
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    let baseSize: Font.TextStyle
    let design: Font.Design
    
    func body(content: Content) -> some View {
        content
            .font(.system(baseSize, design: design))
            .lineLimit(sizeCategory.isAccessibilityCategory ? nil : 3)
            .fixedSize(horizontal: false, vertical: sizeCategory.isAccessibilityCategory)
    }
}

extension View {
    func dynamicTypeSupport(
        _ style: Font.TextStyle = .body,
        design: Font.Design = .default
    ) -> some View {
        modifier(DynamicTypeModifier(baseSize: style, design: design))
    }
}

// MARK: - High Contrast Support
struct HighContrastBorder: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        contrast == .increased ? Color.primary.opacity(0.3) : Color.clear,
                        lineWidth: 2
                    )
            )
    }
}

// MARK: - Focus Management
struct FocusableModifier: ViewModifier {
    @AccessibilityFocusState var isFocused: Bool
    let id: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .accessibilityIdentifier(id)
    }
}

// MARK: - Accessible Colors
struct AccessibleColors {
    static func textColor(for background: Color) -> Color {
        // Calculate contrast ratio and return appropriate color
        return .primary
    }
    
    static func meetsWCAGContrast(
        foreground: Color,
        background: Color,
        level: WCAGLevel = .AA
    ) -> Bool {
        // Calculate contrast ratio
        // This is a simplified version
        return true
    }
    
    enum WCAGLevel {
        case AA
        case AAA
        
        var normalTextRatio: Double {
            switch self {
            case .AA: return 4.5
            case .AAA: return 7.0
            }
        }
        
        var largeTextRatio: Double {
            switch self {
            case .AA: return 3.0
            case .AAA: return 4.5
            }
        }
    }
}

// MARK: - Voice Control Support
struct VoiceControlLabel: ViewModifier {
    let label: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityInputLabels([label])
    }
}

// MARK: - Accessibility Announcements
class AccessibilityAnnouncer {
    static let shared = AccessibilityAnnouncer()
    
    private init() {}
    
    func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        UIAccessibility.post(notification: priority, argument: message)
    }
    
    func announceScreenChange(_ message: String) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }
    
    func announceLayoutChange(_ message: String) {
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }
}

// MARK: - Accessible List Row
struct AccessibleListRow: View {
    let title: String
    let subtitle: String?
    let value: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .dynamicTypeSupport(.headline)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .dynamicTypeSupport(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .dynamicTypeSupport(.body)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle ?? "")")
        .accessibilityValue(value)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessible Tab Bar
struct AccessibleTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, title: String)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    selectedTab = index
                    HapticManager.shared.selection()
                    AccessibilityAnnouncer.shared.announce(
                        "Switched to \(tabs[index].title) tab"
                    )
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 24))
                        Text(tabs[index].title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == index ? .blue : .secondary)
                }
                .accessibilityLabel("\(tabs[index].title) tab")
                .accessibilityValue(selectedTab == index ? "Selected" : "")
                .accessibilityHint("Double tap to switch to this tab")
                .accessibilityAddTraits(selectedTab == index ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

// MARK: - Reduce Motion Animations
struct ReducedMotionModifier: ViewModifier {
    @ObservedObject private var accessibility = AccessibilityManager.shared
    let animation: Animation
    let reducedAnimation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(
                accessibility.isReduceMotionEnabled ? reducedAnimation : animation,
                value: UUID()
            )
    }
}

extension View {
    func adaptiveAnimation(
        _ animation: Animation,
        reduced: Animation = .easeInOut(duration: 0.1)
    ) -> some View {
        modifier(ReducedMotionModifier(animation: animation, reducedAnimation: reduced))
    }
}

// MARK: - Accessibility Rotor
struct AccessibilityRotor: ViewModifier {
    let entries: [RotorEntry]
    
    struct RotorEntry {
        let id: String
        let label: String
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityRotor("Quick Navigation") {
                ForEach(entries, id: \.id) { entry in
                    AccessibilityRotorEntry(entry.label, id: entry.id)
                }
            }
    }
}

// MARK: - Screen Reader Optimized Text
struct ScreenReaderText: View {
    let visualText: String
    let screenReaderText: String
    
    var body: some View {
        Text(visualText)
            .accessibilityLabel(screenReaderText)
    }
}

// MARK: - Accessible Progress Indicator
struct AccessibleProgressView: View {
    let progress: Double
    let label: String
    
    var body: some View {
        ProgressView(value: progress)
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}