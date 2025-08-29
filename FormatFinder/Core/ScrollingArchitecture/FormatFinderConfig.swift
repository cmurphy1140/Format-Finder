import SwiftUI
import Combine

// MARK: - Format Finder Configuration System
class FormatFinderConfig: ObservableObject {
    static let shared = FormatFinderConfig()
    
    // Animation Controls
    @Published var animationsEnabled = true
    @Published var parallaxEnabled = true
    @Published var progressiveRevealEnabled = true
    @Published var hapticFeedbackEnabled = true
    @Published var floatingButtonEnabled = true
    @Published var pullToRefreshEnabled = true
    @Published var stickyHeadersEnabled = true
    @Published var scrollIndicatorEnabled = true
    
    // Animation Speeds
    @Published var globalAnimationSpeed: Double = 1.0
    @Published var transitionDuration: Double = 0.3
    @Published var springResponse: Double = 0.5
    @Published var springDamping: Double = 0.8
    
    // Performance Settings
    @Published var maxConcurrentAnimations = 5
    @Published var imageCacheSize = 100 // MB
    @Published var viewRecyclingEnabled = true
    @Published var lazyLoadingThreshold: CGFloat = 100
    
    // Debug Options
    @Published var debugMode = false
    @Published var showFPSCounter = false
    @Published var showMemoryUsage = false
    @Published var showAnimationTimeline = false
    @Published var visualizeScrollVelocity = false
    
    // Remote Configuration
    @Published var remoteConfigEnabled = false
    @Published var configVersion = "1.0.0"
    private var remoteConfigTimer: Timer?
    
    // A/B Testing
    @Published var experimentGroups: [String: String] = [:]
    @Published var activeExperiments: Set<String> = []
    
    // Analytics
    @Published var analyticsEnabled = true
    @Published var scrollPatternTracking = true
    @Published var performanceMetricsEnabled = true
    
