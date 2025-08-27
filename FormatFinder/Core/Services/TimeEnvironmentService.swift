import Foundation
import CoreLocation
import Solar
import Combine

// MARK: - Time & Environment Service
// Powers UI's environmental awareness with precise time, weather, and location data

@MainActor
final class TimeEnvironmentService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentTimeContext: TimeContext = .day
    @Published private(set) var solarEvents: SolarEvents?
    @Published private(set) var colorPalette: ColorPalette = ColorPalette.day
    @Published private(set) var ambientBrightness: Double = 1.0
    @Published private(set) var seasonalContext: SeasonalContext = .summer
    @Published private(set) var isDynamicUpdateEnabled = true
    
    // MARK: - Time Tracking
    
    private var timeUpdateTimer: Timer?
    private let updateInterval: TimeInterval = 60 // Update every minute
    private var lastSolarCalculation = Date.distantPast
    private let solarCalculationInterval: TimeInterval = 3600 // Recalculate every hour
    
    // MARK: - Location
    
    private var currentLocation: CLLocation?
    private let locationManager = CLLocationManager()
    
    // MARK: - Event System
    
    private let eventPublisher = PassthroughSubject<EnvironmentEvent, Never>()
    var events: AnyPublisher<EnvironmentEvent, Never> {
        eventPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Singleton
    
    static let shared = TimeEnvironmentService()
    
    private init() {
        setupTimeTracking()
        setupLocationServices()
        calculateInitialContext()
    }
    
    // MARK: - Public Methods
    
    /// Get current time context with transitions
    func getCurrentTimeContext() -> TimeContextInfo {
        let now = Date()
        guard let solar = solarEvents else {
            return TimeContextInfo(
                context: .day,
                progress: 0.5,
                nextContext: .dusk,
                timeToNext: 3600
            )
        }
        
        return calculateTimeContext(date: now, solar: solar)
    }
    
    /// Get color palette for current conditions
    func getAdaptiveColorPalette() -> ColorPalette {
        var palette = getBaseColorPalette()
        
        // Apply seasonal adjustments
        palette = applySeasonalAdjustments(palette, season: seasonalContext)
        
        // Apply time-of-day modifications
        palette = applyTimeModifications(palette, context: currentTimeContext)
        
        // Apply ambient brightness
        palette = applyBrightnessAdjustment(palette, brightness: ambientBrightness)
        
        return palette
    }
    
    /// Calculate precise solar events for location
    func calculateSolarEvents(for location: CLLocation? = nil) {
        let targetLocation = location ?? currentLocation ?? getDefaultLocation()
        
        // Use Solar library for precise calculations
        guard let solar = Solar(coordinate: targetLocation.coordinate) else {
            return
        }
        
        let events = SolarEvents(
            sunrise: solar.sunrise ?? Date(),
            sunset: solar.sunset ?? Date(),
            solarNoon: solar.solarNoon ?? Date(),
            civilDawn: solar.civilSunrise ?? Date(),
            civilDusk: solar.civilSunset ?? Date(),
            nauticalDawn: solar.nauticalSunrise ?? Date(),
            nauticalDusk: solar.nauticalSunset ?? Date(),
            astronomicalDawn: solar.astronomicalSunrise ?? Date(),
            astronomicalDusk: solar.astronomicalSunset ?? Date(),
            goldenHourStart: calculateGoldenHourStart(sunset: solar.sunset ?? Date()),
            goldenHourEnd: solar.sunset ?? Date(),
            blueHourStart: solar.sunset ?? Date(),
            blueHourEnd: calculateBlueHourEnd(sunset: solar.sunset ?? Date())
        )
        
        self.solarEvents = events
        lastSolarCalculation = Date()
        
        // Update time context
        updateTimeContext()
        
        // Notify UI
        eventPublisher.send(.solarEventsUpdated(events))
    }
    
    /// Update location and recalculate environment
    func updateLocation(_ location: CLLocation) {
        currentLocation = location
        
        // Recalculate solar events
        calculateSolarEvents(for: location)
        
        // Update seasonal context
        updateSeasonalContext(for: location)
        
        // Notify UI
        eventPublisher.send(.locationChanged(location))
    }
    
    /// Enable or disable dynamic updates
    func setDynamicUpdates(enabled: Bool) {
        isDynamicUpdateEnabled = enabled
        
        if enabled {
            startTimeTracking()
        } else {
            stopTimeTracking()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupTimeTracking() {
        guard isDynamicUpdateEnabled else { return }
        
        timeUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimeContext()
                self?.checkForSolarRecalculation()
            }
        }
    }
    
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func calculateInitialContext() {
        // Set initial values
        let now = Date()
        
        // Determine season
        seasonalContext = calculateSeason(date: now)
        
        // Calculate initial solar events
        calculateSolarEvents()
        
        // Set initial time context
        updateTimeContext()
    }
    
    private func updateTimeContext() {
        let contextInfo = getCurrentTimeContext()
        
        if currentTimeContext != contextInfo.context {
            let oldContext = currentTimeContext
            currentTimeContext = contextInfo.context
            
            // Update color palette
            colorPalette = getAdaptiveColorPalette()
            
            // Notify transition
            eventPublisher.send(.timeContextChanged(
                from: oldContext,
                to: contextInfo.context,
                progress: contextInfo.progress
            ))
        }
        
        // Update ambient brightness based on time
        updateAmbientBrightness(for: contextInfo)
    }
    
    private func calculateTimeContext(date: Date, solar: SolarEvents) -> TimeContextInfo {
        let now = date.timeIntervalSince1970
        
        // Define time periods with transitions
        let periods: [(start: Date, end: Date, context: TimeContext)] = [
            (solar.astronomicalDawn, solar.nauticalDawn, .night),
            (solar.nauticalDawn, solar.civilDawn, .astronomicalTwilight),
            (solar.civilDawn, solar.sunrise, .dawn),
            (solar.sunrise, solar.sunrise.addingTimeInterval(1800), .sunrise),
            (solar.sunrise.addingTimeInterval(1800), solar.goldenHourStart, .morning),
            (solar.goldenHourStart.addingTimeInterval(-3600), solar.solarNoon, .midday),
            (solar.solarNoon, solar.goldenHourStart, .afternoon),
            (solar.goldenHourStart, solar.goldenHourEnd, .goldenHour),
            (solar.sunset, solar.blueHourEnd, .sunset),
            (solar.blueHourEnd, solar.civilDusk, .dusk),
            (solar.civilDusk, solar.nauticalDusk, .twilight),
            (solar.nauticalDusk, solar.astronomicalDusk, .blueTwilight)
        ]
        
        for (i, period) in periods.enumerated() {
            let start = period.start.timeIntervalSince1970
            let end = period.end.timeIntervalSince1970
            
            if now >= start && now < end {
                let progress = (now - start) / (end - start)
                let nextContext = i < periods.count - 1 ? periods[i + 1].context : .night
                let timeToNext = end - now
                
                return TimeContextInfo(
                    context: period.context,
                    progress: progress,
                    nextContext: nextContext,
                    timeToNext: timeToNext
                )
            }
        }
        
        // Default to night
        return TimeContextInfo(
            context: .night,
            progress: 0,
            nextContext: .astronomicalTwilight,
            timeToNext: solar.astronomicalDawn.timeIntervalSince(date)
        )
    }
    
    private func getBaseColorPalette() -> ColorPalette {
        switch currentTimeContext {
        case .night:
            return ColorPalette.night
        case .astronomicalTwilight:
            return ColorPalette.astronomicalTwilight
        case .dawn:
            return ColorPalette.dawn
        case .sunrise:
            return ColorPalette.sunrise
        case .morning:
            return ColorPalette.morning
        case .midday:
            return ColorPalette.midday
        case .afternoon:
            return ColorPalette.afternoon
        case .goldenHour:
            return ColorPalette.goldenHour
        case .sunset:
            return ColorPalette.sunset
        case .dusk:
            return ColorPalette.dusk
        case .twilight:
            return ColorPalette.twilight
        case .blueTwilight:
            return ColorPalette.blueTwilight
        default:
            return ColorPalette.day
        }
    }
    
    private func applySeasonalAdjustments(_ palette: ColorPalette, season: SeasonalContext) -> ColorPalette {
        var adjusted = palette
        
        switch season {
        case .spring:
            // Increase green tints, add freshness
            adjusted.primary = adjustHue(adjusted.primary, by: -5)
            adjusted.saturationMultiplier = 1.1
            
        case .summer:
            // Increase warmth and vibrancy
            adjusted.warmth += 0.1
            adjusted.saturationMultiplier = 1.2
            
        case .autumn:
            // Add orange/red tints
            adjusted.primary = adjustHue(adjusted.primary, by: 15)
            adjusted.warmth += 0.2
            
        case .winter:
            // Cool down colors, reduce saturation
            adjusted.warmth -= 0.15
            adjusted.saturationMultiplier = 0.85
        }
        
        return adjusted
    }
    
    private func applyTimeModifications(_ palette: ColorPalette, context: TimeContext) -> ColorPalette {
        var modified = palette
        
        // Apply time-specific modifications
        let contextInfo = getCurrentTimeContext()
        let progress = contextInfo.progress
        
        // Smooth transitions between contexts
        if progress < 0.2 || progress > 0.8 {
            // Near transition points, blend with adjacent palette
            let blendFactor = progress < 0.5 ? progress * 5 : (1 - progress) * 5
            modified.transitionBlend = blendFactor
        }
        
        return modified
    }
    
    private func applyBrightnessAdjustment(_ palette: ColorPalette, brightness: Double) -> ColorPalette {
        var adjusted = palette
        adjusted.brightnessMultiplier = brightness
        return adjusted
    }
    
    private func updateAmbientBrightness(for contextInfo: TimeContextInfo) {
        // Calculate ambient brightness based on time of day
        switch contextInfo.context {
        case .night, .astronomicalTwilight:
            ambientBrightness = 0.2
        case .dawn, .blueTwilight:
            ambientBrightness = 0.4
        case .sunrise, .sunset:
            ambientBrightness = 0.7
        case .twilight, .dusk:
            ambientBrightness = 0.6
        case .goldenHour:
            ambientBrightness = 0.9
        case .morning, .afternoon:
            ambientBrightness = 1.0
        case .midday:
            ambientBrightness = 1.1 // Slightly over-bright at noon
        default:
            ambientBrightness = 1.0
        }
    }
    
    private func calculateSeason(date: Date, latitude: Double? = nil) -> SeasonalContext {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        
        // Adjust for hemisphere if latitude provided
        let isNorthernHemisphere = (latitude ?? 0) >= 0
        
        if isNorthernHemisphere {
            switch month {
            case 3...5: return .spring
            case 6...8: return .summer
            case 9...11: return .autumn
            default: return .winter
            }
        } else {
            // Southern hemisphere - seasons reversed
            switch month {
            case 3...5: return .autumn
            case 6...8: return .winter
            case 9...11: return .spring
            default: return .summer
            }
        }
    }
    
    private func updateSeasonalContext(for location: CLLocation) {
        let newSeason = calculateSeason(date: Date(), latitude: location.coordinate.latitude)
        
        if newSeason != seasonalContext {
            let oldSeason = seasonalContext
            seasonalContext = newSeason
            
            // Update colors
            colorPalette = getAdaptiveColorPalette()
            
            // Notify change
            eventPublisher.send(.seasonChanged(from: oldSeason, to: newSeason))
        }
    }
    
    private func checkForSolarRecalculation() {
        if Date().timeIntervalSince(lastSolarCalculation) > solarCalculationInterval {
            calculateSolarEvents()
        }
    }
    
    private func calculateGoldenHourStart(sunset: Date) -> Date {
        // Golden hour typically starts 1 hour before sunset
        return sunset.addingTimeInterval(-3600)
    }
    
    private func calculateBlueHourEnd(sunset: Date) -> Date {
        // Blue hour typically ends 40 minutes after sunset
        return sunset.addingTimeInterval(2400)
    }
    
    private func adjustHue(_ color: UIColor, by degrees: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        hue += degrees / 360.0
        if hue > 1 { hue -= 1 }
        if hue < 0 { hue += 1 }
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    private func getDefaultLocation() -> CLLocation {
        // Default to Pebble Beach, CA
        return CLLocation(latitude: 36.5667, longitude: -121.9500)
    }
    
    private func startTimeTracking() {
        setupTimeTracking()
    }
    
    private func stopTimeTracking() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
}

// MARK: - CLLocationManagerDelegate

extension TimeEnvironmentService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            self.updateLocation(location)
        }
    }
}

