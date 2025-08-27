import Foundation
import QuartzCore
import Combine
import simd

// MARK: - Animation Orchestration Service
// Sophisticated animation timeline system for complex UI choreography at 120fps

@MainActor
final class AnimationOrchestrator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var activeAnimations: [UUID: Animation] = [:]
    @Published private(set) var sequenceManagers: [UUID: SequenceManager] = [:]
    @Published private(set) var animationQueues: [AnimationPriority: AnimationQueue] = [:]
    @Published private(set) var performanceMode: PerformanceMode = .automatic
    @Published private(set) var currentFPS: Double = 60
    
    // MARK: - Private Properties
    
    private var displayLink: CADisplayLink?
    private var stateMachines: [UUID: AnimationStateMachine] = [:]
    private var timingLibrary = TimingCurveLibrary()
    private var performanceMonitor = PerformanceMonitor()
    private let animationScheduler = AnimationScheduler()
    
    // Frame timing
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fpsUpdateTime: CFTimeInterval = 0
    
    // MARK: - Constants
    
    private let targetFPS: Double = 120
    private let minFPS: Double = 30
    private let performanceCheckInterval: Double = 0.5
    
    // MARK: - Singleton
    
    static let shared = AnimationOrchestrator()
    
    private init() {
        setupQueues()
        setupDisplayLink()
        startPerformanceMonitoring()
    }
    
    // MARK: - Public Methods - Animation Creation
    
    /// Create a simple animation with timing curve
    func animate<T: AnimatableProperty>(
        _ property: T,
        to target: T.Value,
        duration: Double,
        curve: TimingCurve = .easeInOut,
        delay: Double = 0,
        priority: AnimationPriority = .normal
    ) -> AnimationHandle {
        
        let animation = PropertyAnimation(
            id: UUID(),
            property: property,
            fromValue: property.value,
            toValue: target,
            duration: duration,
            curve: curve,
            delay: delay,
            priority: priority
        )
        
        return scheduleAnimation(animation)
    }
    
    /// Create a staggered entrance sequence
    func createStaggeredSequence(
        elements: [AnimatableElement],
        stagger: Double = 0.05,
        duration: Double = 0.3,
        curve: TimingCurve = .bouncy
    ) -> SequenceHandle {
        
        let sequence = SequenceManager(
            id: UUID(),
            type: .staggered
        )
        
        for (index, element) in elements.enumerated() {
            let delay = Double(index) * stagger
            
            let enterAnimation = ElementAnimation(
                element: element,
                transforms: [
                    .opacity(from: 0, to: 1),
                    .scale(from: 0.8, to: 1.0),
                    .translation(from: SIMD2(0, 20), to: .zero)
                ],
                duration: duration,
                curve: curve,
                delay: delay
            )
            
            sequence.addAnimation(enterAnimation)
        }
        
        sequenceManagers[sequence.id] = sequence
        sequence.start()
        
        return SequenceHandle(id: sequence.id, orchestrator: self)
    }
    
    /// Create complex choreographed animation
    func choreograph(_ builder: ChoreographyBuilder) -> ChoreographyHandle {
        let choreography = builder.build()
        
        // Create timeline
        let timeline = AnimationTimeline(id: UUID())
        
        // Add tracks for each element
        for track in choreography.tracks {
            timeline.addTrack(track)
        }
        
        // Create state machine for complex transitions
        let stateMachine = createStateMachine(for: choreography)
        stateMachines[choreography.id] = stateMachine
        
        // Start playback
        timeline.play()
        
        return ChoreographyHandle(
            id: choreography.id,
            timeline: timeline,
            orchestrator: self
        )
    }
    
    // MARK: - Timing Curves
    
    /// Get pre-defined timing curve
    func getTimingCurve(_ type: CurveType) -> TimingCurve {
        return timingLibrary.getCurve(type)
    }
    
    /// Create custom cubic bezier curve
    func createCustomCurve(
        p1: CGPoint,
        p2: CGPoint
    ) -> TimingCurve {
        return TimingCurve(
            type: .custom,
            controlPoints: (p1, p2),
            evaluator: CubicBezierEvaluator(p1: p1, p2: p2)
        )
    }
    
    // MARK: - Animation Queuing
    
    /// Queue animation with priority handling
    func queueAnimation(
        _ animation: Animation,
        priority: AnimationPriority = .normal,
        interruptible: Bool = true
    ) -> AnimationHandle {
        
        // Get or create queue for priority
        if animationQueues[priority] == nil {
            animationQueues[priority] = AnimationQueue(priority: priority)
        }
        
        guard let queue = animationQueues[priority] else {
            return AnimationHandle(id: UUID(), orchestrator: self)
        }
        
        // Check for conflicts
        let conflicts = findConflictingAnimations(animation)
        
        for conflict in conflicts {
            if shouldInterrupt(conflict, newAnimation: animation) {
                if conflict.interruptible {
                    interruptAnimation(conflict)
                } else {
                    // Queue after non-interruptible animation
                    queue.enqueue(animation, after: conflict)
                    return AnimationHandle(id: animation.id, orchestrator: self)
                }
            }
        }
        
        // Add to queue and start if possible
        queue.enqueue(animation)
        processQueue(queue)
        
        return AnimationHandle(id: animation.id, orchestrator: self)
    }
    
    // MARK: - State Machines
    
    /// Create animation state machine
    func createStateMachine(
        states: [AnimationState],
        transitions: [StateTransition]
    ) -> AnimationStateMachine {
        
        let machine = AnimationStateMachine(
            id: UUID(),
            states: states,
            transitions: transitions
        )
        
        stateMachines[machine.id] = machine
        
        return machine
    }
    
    /// Transition state with animation
    func transitionState(
        machine: AnimationStateMachine,
        to newState: AnimationState,
        animated: Bool = true
    ) {
        
        guard let transition = machine.findTransition(
            from: machine.currentState,
            to: newState
        ) else { return }
        
        if animated {
            // Create transition animation
            let transitionAnimation = createTransitionAnimation(
                from: machine.currentState,
                to: newState,
                transition: transition
            )
            
            scheduleAnimation(transitionAnimation)
        }
        
        machine.transitionTo(newState)
    }
    
    // MARK: - Performance Management
    
    /// Adjust animation complexity for performance
    func setPerformanceMode(_ mode: PerformanceMode) {
        performanceMode = mode
        adjustAnimationComplexity()
    }
    
    /// Get current performance metrics
    func getPerformanceMetrics() -> AnimationPerformanceMetrics {
        return performanceMonitor.currentMetrics
    }
    
    // MARK: - Private Methods - Setup
    
    private func setupQueues() {
        // Initialize priority queues
        AnimationPriority.allCases.forEach { priority in
            animationQueues[priority] = AnimationQueue(priority: priority)
        }
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimations))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(
            minimum: Float(minFPS),
            maximum: Float(targetFPS),
            preferred: Float(targetFPS)
        )
        displayLink?.add(to: .current, forMode: .common)
    }
    
    private func startPerformanceMonitoring() {
        performanceMonitor.startMonitoring { [weak self] metrics in
            self?.handlePerformanceUpdate(metrics)
        }
    }
    
    // MARK: - Animation Update Loop
    
    @objc private func updateAnimations(_ displayLink: CADisplayLink) {
        let currentTime = displayLink.timestamp
        let deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        // Update FPS counter
        updateFPSCounter(currentTime)
        
        // Update all active animations
        updateActiveAnimations(deltaTime: deltaTime, currentTime: currentTime)
        
        // Process sequences
        updateSequences(deltaTime: deltaTime)
        
        // Update state machines
        updateStateMachines(deltaTime: deltaTime)
        
        // Process queues
        processAllQueues()
        
        // Monitor performance
        performanceMonitor.recordFrame(deltaTime: deltaTime)
    }
    
    private func updateActiveAnimations(deltaTime: CFTimeInterval, currentTime: CFTimeInterval) {
        var completedAnimations: [UUID] = []
        
        for (id, animation) in activeAnimations {
            // Check if should start
            if animation.startTime == 0 {
                if currentTime >= animation.delay {
                    animation.startTime = currentTime
                }
            }
            
            guard animation.startTime > 0 else { continue }
            
            // Calculate progress
            let elapsed = currentTime - animation.startTime
            let progress = min(1.0, elapsed / animation.duration)
            
            // Apply timing curve
            let easedProgress = animation.curve.evaluate(progress)
            
            // Update animation value
            animation.updateValue(easedProgress)
            
            // Check completion
            if progress >= 1.0 {
                animation.complete()
                completedAnimations.append(id)
            }
        }
        
        // Remove completed animations
        completedAnimations.forEach { id in
            activeAnimations.removeValue(forKey: id)
        }
    }
    
    private func updateSequences(deltaTime: CFTimeInterval) {
        for (_, sequence) in sequenceManagers {
            sequence.update(deltaTime: deltaTime)
        }
    }
    
    private func updateStateMachines(deltaTime: CFTimeInterval) {
        for (_, machine) in stateMachines {
            machine.update(deltaTime: deltaTime)
        }
    }
    
    // MARK: - Queue Processing
    
    private func processAllQueues() {
        // Process in priority order
        for priority in AnimationPriority.allCases.reversed() {
            if let queue = animationQueues[priority] {
                processQueue(queue)
            }
        }
    }
    
    private func processQueue(_ queue: AnimationQueue) {
        while let animation = queue.dequeue() {
            if canStartAnimation(animation) {
                startAnimation(animation)
            } else {
                // Re-queue if can't start
                queue.requeue(animation)
                break
            }
        }
    }
    
    private func canStartAnimation(_ animation: Animation) -> Bool {
        // Check performance constraints
        if performanceMode == .reduced && activeAnimations.count > 10 {
            return false
        }
        
        // Check for conflicts
        let conflicts = findConflictingAnimations(animation)
        return conflicts.isEmpty || conflicts.allSatisfy { $0.interruptible }
    }
    
    private func startAnimation(_ animation: Animation) {
        activeAnimations[animation.id] = animation
        animation.start()
    }
    
    // MARK: - Conflict Resolution
    
    private func findConflictingAnimations(_ animation: Animation) -> [Animation] {
        return activeAnimations.values.filter { existing in
            animation.conflictsWith(existing)
        }
    }
    
    private func shouldInterrupt(
        _ existing: Animation,
        newAnimation: Animation
    ) -> Bool {
        // Higher priority interrupts lower
        if newAnimation.priority.rawValue > existing.priority.rawValue {
            return true
        }
        
        // Same priority - check if almost complete
        if existing.progress > 0.8 {
            return false
        }
        
        return true
    }
    
    private func interruptAnimation(_ animation: Animation) {
        animation.interrupt()
        activeAnimations.removeValue(forKey: animation.id)
    }
    
    // MARK: - Performance
    
    private func updateFPSCounter(_ currentTime: CFTimeInterval) {
        frameCount += 1
        
        if currentTime - fpsUpdateTime >= 1.0 {
            currentFPS = Double(frameCount) / (currentTime - fpsUpdateTime)
            frameCount = 0
            fpsUpdateTime = currentTime
        }
    }
    
    private func handlePerformanceUpdate(_ metrics: AnimationPerformanceMetrics) {
        if performanceMode == .automatic {
            if metrics.averageFPS < 50 {
                reduceAnimationComplexity()
            } else if metrics.averageFPS > 110 {
                increaseAnimationComplexity()
            }
        }
    }
    
    private func adjustAnimationComplexity() {
        switch performanceMode {
        case .maximum:
            setMaximumQuality()
        case .balanced:
            setBalancedQuality()
        case .reduced:
            setReducedQuality()
        case .automatic:
            break
        }
    }
    
    private func reduceAnimationComplexity() {
        // Reduce particle counts
        // Simplify curves
        // Reduce shadow quality
        // Lower blur samples
    }
    
    private func increaseAnimationComplexity() {
        // Increase particle counts
        // Use complex curves
        // Enhance shadow quality
        // Increase blur samples
    }
    
    private func setMaximumQuality() {
        // All effects enabled
    }
    
    private func setBalancedQuality() {
        // Moderate effects
    }
    
    private func setReducedQuality() {
        // Minimal effects
    }
    
    // MARK: - Helpers
    
    private func scheduleAnimation(_ animation: Animation) -> AnimationHandle {
        queueAnimation(animation, priority: animation.priority)
        return AnimationHandle(id: animation.id, orchestrator: self)
    }
    
    private func createStateMachine(for choreography: Choreography) -> AnimationStateMachine {
        AnimationStateMachine(
            id: choreography.id,
            states: [],
            transitions: []
        )
    }
    
    private func createTransitionAnimation(
        from: AnimationState,
        to: AnimationState,
        transition: StateTransition
    ) -> Animation {
        
        TransitionAnimation(
            id: UUID(),
            fromState: from,
            toState: to,
            duration: transition.duration,
            curve: transition.curve
        )
    }
}

