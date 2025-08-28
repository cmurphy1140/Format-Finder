import SwiftUI
import Combine

// MARK: - Advanced Theme Engine
@MainActor
class ThemeEngine: ObservableObject {
    @Published var currentTheme: Theme = .classic
    @Published var isAutoThemeEnabled = true
    @Published var colorBlindMode: ColorBlindMode = .none
    @Published var useDynamicType = true
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    enum ThemeType: String, CaseIterable {
        case classic = "Classic Green"
        case dark = "Midnight Course"
        case highContrast = "High Contrast"
        case dawn = "Dawn Patrol"
        case dusk = "Twilight Round"
        case links = "Links Style"
        case desert = "Desert Course"
        case autumn = "Autumn Fairway"
    }
    
    enum ColorBlindMode: String, CaseIterable {
        case none = "None"
        case protanopia = "Protanopia"
        case deuteranopia = "Deuteranopia"
        case tritanopia = "Tritanopia"
    }
    
    struct Theme: ThemeProtocol {
        let type: ThemeType
        let colorScheme: ColorScheme
        let animationSettings: AnimationSettings
        let typographySettings: Typography
        
        // ThemeProtocol conformance
        var colors: ThemeColors {
            ThemeColors(
                primary: colorScheme.primary,
                primaryLight: colorScheme.secondary,
                primaryDark: colorScheme.primary.opacity(0.8),
                secondary: colorScheme.secondary,
                secondaryLight: colorScheme.tertiary,
                secondaryDark: colorScheme.secondary.opacity(0.8),
                accent: colorScheme.tertiary,
                accentGold: Color(hex: "FFD700"),
                accentRed: colorScheme.error,
                background: Color.clear, // Will use gradient
                backgroundSecondary: colorScheme.surface.opacity(0.95),
                surface: colorScheme.surface,
                card: colorScheme.surface,
                textPrimary: colorScheme.text,
                textSecondary: colorScheme.textSecondary,
                textTertiary: colorScheme.textSecondary.opacity(0.7),
                textOnPrimary: Color.white,
                success: colorScheme.success,
                warning: colorScheme.warning,
                error: colorScheme.error,
                info: Color.blue,
                fairway: colorScheme.primary,
                bunker: colorScheme.bunker,
                water: Color.blue,
                sky: Color(hex: "87CEEB"),
                divider: Color.gray.opacity(0.3),
                shadow: Color.black.opacity(0.1),
                overlay: Color.black.opacity(0.4),
                primaryGradient: colorScheme.fairway,
                backgroundGradient: colorScheme.background,
                cardGradient: LinearGradient(colors: [colorScheme.surface, colorScheme.surface], startPoint: .top, endPoint: .bottom)
            )
        }
        
        var typography: ThemeTypography {
            ThemeTypography(
                heroTitle: typographySettings.heroTitle,
                displayTitle: typographySettings.displayTitle,
                sectionHeader: typographySettings.sectionHeader,
                cardTitle: typographySettings.cardTitle,
                headline: typographySettings.headline,
                body: typographySettings.body,
                callout: typographySettings.callout,
                caption: typographySettings.caption,
                footnote: typographySettings.footnote,
                scoreDisplay: .system(size: 24, weight: .bold, design: .rounded),
                dataLabel: .system(size: 17, weight: .semibold, design: .default),
                statValue: .system(size: 20, weight: .medium, design: .default),
                primaryFontFamily: "SF Pro",
                secondaryFontFamily: "SF Pro Display"
            )
        }
        
        var layout: ThemeLayout {
            ThemeLayout(
                cardRadius: 16,
                cardPadding: 16,
                cardShadow: (color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4),
                buttonRadius: 12,
                buttonPadding: EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24),
                buttonHeight: 44
            )
        }
        
        var animations: ThemeAnimations {
            ThemeAnimations()
        }
        
        static let classic = Theme(
            type: .classic,
            colorScheme: ColorScheme.classic,
            animationSettings: AnimationSettings.standard,
            typographySettings: Typography.standard
        )
        
        static let dark = Theme(
            type: .dark,
            colorScheme: ColorScheme.dark,
            animationSettings: AnimationSettings.smooth,
            typographySettings: Typography.modern
        )
        
