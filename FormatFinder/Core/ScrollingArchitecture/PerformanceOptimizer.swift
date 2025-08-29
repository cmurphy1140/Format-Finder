import SwiftUI
import QuartzCore
import Combine

// MARK: - Performance Optimization Layer
class PerformanceOptimizer: NSObject, ObservableObject {
    static let shared = PerformanceOptimizer()
    
    @Published var currentFPS: Double = 60.0
    @Published var isOptimizationEnabled = true
    
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount = 0
    private var animationBatch: [AnimationTask] = []
    private let batchQueue = DispatchQueue(label: "animation.batch", qos: .userInteractive)
    
    // Debouncing
    private var scrollDebouncer: AnyCancellable?
    private let scrollSubject = PassthroughSubject<CGFloat, Never>()
    
    // View recycling
    private let viewPool = ViewRecyclingPool()
    
    // Image cache
    private let imageCache = ImageCacheManager()
    
    struct AnimationTask {
        let id: UUID
        let priority: Int
        let animation: () -> Void
    }
    
    override init() {
        super.init()
        setupDisplayLink()
        setupDebouncer()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func setupDebouncer() {
        scrollDebouncer = scrollSubject
            .debounce(for: .milliseconds(16), scheduler: RunLoop.main)
            .sink { [weak self] offset in
                self?.handleDebouncedScroll(offset: offset)
            }
    }
    
    @objc private func displayLinkFired(_ displayLink: CADisplayLink) {
        if lastFrameTime == 0 {
            lastFrameTime = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let elapsed = displayLink.timestamp - lastFrameTime
        
        if elapsed >= 1.0 {
            currentFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastFrameTime = displayLink.timestamp
            
            // Adjust optimization based on FPS
            adjustOptimizationLevel()
        }
        
        // Process animation batch
        processAnimationBatch()
    }
    
    private func adjustOptimizationLevel() {
        if currentFPS < 30 {
            // Critical performance - maximum optimization
            enableAggressiveOptimization()
        } else if currentFPS < 50 {
            // Moderate performance - balanced optimization
            enableModerateOptimization()
        } else {
            // Good performance - minimal optimization
            enableMinimalOptimization()
        }
    }
    
    private func enableAggressiveOptimization() {
        isOptimizationEnabled = true
        viewPool.maxPoolSize = 3
        imageCache.maxMemorySize = 50 // MB
    }
    
    private func enableModerateOptimization() {
        isOptimizationEnabled = true
        viewPool.maxPoolSize = 5
        imageCache.maxMemorySize = 100 // MB
    }
    
    private func enableMinimalOptimization() {
        isOptimizationEnabled = false
        viewPool.maxPoolSize = 10
        imageCache.maxMemorySize = 200 // MB
    }
    
    func handleScroll(_ offset: CGFloat) {
        scrollSubject.send(offset)
    }
    
    private func handleDebouncedScroll(offset: CGFloat) {
        // Process scroll after debouncing
        NotificationCenter.default.post(
            name: .debouncedScrollUpdate,
            object: nil,
            userInfo: ["offset": offset]
        )
    }
    
    func batchAnimation(_ task: AnimationTask) {
        batchQueue.async { [weak self] in
            self?.animationBatch.append(task)
            self?.animationBatch.sort { $0.priority > $1.priority }
        }
    }
    
    private func processAnimationBatch() {
        guard !animationBatch.isEmpty else { return }
        
        batchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let tasksToProcess = self.animationBatch.prefix(3) // Process top 3 priority
            
            DispatchQueue.main.async {
                tasksToProcess.forEach { $0.animation() }
            }
            
            self.animationBatch.removeFirst(min(3, self.animationBatch.count))
        }
    }
    
    deinit {
        displayLink?.invalidate()
        scrollDebouncer?.cancel()
    }
}

// MARK: - View Recycling Pool
class ViewRecyclingPool {
    var maxPoolSize = 5
    private var pool: [String: AnyView] = [:]
    private var accessOrder: [String] = []
    
    func getView<T: View>(id: String, create: () -> T) -> AnyView {
        if let cached = pool[id] {
            // Move to end (most recently used)
            if let index = accessOrder.firstIndex(of: id) {
                accessOrder.remove(at: index)
            }
            accessOrder.append(id)
            return cached
        }
        
        let newView = AnyView(create())
        pool[id] = newView
        accessOrder.append(id)
        
        // Maintain pool size
        if pool.count > maxPoolSize {
            if let lru = accessOrder.first {
                pool.removeValue(forKey: lru)
                accessOrder.removeFirst()
            }
        }
        
        return newView
    }
    
    func recycle(id: String) {
        pool.removeValue(forKey: id)
        if let index = accessOrder.firstIndex(of: id) {
            accessOrder.remove(at: index)
        }
    }
}

// MARK: - Image Cache Manager
class ImageCacheManager: ObservableObject {
    var maxMemorySize: Int = 100 // MB
    private let cache = NSCache<NSString, UIImage>()
    @Published var currentMemoryUsage: Int = 0
    
    init() {
        cache.totalCostLimit = maxMemorySize * 1024 * 1024
        setupMemoryWarningObserver()
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        cache.removeAllObjects()
        currentMemoryUsage = 0
    }
    
    func cache(image: UIImage, for key: String) {
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
        currentMemoryUsage += cost / (1024 * 1024)
    }
    
    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func preloadImages(urls: [String]) {
        urls.forEach { url in
            if image(for: url) == nil {
                // Simulate loading - in production, load from network/disk
                if let image = UIImage(systemName: "photo") {
                    cache(image: image, for: url)
                }
            }
        }
    }
}

// MARK: - Lazy Loading System
struct LazyLoadingView<Content: View>: View {
    let threshold: CGFloat
    let content: () -> Content
    @State private var isLoaded = false
    @State private var visibilityPercentage: CGFloat = 0
    
    init(threshold: CGFloat = 100, @ViewBuilder content: @escaping () -> Content) {
        self.threshold = threshold
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoaded {
                    content()
                        .transition(.opacity.combined(with: .scale))
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                checkVisibility(geometry: geometry)
            }
            .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                checkVisibility(frame: newFrame)
            }
        }
    }
    
    private func checkVisibility(geometry: GeometryProxy) {
        checkVisibility(frame: geometry.frame(in: .global))
    }
    
    private func checkVisibility(frame: CGRect) {
        let screenHeight = UIScreen.main.bounds.height
        let bottomEdge = frame.maxY
        
        if bottomEdge > threshold && !isLoaded {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoaded = true
            }
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let debouncedScrollUpdate = Notification.Name("debouncedScrollUpdate")
}

// MARK: - Performance Monitoring View Modifier
struct PerformanceMonitoring: ViewModifier {
    @StateObject private var optimizer = PerformanceOptimizer.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        if optimizer.currentFPS < 50 {
                            Text("FPS: \(Int(optimizer.currentFPS))")
                                .font(.caption2)
                                .padding(4)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    Spacer()
                }
                .padding()
            )
    }
}

extension View {
    func performanceMonitoring() -> some View {
        modifier(PerformanceMonitoring())
    }
}