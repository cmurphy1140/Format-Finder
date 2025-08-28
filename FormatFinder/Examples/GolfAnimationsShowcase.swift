import SwiftUI

// MARK: - Golf Animations Showcase
// Demonstrates all the golf animations and backgrounds

struct GolfAnimationsShowcase: View {
    @State private var selectedBackground = 0
    @State private var showRain = false
    @State private var showWind = false
    @State private var showCelebration = false
    @State private var celebrationType = 0
    @State private var selectedTab = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var showTransition = false
    
    let backgrounds = ["Morning", "Afternoon", "Sunset", "Night"]
    let celebrations = ["Hole in One", "Eagle", "Birdie"]
    
    var body: some View {
        ZStack {
            // Dynamic background
            backgroundView
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 30) {
                        headerSection
                        backgroundControlSection
                        weatherControlSection
                        celebrationSection
                        animatedElementsSection
                        transitionDemoSection
                        loadingDemoSection
                    }
                    .padding()
                    .background(GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .global).minY
                        )
                    })
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            
            // Weather effects overlay
            if showRain {
                RainEffect()
                    .allowsHitTesting(false)
            }
            
            if showWind {
                WindParticles()
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .bottom) {
            AnimatedGolfTabBar(selectedTab: $selectedTab)
        }
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        switch selectedBackground {
        case 0:
            MorningTeeBackground()
                .ignoresSafeArea()
        case 1:
            AfternoonFairwayBackground()
                .ignoresSafeArea()
        case 2:
            SunsetRoundBackground()
                .ignoresSafeArea()
        case 3:
            NightGolfBackground()
                .ignoresSafeArea()
        default:
            Color.green.ignoresSafeArea()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Golf Animations")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            Text("Interactive showcase of all animations")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Background Control Section
    
    private var backgroundControlSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Backgrounds")
                .font(.headline)
                .foregroundColor(.white)
            
            Picker("Background", selection: $selectedBackground) {
                ForEach(0..<backgrounds.count, id: \.self) { index in
                    Text(backgrounds[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .background(Color.white.opacity(0.9))
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Weather Control Section
    
    private var weatherControlSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weather Effects")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                Toggle("Rain", isOn: $showRain)
                    .toggleStyle(GolfToggleStyle(icon: "cloud.rain.fill"))
                
                Toggle("Wind", isOn: $showWind)
                    .toggleStyle(GolfToggleStyle(icon: "wind"))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Celebration Section
    
    private var celebrationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Celebrations")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                ForEach(0..<celebrations.count, id: \.self) { index in
                    Button(action: {
                        triggerCelebration(index)
                    }) {
                        Text(celebrations[index])
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(celebrationColor(for: index))
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            Group {
                if showCelebration {
                    celebrationOverlay
                }
            }
        )
    }
    
    // MARK: - Animated Elements Section
    
    private var animatedElementsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Animated Elements")
                .font(.headline)
                .foregroundColor(.white)
            
            // Golf ball trajectory
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 150)
                
                GolfBallTrajectoryAnimation()
            }
            
            // Flag waving
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 100)
                
                FlagWavingAnimation()
                    .frame(height: 80)
            }
            
            // Grass animation
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 100)
                
                AnimatedGrassTexture()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Transition Demo Section
    
    private var transitionDemoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Transitions")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: {
                withAnimation(.easeOut(duration: 0.6)) {
                    showTransition.toggle()
                }
            }) {
                Text("Toggle Golf Ball Transition")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
            }
            
            if showTransition {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(height: 100)
                    .overlay(
                        Text("Transitioned View")
                            .foregroundColor(.green)
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Loading Demo Section
    
    private var loadingDemoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Loading Animation")
                .font(.headline)
                .foregroundColor(.white)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 100)
                
                GolfBallRollingLoader()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Celebration Overlay
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        switch celebrationType {
        case 0:
            HoleInOneFireworks()
        case 1:
            EagleAnimation()
        case 2:
            BirdieBirdAnimation()
        default:
            EmptyView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func triggerCelebration(_ type: Int) {
        celebrationType = type
        showCelebration = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showCelebration = false
        }
    }
    
    private func celebrationColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .orange
        case 2: return .blue
        default: return .green
        }
    }
}

// MARK: - Custom Components

struct GolfToggleStyle: ToggleStyle {
    let icon: String
    
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                configuration.label
            }
            .foregroundColor(configuration.isOn ? .white : .white.opacity(0.6))
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(configuration.isOn ? Color.green : Color.white.opacity(0.2))
            )
        }
    }
}

struct EagleAnimation: View {
    @State private var soar = false
    
    var body: some View {
        Image(systemName: "bird")
            .font(.system(size: 100))
            .foregroundColor(.yellow)
            .shadow(color: .yellow, radius: 20)
            .rotationEffect(.degrees(soar ? 0 : -20))
            .offset(x: soar ? 300 : -300, y: soar ? -100 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2)) {
                    soar = true
                }
            }
    }
}

// MARK: - Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

struct GolfAnimationsShowcase_Previews: PreviewProvider {
    static var previews: some View {
        GolfAnimationsShowcase()
    }
}

// MARK: - Usage Examples

struct ExampleUsageView: View {
    @State private var isLoading = false
    @State private var showScore = false
    @State private var timeOfDay: TimeOfDay = .afternoon
    
    var body: some View {
        VStack {
            // Example 1: Time-based background
            Text("Scorecard")
                .font(.largeTitle)
                .timeBasedGolfBackground(for: timeOfDay)
            
            // Example 2: Weather effects
            HStack {
                Text("Rainy Day Golf")
                    .rainEffect(intensity: .light)
                
                Text("Windy Conditions")
                    .windEffect(strength: .moderate)
            }
            
            // Example 3: Loading overlay
            Button("Load Scores") {
                isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isLoading = false
                }
            }
            .golfLoadingOverlay(isLoading: isLoading)
            
            // Example 4: Celebration
            if showScore {
                Text("Birdie!")
                    .font(.largeTitle)
                    .celebrateBirdie()
            }
            
            // Example 5: Parallax scrolling
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<10) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.8))
                            .frame(height: 100)
                    }
                }
                .parallaxEffect(offset: 0)
            }
        }
    }
}