// MARK: - Timing Curve Library

class TimingCurveLibrary {
    private var curves: [CurveType: TimingCurve] = [:]
    
    init() {
        registerDefaultCurves()
    }
    
    private func registerDefaultCurves() {
        // Linear
        curves[.linear] = TimingCurve(
            type: .linear,
            controlPoints: (CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 1)),
            evaluator: LinearEvaluator()
        )
        
        // Ease In
        curves[.easeIn] = TimingCurve(
            type: .easeIn,
            controlPoints: (CGPoint(x: 0.42, y: 0), CGPoint(x: 1, y: 1)),
            evaluator: CubicBezierEvaluator(p1: CGPoint(x: 0.42, y: 0), p2: CGPoint(x: 1, y: 1))
        )
        
        // Ease Out
        curves[.easeOut] = TimingCurve(
            type: .easeOut,
            controlPoints: (CGPoint(x: 0, y: 0), CGPoint(x: 0.58, y: 1)),
            evaluator: CubicBezierEvaluator(p1: CGPoint(x: 0, y: 0), p2: CGPoint(x: 0.58, y: 1))
        )
        
        // Ease In Out
        curves[.easeInOut] = TimingCurve(
            type: .easeInOut,
            controlPoints: (CGPoint(x: 0.42, y: 0), CGPoint(x: 0.58, y: 1)),
            evaluator: CubicBezierEvaluator(p1: CGPoint(x: 0.42, y: 0), p2: CGPoint(x: 0.58, y: 1))
        )
        
