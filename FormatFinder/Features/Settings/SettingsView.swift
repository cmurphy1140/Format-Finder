import SwiftUI
import UIKit

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    @State private var hapticIntensity: Double = 1.0
    
    var body: some View {
        NavigationView {
            Form {
                // Player Preferences Section
                playerPreferencesSection
                
                // Gameplay Options Section  
                gameplayOptionsSection
                
                // Display & Sound Section
                displayAndSoundSection
                
                // Data Management Section
                dataManagementSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    // MARK: - Player Preferences Section
    private var playerPreferencesSection: some View {
        Section {
            HStack {
                Label("Default Name", systemImage: "person.fill")
                    .foregroundColor(.primary)
                Spacer()
                TextField("Player", text: $settings.defaultPlayerName)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
            }
            
            Picker("Preferred Tees", selection: $settings.preferredTees) {
                ForEach(TeeBox.allCases) { tee in
                    Label(tee.name, systemImage: tee.icon)
                        .tag(tee)
                }
            }
            
            Stepper(
                "Default Handicap: \(settings.defaultHandicap)",
                value: $settings.defaultHandicap,
                in: 0...54
            )
            
            Toggle(isOn: $settings.autoCalculateHandicap) {
                Label("Auto-Calculate Handicap", systemImage: "function")
            }
            
        } header: {
            Text("Player Preferences")
        } footer: {
            Text("These defaults will be used when creating new games")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Gameplay Options Section
    private var gameplayOptionsSection: some View {
        Section {
            Toggle(isOn: $settings.paceOfPlayAlerts) {
                Label("Pace of Play Alerts", systemImage: "timer")
            }
            
            if settings.paceOfPlayAlerts {
                Picker("Target Pace", selection: $settings.targetPaceMinutes) {
                    Text("Fast (210 min)").tag(210)
                    Text("Normal (240 min)").tag(240)
                    Text("Relaxed (270 min)").tag(270)
                }
                .pickerStyle(.segmented)
            }
            
            Toggle(isOn: $settings.autoAdvanceHoles) {
                Label("Auto-Advance Holes", systemImage: "arrow.right.circle")
            }
            
            Toggle(isOn: $settings.confirmExceptionalScores) {
                Label("Confirm Exceptional Scores", systemImage: "exclamationmark.triangle")
            }
            
            Toggle(isOn: $settings.showShotTracking) {
                Label("Shot-by-Shot Tracking", systemImage: "scope")
            }
            
        } header: {
            Text("Gameplay Options")
        } footer: {
            Text("Customize how the app behaves during your round")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Display & Sound Section
    private var displayAndSoundSection: some View {
        Section {
            Toggle(isOn: $settings.hapticFeedback) {
                Label("Haptic Feedback", systemImage: "hand.tap")
            }
            
            if settings.hapticFeedback {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Intensity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "hand.tap")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: $settings.hapticIntensity,
                            in: 0.25...1.0,
                            step: 0.25
                        ) {
                            Text("Haptic Intensity")
                        } onEditingChanged: { editing in
                            if !editing {
                                // Test haptic at selected intensity
                                testHaptic()
                            }
                        }
                        
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(hapticIntensityText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Toggle(isOn: $settings.soundEffects) {
                Label("Sound Effects", systemImage: "speaker.wave.2")
            }
            
            Toggle(isOn: $settings.celebrationAnimations) {
                Label("Celebration Animations", systemImage: "sparkles")
            }
            
            Picker("Color Theme", selection: $settings.colorTheme) {
                ForEach(ColorTheme.allCases) { theme in
                    Label(theme.name, systemImage: theme.icon)
                        .tag(theme)
                }
            }
            
            Toggle(isOn: $settings.largeTextMode) {
                Label("Large Text", systemImage: "textformat.size")
            }
            
        } header: {
            Text("Display & Sound")
        }
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        Section {
            Button(action: clearRecentSearches) {
                Label("Clear Recent Searches", systemImage: "magnifyingglass.circle")
                    .foregroundColor(.primary)
            }
            
            Button(action: clearRecentlyPlayed) {
                Label("Clear Recently Played", systemImage: "clock.arrow.circlepath")
                    .foregroundColor(.primary)
            }
            
            Button(action: exportData) {
                Label("Export Game Data", systemImage: "square.and.arrow.up")
                    .foregroundColor(.primary)
            }
            
            Button(action: { showingResetAlert = true }) {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.red)
            }
            
        } header: {
            Text("Data Management")
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(AppInfo.version)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(AppInfo.build)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { showingAbout = true }) {
                HStack {
                    Text("About Format Finder")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            Link(destination: URL(string: "https://www.usga.org/rules")!) {
                HStack {
                    Label("Official Golf Rules", systemImage: "book")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Link(destination: URL(string: "https://www.usga.org/handicapping")!) {
                HStack {
                    Label("Handicap System", systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Helper Functions
    
    private var hapticIntensityText: String {
        switch settings.hapticIntensity {
        case 0.25: return "Light"
        case 0.5: return "Medium"
        case 0.75: return "Strong"
        case 1.0: return "Maximum"
        default: return "Custom"
        }
    }
    
    private func testHaptic() {
        let intensity = settings.hapticIntensity
        if intensity <= 0.25 {
            HapticManager.impact(.soft)
        } else if intensity <= 0.5 {
            HapticManager.impact(.light)
        } else if intensity <= 0.75 {
            HapticManager.impact(.medium)
        } else {
            HapticManager.impact(.heavy)
        }
    }
    
    private func clearRecentSearches() {
        SearchService().clearRecentSearches()
    }
    
    private func clearRecentlyPlayed() {
        // Clear recently played formats
        UserDefaults.standard.removeObject(forKey: "RecentlyPlayed")
    }
    
    private func exportData() {
        // Implement data export functionality
        // This would typically create a JSON/CSV file with game history
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // App Icon and Name
                    VStack(spacing: 12) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, Color(red: 0.2, green: 0.6, blue: 0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(radius: 10)
                        
                        Text("Format Finder")
                            .font(.largeTitle.bold())
                        
                        Text("Master Every Golf Format")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Description
                    Text("Format Finder is your comprehensive guide to golf game formats. Learn new ways to play, track scores accurately, and make every round more enjoyable.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(
                            icon: "gamecontroller",
                            title: "13+ Game Formats",
                            description: "From classic Stroke Play to complex Wolf"
                        )
                        
                        FeatureRow(
                            icon: "chart.bar",
                            title: "Smart Scoring",
                            description: "Automatic calculations for every format"
                        )
                        
                        FeatureRow(
                            icon: "person.2",
                            title: "Group Recommendations",
                            description: "AI suggests the best format for your group"
                        )
                        
                        FeatureRow(
                            icon: "sparkles",
                            title: "Interactive Learning",
                            description: "Visual tutorials and simulators"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Credits
                    VStack(spacing: 8) {
                        Text("Designed with love for golfers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("© 2024 Format Finder")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - App Settings Model
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // Player Preferences
    @AppStorage("defaultPlayerName") var defaultPlayerName = "Player"
    @AppStorage("preferredTees") private var preferredTeesRaw = "white"
    @AppStorage("defaultHandicap") var defaultHandicap = 15
    @AppStorage("autoCalculateHandicap") var autoCalculateHandicap = false
    
    // Gameplay Options
    @AppStorage("paceOfPlayAlerts") var paceOfPlayAlerts = false
    @AppStorage("targetPaceMinutes") var targetPaceMinutes = 240
    @AppStorage("autoAdvanceHoles") var autoAdvanceHoles = true
    @AppStorage("confirmExceptionalScores") var confirmExceptionalScores = true
    @AppStorage("showShotTracking") var showShotTracking = false
    
    // Display & Sound
    @AppStorage("hapticFeedback") var hapticFeedback = true
    @AppStorage("hapticIntensity") var hapticIntensity = 0.75
    @AppStorage("soundEffects") var soundEffects = true
    @AppStorage("celebrationAnimations") var celebrationAnimations = true
    @AppStorage("colorThemeRaw") private var colorThemeRaw = "classic"
    @AppStorage("largeTextMode") var largeTextMode = false
    
    var preferredTees: TeeBox {
        get { TeeBox(rawValue: preferredTeesRaw) ?? .white }
        set { preferredTeesRaw = newValue.rawValue }
    }
    
    var colorTheme: ColorTheme {
        get { ColorTheme(rawValue: colorThemeRaw) ?? .classic }
        set { colorThemeRaw = newValue.rawValue }
    }
    
    func resetToDefaults() {
        defaultPlayerName = "Player"
        preferredTeesRaw = "white"
        defaultHandicap = 15
        autoCalculateHandicap = false
        paceOfPlayAlerts = false
        targetPaceMinutes = 240
        autoAdvanceHoles = true
        confirmExceptionalScores = true
        showShotTracking = false
        hapticFeedback = true
        hapticIntensity = 0.75
        soundEffects = true
        celebrationAnimations = true
        colorThemeRaw = "classic"
        largeTextMode = false
    }
}

// MARK: - Supporting Types
enum TeeBox: String, CaseIterable, Identifiable {
    case black = "black"
    case blue = "blue"
    case white = "white"
    case gold = "gold"
    case red = "red"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .black: return "Black"
        case .blue: return "Blue"
        case .white: return "White"
        case .gold: return "Gold/Senior"
        case .red: return "Red/Forward"
        }
    }
    
    var icon: String {
        switch self {
        case .black: return "flag.fill"
        case .blue: return "flag"
        case .white: return "flag"
        case .gold: return "star"
        case .red: return "arrow.up.forward"
        }
    }
}

enum ColorTheme: String, CaseIterable, Identifiable {
    case classic = "classic"
    case modern = "modern"
    case dark = "dark"
    case nature = "nature"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .classic: return "Classic Green"
        case .modern: return "Modern Blue"
        case .dark: return "Dark Mode"
        case .nature: return "Nature"
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "leaf"
        case .modern: return "paintbrush"
        case .dark: return "moon"
        case .nature: return "tree"
        }
    }
}

// MARK: - App Info
struct AppInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}