import Foundation
import simd
import QuartzCore
import Combine

// MARK: - Physics Simulation Engine
// High-performance physics calculations for 120fps fluid interactions

@MainActor
final class PhysicsSimulationEngine: ObservableObject {
    
    // MARK: - Constants
    
    private let targetFrameRate: Double = 120.0
    private let timestep: Double = 1.0 / 120.0
    private let maxTimestep: Double = 1.0 / 30.0 // Prevent spiral of death
    
    // MARK: - Published Properties
    
    @Published private(set) var activeSimulations: [UUID: PhysicsSimulation] = [:]
    @Published private(set) var performanceMetrics = PerformanceMetrics()
    
    // MARK: - Private Properties
    
    private var displayLink: CADisplayLink?
    private var accumulator: Double = 0
    private var lastFrameTime: Double = CACurrentMediaTime()
    private var simulationQueue = DispatchQueue(label: "physics.simulation", qos: .userInteractive)
    
    // Gesture prediction
    private var gesturePredictors: [UUID: GesturePredictor] = [:]
    private var predictedOutcomes: [UUID: [PredictedOutcome]] = [:]
    
    // MARK: - Singleton
    
    static let shared = PhysicsSimulationEngine()
    
    private init() {
        setupDisplayLink()
    }
    
    // MARK: - Public Methods - Momentum & Velocity
    
    /// Calculate momentum for swipe gestures with natural deceleration
    func calculateSwipeMomentum(
        velocity: SIMD2<Double>,
        mass: Double = 1.0,
        friction: Double = 0.95
    ) -> MomentumSimulation {
        
        let simulation = MomentumSimulation(
            id: UUID(),
            velocity: velocity,
            mass: mass,
            friction: friction,
            bounceEnabled: true
        )
        
        // Pre-calculate trajectory
        simulation.trajectory = predictTrajectory(simulation)
        
        // Calculate key points
        simulation.decelerationPoint = calculateDecelerationPoint(simulation)
        simulation.stopPoint = calculateStopPoint(simulation)
        
        if simulation.bounceEnabled {
            simulation.bouncePoints = calculateBouncePoints(simulation)
        }
        
        activeSimulations[simulation.id] = simulation
        
        return simulation
    }
    
    /// Process velocity update for ongoing gesture
    func updateMomentum(
        _ simulationID: UUID,
        velocity: SIMD2<Double>,
        position: SIMD2<Double>
    ) {
        guard var simulation = activeSimulations[simulationID] as? MomentumSimulation else { return }
        
        // Apply smoothing for natural feel
        let smoothingFactor = 0.3
        simulation.velocity = simd_mix(simulation.velocity, velocity, SIMD2(repeating: smoothingFactor))
        simulation.position = position
        
        // Update prediction
        simulation.trajectory = predictTrajectory(simulation)
        
        activeSimulations[simulationID] = simulation
    }
    
    // MARK: - Spring Physics
    
    /// Create spring animation for elastic interactions
    func createSpringAnimation(
        from: Double,
        to: Double,
        stiffness: Double = 300,
        damping: Double = 20,
        mass: Double = 1.0
    ) -> SpringSimulation {
        
        let simulation = SpringSimulation(
            id: UUID(),
            currentValue: from,
            targetValue: to,
            velocity: 0,
            stiffness: stiffness,
            damping: damping,
            mass: mass
        )
        
        // Calculate spring characteristics
        let omega = sqrt(stiffness / mass)
        let zeta = damping / (2 * sqrt(stiffness * mass))
        
        simulation.naturalFrequency = omega
        simulation.dampingRatio = zeta
        simulation.settlingTime = calculateSettlingTime(omega: omega, zeta: zeta)
        
        // Determine spring type
        if zeta < 1 {
            simulation.springType = .underdamped
            simulation.overshoot = calculateOvershoot(zeta: zeta)
        } else if zeta == 1 {
            simulation.springType = .criticallyDamped
        } else {
            simulation.springType = .overdamped
        }
        
        activeSimulations[simulation.id] = simulation
        
        return simulation
    }
    
