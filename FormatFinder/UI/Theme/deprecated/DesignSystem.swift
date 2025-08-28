import SwiftUI

// MARK: - Design System
// Centralized design system for consistent UI across the app

public struct DesignSystem {
    
    // MARK: - Colors
    public struct Colors {
        
        // MARK: Semantic Colors
        public static let primary = Color("Primary", bundle: .main)
        public static let primaryVariant = Color("PrimaryVariant", bundle: .main)
        public static let secondary = Color("Secondary", bundle: .main)
        public static let secondaryVariant = Color("SecondaryVariant", bundle: .main)
        
        // MARK: Feedback Colors
        public static let success = Color("Success", bundle: .main)
        public static let warning = Color("Warning", bundle: .main)
        public static let error = Color("Error", bundle: .main)
        public static let info = Color("Info", bundle: .main)
        
        // MARK: Surface Colors
        public static let background = Color("Background", bundle: .main)
        public static let surface = Color("Surface", bundle: .main)
        public static let surfaceVariant = Color("SurfaceVariant", bundle: .main)
        
        // MARK: Text Colors
        public static let textPrimary = Color("TextPrimary", bundle: .main)
        public static let textSecondary = Color("TextSecondary", bundle: .main)
        public static let textTertiary = Color("TextTertiary", bundle: .main)
        public static let textOnPrimary = Color("TextOnPrimary", bundle: .main)
        public static let textOnSecondary = Color("TextOnSecondary", bundle: .main)
        
        // MARK: Component Colors
        public static let divider = Color("Divider", bundle: .main)
        public static let border = Color("Border", bundle: .main)
        public static let shadow = Color("Shadow", bundle: .main)
        public static let overlay = Color("Overlay", bundle: .main)
        
        // MARK: Golf-Specific Colors (Fallback values for compatibility)
        public static let fairwayGreen = Color(red: 76/255, green: 175/255, blue: 80/255)
        public static let darkGreen = Color(red: 56/255, green: 142/255, blue: 60/255)
        public static let lightGreen = Color(red: 129/255, green: 199/255, blue: 132/255)
        public static let brightGreen = Color(red: 102/255, green: 204/255, blue: 0/255)
        
        // MARK: Score Colors
        public static let eagle = Color(red: 255/255, green: 215/255, blue: 0/255) // Gold
        public static let birdie = Color(red: 76/255, green: 175/255, blue: 80/255) // Green
        public static let par = Color(red: 33/255, green: 150/255, blue: 243/255) // Blue
        public static let bogey = Color(red: 255/255, green: 152/255, blue: 0/255) // Orange
        public static let doubleBogey = Color(red: 244/255, green: 67/255, blue: 54/255) // Red
    }
    
    // MARK: - Typography
    public struct Typography {
        
        // MARK: Font Families
        private static let displayFont = "SF Pro Display"
        private static let textFont = "SF Pro Text"
        private static let roundedFont = "SF Pro Rounded"
        
        // MARK: Title Styles
        public static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        public static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        public static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
        public static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        
        // MARK: Text Styles
        public static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        public static let body = Font.system(size: 17, weight: .regular, design: .default)
        public static let callout = Font.system(size: 16, weight: .regular, design: .default)
        public static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        public static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        public static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        public static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // MARK: Custom Styles
        public static let scoreDisplay = Font.system(size: 48, weight: .heavy, design: .rounded)
        public static let buttonText = Font.system(size: 16, weight: .semibold, design: .default)
        public static let navigationTitle = Font.system(size: 17, weight: .semibold, design: .default)
        
        // MARK: Dynamic Type Support
        public static func dynamicFont(_ style: Font.TextStyle) -> Font {
            Font.system(style)
        }
    }
    
    // MARK: - Spacing
    public enum Spacing: CGFloat {
        case xxxs = 2
        case xxs = 4
        case xs = 8
        case sm = 12
        case md = 16
        case lg = 24
        case xl = 32
        case xxl = 48
        case xxxl = 64
        
        // MARK: Semantic Spacing
        public static let buttonPadding = Spacing.md.rawValue
        public static let cardPadding = Spacing.lg.rawValue
        public static let screenPadding = Spacing.md.rawValue
        public static let itemSpacing = Spacing.sm.rawValue
        public static let sectionSpacing = Spacing.xl.rawValue
        
        // MARK: Grid Spacing
        public static let gridSpacing = Spacing.md.rawValue
        public static let listSpacing = Spacing.xs.rawValue
    }
    
    // MARK: - Corner Radius
    public enum CornerRadius: CGFloat {
        case none = 0
        case xs = 4
        case small = 8
        case medium = 12
        case large = 16
        case xl = 20
        case xxl = 24
        case full = 9999
        
        // MARK: Semantic Radius
        public static let button = CornerRadius.medium.rawValue
        public static let card = CornerRadius.large.rawValue
        public static let sheet = CornerRadius.xl.rawValue
        public static let input = CornerRadius.small.rawValue
        public static let chip = CornerRadius.full.rawValue
    }
    
    // MARK: - Shadows
    public struct Shadows {
        
        // MARK: Shadow Definitions
        public static let subtle = Shadow(
            color: Color.black.opacity(0.04),
            radius: 2,
            x: 0,
            y: 1
        )
        
        public static let regular = Shadow(
            color: Color.black.opacity(0.08),
            radius: 6,
            x: 0,
            y: 3
        )
        
        public static let prominent = Shadow(
            color: Color.black.opacity(0.12),
            radius: 12,
            x: 0,
            y: 6
        )
        
