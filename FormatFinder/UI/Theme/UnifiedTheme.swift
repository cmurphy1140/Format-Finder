import SwiftUI

// MARK: - Unified Theme System
// Single source of truth for all theming in FormatFinder
// Consolidates: ColorTheme, GolfTheme, MastersTheme, MastersDesignSystem, DesignSystem

// MARK: - Theme Protocol
protocol ThemeProtocol {
    var colors: ThemeColors { get }
    var typography: ThemeTypography { get }
    var layout: ThemeLayout { get }
    var animations: ThemeAnimations { get }
}

// MARK: - Current Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .masters
    
    static let shared = ThemeManager()
    
    enum Theme: String, CaseIterable {
        case masters = "Masters"
        case classic = "Classic"
        case modern = "Modern"
        
        var implementation: ThemeProtocol {
            switch self {
            case .masters: return MastersThemeImplementation()
            case .classic: return ClassicThemeImplementation()
            case .modern: return ModernThemeImplementation()
            }
        }
    }
}

// MARK: - Unified Color System
struct ThemeColors {
    // Primary Colors
    let primary: Color
    let primaryLight: Color
    let primaryDark: Color
    
    // Secondary Colors
    let secondary: Color
    let secondaryLight: Color
    let secondaryDark: Color
    
    // Accent Colors
    let accent: Color
    let accentGold: Color
    let accentRed: Color
    
    // Background Colors
    let background: Color
    let backgroundSecondary: Color
    let surface: Color
    let card: Color
    
    // Text Colors
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textOnPrimary: Color
    
    // Semantic Colors
    let success: Color      // Birdie, Eagle
    let warning: Color      // Bogey
    let error: Color        // Double Bogey+
    let info: Color         // Par
    
    // Special Golf Colors
    let fairway: Color
    let bunker: Color
    let water: Color
    let sky: Color
    
    // UI Colors
    let divider: Color
    let shadow: Color
    let overlay: Color
    
    // Gradients
    let primaryGradient: LinearGradient
    let backgroundGradient: LinearGradient
    let cardGradient: LinearGradient
}

// MARK: - Unified Typography System
struct ThemeTypography {
    // Display Fonts
    let heroTitle: Font         // 42pt - App title
    let displayTitle: Font      // 34pt - Screen titles
    let sectionHeader: Font     // 28pt - Section headers
    let cardTitle: Font         // 22pt - Card titles
    
    // Body Fonts
    let headline: Font          // 17pt bold
    let body: Font              // 16pt regular
    let callout: Font           // 15pt regular
    let caption: Font           // 13pt regular
    let footnote: Font          // 11pt regular
    
    // Data Display
    let scoreDisplay: Font      // 24pt bold - Scores
    let dataLabel: Font         // 17pt semibold - Labels
    let statValue: Font         // 20pt medium - Stats
    
    // Font Families
    let primaryFontFamily: String
    let secondaryFontFamily: String
}

// MARK: - Unified Layout System
struct ThemeLayout {
    // Spacing
    let spacingXS: CGFloat = 4
    let spacingS: CGFloat = 8
    let spacingM: CGFloat = 16
    let spacingL: CGFloat = 24
    let spacingXL: CGFloat = 32
    let spacingXXL: CGFloat = 48
    
    // Corner Radius
    let radiusS: CGFloat = 8
    let radiusM: CGFloat = 12
    let radiusL: CGFloat = 16
    let radiusXL: CGFloat = 20
    let radiusRound: CGFloat = 100
    
    // Card Styling
    let cardRadius: CGFloat
    let cardPadding: CGFloat
    let cardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    
    // Button Styling
    let buttonRadius: CGFloat
    let buttonPadding: EdgeInsets
    let buttonHeight: CGFloat
}

// MARK: - Unified Animation System
struct ThemeAnimations {
    let standard: Animation = .spring(response: 0.3, dampingFraction: 0.7)
    let bounce: Animation = .spring(response: 0.4, dampingFraction: 0.6)
    let smooth: Animation = .easeInOut(duration: 0.3)
    let quick: Animation = .easeOut(duration: 0.2)
    let slow: Animation = .easeInOut(duration: 0.6)
    
