import SwiftUI
import UIKit

// MARK: - Masters Tournament-Inspired Design System
// Professional golf app design system inspired by the prestigious Masters Tournament aesthetic

// MARK: - Color Palette
struct MastersColors {
    // Primary Colors - Augusta National Palette
    static let mastersGreen = Color(hex: "006747")        // Official Masters/Augusta green
    static let augustaGold = Color(hex: "FFD700")         // Tournament gold
    static let azaleaWhite = Color(hex: "FFFFFF")         // Clean white
    static let magnoliaLane = Color(hex: "F8F8F5")        // Off-white/cream
    
    // Supporting Colors
    static let pineFrost = Color(hex: "E8F5E9")           // Light green tint
    static let shadowGreen = Color(hex: "004D35")         // Deep green for emphasis
    static let fairwayMist = Color(hex: "F0F7F2")         // Very light green background
    static let scoreRed = Color(hex: "C41E3A")            // Traditional scorecard red
    static let eagleGold = Color(hex: "FFC107")           // Bright gold for achievements
    
    // Neutral Tones
    static let slate = Color(hex: "2C3E50")               // Dark text
    static let graphite = Color(hex: "34495E")            // Headers
    static let silver = Color(hex: "95A5A6")              // Secondary text
    static let pearl = Color(hex: "ECF0F1")               // Borders/dividers
    static let fog = Color(hex: "BDC3C7")                 // Disabled states
    
    // Semantic Colors
    static let birdie = Color(hex: "4CAF50")              // Under par
    static let par = Color(hex: "2196F3")                 // Par score
    static let bogey = Color(hex: "FF9800")               // Over par
    static let doubleBogey = Color(hex: "F44336")         // Significantly over par
    
    // Background Gradients
    static let morningMist = LinearGradient(
        colors: [fairwayMist, azaleaWhite],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let augustaSunset = LinearGradient(
        colors: [mastersGreen.opacity(0.1), augustaGold.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography System
struct MastersTypography {
    // Custom font names (fallback to system if not available)
    static let serifDisplay = "Georgia"          // Elegant serif for headers
    static let serifBody = "Baskerville"         // Classic serif for special text
    static let sansBody = "SF Pro Display"       // Clean sans for data
    static let sansText = "SF Pro Text"          // Readable sans for body
    
    // Font Styles
    static func heroTitle() -> Font {
        Font.custom(serifDisplay, size: 42)
            .weight(.light)
    }
    
    static func displayTitle() -> Font {
        Font.custom(serifDisplay, size: 34)
            .weight(.regular)
    }
    
    static func sectionHeader() -> Font {
        Font.custom(serifDisplay, size: 28)
            .weight(.medium)
    }
    
    static func cardTitle() -> Font {
        Font.custom(serifBody, size: 22)
            .weight(.medium)
    }
    
    static func dataLabel() -> Font {
        Font.custom(sansBody, size: 17)
            .weight(.semibold)
    }
    
    static func bodyText() -> Font {
        Font.custom(sansText, size: 16)
            .weight(.regular)
    }
    
    static func scoreDisplay() -> Font {
        Font.custom(sansBody, size: 24)
            .weight(.bold)
    }
    
    static func captionText() -> Font {
        Font.custom(sansText, size: 13)
            .weight(.regular)
    }
    
    static func microText() -> Font {
        Font.custom(sansText, size: 11)
            .weight(.medium)
    }
}

// MARK: - Layout Constants
struct MastersLayout {
    // Spacing
    static let microSpacing: CGFloat = 4
    static let tinySpacing: CGFloat = 8
    static let smallSpacing: CGFloat = 12
    static let standardSpacing: CGFloat = 16
    static let mediumSpacing: CGFloat = 20
    static let largeSpacing: CGFloat = 24
    static let xLargeSpacing: CGFloat = 32
    static let heroSpacing: CGFloat = 48
    
    // Corner Radius
    static let smallRadius: CGFloat = 6
    static let standardRadius: CGFloat = 10
    static let cardRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    
    // Component Sizes
    static let buttonHeight: CGFloat = 52
    static let tabBarHeight: CGFloat = 88
    static let navigationBarHeight: CGFloat = 96
    static let scoreCardCellHeight: CGFloat = 56
    static let leaderboardRowHeight: CGFloat = 72
    
    // Content Width
    static let maxContentWidth: CGFloat = 428  // iPhone 14 Pro Max width
    static let compactWidth: CGFloat = 375     // Standard iPhone width
    
    // Shadows
    static let cardShadow = Shadow(
        color: Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 2
    )
    
    static let elevatedShadow = Shadow(
        color: Color.black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 4
    )
}

// MARK: - Component Styles
struct MastersComponentStyles {
    
    // MARK: Card Style
    struct CardStyle: ViewModifier {
        let elevated: Bool
        
        func body(content: Content) -> some View {
            content
                .background(MastersColors.azaleaWhite)
                .cornerRadius(MastersLayout.cardRadius)
                .shadow(
                    color: elevated ? MastersLayout.elevatedShadow.color : MastersLayout.cardShadow.color,
                    radius: elevated ? MastersLayout.elevatedShadow.radius : MastersLayout.cardShadow.radius,
                    x: elevated ? MastersLayout.elevatedShadow.x : MastersLayout.cardShadow.x,
                    y: elevated ? MastersLayout.elevatedShadow.y : MastersLayout.cardShadow.y
                )
        }
    }
    
    // MARK: Primary Button Style
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(MastersTypography.dataLabel())
                .foregroundColor(.white)
                .frame(height: MastersLayout.buttonHeight)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: MastersLayout.standardRadius)
                        .fill(MastersColors.mastersGreen)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    // MARK: Secondary Button Style
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(MastersTypography.dataLabel())
                .foregroundColor(MastersColors.mastersGreen)
                .frame(height: MastersLayout.buttonHeight)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: MastersLayout.standardRadius)
                        .stroke(MastersColors.mastersGreen, lineWidth: 2)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    // MARK: Score Display Style
    struct ScoreDisplayStyle: ViewModifier {
        let score: Int
        let par: Int
        
        var scoreColor: Color {
            if score < par { return MastersColors.birdie }
            else if score == par { return MastersColors.par }
            else if score == par + 1 { return MastersColors.bogey }
            else { return MastersColors.doubleBogey }
        }
        
        func body(content: Content) -> some View {
            content
                .font(MastersTypography.scoreDisplay())
                .foregroundColor(scoreColor)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(scoreColor.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - View Extensions
extension View {
    func mastersCard(elevated: Bool = false) -> some View {
        self.modifier(MastersComponentStyles.CardStyle(elevated: elevated))
    }
    
    func mastersScoreDisplay(score: Int, par: Int) -> some View {
        self.modifier(MastersComponentStyles.ScoreDisplayStyle(score: score, par: par))
    }
}

// MARK: - Navigation Components
struct MastersNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    var body: some View {
        HStack(spacing: MastersLayout.standardSpacing) {
            if showBackButton {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(MastersColors.mastersGreen)
                }
            }
            
            Text(title)
                .font(MastersTypography.sectionHeader())
                .foregroundColor(MastersColors.graphite)
            
            Spacer()
        }
        .padding(.horizontal, MastersLayout.standardSpacing)
        .padding(.vertical, MastersLayout.smallSpacing)
        .background(MastersColors.azaleaWhite)
    }
}

// MARK: - Tab Bar
struct MastersTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        ("house.fill", "Home"),
        ("flag.fill", "Formats"),
        ("square.grid.3x3.fill", "Scorecard"),
        ("chart.bar.fill", "Stats"),
        ("person.fill", "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].0)
                            .font(.system(size: 22))
                        Text(tabs[index].1)
                            .font(MastersTypography.microText())
                    }
                    .foregroundColor(selectedTab == index ? MastersColors.mastersGreen : MastersColors.fog)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, MastersLayout.tinySpacing)
        .padding(.bottom, MastersLayout.mediumSpacing)
        .background(
            MastersColors.azaleaWhite
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 1,
                    x: 0,
                    y: -1
                )
        )
    }
}

