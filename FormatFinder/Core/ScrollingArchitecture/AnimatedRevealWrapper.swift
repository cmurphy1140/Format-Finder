import SwiftUI

struct AnimatedRevealWrapper: View {
    let content: AnyView
    let delay: Double
    let springResponse: Double
    let springDamping: Double
    let visibilityThreshold: Double
    
    @State private var hasAnimated = false
    @State private var isVisible = false
    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0
    
    init<Content: View>(
        @ViewBuilder content: () -> Content,
        delay: Double = 0,
        springResponse: Double = 0.5,
        springDamping: Double = 0.8,
        visibilityThreshold: Double = 0.3
    ) {
        self.content = AnyView(content())
        self.delay = delay
        self.springResponse = springResponse
        self.springDamping = springDamping
        self.visibilityThreshold = visibilityThreshold
    }
    
    var body: some View {
        content
            .offset(x: offset)
            .opacity(opacity)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: VisibilityPreferenceKey.self,
                            value: geometry.frame(in: .global)
                        )
                }
            )
            .onPreferenceChange(VisibilityPreferenceKey.self) { frame in
                checkVisibility(frame: frame)
            }
            .onChange(of: isVisible) { oldValue, newValue in
                if newValue && !hasAnimated {
                    triggerAnimation()
                }
            }
    }
    
    private func checkVisibility(frame: CGRect) {
        guard !hasAnimated else { return }
        
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight = min(frame.maxY, screenHeight) - max(frame.minY, 0)
        let itemHeight = frame.height
        
        if itemHeight > 0 {
            let visibilityRatio = visibleHeight / itemHeight
            isVisible = visibilityRatio >= visibilityThreshold
        }
    }
    
    private func triggerAnimation() {
        hasAnimated = true
        
        withAnimation(
            .spring(response: springResponse, dampingFraction: springDamping)
            .delay(delay)
        ) {
            offset = 0
            opacity = 1
        }
    }
}

struct VisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// Stagger Animation Controller
class StaggerAnimationController: ObservableObject {
    @Published var currentIndex: Int = 0
    private var baseDelay: Double = 0.15
    private var items: [UUID] = []
    
    func register(id: UUID) {
        if !items.contains(id) {
            items.append(id)
        }
    }
    
    func getDelay(for id: UUID) -> Double {
        guard let index = items.firstIndex(of: id) else { return 0 }
        return Double(index) * baseDelay
    }
    
    func reset() {
        currentIndex = 0
        items.removeAll()
    }
}

// Extension for easy use
extension View {
    func animatedReveal(
        delay: Double = 0,
        springResponse: Double = 0.5,
        springDamping: Double = 0.8
    ) -> some View {
        AnimatedRevealWrapper(
            content: { self },
            delay: delay,
            springResponse: springResponse,
            springDamping: springDamping
        )
    }
}