        static let highContrast = Theme(
            type: .highContrast,
            colorScheme: ColorScheme.highContrast,
            animationSettings: AnimationSettings.reduced,
            typographySettings: Typography.accessible
        )
        
        static let dawn = Theme(
            type: .dawn,
            colorScheme: ColorScheme.dawn,
            animationSettings: AnimationSettings.gentle,
            typographySettings: Typography.elegant
        )
        
        static let dusk = Theme(
            type: .dusk,
            colorScheme: ColorScheme.dusk,
            animationSettings: AnimationSettings.dramatic,
            typographySettings: Typography.modern
        )
    }
    
    struct ColorScheme {
        let primary: Color
        let secondary: Color
        let tertiary: Color
        let background: LinearGradient
        let surface: Color
        let text: Color
        let textSecondary: Color
        let success: Color
        let warning: Color
        let error: Color
        let fairway: LinearGradient
        let rough: Color
        let bunker: Color
        let water: LinearGradient
        
        static let classic = ColorScheme(
            primary: Color(hex: "2E7D32"),
            secondary: Color(hex: "66BB6A"),
            tertiary: Color(hex: "81C784"),
            background: LinearGradient(
                colors: [Color(hex: "E8F5E9"), Color(hex: "C8E6C9")],
                startPoint: .top,
                endPoint: .bottom
            ),
            surface: Color.white,
            text: Color(hex: "1B5E20"),
            textSecondary: Color(hex: "4CAF50"),
            success: Color(hex: "4CAF50"),
            warning: Color(hex: "FFC107"),
            error: Color(hex: "F44336"),
            fairway: LinearGradient(
                colors: [Color(hex: "388E3C"), Color(hex: "2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            rough: Color(hex: "5D4037"),
            bunker: Color(hex: "FFE0B2"),
            water: LinearGradient(
                colors: [Color(hex: "1976D2"), Color(hex: "0D47A1")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        
        static let dark = ColorScheme(
            primary: Color(hex: "1B5E20"),
            secondary: Color(hex: "2E7D32"),
            tertiary: Color(hex: "388E3C"),
            background: LinearGradient(
                colors: [Color(hex: "0A0E27"), Color(hex: "1A237E")],
                startPoint: .top,
                endPoint: .bottom
            ),
            surface: Color(hex: "1E1E2E"),
            text: Color(hex: "E8F5E9"),
            textSecondary: Color(hex: "81C784"),
            success: Color(hex: "66BB6A"),
            warning: Color(hex: "FFB74D"),
            error: Color(hex: "EF5350"),
            fairway: LinearGradient(
                colors: [Color(hex: "1B5E20"), Color(hex: "0D47A1")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            rough: Color(hex: "3E2723"),
            bunker: Color(hex: "6D4C41"),
            water: LinearGradient(
                colors: [Color(hex: "01579B"), Color(hex: "002171")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        
        static let highContrast = ColorScheme(
            primary: Color.black,
            secondary: Color(hex: "333333"),
            tertiary: Color(hex: "666666"),
            background: LinearGradient(
                colors: [Color.white, Color(hex: "F5F5F5")],
                startPoint: .top,
                endPoint: .bottom
            ),
            surface: Color.white,
            text: Color.black,
            textSecondary: Color(hex: "333333"),
            success: Color(hex: "00C853"),
            warning: Color(hex: "FFD600"),
            error: Color(hex: "D50000"),
            fairway: LinearGradient(
                colors: [Color(hex: "00C853"), Color(hex: "00E676")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            rough: Color(hex: "424242"),
            bunker: Color(hex: "FFF9C4"),
            water: LinearGradient(
                colors: [Color(hex: "0091EA"), Color(hex: "00B0FF")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        
        static let dawn = ColorScheme(
            primary: Color(hex: "FF6F61"),
            secondary: Color(hex: "FFB347"),
            tertiary: Color(hex: "FFD700"),
            background: LinearGradient(
                colors: [
                    Color(hex: "FFE5CC"),
                    Color(hex: "FFDAB9"),
                    Color(hex: "87CEEB").opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            surface: Color(hex: "FFF5EE"),
            text: Color(hex: "4A4A4A"),
            textSecondary: Color(hex: "7A7A7A"),
            success: Color(hex: "90EE90"),
            warning: Color(hex: "FFB347"),
            error: Color(hex: "FF6B6B"),
            fairway: LinearGradient(
                colors: [Color(hex: "98D982"), Color(hex: "7CB342")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            rough: Color(hex: "8B7355"),
            bunker: Color(hex: "F4E4C1"),
            water: LinearGradient(
                colors: [Color(hex: "87CEEB"), Color(hex: "4682B4")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        
        static let dusk = ColorScheme(
            primary: Color(hex: "4A148C"),
            secondary: Color(hex: "7B1FA2"),
            tertiary: Color(hex: "9C27B0"),
            background: LinearGradient(
                colors: [
                    Color(hex: "1A237E"),
                    Color(hex: "283593"),
                    Color(hex: "E91E63").opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            surface: Color(hex: "311B92"),
            text: Color(hex: "E1BEE7"),
            textSecondary: Color(hex: "BA68C8"),
            success: Color(hex: "69F0AE"),
            warning: Color(hex: "FFD54F"),
            error: Color(hex: "FF5252"),
            fairway: LinearGradient(
                colors: [Color(hex: "004D40"), Color(hex: "00695C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            rough: Color(hex: "3E2723"),
            bunker: Color(hex: "5D4037"),
            water: LinearGradient(
                colors: [Color(hex: "1A237E"), Color(hex: "0D47A1")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    struct AnimationSettings {
        let cardFlip: Animation
        let transition: Animation
        let bounce: Animation
        let scale: Animation
        let fade: Animation
        
        static let standard = AnimationSettings(
            cardFlip: .spring(response: 0.6, dampingFraction: 0.8),
            transition: .easeInOut(duration: 0.3),
            bounce: .spring(response: 0.5, dampingFraction: 0.7),
            scale: .easeInOut(duration: 0.2),
            fade: .easeIn(duration: 0.2)
        )
        
        static let smooth = AnimationSettings(
            cardFlip: .spring(response: 0.8, dampingFraction: 0.9),
            transition: .easeInOut(duration: 0.4),
            bounce: .spring(response: 0.6, dampingFraction: 0.8),
            scale: .easeInOut(duration: 0.3),
            fade: .easeIn(duration: 0.3)
        )
        
        static let reduced = AnimationSettings(
            cardFlip: .linear(duration: 0.1),
            transition: .linear(duration: 0.1),
            bounce: .linear(duration: 0.1),
            scale: .linear(duration: 0.1),
            fade: .linear(duration: 0.1)
        )
        
        static let gentle = AnimationSettings(
            cardFlip: .easeInOut(duration: 0.5),
            transition: .easeInOut(duration: 0.35),
            bounce: .spring(response: 0.7, dampingFraction: 0.85),
            scale: .easeInOut(duration: 0.25),
            fade: .easeIn(duration: 0.25)
        )
        
        static let dramatic = AnimationSettings(
            cardFlip: .spring(response: 0.4, dampingFraction: 0.6),
            transition: .easeInOut(duration: 0.5),
            bounce: .spring(response: 0.3, dampingFraction: 0.5),
            scale: .spring(response: 0.3, dampingFraction: 0.7),
            fade: .easeIn(duration: 0.4)
        )
    }
    
    struct Typography {
        let largeTitle: Font
        let title: Font
        let headline: Font
        let body: Font
        let callout: Font
        let caption: Font
        
        // Additional properties for ThemeProtocol conformance
        var heroTitle: Font { largeTitle }
        var displayTitle: Font { largeTitle }
        var sectionHeader: Font { title }
        var cardTitle: Font { headline }
        var subheadline: Font { callout }
        var footnote: Font { caption }
        
        static let standard = Typography(
            largeTitle: .system(size: 34, weight: .bold, design: .rounded),
            title: .system(size: 28, weight: .semibold, design: .rounded),
            headline: .system(size: 20, weight: .semibold, design: .default),
            body: .system(size: 17, weight: .regular, design: .default),
            callout: .system(size: 15, weight: .regular, design: .default),
            caption: .system(size: 12, weight: .regular, design: .default)
        )
        
        static let modern = Typography(
            largeTitle: .system(size: 36, weight: .heavy, design: .serif),
            title: .system(size: 30, weight: .bold, design: .serif),
            headline: .system(size: 22, weight: .semibold, design: .serif),
            body: .system(size: 18, weight: .regular, design: .default),
            callout: .system(size: 16, weight: .regular, design: .default),
            caption: .system(size: 13, weight: .light, design: .default)
        )
        
        static let accessible = Typography(
            largeTitle: .system(size: 40, weight: .black, design: .default),
            title: .system(size: 32, weight: .bold, design: .default),
            headline: .system(size: 24, weight: .bold, design: .default),
            body: .system(size: 20, weight: .medium, design: .default),
            callout: .system(size: 18, weight: .regular, design: .default),
            caption: .system(size: 16, weight: .regular, design: .default)
        )
        
        static let elegant = Typography(
            largeTitle: .system(size: 32, weight: .thin, design: .serif),
            title: .system(size: 26, weight: .light, design: .serif),
            headline: .system(size: 19, weight: .regular, design: .serif),
            body: .system(size: 16, weight: .light, design: .serif),
            callout: .system(size: 14, weight: .light, design: .serif),
            caption: .system(size: 11, weight: .light, design: .serif)
        )
    }
    
    init() {
        loadUserPreferences()
        setupAutoTheme()
    }
    
    private func loadUserPreferences() {
        if let themeString = userDefaults.string(forKey: "selectedTheme"),
           let themeType = ThemeType(rawValue: themeString) {
            updateTheme(to: themeType)
        }
        
        isAutoThemeEnabled = userDefaults.bool(forKey: "autoTheme")
        
        if let colorBlindString = userDefaults.string(forKey: "colorBlindMode"),
           let mode = ColorBlindMode(rawValue: colorBlindString) {
            colorBlindMode = mode
        }
    }
    
    private func setupAutoTheme() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if self.isAutoThemeEnabled {
                    self.updateThemeBasedOnTime()
                }
            }
            .store(in: &cancellables)
        
        // Initial check
        if isAutoThemeEnabled {
            updateThemeBasedOnTime()
        }
    }
    
    func updateThemeBasedOnTime() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<9:
            updateTheme(to: .dawn)
        case 9..<17:
            updateTheme(to: .classic)
        case 17..<20:
            updateTheme(to: .dusk)
        default:
            updateTheme(to: .dark)
        }
    }
    
    func updateTheme(to type: ThemeType) {
        withAnimation(.easeInOut(duration: 0.5)) {
            switch type {
            case .classic:
                currentTheme = .classic
            case .dark:
                currentTheme = .dark
            case .highContrast:
                currentTheme = .highContrast
            case .dawn:
                currentTheme = .dawn
            case .dusk:
                currentTheme = .dusk
            case .links:
                currentTheme = Theme(
                    type: .links,
                    colorScheme: ColorScheme.classic,
                    animationSettings: AnimationSettings.standard,
                    typographySettings: Typography.elegant
                )
            case .desert:
                currentTheme = Theme(
                    type: .desert,
                    colorScheme: ColorScheme.dawn,
                    animationSettings: AnimationSettings.gentle,
                    typographySettings: Typography.modern
                )
            case .autumn:
                currentTheme = Theme(
                    type: .autumn,
                    colorScheme: ColorScheme.dusk,
                    animationSettings: AnimationSettings.dramatic,
                    typographySettings: Typography.elegant
                )
            }
        }
        
        userDefaults.set(type.rawValue, forKey: "selectedTheme")
    }
    
    func applyColorBlindFilter(to color: Color) -> Color {
        switch colorBlindMode {
        case .none:
            return color
        case .protanopia:
            // Red-blind simulation
            return color.adjustedForProtanopia()
        case .deuteranopia:
            // Green-blind simulation
            return color.adjustedForDeuteranopia()
        case .tritanopia:
            // Blue-blind simulation
            return color.adjustedForTritanopia()
        }
    }
}

// MARK: - Theme Environment Key (removed duplicate - using UnifiedTheme.swift implementation)

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func adjustedForProtanopia() -> Color {
        // Simplified protanopia adjustment
        return self
    }
    
    func adjustedForDeuteranopia() -> Color {
        // Simplified deuteranopia adjustment
        return self
    }
    
    func adjustedForTritanopia() -> Color {
        // Simplified tritanopia adjustment
        return self
    }
}

// MARK: - Theme Selector View
struct ThemeSelectorView: View {
    @StateObject private var themeEngine = ThemeEngine()
    @State private var selectedTheme: ThemeEngine.ThemeType = .classic
    @State private var showPreview = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Auto Theme")) {
                    Toggle("Time-based themes", isOn: $themeEngine.isAutoThemeEnabled)
                        .onChange(of: themeEngine.isAutoThemeEnabled) { newValue in
                            if newValue {
                                themeEngine.updateThemeBasedOnTime()
                            }
                        }
                }
                
                Section(header: Text("Manual Theme Selection")) {
                    ForEach(ThemeEngine.ThemeType.allCases, id: \.self) { themeType in
                        ThemeRowView(
                            themeType: themeType,
                            isSelected: selectedTheme == themeType,
                            onSelect: {
                                selectedTheme = themeType
                                themeEngine.updateTheme(to: themeType)
                                showPreview = true
                            }
                        )
                    }
                }
                .disabled(themeEngine.isAutoThemeEnabled)
                .opacity(themeEngine.isAutoThemeEnabled ? 0.5 : 1.0)
                
                Section(header: Text("Accessibility")) {
                    Picker("Color Blind Mode", selection: $themeEngine.colorBlindMode) {
                        ForEach(ThemeEngine.ColorBlindMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    
                    Toggle("Use Dynamic Type", isOn: $themeEngine.useDynamicType)
                }
                
                if showPreview {
                    Section(header: Text("Preview")) {
                        ThemePreviewCard()
                            .environmentObject(themeEngine)
                    }
                }
            }
            .navigationTitle("Themes")
            .environment(\.theme, themeEngine.currentTheme)
        }
    }
}

struct ThemeRowView: View {
    let themeType: ThemeEngine.ThemeType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var previewColors: [Color] {
        switch themeType {
        case .classic:
            return [Color(hex: "2E7D32"), Color(hex: "66BB6A"), Color(hex: "81C784")]
        case .dark:
            return [Color(hex: "1B5E20"), Color(hex: "2E7D32"), Color(hex: "388E3C")]
        case .highContrast:
            return [.black, Color(hex: "333333"), Color(hex: "666666")]
        case .dawn:
            return [Color(hex: "FF6F61"), Color(hex: "FFB347"), Color(hex: "FFD700")]
        case .dusk:
            return [Color(hex: "4A148C"), Color(hex: "7B1FA2"), Color(hex: "9C27B0")]
        case .links:
            return [Color(hex: "2E7D32"), Color(hex: "87CEEB"), Color(hex: "C8E6C9")]
        case .desert:
            return [Color(hex: "D2691E"), Color(hex: "F4A460"), Color(hex: "FFD700")]
        case .autumn:
            return [Color(hex: "8B4513"), Color(hex: "D2691E"), Color(hex: "FF8C00")]
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(themeType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        ForEach(previewColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemePreviewCard: View {
    @EnvironmentObject var themeEngine: ThemeEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format Finder")
                .font(themeEngine.currentTheme.typography.displayTitle)
                .foregroundColor(themeEngine.currentTheme.colors.primary)
            
            Text("Your golf game, perfected")
                .font(themeEngine.currentTheme.typography.body)
                .foregroundColor(themeEngine.currentTheme.colors.textSecondary)
            
            HStack(spacing: 12) {
                FormatPreviewBadge(text: "Scramble", color: themeEngine.currentTheme.colors.success)
                FormatPreviewBadge(text: "Best Ball", color: themeEngine.currentTheme.colors.warning)
                FormatPreviewBadge(text: "Skins", color: themeEngine.currentTheme.colors.error)
            }
        }
        .padding()
        .background(themeEngine.currentTheme.colors.surface)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct FormatPreviewBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(8)
    }
}