        // Bouncy (Overshoot)
        curves[.bouncy] = TimingCurve(
            type: .bouncy,
            controlPoints: (CGPoint(x: 0.68, y: -0.55), CGPoint(x: 0.265, y: 1.55)),
            evaluator: CubicBezierEvaluator(p1: CGPoint(x: 0.68, y: -0.55), p2: CGPoint(x: 0.265, y: 1.55))
        )
        
        // Smooth (iOS Default)
        curves[.smooth] = TimingCurve(
            type: .smooth,
            controlPoints: (CGPoint(x: 0.25, y: 0.1), CGPoint(x: 0.25, y: 1)),
            evaluator: CubicBezierEvaluator(p1: CGPoint(x: 0.25, y: 0.1), p2: CGPoint(x: 0.25, y: 1))
        )
        
        // Snappy
        curves[.snappy] = TimingCurve(
            type: .snappy,
            controlPoints: (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1)),
            evaluator: CubicBezierEvaluator(p1: CGPoint(x: 0.5, y: 0), p2: CGPoint(x: 0.5, y: 1))
        )
        
        // Spring
        curves[.spring] = TimingCurve(
            type: .spring,
            controlPoints: (CGPoint(x: 0.5, y: 1.2), CGPoint(x: 0.5, y: 0.8)),
            evaluator: SpringEvaluator(damping: 0.7, frequency: 0.3)
        )
    }
    
    func getCurve(_ type: CurveType) -> TimingCurve {
        return curves[type] ?? curves[.linear]!
    }
}

