import Foundation

// MARK: - Feature Flags

/// Manages feature flags for gradual migration to new data layer
final class FeatureFlags {
    static let shared = FeatureFlags()
    
    private let userDefaults: UserDefaults
    private let remoteConfig: RemoteConfigService?
    
    private init(
        userDefaults: UserDefaults = .standard,
        remoteConfig: RemoteConfigService? = nil
    ) {
        self.userDefaults = userDefaults
        self.remoteConfig = remoteConfig
    }
    
    // MARK: - Feature Flags
    
    /// Use new Redux-style state management instead of @StateObject
    var useNewStateManagement: Bool {
        getValue(for: .newStateManagement, default: false)
    }
    
    /// Use Core Data for persistence instead of in-memory storage
    var useCoreDataPersistence: Bool {
        getValue(for: .coreDataPersistence, default: false)
    }
    
    /// Enable CloudKit sync
    var useCloudKitSync: Bool {
        getValue(for: .cloudKitSync, default: false)
    }
    
    /// Use new protocol-based game engine
    var useNewGameEngine: Bool {
        getValue(for: .newGameEngine, default: false)
    }
    
    /// Enable time-travel debugging in scorecards
    var enableTimeTravelDebugging: Bool {
        getValue(for: .timeTravelDebugging, default: false)
    }
    
    /// Enable analytics collection
    var enableAnalytics: Bool {
        getValue(for: .analytics, default: false)
    }
    
    /// Enable performance monitoring
    var enablePerformanceMonitoring: Bool {
        getValue(for: .performanceMonitoring, default: false)
    }
    
    /// Gradual migration per format
    func useNewSystemForFormat(_ format: FormatType) -> Bool {
        getValue(for: FeatureFlag(rawValue: "new_system_\(format.rawValue)") ?? .newStateManagement, default: false)
    }
    
    // MARK: - Configuration
    
    func enableFeature(_ flag: FeatureFlag) {
        setValue(true, for: flag)
    }
    
    func disableFeature(_ flag: FeatureFlag) {
        setValue(false, for: flag)
    }
    
    func toggleFeature(_ flag: FeatureFlag) {
        let currentValue = getValue(for: flag, default: false)
        setValue(!currentValue, for: flag)
    }
    
    func resetToDefaults() {
        FeatureFlag.allCases.forEach { flag in
            userDefaults.removeObject(forKey: flag.rawValue)
        }
    }
    
    // MARK: - Migration Helpers
    
    /// Enable new system gradually by format
    func enableNewSystemForFormat(_ format: FormatType) {
        let flag = FeatureFlag(rawValue: "new_system_\(format.rawValue)") ?? .newStateManagement
        setValue(true, for: flag)
    }
    
    /// Check migration status
    var migrationStatus: MigrationStatus {
        let totalFormats = FormatType.allCases.count
        let migratedFormats = FormatType.allCases.filter { useNewSystemForFormat($0) }.count
        
        if migratedFormats == 0 {
            return .notStarted
        } else if migratedFormats < totalFormats {
            return .inProgress(migratedFormats, totalFormats)
        } else {
            return .completed
        }
    }
    
    // MARK: - Private Methods
    
    private func getValue(for flag: FeatureFlag, default defaultValue: Bool) -> Bool {
        // Check remote config first
        if let remoteValue = remoteConfig?.getValue(for: flag.rawValue) {
            return remoteValue
        }
        
        // Fall back to local UserDefaults
        if userDefaults.object(forKey: flag.rawValue) != nil {
            return userDefaults.bool(forKey: flag.rawValue)
        }
        
        // Return default value
        return defaultValue
    }
    
    private func setValue(_ value: Bool, for flag: FeatureFlag) {
        userDefaults.set(value, forKey: flag.rawValue)
    }
}

// MARK: - Feature Flag Enum

enum FeatureFlag: String, CaseIterable {
    case newStateManagement = "feature_new_state_management"
    case coreDataPersistence = "feature_core_data_persistence"
    case cloudKitSync = "feature_cloudkit_sync"
    case newGameEngine = "feature_new_game_engine"
    case timeTravelDebugging = "feature_time_travel_debugging"
    case analytics = "feature_analytics"
    case performanceMonitoring = "feature_performance_monitoring"
}

