import SwiftUI
import Combine
import UIKit

// MARK: - Dynamic Scroll View Manager
class DynamicScrollViewModel: ObservableObject {
    @Published var scrollState = ScrollState()
    @Published var sectionAnchors: [SectionAnchor] = []
    @Published var showDebugOverlay = false
    
    private var lastOffset: CGFloat = 0
    private var velocityTimer: Timer?
    private var contentHeight: CGFloat = 0
    
    // Combine publishers for scroll events
    let scrollEventPublisher = PassthroughSubject<ScrollState, Never>()
    let sectionChangePublisher = PassthroughSubject<String, Never>()
    
    init() {
        setupSectionAnchors()
    }
    
    private func setupSectionAnchors() {
        sectionAnchors = [
            SectionAnchor(name: "Welcome", offset: 0),
            SectionAnchor(name: "How to Use", offset: 400),
            SectionAnchor(name: "Format Categories", offset: 800),
            SectionAnchor(name: "Play Styles", offset: 1200),
            SectionAnchor(name: "Ready to Play", offset: 1600)
        ]
    }
    
    func updateScroll(offset: CGFloat, contentHeight: CGFloat, viewHeight: CGFloat) {
        self.contentHeight = contentHeight
        
        // Calculate scroll metrics
        let clampedOffset = max(0, offset)
        let maxScroll = max(0, contentHeight - viewHeight)
        let progress = maxScroll > 0 ? min(clampedOffset / maxScroll, 1) : 0
        
        // Calculate header compression
        let headerProgress = min(clampedOffset / ScrollConfig.Layout.headerCompressionRange, 1)
        
        // Calculate velocity
        let velocity = clampedOffset - lastOffset
        let direction: ScrollState.ScrollDirection = velocity > 0.1 ? .down : velocity < -0.1 ? .up : .idle
        
        // Update state
        scrollState = ScrollState(
            offset: clampedOffset,
            velocity: velocity,
            direction: direction,
            progress: progress,
            headerProgress: headerProgress,
            isScrolling: abs(velocity) > 0.1
        )
        
        // Update section anchors
        updateActiveSections(for: clampedOffset)
        
        // Publish events
        scrollEventPublisher.send(scrollState)
        
        lastOffset = clampedOffset
    }
    
    private func updateActiveSections(for offset: CGFloat) {
        for index in sectionAnchors.indices {
            let anchor = sectionAnchors[index]
            let threshold = anchor.offset + ScrollConfig.Thresholds.sectionActivationOffset
            sectionAnchors[index].isActive = offset >= threshold
            
            // Notify when entering a new section
            if sectionAnchors[index].isActive && (index == 0 || !sectionAnchors[index - 1].isActive) {
                sectionChangePublisher.send(anchor.name)
            }
        }
    }
    
    func scrollToSection(_ name: String, animated: Bool = true) {
        guard let anchor = sectionAnchors.first(where: { $0.name == name }) else { return }
        // TODO: Phase 2 - Implement programmatic scrolling
    }
}

// MARK: - Dynamic Scroll View
struct DynamicScrollView<Content: View>: View {
    @StateObject private var viewModel = DynamicScrollViewModel()
    @State private var scrollOffset: CGFloat = 0
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Content with geometry tracking
                        content
                            .background(
                                GeometryReader { contentGeometry in
                                    Color.clear
                                        .preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: -contentGeometry.frame(in: .named("scroll")).minY
                                        )
                                }
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    viewModel.updateScroll(
                        offset: value,
                        contentHeight: 2000, // TODO: Calculate actual content height
                        viewHeight: geometry.size.height
                    )
                }
                .overlay(alignment: .topTrailing) {
                    if viewModel.showDebugOverlay {
                        DebugOverlay(scrollState: viewModel.scrollState)
                    }
                }
            }
        }
        .background(ScrollConfig.Colors.background)
        .environmentObject(viewModel)
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Debug Overlay
struct DebugOverlay: View {
    let scrollState: ScrollState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Scroll Debug")
                .font(.caption.bold())
            
            Text("Offset: \(Int(scrollState.offset))pt")
            Text("Progress: \(Int(scrollState.progress * 100))%")
            Text("Header: \(Int(scrollState.headerProgress * 100))%")
            Text("Velocity: \(String(format: "%.1f", scrollState.velocity))")
            Text("Direction: \(directionText)")
            
            Divider()
            
            Text("Tagline: \(Int(scrollState.taglineOpacity * 100))%")
        }
        .font(.caption)
        .foregroundColor(ScrollConfig.Colors.primaryText)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(ScrollConfig.Colors.surface.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ScrollConfig.Colors.accentBorder, lineWidth: 1)
                )
        )
        .padding()
        .allowsHitTesting(false)
    }
    
    private var directionText: String {
        switch scrollState.direction {
        case .up: return "↑"
        case .down: return "↓"
        case .idle: return "—"
        }
    }
}

// MARK: - Test Harness
struct ScrollTestHarness: View {
    @State private var simulatedOffset: CGFloat = 0
    @StateObject private var viewModel = DynamicScrollViewModel()
    
    var body: some View {
        VStack {
            // Simulated scroll positions
            HStack(spacing: 16) {
                Button("Top") { animateToOffset(0) }
                Button("25%") { animateToOffset(500) }
                Button("50%") { animateToOffset(1000) }
                Button("75%") { animateToOffset(1500) }
                Button("Bottom") { animateToOffset(2000) }
            }
            .padding()
            
            Slider(value: $simulatedOffset, in: 0...2000)
                .padding(.horizontal)
            
            Text("Simulated Offset: \(Int(simulatedOffset))pt")
                .font(.caption)
                .foregroundColor(ScrollConfig.Colors.secondaryText)
            
            Divider()
            
            // Debug info display
            VStack(alignment: .leading) {
                Text("Header Progress: \(Int(viewModel.scrollState.headerProgress * 100))%")
                Text("Tagline Opacity: \(Int(viewModel.scrollState.taglineOpacity * 100))%")
            }
            .padding()
        }
        .onChange(of: simulatedOffset) { newValue in
            viewModel.updateScroll(offset: newValue, contentHeight: 2000, viewHeight: 800)
        }
    }
    
    private func animateToOffset(_ offset: CGFloat) {
        withAnimation(.easeInOut(duration: 0.5)) {
            simulatedOffset = offset
        }
    }
}