// MARK: - Supporting Types

protocol Animation: AnyObject {
    var id: UUID { get }
    var duration: Double { get }
    var delay: Double { get }
    var priority: AnimationPriority { get }
    var curve: TimingCurve { get }
    var startTime: CFTimeInterval { get set }
    var progress: Double { get }
    var interruptible: Bool { get }
    
    func start()
    func updateValue(_ progress: Double)
    func complete()
    func interrupt()
    func conflictsWith(_ other: Animation) -> Bool
}

class PropertyAnimation<T: AnimatableProperty>: Animation {
    let id: UUID
    let property: T
    let fromValue: T.Value
    let toValue: T.Value
    let duration: Double
    let delay: Double
    let priority: AnimationPriority
    let curve: TimingCurve
    var startTime: CFTimeInterval = 0
    let interruptible: Bool = true
    
    var progress: Double {
        guard startTime > 0 else { return 0 }
        return min(1.0, (CACurrentMediaTime() - startTime) / duration)
    }
    
    init(id: UUID, property: T, fromValue: T.Value, toValue: T.Value,
         duration: Double, curve: TimingCurve, delay: Double, priority: AnimationPriority) {
        self.id = id
        self.property = property
        self.fromValue = fromValue
        self.toValue = toValue
        self.duration = duration
        self.curve = curve
        self.delay = delay
        self.priority = priority
    }
    
