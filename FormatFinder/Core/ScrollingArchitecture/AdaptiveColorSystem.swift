import SwiftUI
import UIKit

// MARK: - Adaptive Color System
class AdaptiveColorSystem: ObservableObject {
    static let shared = AdaptiveColorSystem()
    
    @Published var currentTheme: ColorTheme = .forest
    @Published var backgroundGradient: LinearGradient
    @Published var textColor: Color = .white
    @Published var navigationTint: Color = .white
    @Published var isDarkMode: Bool = false
    @Published var isHighContrast: Bool = false
    
    // Color definitions
    private let forestGreen = Color(red: 0.11, green: 0.26, blue: 0.20) // #1B4332
    private let mintGreen = Color(red: 0.25, green: 0.57, blue: 0.42) // #40916C
    
    // Stored user preference
    @AppStorage("selectedTheme") private var storedTheme: String = "forest"
    @AppStorage("useSystemTheme") private var useSystemTheme: Bool = true
    
    enum ColorTheme: String, CaseIterable {
        case forest = "forest"
        case mint = "mint"
        case ocean = "ocean"
        case sunset = "sunset"
        case midnight = "midnight"
        
        var colors: (primary: Color, secondary: Color) {
            switch self {
            case .forest:
                return (Color(red: 0.11, green: 0.26, blue: 0.20),
                       Color(red: 0.25, green: 0.57, blue: 0.42))
            case .mint:
                return (Color(red: 0.25, green: 0.57, blue: 0.42),
                       Color(red: 0.50, green: 0.75, blue: 0.60))
            case .ocean:
                return (Color(red: 0.00, green: 0.40, blue: 0.60),
                       Color(red: 0.00, green: 0.60, blue: 0.80))
            case .sunset:
                return (Color(red: 0.95, green: 0.40, blue: 0.30),
                       Color(red: 1.00, green: 0.60, blue: 0.40))
            case .midnight:
                return (Color(red: 0.10, green: 0.10, blue: 0.20),
                       Color(red: 0.20, green: 0.20, blue: 0.40))
            }
        }
    }
    
    init() {
        // Load stored theme
        if let stored = ColorTheme(rawValue: storedTheme) {
            currentTheme = stored
        }
        
        // Initialize gradient
        let colors = currentTheme.colors
        backgroundGradient = LinearGradient(
            colors: [colors.primary, colors.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Setup observers
        setupColorSchemeObserver()
        setupAccessibilityObserver()
        
        // Initial contrast calculation
        updateTextColorForContrast()
    }
    
    private func setupColorSchemeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(colorSchemeChanged),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
    }
    
    private func setupAccessibilityObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityChanged),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func colorSchemeChanged() {
        isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        if useSystemTheme {
            adaptToSystemTheme()
        }
    }
    
    @objc private func accessibilityChanged() {
        isHighContrast = UIAccessibility.isDarkerSystemColorsEnabled
        updateTextColorForContrast()
    }
    
