import SwiftUI
import CoreHaptics

// MARK: - Bounce Button
struct BounceButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1
    @State private var rotation: Double = 0
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Trigger haptic
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            // Animate
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.9
                rotation = 5
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                scale = 1.1
                rotation = -5
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.2)) {
                scale = 1
                rotation = 0
            }
            
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.3), radius: isPressed ? 5 : 10, y: isPressed ? 2 : 5)
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
            isPressed = true
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
                scale = pressing ? 0.95 : 1
            }
        }
    }
}

// MARK: - Elastic Tab View
struct ElasticTabView: View {
    let tabs: [String]
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                TabButton(
                    title: tabs[index],
                    isSelected: selectedTab == index,
                    animation: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    struct TabButton: View {
        let title: String
        let isSelected: Bool
        let animation: Namespace.ID
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if isSelected {
                                Capsule()
                                    .fill(Color.blue)
                                    .matchedGeometryEffect(id: "tab", in: animation)
                            }
                        }
                    )
            }
        }
    }
}

// MARK: - Sliding Toggle
struct SlidingToggle: View {
    @Binding var isOn: Bool
    let onColor: Color
    let offColor: Color
    
    @State private var dragOffset: CGFloat = 0
    
    init(isOn: Binding<Bool>, onColor: Color = .green, offColor: Color = .gray) {
        self._isOn = isOn
        self.onColor = onColor
        self.offColor = offColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: isOn ? .trailing : .leading) {
                // Track
                Capsule()
                    .fill(isOn ? onColor : offColor)
                    .animation(.spring(response: 0.3), value: isOn)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                    .offset(x: dragOffset)
                    .padding(2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let translation = value.translation.width
                                let maxOffset = geometry.size.width - 30
                                dragOffset = min(max(0, (isOn ? maxOffset : 0) + translation), maxOffset)
                            }
                            .onEnded { value in
                                let threshold = geometry.size.width / 2
                                let shouldTurnOn = dragOffset > threshold
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isOn = shouldTurnOn
                                    dragOffset = 0
                                }
                                
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    )
            }
        }
        .frame(width: 51, height: 31)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Pulsing Heart
struct PulsingHeart: View {
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    @State private var isLiked = false
    
    var body: some View {
        Button(action: {
            isLiked.toggle()
            
            if isLiked {
                // Like animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.3
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                    scale = 0.9
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.2)) {
                    scale = 1.1
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.3)) {
                    scale = 1
                }
                
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 30))
                .foregroundColor(isLiked ? .red : .gray)
                .scaleEffect(scale)
                .animation(.spring(response: 0.3), value: isLiked)
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    let trigger: Bool
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var rotation: Double
        var rotationSpeed: Double
        var scale: CGFloat
        var color: Color
        var shape: AnyShape
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    piece.shape
                        .fill(piece.color)
                        .frame(width: 10, height: 10)
                        .scaleEffect(piece.scale)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                }
            }
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    createConfetti(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createConfetti(in size: CGSize) {
        confettiPieces = (0..<30).map { _ in
            let shapes: [AnyShape] = [
                AnyShape(Rectangle()),
                AnyShape(Circle()),
                AnyShape(Ellipse())
            ]
            
            return ConfettiPiece(
                position: CGPoint(x: size.width / 2, y: size.height / 2),
                velocity: CGVector(
                    dx: CGFloat.random(in: -200...200),
                    dy: CGFloat.random(in: -400...(-200))
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -180...180),
                scale: CGFloat.random(in: 0.5...1.5),
                color: [.red, .blue, .green, .yellow, .purple, .orange].randomElement()!,
                shape: shapes.randomElement()!
            )
        }
        
        animateConfetti()
    }
    
    private func animateConfetti() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in confettiPieces.indices {
                // Update position
                confettiPieces[i].position.x += confettiPieces[i].velocity.dx * 0.016
                confettiPieces[i].position.y += confettiPieces[i].velocity.dy * 0.016
                
                // Apply gravity
                confettiPieces[i].velocity.dy += 500 * 0.016
                
                // Rotate
                confettiPieces[i].rotation += confettiPieces[i].rotationSpeed * 0.016
                
                // Fade out
                confettiPieces[i].scale = max(0, confettiPieces[i].scale - 0.016)
            }
            
            // Remove faded pieces
            confettiPieces.removeAll { $0.scale <= 0 }
            
            // Stop timer when all pieces are gone
            if confettiPieces.isEmpty {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    @State private var isExpanded = false
    @State private var dragOffset = CGSize.zero
    
    let mainIcon: String
    let actions: [(icon: String, color: Color, action: () -> Void)]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Action buttons
            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(actions.indices, id: \.self) { index in
                        Button(action: {
                            actions[index].action()
                            withAnimation(.spring()) {
                                isExpanded = false
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            Image(systemName: actions[index].icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(actions[index].color)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .transition(
                            .asymmetric(
                                insertion: .scale.combined(with: .opacity).animation(.spring().delay(Double(index) * 0.05)),
                                removal: .scale.combined(with: .opacity)
                            )
                        )
                    }
                }
            }
            
            // Main button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Image(systemName: isExpanded ? "xmark" : mainIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
            )
        }
    }
}

// MARK: - Shape Helper
struct AnyShape: Shape {
    private let path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

// MARK: - Demo View
struct MicroInteractionsDemo: View {
    @State private var selectedTab = 0
    @State private var toggleState = false
    @State private var showConfetti = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Bounce button
                BounceButton(title: "Play Round", icon: "play.fill") {
                    print("Play tapped")
                }
                
                // Elastic tabs
                ElasticTabView(
                    tabs: ["Stroke", "Match", "Stableford", "Skins"],
                    selectedTab: $selectedTab
                )
                
                // Sliding toggle
                HStack {
                    Text("Enable Handicap")
                    Spacer()
                    SlidingToggle(isOn: $toggleState)
                }
                .padding(.horizontal, 40)
                
                // Pulsing heart
                PulsingHeart()
                
                // Confetti trigger
                Button("Celebrate!") {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showConfetti = false
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(Capsule())
                
                // Floating action button
                FloatingActionButton(
                    mainIcon: "plus",
                    actions: [
                        (icon: "camera.fill", color: .blue, action: { print("Camera") }),
                        (icon: "photo.fill", color: .green, action: { print("Photo") }),
                        (icon: "doc.fill", color: .orange, action: { print("Document") })
                    ]
                )
            }
            .padding()
        }
        .overlay(
            ConfettiView(trigger: showConfetti)
        )
    }
}

#Preview {
    MicroInteractionsDemo()
}