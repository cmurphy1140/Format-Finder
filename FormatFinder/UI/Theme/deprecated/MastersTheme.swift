import SwiftUI

// MARK: - Masters App Color Palette
struct MastersColors {
    // Primary Masters Green
    static let augustaGreen = Color(red: 0/255, green: 106/255, blue: 78/255)
    static let darkGreen = Color(red: 0/255, green: 51/255, blue: 25/255)
    static let lightGreen = Color(red: 124/255, green: 169/255, blue: 85/255)
    static let fairwayGreen = Color(red: 87/255, green: 138/255, blue: 52/255)
    
    // Accent Colors
    static let azaleaPink = Color(red: 216/255, green: 27/255, blue: 96/255)
    static let magnoliaWhite = Color(red: 255/255, green: 255/255, blue: 250/255)
    static let sandBunker = Color(red: 244/255, green: 238/255, blue: 224/255)
    static let skyBlue = Color(red: 135/255, green: 206/255, blue: 235/255)
    
    // UI Colors
    static let cardBackground = Color(red: 250/255, green: 250/255, blue: 245/255)
    static let textPrimary = Color(red: 0/255, green: 51/255, blue: 25/255)
    static let textSecondary = Color(red: 87/255, green: 138/255, blue: 52/255)
    static let divider = Color(red: 200/255, green: 200/255, blue: 190/255).opacity(0.3)
    
    // Status Colors
    static let birdie = Color(red: 220/255, green: 20/255, blue: 60/255)
    static let eagle = Color(red: 255/255, green: 215/255, blue: 0/255)
    static let par = augustaGreen
    static let bogey = Color(red: 70/255, green: 130/255, blue: 180/255)
}

// MARK: - Masters Typography
struct MastersTypography {
    static func applyMastersFont() -> Font {
        // Masters uses a custom serif font similar to Georgia
        return Font.custom("Georgia", size: 16)
    }
    
    static let largeTitle = Font.custom("Georgia-Bold", size: 34)
    static let title = Font.custom("Georgia-Bold", size: 28)
    static let title2 = Font.custom("Georgia", size: 22)
    static let title3 = Font.custom("Georgia", size: 20)
    static let headline = Font.custom("Georgia-Bold", size: 17)
    static let body = Font.custom("Georgia", size: 17)
    static let callout = Font.custom("Georgia", size: 16)
    static let subheadline = Font.custom("Georgia", size: 15)
    static let footnote = Font.custom("Georgia", size: 13)
    static let caption = Font.custom("Georgia", size: 12)
    static let caption2 = Font.custom("Georgia", size: 11)
}

// MARK: - Masters Style View Modifiers
struct MastersCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(MastersColors.cardBackground)
            .cornerRadius(0) // Masters uses sharp corners
            .overlay(
                Rectangle()
                    .stroke(MastersColors.divider, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MastersButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MastersTypography.callout)
            .foregroundColor(isPrimary ? MastersColors.magnoliaWhite : MastersColors.augustaGreen)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isPrimary ? MastersColors.augustaGreen : MastersColors.magnoliaWhite)
                    .overlay(
                        Rectangle()
                            .stroke(MastersColors.augustaGreen, lineWidth: isPrimary ? 0 : 2)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Loading & Empty States
struct MastersEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(MastersColors.lightGreen)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(MastersTypography.title3)
                    .foregroundColor(MastersColors.textPrimary)
                
                Text(message)
                    .font(MastersTypography.body)
                    .foregroundColor(MastersColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(MastersButtonStyle(isPrimary: true))
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MastersColors.magnoliaWhite)
    }
}

struct MastersSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(MastersColors.divider)
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    MastersColors.divider,
                                    MastersColors.magnoliaWhite.opacity(0.8),
                                    MastersColors.divider
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Masters Navigation Bar
struct MastersNavigationBar: View {
    let title: String
    let showBack: Bool
    let onBack: (() -> Void)?
    
    var body: some View {
        HStack {
            if showBack {
                Button(action: { onBack?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(MastersTypography.callout)
                    }
                    .foregroundColor(MastersColors.augustaGreen)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(MastersTypography.headline)
                .foregroundColor(MastersColors.textPrimary)
            
            Spacer()
            
            if showBack {
                // Balance the back button
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(MastersTypography.callout)
                }
                .opacity(0)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(MastersColors.magnoliaWhite)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(MastersColors.divider),
            alignment: .bottom
        )
    }
}

// MARK: - Masters Tab Bar
struct MastersTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    @State private var bounceAnimation = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .scaleEffect(bounceAnimation ? 1.2 : 1.0)
            
            Text(title)
                .font(MastersTypography.caption2)
        }
        .foregroundColor(isSelected ? MastersColors.augustaGreen : MastersColors.textSecondary)
        .onChange(of: isSelected) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    bounceAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    bounceAnimation = false
                }
            }
        }
    }
}

// MARK: - Pull to Refresh
struct MastersPullToRefresh: ViewModifier {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                await action()
            }
            .overlay(
                Group {
                    if isRefreshing {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: MastersColors.augustaGreen))
                                .padding()
                            Spacer()
                        }
                    }
                }
            )
    }
}

// MARK: - Swipe Actions
struct MastersSwipeAction: ViewModifier {
    let onDelete: () -> Void
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(MastersColors.birdie)
            }
    }
}

// MARK: - Long Press Preview
struct MastersLongPressPreview: ViewModifier {
    @State private var isShowingPreview = false
    let previewContent: AnyView
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                withAnimation {
                    isShowingPreview = true
                }
            }
            .popover(isPresented: $isShowingPreview) {
                previewContent
                    .frame(width: 300, height: 400)
            }
    }
}

// MARK: - Extension helpers
extension View {
    func mastersCard() -> some View {
        modifier(MastersCardStyle())
    }
    
    func mastersPullToRefresh(isRefreshing: Binding<Bool>, action: @escaping () async -> Void) -> some View {
        modifier(MastersPullToRefresh(isRefreshing: isRefreshing, action: action))
    }
    
    func mastersSwipeToDelete(onDelete: @escaping () -> Void) -> some View {
        modifier(MastersSwipeAction(onDelete: onDelete))
    }
    
    func mastersLongPressPreview(_ preview: AnyView) -> some View {
        modifier(MastersLongPressPreview(previewContent: preview))
    }
}