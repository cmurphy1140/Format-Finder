import SwiftUI
import UIKit

// MARK: - Accessibility Manager
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverRunning: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    @Published var prefersCrossFadeTransitions: Bool = false
    @Published var dynamicTypeSize: DynamicTypeSize = .large
    @Published var isHighContrastEnabled: Bool = false
    @Published var currentSection: String = ""
    
    init() {
        setupAccessibilityObservers()
        updateAccessibilityStatus()
    }
    
    private func setupAccessibilityObservers() {
        // VoiceOver
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        
        // Reduce Motion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        
        // Dynamic Type
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeCategoryChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
        
        // High Contrast
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(highContrastStatusChanged),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func voiceOverStatusChanged() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    }
    
    @objc private func reduceMotionStatusChanged() {
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        prefersCrossFadeTransitions = UIAccessibility.prefersCrossFadeTransitions
    }
    
    @objc private func contentSizeCategoryChanged() {
        updateDynamicTypeSize()
    }
    
    @objc private func highContrastStatusChanged() {
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    private func updateAccessibilityStatus() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        prefersCrossFadeTransitions = UIAccessibility.prefersCrossFadeTransitions
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        updateDynamicTypeSize()
    }
    
    private func updateDynamicTypeSize() {
        let category = UIApplication.shared.preferredContentSizeCategory
        dynamicTypeSize = DynamicTypeSize.from(category)
    }
    
    func announceSection(_ section: String) {
        guard isVoiceOverRunning else { return }
        
        currentSection = section
        let announcement = "Now viewing \(section) section"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(
                notification: .announcement,
                argument: announcement
            )
        }
    }
    
    func announceChange(_ message: String) {
        guard isVoiceOverRunning else { return }
        
        UIAccessibility.post(
            notification: .layoutChanged,
            argument: message
        )
    }
}

// MARK: - Dynamic Type Size
enum DynamicTypeSize {
    case xSmall, small, medium, large, xLarge, xxLarge, xxxLarge
    case accessibility1, accessibility2, accessibility3, accessibility4, accessibility5
    
    static func from(_ category: UIContentSizeCategory) -> DynamicTypeSize {
        switch category {
        case .extraSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .xLarge
        case .extraExtraLarge: return .xxLarge
        case .extraExtraExtraLarge: return .xxxLarge
        case .accessibilityMedium: return .accessibility1
        case .accessibilityLarge: return .accessibility2
        case .accessibilityExtraLarge: return .accessibility3
        case .accessibilityExtraExtraLarge: return .accessibility4
        case .accessibilityExtraExtraExtraLarge: return .accessibility5
        default: return .large
        }
    }
    
    var scaleFactor: CGFloat {
        switch self {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .xLarge: return 1.2
        case .xxLarge: return 1.3
        case .xxxLarge: return 1.4
        case .accessibility1: return 1.6
        case .accessibility2: return 1.8
        case .accessibility3: return 2.0
        case .accessibility4: return 2.3
        case .accessibility5: return 2.6
        }
    }
}

// MARK: - Responsive Layout Manager
struct ResponsiveLayout {
    enum DeviceType {
        case iPhone, iPadCompact, iPadRegular
        
        static var current: DeviceType {
            let idiom = UIDevice.current.userInterfaceIdiom
            let horizontalSize = UIScreen.main.bounds.width
            
            switch idiom {
            case .phone:
                return .iPhone
            case .pad:
                return horizontalSize < 768 ? .iPadCompact : .iPadRegular
            default:
                return .iPhone
            }
        }
    }
    
    enum Orientation {
        case portrait, landscape
        
        static var current: Orientation {
            UIDevice.current.orientation.isLandscape ? .landscape : .portrait
        }
    }
    
    static func columns(for device: DeviceType, orientation: Orientation) -> Int {
        switch (device, orientation) {
        case (.iPhone, .portrait): return 1
        case (.iPhone, .landscape): return 2
        case (.iPadCompact, _): return 2
        case (.iPadRegular, .portrait): return 3
        case (.iPadRegular, .landscape): return 4
        }
    }
    
