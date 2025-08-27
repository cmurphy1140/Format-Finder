import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - Course Environment Service
// Provides course context to inform UI textures, backgrounds, and visual themes

@MainActor
final class CourseEnvironmentService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentEnvironment: CourseEnvironment?
    @Published private(set) var visualTheme: CourseVisualTheme = .standard
    @Published private(set) var backgroundTextures: BackgroundTextureSet = .parkland
    @Published private(set) var colorScheme: EnvironmentColorScheme = .grass
    @Published private(set) var ambientSounds: AmbientSoundscape = .birds
    
    // MARK: - Private Properties
    
    private var knownCourses: [UUID: CourseData] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let geocoder = CLGeocoder()
    
    // MARK: - Event Publisher
    
    private let eventPublisher = PassthroughSubject<CourseEnvironmentEvent, Never>()
    var events: AnyPublisher<CourseEnvironmentEvent, Never> {
        eventPublisher.eraseToAnyPublisher()
    }
    
    // MARK: - Singleton
    
    static let shared = CourseEnvironmentService()
    
    private init() {
        loadKnownCourses()
        subscribeToLocationUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Detect course environment from location
    func detectEnvironment(at location: CLLocation) async -> CourseEnvironment? {
        // First check if we're at a known course
        if let knownCourse = findKnownCourse(at: location) {
            let environment = knownCourse.environment
            await updateVisualTheme(for: environment)
            return environment
        }
        
        // Search for nearby golf courses
        if let detectedCourse = await searchNearbyGolfCourses(location: location) {
            let environment = await analyzeEnvironment(for: detectedCourse, at: location)
            await updateVisualTheme(for: environment)
            return environment
        }
        
        // Fall back to terrain analysis
        let environment = await analyzeTerrainEnvironment(at: location)
        await updateVisualTheme(for: environment)
        return environment
    }
    
    /// Get visual theme for course type
    func getVisualTheme(for environment: CourseEnvironment) -> CourseVisualTheme {
        switch environment.type {
        case .links:
            return .links(
                primary: UIColor(red: 0.4, green: 0.5, blue: 0.3, alpha: 1),
                secondary: UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 1),
                accent: UIColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1),
                textures: ["dunes", "fescue", "bunkers"],
                atmosphere: .windswept
            )
            
        case .parkland:
            return .parkland(
                primary: UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1),
                secondary: UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1),
                accent: UIColor(red: 0.6, green: 0.8, blue: 0.4, alpha: 1),
                textures: ["manicured", "trees", "fairway"],
                atmosphere: .serene
            )
            
        case .desert:
            return .desert(
                primary: UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1),
                secondary: UIColor(red: 0.6, green: 0.4, blue: 0.3, alpha: 1),
                accent: UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1),
                textures: ["sand", "rocks", "cactus"],
                atmosphere: .arid
            )
            
        case .mountain:
            return .mountain(
                primary: UIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1),
                secondary: UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1),
                accent: UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1),
                textures: ["elevation", "pines", "rocks"],
                atmosphere: .alpine
            )
            
        case .coastal:
            return .coastal(
                primary: UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 1),
                secondary: UIColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 1),
                accent: UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1),
                textures: ["ocean", "cliffs", "seaside"],
                atmosphere: .maritime
            )
            
        case .resort:
            return .resort(
                primary: UIColor(red: 0.3, green: 0.7, blue: 0.5, alpha: 1),
                secondary: UIColor(red: 0.9, green: 0.9, blue: 0.8, alpha: 1),
                accent: UIColor(red: 0.4, green: 0.8, blue: 0.9, alpha: 1),
                textures: ["tropical", "palms", "water"],
                atmosphere: .tropical
            )
        }
    }
    
    /// Get background textures for environment
    func getBackgroundTextures(for environment: CourseEnvironment) -> BackgroundTextureSet {
        let season = TimeEnvironmentService.shared.seasonalContext
        
        switch environment.type {
        case .links:
            return BackgroundTextureSet(
                primary: "texture_links_grass",
                secondary: "texture_links_dunes",
                overlay: season == .autumn ? "texture_links_autumn" : nil,
                pattern: .windswept,
                opacity: 0.3
            )
            
        case .parkland:
            return BackgroundTextureSet(
                primary: "texture_parkland_fairway",
                secondary: "texture_parkland_trees",
                overlay: season == .spring ? "texture_parkland_bloom" : nil,
                pattern: .manicured,
                opacity: 0.25
            )
            
        case .desert:
            return BackgroundTextureSet(
                primary: "texture_desert_sand",
                secondary: "texture_desert_rock",
                overlay: "texture_desert_heat",
                pattern: .natural,
                opacity: 0.35
            )
            
        case .mountain:
            return BackgroundTextureSet(
                primary: "texture_mountain_grass",
                secondary: "texture_mountain_pine",
                overlay: season == .winter ? "texture_mountain_snow" : nil,
                pattern: .elevation,
                opacity: 0.3
            )
            
        case .coastal:
            return BackgroundTextureSet(
                primary: "texture_coastal_grass",
                secondary: "texture_coastal_sand",
                overlay: "texture_coastal_mist",
                pattern: .coastal,
                opacity: 0.28
            )
            
        case .resort:
            return BackgroundTextureSet(
                primary: "texture_resort_grass",
                secondary: "texture_resort_palm",
                overlay: "texture_resort_tropical",
                pattern: .tropical,
                opacity: 0.22
            )
        }
    }
    
    /// Get dynamic UI adjustments for environment
    func getUIAdjustments(for environment: CourseEnvironment) -> EnvironmentUIAdjustments {
        var adjustments = EnvironmentUIAdjustments()
        
        // Adjust based on course type
        switch environment.type {
        case .links:
            adjustments.cardTransparency = 0.85
            adjustments.blurIntensity = 0.2
            adjustments.shadowSoftness = 1.2
            adjustments.cornerRadius = 12
            
        case .parkland:
            adjustments.cardTransparency = 0.9
            adjustments.blurIntensity = 0.15
            adjustments.shadowSoftness = 1.0
            adjustments.cornerRadius = 10
            
        case .desert:
            adjustments.cardTransparency = 0.88
            adjustments.blurIntensity = 0.1
            adjustments.shadowSoftness = 0.8
            adjustments.cornerRadius = 8
            adjustments.warmthBoost = 0.2
            
        case .mountain:
            adjustments.cardTransparency = 0.92
            adjustments.blurIntensity = 0.25
            adjustments.shadowSoftness = 1.3
            adjustments.cornerRadius = 14
            adjustments.coolnessBoost = 0.15
            
        case .coastal:
            adjustments.cardTransparency = 0.87
            adjustments.blurIntensity = 0.3
            adjustments.shadowSoftness = 1.1
            adjustments.cornerRadius = 11
            adjustments.saturationBoost = 0.1
            
        case .resort:
            adjustments.cardTransparency = 0.85
            adjustments.blurIntensity = 0.18
            adjustments.shadowSoftness = 0.9
            adjustments.cornerRadius = 15
            adjustments.vibrancyBoost = 0.15
        }
        
        // Adjust for elevation
        if environment.elevation > 1000 {
            adjustments.coolnessBoost += 0.1
            adjustments.blurIntensity += 0.05
        }
        
        // Adjust for water proximity
        if environment.nearWater {
            adjustments.saturationBoost += 0.05
            adjustments.reflectionIntensity = 0.3
        }
        
        return adjustments
    }
    
    /// Get ambient sounds for environment
    func getAmbientSounds(for environment: CourseEnvironment) -> AmbientSoundscape {
        switch environment.type {
        case .links:
            return .wind
        case .parkland:
            return .birds
        case .desert:
            return .desert
        case .mountain:
            return .mountain
        case .coastal:
            return .ocean
        case .resort:
            return .tropical
        }
    }
    
    // MARK: - Private Methods
    
    private func loadKnownCourses() {
        // Load famous courses with pre-defined environments
        knownCourses = loadPredefinedCourses()
    }
    
    private func subscribeToLocationUpdates() {
        TimeEnvironmentService.shared.events
            .sink { [weak self] event in
                switch event {
                case .locationChanged(let location):
                    Task {
                        _ = await self?.detectEnvironment(at: location)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private func findKnownCourse(at location: CLLocation) -> CourseData? {
        for course in knownCourses.values {
            let distance = location.distance(from: course.location)
            if distance < 1000 { // Within 1km
                return course
            }
        }
        return nil
    }
    
    private func searchNearbyGolfCourses(location: CLLocation) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "golf course"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems.first
        } catch {
            return nil
        }
    }
    
    private func analyzeEnvironment(for mapItem: MKMapItem, at location: CLLocation) async -> CourseEnvironment {
        let type = detectCourseType(from: mapItem)
        let terrain = await analyzeTerrainType(at: location)
        let vegetation = detectVegetationType(from: mapItem, location: location)
        
        return CourseEnvironment(
            type: type,
            terrain: terrain,
            vegetation: vegetation,
            elevation: location.altitude,
            nearWater: await checkWaterProximity(at: location),
            textureStyle: determineTextureStyle(type: type, terrain: terrain)
        )
    }
    
    private func analyzeTerrainEnvironment(at location: CLLocation) async -> CourseEnvironment {
        // Fallback terrain analysis
        let terrain = await analyzeTerrainType(at: location)
        let vegetation = await detectVegetationFromLocation(location)
        let nearWater = await checkWaterProximity(at: location)
        
        // Guess course type from terrain
        let type: CourseType
        if nearWater && location.altitude < 100 {
            type = .coastal
        } else if location.altitude > 1500 {
            type = .mountain
        } else if await isDesertRegion(location) {
            type = .desert
        } else {
            type = .parkland
        }
        
        return CourseEnvironment(
            type: type,
            terrain: terrain,
            vegetation: vegetation,
            elevation: location.altitude,
            nearWater: nearWater,
            textureStyle: determineTextureStyle(type: type, terrain: terrain)
        )
    }
    
    private func detectCourseType(from mapItem: MKMapItem) -> CourseType {
        let name = mapItem.name?.lowercased() ?? ""
        
        if name.contains("links") || name.contains("dunes") {
            return .links
        } else if name.contains("resort") || name.contains("club") {
            return .resort
        } else if name.contains("desert") || name.contains("canyon") {
            return .desert
        } else if name.contains("mountain") || name.contains("highland") {
            return .mountain
        } else if name.contains("beach") || name.contains("ocean") || name.contains("bay") {
            return .coastal
        } else {
            return .parkland
        }
    }
    
    private func analyzeTerrainType(at location: CLLocation) async -> TerrainType {
        let elevation = location.altitude
        
        if elevation < 100 {
            return .flat
        } else if elevation < 500 {
            return .rolling
        } else if elevation < 1000 {
            return .hilly
        } else {
            return .mountainous
        }
    }
    
    private func detectVegetationType(from mapItem: MKMapItem, location: CLLocation) -> VegetationType {
        // Use region and name hints
        if location.coordinate.latitude < 35 && location.coordinate.latitude > 25 {
            return .palm
        } else if mapItem.name?.contains("Pine") == true {
            return .pine
        } else {
            return .grass
        }
    }
    
    private func detectVegetationFromLocation(_ location: CLLocation) async -> VegetationType {
        // Basic vegetation detection based on coordinates
        let lat = location.coordinate.latitude
        
        if lat > 45 || lat < -45 {
            return .pine
        } else if lat < 35 && lat > 25 {
            return .palm
        } else {
            return .grass
        }
    }
    
    private func checkWaterProximity(at location: CLLocation) async -> Bool {
        // Check for water features nearby
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "water ocean lake river"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return !response.mapItems.isEmpty
        } catch {
            return false
        }
    }
    
    private func isDesertRegion(_ location: CLLocation) async -> Bool {
        // Check if in known desert regions
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let state = placemarks.first?.administrativeArea {
                let desertStates = ["Arizona", "Nevada", "New Mexico", "AZ", "NV", "NM"]
                return desertStates.contains(state)
            }
        } catch {
            return false
        }
        return false
    }
    
    private func determineTextureStyle(type: CourseType, terrain: TerrainType) -> TextureStyle {
        switch type {
        case .links:
            return .rugged
        case .parkland:
            return .manicured
        case .desert:
            return terrain == .mountainous ? .mountain : .desert
        case .mountain:
            return .mountain
        case .coastal:
            return .coastal
        case .resort:
            return .tropical
        }
    }
    
    private func updateVisualTheme(for environment: CourseEnvironment) async {
        self.currentEnvironment = environment
        self.visualTheme = getVisualTheme(for: environment)
        self.backgroundTextures = getBackgroundTextures(for: environment)
        self.colorScheme = getColorScheme(for: environment)
        self.ambientSounds = getAmbientSounds(for: environment)
        
        // Notify UI
        eventPublisher.send(.environmentDetected(environment))
    }
    
    private func getColorScheme(for environment: CourseEnvironment) -> EnvironmentColorScheme {
        switch environment.vegetation {
        case .grass:
            return .grass
        case .pine:
            return .pine
        case .palm:
            return .tropical
        case .cactus:
            return .desert
        case .mixed:
            return .mixed
        }
    }
    
    private func loadPredefinedCourses() -> [UUID: CourseData] {
        var courses: [UUID: CourseData] = [:]
        
        // Pebble Beach
        let pebbleBeach = CourseData(
            id: UUID(),
            name: "Pebble Beach Golf Links",
            location: CLLocation(latitude: 36.5667, longitude: -121.9500),
            environment: CourseEnvironment(
                type: .coastal,
                terrain: .rolling,
                vegetation: .grass,
                elevation: 50,
                nearWater: true,
                textureStyle: .coastal
            )
        )
        courses[pebbleBeach.id] = pebbleBeach
        
        // St. Andrews
        let stAndrews = CourseData(
            id: UUID(),
            name: "St. Andrews Old Course",
            location: CLLocation(latitude: 56.3498, longitude: -2.8028),
            environment: CourseEnvironment(
                type: .links,
                terrain: .rolling,
                vegetation: .grass,
                elevation: 20,
                nearWater: true,
                textureStyle: .rugged
            )
        )
        courses[stAndrews.id] = stAndrews
        
        // Add more famous courses...
        
        return courses
    }
}