    // Persistence
    @AppStorage("animationsEnabled") private var storedAnimationsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var storedHapticEnabled = true
    @AppStorage("debugMode") private var storedDebugMode = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadStoredSettings()
        setupBindings()
        if remoteConfigEnabled {
            startRemoteConfigSync()
        }
    }
    
    private func loadStoredSettings() {
        animationsEnabled = storedAnimationsEnabled
        hapticFeedbackEnabled = storedHapticEnabled
        debugMode = storedDebugMode
    }
    
    private func setupBindings() {
        // Sync published properties with AppStorage
        $animationsEnabled
            .sink { [weak self] value in
                self?.storedAnimationsEnabled = value
            }
            .store(in: &cancellables)
        
        $hapticFeedbackEnabled
            .sink { [weak self] value in
                self?.storedHapticEnabled = value
            }
            .store(in: &cancellables)
        
        $debugMode
            .sink { [weak self] value in
                self?.storedDebugMode = value
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Configuration Methods
    
    func toggleAnimation(_ type: AnimationType, enabled: Bool) {
        switch type {
        case .parallax:
            parallaxEnabled = enabled
        case .progressiveReveal:
            progressiveRevealEnabled = enabled
        case .floatingButton:
            floatingButtonEnabled = enabled
        case .pullToRefresh:
            pullToRefreshEnabled = enabled
        case .stickyHeaders:
            stickyHeadersEnabled = enabled
        case .scrollIndicator:
            scrollIndicatorEnabled = enabled
        }
    }
    
    func adjustAnimationSpeed(_ multiplier: Double) {
        globalAnimationSpeed = max(0.1, min(2.0, multiplier))
        transitionDuration = 0.3 / globalAnimationSpeed
        springResponse = 0.5 / globalAnimationSpeed
    }
    
    func enableDebugVisualization() {
        debugMode = true
        showFPSCounter = true
        showMemoryUsage = true
        showAnimationTimeline = true
        visualizeScrollVelocity = true
    }
    
    func disableAllAnimations() {
        animationsEnabled = false
        parallaxEnabled = false
        progressiveRevealEnabled = false
        floatingButtonEnabled = false
        stickyHeadersEnabled = false
    }
    
    // MARK: - Remote Configuration
    
    private func startRemoteConfigSync() {
        remoteConfigTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.fetchRemoteConfig()
            }
        }
    }
    
    private func fetchRemoteConfig() async {
        // Simulated remote config fetch
        // In production, this would fetch from a real endpoint
        // Following the rule: max 2 attempts for API requests
        var attempts = 0
        let maxAttempts = 2
        
        while attempts < maxAttempts {
            attempts += 1
            
            // Simulate API call
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                
                // Mock successful response
                await MainActor.run {
                    self.applyRemoteConfig([
                        "animationsEnabled": true,
                        "globalAnimationSpeed": 1.0,
                        "experimentGroups": ["scrolling": "variant_a"]
                    ])
                }
                break
            } catch {
                if attempts >= maxAttempts {
                    print("Remote config fetch failed after \(maxAttempts) attempts")
                    break
                }
            }
        }
    }
    
    private func applyRemoteConfig(_ config: [String: Any]) {
        if let animations = config["animationsEnabled"] as? Bool {
            animationsEnabled = animations
        }
        
        if let speed = config["globalAnimationSpeed"] as? Double {
            adjustAnimationSpeed(speed)
        }
        
        if let experiments = config["experimentGroups"] as? [String: String] {
            experimentGroups = experiments
        }
        
        configVersion = config["version"] as? String ?? configVersion
    }
    
    // MARK: - A/B Testing
    
    func enrollInExperiment(_ experimentId: String, variant: String) {
        experimentGroups[experimentId] = variant
        activeExperiments.insert(experimentId)
        
        // Apply experiment-specific settings
        applyExperimentSettings(experimentId: experimentId, variant: variant)
    }
    
    private func applyExperimentSettings(experimentId: String, variant: String) {
        switch (experimentId, variant) {
        case ("scrolling", "smooth"):
            springDamping = 0.9
            springResponse = 0.4
        case ("scrolling", "bouncy"):
            springDamping = 0.6
            springResponse = 0.6
        case ("animations", "minimal"):
            progressiveRevealEnabled = false
            floatingButtonEnabled = false
        case ("animations", "rich"):
            progressiveRevealEnabled = true
            floatingButtonEnabled = true
            parallaxEnabled = true
        default:
            break
        }
    }
    
    func getExperimentVariant(_ experimentId: String) -> String? {
        return experimentGroups[experimentId]
    }
    
    // MARK: - Performance Monitoring
    
    func trackScrollPattern(offset: CGFloat, velocity: CGFloat) {
        guard scrollPatternTracking else { return }
        
        // Track scroll patterns for analytics
        let pattern = ScrollPattern(
            timestamp: Date(),
            offset: offset,
            velocity: velocity
        )
        
        AnalyticsManager.shared.track(pattern)
    }
    
    func reportPerformanceMetrics(fps: Double, memory: Double) {
        guard performanceMetricsEnabled else { return }
        
        let metrics = PerformanceMetrics(
            fps: fps,
            memoryUsage: memory,
            timestamp: Date()
        )
        
        AnalyticsManager.shared.track(metrics)
    }
    
    enum AnimationType {
        case parallax
        case progressiveReveal
        case floatingButton
        case pullToRefresh
        case stickyHeaders
        case scrollIndicator
    }
}

// MARK: - Configuration View
struct ConfigurationView: View {
    @StateObject private var config = FormatFinderConfig.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                AnimationSettingsView()
                    .tabItem {
                        Label("Animations", systemImage: "wand.and.rays")
                    }
                    .tag(0)
                
                PerformanceSettingsView()
                    .tabItem {
                        Label("Performance", systemImage: "speedometer")
                    }
                    .tag(1)
                
                DebugSettingsView()
                    .tabItem {
                        Label("Debug", systemImage: "ant.circle")
                    }
                    .tag(2)
                