    static func spacing(for device: DeviceType) -> CGFloat {
        switch device {
        case .iPhone: return 16
        case .iPadCompact: return 20
        case .iPadRegular: return 24
        }
    }
    
    static func padding(for device: DeviceType) -> EdgeInsets {
        switch device {
        case .iPhone:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .iPadCompact:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        case .iPadRegular:
            return EdgeInsets(top: 24, leading: 32, bottom: 24, trailing: 32)
        }
    }
}

// MARK: - Accessible Animation Modifier
struct AccessibleAnimation: ViewModifier {
    @StateObject private var accessibility = AccessibilityManager.shared
    let animation: Animation
    let reducedMotionAnimation: Animation
    
    init(
        animation: Animation = .spring(),
        reducedMotion: Animation = .easeInOut(duration: 0.1)
    ) {
        self.animation = animation
        self.reducedMotionAnimation = reducedMotion
    }
    
    func body(content: Content) -> some View {
        content
            .animation(
                accessibility.isReduceMotionEnabled ? reducedMotionAnimation : animation,
                value: UUID()
            )
    }
}

// MARK: - VoiceOver Announcer
struct VoiceOverAnnouncer: ViewModifier {
    let message: String
    let trigger: Bool
    @StateObject private var accessibility = AccessibilityManager.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, newValue in
                if newValue && accessibility.isVoiceOverRunning {
                    accessibility.announceChange(message)
                }
            }
    }
}

// MARK: - Keyboard Navigation Support
struct KeyboardNavigatable: ViewModifier {
    @FocusState private var isFocused: Bool
    let onEnter: () -> Void
    let onEscape: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .focusable()
            .focused($isFocused)
            .onKeyPress(.return) {
                onEnter()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
            .onKeyPress(.tab) {
                // Tab navigation handled by system
                return .ignored
            }
    }
}

// MARK: - Responsive Grid View
struct ResponsiveGridView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    @State private var deviceType = ResponsiveLayout.DeviceType.current
    @State private var orientation = ResponsiveLayout.Orientation.current
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var columns: [GridItem] {
        let count = ResponsiveLayout.columns(for: deviceType, orientation: orientation)
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
    
    var spacing: CGFloat {
        ResponsiveLayout.spacing(for: deviceType)
    }
    
    var padding: EdgeInsets {
        ResponsiveLayout.padding(for: deviceType)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(items) { item in
                    content(item)
                }
            }
            .padding(padding)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            updateLayout()
        }
        .onAppear {
            updateLayout()
        }
    }
    
    private func updateLayout() {
        deviceType = ResponsiveLayout.DeviceType.current
        orientation = ResponsiveLayout.Orientation.current
    }
}

// MARK: - High Contrast Border
struct HighContrastBorder: ViewModifier {
    @StateObject private var accessibility = AccessibilityManager.shared
    let color: Color
    let width: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        accessibility.isHighContrastEnabled ? color : Color.clear,
                        lineWidth: accessibility.isHighContrastEnabled ? width : 0
                    )
            )
    }
}

// MARK: - Extension Methods
extension View {
    func accessibleAnimation(
        _ animation: Animation = .spring(),
        reducedMotion: Animation = .easeInOut(duration: 0.1)
    ) -> some View {
        modifier(AccessibleAnimation(animation: animation, reducedMotion: reducedMotion))
    }
    
    func announceOnChange(of trigger: Bool, message: String) -> some View {
        modifier(VoiceOverAnnouncer(message: message, trigger: trigger))
    }
    
    func keyboardNavigatable(
        onEnter: @escaping () -> Void,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardNavigatable(onEnter: onEnter, onEscape: onEscape))
    }
    
    func highContrastBorder(color: Color = .primary, width: CGFloat = 2) -> some View {
        modifier(HighContrastBorder(color: color, width: width))
    }
}

// MARK: - Dynamic Type Scaling
struct DynamicTypeScaling: ViewModifier {
    @StateObject private var accessibility = AccessibilityManager.shared
    let baseSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: baseSize * accessibility.dynamicTypeSize.scaleFactor))
    }
}

extension View {
    func dynamicTypeScaling(baseSize: CGFloat) -> some View {
        modifier(DynamicTypeScaling(baseSize: baseSize))
    }
}