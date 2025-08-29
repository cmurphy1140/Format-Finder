import SwiftUI

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let animation: Animation
    
    init(animation: Animation = .linear(duration: 1.5).repeatForever(autoreverses: false)) {
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 400 - 200)
                .mask(content)
            )
            .onAppear {
                withAnimation(animation) {
                    phase = 1
                }
            }
    }
}

// MARK: - Skeleton View
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(width: width, height: height)
            .modifier(ShimmerEffect())
    }
}

// MARK: - Card Skeleton
struct CardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header skeleton
            HStack {
                SkeletonView(width: 40, height: 40, cornerRadius: 20)
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView(width: 120, height: 16)
                    SkeletonView(width: 80, height: 12)
                }
                Spacer()
            }
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(height: 14)
                SkeletonView(height: 14)
                SkeletonView(width: 200, height: 14)
            }
            
            Spacer()
            
            // Footer skeleton
            HStack {
                SkeletonView(width: 60, height: 24, cornerRadius: 12)
                SkeletonView(width: 60, height: 24, cornerRadius: 12)
                Spacer()
            }
        }
        .padding()
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .scaleEffect(isAnimating ? 1.0 : 0.98)
        .opacity(isAnimating ? 1.0 : 0.8)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: Error
    let onRetry: () -> Void
    
    @State private var bounceOffset: CGFloat = 0
    @State private var iconRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon with animation
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(iconRotation))
                    .offset(y: bounceOffset)
            }
            .onAppear {
                startErrorAnimation()
            }
            
            // Error message
            VStack(spacing: 8) {
                Text("Oops! Something went wrong")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Retry button
            Button(action: {
                handleRetry()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
            }
            .scaleEffect(bounceOffset == 0 ? 1.0 : 1.1)
        }
        .padding()
    }
    
    private func startErrorAnimation() {
        // Icon shake animation
        withAnimation(
            .easeInOut(duration: 0.1)
            .repeatCount(3, autoreverses: true)
        ) {
            iconRotation = 5
        }
        
        // Bounce animation
        withAnimation(
            .interpolatingSpring(stiffness: 200, damping: 10)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -5
        }
    }
    
    private func handleRetry() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Scale animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            bounceOffset = -10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onRetry()
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let action: (() -> Void)?
    
    @State private var parallaxOffset: CGSize = .zero
    @State private var floatOffset: CGFloat = 0
    
    init(
        title: String,
        message: String,
        systemImage: String = "tray",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Illustration with parallax
            ZStack {
                // Background layer
                Circle()
                    .fill(Color.gray.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: parallaxOffset.width * 0.02, y: parallaxOffset.height * 0.02)
                
                // Middle layer
                Circle()
                    .fill(Color.gray.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .offset(x: parallaxOffset.width * 0.04, y: parallaxOffset.height * 0.04)
                
                // Icon layer
                Image(systemName: systemImage)
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.5))
                    .offset(x: parallaxOffset.width * 0.06, y: parallaxOffset.height * 0.06 + floatOffset)
            }
            .onAppear {
                startFloatingAnimation()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        parallaxOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            parallaxOffset = .zero
                        }
                    }
            )
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action button
            if action != nil {
                Button(action: action!) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                }
            }
        }
        .padding()
    }
    
    private func startFloatingAnimation() {
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -10
        }
    }
}

// MARK: - Coached Mark
struct CoachedMark: View {
    let text: String
    let targetFrame: CGRect
    let onDismiss: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var arrowOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Highlight circle
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: targetFrame.width + 20, height: targetFrame.height + 20)
                .position(x: targetFrame.midX, y: targetFrame.midY)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulseScale = 1.1
                    }
                }
            
            // Instruction bubble
            VStack(spacing: 8) {
                // Arrow pointing to target
                Image(systemName: "arrow.down")
                    .font(.title)
                    .foregroundColor(.white)
                    .offset(y: arrowOffset)
                
                // Instruction text
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                    )
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Got it!")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
            }
            .position(x: targetFrame.midX, y: targetFrame.minY - 100)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    arrowOffset = 10
                }
            }
        }
    }
}

// MARK: - Loading State Manager
class LoadingStateManager: ObservableObject {
    enum LoadingState {
        case idle
        case loading
        case loaded
        case error(Error)
        case empty
    }
    
    @Published var state: LoadingState = .idle
    @Published var showCoachMarks = false
    @Published var currentCoachMark: Int = 0
    
    let coachMarks = [
        "Swipe down to refresh content",
        "Tap cards to see more details",
        "Long press for quick preview"
    ]
    
    func startLoading() {
        state = .loading
    }
    
    func finishLoading(isEmpty: Bool = false) {
        state = isEmpty ? .empty : .loaded
        
        // Show coach marks for first-time users
        if !UserDefaults.standard.bool(forKey: "hasSeenCoachMarks") {
            showCoachMarks = true
        }
    }
    
    func handleError(_ error: Error) {
        state = .error(error)
    }
    
    func nextCoachMark() {
        if currentCoachMark < coachMarks.count - 1 {
            currentCoachMark += 1
        } else {
            dismissCoachMarks()
        }
    }
    
    func dismissCoachMarks() {
        showCoachMarks = false
        UserDefaults.standard.set(true, forKey: "hasSeenCoachMarks")
    }
}

// MARK: - View Extensions
extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    func skeleton(width: CGFloat? = nil, height: CGFloat = 20) -> some View {
        overlay(
            SkeletonView(width: width, height: height)
        )
    }
}