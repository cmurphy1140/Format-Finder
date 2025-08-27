import SwiftUI

// MARK: - App Icon Design View

struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Light gradient background
            LinearGradient(
                colors: [
                    Color(red: 240/255, green: 255/255, blue: 240/255),  // Very light mint
                    Color(red: 220/255, green: 245/255, blue: 220/255)   // Light green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Golf ball pattern in background
            GeometryReader { geometry in
                ZStack {
                    // Golf ball
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 245/255, green: 245/255, blue: 245/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size * 0.5, height: size * 0.5)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .offset(x: size * 0.25, y: -size * 0.15)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 2, y: 4)
                    
                    // Golf flag
                    ZStack(alignment: .topLeading) {
                        // Flag pole
                        Rectangle()
                            .fill(Color(red: 80/255, green: 80/255, blue: 80/255))
                            .frame(width: size * 0.02, height: size * 0.6)
                        
                        // Flag
                        Path { path in
                            path.move(to: CGPoint(x: size * 0.02, y: 0))
                            path.addLine(to: CGPoint(x: size * 0.35, y: size * 0.08))
                            path.addLine(to: CGPoint(x: size * 0.32, y: size * 0.16))
                            path.addLine(to: CGPoint(x: size * 0.02, y: size * 0.12))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 255/255, green: 87/255, blue: 34/255),   // Deep orange
                                    Color(red: 255/255, green: 152/255, blue: 0/255)    // Orange
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 4, x: 2, y: 2)
                    }
                    .offset(x: size * 0.3, y: size * 0.2)
                    
                    // Green/fairway shape at bottom
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: size * 0.65))
                        path.addQuadCurve(
                            to: CGPoint(x: size, y: size * 0.65),
                            control: CGPoint(x: size * 0.5, y: size * 0.55)
                        )
                        path.addLine(to: CGPoint(x: size, y: size))
                        path.addLine(to: CGPoint(x: 0, y: size))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 76/255, green: 175/255, blue: 80/255),
                                Color(red: 56/255, green: 142/255, blue: 60/255)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Format text
                    VStack {
                        Spacer()
                        Text("FF")
                            .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    }
                    .padding(.bottom, size * 0.08)
                }
                .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.2237) // iOS app icon corner radius
    }
}

// MARK: - App Icon Generator

struct ViewAppIconGenerator: View {
    var body: some View {
        VStack(spacing: 20) {
            // 1024x1024 App Store Icon
            AppIconView(size: 1024)
                .frame(width: 1024, height: 1024)
            
            // Display preview at different sizes
            HStack(spacing: 20) {
                AppIconView(size: 180)
                    .frame(width: 180, height: 180)
                
                AppIconView(size: 120)
                    .frame(width: 120, height: 120)
                
                AppIconView(size: 60)
                    .frame(width: 60, height: 60)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Preview

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        ViewAppIconGenerator()
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}