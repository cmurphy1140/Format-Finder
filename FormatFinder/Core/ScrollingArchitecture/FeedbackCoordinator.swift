import SwiftUI
import AVFoundation

class FeedbackCoordinator: ObservableObject {
    @Published var currentSection: Int = 0
    @Published var isMuted: Bool = false
    @Published var respectsAccessibility: Bool = true
    
    private var lastHapticSection: Int = -1
    private var audioPlayer: AVAudioPlayer?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    // Section boundaries for triggering feedback
    private let sectionBoundaries: [CGFloat] = [0, 300, 600, 900, 1200, 1500]
    
    init() {
        setupAudioSession()
        prepareHaptics()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
    }
    
    func handleScroll(offset: CGFloat) {
        let newSection = calculateSection(from: offset)
        
        if newSection != currentSection {
            currentSection = newSection
            triggerSectionFeedback(section: newSection)
        }
    }
    
    private func calculateSection(from offset: CGFloat) -> Int {
        for (index, boundary) in sectionBoundaries.enumerated() {
            if offset < boundary {
                return max(0, index - 1)
            }
        }
        return sectionBoundaries.count - 1
    }
    
    func triggerSectionFeedback(section: Int) {
        guard section != lastHapticSection else { return }
        lastHapticSection = section
        
        // Check accessibility settings
        if respectsAccessibility && UIAccessibility.isReduceMotionEnabled {
            return
        }
        
        // Trigger appropriate haptic
        switch section {
        case 0:
            impactLight.impactOccurred()
        case 1, 2:
            selectionFeedback.selectionChanged()
        case 3, 4:
            impactMedium.impactOccurred()
        default:
            impactHeavy.impactOccurred()
        }
        
        // Play sound if not muted
        if !isMuted {
            playTransitionSound(for: section)
        }
    }
    
    private func playTransitionSound(for section: Int) {
        // Using system sounds for now
        let soundID: SystemSoundID = section % 2 == 0 ? 1104 : 1105
        AudioServicesPlaySystemSound(soundID)
    }
    
    func triggerInteractionFeedback(type: InteractionType) {
        guard !respectsAccessibility || !UIAccessibility.isReduceMotionEnabled else { return }
        
        switch type {
        case .tap:
            impactLight.impactOccurred()
        case .longPress:
            impactMedium.impactOccurred()
        case .swipe:
            selectionFeedback.selectionChanged()
        case .pinch:
            impactHeavy.impactOccurred()
        }
    }
    
    enum InteractionType {
        case tap, longPress, swipe, pinch
    }
}

// Micro Animation Views
struct MicroAnimationView: View {
    let type: AnimationType
    @State private var isAnimating = false
    
    enum AnimationType {
        case pulse, ripple, bounce, spin
    }
    
    var body: some View {
        ZStack {
            switch type {
            case .pulse:
                Circle()
                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0 : 1)
                
            case .ripple:
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        .scaleEffect(isAnimating ? 2.0 : 0.5)
                        .opacity(isAnimating ? 0 : 0.6)
                        .animation(
                            .easeOut(duration: 1.0)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
                
            case .bounce:
                Circle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 10, height: 10)
                    .offset(y: isAnimating ? -20 : 0)
                    .animation(
                        .interpolatingSpring(stiffness: 300, damping: 10)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
            case .spin:
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 2)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Feedback Modifier
struct InteractiveFeedbackModifier: ViewModifier {
    @StateObject private var coordinator = FeedbackCoordinator()
    let scrollOffset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .onChange(of: scrollOffset) { oldValue, newValue in
                coordinator.handleScroll(offset: newValue)
            }
            .onTapGesture {
                coordinator.triggerInteractionFeedback(type: .tap)
            }
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        FeedbackDebugView(coordinator: coordinator)
                    }
                    Spacer()
                }
                .padding()
            )
    }
}

struct FeedbackDebugView: View {
    @ObservedObject var coordinator: FeedbackCoordinator
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("Section: \(coordinator.currentSection)")
                .font(.caption2)
            
            HStack(spacing: 5) {
                Image(systemName: coordinator.isMuted ? "speaker.slash" : "speaker.wave.2")
                    .font(.caption)
                
                Toggle("", isOn: $coordinator.isMuted)
                    .labelsHidden()
                    .scaleEffect(0.7)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.7))
        .foregroundColor(.white)
        .cornerRadius(8)
        .opacity(0.7)
    }
}

extension View {
    func interactiveFeedback(scrollOffset: CGFloat) -> some View {
        modifier(InteractiveFeedbackModifier(scrollOffset: scrollOffset))
    }
}