// MARK: - Supporting Types

struct TimeContextInfo {
    let context: TimeContext
    let progress: Double // 0.0 to 1.0 within current context
    let nextContext: TimeContext
    let timeToNext: TimeInterval
}

enum TimeContext: String, CaseIterable {
    case night
    case astronomicalTwilight
    case dawn
    case sunrise
    case morning
    case midday
    case afternoon
    case goldenHour
    case sunset
    case dusk
    case twilight
    case blueTwilight
    case day // Generic fallback
}

struct SolarEvents {
    let sunrise: Date
    let sunset: Date
    let solarNoon: Date
    let civilDawn: Date
    let civilDusk: Date
    let nauticalDawn: Date
    let nauticalDusk: Date
    let astronomicalDawn: Date
    let astronomicalDusk: Date
    let goldenHourStart: Date
    let goldenHourEnd: Date
    let blueHourStart: Date
    let blueHourEnd: Date
}

enum SeasonalContext {
    case spring
    case summer
    case autumn
    case winter
}

struct ColorPalette {
    var primary: UIColor
    var secondary: UIColor
    var tertiary: UIColor
    var background: UIColor
    var surface: UIColor
    var text: UIColor
    var warmth: Double // -1.0 (cool) to 1.0 (warm)
    var saturationMultiplier: Double
    var brightnessMultiplier: Double
    var transitionBlend: Double // For smooth transitions
    
