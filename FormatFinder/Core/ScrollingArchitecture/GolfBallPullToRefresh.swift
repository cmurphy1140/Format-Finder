import SwiftUI
import Combine

// MARK: - Golf Ball Pull to Refresh
struct GolfBallPullToRefresh: View {
    @Binding var isRefreshing: Bool
    @State private var pullProgress: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var ballScale: CGFloat = 1.0
    @State private var showSuccess = false
    @State private var showError = false
    @State private var elasticOffset: CGFloat = 0
    
    let onRefresh: () async -> Bool
    
    private let threshold: CGFloat = 80
    private let maxPull: CGFloat = 150
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Elastic background
                ElasticStretchView(offset: elasticOffset)
                    .frame(height: max(0, elasticOffset))
                    .offset(y: -elasticOffset)
                
                // Golf ball spinner
                VStack {
                    ZStack {
                        // Shadow
                        Ellipse()
                            .fill(Color.black.opacity(0.2))
                            .frame(width: 50 * ballScale, height: 10)
                            .offset(y: 25)
                            .blur(radius: 5)
                        
                        // Golf ball
                        GolfBallView(rotation: rotation)
                            .frame(width: 50, height: 50)
                            .scaleEffect(ballScale)
                            .rotationEffect(.degrees(rotation))
                        
                        // Success/Error indicators
                        if showSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        } else if showError {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    // Status text
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(pullProgress > 0.3 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: pullProgress)
                }
                .offset(y: calculateBallOffset())
                .opacity(pullProgress > 0 ? 1 : 0)
            }
        }
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                startRefreshing()
            }
        }
    }
    
    private var statusText: String {
        if isRefreshing {
            return "Loading..."
        } else if pullProgress >= 1.0 {
            return "Release to refresh"
        } else if pullProgress > 0.3 {
            return "Pull to refresh"
        }
        return ""
    }
    
    private func calculateBallOffset() -> CGFloat {
        let baseOffset: CGFloat = 20
        let pullOffset = min(pullProgress * threshold, maxPull)
        return baseOffset + pullOffset + elasticOffset * 0.3
    }
    
    func handlePull(offset: CGFloat) {
        guard !isRefreshing else { return }
        
        elasticOffset = calculateElasticOffset(from: offset)
        pullProgress = min(max(offset / threshold, 0), 1.5)
        
        // Rotate ball based on pull
        if pullProgress > 0 {
            rotation = Double(offset * 2)
        }
        
        // Scale effect at threshold
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            ballScale = pullProgress >= 1.0 ? 1.2 : 1.0
        }
        
        // Haptic feedback at threshold
        if pullProgress >= 1.0 && pullProgress < 1.05 {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    func handleRelease() {
        if pullProgress >= 1.0 && !isRefreshing {
            triggerRefresh()
        } else {
            reset()
        }
    }
    
    private func calculateElasticOffset(from pull: CGFloat) -> CGFloat {
        let resistance: CGFloat = 0.5
        let maxElastic: CGFloat = 100
        
        if pull <= threshold {
            return pull
        } else {
            let overpull = pull - threshold
            let elasticPull = threshold + (overpull * resistance)
            return min(elasticPull, maxElastic)
        }
    }
    
    private func triggerRefresh() {
        isRefreshing = true
        
        // Start spinning animation
        withAnimation(
            .linear(duration: 1)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
        
        // Perform refresh
        Task {
            let success = await onRefresh()
            await handleRefreshComplete(success: success)
        }
    }
    
    @MainActor
    private func handleRefreshComplete(success: Bool) {
        // Stop spinning
        withAnimation(.easeOut(duration: 0.3)) {
            rotation = 0
        }
        
        // Show result
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if success {
                showSuccess = true
            } else {
                showError = true
            }
        }
        
        // Haptic feedback
        let notification = UINotificationFeedbackGenerator()
        if success {
            notification.notificationOccurred(.success)
        } else {
            notification.notificationOccurred(.error)
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            reset()
        }
    }
    
    private func startRefreshing() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            pullProgress = 1.0
            elasticOffset = threshold
        }
        
        withAnimation(
            .linear(duration: 1)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
    }
    
    private func reset() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            pullProgress = 0
            elasticOffset = 0
            ballScale = 1.0
            showSuccess = false
            showError = false
            isRefreshing = false
        }
    }
}

// MARK: - Golf Ball View
struct GolfBallView: View {
    let rotation: Double
    
    var body: some View {
        ZStack {
            // Ball base
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color.gray.opacity(0.3)],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
            
            // Dimples pattern
            GeometryReader { geometry in
                ForEach(0..<12) { row in
                    ForEach(0..<8) { col in
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 3, height: 3)
                            .position(
                                x: CGFloat(col) * 6 + 5,
                                y: CGFloat(row) * 4 + 3
                            )
                    }
                }
            }
            .mask(Circle())
            
            // Highlight
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 15, height: 15)
                .offset(x: -12, y: -12)
        }
    }
}

// MARK: - Elastic Stretch View
struct ElasticStretchView: View {
    let offset: CGFloat
    
    var body: some View {
        Canvas { context, size in
            let path = Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                
                // Create elastic curve
                let controlPoint1 = CGPoint(x: size.width * 0.25, y: offset * 0.6)
                let controlPoint2 = CGPoint(x: size.width * 0.75, y: offset * 0.6)
                let endPoint = CGPoint(x: size.width, y: 0)
                
                path.addCurve(
                    to: endPoint,
                    control1: controlPoint1,
                    control2: controlPoint2
                )
                
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            
            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.green.opacity(0.1),
                        Color.green.opacity(0.05)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
        }
    }
}

// MARK: - Pull to Refresh Modifier
struct PullToRefreshModifier: ViewModifier {
    @State private var isRefreshing = false
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    let onRefresh: () async -> Bool
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            // Refresh indicator
            GolfBallPullToRefresh(
                isRefreshing: $isRefreshing,
                onRefresh: onRefresh
            )
            .zIndex(1)
            
            // Content
            ScrollView {
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("pullToRefresh")).minY
                        )
                }
                .frame(height: 0)
                
                content
            }
            .coordinateSpace(name: "pullToRefresh")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                if !isRefreshing {
                    scrollOffset = value
                    if let refreshView = getRefreshView() {
                        refreshView.handlePull(offset: max(0, value))
                    }
                }
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        if value.translation.height > 0 && scrollOffset >= 0 {
                            state = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 80 && scrollOffset >= 0 {
                            if let refreshView = getRefreshView() {
                                refreshView.handleRelease()
                            }
                        }
                    }
            )
        }
    }
    
    private func getRefreshView() -> GolfBallPullToRefresh? {
        // This would need proper reference management in production
        return nil
    }
}

extension View {
    func golfBallPullToRefresh(onRefresh: @escaping () async -> Bool) -> some View {
        modifier(PullToRefreshModifier(onRefresh: onRefresh))
    }
}