    // Haptic Feedback Types
    enum HapticStyle {
        case light, medium, heavy, success, warning, error
    }
    
    func triggerHaptic(_ style: HapticStyle) {
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Masters Theme Implementation
struct MastersThemeImplementation: ThemeProtocol {
    var colors: ThemeColors {
        ThemeColors(
            // Primary - Augusta Green
            primary: Color(hex: "006747"),
            primaryLight: Color(hex: "4CAF50"),
            primaryDark: Color(hex: "004D35"),
            
            // Secondary - Augusta Gold
            secondary: Color(hex: "FFD700"),
            secondaryLight: Color(hex: "FFC107"),
            secondaryDark: Color(hex: "FFA000"),
            
            // Accent Colors
            accent: Color(hex: "AF52DE"),  // Purple
            accentGold: Color(hex: "FFD700"),
            accentRed: Color(hex: "C41E3A"),
            
            // Backgrounds
            background: Color(hex: "F8F8F5"),  // Magnolia Lane
            backgroundSecondary: Color(hex: "F0F7F2"),  // Fairway Mist
            surface: Color(hex: "FFFFFF"),  // Azalea White
            card: Color(hex: "FFFFFF"),
            
            // Text
            textPrimary: Color(hex: "2C3E50"),  // Graphite
            textSecondary: Color(hex: "34495E"),
            textTertiary: Color(hex: "95A5A6"),  // Silver
            textOnPrimary: Color(hex: "FFFFFF"),
            
            // Semantic
            success: Color(hex: "4CAF50"),  // Birdie
            warning: Color(hex: "FF9800"),  // Bogey
            error: Color(hex: "F44336"),    // Double Bogey
            info: Color(hex: "2196F3"),     // Par
            
            // Golf Specific
            fairway: Color(hex: "228B22"),
            bunker: Color(hex: "EECBAD"),
            water: Color(hex: "4682B4"),
            sky: Color(hex: "87CEEB"),
            
            // UI
            divider: Color(hex: "ECF0F1").opacity(0.3),
            shadow: Color.black.opacity(0.1),
            overlay: Color.black.opacity(0.3),
            
            // Gradients
            primaryGradient: LinearGradient(
                colors: [Color(hex: "006747"), Color(hex: "4CAF50")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            backgroundGradient: LinearGradient(
                colors: [Color(hex: "F0F7F2"), Color(hex: "FFFFFF")],
                startPoint: .top,
                endPoint: .bottom
            ),
            cardGradient: LinearGradient(
                colors: [Color.white, Color(hex: "FCFEFC")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    var typography: ThemeTypography {
        ThemeTypography(
            heroTitle: Font.custom("Georgia", size: 42).weight(.light),
            displayTitle: Font.custom("Georgia", size: 34),
            sectionHeader: Font.custom("Georgia", size: 28).weight(.medium),
            cardTitle: Font.custom("Georgia", size: 22).weight(.medium),
            headline: Font.custom("Georgia-Bold", size: 17),
            body: Font.custom("Georgia", size: 16),
            callout: Font.custom("Georgia", size: 15),
            caption: Font.custom("Georgia", size: 13),
            footnote: Font.custom("Georgia", size: 11),
            scoreDisplay: Font.custom("SF Pro Display", size: 24).weight(.bold),
            dataLabel: Font.custom("SF Pro Display", size: 17).weight(.semibold),
            statValue: Font.custom("SF Pro Display", size: 20).weight(.medium),
            primaryFontFamily: "Georgia",
            secondaryFontFamily: "SF Pro Display"
        )
    }
    
    var layout: ThemeLayout {
        ThemeLayout(
            cardRadius: 16,
            cardPadding: 16,
            cardShadow: (
                color: Color.black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            ),
            buttonRadius: 12,
            buttonPadding: EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24),
            buttonHeight: 48
        )
    }
    
    var animations: ThemeAnimations {
        ThemeAnimations()
    }
}

// MARK: - Classic Theme Implementation
struct ClassicThemeImplementation: ThemeProtocol {
    var colors: ThemeColors {
        ThemeColors(
            // Material Design inspired
            primary: Color(hex: "4CAF50"),
            primaryLight: Color(hex: "81C784"),
            primaryDark: Color(hex: "388E3C"),
            
            secondary: Color(hex: "2196F3"),
            secondaryLight: Color(hex: "64B5F6"),
            secondaryDark: Color(hex: "1976D2"),
            
            accent: Color(hex: "FF9800"),
            accentGold: Color(hex: "FFC107"),
            accentRed: Color(hex: "DC143C"),
            
            background: Color(hex: "F8FAFc"),
            backgroundSecondary: Color(hex: "F5F7FA"),
            surface: Color.white,
            card: Color.white,
            
            textPrimary: Color(hex: "212529"),
            textSecondary: Color(hex: "6C757D"),
            textTertiary: Color(hex: "ADB5BD"),
            textOnPrimary: Color.white,
            
            success: Color(hex: "4CAF50"),
            warning: Color(hex: "FF9800"),
            error: Color(hex: "F44336"),
            info: Color(hex: "2196F3"),
            
            fairway: Color(hex: "228B22"),
            bunker: Color(hex: "EECBAD"),
            water: Color(hex: "4682B4"),
            sky: Color(hex: "87CEEB"),
            
            divider: Color.gray.opacity(0.2),
            shadow: Color.black.opacity(0.08),
            overlay: Color.black.opacity(0.4),
            
            primaryGradient: LinearGradient(
                colors: [Color(hex: "4CAF50"), Color(hex: "81C784")],
                startPoint: .leading,
                endPoint: .trailing
            ),
            backgroundGradient: LinearGradient(
                colors: [Color(hex: "F0F9F0"), Color(hex: "F5FAF5")],
                startPoint: .top,
                endPoint: .bottom
            ),
            cardGradient: LinearGradient(
                colors: [Color.white, Color(hex: "FCFEFC")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    var typography: ThemeTypography {
        ThemeTypography(
            heroTitle: Font.system(size: 42, weight: .heavy, design: .rounded),
            displayTitle: Font.system(size: 34, weight: .bold, design: .rounded),
            sectionHeader: Font.system(size: 28, weight: .semibold, design: .rounded),
            cardTitle: Font.system(size: 22, weight: .medium),
            headline: Font.system(size: 17, weight: .semibold),
            body: Font.system(size: 16),
            callout: Font.system(size: 15),
            caption: Font.system(size: 13),
            footnote: Font.system(size: 11),
            scoreDisplay: Font.system(size: 24, weight: .bold, design: .monospaced),
            dataLabel: Font.system(size: 17, weight: .semibold),
            statValue: Font.system(size: 20, weight: .medium),
            primaryFontFamily: "-apple-system",
            secondaryFontFamily: "SF Pro Display"
        )
    }
    
    var layout: ThemeLayout {
        ThemeLayout(
            cardRadius: 20,
            cardPadding: 20,
            cardShadow: (
                color: Color.black.opacity(0.08),
                radius: 10,
                x: 0,
                y: 4
            ),
            buttonRadius: 25,
            buttonPadding: EdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28),
            buttonHeight: 52
        )
    }
    
    var animations: ThemeAnimations {
        ThemeAnimations()
    }
}

// MARK: - Modern Theme Implementation
struct ModernThemeImplementation: ThemeProtocol {
    var colors: ThemeColors {
        ThemeColors(
            primary: Color(hex: "007AFF"),
            primaryLight: Color(hex: "5AC8FA"),
            primaryDark: Color(hex: "0051D5"),
            
            secondary: Color(hex: "5856D6"),
            secondaryLight: Color(hex: "AF52DE"),
            secondaryDark: Color(hex: "3634A3"),
            
            accent: Color(hex: "FF3B30"),
            accentGold: Color(hex: "FFCC00"),
            accentRed: Color(hex: "FF3B30"),
            
            background: Color(hex: "000000"),
            backgroundSecondary: Color(hex: "1C1C1E"),
            surface: Color(hex: "2C2C2E"),
            card: Color(hex: "3A3A3C"),
            
            textPrimary: Color.white,
            textSecondary: Color(hex: "EBEBF5").opacity(0.6),
            textTertiary: Color(hex: "EBEBF5").opacity(0.3),
            textOnPrimary: Color.white,
            
            success: Color(hex: "32D74B"),
            warning: Color(hex: "FF9500"),
            error: Color(hex: "FF453A"),
            info: Color(hex: "64D2FF"),
            
            fairway: Color(hex: "32D74B"),
            bunker: Color(hex: "AC8E68"),
            water: Color(hex: "64D2FF"),
            sky: Color(hex: "0A84FF"),
            
            divider: Color.white.opacity(0.1),
            shadow: Color.black.opacity(0.3),
            overlay: Color.black.opacity(0.5),
            
            primaryGradient: LinearGradient(
                colors: [Color(hex: "007AFF"), Color(hex: "5AC8FA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            backgroundGradient: LinearGradient(
                colors: [Color(hex: "000000"), Color(hex: "1C1C1E")],
                startPoint: .top,
                endPoint: .bottom
            ),
            cardGradient: LinearGradient(
                colors: [Color(hex: "3A3A3C"), Color(hex: "2C2C2E")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    var typography: ThemeTypography {
        ThemeTypography(
            heroTitle: Font.system(size: 42, weight: .black, design: .default),
            displayTitle: Font.system(size: 34, weight: .bold),
            sectionHeader: Font.system(size: 28, weight: .semibold),
            cardTitle: Font.system(size: 22, weight: .medium),
            headline: Font.system(size: 17, weight: .semibold),
            body: Font.system(size: 16),
            callout: Font.system(size: 15),
            caption: Font.system(size: 13),
            footnote: Font.system(size: 11),
            scoreDisplay: Font.system(size: 24, weight: .heavy, design: .monospaced),
            dataLabel: Font.system(size: 17, weight: .bold),
            statValue: Font.system(size: 20, weight: .semibold),
            primaryFontFamily: "SF Pro Display",
            secondaryFontFamily: "SF Pro Text"
        )
    }
    
    var layout: ThemeLayout {
        ThemeLayout(
            cardRadius: 14,
            cardPadding: 18,
            cardShadow: (
                color: Color.black.opacity(0.3),
                radius: 12,
                x: 0,
                y: 8
            ),
            buttonRadius: 10,
            buttonPadding: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20),
            buttonHeight: 44
        )
    }
    
    var animations: ThemeAnimations {
        ThemeAnimations()
    }
}


// MARK: - Environment Key for Theme
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeProtocol = MastersThemeImplementation()
}

extension EnvironmentValues {
    var theme: ThemeProtocol {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func withTheme(_ theme: ThemeManager.Theme = .masters) -> some View {
        self.environment(\.theme, theme.implementation)
    }
    
    // Card Styles
    func themeCard() -> some View {
        self.modifier(ThemeCardModifier())
    }
    
    // Button Styles
    func themePrimaryButton() -> some View {
        self.modifier(ThemePrimaryButtonModifier())
    }
    
    func themeSecondaryButton() -> some View {
        self.modifier(ThemeSecondaryButtonModifier())
    }
    
    // Text Styles
    func themeTitle() -> some View {
        self.modifier(ThemeTitleModifier())
    }
    
    func themeBody() -> some View {
        self.modifier(ThemeBodyModifier())
    }
    
    func themeCaption() -> some View {
        self.modifier(ThemeCaptionModifier())
    }
}

// MARK: - Theme View Modifiers
struct ThemeCardModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .background(theme.colors.card)
            .cornerRadius(theme.layout.cardRadius)
            .shadow(
                color: theme.layout.cardShadow.color,
                radius: theme.layout.cardShadow.radius,
                x: theme.layout.cardShadow.x,
                y: theme.layout.cardShadow.y
            )
    }
}

struct ThemePrimaryButtonModifier: ViewModifier {
    @Environment(\.theme) var theme
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.headline)
            .foregroundColor(theme.colors.textOnPrimary)
            .padding(theme.layout.buttonPadding)
            .background(theme.colors.primary)
            .cornerRadius(theme.layout.buttonRadius)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(theme.animations.quick) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

struct ThemeSecondaryButtonModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.headline)
            .foregroundColor(theme.colors.primary)
            .padding(theme.layout.buttonPadding)
            .background(
                RoundedRectangle(cornerRadius: theme.layout.buttonRadius)
                    .stroke(theme.colors.primary, lineWidth: 2)
            )
    }
}

struct ThemeTitleModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.sectionHeader)
            .foregroundColor(theme.colors.textPrimary)
    }
}

struct ThemeBodyModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.body)
            .foregroundColor(theme.colors.textPrimary)
    }
}

struct ThemeCaptionModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        content
            .font(theme.typography.caption)
            .foregroundColor(theme.colors.textSecondary)
    }
}

// MARK: - Backwards Compatibility
// These typealiases maintain compatibility with existing code
typealias MastersColors = UnifiedColors
typealias AppColors = UnifiedColors
typealias GolfColors = UnifiedColors

struct UnifiedColors {
    // Masters Theme Colors (Default)
    static let mastersGreen = Color(hex: "006747")
    static let augustaGold = Color(hex: "FFD700")
    static let azaleaWhite = Color(hex: "FFFFFF")
    static let magnoliaLane = Color(hex: "F8F8F5")
    static let fairwayMist = Color(hex: "F0F7F2")
    static let shadowGreen = Color(hex: "004D35")
    static let eagleGold = Color(hex: "FFC107")
    static let graphite = Color(hex: "34495E")
    static let silver = Color(hex: "95A5A6")
    static let fog = Color(hex: "BDC3C7")
    static let pearl = Color(hex: "F5F5F0")
    static let slate = Color(hex: "708090")
    static let divider = Color.gray.opacity(0.3)
    static let shadow = Color.black.opacity(0.1)
    static let scoreRed = Color(hex: "DC143C")
    static let par = Color(hex: "4169E1")
    
    // Gradients
    static let headerGradient = LinearGradient(
        gradient: Gradient(colors: [mastersGreen, mastersGreen.opacity(0.8)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // App Colors (Legacy)
    static let primaryGreen = mastersGreen
    static let backgroundPrimary = mastersGreen
    static let lightGreen = Color(hex: "81C784")
    static let darkGreen = shadowGreen
    static let fairwayGreen = Color(hex: "7CB342")
    static let brightGreen = Color(hex: "66CC00")
    
    // Common Colors
    static let cardBackground = azaleaWhite
    static let cardShadow = Color.black.opacity(0.1)
    static let textPrimary = graphite
    static let textSecondary = Color(hex: "6C757D")
    
    // Scoring Colors
    static let birdie = Color(hex: "4CAF50")
    static let bogey = Color(hex: "FF9800")
    static let doubleBogey = Color(hex: "F44336")
}

// Typography Backwards Compatibility
typealias MastersTypography = UnifiedTypography
typealias MastersLayout = UnifiedLayout

struct UnifiedTypography {
    static func heroTitle() -> Font { Font.custom("Georgia", size: 42).weight(.light) }
    static func displayTitle() -> Font { Font.custom("Georgia", size: 34) }
    static func sectionHeader() -> Font { Font.custom("Georgia", size: 28).weight(.medium) }
    static func cardTitle() -> Font { Font.custom("Georgia", size: 22).weight(.medium) }
    static func bodyText() -> Font { Font.custom("Georgia", size: 16) }
    static func captionText() -> Font { Font.custom("Georgia", size: 13) }
    static func scoreDisplay() -> Font { Font.custom("SF Pro Display", size: 24).weight(.bold) }
    static func dataLabel() -> Font { Font.custom("SF Pro Display", size: 17).weight(.semibold) }
    static func microText() -> Font { Font.custom("SF Pro Display", size: 10) }
}

struct UnifiedLayout {
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 12
    static let cardShadow = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    
    // Spacing constants
    static let microSpacing: CGFloat = 2
    static let tinySpacing: CGFloat = 4
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 12
    static let standardSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 16
    static let xLargeSpacing: CGFloat = 24
    static let heroSpacing: CGFloat = 32
    
    // Radius constants
    static let smallRadius: CGFloat = 8
    static let standardRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
}