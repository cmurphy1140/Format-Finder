import SwiftUI

struct ScrollProgressIndicator: View {
    @ObservedObject var scrollState: ScrollState
    let sections: [ScrollSection]
    @State private var isVisible = true
    @State private var hideTimer: Timer?
    @State private var pulsingSectionIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    struct ScrollSection {
        let id: String
        let title: String
        let offset: CGFloat
        let color: Color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                if isVisible {
                    VStack(spacing: 0) {
                        // Progress track
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 3)
                            .overlay(
                                // Progress fill
                                GeometryReader { progressGeometry in
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(currentSectionColor)
                                        .frame(height: calculateProgressHeight(in: progressGeometry))
                                        .offset(y: 0)
                                        .animation(.easeInOut(duration: 0.2), value: scrollState.offset)
                                }
                            )
                        
                        // Section markers
                        .overlay(
                            VStack(spacing: 0) {
                                ForEach(sections.indices, id: \.self) { index in
                                    Spacer()
                                    SectionMarker(
                                        section: sections[index],
                                        isActive: isActiveSection(index),
                                        isPulsing: pulsingSectionIndex == index
                                    )
                                    if index < sections.count - 1 {
                                        Spacer()
                                    }
                                }
                            }
                        )
                    }
                    .frame(width: 30, height: geometry.size.height * 0.6)
                    .offset(x: isDragging ? -10 : 0)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isVisible)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleDrag(value: value, in: geometry)
                            }
                            .onEnded { _ in
                                endDrag()
                            }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.trailing, 10)
        }
        .onChange(of: scrollState.offset) { _, _ in
            showIndicator()
        }
        .onAppear {
            startHideTimer()
        }
    }
    
    private var currentSectionColor: Color {
        let currentIndex = getCurrentSectionIndex()
        return sections[safe: currentIndex]?.color ?? .blue
    }
    
    private func calculateProgressHeight(in geometry: GeometryProxy) -> CGFloat {
        let totalScrollableHeight = scrollState.contentHeight - UIScreen.main.bounds.height
        guard totalScrollableHeight > 0 else { return 0 }
        
        let progress = min(max(scrollState.offset / totalScrollableHeight, 0), 1)
        return geometry.size.height * progress
    }
    
    private func getCurrentSectionIndex() -> Int {
        for (index, section) in sections.enumerated().reversed() {
            if scrollState.offset >= section.offset {
                return index
            }
        }
        return 0
    }
    
    private func isActiveSection(_ index: Int) -> Bool {
        getCurrentSectionIndex() == index
    }
    
    private func handleDrag(value: DragGesture.Value, in geometry: GeometryProxy) {
        isDragging = true
        stopHideTimer()
        
        let touchY = value.location.y
        let indicatorHeight = geometry.size.height * 0.6
        let progress = min(max(touchY / indicatorHeight, 0), 1)
        
        // Calculate target offset
        let totalScrollableHeight = scrollState.contentHeight - UIScreen.main.bounds.height
        let targetOffset = progress * totalScrollableHeight
        
        // Find nearest section
        var nearestSection: (index: Int, section: ScrollSection)?
        var minDistance: CGFloat = .infinity
        
        for (index, section) in sections.enumerated() {
            let distance = abs(targetOffset - section.offset)
            if distance < minDistance {
                minDistance = distance
                nearestSection = (index, section)
            }
        }
        
        if let nearest = nearestSection {
            pulsingSectionIndex = nearest.index
            
            // Trigger haptic when hovering over section
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
            
            // Jump to section
            withAnimation(.easeInOut(duration: 0.3)) {
                scrollState.scrollTo(offset: nearest.section.offset)
            }
        }
    }
    
    private func endDrag() {
        isDragging = false
        pulsingSectionIndex = nil
        startHideTimer()
    }
    
    private func showIndicator() {
        isVisible = true
        startHideTimer()
    }
    
    private func startHideTimer() {
        stopHideTimer()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation {
                isVisible = false
            }
        }
    }
    
    private func stopHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
}

struct SectionMarker: View {
    let section: ScrollProgressIndicator.ScrollSection
    let isActive: Bool
    let isPulsing: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 5) {
            // Marker dot
            Circle()
                .fill(isActive ? section.color : Color.gray.opacity(0.4))
                .frame(width: isActive ? 10 : 6, height: isActive ? 10 : 6)
                .scaleEffect(isPulsing ? pulseScale : 1.0)
                .animation(
                    isPulsing ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                    value: isPulsing
                )
            
            // Section label (shown on hover/drag)
            if isDragging || isActive {
                Text(section.title)
                    .font(.caption2)
                    .foregroundColor(section.color)
                    .padding(.horizontal, 4)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: .systemBackground))
                            .overlay(
                                Capsule()
                                    .stroke(section.color.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .offset(x: -40)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onAppear {
            if isPulsing {
                pulseScale = 1.3
            }
        }
        .onChange(of: isPulsing) { _, newValue in
            pulseScale = newValue ? 1.3 : 1.0
        }
    }
    
    private var isDragging: Bool {
        isPulsing
    }
}

// Safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}