    /// Calculate spring compression and rebound for buttons
    func calculateButtonSpring(
        pressure: Double,
        maxCompression: Double = 0.1
    ) -> ButtonSpringState {
        
        let compression = min(pressure * maxCompression, maxCompression)
        
        // Non-linear response for natural feel
        let responsesCurve = pow(pressure, 1.5)
        let scale = 1.0 - compression * responsesCurve
        
        // Calculate rebound velocity based on compression
        let reboundVelocity = compression * 500 // pixels/second
        
        // Create spring for rebound animation
        let reboundSpring = createSpringAnimation(
            from: scale,
            to: 1.0,
            stiffness: 400,
            damping: 15
        )
        
        return ButtonSpringState(
            scale: scale,
            compression: compression,
            reboundVelocity: reboundVelocity,
            reboundSpring: reboundSpring,
            hapticIntensity: responsesCurve
        )
    }
    
    // MARK: - Ball Flight Physics
    
    /// Generate realistic ball trajectories for loading animations
    func calculateBallTrajectory(
        initialPosition: SIMD3<Double>,
        initialVelocity: SIMD3<Double>,
        spin: SIMD3<Double> = .zero,
        gravity: Double = -9.81,
        airDensity: Double = 1.225
    ) -> BallFlightSimulation {
        
        let simulation = BallFlightSimulation(
            id: UUID(),
            position: initialPosition,
            velocity: initialVelocity,
            spin: spin,
            gravity: SIMD3(0, gravity, 0),
            airDensity: airDensity,
            dragCoefficient: 0.47, // Sphere
            liftCoefficient: 0.2,
            mass: 0.045, // Golf ball mass in kg
            radius: 0.0213 // Golf ball radius in meters
        )
        
        // Calculate trajectory points
        simulation.trajectoryPoints = calculateFlightPath(simulation)
        
        // Find key points
        simulation.apexPoint = findApex(simulation.trajectoryPoints)
        simulation.landingPoint = findLanding(simulation.trajectoryPoints)
        simulation.flightTime = calculateFlightTime(simulation)
        
        // Calculate visual effects
        simulation.spinEffect = calculateSpinEffect(spin)
        simulation.compressionAtImpact = calculateImpactCompression(simulation)
        
        activeSimulations[simulation.id] = simulation
        
        return simulation
    }
    
    // MARK: - Gesture Prediction
    
    /// Predict user gesture intentions for instant response
    func predictGestureOutcome(
        currentPosition: SIMD2<Double>,
        velocity: SIMD2<Double>,
        history: [GesturePoint]
    ) -> [PredictedOutcome] {
        
        let predictorID = UUID()
        
        // Create or update predictor
        if gesturePredictors[predictorID] == nil {
            gesturePredictors[predictorID] = GesturePredictor(
                historySize: 20,
                predictionHorizon: 0.5 // seconds
            )
        }
        
        guard let predictor = gesturePredictors[predictorID] else { return [] }
        
        // Update predictor with current state
        predictor.update(position: currentPosition, velocity: velocity)
        
        // Generate predictions for multiple scenarios
        var outcomes: [PredictedOutcome] = []
        
        // Scenario 1: Continue current trajectory
        let continuationOutcome = predictContinuation(
            position: currentPosition,
            velocity: velocity,
            friction: 0.95
        )
        outcomes.append(continuationOutcome)
        
        // Scenario 2: Quick stop (user might release)
        let stopOutcome = predictQuickStop(
            position: currentPosition,
            velocity: velocity
        )
        outcomes.append(stopOutcome)
        
        // Scenario 3: Direction change (user might flick)
        if let flickOutcome = predictFlick(history: history, currentVelocity: velocity) {
            outcomes.append(flickOutcome)
        }
        
        // Scenario 4: Snap to nearest target
        if let snapOutcome = predictSnapToTarget(position: currentPosition, velocity: velocity) {
            outcomes.append(snapOutcome)
        }
        
        // Sort by probability
        outcomes.sort { $0.probability > $1.probability }
        
        // Cache predictions
        predictedOutcomes[predictorID] = outcomes
        
        return outcomes
    }
    
    // MARK: - Rubber Band Effects
    
    /// Calculate rubber band stretch and snapback
    func calculateRubberBandEffect(
        position: Double,
        limit: Double,
        stiffness: Double = 0.55
    ) -> RubberBandState {
        
        let overshoot = max(0, position - limit)
        
        // Non-linear stretch resistance
        let resistance = 1.0 - exp(-stiffness * overshoot)
        let stretchedPosition = limit + log(1 + overshoot) / stiffness
        
        // Calculate snapback force
        let snapbackForce = overshoot * stiffness * 100
        
        // Create snapback spring
        let snapbackSpring = createSpringAnimation(
            from: stretchedPosition,
            to: limit,
            stiffness: 250,
            damping: 20
        )
        
        return RubberBandState(
            currentPosition: stretchedPosition,
            overshoot: overshoot,
            resistance: resistance,
            snapbackForce: snapbackForce,
            snapbackSpring: snapbackSpring,
            visualStretch: calculateVisualStretch(overshoot, stiffness: stiffness)
        )
    }
    