    // Predefined palettes for each time context
    static let night = ColorPalette(
        primary: UIColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1),
        secondary: UIColor(red: 0.05, green: 0.05, blue: 0.2, alpha: 1),
        tertiary: UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1),
        background: UIColor.black,
        surface: UIColor(white: 0.1, alpha: 1),
        text: UIColor(white: 0.8, alpha: 1),
        warmth: -0.3,
        saturationMultiplier: 0.6,
        brightnessMultiplier: 0.2,
        transitionBlend: 0
    )
    
    static let dawn = ColorPalette(
        primary: UIColor(red: 0.9, green: 0.6, blue: 0.4, alpha: 1),
        secondary: UIColor(red: 0.6, green: 0.4, blue: 0.5, alpha: 1),
        tertiary: UIColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1),
        background: UIColor(red: 0.95, green: 0.9, blue: 0.85, alpha: 1),
        surface: UIColor(red: 1, green: 0.98, blue: 0.95, alpha: 1),
        text: UIColor(white: 0.2, alpha: 1),
        warmth: 0.3,
        saturationMultiplier: 0.8,
        brightnessMultiplier: 0.6,
        transitionBlend: 0
    )
    
    static let day = ColorPalette(
        primary: UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1),
        secondary: UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),
        tertiary: UIColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1),
        background: UIColor.white,
        surface: UIColor(white: 0.98, alpha: 1),
        text: UIColor(white: 0.1, alpha: 1),
        warmth: 0,
        saturationMultiplier: 1.0,
        brightnessMultiplier: 1.0,
        transitionBlend: 0
    )
    
    static let goldenHour = ColorPalette(
        primary: UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1),
        secondary: UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1),
        tertiary: UIColor(red: 0.9, green: 0.6, blue: 0.4, alpha: 1),
        background: UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1),
        surface: UIColor(red: 1.0, green: 0.98, blue: 0.94, alpha: 1),
        text: UIColor(white: 0.15, alpha: 1),
        warmth: 0.6,
        saturationMultiplier: 1.3,
        brightnessMultiplier: 0.9,
        transitionBlend: 0
    )
    
    // Additional palette definitions...
    static let astronomicalTwilight = night
    static let sunrise = dawn
    static let morning = day
    static let midday = day
    static let afternoon = day
    static let sunset = goldenHour
    static let dusk = dawn
    static let twilight = dawn
    static let blueTwilight = night
}