// MARK: - Supporting Types

enum CourseVisualTheme {
    case standard
    case links(primary: UIColor, secondary: UIColor, accent: UIColor, textures: [String], atmosphere: Atmosphere)
    case parkland(primary: UIColor, secondary: UIColor, accent: UIColor, textures: [String], atmosphere: Atmosphere)
    case desert(primary: UIColor, secondary: UIColor, accent: UIColor, textures: [String], atmosphere: Atmosphere)
    case mountain(primary: UIColor, secondary: UIColor, accent: UIColor, textures: [String], atmosphere: Atmosphere)
    case coastal(primary: UIColor, secondary: UIColor, accent: UIColor, textures: [String], atmosphere: Atmosphere)
    case resort(primary: UIColor, secondary: UIColor, accent: UIColor, textures: [String], atmosphere: Atmosphere)
}

enum Atmosphere {
    case windswept
    case serene
    case arid
    case alpine
    case maritime
    case tropical
}

struct BackgroundTextureSet {
    let primary: String
    let secondary: String
    let overlay: String?
    let pattern: TexturePattern
    let opacity: Double
}

enum TexturePattern {
    case windswept
    case manicured
    case natural
    case elevation
    case coastal
    case tropical
}

enum EnvironmentColorScheme {
    case grass
    case pine
    case tropical
    case desert
    case mixed
}

enum AmbientSoundscape {
    case birds
    case wind
    case ocean
    case desert
    case mountain
    case tropical
    case silent
}

struct EnvironmentUIAdjustments {
    var cardTransparency: Double = 0.9
    var blurIntensity: Double = 0.2
    var shadowSoftness: Double = 1.0
    var cornerRadius: CGFloat = 10
    var warmthBoost: Double = 0
    var coolnessBoost: Double = 0
    var saturationBoost: Double = 0
    var vibrancyBoost: Double = 0
    var reflectionIntensity: Double = 0
}

struct CourseData {
    let id: UUID
    let name: String
    let location: CLLocation
    let environment: CourseEnvironment
}

enum CourseEnvironmentEvent {
    case environmentDetected(CourseEnvironment)
    case themeChanged(CourseVisualTheme)
    case texturesUpdated(BackgroundTextureSet)
}