    func start() {
        startTime = CACurrentMediaTime() + delay
    }
    
    func updateValue(_ progress: Double) {
        property.interpolate(from: fromValue, to: toValue, progress: progress)
    }
    
    func complete() {
        property.value = toValue
    }
    
    func interrupt() {
        // Keep current value
    }
    
    func conflictsWith(_ other: Animation) -> Bool {
        if let otherProperty = other as? PropertyAnimation<T> {
            return property.id == otherProperty.property.id
        }
        return false
    }
}

protocol AnimatableProperty {
    associatedtype Value
    var id: String { get }
    var value: Value { get set }
    func interpolate(from: Value, to: Value, progress: Double)
}

struct AnimatableElement {
    let id: UUID
    let view: AnyObject
    var opacity: Double = 1
    var scale: SIMD2<Double> = SIMD2(1, 1)
    var translation: SIMD2<Double> = .zero
    var rotation: Double = 0
}

class ElementAnimation: Animation {
    let id = UUID()
    let element: AnimatableElement
    let transforms: [Transform]
    let duration: Double
    let curve: TimingCurve
    let delay: Double
    let priority: AnimationPriority = .normal
    var startTime: CFTimeInterval = 0
    let interruptible = true
    
    var progress: Double {
        guard startTime > 0 else { return 0 }
        return min(1.0, (CACurrentMediaTime() - startTime) / duration)
    }
    
    init(element: AnimatableElement, transforms: [Transform], duration: Double, curve: TimingCurve, delay: Double) {
        self.element = element
        self.transforms = transforms
        self.duration = duration
        self.curve = curve
        self.delay = delay
    }
    
    func start() {}
    func updateValue(_ progress: Double) {}
    func complete() {}
    func interrupt() {}
    func conflictsWith(_ other: Animation) -> Bool { false }
}

enum Transform {
    case opacity(from: Double, to: Double)
    case scale(from: Double, to: Double)
    case translation(from: SIMD2<Double>, to: SIMD2<Double>)
    case rotation(from: Double, to: Double)
}

class TransitionAnimation: Animation {
    let id: UUID
    let fromState: AnimationState
    let toState: AnimationState
    let duration: Double
    let curve: TimingCurve
    let delay: Double = 0
    let priority: AnimationPriority = .high
    var startTime: CFTimeInterval = 0
    let interruptible = false
    
    var progress: Double {
        guard startTime > 0 else { return 0 }
        return min(1.0, (CACurrentMediaTime() - startTime) / duration)
    }
    