// MARK: - Leaderboard Row Component
struct MastersLeaderboardRow: View {
    let position: Int
    let player: String
    let score: String
    let thru: String
    let isLeader: Bool
    
    var body: some View {
        HStack(spacing: MastersLayout.standardSpacing) {
            // Position
            Text("\(position)")
                .font(MastersTypography.dataLabel())
                .foregroundColor(isLeader ? MastersColors.augustaGold : MastersColors.graphite)
                .frame(width: 40, alignment: .center)
            
            // Player Name
            VStack(alignment: .leading, spacing: 2) {
                Text(player)
                    .font(MastersTypography.dataLabel())
                    .foregroundColor(MastersColors.slate)
                
                if isLeader {
                    Text("LEADER")
                        .font(MastersTypography.microText())
                        .foregroundColor(MastersColors.augustaGold)
                }
            }
            
            Spacer()
            
            // Through
            Text(thru)
                .font(MastersTypography.captionText())
                .foregroundColor(MastersColors.silver)
            
            // Score
            Text(score)
                .font(MastersTypography.scoreDisplay())
                .foregroundColor(scoreColor(for: score))
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, MastersLayout.standardSpacing)
        .padding(.vertical, MastersLayout.smallSpacing)
        .background(
            isLeader ? MastersColors.pineFrost : Color.clear
        )
    }
    
    func scoreColor(for score: String) -> Color {
        if score.contains("-") { return MastersColors.birdie }
        else if score == "E" { return MastersColors.par }
        else { return MastersColors.bogey }
    }
}

// MARK: - Scorecard Cell
struct MastersScorecardCell: View {
    let hole: Int
    let par: Int
    let yards: Int
    @Binding var score: String
    
    var body: some View {
        HStack(spacing: MastersLayout.standardSpacing) {
            // Hole Number
            VStack(spacing: 2) {
                Text("HOLE")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
                Text("\(hole)")
                    .font(MastersTypography.dataLabel())
                    .foregroundColor(MastersColors.graphite)
            }
            .frame(width: 50)
            
            Divider()
                .frame(height: 40)
            
            // Par & Yards
            VStack(alignment: .leading, spacing: 2) {
                Text("PAR \(par)")
                    .font(MastersTypography.captionText())
                    .foregroundColor(MastersColors.slate)
                Text("\(yards) YDS")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
            }
            
            Spacer()
            
            // Score Input
            TextField("—", text: $score)
                .font(MastersTypography.scoreDisplay())
                .multilineTextAlignment(.center)
                .frame(width: 60, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: MastersLayout.smallRadius)
                        .fill(MastersColors.fairwayMist)
                        .overlay(
                            RoundedRectangle(cornerRadius: MastersLayout.smallRadius)
                                .stroke(MastersColors.pearl, lineWidth: 1)
                        )
                )
                .keyboardType(.numberPad)
        }
        .padding(.horizontal, MastersLayout.standardSpacing)
        .padding(.vertical, MastersLayout.tinySpacing)
        .background(MastersColors.azaleaWhite)
    }
}

// Note: Color(hex:) extension is already defined in ThemeEngine.swift

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}