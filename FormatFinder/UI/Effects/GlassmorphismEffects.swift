import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Glassmorphism View Modifier
struct GlassmorphismModifier: ViewModifier {
    let cornerRadius: CGFloat
    let blurAmount: CGFloat
    let opacity: CGFloat
    let borderWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = 20,
        blurAmount: CGFloat = 20,
        opacity: CGFloat = 0.7,
        borderWidth: CGFloat = 1
    ) {
        self.cornerRadius = cornerRadius
        self.blurAmount = blurAmount
        self.opacity = opacity
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(opacity)
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Neumorphism View Modifier
struct NeumorphismModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isPressed: Bool
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let darkShadow = colorScheme == .dark ? 
            Color.black.opacity(0.8) : Color(red: 0.7, green: 0.7, blue: 0.8)
        let lightShadow = colorScheme == .dark ?
            Color.white.opacity(0.1) : Color.white
        
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        colorScheme == .dark ?
                        Color(red: 0.15, green: 0.15, blue: 0.17) :
                        Color(red: 0.93, green: 0.93, blue: 0.94)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: isPressed ? lightShadow : darkShadow,
                radius: isPressed ? 4 : 8,
                x: isPressed ? -2 : -4,
                y: isPressed ? -2 : -4
            )
            .shadow(
                color: isPressed ? darkShadow : lightShadow,
                radius: isPressed ? 4 : 8,
                x: isPressed ? 2 : 4,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
    }
}

// MARK: - Custom Shader Effects
struct GrassTextureView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Canvas { context, size in
            // Create grass blade pattern
            for x in stride(from: 0, to: size.width, by: 3) {
                for y in stride(from: 0, to: size.height, by: 2) {
                    let offset = sin(phase + x * 0.01) * 2
                    let height = CGFloat.random(in: 8...15)
                    
                    let blade = Path { path in
                        path.move(to: CGPoint(x: x, y: y))
                        path.addQuadCurve(
                            to: CGPoint(x: x + offset, y: y - height),
                            control: CGPoint(x: x + offset * 0.5, y: y - height * 0.5)
                        )
                    }
                    
                    context.stroke(
                        blade,
                        with: .color(
                            Color(
                                red: Double.random(in: 0.2...0.3),
                                green: Double.random(in: 0.5...0.7),
                                blue: Double.random(in: 0.1...0.2)
                            )
                        ),
                        lineWidth: 1
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

struct SandTextureView: View {
    var body: some View {
        Canvas { context, size in
            // Create sand grain pattern
            for _ in 0..<5000 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let radius = CGFloat.random(in: 0.3...1.2)
                
                let circle = Path { path in
                    path.addEllipse(in: CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                }
                
                context.fill(
                    circle,
                    with: .color(
                        Color(
                            red: Double.random(in: 0.85...0.95),
                            green: Double.random(in: 0.75...0.85),
                            blue: Double.random(in: 0.55...0.65)
                        ).opacity(Double.random(in: 0.3...0.7))
                    )
                )
            }
        }
    }
}

// MARK: - Water Ripple Effect
struct WaterRippleView: View {
    @State private var ripples: [Ripple] = []
    
    struct Ripple: Identifiable {
        let id = UUID()
        let position: CGPoint
        var scale: CGFloat = 0.1
        var opacity: Double = 1
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Water base
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.4, blue: 0.6),
                        Color(red: 0.1, green: 0.3, blue: 0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Ripples
                ForEach(ripples) { ripple in
                    Circle()
                        .stroke(Color.white.opacity(ripple.opacity), lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .scaleEffect(ripple.scale)
                        .position(ripple.position)
                }
            }
            .onTapGesture { location in
                addRipple(at: location)
            }
        }
    }
    
    private func addRipple(at location: CGPoint) {
        var newRipple = Ripple(position: location)
        ripples.append(newRipple)
        
        withAnimation(.easeOut(duration: 1.5)) {
            if let index = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples[index].scale = 4
                ripples[index].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }
}

// MARK: - Particle System
struct ParticleSystemView: View {
    let particleCount: Int
    let colors: [Color]
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var scale: CGFloat
        var opacity: Double
        var rotation: Angle
        var color: Color
    }
    
    init(particleCount: Int = 50, colors: [Color] = [.yellow, .orange, .red]) {
        self.particleCount = particleCount
        self.colors = colors
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: "star.fill")
                        .foregroundColor(particle.color)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .rotationEffect(particle.rotation)
                        .position(particle.position)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(x: size.width / 2, y: size.height / 2),
                velocity: CGVector(
                    dx: CGFloat.random(in: -100...100),
                    dy: CGFloat.random(in: -200...(-50))
                ),
                scale: CGFloat.random(in: 0.3...1.0),
                opacity: 1,
                rotation: .degrees(Double.random(in: 0...360)),
                color: colors.randomElement() ?? .yellow
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in particles.indices {
                // Update position
                particles[i].position.x += particles[i].velocity.dx * 0.016
                particles[i].position.y += particles[i].velocity.dy * 0.016
                
                // Apply gravity
                particles[i].velocity.dy += 200 * 0.016
                
                // Fade out
                particles[i].opacity = max(0, particles[i].opacity - 0.016)
                
                // Rotate
                particles[i].rotation.degrees += 180 * 0.016
                
                // Reset if needed
                if particles[i].opacity <= 0 {
                    particles[i].position = CGPoint(x: 200, y: 400)
                    particles[i].velocity = CGVector(
                        dx: CGFloat.random(in: -100...100),
                        dy: CGFloat.random(in: -200...(-50))
                    )
                    particles[i].opacity = 1
                }
            }
        }
    }
}

// MARK: - Glow Effect
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .blur(radius: radius)
                    .opacity(0.6)
                    .blendMode(.plusLighter)
            )
            .overlay(
                content
                    .blur(radius: radius * 0.5)
                    .opacity(0.4)
                    .blendMode(.plusLighter)
            )
    }
}

// MARK: - View Extensions
extension View {
    func glassmorphism(
        cornerRadius: CGFloat = 20,
        blurAmount: CGFloat = 20,
        opacity: CGFloat = 0.7,
        borderWidth: CGFloat = 1
    ) -> some View {
        modifier(GlassmorphismModifier(
            cornerRadius: cornerRadius,
            blurAmount: blurAmount,
            opacity: opacity,
            borderWidth: borderWidth
        ))
    }
    
    func neumorphism(cornerRadius: CGFloat = 20, isPressed: Bool = false) -> some View {
        modifier(NeumorphismModifier(cornerRadius: cornerRadius, isPressed: isPressed))
    }
    
    func glow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Demo View
struct VisualEffectsDemo: View {
    @State private var isPressed = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Glassmorphism example
                VStack {
                    Text("Glassmorphism Card")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Beautiful frosted glass effect")
                        .font(.caption)
                        .opacity(0.7)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassmorphism()
                .padding(.horizontal)
                
                // Neumorphism example
                Button(action: {}) {
                    Text("Neumorphic Button")
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .neumorphism(isPressed: isPressed)
                .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
                    isPressed = true
                } onPressingChanged: { pressing in
                    isPressed = pressing
                }
                .padding(.horizontal)
                
                // Grass texture
                GrassTextureView()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
                
                // Sand texture
                SandTextureView()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
                
                // Water ripple
                WaterRippleView()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
                
                // Glow effect
                Text("Glowing Text")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .glow(color: .blue, radius: 15)
                    .padding()
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.2, green: 0.2, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    VisualEffectsDemo()
}