import SwiftUI

struct Phase2IntegratedView: View {
    @StateObject private var scrollState = ScrollState()
    @StateObject private var staggerController = StaggerAnimationController()
    @StateObject private var feedbackCoordinator = FeedbackCoordinator()
    
    private let sections = [
        ScrollProgressIndicator.ScrollSection(id: "welcome", title: "Welcome", offset: 0, color: .blue),
        ScrollProgressIndicator.ScrollSection(id: "howto", title: "How To", offset: 300, color: .green),
        ScrollProgressIndicator.ScrollSection(id: "features", title: "Features", offset: 600, color: .purple),
        ScrollProgressIndicator.ScrollSection(id: "examples", title: "Examples", offset: 900, color: .orange),
        ScrollProgressIndicator.ScrollSection(id: "advanced", title: "Advanced", offset: 1200, color: .red)
    ]
    
    var body: some View {
        ZStack {
            // Main scrolling content
            ScrollView {
                VStack(spacing: 0) {
                    // Parallax Header from Phase 1
                    ParallaxHeaderView(
                        scrollState: scrollState,
                        title: "Golf Format Finder",
                        subtitle: "Interactive Scrolling Experience"
                    )
                    
                    // Content sections with progressive reveal
                    VStack(spacing: 40) {
                        // Welcome Section
                        SectionContainer(title: "Welcome") {
                            WelcomeContent()
                                .animatedReveal(delay: 0.1)
                        }
                        .stickyHeader("Welcome")
                        
                        // How To Use Section
                        SectionContainer(title: "How to Use") {
                            HowToUseContent()
                        }
                        .stickyHeader("How to Use")
                        
                        // Features Section
                        SectionContainer(title: "Features") {
                            FeaturesContent()
                        }
                        .stickyHeader("Features")
                        
                        // Examples Section
                        SectionContainer(title: "Examples") {
                            ExamplesContent()
                        }
                        .stickyHeader("Examples")
                        
                        // Advanced Section
                        SectionContainer(title: "Advanced") {
                            AdvancedContent()
                        }
                        .stickyHeader("Advanced")
                    }
                    .padding(.vertical, 20)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                scrollState.contentHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size) { _, newSize in
                                scrollState.contentHeight = newSize.height
                            }
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                scrollState.offset = offset
            }
            .interactiveFeedback(scrollOffset: scrollState.offset)
            
            // Floating Action Button
            FloatingQuickStartButton(scrollState: scrollState) {
                handleQuickStart()
            }
            
            // Scroll Progress Indicator
            ScrollProgressIndicator(scrollState: scrollState, sections: sections)
            
            // Debug Panel
            VStack {
                HStack {
                    AnimationDebugPanel()
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
        .environmentObject(staggerController)
    }
    
    private func handleQuickStart() {
        // Navigate to quick start or perform action
        print("Quick Start triggered")
    }
}

// Section Container
struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            content()
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }
}

// Content Views
struct WelcomeContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to the enhanced scrolling experience!")
                .font(.title2)
                .animatedReveal(delay: 0.1)
            
            Text("This view demonstrates all Phase 2 features working together.")
                .font(.body)
                .foregroundColor(.secondary)
                .animatedReveal(delay: 0.2)
            
            HStack(spacing: 20) {
                FeaturePill(icon: "sparkles", text: "Animations")
                    .animatedReveal(delay: 0.3)
                FeaturePill(icon: "hand.tap", text: "Interactive")
                    .animatedReveal(delay: 0.4)
                FeaturePill(icon: "gauge", text: "60 FPS")
                    .animatedReveal(delay: 0.5)
            }
        }
    }
}

struct HowToUseContent: View {
    @EnvironmentObject var staggerController: StaggerAnimationController
    
    let steps = [
        (icon: "1.circle.fill", text: "Scroll to explore content"),
        (icon: "2.circle.fill", text: "Watch headers stick to top"),
        (icon: "3.circle.fill", text: "Feel haptic feedback at sections"),
        (icon: "4.circle.fill", text: "Use progress indicator to jump"),
        (icon: "5.circle.fill", text: "Tap floating button for quick actions")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(steps.indices, id: \.self) { index in
                HowToStep(
                    icon: steps[index].icon,
                    text: steps[index].text
                )
                .animatedReveal(
                    delay: Double(index) * 0.15,
                    springResponse: 0.5,
                    springDamping: 0.8
                )
            }
        }
    }
}

struct HowToStep: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct FeaturesContent: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(0..<6, id: \.self) { index in
                FeatureCard(index: index)
                    .animatedReveal(delay: Double(index) * 0.1)
            }
        }
    }
}

struct FeatureCard: View {
    let index: Int
    
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            
            Text("Feature \(index + 1)")
                .font(.headline)
            
            Text("Amazing feature")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct ExamplesContent: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                ExampleRow(index: index)
                    .animatedReveal(delay: Double(index) * 0.2)
            }
        }
    }
}

struct ExampleRow: View {
    let index: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 50, height: 50)
                .overlay(
                    Text("\(index + 1)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )
            
            VStack(alignment: .leading) {
                Text("Example \(index + 1)")
                    .font(.headline)
                Text("Demonstration of features")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AdvancedContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Configuration")
                .font(.headline)
                .animatedReveal(delay: 0.1)
            
            Text("Customize animations, feedback, and behavior.")
                .font(.body)
                .foregroundColor(.secondary)
                .animatedReveal(delay: 0.2)
            
            Button(action: {}) {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .animatedReveal(delay: 0.3)
        }
    }
}

struct FeaturePill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// Preview
struct Phase2IntegratedView_Previews: PreviewProvider {
    static var previews: some View {
        Phase2IntegratedView()
    }
}