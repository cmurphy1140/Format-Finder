import SwiftUI

// MARK: - App Color Theme

struct AppColors {
    // Light, Modern Color Palette
    static let primaryGreen = Color(red: 76/255, green: 175/255, blue: 80/255)  // Material Green 500
    static let lightGreen = Color(red: 129/255, green: 199/255, blue: 132/255)  // Material Green 300
    static let darkGreen = Color(red: 56/255, green: 142/255, blue: 60/255)     // Material Green 700
    
    // Background Colors
    static let backgroundPrimary = Color(red: 248/255, green: 250/255, blue: 252/255)  // Very light gray-blue
    static let backgroundSecondary = Color.white
    static let backgroundTertiary = Color(red: 245/255, green: 247/255, blue: 250/255)
    
    // Accent Colors
    static let accentBlue = Color(red: 33/255, green: 150/255, blue: 243/255)    // Material Blue 500
    static let accentOrange = Color(red: 255/255, green: 152/255, blue: 0/255)   // Material Orange 500
    static let accentPurple = Color(red: 156/255, green: 39/255, blue: 176/255)  // Material Purple 500
    
    // Text Colors
    static let textPrimary = Color(red: 33/255, green: 37/255, blue: 41/255)     // Dark gray
    static let textSecondary = Color(red: 108/255, green: 117/255, blue: 125/255) // Medium gray
    static let textTertiary = Color(red: 173/255, green: 181/255, blue: 189/255)  // Light gray
    
    // Surface Colors
    static let cardBackground = Color.white
    static let cardShadow = Color.black.opacity(0.08)
    
    // Gradients
    static let lightGradient = LinearGradient(
        colors: [
            Color(red: 240/255, green: 249/255, blue: 240/255),  // Very light green tint
            Color(red: 245/255, green: 250/255, blue: 245/255)   // Almost white with green hint
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let headerGradient = LinearGradient(
        colors: [
            primaryGreen,
            lightGreen
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [
            Color.white,
            Color(red: 252/255, green: 254/255, blue: 252/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View Extensions

extension View {
    func appCardStyle() -> some View {
        self
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 2)
    }
    
    func lightCardStyle() -> some View {
        self
            .background(AppColors.cardGradient)
            .cornerRadius(12)
            .shadow(color: AppColors.cardShadow, radius: 4, x: 0, y: 1)
    }
}