enum EnvironmentEvent {
    case solarEventsUpdated(SolarEvents)
    case timeContextChanged(from: TimeContext, to: TimeContext, progress: Double)
    case seasonChanged(from: SeasonalContext, to: SeasonalContext)
    case locationChanged(CLLocation)
    case weatherUpdated(WeatherConditions)
    case courseEnvironmentDetected(CourseEnvironment)
}

struct WeatherConditions {
    let temperature: Double
    let cloudCover: Double // 0.0 to 1.0
    let precipitation: Double // mm/hour
    let windSpeed: Double // m/s
    let visibility: Double // meters
    let condition: WeatherCondition
}

enum WeatherCondition {
    case clear
    case partlyCloudy
    case cloudy
    case overcast
    case fog
    case rain
    case snow
    case storm
}

struct CourseEnvironment {
    let type: CourseType
    let terrain: TerrainType
    let vegetation: VegetationType
    let elevation: Double
    let nearWater: Bool
    let textureStyle: TextureStyle
}

enum CourseType {
    case links
    case parkland
    case desert
    case mountain
    case coastal
    case resort
}

enum TerrainType {
    case flat
    case rolling
    case hilly
    case mountainous
}

enum VegetationType {
    case grass
    case pine
    case palm
    case cactus
    case mixed
}

enum TextureStyle {
    case manicured
    case natural
    case rugged
    case tropical
    case desert
    case mountain
    case coastal
    case standard
}

// MARK: - Solar Library Mock (Replace with actual Solar pod/package)

struct Solar {
    let coordinate: CLLocationCoordinate2D
    
    var sunrise: Date? {
        // Mock calculation - replace with actual Solar library
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 30
        return calendar.date(from: components)
    }
    
    var sunset: Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 19
        components.minute = 30
        return calendar.date(from: components)
    }
    
    var solarNoon: Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 13
        components.minute = 0
        return calendar.date(from: components)
    }
    
    var civilSunrise: Date? {
        sunrise?.addingTimeInterval(-1800)
    }
    
    var civilSunset: Date? {
        sunset?.addingTimeInterval(1800)
    }
    
    var nauticalSunrise: Date? {
        sunrise?.addingTimeInterval(-3600)
    }
    
    var nauticalSunset: Date? {
        sunset?.addingTimeInterval(3600)
    }
    
    var astronomicalSunrise: Date? {
        sunrise?.addingTimeInterval(-5400)
    }
    
    var astronomicalSunset: Date? {
        sunset?.addingTimeInterval(5400)
    }
}