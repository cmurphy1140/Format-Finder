import SwiftUI

// MARK: - Loading States
struct LoadingView: View {
    @State private var isAnimating = false
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            Text(message)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Skeleton Loading
struct SkeletonView: View {
    @State private var shimmer = false
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: shimmer ? .leading : .trailing,
                    endPoint: shimmer ? .trailing : .leading
                )
            )
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: shimmer)
            .onAppear {
                shimmer = true
            }
    }
}

// MARK: - Haptic Feedback Button
struct HapticButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    init(
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.hapticStyle = hapticStyle
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(hapticStyle)
            action()
        }) {
            label()
        }
    }
}

// MARK: - Interactive Card
struct InteractiveCard<Content: View>: View {
    @State private var isPressed = false
    @State private var isDragging = false
    
    let content: () -> Content
    let action: () -> Void
    
    var body: some View {
        content()
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isDragging ? 0.8 : 1.0)
            .rotation3DEffect(
                .degrees(isDragging ? 5 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            .onTapGesture {
                HapticManager.shared.impact(.light)
                action()
            }
            .onLongPressGesture(
                minimumDuration: 0.1,
                maximumDistance: .infinity,
                pressing: { pressing in
                    isPressed = pressing
                },
                perform: {}
            )
            .gesture(
                DragGesture()
                    .onChanged { _ in
                        if !isDragging {
                            isDragging = true
                            HapticManager.shared.impact(.medium)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}

// MARK: - Success/Error Feedback
struct FeedbackOverlay: View {
    enum FeedbackType {
        case success
        case error
        case warning
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
    }
    
    let type: FeedbackType
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(type.color)
                    
                    Text(message)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .shadow(radius: 10)
                )
                .padding()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .onAppear {
                    HapticManager.shared.notification(
                        type == .success ? .success :
                        type == .error ? .error : .warning
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isShowing)
    }
}

// MARK: - Pull to Refresh
struct PullToRefresh: ViewModifier {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                await action()
            }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                
                Text(description)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    action()
                }) {
                    Text(actionTitle)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(40)
    }
}

// MARK: - Animated Transition
struct AnimatedTransition: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    init(delay: Double = 0) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func animatedTransition(delay: Double = 0) -> some View {
        modifier(AnimatedTransition(delay: delay))
    }
    
    func pullToRefresh(isRefreshing: Binding<Bool>, action: @escaping () async -> Void) -> some View {
        modifier(PullToRefresh(isRefreshing: isRefreshing, action: action))
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    let pages: [(icon: String, title: String, description: String)] = [
        ("sportscourt", "Welcome to Format Finder", "Discover exciting golf game formats for your next round"),
        ("magnifyingglass", "Browse Formats", "Explore tournament and betting formats with detailed rules"),
        ("bookmark.fill", "Save Favorites", "Bookmark your favorite formats for quick access"),
        ("play.circle.fill", "Interactive Guides", "Learn with step-by-step visual demonstrations")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 30) {
                        Image(systemName: pages[index].icon)
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .padding(.top, 100)
                        
                        VStack(spacing: 16) {
                            Text(pages[index].title)
                                .font(.system(.title, design: .rounded, weight: .bold))
                            
                            Text(pages[index].description)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            HStack(spacing: 20) {
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        HapticManager.shared.impact(.light)
                        withAnimation {
                            showOnboarding = false
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.impact(.light)
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        withAnimation {
                            showOnboarding = false
                        }
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemBackground))
    }
}