    init(id: UUID, fromState: AnimationState, toState: AnimationState, duration: Double, curve: TimingCurve) {
        self.id = id
        self.fromState = fromState
        self.toState = toState
        self.duration = duration
        self.curve = curve
    }
    
    func start() {}
    func updateValue(_ progress: Double) {}
    func complete() {}
    func interrupt() {}
    func conflictsWith(_ other: Animation) -> Bool { false }
}

struct TimingCurve {
    let type: CurveType
    let controlPoints: (CGPoint, CGPoint)
    let evaluator: TimingEvaluator
    
    func evaluate(_ t: Double) -> Double {
        return evaluator.evaluate(t)
    }
}

enum CurveType {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case bouncy
    case smooth
    case snappy
    case spring
    case custom
}

protocol TimingEvaluator {
    func evaluate(_ t: Double) -> Double
}

struct LinearEvaluator: TimingEvaluator {
    func evaluate(_ t: Double) -> Double { t }
}

struct CubicBezierEvaluator: TimingEvaluator {
    let p1: CGPoint
    let p2: CGPoint
    
    func evaluate(_ t: Double) -> Double {
        // Simplified cubic bezier evaluation
        let t2 = t * t
        let t3 = t2 * t
        let mt = 1 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        
        return mt3 * 0 + 3 * mt2 * t * Double(p1.y) + 3 * mt * t2 * Double(p2.y) + t3 * 1
    }
}

struct SpringEvaluator: TimingEvaluator {
    let damping: Double
    let frequency: Double
    
    func evaluate(_ t: Double) -> Double {
        let amplitude = exp(-damping * t)
        return 1 - amplitude * cos(frequency * t * 2 * .pi)
    }
}

class SequenceManager {
    let id: UUID
    let type: SequenceType
    private var animations: [Animation] = []
    private var currentIndex = 0
    
    init(id: UUID, type: SequenceType) {
        self.id = id
        self.type = type
    }
    
    func addAnimation(_ animation: Animation) {
        animations.append(animation)
    }
    
    func start() {
        guard !animations.isEmpty else { return }
        animations[0].start()
    }
    
    func update(deltaTime: CFTimeInterval) {
        guard currentIndex < animations.count else { return }
        
        let current = animations[currentIndex]
        if current.progress >= 1.0 {
            currentIndex += 1
            if currentIndex < animations.count {
                animations[currentIndex].start()
            }
        }
    }
}

enum SequenceType {
    case sequential
    case parallel
    case staggered
}

class AnimationQueue {
    let priority: AnimationPriority
    private var queue: [Animation] = []
    private var dependencies: [UUID: Set<UUID>] = [:]
    
    init(priority: AnimationPriority) {
        self.priority = priority
    }
    
    func enqueue(_ animation: Animation, after dependency: Animation? = nil) {
        queue.append(animation)
        
        if let dep = dependency {
            dependencies[animation.id, default: []].insert(dep.id)
        }
    }
    
    func dequeue() -> Animation? {
        guard let next = queue.first(where: { canStart($0) }) else {
            return nil
        }
        
        queue.removeAll { $0.id == next.id }
        return next
    }
    
    func requeue(_ animation: Animation) {
        queue.insert(animation, at: 0)
    }
    
    private func canStart(_ animation: Animation) -> Bool {
        guard let deps = dependencies[animation.id] else { return true }
        return deps.isEmpty
    }
}

enum AnimationPriority: Int, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: AnimationPriority, rhs: AnimationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

class AnimationStateMachine {
    let id: UUID
    private(set) var currentState: AnimationState
    let states: [AnimationState]
    let transitions: [StateTransition]
    
    init(id: UUID, states: [AnimationState], transitions: [StateTransition]) {
        self.id = id
        self.states = states
        self.currentState = states.first ?? AnimationState(name: "default")
        self.transitions = transitions
    }
    
    func findTransition(from: AnimationState, to: AnimationState) -> StateTransition? {
        transitions.first { $0.from == from.name && $0.to == to.name }
    }
    
