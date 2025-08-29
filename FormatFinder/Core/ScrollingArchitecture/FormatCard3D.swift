import SwiftUI

struct FormatCard3D: View {
    let format: GolfFormat
    @State private var isFlipped = false
    @State private var rotation: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isLongPressing = false
    @State private var shadowRadius: CGFloat = 10
    @State private var shadowY: CGFloat = 5
    @State private var isPreloaded = false
    
    // Gesture states
    @GestureState private var longPressState = false
    
    var body: some View {
        ZStack {
            // Back of card
            CardBack(format: format)
                .rotation3DEffect(
                    .degrees(180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
                .scaleEffect(isLongPressing ? 1.05 : 1.0)
            
            // Front of card
            CardFront(format: format)
                .opacity(isFlipped ? 0 : 1)
                .scaleEffect(isLongPressing ? 1.05 : 1.0)
        }
        .frame(height: 200)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            anchorZ: 0,
            perspective: 0.5 // Creates depth effect
        )
        .offset(dragOffset)
        .shadow(
            color: Color.black.opacity(0.3),
            radius: shadowRadius,
            x: 0,
            y: shadowY
        )
        .onTapGesture {
            handleTap()
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .updating($longPressState) { currentState, gestureState, _ in
                    gestureState = currentState
                }
                .onChanged { _ in
                    handleLongPressStart()
                }
                .onEnded { _ in
                    handleLongPressEnd()
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    handleDrag(value: value)
                }
                .onEnded { _ in
                    handleDragEnd()
                }
        )
        .onAppear {
            preloadContent()
        }
        .onChange(of: rotation) { _, newValue in
            updateShadow(for: newValue)
        }
    }
    
    private func handleTap() {
        // Handle interrupt if animation is in progress
        let isAnimating = rotation.truncatingRemainder(dividingBy: 180) != 0
        
        if isAnimating {
            // Snap to nearest state
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                rotation = isFlipped ? 0 : 180
                isFlipped.toggle()
            }
        } else {
            // Normal flip animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                rotation += 180
                isFlipped.toggle()
            }
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    private func handleLongPressStart() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLongPressing = true
            shadowRadius = 20
            shadowY = 10
        }
        
        // Heavy haptic for preview
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    private func handleLongPressEnd() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isLongPressing = false
            shadowRadius = 10
            shadowY = 5
        }
    }
    
    private func handleDrag(value: DragGesture.Value) {
        dragOffset = value.translation
        
        // Add rotation based on drag for 3D effect
        let horizontalDrag = value.translation.width
        withAnimation(.interactiveSpring()) {
            rotation = Double(horizontalDrag / 5)
        }
    }
    
    private func handleDragEnd() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            dragOffset = .zero
            rotation = isFlipped ? 180 : 0
        }
    }
    
    private func updateShadow(for angle: Double) {
        let normalizedAngle = abs(angle.truncatingRemainder(dividingBy: 180))
        let shadowIntensity = 1 - (normalizedAngle / 180)
        
        shadowRadius = 10 + (10 * CGFloat(shadowIntensity))
        shadowY = 5 + (5 * CGFloat(shadowIntensity))
    }
    
    private func preloadContent() {
        // Simulate content preloading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPreloaded = true
        }
    }
}

struct CardFront: View {
    let format: GolfFormat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: format.icon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(format.difficulty)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.3)))
                    .foregroundColor(.white)
            }
            
            Text(format.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(format.shortDescription)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
            
            Spacer()
            
            HStack {
                ForEach(format.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.26, blue: 0.20),
                    Color(red: 0.25, green: 0.57, blue: 0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CardBack: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Play")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(format.rules.prefix(3), id: \.self) { rule in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(rule)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Players")
                    Text(format.playerRange)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Time")
                    Text(format.duration)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.57, blue: 0.42),
                    Color(red: 0.11, green: 0.26, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// Card recycling pool for performance
class CardRecyclingPool: ObservableObject {
    private var pool: [FormatCard3D] = []
    private let maxPoolSize = 5
    @Published var activeCards: [String: FormatCard3D] = [:]
    
    func getCard(for format: GolfFormat) -> FormatCard3D {
        if let existingCard = activeCards[format.id] {
            return existingCard
        }
        
        let newCard = FormatCard3D(format: format)
        activeCards[format.id] = newCard
        
        // Maintain pool size
        if activeCards.count > maxPoolSize {
            // Remove least recently used
            if let oldestKey = activeCards.keys.first {
                activeCards.removeValue(forKey: oldestKey)
            }
        }
        
        return newCard
    }
    
    func recycleCard(formatId: String) {
        activeCards.removeValue(forKey: formatId)
    }
}