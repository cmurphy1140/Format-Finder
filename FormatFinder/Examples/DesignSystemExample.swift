import SwiftUI

// MARK: - Design System Usage Examples
// This file demonstrates how to use the new Design System

struct DesignSystemExample: View {
    @State private var showAlert = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
                
                // MARK: - Typography Examples
                typographySection
                
                // MARK: - Color Examples
                colorSection
                
                // MARK: - Spacing Examples
                spacingSection
                
                // MARK: - Button Examples
                buttonSection
                
                // MARK: - Card Examples
                cardSection
                
                // MARK: - Shadow Examples
                shadowSection
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Design System")
    }
    
    // MARK: - Typography Section
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.itemSpacing) {
            Text("Typography")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Large Title")
                .font(DesignSystem.Typography.largeTitle)
            
            Text("Title 1")
                .font(DesignSystem.Typography.title1)
            
            Text("Title 2")
                .font(DesignSystem.Typography.title2)
            
            Text("Headline")
                .font(DesignSystem.Typography.headline)
            
            Text("Body Text")
                .font(DesignSystem.Typography.body)
            
            Text("Caption")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Color Section
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.itemSpacing) {
            Text("Colors")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.itemSpacing) {
                ColorSwatch(color: DesignSystem.Colors.primary, label: "Primary")
                ColorSwatch(color: DesignSystem.Colors.secondary, label: "Secondary")
                ColorSwatch(color: DesignSystem.Colors.success, label: "Success")
                ColorSwatch(color: DesignSystem.Colors.warning, label: "Warning")
                ColorSwatch(color: DesignSystem.Colors.error, label: "Error")
            }
            
            // Score Colors
            HStack(spacing: DesignSystem.Spacing.itemSpacing) {
                ScoreBadge(score: "Eagle", color: DesignSystem.Colors.eagle)
                ScoreBadge(score: "Birdie", color: DesignSystem.Colors.birdie)
                ScoreBadge(score: "Par", color: DesignSystem.Colors.par)
                ScoreBadge(score: "Bogey", color: DesignSystem.Colors.bogey)
            }
        }
    }
    
    // MARK: - Spacing Section
    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.itemSpacing) {
            Text("Spacing")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: 0) {
                SpacingExample(spacing: .xxs, label: "XXS (4pt)")
                SpacingExample(spacing: .xs, label: "XS (8pt)")
                SpacingExample(spacing: .sm, label: "SM (12pt)")
                SpacingExample(spacing: .md, label: "MD (16pt)")
                SpacingExample(spacing: .lg, label: "LG (24pt)")
                SpacingExample(spacing: .xl, label: "XL (32pt)")
            }
        }
    }
    
    // MARK: - Button Section
    private var buttonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.itemSpacing) {
            Text("Buttons")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Button("Primary Button") {
                showAlert = true
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button("Secondary Button") {
                showAlert = true
            }
            .buttonStyle(SecondaryButtonStyle())
            
            HStack(spacing: DesignSystem.Spacing.itemSpacing) {
                Button("Cancel") {
                    // Action
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Confirm") {
                    // Action
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
    
    // MARK: - Card Section
    private var cardSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.itemSpacing) {
            Text("Cards")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Simple Card
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Format: Stroke Play")
                    .font(DesignSystem.Typography.headline)
                Text("Traditional scoring format where total strokes count")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.cardPadding)
            .cardStyle()
            
            // Interactive Card
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Hole 9")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("Par 4")
                        .font(DesignSystem.Typography.headline)
                }
                
                Spacer()
                
                Text("3")
                    .font(DesignSystem.Typography.scoreDisplay)
                    .foregroundColor(DesignSystem.Colors.birdie)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .cardStyle(shadow: DesignSystem.Shadows.prominent)
        }
    }
    
    // MARK: - Shadow Section
    private var shadowSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Shadows")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                Rectangle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 80, height: 80)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .subtleShadow()
                    .overlay(
                        Text("Subtle")
                            .font(DesignSystem.Typography.caption1)
                    )
                
                Rectangle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 80, height: 80)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .regularShadow()
                    .overlay(
                        Text("Regular")
                            .font(DesignSystem.Typography.caption1)
                    )
                
                Rectangle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 80, height: 80)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .prominentShadow()
                    .overlay(
                        Text("Prominent")
                            .font(DesignSystem.Typography.caption1)
                    )
            }
        }
    }
}

// MARK: - Helper Views

struct ColorSwatch: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(color)
                .frame(width: 60, height: 60)
                .regularShadow()
            
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct ScoreBadge: View {
    let score: String
    let color: Color
    
    var body: some View {
        Text(score)
            .font(DesignSystem.Typography.caption1)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

struct SpacingExample: View {
    let spacing: DesignSystem.Spacing
    let label: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 80)
            
            Rectangle()
                .fill(DesignSystem.Colors.primary.opacity(0.3))
                .frame(width: spacing.rawValue, height: 20)
            
            Rectangle()
                .fill(DesignSystem.Colors.primary)
                .frame(width: 100, height: 20)
                .cornerRadius(4)
        }
    }
}

// MARK: - Real-World Component Example

struct ScoreCardRow: View {
    let hole: Int
    let par: Int
    @State private var score: Int = 0
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Hole Number
            Text("Hole \(hole)")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(width: 80, alignment: .leading)
            
            // Par
            VStack(spacing: 2) {
                Text("PAR")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                Text("\(par)")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            // Score Input
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button {
                    if score > 0 { score -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: DesignSystem.Layout.iconSizeLarge))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Text(score == 0 ? "—" : "\(score)")
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(scoreColor)
                    .frame(width: 50)
                
                Button {
                    if score < 10 { score += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: DesignSystem.Layout.iconSizeLarge))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
        .animation(DesignSystem.Animations.spring, value: score)
    }
    
    private var scoreColor: Color {
        guard score > 0 else { return DesignSystem.Colors.textTertiary }
        let diff = score - par
        switch diff {
        case ..<(-1): return DesignSystem.Colors.eagle
        case -1: return DesignSystem.Colors.birdie
        case 0: return DesignSystem.Colors.par
        case 1: return DesignSystem.Colors.bogey
        default: return DesignSystem.Colors.doubleBogey
        }
    }
}

// MARK: - Preview
struct DesignSystemExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DesignSystemExample()
        }
        .preferredColorScheme(.light)
        
        NavigationView {
            DesignSystemExample()
        }
        .preferredColorScheme(.dark)
    }
}