import Foundation
import WeatherKit
import CoreLocation
import Combine

// MARK: - Weather UI Service
// Provides weather data specifically formatted for UI mood and visual adjustments

@MainActor
final class WeatherUIService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentMood: WeatherMood = .neutral
    @Published private(set) var visualEffects: WeatherVisualEffects = .none
    @Published private(set) var colorAdjustments: ColorAdjustments = ColorAdjustments()
    @Published private(set) var currentConditions: WeatherConditions?
    @Published private(set) var playConditions: PlayConditions = .ideal
    
    // MARK: - Private Properties
    
    private let weatherService = WeatherService.shared
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 600 // 10 minutes
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Event Publisher
    
    private let eventPublisher = PassthroughSubject<WeatherUIEvent, Never>()
    var events: AnyPublisher<WeatherUIEvent, Never> {
        eventPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Singleton
    
    static let shared = WeatherUIService()
    
    private init() {
        setupWeatherUpdates()
        subscribeToTimeEvents()
    }
    
    // MARK: - Public Methods
    
    /// Fetch weather and calculate UI adjustments
    func updateWeatherMood(for location: CLLocation) async {
        do {
            // Fetch current weather
            let weather = try await weatherService.weather(for: location)
            
            // Extract current conditions
            guard let current = weather.currentWeather else { return }
            
            // Convert to our weather conditions
            let conditions = WeatherConditions(
                temperature: current.temperature.value,
                cloudCover: current.cloudCover,
                precipitation: 0, // Would need hourly data
                windSpeed: current.wind.speed.value,
                visibility: current.visibility.value,
                condition: mapWeatherCondition(current.condition)
            )
            
            self.currentConditions = conditions
            
            // Calculate mood based on conditions
            let mood = calculateWeatherMood(conditions)
            
            // Calculate visual effects
            let effects = calculateVisualEffects(conditions)
            
            // Calculate color adjustments
            let adjustments = calculateColorAdjustments(conditions, mood: mood)
            
            // Update published properties
            self.currentMood = mood
            self.visualEffects = effects
            self.colorAdjustments = adjustments
            
            // Calculate play conditions
            self.playConditions = calculatePlayConditions(conditions)
            
            // Notify UI
            eventPublisher.send(.weatherUpdated(mood: mood, effects: effects))
            
        } catch {
            print("Failed to fetch weather: \(error)")
            // Fall back to neutral mood
            self.currentMood = .neutral
            self.visualEffects = .none
        }
    }
    
    /// Get dynamic background adjustments based on weather
    func getBackgroundAdjustments() -> BackgroundAdjustments {
        BackgroundAdjustments(
            saturation: colorAdjustments.saturationMultiplier,
            brightness: colorAdjustments.brightnessMultiplier,
            contrast: colorAdjustments.contrastMultiplier,
            blur: visualEffects.contains(.blur) ? 0.3 : 0,
            overlayOpacity: getOverlayOpacity(),
            gradientIntensity: getGradientIntensity(),
            animationSpeed: getAnimationSpeed()
        )
    }
    
    /// Get particle effects for current weather
    func getParticleEffects() -> [ParticleEffect] {
        var effects: [ParticleEffect] = []
        
        if visualEffects.contains(.rain) {
            effects.append(ParticleEffect(
                type: .rain,
                intensity: getRainIntensity(),
                color: UIColor(white: 0.8, alpha: 0.6),
                speed: 1.0,
                angle: 15 // Slight angle for wind
            ))
        }
        
        if visualEffects.contains(.snow) {
            effects.append(ParticleEffect(
                type: .snow,
                intensity: 0.5,
                color: .white,
                speed: 0.3,
                angle: 0
            ))
        }
        
        if visualEffects.contains(.fog) {
            effects.append(ParticleEffect(
                type: .fog,
                intensity: 0.7,
                color: UIColor(white: 0.9, alpha: 0.3),
                speed: 0.1,
                angle: 0
            ))
        }
        
        if visualEffects.contains(.leaves) && currentConditions?.windSpeed ?? 0 > 5 {
            effects.append(ParticleEffect(
                type: .leaves,
                intensity: 0.3,
                color: UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 0.8),
                speed: 0.5,
                angle: 45
            ))
        }
        
        return effects
    }
    
    /// Get UI text descriptions for weather
    func getWeatherDescription() -> WeatherDescription {
        guard let conditions = currentConditions else {
            return WeatherDescription(
                brief: "Clear",
                detailed: "Perfect golfing weather",
                emoji: "☀️",
                playAdvice: nil
            )
        }
        
        let brief = getBriefDescription(conditions)
        let detailed = getDetailedDescription(conditions)
        let emoji = getWeatherEmoji(conditions)
        let advice = getPlayAdvice(conditions)
        
        return WeatherDescription(
            brief: brief,
            detailed: detailed,
            emoji: emoji,
            playAdvice: advice
        )
    }
    
    // MARK: - Private Methods
    
    private func setupWeatherUpdates() {
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            Task {
                if let location = CLLocationManager().location {
                    await self?.updateWeatherMood(for: location)
                }
            }
        }
    }
    
    private func subscribeToTimeEvents() {
        TimeEnvironmentService.shared.events
            .sink { [weak self] event in
                switch event {
                case .locationChanged(let location):
                    Task {
                        await self?.updateWeatherMood(for: location)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateWeatherMood(_ conditions: WeatherConditions) -> WeatherMood {
        // Determine mood based on multiple factors
        let cloudiness = conditions.cloudCover
        let temp = conditions.temperature
        let wind = conditions.windSpeed
        
        if conditions.condition == .clear && temp >= 18 && temp <= 28 && wind < 5 {
            return .vibrant
        } else if conditions.condition == .partlyCloudy && temp >= 15 && temp <= 25 {
            return .cheerful
        } else if cloudiness > 0.8 {
            return .moody
        } else if conditions.condition == .rain {
            return .melancholic
        } else if conditions.condition == .fog {
            return .mysterious
        } else if conditions.condition == .storm {
            return .dramatic
        } else if temp > 35 {
            return .intense
        } else if temp < 5 {
            return .crisp
        } else {
            return .neutral
        }
    }
    
    private func calculateVisualEffects(_ conditions: WeatherConditions) -> WeatherVisualEffects {
        var effects = WeatherVisualEffects()
        
        switch conditions.condition {
        case .rain:
            effects.insert(.rain)
            if conditions.visibility < 5000 {
                effects.insert(.blur)
            }
        case .snow:
            effects.insert(.snow)
            effects.insert(.blur)
        case .fog:
            effects.insert(.fog)
            effects.insert(.blur)
        case .storm:
            effects.insert(.rain)
            effects.insert(.lightning)
        case .cloudy, .overcast:
            effects.insert(.clouds)
        default:
            break
        }
        
        // Add wind effects
        if conditions.windSpeed > 8 {
            effects.insert(.windLines)
            if TimeEnvironmentService.shared.seasonalContext == .autumn {
                effects.insert(.leaves)
            }
        }
        
        // Add heat shimmer for hot days
        if conditions.temperature > 35 {
            effects.insert(.heatShimmer)
        }
        
        return effects
    }
    
    private func calculateColorAdjustments(_ conditions: WeatherConditions, mood: WeatherMood) -> ColorAdjustments {
        var adjustments = ColorAdjustments()
        
        // Adjust saturation based on mood
        switch mood {
        case .vibrant:
            adjustments.saturationMultiplier = 1.3
            adjustments.brightnessMultiplier = 1.1
        case .cheerful:
            adjustments.saturationMultiplier = 1.15
            adjustments.brightnessMultiplier = 1.05
        case .moody:
            adjustments.saturationMultiplier = 0.7
            adjustments.brightnessMultiplier = 0.85
            adjustments.contrastMultiplier = 1.1
        case .melancholic:
            adjustments.saturationMultiplier = 0.6
            adjustments.brightnessMultiplier = 0.8
            adjustments.coolnessShift = 0.1
        case .mysterious:
            adjustments.saturationMultiplier = 0.5
            adjustments.brightnessMultiplier = 0.7
            adjustments.contrastMultiplier = 0.9
        case .dramatic:
            adjustments.saturationMultiplier = 0.8
            adjustments.brightnessMultiplier = 0.75
            adjustments.contrastMultiplier = 1.3
        case .intense:
            adjustments.saturationMultiplier = 1.1
            adjustments.brightnessMultiplier = 1.2
            adjustments.warmthShift = 0.2
        case .crisp:
            adjustments.saturationMultiplier = 1.05
            adjustments.brightnessMultiplier = 1.1
            adjustments.coolnessShift = 0.15
        case .neutral:
            break // No adjustments
        }
        
        // Additional adjustments based on specific conditions
        if conditions.cloudCover > 0.9 {
            adjustments.saturationMultiplier *= 0.9
        }
        
        if conditions.visibility < 2000 {
            adjustments.contrastMultiplier *= 0.8
        }
        
        return adjustments
    }
    
    private func calculatePlayConditions(_ conditions: WeatherConditions) -> PlayConditions {
        let temp = conditions.temperature
        let wind = conditions.windSpeed
        
        if conditions.condition == .storm || wind > 15 {
            return .challenging
        } else if conditions.condition == .rain && wind > 8 {
            return .difficult
        } else if temp < 5 || temp > 38 {
            return .uncomfortable
        } else if temp >= 18 && temp <= 28 && wind < 5 && conditions.condition == .clear {
            return .ideal
        } else if temp >= 15 && temp <= 30 && wind < 10 {
            return .good
        } else {
            return .fair
        }
    }
    
    private func mapWeatherCondition(_ condition: WeatherCondition) -> WeatherCondition {
        // Map WeatherKit conditions to our enum
        switch condition {
        case .clear, .mostlyClear:
            return .clear
        case .partlyCloudy:
            return .partlyCloudy
        case .cloudy, .mostlyCloudy:
            return .cloudy
        case .overcast:
            return .overcast
        case .foggy, .haze, .smoky:
            return .fog
        case .drizzle, .rain, .heavyRain, .showers:
            return .rain
        case .snow, .sleet, .flurries, .heavySnow:
            return .snow
        case .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms:
            return .storm
        default:
            return .clear
        }
    }
    
    private func getOverlayOpacity() -> Double {
        switch currentMood {
        case .moody, .melancholic:
            return 0.2
        case .mysterious:
            return 0.3
        case .dramatic:
            return 0.25
        default:
            return 0
        }
    }
    
    private func getGradientIntensity() -> Double {
        switch currentMood {
        case .vibrant:
            return 1.2
        case .cheerful:
            return 1.1
        case .intense:
            return 1.3
        default:
            return 1.0
        }
    }
    
    private func getAnimationSpeed() -> Double {
        guard let wind = currentConditions?.windSpeed else { return 1.0 }
        
        if wind > 10 {
            return 1.5
        } else if wind > 5 {
            return 1.2
        } else {
            return 1.0
        }
    }
    
    private func getRainIntensity() -> Double {
        guard let conditions = currentConditions else { return 0.5 }
        
        switch conditions.condition {
        case .rain:
            return conditions.precipitation > 5 ? 0.8 : 0.5
        case .storm:
            return 1.0
        default:
            return 0.3
        }
    }
    
    private func getBriefDescription(_ conditions: WeatherConditions) -> String {
        let temp = Int(conditions.temperature)
        
        switch conditions.condition {
        case .clear:
            return "Clear, \(temp)°"
        case .partlyCloudy:
            return "Partly Cloudy, \(temp)°"
        case .cloudy:
            return "Cloudy, \(temp)°"
        case .overcast:
            return "Overcast, \(temp)°"
        case .fog:
            return "Foggy, \(temp)°"
        case .rain:
            return "Rainy, \(temp)°"
        case .snow:
            return "Snowy, \(temp)°"
        case .storm:
            return "Stormy, \(temp)°"
        }
    }
    
    private func getDetailedDescription(_ conditions: WeatherConditions) -> String {
        var details = [String]()
        
        // Temperature feel
        if conditions.temperature > 30 {
            details.append("Hot")
        } else if conditions.temperature > 25 {
            details.append("Warm")
        } else if conditions.temperature > 18 {
            details.append("Pleasant")
        } else if conditions.temperature > 10 {
            details.append("Cool")
        } else {
            details.append("Cold")
        }
        
        // Wind
        if conditions.windSpeed > 10 {
            details.append("windy")
        } else if conditions.windSpeed > 5 {
            details.append("breezy")
        } else {
            details.append("calm")
        }
        
        // Visibility
        if conditions.visibility < 1000 {
            details.append("poor visibility")
        }
        
        return details.joined(separator: ", ")
    }
    
    private func getWeatherEmoji(_ conditions: WeatherConditions) -> String {
        switch conditions.condition {
        case .clear:
            return TimeEnvironmentService.shared.currentTimeContext == .night ? "🌙" : "☀️"
        case .partlyCloudy:
            return "⛅"
        case .cloudy:
            return "☁️"
        case .overcast:
            return "☁️"
        case .fog:
            return "🌫️"
        case .rain:
            return "🌧️"
        case .snow:
            return "❄️"
        case .storm:
            return "⛈️"
        }
    }
    
    private func getPlayAdvice(_ conditions: WeatherConditions) -> String? {
        if conditions.windSpeed > 10 {
            return "Club up in the wind"
        } else if conditions.condition == .rain {
            return "Keep grips and balls dry"
        } else if conditions.temperature > 35 {
            return "Stay hydrated"
        } else if conditions.temperature < 10 {
            return "Ball won't travel as far in cold"
        } else {
            return nil
        }
    }
}

// MARK: - Supporting Types

enum WeatherMood {
    case vibrant      // Clear, sunny, perfect conditions
    case cheerful     // Partly cloudy, pleasant
    case neutral      // Average conditions
    case moody        // Overcast, gray
    case melancholic  // Rainy, dreary
    case mysterious   // Foggy
    case dramatic     // Stormy
    case intense      // Very hot
    case crisp        // Cold, clear
}

struct WeatherVisualEffects: OptionSet {
    let rawValue: Int
    
    static let none = WeatherVisualEffects([])
    static let rain = WeatherVisualEffects(rawValue: 1 << 0)
    static let snow = WeatherVisualEffects(rawValue: 1 << 1)
    static let fog = WeatherVisualEffects(rawValue: 1 << 2)
    static let clouds = WeatherVisualEffects(rawValue: 1 << 3)
    static let lightning = WeatherVisualEffects(rawValue: 1 << 4)
    static let windLines = WeatherVisualEffects(rawValue: 1 << 5)
    static let leaves = WeatherVisualEffects(rawValue: 1 << 6)
    static let heatShimmer = WeatherVisualEffects(rawValue: 1 << 7)
    static let blur = WeatherVisualEffects(rawValue: 1 << 8)
}

struct ColorAdjustments {
    var saturationMultiplier: Double = 1.0
    var brightnessMultiplier: Double = 1.0
    var contrastMultiplier: Double = 1.0
    var warmthShift: Double = 0 // -1 to 1
    var coolnessShift: Double = 0 // -1 to 1
}

struct BackgroundAdjustments {
    let saturation: Double
    let brightness: Double
    let contrast: Double
    let blur: Double
    let overlayOpacity: Double
    let gradientIntensity: Double
    let animationSpeed: Double
}

struct ParticleEffect {
    enum ParticleType {
        case rain
        case snow
        case fog
        case leaves
        case pollen
        case dust
    }
    
    let type: ParticleType
    let intensity: Double // 0 to 1
    let color: UIColor
    let speed: Double // Animation speed multiplier
    let angle: Double // Direction in degrees
}

enum PlayConditions {
    case ideal
    case good
    case fair
    case challenging
    case difficult
    case uncomfortable
}

struct WeatherDescription {
    let brief: String
    let detailed: String
    let emoji: String
    let playAdvice: String?
}

enum WeatherUIEvent {
    case weatherUpdated(mood: WeatherMood, effects: WeatherVisualEffects)
    case playConditionsChanged(PlayConditions)
    case severeWeatherAlert(String)
}