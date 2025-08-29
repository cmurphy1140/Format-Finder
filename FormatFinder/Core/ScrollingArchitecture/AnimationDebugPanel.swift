import SwiftUI
import QuartzCore

class AnimationMonitor: ObservableObject {
    @Published var activeAnimations: Int = 0
    @Published var frameRate: Double = 60.0
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var lastTimestamp: CFTimeInterval = 0
    private var animationQueue: Set<UUID> = []
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        displayLink?.add(to: .main, forMode: .common)
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateMemoryUsage()
            self.updateCPUUsage()
        }
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateFrameRate(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let elapsed = displayLink.timestamp - lastTimestamp
        
        if elapsed >= 1.0 {
            frameRate = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            memoryUsage = Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
    }
    
    private func updateCPUUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let userTime = info.user_time
            let systemTime = info.system_time
            let totalTime = Double(userTime.seconds) + Double(userTime.microseconds) / 1_000_000 +
                           Double(systemTime.seconds) + Double(systemTime.microseconds) / 1_000_000
            cpuUsage = min(totalTime * 100, 100) // Cap at 100%
        }
    }
    
    func registerAnimation(id: UUID) {
        animationQueue.insert(id)
        activeAnimations = animationQueue.count
    }
    
    func unregisterAnimation(id: UUID) {
        animationQueue.remove(id)
        activeAnimations = animationQueue.count
    }
}

struct AnimationDebugPanel: View {
    @StateObject private var monitor = AnimationMonitor()
    @State private var isExpanded = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Compact view
            HStack(spacing: 8) {
                if !isExpanded {
                    Image(systemName: "speedometer")
                        .font(.caption)
                    Text("\(Int(monitor.frameRate)) FPS")
                        .font(.caption.monospacedDigit())
                }
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.8))
            )
            
            // Expanded view
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    PerformanceRow(
                        icon: "speedometer",
                        label: "Frame Rate",
                        value: "\(Int(monitor.frameRate)) FPS",
                        status: frameRateStatus
                    )
                    
                    PerformanceRow(
                        icon: "play.circle",
                        label: "Active Animations",
                        value: "\(monitor.activeAnimations)",
                        status: animationStatus
                    )
                    
                    PerformanceRow(
                        icon: "memorychip",
                        label: "Memory",
                        value: String(format: "%.1f MB", monitor.memoryUsage),
                        status: memoryStatus
                    )
                    
                    PerformanceRow(
                        icon: "cpu",
                        label: "CPU",
                        value: String(format: "%.1f%%", monitor.cpuUsage),
                        status: cpuStatus
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    Button(action: { showDetails.toggle() }) {
                        HStack {
                            Text("Advanced Details")
                                .font(.caption2)
                            Spacer()
                            Image(systemName: "info.circle")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.9))
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .foregroundColor(.white)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .sheet(isPresented: $showDetails) {
            AdvancedDebugView(monitor: monitor)
        }
    }
    
    private var frameRateStatus: PerformanceStatus {
        if monitor.frameRate >= 55 { return .good }
        if monitor.frameRate >= 45 { return .warning }
        return .critical
    }
    
    private var animationStatus: PerformanceStatus {
        if monitor.activeAnimations <= 5 { return .good }
        if monitor.activeAnimations <= 10 { return .warning }
        return .critical
    }
    
    private var memoryStatus: PerformanceStatus {
        if monitor.memoryUsage < 100 { return .good }
        if monitor.memoryUsage < 200 { return .warning }
        return .critical
    }
    
    private var cpuStatus: PerformanceStatus {
        if monitor.cpuUsage < 50 { return .good }
        if monitor.cpuUsage < 80 { return .warning }
        return .critical
    }
}

struct PerformanceRow: View {
    let icon: String
    let label: String
    let value: String
    let status: PerformanceStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(status.color)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .frame(minWidth: 80, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundColor(status.color)
        }
    }
}

enum PerformanceStatus {
    case good, warning, critical
    
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}

struct AdvancedDebugView: View {
    @ObservedObject var monitor: AnimationMonitor
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Performance Metrics") {
                    MetricRow(label: "Frame Rate", value: "\(Int(monitor.frameRate)) FPS")
                    MetricRow(label: "Target Frame Rate", value: "60 FPS")
                    MetricRow(label: "Frame Drops", value: "\(max(0, 60 - Int(monitor.frameRate)))")
                }
                
                Section("Animation Queue") {
                    MetricRow(label: "Active Animations", value: "\(monitor.activeAnimations)")
                    MetricRow(label: "Queue Capacity", value: "Unlimited")
                    MetricRow(label: "Animation Type", value: "Spring & Ease")
                }
                
                Section("Resource Usage") {
                    MetricRow(label: "Memory Usage", value: String(format: "%.2f MB", monitor.memoryUsage))
                    MetricRow(label: "CPU Usage", value: String(format: "%.2f%%", monitor.cpuUsage))
                    MetricRow(label: "GPU Usage", value: "Not Available")
                }
                
                Section("Optimization Tips") {
                    Text("• Reduce concurrent animations")
                        .font(.caption)
                    Text("• Use simpler animation curves")
                        .font(.caption)
                    Text("• Minimize view hierarchy depth")
                        .font(.caption)
                    Text("• Cache computed values")
                        .font(.caption)
                }
            }
            .navigationTitle("Animation Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
    }
}