// MARK: - Migration Status

enum MigrationStatus {
    case notStarted
    case inProgress(Int, Int)  // (completed, total)
    case completed
    
    var description: String {
        switch self {
        case .notStarted:
            return "Migration not started"
        case .inProgress(let completed, let total):
            return "Migration in progress: \(completed)/\(total) formats migrated"
        case .completed:
            return "Migration completed"
        }
    }
    
    var progress: Double {
        switch self {
        case .notStarted:
            return 0.0
        case .inProgress(let completed, let total):
            return Double(completed) / Double(total)
        case .completed:
            return 1.0
        }
    }
}

// MARK: - Remote Config Service (Stub)

protocol RemoteConfigService {
    func getValue(for key: String) -> Bool?
    func fetch() async throws
}

// MARK: - Debug Settings View

import SwiftUI

struct FeatureFlagsDebugView: View {
    @State private var flags = FeatureFlags.shared
    @State private var migrationStatus = FeatureFlags.shared.migrationStatus
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Core Features")) {
                    Toggle("New State Management", isOn: binding(for: .newStateManagement))
                    Toggle("Core Data Persistence", isOn: binding(for: .coreDataPersistence))
                    Toggle("CloudKit Sync", isOn: binding(for: .cloudKitSync))
                    Toggle("New Game Engine", isOn: binding(for: .newGameEngine))
                }
                
                Section(header: Text("Debug Features")) {
                    Toggle("Time Travel Debugging", isOn: binding(for: .timeTravelDebugging))
                    Toggle("Analytics", isOn: binding(for: .analytics))
                    Toggle("Performance Monitoring", isOn: binding(for: .performanceMonitoring))
                }
                
                Section(header: Text("Format-Specific Migration")) {
                    ForEach(FormatType.allCases, id: \.self) { format in
                        HStack {
                            Text(format.rawValue)
                            Spacer()
                            Toggle("", isOn: formatBinding(for: format))
                                .labelsHidden()
                        }
                    }
                }
                
                Section(header: Text("Migration Status")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(migrationStatus.description)
                            .font(.caption)
                        
                        ProgressView(value: migrationStatus.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button("Enable All Features") {
                        enableAllFeatures()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to Defaults") {
                        resetFeatures()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Feature Flags")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func binding(for flag: FeatureFlag) -> Binding<Bool> {
        Binding(
            get: {
                switch flag {
                case .newStateManagement: return flags.useNewStateManagement
                case .coreDataPersistence: return flags.useCoreDataPersistence
                case .cloudKitSync: return flags.useCloudKitSync
                case .newGameEngine: return flags.useNewGameEngine
                case .timeTravelDebugging: return flags.enableTimeTravelDebugging
                case .analytics: return flags.enableAnalytics
                case .performanceMonitoring: return flags.enablePerformanceMonitoring
                }
            },
            set: { value in
                if value {
                    flags.enableFeature(flag)
                } else {
                    flags.disableFeature(flag)
                }
                migrationStatus = flags.migrationStatus
            }
        )
    }
    
    private func formatBinding(for format: FormatType) -> Binding<Bool> {
        Binding(
            get: { flags.useNewSystemForFormat(format) },
            set: { value in
                if value {
                    flags.enableNewSystemForFormat(format)
                } else {
                    // Disable format-specific flag
                    let flag = FeatureFlag(rawValue: "new_system_\(format.rawValue)") ?? .newStateManagement
                    flags.disableFeature(flag)
                }
                migrationStatus = flags.migrationStatus
            }
        )
    }
    
    private func enableAllFeatures() {
        FeatureFlag.allCases.forEach { flags.enableFeature($0) }
        FormatType.allCases.forEach { flags.enableNewSystemForFormat($0) }
        migrationStatus = flags.migrationStatus
    }
    
    private func resetFeatures() {
        flags.resetToDefaults()
        migrationStatus = flags.migrationStatus
    }
}