    func transitionTo(_ state: AnimationState) {
        currentState = state
    }
    
    func update(deltaTime: CFTimeInterval) {
        // Update current state
    }
}

struct AnimationState {
    let name: String
    var animations: [Animation] = []
}

struct StateTransition {
    let from: String
    let to: String
    let duration: Double
    let curve: TimingCurve
}

class AnimationTimeline {
    let id: UUID
    private var tracks: [AnimationTrack] = []
    private var playhead: CFTimeInterval = 0
    private var isPlaying = false
    
    init(id: UUID) {
        self.id = id
    }
    
    func addTrack(_ track: AnimationTrack) {
        tracks.append(track)
    }
    
    func play() {
        isPlaying = true
    }
    
    func pause() {
        isPlaying = false
    }
}

struct AnimationTrack {
    let id: UUID
    let element: AnimatableElement
    var keyframes: [Keyframe] = []
}

struct Keyframe {
    let time: CFTimeInterval
    let value: Any
}

class ChoreographyBuilder {
    private var tracks: [AnimationTrack] = []
    
    func addTrack(_ track: AnimationTrack) -> ChoreographyBuilder {
        tracks.append(track)
        return self
    }
    
    func build() -> Choreography {
        Choreography(id: UUID(), tracks: tracks)
    }
}

struct Choreography {
    let id: UUID
    let tracks: [AnimationTrack]
}

// MARK: - Handles

struct AnimationHandle {
    let id: UUID
    weak var orchestrator: AnimationOrchestrator?
    
    func cancel() {
        orchestrator?.activeAnimations.removeValue(forKey: id)
    }
}

struct SequenceHandle {
    let id: UUID
    weak var orchestrator: AnimationOrchestrator?
}

struct ChoreographyHandle {
    let id: UUID
    let timeline: AnimationTimeline
    weak var orchestrator: AnimationOrchestrator?
}

// MARK: - Performance

enum PerformanceMode {
    case automatic
    case maximum
    case balanced
    case reduced
}

class PerformanceMonitor {
    private(set) var currentMetrics = AnimationPerformanceMetrics()
    private var frameTimings: [CFTimeInterval] = []
    private var updateCallback: ((AnimationPerformanceMetrics) -> Void)?
    
    func startMonitoring(callback: @escaping (AnimationPerformanceMetrics) -> Void) {
        updateCallback = callback
    }
    
    func recordFrame(deltaTime: CFTimeInterval) {
        frameTimings.append(deltaTime)
        
        if frameTimings.count > 120 {
            frameTimings.removeFirst()
        }
        
        updateMetrics()
    }
    
    private func updateMetrics() {
        guard !frameTimings.isEmpty else { return }
        
        currentMetrics.averageFPS = 1.0 / (frameTimings.reduce(0, +) / Double(frameTimings.count))
        currentMetrics.minFPS = 1.0 / (frameTimings.max() ?? 1)
        currentMetrics.maxFPS = 1.0 / (frameTimings.min() ?? 0.001)
        currentMetrics.droppedFrames = frameTimings.filter { $0 > 1.0/30 }.count
        
        updateCallback?(currentMetrics)
    }
}

struct AnimationPerformanceMetrics {
    var averageFPS: Double = 60
    var minFPS: Double = 60
    var maxFPS: Double = 60
    var droppedFrames: Int = 0
    var activeAnimationCount: Int = 0
    var memoryUsage: Double = 0
}

class AnimationScheduler {
    private var scheduledAnimations: [(Animation, CFTimeInterval)] = []
    
    func schedule(_ animation: Animation, at time: CFTimeInterval) {
        scheduledAnimations.append((animation, time))
    }
    
    func processScheduled(currentTime: CFTimeInterval) -> [Animation] {
        let ready = scheduledAnimations.filter { $0.1 <= currentTime }
        scheduledAnimations.removeAll { $0.1 <= currentTime }
        return ready.map { $0.0 }
    }
}