        public static let elevated = Shadow(
            color: Color.black.opacity(0.16),
            radius: 20,
            x: 0,
            y: 10
        )
        
        public struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animations
    public struct Animations {
        
        // MARK: Timing Curves
        public static let easeInOut = Animation.easeInOut(duration: 0.3)
        public static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
        public static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
        public static let springSmooth = Animation.spring(response: 0.3, dampingFraction: 0.9)
        
        // MARK: Durations
        public static let veryFast: Double = 0.15
        public static let fast: Double = 0.25
        public static let regular: Double = 0.35
        public static let slow: Double = 0.5
        public static let verySlow: Double = 0.75
        
        // MARK: Preset Animations
        public static let buttonTap = Animation.spring(response: 0.3, dampingFraction: 0.7)
        public static let cardAppear = Animation.easeOut(duration: 0.4)
        public static let slideTransition = Animation.easeInOut(duration: 0.3)
        public static let fadeTransition = Animation.easeIn(duration: 0.2)
    }
    
    // MARK: - Layout
    public struct Layout {
        
        // MARK: Screen Margins
        public static let screenMargin: CGFloat = 16
        public static let screenMarginCompact: CGFloat = 12
        
        // MARK: Component Heights
        public static let buttonHeight: CGFloat = 48
        public static let buttonHeightSmall: CGFloat = 36
        public static let buttonHeightLarge: CGFloat = 56
        
        public static let inputHeight: CGFloat = 48
        public static let navBarHeight: CGFloat = 44
        public static let tabBarHeight: CGFloat = 49
        
        // MARK: Icon Sizes
        public static let iconSizeXS: CGFloat = 16
        public static let iconSizeSmall: CGFloat = 20
        public static let iconSizeMedium: CGFloat = 24
        public static let iconSizeLarge: CGFloat = 32
        public static let iconSizeXL: CGFloat = 48
        
        // MARK: Grid Layouts
        public static let minCardWidth: CGFloat = 140
        public static let maxCardWidth: CGFloat = 180
        public static let aspectRatio: CGFloat = 1.3
    }
}

// MARK: - View Modifiers

// MARK: Shadow Modifiers
public struct SubtleShadow: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: DesignSystem.Shadows.subtle.color,
                radius: DesignSystem.Shadows.subtle.radius,
                x: DesignSystem.Shadows.subtle.x,
                y: DesignSystem.Shadows.subtle.y
            )
    }
}

public struct RegularShadow: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: DesignSystem.Shadows.regular.color,
                radius: DesignSystem.Shadows.regular.radius,
                x: DesignSystem.Shadows.regular.x,
                y: DesignSystem.Shadows.regular.y
            )
    }
}

public struct ProminentShadow: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: DesignSystem.Shadows.prominent.color,
                radius: DesignSystem.Shadows.prominent.radius,
                x: DesignSystem.Shadows.prominent.x,
                y: DesignSystem.Shadows.prominent.y
            )
    }
}

public struct ElevatedShadow: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: DesignSystem.Shadows.elevated.color,
                radius: DesignSystem.Shadows.elevated.radius,
                x: DesignSystem.Shadows.elevated.x,
                y: DesignSystem.Shadows.elevated.y
            )
    }
}

// MARK: Card Modifier
public struct CardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: DesignSystem.Shadows.Shadow
    
    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: DesignSystem.Shadows.Shadow = DesignSystem.Shadows.regular
    ) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    public func body(content: Content) -> some View {
        content
            .background(DesignSystem.Colors.surface)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: Button Style
public struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.buttonText)
            .foregroundColor(DesignSystem.Colors.textOnPrimary)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .fill(isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DesignSystem.Animations.buttonTap, value: configuration.isPressed)
    }
}

public struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.buttonText)
            .foregroundColor(isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(
                        isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                        lineWidth: 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DesignSystem.Animations.buttonTap, value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    
    // MARK: Shadow Extensions
    public func subtleShadow() -> some View {
        modifier(SubtleShadow())
    }
    
    public func regularShadow() -> some View {
        modifier(RegularShadow())
    }
    
    public func prominentShadow() -> some View {
        modifier(ProminentShadow())
    }
    
    public func elevatedShadow() -> some View {
        modifier(ElevatedShadow())
    }
    
    // MARK: Card Extension
    public func cardStyle(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: DesignSystem.Shadows.Shadow = DesignSystem.Shadows.regular
    ) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, shadow: shadow))
    }
    
    // MARK: Spacing Extensions
    public func spacing(_ spacing: DesignSystem.Spacing) -> some View {
        padding(spacing.rawValue)
    }
    
    public func horizontalSpacing(_ spacing: DesignSystem.Spacing) -> some View {
        padding(.horizontal, spacing.rawValue)
    }
    
    public func verticalSpacing(_ spacing: DesignSystem.Spacing) -> some View {
        padding(.vertical, spacing.rawValue)
    }
}

// MARK: - Gradients
extension DesignSystem.Colors {
    
    public static let primaryGradient = LinearGradient(
        colors: [primary, primaryVariant],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let secondaryGradient = LinearGradient(
        colors: [secondary, secondaryVariant],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let successGradient = LinearGradient(
        colors: [success, success.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let backgroundGradient = LinearGradient(
        colors: [background, surface],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Haptic Feedback Extension
extension View {
    public func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }
}

// MARK: - Adaptive Layout
public struct AdaptiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content
    
    public init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: verticalAlignment, spacing: spacing, content: content)
        } else {
            VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
        }
    }
}