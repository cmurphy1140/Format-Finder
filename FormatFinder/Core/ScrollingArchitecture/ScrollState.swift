import SwiftUI
import Combine

// MARK: - Scroll State Management
class ScrollState: ObservableObject {
    @Published var offset: CGFloat = 0
    @Published var velocity: CGFloat = 0
    @Published var contentHeight: CGFloat = 0
    @Published var isScrolling: Bool = false
    
    private var lastUpdateTime: Date = Date()
    private var lastOffset: CGFloat = 0
    
    var scrollProgress: CGFloat {
        guard contentHeight > 0 else { return 0 }
        return min(max(offset / (contentHeight - UIScreen.main.bounds.height), 0), 1)
    }
    
    var isDragging: Bool = false
    var isDecelerating: Bool = false
    
    func updateOffset(_ newOffset: CGFloat) {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastUpdateTime)
        
        if timeDelta > 0 {
            let offsetDelta = newOffset - lastOffset
            velocity = CGFloat(offsetDelta / timeDelta)
        }
        
        offset = newOffset
        lastOffset = newOffset
        lastUpdateTime = now
        
        // Update scrolling state
        isScrolling = abs(velocity) > 1.0
    }
    
    func updateVelocity(_ newVelocity: CGFloat) {
        velocity = newVelocity
        isScrolling = abs(velocity) > 1.0
    }
    
    func scrollTo(offset: CGFloat, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.offset = offset
            }
        } else {
            self.offset = offset
        }
    }
    
    func reset() {
        offset = 0
        velocity = 0
        isScrolling = false
        lastOffset = 0
        lastUpdateTime = Date()
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}