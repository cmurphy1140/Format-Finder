import SwiftUI
import Combine

// MARK: - Performance Monitor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var memoryUsage: Float = 0
    @Published var cpuUsage: Float = 0
    @Published var fps: Int = 60
    
    private var cancellables = Set<AnyCancellable>()
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        // Monitor memory
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
        
        // Monitor FPS
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Float(info.resident_size) / 1024.0 / 1024.0
            DispatchQueue.main.async {
                self.memoryUsage = usedMemory
            }
        }
    }
    
    @objc private func updateFPS(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let elapsed = displayLink.timestamp - lastTimestamp
        
        if elapsed >= 1.0 {
            DispatchQueue.main.async {
                self.fps = self.frameCount
            }
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
    
    func logPerformance(event: String) {
        print("[Performance] \(event) - Memory: \(memoryUsage)MB, FPS: \(fps)")
    }
}

// MARK: - Lazy Loading Container
struct LazyContainer<Content: View>: View {
    let threshold: CGFloat
    let content: () -> Content
    @State private var hasAppeared = false
    
    init(threshold: CGFloat = 100, @ViewBuilder content: @escaping () -> Content) {
        self.threshold = threshold
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            if hasAppeared {
                content()
            } else {
                Color.clear
                    .onAppear {
                        if geometry.frame(in: .global).minY < UIScreen.main.bounds.height + threshold {
                            hasAppeared = true
                        }
                    }
            }
        }
    }
}

// MARK: - Image Cache Manager
class ImageCacheManager {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func store(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.pngData()?.count ?? 0)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Optimized List
struct OptimizedList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var visibleIndices = Set<Int>()
    
    init(_ data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .onAppear {
                            visibleIndices.insert(index)
                        }
                        .onDisappear {
                            visibleIndices.remove(index)
                        }
                }
            }
        }
    }
}

// MARK: - Debounced Search
class DebouncedSearchModel: ObservableObject {
    @Published var searchText = ""
    @Published var debouncedSearchText = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(delay: TimeInterval = 0.5) {
        $searchText
            .debounce(for: .seconds(delay), scheduler: DispatchQueue.main)
            .assign(to: &$debouncedSearchText)
    }
}

// MARK: - Memory-Efficient Data Store
actor DataStore<T: Codable> {
    private var cache: [String: T] = [:]
    private let maxCacheSize: Int
    private var accessOrder: [String] = []
    
    init(maxCacheSize: Int = 100) {
        self.maxCacheSize = maxCacheSize
    }
    
    func get(_ key: String) async -> T? {
        if let value = cache[key] {
            // Update access order for LRU
            accessOrder.removeAll { $0 == key }
            accessOrder.append(key)
            return value
        }
        return nil
    }
    
    func set(_ key: String, value: T) async {
        cache[key] = value
        accessOrder.append(key)
        
        // Implement LRU eviction
        if cache.count > maxCacheSize {
            if let oldestKey = accessOrder.first {
                cache.removeValue(forKey: oldestKey)
                accessOrder.removeFirst()
            }
        }
    }
    
    func clear() async {
        cache.removeAll()
        accessOrder.removeAll()
    }
}

// MARK: - Render Optimization
struct RenderOptimized<Content: View>: View {
    let content: Content
    @State private var renderID = UUID()
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .drawingGroup() // Flatten view hierarchy for better performance
            .id(renderID)
    }
    
    func forceRender() {
        renderID = UUID()
    }
}

// MARK: - Batch Updates
class BatchUpdateManager<T> {
    private var pendingUpdates: [T] = []
    private var updateTimer: Timer?
    private let batchSize: Int
    private let updateHandler: ([T]) -> Void
    
    init(batchSize: Int = 10, updateHandler: @escaping ([T]) -> Void) {
        self.batchSize = batchSize
        self.updateHandler = updateHandler
    }
    
    func add(_ update: T) {
        pendingUpdates.append(update)
        
        if pendingUpdates.count >= batchSize {
            flush()
        } else {
            scheduleFlush()
        }
    }
    
    private func scheduleFlush() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            self.flush()
        }
    }
    
    private func flush() {
        guard !pendingUpdates.isEmpty else { return }
        
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        updateHandler(updates)
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
}

// MARK: - Preloader
class ContentPreloader {
    static let shared = ContentPreloader()
    private var preloadTasks: [String: Task<Void, Never>] = [:]
    
    private init() {}
    
    func preload(id: String, task: @escaping () async -> Void) {
        guard preloadTasks[id] == nil else { return }
        
        preloadTasks[id] = Task {
            await task()
            preloadTasks.removeValue(forKey: id)
        }
    }
    
    func cancelPreload(id: String) {
        preloadTasks[id]?.cancel()
        preloadTasks.removeValue(forKey: id)
    }
    
    func cancelAll() {
        preloadTasks.values.forEach { $0.cancel() }
        preloadTasks.removeAll()
    }
}

// MARK: - Performance Optimized View
struct PerformanceOptimizedView: ViewModifier {
    @StateObject private var monitor = PerformanceMonitor.shared
    let showDebugInfo: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if showDebugInfo {
                VStack {
                    HStack {
                        Text("FPS: \(monitor.fps)")
                        Text("Memory: \(String(format: "%.1f", monitor.memoryUsage))MB")
                    }
                    .font(.caption)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

extension View {
    func performanceOptimized(showDebugInfo: Bool = false) -> some View {
        modifier(PerformanceOptimizedView(showDebugInfo: showDebugInfo))
    }
}