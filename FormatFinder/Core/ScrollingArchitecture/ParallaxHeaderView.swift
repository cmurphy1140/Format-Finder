import SwiftUI

// MARK: - Parallax Header View
struct ParallaxHeaderView: View {
    @EnvironmentObject var scrollViewModel: DynamicScrollViewModel
    @State private var iconScale: CGFloat = 1.0
    @State private var titleOpacity: CGFloat = 1.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with parallax
            headerBackground
            
            // Content overlay
            headerContent
        }
        .frame(height: currentHeight)
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    // MARK: - Computed Properties
    
    private var currentHeight: CGFloat {
        let progress = scrollViewModel.scrollState.headerProgress
        let compressionAmount = ScrollConfig.Layout.headerCompressionRange * progress
        return ScrollConfig.Layout.headerMaxHeight - compressionAmount
    }
    
    private var iconSize: CGFloat {
        let progress = scrollViewModel.scrollState.headerProgress
        let sizeDiff = ScrollConfig.Layout.iconMaxSize - ScrollConfig.Layout.iconMinSize
        return ScrollConfig.Layout.iconMaxSize - (sizeDiff * progress)
    }
    
    private var titleSize: CGFloat {
        let progress = scrollViewModel.scrollState.headerProgress
        let sizeDiff = ScrollConfig.Typography.heroTitleSize - ScrollConfig.Typography.compressedTitleSize
        return ScrollConfig.Typography.heroTitleSize - (sizeDiff * progress)
    }
    
    private var parallaxOffset: CGFloat {
        ScrollConfig.parallaxOffset(for: scrollViewModel.scrollState.offset)
    }
    
    private var blurRadius: CGFloat {
        ScrollConfig.blurRadius(for: scrollViewModel.scrollState.headerProgress)
    }
    
    // MARK: - Header Background
    
    @ViewBuilder
    private var headerBackground: some View {
        // Gradient background with parallax
        LinearGradient(
            gradient: Gradient(colors: [
                ScrollConfig.Colors.accent.opacity(0.3),
                ScrollConfig.Colors.background
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .offset(y: parallaxOffset)
        .blur(radius: blurRadius)
        
        // Overlay pattern (subtle golf course texture)
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw subtle pattern
                let patternSize: CGFloat = 40
                let rows = Int(size.height / patternSize) + 2
                let cols = Int(size.width / patternSize) + 2
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * patternSize
                        let y = CGFloat(row) * patternSize - parallaxOffset
                        
                        // Draw subtle dots for texture
                        if (row + col) % 2 == 0 {
                            let rect = CGRect(x: x + patternSize/2 - 1, y: y + patternSize/2 - 1, width: 2, height: 2)
                            context.fill(Path(ellipseIn: rect), with: .color(ScrollConfig.Colors.accent.opacity(0.05)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Header Content
    
    @ViewBuilder
    private var headerContent: some View {
        VStack(spacing: 12) {
            Spacer()
            
            // Golf Icon with scaling
            Image(systemName: "figure.golf")
                .font(.system(size: iconSize))
                .foregroundColor(ScrollConfig.Colors.primaryText)
                .scaleEffect(iconScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: iconSize)
            
            // Title
            Text("Format Finder")
                .font(.system(size: titleSize, weight: .thin, design: .serif))
                .foregroundColor(ScrollConfig.Colors.primaryText)
                .animation(.easeInOut(duration: 0.2), value: titleSize)
            
            // Tagline with fade
            if scrollViewModel.scrollState.taglineOpacity > 0 {
                Text("Elevate Your Golf Experience")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(ScrollConfig.Colors.secondaryText)
                    .opacity(scrollViewModel.scrollState.taglineOpacity)
                    .animation(.easeOut(duration: 0.3), value: scrollViewModel.scrollState.taglineOpacity)
            }
            
            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sticky Header Modifier
struct StickyHeaderModifier: ViewModifier {
    @EnvironmentObject var scrollViewModel: DynamicScrollViewModel
    
    func body(content: Content) -> some View {
        content
            .offset(y: headerOffset)
            .zIndex(1000)
    }
    
    private var headerOffset: CGFloat {
        let offset = scrollViewModel.scrollState.offset
        if offset > 0 {
            return -min(offset, ScrollConfig.Layout.headerCompressionRange)
        }
        return -offset // Stretch effect when pulling down
    }
}

extension View {
    func stickyHeader() -> some View {
        modifier(StickyHeaderModifier())
    }
}

// MARK: - Compressed Header Bar
struct CompressedHeaderBar: View {
    @EnvironmentObject var scrollViewModel: DynamicScrollViewModel
    
    var body: some View {
        HStack {
            // Small icon
            Image(systemName: "figure.golf")
                .font(.system(size: 24))
                .foregroundColor(ScrollConfig.Colors.primaryText)
            
            Text("Format Finder")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(ScrollConfig.Colors.primaryText)
            
            Spacer()
            
            // TODO: Phase 2 - Add navigation buttons
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            ScrollConfig.Colors.surface
                .opacity(scrollViewModel.scrollState.isHeaderCompressed ? 0.95 : 0)
                .blur(radius: 10)
        )
        .overlay(
            Divider()
                .background(ScrollConfig.Colors.divider)
                .opacity(scrollViewModel.scrollState.isHeaderCompressed ? 1 : 0),
            alignment: .bottom
        )
        .animation(.easeInOut(duration: 0.3), value: scrollViewModel.scrollState.isHeaderCompressed)
    }
}