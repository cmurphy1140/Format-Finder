import SwiftUI

struct FloatingQuickStartButton: View {
    @ObservedObject var scrollState: ScrollState
    @State private var isVisible = false
    @State private var isPressed = false
    @State private var bounceScale: CGFloat = 1.0
    
    let action: () -> Void
    let appearanceThreshold: CGFloat = 200
    let springDamping: Double = 0.6
    
    init(scrollState: ScrollState, action: @escaping () -> Void) {
        self.scrollState = scrollState
        self.action = action
    }
    
    var body: some View {
        ZStack {
            if isVisible {
                Button(action: handleTap) {
                    ZStack {
                        // Shadow layer
                        Circle()
                            .fill(Color.black.opacity(0.2))
                            .blur(radius: 10)
                            .offset(y: 5)
                        
                        // Main button
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.8, blue: 0.2),
                                        Color(red: 0.1, green: 0.6, blue: 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Icon
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isPressed ? 10 : 0))
                    }
                    .frame(width: 60, height: 60)
                    .scaleEffect(isPressed ? 0.9 : bounceScale)
                }
                .buttonStyle(FloatingButtonStyle())
                .transition(
                    .asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale(scale: 0.1).combined(with: .opacity)
                    )
                )
                .animation(
                    .spring(response: 0.5, dampingFraction: springDamping),
                    value: isVisible
                )
                .onAppear {
                    performEntranceAnimation()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 20)
        .padding(.bottom, 40)
        .onChange(of: scrollState.offset) { oldValue, newValue in
            updateVisibility(offset: newValue)
        }
    }
    
    private func handleTap() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
            impactFeedback.impactOccurred()
            action()
        }
    }
    
    private func updateVisibility(offset: CGFloat) {
        let shouldShow = offset > appearanceThreshold
        
        if shouldShow != isVisible {
            withAnimation(.spring(response: 0.5, dampingFraction: springDamping)) {
                isVisible = shouldShow
            }
        }
    }
    
    private func performEntranceAnimation() {
        bounceScale = 0.1
        withAnimation(
            .spring(response: 0.6, dampingFraction: springDamping)
            .delay(0.1)
        ) {
            bounceScale = 1.0
        }
    }
}

struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Floating Action Button Container
struct FloatingActionContainer: View {
    @ObservedObject var scrollState: ScrollState
    let primaryAction: () -> Void
    let secondaryActions: [(icon: String, action: () -> Void)]
    
    @State private var isExpanded = false
    @State private var showSecondaryButtons = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 15) {
            if isExpanded {
                ForEach(secondaryActions.indices, id: \.self) { index in
                    SecondaryFloatingButton(
                        icon: secondaryActions[index].icon,
                        action: secondaryActions[index].action,
                        delay: Double(index) * 0.05,
                        isVisible: $showSecondaryButtons
                    )
                }
            }
            
            FloatingQuickStartButton(scrollState: scrollState) {
                if secondaryActions.isEmpty {
                    primaryAction()
                } else {
                    toggleExpansion()
                }
            }
        }
    }
    
    private func toggleExpansion() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
        
        if isExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showSecondaryButtons = true
            }
        } else {
            showSecondaryButtons = false
        }
    }
}

struct SecondaryFloatingButton: View {
    let icon: String
    let action: () -> Void
    let delay: Double
    @Binding var isVisible: Bool
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(uiColor: .systemBackground))
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                )
                .frame(width: 45, height: 45)
        }
        .scaleEffect(isVisible ? 1 : 0)
        .opacity(isVisible ? 1 : 0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.6)
            .delay(delay),
            value: isVisible
        )
    }
}