    func transitionToTheme(_ theme: ColorTheme, duration: Double = 0.3) {
        withAnimation(.easeInOut(duration: duration)) {
            currentTheme = theme
            storedTheme = theme.rawValue
            
            let colors = theme.colors
            backgroundGradient = LinearGradient(
                colors: isDarkMode ? [colors.secondary, colors.primary] : [colors.primary, colors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            updateTextColorForContrast()
            updateNavigationBarTint()
        }
    }
    
    func animateGradientScroll(offset: CGFloat, maxOffset: CGFloat) {
        let progress = min(max(offset / maxOffset, 0), 1)
        let colors = currentTheme.colors
        
        // Interpolate between colors based on scroll
        let interpolatedPrimary = interpolateColor(
            from: colors.primary,
            to: colors.secondary,
            progress: progress
        )
        
        let interpolatedSecondary = interpolateColor(
            from: colors.secondary,
            to: colors.primary,
            progress: progress
        )
        
        withAnimation(.linear(duration: 0.1)) {
            backgroundGradient = LinearGradient(
                colors: [interpolatedPrimary, interpolatedSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        updateTextColorForContrast()
    }
    
    private func interpolateColor(from: Color, to: Color, progress: CGFloat) -> Color {
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * progress
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * progress
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * progress
        
        return Color(red: r, green: g, blue: b)
    }
    
    private func updateTextColorForContrast() {
        // Calculate contrast ratio for WCAG AA compliance
        let backgroundColor = currentTheme.colors.primary
        let lightContrast = calculateContrastRatio(
            foreground: .white,
            background: backgroundColor
        )
        let darkContrast = calculateContrastRatio(
            foreground: .black,
            background: backgroundColor
        )
        
        // WCAG AA requires 4.5:1 for normal text
        let requiredContrast: CGFloat = isHighContrast ? 7.0 : 4.5
        
        if lightContrast >= requiredContrast {
            textColor = .white
        } else if darkContrast >= requiredContrast {
            textColor = .black
        } else {
            // Adjust color to meet contrast requirements
            textColor = isHighContrast ? .white : Color.white.opacity(0.95)
        }
    }
    
    private func calculateContrastRatio(foreground: Color, background: Color) -> CGFloat {
        let fgLuminance = relativeLuminance(of: foreground)
        let bgLuminance = relativeLuminance(of: background)
        
        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private func relativeLuminance(of color: Color) -> CGFloat {
        let components = UIColor(color).cgColor.components ?? [0, 0, 0]
        
        let rgb = components.prefix(3).map { component in
            if component <= 0.03928 {
                return component / 12.92
            } else {
                return pow((component + 0.055) / 1.055, 2.4)
            }
        }
        
        return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
    }
    
    private func updateNavigationBarTint() {
        navigationTint = textColor
        
        // Update UIKit navigation bar
        DispatchQueue.main.async {
            UINavigationBar.appearance().tintColor = UIColor(self.navigationTint)
        }
    }
    
    private func adaptToSystemTheme() {
        if isDarkMode {
            transitionToTheme(.midnight)
        } else {
            transitionToTheme(.forest)
        }
    }
}

// MARK: - Theme Picker View
struct ThemePickerView: View {
    @StateObject private var colorSystem = AdaptiveColorSystem.shared
    @State private var selectedTheme: AdaptiveColorSystem.ColorTheme
    @State private var showPreview = false
    
    init() {
        _selectedTheme = State(initialValue: AdaptiveColorSystem.shared.currentTheme)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Theme")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(AdaptiveColorSystem.ColorTheme.allCases, id: \.self) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        action: {
                            selectTheme(theme)
                        }
                    )
                }
            }
            
            Toggle("Use System Theme", isOn: $colorSystem.useSystemTheme)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            if showPreview {
                PreviewSection()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding()
    }
    
    private func selectTheme(_ theme: AdaptiveColorSystem.ColorTheme) {
        selectedTheme = theme
        colorSystem.transitionToTheme(theme)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showPreview = true
        }
        
        // Hide preview after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showPreview = false
            }
        }
    }
}

struct ThemeCard: View {
    let theme: AdaptiveColorSystem.ColorTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                LinearGradient(
                    colors: [theme.colors.primary, theme.colors.secondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 80)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                )
                
                Text(theme.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct PreviewSection: View {
    @StateObject private var colorSystem = AdaptiveColorSystem.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(colorSystem.textColor)
            
            Text("This text adapts to maintain WCAG AA contrast")
                .font(.body)
                .foregroundColor(colorSystem.textColor.opacity(0.8))
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Accessible")
                    .foregroundColor(colorSystem.textColor)
            }
        }
        .padding()
        .background(colorSystem.backgroundGradient)
        .cornerRadius(12)
    }
}

// MARK: - View Modifier for Adaptive Background
struct AdaptiveBackground: ViewModifier {
    @StateObject private var colorSystem = AdaptiveColorSystem.shared
    let scrollOffset: CGFloat
    let maxOffset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(colorSystem.backgroundGradient)
            .onChange(of: scrollOffset) { _, newOffset in
                colorSystem.animateGradientScroll(
                    offset: newOffset,
                    maxOffset: maxOffset
                )
            }
    }
}

extension View {
    func adaptiveBackground(scrollOffset: CGFloat, maxOffset: CGFloat = 1000) -> some View {
        modifier(AdaptiveBackground(scrollOffset: scrollOffset, maxOffset: maxOffset))
    }
}