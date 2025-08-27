import SwiftUI
import Combine

// MARK: - Timer Manager
class TimerManager: ObservableObject {
    @Published var currentSlide = 0
    @Published var isPlaying = false
    @Published var animationPhase = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var slideTimer: Timer?
    private var animationTimer: Timer?
    
    let slideCount: Int
    let slideDuration: TimeInterval
    
    init(slideCount: Int, slideDuration: TimeInterval = 5.0) {
        self.slideCount = slideCount
        self.slideDuration = slideDuration
    }
    
    func startSlideshow() {
        stopSlideshow()
        isPlaying = true
        
        slideTimer = Timer.scheduledTimer(withTimeInterval: slideDuration, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.nextSlide()
        }
    }
    
    func stopSlideshow() {
        isPlaying = false
        slideTimer?.invalidate()
        slideTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    func nextSlide() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSlide = (currentSlide + 1) % slideCount
        }
        triggerAnimations()
    }
    
    func previousSlide() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSlide = currentSlide > 0 ? currentSlide - 1 : slideCount - 1
        }
        triggerAnimations()
    }
    
    func goToSlide(_ index: Int) {
        guard index >= 0 && index < slideCount else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            currentSlide = index
        }
        triggerAnimations()
    }
    
    private func triggerAnimations() {
        animationPhase = 0
        
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            withAnimation(.easeOut(duration: 0.8)) {
                self.animationPhase += 1
            }
            if self.animationPhase >= 5 {
                self.animationTimer?.invalidate()
                self.animationTimer = nil
            }
        }
    }
    
    deinit {
        stopSlideshow()
    }
}

// MARK: - Timer View Modifier
struct ManagedTimer: ViewModifier {
    @StateObject private var timerManager: TimerManager
    
    init(slideCount: Int, duration: TimeInterval = 5.0) {
        self._timerManager = StateObject(wrappedValue: TimerManager(slideCount: slideCount, slideDuration: duration))
    }
    
    func body(content: Content) -> some View {
        content
            .environmentObject(timerManager)
            .onDisappear {
                timerManager.stopSlideshow()
            }
    }
}

extension View {
    func withManagedTimer(slideCount: Int, duration: TimeInterval = 5.0) -> some View {
        modifier(ManagedTimer(slideCount: slideCount, duration: duration))
    }
}