import SwiftUI

// MARK: - Scroll Content Container
struct ScrollContentContainer<Content: View>: View {
    @EnvironmentObject var scrollViewModel: DynamicScrollViewModel
    @State private var contentSize: CGSize = .zero
    
    let content: Content
    let spacing: CGFloat
    
    init(spacing: CGFloat = ScrollConfig.Layout.sectionSpacing, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Add top padding to account for header
            Color.clear
                .frame(height: ScrollConfig.Layout.headerMaxHeight)
            
            // Main content
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ScrollConfig.Layout.contentPadding)
            
            // Bottom padding for safe area
            Color.clear
                .frame(height: ScrollConfig.Layout.safeAreaPadding)
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        contentSize = geometry.size
                    }
                    .onChange(of: geometry.size) { newSize in
                        contentSize = newSize
                    }
            }
        )
    }
}

// MARK: - Animated Section Container
struct AnimatedSectionContainer<Content: View>: View {
    @EnvironmentObject var scrollViewModel: DynamicScrollViewModel
    @State private var isVisible = false
    @State private var hasAppeared = false
    
    let sectionName: String
    let delay: Double
    let content: Content
    
    init(
        _ sectionName: String,
        delay: Double = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.sectionName = sectionName
        self.delay = delay
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: ScrollConfig.Layout.cardSpacing) {
            content
        }
        .opacity(opacity)
        .offset(y: offset)
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeOut(duration: ScrollConfig.Animation.longDuration).delay(delay)) {
                hasAppeared = true
            }
        }
        .onReceive(scrollViewModel.sectionChangePublisher) { activeSectionName in
            if activeSectionName == sectionName {
                withAnimation(.easeOut(duration: ScrollConfig.Animation.defaultDuration)) {
                    isVisible = true
                }
            }
        }
        .id(sectionName)
    }
    
    private var opacity: Double {
        guard hasAppeared else { return 0 }
        
        // Fade based on scroll position
        let sectionAnchor = scrollViewModel.sectionAnchors.first { $0.name == sectionName }
        let fadeStart = (sectionAnchor?.offset ?? 0) - ScrollConfig.Thresholds.welcomeFadeStart
        let fadeEnd = (sectionAnchor?.offset ?? 0) + ScrollConfig.Thresholds.welcomeFadeEnd
        
        let offset = scrollViewModel.scrollState.offset
        
        if offset < fadeStart {
            return 0
        } else if offset > fadeEnd {
            return 1
        } else {
            let progress = (offset - fadeStart) / (fadeEnd - fadeStart)
            return Double(progress)
        }
    }
    
    private var offset: CGFloat {
        hasAppeared ? 0 : 20
    }
    
    private var scale: CGFloat {
        hasAppeared ? 1 : 0.95
    }
}

// MARK: - Section Header View
struct SectionHeaderView: View {
    let title: String
    let icon: String
    let subtitle: String?
    
    @EnvironmentObject var scrollViewModel: DynamicScrollViewModel
    @State private var isHighlighted = false
    
    init(title: String, icon: String, subtitle: String? = nil) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(ScrollConfig.Colors.accent)
                    .rotationEffect(.degrees(isHighlighted ? 360 : 0))
                    .animation(.easeInOut(duration: 0.6), value: isHighlighted)
                
                Text(title)
                    .font(ScrollConfig.Typography.sectionFont)
                    .foregroundColor(ScrollConfig.Colors.primaryText)
                
                Spacer()
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(ScrollConfig.Typography.bodyFont)
                    .foregroundColor(ScrollConfig.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
        .onReceive(scrollViewModel.sectionChangePublisher) { sectionName in
            if sectionName == title {
                withAnimation {
                    isHighlighted = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isHighlighted = false
                }
            }
        }
    }
}

// MARK: - Fade In View Modifier
struct FadeInModifier: ViewModifier {
    @EnvironmentObject var scrollViewModel: DynamicScrollViewModel
    let threshold: CGFloat
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .animation(.easeOut(duration: ScrollConfig.Animation.defaultDuration), value: opacity)
    }
    
    private var opacity: Double {
        let offset = scrollViewModel.scrollState.offset
        if offset < threshold {
            return 0
        } else if offset > threshold + 50 {
            return 1
        } else {
            return Double((offset - threshold) / 50)
        }
    }
}

extension View {
    func fadeIn(at threshold: CGFloat) -> some View {
        modifier(FadeInModifier(threshold: threshold))
    }
}

// MARK: - Safe Area Handler
struct SafeAreaHandler: ViewModifier {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    func body(content: Content) -> some View {
        content
            .padding(.top, safeAreaInsets.top)
            .padding(.bottom, safeAreaInsets.bottom)
    }
}

extension View {
    func handleSafeArea() -> some View {
        modifier(SafeAreaHandler())
    }
}

// MARK: - Dynamic Height Preference
struct DynamicHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// TODO: Phase 2 Integration Points
// - Add gesture recognizers for swipe navigation
// - Implement section-based scroll anchoring
// - Add pull-to-refresh functionality
// - Create custom scroll indicators
// - Add keyboard avoidance for form sections