                ExperimentSettingsView()
                    .tabItem {
                        Label("Experiments", systemImage: "flask")
                    }
                    .tag(3)
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AnimationSettingsView: View {
    @StateObject private var config = FormatFinderConfig.shared
    
    var body: some View {
        Form {
            Section("Animation Controls") {
                Toggle("Enable All Animations", isOn: $config.animationsEnabled)
                Toggle("Parallax Effect", isOn: $config.parallaxEnabled)
                Toggle("Progressive Reveal", isOn: $config.progressiveRevealEnabled)
                Toggle("Haptic Feedback", isOn: $config.hapticFeedbackEnabled)
                Toggle("Floating Button", isOn: $config.floatingButtonEnabled)
                Toggle("Pull to Refresh", isOn: $config.pullToRefreshEnabled)
                Toggle("Sticky Headers", isOn: $config.stickyHeadersEnabled)
                Toggle("Scroll Indicator", isOn: $config.scrollIndicatorEnabled)
            }
            
            Section("Animation Speed") {
                HStack {
                    Text("Global Speed")
                    Slider(value: $config.globalAnimationSpeed, in: 0.1...2.0)
                    Text("\(config.globalAnimationSpeed, specifier: "%.1f")x")
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Spring Response")
                    Slider(value: $config.springResponse, in: 0.1...1.0)
                    Text("\(config.springResponse, specifier: "%.2f")")
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Spring Damping")
                    Slider(value: $config.springDamping, in: 0.1...1.0)
                    Text("\(config.springDamping, specifier: "%.2f")")
                        .monospacedDigit()
                }
            }
        }
    }
}

struct PerformanceSettingsView: View {
    @StateObject private var config = FormatFinderConfig.shared
    
    var body: some View {
        Form {
            Section("Performance") {
                Stepper("Max Animations: \(config.maxConcurrentAnimations)", 
                       value: $config.maxConcurrentAnimations, in: 1...10)
                
                Stepper("Image Cache: \(config.imageCacheSize) MB", 
                       value: $config.imageCacheSize, in: 50...500, step: 50)
                
                Toggle("View Recycling", isOn: $config.viewRecyclingEnabled)
                
                HStack {
                    Text("Lazy Load Threshold")
                    Slider(value: $config.lazyLoadingThreshold, in: 50...300)
                    Text("\(Int(config.lazyLoadingThreshold))pt")
                        .monospacedDigit()
                }
            }
            
            Section("Analytics") {
                Toggle("Enable Analytics", isOn: $config.analyticsEnabled)
                Toggle("Track Scroll Patterns", isOn: $config.scrollPatternTracking)
                Toggle("Performance Metrics", isOn: $config.performanceMetricsEnabled)
            }
        }
    }
}

struct DebugSettingsView: View {
    @StateObject private var config = FormatFinderConfig.shared
    
    var body: some View {
        Form {
            Section("Debug Options") {
                Toggle("Debug Mode", isOn: $config.debugMode)
                Toggle("Show FPS Counter", isOn: $config.showFPSCounter)
                Toggle("Show Memory Usage", isOn: $config.showMemoryUsage)
                Toggle("Animation Timeline", isOn: $config.showAnimationTimeline)
                Toggle("Visualize Scroll Velocity", isOn: $config.visualizeScrollVelocity)
            }
            
            Section("Actions") {
                Button("Enable All Debug Options") {
                    config.enableDebugVisualization()
                }
                
                Button("Disable All Animations") {
                    config.disableAllAnimations()
                }
                .foregroundColor(.red)
                
                Button("Reset to Defaults") {
                    // Reset implementation
                }
            }
        }
    }
}

struct ExperimentSettingsView: View {
    @StateObject private var config = FormatFinderConfig.shared
    
    var body: some View {
        Form {
            Section("Active Experiments") {
                if config.activeExperiments.isEmpty {
                    Text("No active experiments")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(config.activeExperiments), id: \.self) { experiment in
                        HStack {
                            Text(experiment)
                            Spacer()
                            Text(config.experimentGroups[experiment] ?? "unknown")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Remote Config") {
                Toggle("Enable Remote Config", isOn: $config.remoteConfigEnabled)
                HStack {
                    Text("Config Version")
                    Spacer()
                    Text(config.configVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Analytics Support
struct ScrollPattern {
    let timestamp: Date
    let offset: CGFloat
    let velocity: CGFloat
}

struct PerformanceMetrics {
    let fps: Double
    let memoryUsage: Double
    let timestamp: Date
}

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    func track(_ pattern: ScrollPattern) {
        // Analytics implementation
    }
    
    func track(_ metrics: PerformanceMetrics) {
        // Analytics implementation
    }
}