    // MARK: - Magnetic Edge Detection
    
    /// Find snap points and calculate attraction forces
    func calculateMagneticAttraction(
        position: SIMD2<Double>,
        snapPoints: [SnapPoint],
        magneticRadius: Double = 50
    ) -> MagneticState {
        
        var nearestSnap: SnapPoint?
        var minDistance = Double.infinity
        var activeSnaps: [SnapPoint] = []
        
        // Find snap points within magnetic radius
        for snap in snapPoints {
            let distance = simd_distance(position, snap.position)
            
            if distance < magneticRadius {
                activeSnaps.append(snap)
                
                if distance < minDistance {
                    minDistance = distance
                    nearestSnap = snap
                }
            }
        }
        
        guard let target = nearestSnap else {
            return MagneticState(
                isActive: false,
                targetPoint: nil,
                attractionForce: .zero,
                snapVelocity: .zero
            )
        }
        
        // Calculate attraction force (inverse square law)
        let direction = simd_normalize(target.position - position)
        let forceMagnitude = target.strength * (1.0 - minDistance / magneticRadius) * (1.0 - minDistance / magneticRadius)
        let attractionForce = direction * forceMagnitude
        
        // Calculate snap velocity for smooth transition
        let snapVelocity = direction * sqrt(2 * forceMagnitude * minDistance)
        
        // Determine if should snap
        let shouldSnap = minDistance < target.snapThreshold
        
        return MagneticState(
            isActive: true,
            targetPoint: target,
            attractionForce: attractionForce,
            snapVelocity: snapVelocity,
            distance: minDistance,
            shouldSnap: shouldSnap,
            snapProgress: 1.0 - minDistance / magneticRadius
        )
    }
    
    // MARK: - Physics Update Loop
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updatePhysics))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updatePhysics(_ displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        let deltaTime = min(currentTime - lastFrameTime, maxTimestep)
        lastFrameTime = currentTime
        
        accumulator += deltaTime
        
        // Fixed timestep for deterministic physics
        while accumulator >= timestep {
            performPhysicsStep(timestep)
            accumulator -= timestep
        }
        
        // Interpolate for smooth rendering
        let alpha = accumulator / timestep
        interpolateSimulations(alpha: alpha)
        
        // Update performance metrics
        updatePerformanceMetrics(deltaTime: deltaTime)
    }
    
    private func performPhysicsStep(_ dt: Double) {
        for (id, simulation) in activeSimulations {
            switch simulation {
            case let momentum as MomentumSimulation:
                updateMomentumSimulation(momentum, dt: dt)
                
            case let spring as SpringSimulation:
                updateSpringSimulation(spring, dt: dt)
                
            case let ballFlight as BallFlightSimulation:
                updateBallFlightSimulation(ballFlight, dt: dt)
                
            default:
                break
            }
            
            // Remove completed simulations
            if simulation.isComplete {
                activeSimulations.removeValue(forKey: id)
            }
        }
    }
    
    // MARK: - Simulation Updates
    
    private func updateMomentumSimulation(_ simulation: MomentumSimulation, dt: Double) {
        // Apply friction
        simulation.velocity *= pow(simulation.friction, dt * 60)
        
        // Update position
        simulation.position += simulation.velocity * dt
        
        // Check for bounce
        if simulation.bounceEnabled {
            checkBounce(simulation)
        }
        
        // Check if should stop
        if simd_length(simulation.velocity) < 0.1 {
            simulation.isComplete = true
        }
    }
    
    private func updateSpringSimulation(_ simulation: SpringSimulation, dt: Double) {
        let displacement = simulation.currentValue - simulation.targetValue
        let springForce = -simulation.stiffness * displacement
        let dampingForce = -simulation.damping * simulation.velocity
        
        let acceleration = (springForce + dampingForce) / simulation.mass
        
        simulation.velocity += acceleration * dt
        simulation.currentValue += simulation.velocity * dt
        
        // Check if settled
        if abs(displacement) < 0.001 && abs(simulation.velocity) < 0.001 {
            simulation.currentValue = simulation.targetValue
            simulation.velocity = 0
            simulation.isComplete = true
        }
    }
    
    private func updateBallFlightSimulation(_ simulation: BallFlightSimulation, dt: Double) {
        // Apply gravity
        simulation.velocity += simulation.gravity * dt
        
        // Apply drag
        let speed = simd_length(simulation.velocity)
        if speed > 0 {
            let dragForce = 0.5 * simulation.airDensity * simulation.dragCoefficient * 
                           pow(simulation.radius, 2) * .pi * pow(speed, 2)
            let dragAcceleration = -dragForce / simulation.mass * simd_normalize(simulation.velocity)
            simulation.velocity += dragAcceleration * dt
        }
        
        // Apply Magnus effect (lift from spin)
        if simd_length(simulation.spin) > 0 {
            let magnus = simd_cross(simulation.spin, simulation.velocity) * simulation.liftCoefficient
            simulation.velocity += magnus * dt
        }
        
        // Update position
        simulation.position += simulation.velocity * dt
        
        // Check for landing
        if simulation.position.y <= 0 {
            simulation.position.y = 0
            simulation.isComplete = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func predictTrajectory(_ simulation: MomentumSimulation) -> [SIMD2<Double>] {
        var points: [SIMD2<Double>] = []
        var pos = simulation.position
        var vel = simulation.velocity
        
        for _ in 0..<60 { // Predict 1 second ahead
            vel *= simulation.friction
            pos += vel * timestep
            points.append(pos)
            
            if simd_length(vel) < 0.1 {
                break
            }
        }
        
        return points
    }
    
    private func calculateDecelerationPoint(_ simulation: MomentumSimulation) -> SIMD2<Double> {
        let decelerationTime = log(0.1 / simd_length(simulation.velocity)) / log(simulation.friction)
        return simulation.position + simulation.velocity * decelerationTime * 0.5
    }
    
    private func calculateStopPoint(_ simulation: MomentumSimulation) -> SIMD2<Double> {
        let totalDistance = simd_length(simulation.velocity) / (1 - simulation.friction)
        return simulation.position + simd_normalize(simulation.velocity) * totalDistance
    }
    
    private func calculateBouncePoints(_ simulation: MomentumSimulation) -> [SIMD2<Double>] {
        // Simplified bounce calculation
        return []
    }
    
    private func calculateSettlingTime(omega: Double, zeta: Double) -> Double {
        if zeta >= 1 {
            return 4 / (zeta * omega)
        } else {
            return 4 / (zeta * omega)
        }
    }
    
    private func calculateOvershoot(zeta: Double) -> Double {
        guard zeta < 1 else { return 0 }
        return exp(-zeta * .pi / sqrt(1 - zeta * zeta))
    }
    
    private func calculateFlightPath(_ simulation: BallFlightSimulation) -> [SIMD3<Double>] {
        var points: [SIMD3<Double>] = []
        var pos = simulation.position
        var vel = simulation.velocity
        
        let dt = 0.01
        
        while pos.y >= 0 && points.count < 1000 {
            // Gravity
            vel.y += simulation.gravity.y * dt
            
            // Drag
            let speed = simd_length(vel)
            if speed > 0 {
                let drag = 0.5 * simulation.airDensity * simulation.dragCoefficient * pow(speed, 2)
                vel -= simd_normalize(vel) * drag * dt
            }
            
            pos += vel * dt
            points.append(pos)
        }
        
        return points
    }
    
    private func findApex(_ points: [SIMD3<Double>]) -> SIMD3<Double> {
        return points.max { $0.y < $1.y } ?? .zero
    }
    
    private func findLanding(_ points: [SIMD3<Double>]) -> SIMD3<Double> {
        return points.last { $0.y >= 0 } ?? .zero
    }
    
    private func calculateFlightTime(_ simulation: BallFlightSimulation) -> Double {
        let v0 = simulation.velocity.y
        let g = abs(simulation.gravity.y)
        return 2 * v0 / g
    }
    
    private func calculateSpinEffect(_ spin: SIMD3<Double>) -> SpinEffect {
        let spinRate = simd_length(spin)
        return SpinEffect(
            backspin: spin.z > 0,
            sidespin: abs(spin.x),
            rate: spinRate,
            visualRotation: spinRate * 0.1
        )
    }
    
    private func calculateImpactCompression(_ simulation: BallFlightSimulation) -> Double {
        let impactVelocity = abs(simulation.velocity.y)
        return min(0.3, impactVelocity / 100)
    }
    
    private func calculateVisualStretch(_ overshoot: Double, stiffness: Double) -> Double {
        return 1.0 + log(1 + overshoot) * 0.1
    }
    
    private func checkBounce(_ simulation: MomentumSimulation) {
        // Check boundaries and apply bounce
    }
    
    private func interpolateSimulations(alpha: Double) {
        // Interpolate between physics steps for smooth rendering
    }
    
    private func updatePerformanceMetrics(deltaTime: Double) {
        performanceMetrics.frameRate = 1.0 / deltaTime
        performanceMetrics.physicsLoad = Double(activeSimulations.count) / 100.0
        performanceMetrics.lastFrameTime = deltaTime * 1000 // Convert to ms
    }
    
    // MARK: - Prediction Helpers
    
    private func predictContinuation(
        position: SIMD2<Double>,
        velocity: SIMD2<Double>,
        friction: Double
    ) -> PredictedOutcome {
        
        let finalPosition = position + velocity / (1 - friction)
        
        return PredictedOutcome(
            type: .continuation,
            finalPosition: finalPosition,
            duration: 1.0,
            probability: 0.6,
            confidence: 0.8
        )
    }
    
    private func predictQuickStop(
        position: SIMD2<Double>,
        velocity: SIMD2<Double>
    ) -> PredictedOutcome {
        
        let stopPosition = position + velocity * 0.1
        
        return PredictedOutcome(
            type: .stop,
            finalPosition: stopPosition,
            duration: 0.2,
            probability: 0.2,
            confidence: 0.9
        )
    }
    
    private func predictFlick(
        history: [GesturePoint],
        currentVelocity: SIMD2<Double>
    ) -> PredictedOutcome? {
        
        guard history.count > 5 else { return nil }
        
        // Detect acceleration pattern
        let recentVelocities = history.suffix(5).map { $0.velocity }
        let acceleration = (recentVelocities.last! - recentVelocities.first!) / 0.05
        
        if simd_length(acceleration) > 1000 {
            let flickVelocity = currentVelocity + acceleration * 0.1
            let flickPosition = history.last!.position + flickVelocity * 0.5
            
            return PredictedOutcome(
                type: .flick,
                finalPosition: flickPosition,
                duration: 0.5,
                probability: 0.15,
                confidence: 0.6
            )
        }
        
        return nil
    }
    
    private func predictSnapToTarget(
        position: SIMD2<Double>,
        velocity: SIMD2<Double>
    ) -> PredictedOutcome? {
        
        // Find nearest snap point
        let snapPoints = getActiveSnapPoints()
        guard let nearest = findNearestSnapPoint(position, snapPoints: snapPoints) else {
            return nil
        }
        
        let distance = simd_distance(position, nearest.position)
        
        if distance < 100 {
            return PredictedOutcome(
                type: .snap,
                finalPosition: nearest.position,
                duration: 0.3,
                probability: 0.05,
                confidence: 0.95
            )
        }
        
        return nil
    }
    
    private func getActiveSnapPoints() -> [SnapPoint] {
        // Return active snap points in the UI
        return []
    }
    
    private func findNearestSnapPoint(_ position: SIMD2<Double>, snapPoints: [SnapPoint]) -> SnapPoint? {
        return snapPoints.min { simd_distance($0.position, position) < simd_distance($1.position, position) }
    }
}

// MARK: - Supporting Types

protocol PhysicsSimulation: AnyObject {
    var id: UUID { get }
    var isComplete: Bool { get set }
}

class MomentumSimulation: PhysicsSimulation {
    let id: UUID
    var position: SIMD2<Double>
    var velocity: SIMD2<Double>
    let mass: Double
    let friction: Double
    let bounceEnabled: Bool
    var isComplete: Bool = false
    
    var trajectory: [SIMD2<Double>] = []
    var decelerationPoint: SIMD2<Double> = .zero
    var stopPoint: SIMD2<Double> = .zero
    var bouncePoints: [SIMD2<Double>] = []
    
    init(id: UUID, velocity: SIMD2<Double>, mass: Double, friction: Double, bounceEnabled: Bool) {
        self.id = id
        self.position = .zero
        self.velocity = velocity
        self.mass = mass
        self.friction = friction
        self.bounceEnabled = bounceEnabled
    }
}

class SpringSimulation: PhysicsSimulation {
    let id: UUID
    var currentValue: Double
    let targetValue: Double
    var velocity: Double
    let stiffness: Double
    let damping: Double
    let mass: Double
    var isComplete: Bool = false
    
    var naturalFrequency: Double = 0
    var dampingRatio: Double = 0
    var settlingTime: Double = 0
    var springType: SpringType = .underdamped
    var overshoot: Double = 0
    
    init(id: UUID, currentValue: Double, targetValue: Double, velocity: Double,
         stiffness: Double, damping: Double, mass: Double) {
        self.id = id
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.velocity = velocity
        self.stiffness = stiffness
        self.damping = damping
        self.mass = mass
    }
}

enum SpringType {
    case underdamped
    case criticallyDamped
    case overdamped
}

class BallFlightSimulation: PhysicsSimulation {
    let id: UUID
    var position: SIMD3<Double>
    var velocity: SIMD3<Double>
    let spin: SIMD3<Double>
    let gravity: SIMD3<Double>
    let airDensity: Double
    let dragCoefficient: Double
    let liftCoefficient: Double
    let mass: Double
    let radius: Double
    var isComplete: Bool = false
    
    var trajectoryPoints: [SIMD3<Double>] = []
    var apexPoint: SIMD3<Double> = .zero
    var landingPoint: SIMD3<Double> = .zero
    var flightTime: Double = 0
    var spinEffect: SpinEffect = SpinEffect()
    var compressionAtImpact: Double = 0
    
    init(id: UUID, position: SIMD3<Double>, velocity: SIMD3<Double>, spin: SIMD3<Double>,
         gravity: SIMD3<Double>, airDensity: Double, dragCoefficient: Double,
         liftCoefficient: Double, mass: Double, radius: Double) {
        self.id = id
        self.position = position
        self.velocity = velocity
        self.spin = spin
        self.gravity = gravity
        self.airDensity = airDensity
        self.dragCoefficient = dragCoefficient
        self.liftCoefficient = liftCoefficient
        self.mass = mass
        self.radius = radius
    }
}

struct ButtonSpringState {
    let scale: Double
    let compression: Double
    let reboundVelocity: Double
    let reboundSpring: SpringSimulation
    let hapticIntensity: Double
}

struct SpinEffect {
    var backspin: Bool = false
    var sidespin: Double = 0
    var rate: Double = 0
    var visualRotation: Double = 0
}

class GesturePredictor {
    let historySize: Int
    let predictionHorizon: Double
    private var history: [GesturePoint] = []
    
    init(historySize: Int, predictionHorizon: Double) {
        self.historySize = historySize
        self.predictionHorizon = predictionHorizon
    }
    
    func update(position: SIMD2<Double>, velocity: SIMD2<Double>) {
        let point = GesturePoint(
            position: position,
            velocity: velocity,
            timestamp: CACurrentMediaTime()
        )
        
        history.append(point)
        
        if history.count > historySize {
            history.removeFirst()
        }
    }
}

struct GesturePoint {
    let position: SIMD2<Double>
    let velocity: SIMD2<Double>
    let timestamp: Double
}

struct PredictedOutcome {
    let type: PredictionType
    let finalPosition: SIMD2<Double>
    let duration: Double
    let probability: Double
    let confidence: Double
}

enum PredictionType {
    case continuation
    case stop
    case flick
    case snap
    case bounce
}

struct RubberBandState {
    let currentPosition: Double
    let overshoot: Double
    let resistance: Double
    let snapbackForce: Double
    let snapbackSpring: SpringSimulation
    let visualStretch: Double
}

struct MagneticState {
    let isActive: Bool
    let targetPoint: SnapPoint?
    let attractionForce: SIMD2<Double>
    let snapVelocity: SIMD2<Double>
    var distance: Double = 0
    var shouldSnap: Bool = false
    var snapProgress: Double = 0
}

struct SnapPoint {
    let id: UUID
    let position: SIMD2<Double>
    let strength: Double
    let snapThreshold: Double
    let type: SnapType
}

enum SnapType {
    case edge
    case center
    case grid
    case custom
}

struct PerformanceMetrics {
    var frameRate: Double = 0
    var physicsLoad: Double = 0
    var lastFrameTime: Double = 0
    var droppedFrames: Int = 0
}