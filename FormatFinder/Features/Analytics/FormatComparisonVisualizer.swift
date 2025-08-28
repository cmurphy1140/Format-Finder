import SwiftUI
import Charts

// MARK: - Format Analytics Data Model
struct FormatAnalytics {
    let format: GolfFormat
    let popularity: Double          // 0-100 popularity score
    let skillLevel: Double          // 1-5 required skill
    let socialAspect: Double        // 1-5 social interaction
    let competitiveness: Double     // 1-5 competitive level
    let paceOfPlay: Double          // 1-5 pace (1=slow, 5=fast)
    let strategy: Double            // 1-5 strategic depth
    let funFactor: Double           // 1-5 enjoyment rating
    let learning: Double            // 1-5 ease of learning
    
    // Usage statistics
    let weeklyPlays: Int
    let averageGroupSize: Double
    let preferredByHandicap: ClosedRange<Int>
    let tournamentUsage: Double    // % of tournaments using this format
    
    // Demographic preferences
    let ageGroupPreference: [AgeGroup: Double]
    let skillPreference: [SkillLevel: Double]
}

enum AgeGroup: String, CaseIterable {
    case youth = "Under 25"
    case young = "25-40"
    case middle = "40-55"
    case senior = "55+"
}

enum SkillLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

// MARK: - Main Comparison Visualizer
struct FormatComparisonVisualizer: View {
    @State private var selectedFormats: Set<String> = ["Scramble", "Best Ball", "Match Play"]
    @State private var comparisonMode: ComparisonMode = .radar
    @State private var sortBy: SortMetric = .popularity
    @State private var filterSkillLevel: SkillLevel? = nil
    @State private var animateCharts = false
    
    let analytics = FormatAnalyticsProvider.generateAnalytics()
    
    enum ComparisonMode: String, CaseIterable {
        case radar = "Radar"
        case bars = "Bars"
        case matrix = "Matrix"
        case trends = "Trends"
        case recommendations = "For You"
    }
    
    enum SortMetric: String, CaseIterable {
        case popularity = "Most Popular"
        case skill = "Skill Level"
        case social = "Most Social"
        case competitive = "Competition"
        case pace = "Pace of Play"
        case fun = "Fun Factor"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Professional gradient background
                LinearGradient(
                    colors: [
                        MastersColors.fairwayMist,
                        MastersColors.magnoliaLane
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: MastersLayout.largeSpacing) {
                        // Header
                        headerSection
                        
                        // Mode Selector
                        modeSelector
                            .padding(.horizontal)
                        
                        // Main Visualization
                        mainVisualization
                            .padding(.horizontal)
                        
                        // Format Selector
                        formatSelector
                            .padding(.horizontal)
                        
                        // Additional Insights
                        insightsSection
                            .padding(.horizontal)
                    }
                    .padding(.vertical, MastersLayout.largeSpacing)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateCharts = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: MastersLayout.smallSpacing) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundColor(MastersColors.mastersGreen)
            
            Text("Format Analytics")
                .font(MastersTypography.displayTitle())
                .foregroundColor(MastersColors.graphite)
            
            Text("Compare and discover the perfect format for your game")
                .font(MastersTypography.bodyText())
                .foregroundColor(MastersColors.silver)
                .multilineTextAlignment(.center)
        }
        .padding(.top, MastersLayout.heroSpacing)
    }
    
    // MARK: - Mode Selector
    private var modeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MastersLayout.smallSpacing) {
                ForEach(ComparisonMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.spring()) {
                            comparisonMode = mode
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: modeIcon(for: mode))
                                .font(.system(size: 16))
                            Text(mode.rawValue)
                                .font(MastersTypography.captionText())
                        }
                        .foregroundColor(comparisonMode == mode ? .white : MastersColors.mastersGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(comparisonMode == mode ? 
                                      MastersColors.mastersGreen : 
                                      MastersColors.mastersGreen.opacity(0.1))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Main Visualization
    @ViewBuilder
    private var mainVisualization: some View {
        switch comparisonMode {
        case .radar:
            RadarChartComparison(
                selectedFormats: selectedFormats,
                analytics: analytics,
                animated: animateCharts
            )
        case .bars:
            BarChartComparison(
                selectedFormats: selectedFormats,
                analytics: analytics,
                sortBy: sortBy
            )
        case .matrix:
            ComparisonMatrix(
                selectedFormats: selectedFormats,
                analytics: analytics
            )
        case .trends:
            PopularityTrends(analytics: analytics)
        case .recommendations:
            PersonalizedRecommendations(
                analytics: analytics,
                skillLevel: filterSkillLevel
            )
        }
    }
    
    // MARK: - Format Selector
    private var formatSelector: some View {
        VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
            Text("SELECT FORMATS TO COMPARE")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: MastersLayout.smallSpacing) {
                ForEach(analytics, id: \.format.id) { data in
                    FormatChip(
                        name: data.format.name,
                        isSelected: selectedFormats.contains(data.format.name),
                        popularity: data.popularity
                    ) {
                        withAnimation {
                            if selectedFormats.contains(data.format.name) {
                                selectedFormats.remove(data.format.name)
                            } else {
                                selectedFormats.insert(data.format.name)
                            }
                        }
                    }
                }
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(spacing: MastersLayout.standardSpacing) {
            // Quick Stats
            QuickStatsRow(analytics: analytics, selectedFormats: selectedFormats)
            
            // Popularity by Demographics
            DemographicsChart(analytics: analytics, selectedFormats: selectedFormats)
            
            // Skill Level Distribution
            SkillDistribution(analytics: analytics, selectedFormats: selectedFormats)
        }
    }
    
    private func modeIcon(for mode: ComparisonMode) -> String {
        switch mode {
        case .radar: return "hexagon"
        case .bars: return "chart.bar"
        case .matrix: return "square.grid.3x3"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .recommendations: return "star.circle"
        }
    }
}

// MARK: - Radar Chart Comparison
struct RadarChartComparison: View {
    let selectedFormats: Set<String>
    let analytics: [FormatAnalytics]
    let animated: Bool
    
    @State private var animationProgress: Double = 0
    
    let dimensions = [
        ("Popularity", \FormatAnalytics.popularity),
        ("Skill Required", \FormatAnalytics.skillLevel),
        ("Social", \FormatAnalytics.socialAspect),
        ("Competition", \FormatAnalytics.competitiveness),
        ("Pace", \FormatAnalytics.paceOfPlay),
        ("Strategy", \FormatAnalytics.strategy),
        ("Fun", \FormatAnalytics.funFactor),
        ("Easy to Learn", \FormatAnalytics.learning)
    ]
    
    var body: some View {
        VStack(spacing: MastersLayout.standardSpacing) {
            Text("FORMAT CHARACTERISTICS")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            GeometryReader { geometry in
                ZStack {
                    radarChartBackground(geometry: geometry)
                    radarChartPolygons(geometry: geometry)
                    radarChartLabels(geometry: geometry)
                }
            }
            .frame(height: 350)
            
            // Legend
            HStack(spacing: MastersLayout.standardSpacing) {
                ForEach(analytics.filter { selectedFormats.contains($0.format.name) }, 
                        id: \.format.id) { data in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(formatColor(for: data.format.name))
                            .frame(width: 8, height: 8)
                        Text(data.format.name)
                            .font(MastersTypography.captionText())
                            .foregroundColor(MastersColors.graphite)
                    }
                }
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
    
    @ViewBuilder
    private func radarChartBackground(geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
        
        RadarGrid(
            center: center,
            radius: radius,
            dimensions: dimensions.count
        )
    }
    
    @ViewBuilder
    private func radarChartPolygons(geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
        
        ForEach(analytics.filter { selectedFormats.contains($0.format.name) }, 
                id: \.format.id) { data in
            RadarPolygon(
                data: data,
                dimensions: dimensions.map { $0.1 },
                center: center,
                radius: radius,
                color: formatColor(for: data.format.name),
                animationProgress: animationProgress
            )
        }
    }
    
    @ViewBuilder
    private func radarChartLabels(geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
        
        ForEach(0..<dimensions.count, id: \.self) { index in
            radarLabel(index: index, center: center, radius: radius)
        }
    }
    
    private func radarLabel(index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let angle = (Double(index) * 2 * .pi / Double(dimensions.count)) - .pi / 2
        let labelRadius = radius + 25
        let x = center.x + cos(angle) * labelRadius
        let y = center.y + sin(angle) * labelRadius
        
        return Text(dimensions[index].0)
            .font(MastersTypography.microText())
            .foregroundColor(MastersColors.graphite)
            .position(x: x, y: y)
    }
    
    private func formatColor(for name: String) -> Color {
        switch name {
        case "Scramble": return MastersColors.mastersGreen
        case "Best Ball": return MastersColors.augustaGold
        case "Match Play": return MastersColors.scoreRed
        case "Skins": return MastersColors.par
        default: return MastersColors.birdie
        }
    }
}

// MARK: - Radar Grid
struct RadarGrid: View {
    let center: CGPoint
    let radius: CGFloat
    let dimensions: Int
    
    var body: some View {
        ZStack {
            // Concentric circles
            ForEach(1...5, id: \.self) { level in
                Path { path in
                    for i in 0..<dimensions {
                        let angle = (Double(i) * 2 * .pi / Double(dimensions)) - .pi / 2
                        let r = radius * CGFloat(level) / 5
                        let x = center.x + cos(angle) * r
                        let y = center.y + sin(angle) * r
                        
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(MastersColors.pearl, lineWidth: 1)
            }
            
            // Radial lines
            ForEach(0..<dimensions, id: \.self) { i in
                let angle = (Double(i) * 2 * .pi / Double(dimensions)) - .pi / 2
                let x = center.x + cos(angle) * radius
                let y = center.y + sin(angle) * radius
                
                Path { path in
                    path.move(to: center)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                .stroke(MastersColors.pearl, lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Radar Polygon
struct RadarPolygon: View {
    let data: FormatAnalytics
    let dimensions: [KeyPath<FormatAnalytics, Double>]
    let center: CGPoint
    let radius: CGFloat
    let color: Color
    let animationProgress: Double
    
    var body: some View {
        ZStack {
            polygonFill
            polygonStroke
        }
    }
    
    private var polygonFill: some View {
        Path { path in
            buildPolygonPath(&path)
        }
        .fill(color.opacity(0.2))
    }
    
    private var polygonStroke: some View {
        Path { path in
            buildPolygonPath(&path)
        }
        .stroke(color, lineWidth: 2)
    }
    
    private func buildPolygonPath(_ path: inout Path) {
        for (index, dimension) in dimensions.enumerated() {
            let value = normalizeValue(data[keyPath: dimension])
            let angle = (Double(index) * 2 * .pi / Double(dimensions.count)) - .pi / 2
            let r = radius * CGFloat(value) * CGFloat(animationProgress)
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
    }
    
    private func normalizeValue(_ value: Double) -> Double {
        if dimensions.count > 0 && dimensions[0] == \FormatAnalytics.popularity {
            return value / 100  // Popularity is 0-100
        }
        return value / 5  // Other metrics are 1-5
    }
}

// MARK: - Bar Chart Comparison
struct BarChartComparison: View {
    let selectedFormats: Set<String>
    let analytics: [FormatAnalytics]
    let sortBy: FormatComparisonVisualizer.SortMetric
    
    var sortedAnalytics: [FormatAnalytics] {
        let filtered = analytics.filter { selectedFormats.contains($0.format.name) }
        
        switch sortBy {
        case .popularity:
            return filtered.sorted { $0.popularity > $1.popularity }
        case .skill:
            return filtered.sorted { $0.skillLevel < $1.skillLevel }
        case .social:
            return filtered.sorted { $0.socialAspect > $1.socialAspect }
        case .competitive:
            return filtered.sorted { $0.competitiveness > $1.competitiveness }
        case .pace:
            return filtered.sorted { $0.paceOfPlay > $1.paceOfPlay }
        case .fun:
            return filtered.sorted { $0.funFactor > $1.funFactor }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: MastersLayout.standardSpacing) {
            HStack {
                Text("FORMAT COMPARISON")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
                
                Spacer()
                
                Menu {
                    ForEach(FormatComparisonVisualizer.SortMetric.allCases, id: \.self) { metric in
                        Button(metric.rawValue) {
                            // Parent view handles this
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortBy.rawValue)
                            .font(MastersTypography.captionText())
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(MastersColors.mastersGreen)
                }
            }
            
            Chart(sortedAnalytics, id: \.format.id) { data in
                BarMark(
                    x: .value("Format", data.format.name),
                    y: .value("Value", metricValue(for: data))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [MastersColors.mastersGreen, MastersColors.shadowGreen],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .frame(height: 250)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel() {
                        if let format = value.as(String.self) {
                            Text(format)
                                .font(MastersTypography.microText())
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
    
    private func metricValue(for data: FormatAnalytics) -> Double {
        switch sortBy {
        case .popularity: return data.popularity
        case .skill: return data.skillLevel * 20
        case .social: return data.socialAspect * 20
        case .competitive: return data.competitiveness * 20
        case .pace: return data.paceOfPlay * 20
        case .fun: return data.funFactor * 20
        }
    }
}

// MARK: - Comparison Matrix
struct ComparisonMatrix: View {
    let selectedFormats: Set<String>
    let analytics: [FormatAnalytics]
    
    let attributes = [
        ("Players", \FormatAnalytics.averageGroupSize),
        ("Skill Level", \FormatAnalytics.skillLevel),
        ("Social", \FormatAnalytics.socialAspect),
        ("Competition", \FormatAnalytics.competitiveness),
        ("Pace", \FormatAnalytics.paceOfPlay),
        ("Strategy", \FormatAnalytics.strategy),
        ("Fun Factor", \FormatAnalytics.funFactor),
        ("Learning Curve", \FormatAnalytics.learning)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("Attribute")
                    .font(MastersTypography.captionText())
                    .foregroundColor(MastersColors.silver)
                    .frame(width: 120, alignment: .leading)
                    .padding(.horizontal, MastersLayout.smallSpacing)
                
                ForEach(analytics.filter { selectedFormats.contains($0.format.name) }, 
                        id: \.format.id) { data in
                    Text(data.format.name)
                        .font(MastersTypography.microText())
                        .foregroundColor(MastersColors.graphite)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, MastersLayout.tinySpacing)
            .background(MastersColors.fairwayMist)
            
            Divider()
            
            // Matrix rows
            ForEach(attributes, id: \.0) { attribute in
                HStack(spacing: 0) {
                    Text(attribute.0)
                        .font(MastersTypography.captionText())
                        .foregroundColor(MastersColors.graphite)
                        .frame(width: 120, alignment: .leading)
                        .padding(.horizontal, MastersLayout.smallSpacing)
                    
                    ForEach(analytics.filter { selectedFormats.contains($0.format.name) }, 
                            id: \.format.id) { data in
                        MatrixCell(
                            value: data[keyPath: attribute.1],
                            maxValue: attribute.0 == "Players" ? 4 : 5
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, MastersLayout.tinySpacing)
                
                if attribute.0 != attributes.last?.0 {
                    Divider()
                }
            }
        }
        .mastersCard()
    }
}

// MARK: - Matrix Cell
struct MatrixCell: View {
    let value: Double
    let maxValue: Double
    
    var body: some View {
        ZStack {
            if maxValue == 4 {
                // For player count
                Text(String(format: "%.0f", value))
                    .font(MastersTypography.dataLabel())
                    .foregroundColor(MastersColors.graphite)
            } else {
                // For ratings
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(Double(index) < value ? 
                                  MastersColors.mastersGreen : 
                                  MastersColors.pearl)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(height: 32)
    }
}

// MARK: - Popularity Trends
struct PopularityTrends: View {
    let analytics: [FormatAnalytics]
    @State private var timeRange = TimeRange.month
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        VStack(spacing: MastersLayout.standardSpacing) {
            HStack {
                Text("POPULARITY TRENDS")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
                
                Spacer()
                
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            Chart {
                ForEach(analytics.prefix(5), id: \.format.id) { data in
                    ForEach(generateTrendData(for: data.format.name), id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Popularity", point.value)
                        )
                        .foregroundStyle(by: .value("Format", data.format.name))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Popularity", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    formatColor(for: data.format.name).opacity(0.3),
                                    formatColor(for: data.format.name).opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
            .frame(height: 250)
            .chartLegend(position: .bottom, spacing: 10)
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
    
    private func generateTrendData(for format: String) -> [TrendPoint] {
        let basePopularity: Double = {
            switch format {
            case "Scramble": return 85
            case "Best Ball": return 75
            case "Match Play": return 65
            case "Skins": return 55
            default: return 45
            }
        }()
        
        return (0..<12).map { month in
            TrendPoint(
                date: Calendar.current.date(byAdding: .month, value: -month, to: Date())!,
                value: basePopularity + Double.random(in: -10...10)
            )
        }.reversed()
    }
    
    private func formatColor(for name: String) -> Color {
        switch name {
        case "Scramble": return MastersColors.mastersGreen
        case "Best Ball": return MastersColors.augustaGold
        case "Match Play": return MastersColors.scoreRed
        case "Skins": return MastersColors.par
        default: return MastersColors.birdie
        }
    }
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Personalized Recommendations
struct PersonalizedRecommendations: View {
    let analytics: [FormatAnalytics]
    let skillLevel: SkillLevel?
    
    @State private var userPreferences = UserPreferences()
    
    struct UserPreferences {
        var skillLevel: Double = 2.5
        var groupSize: Double = 4
        var competitiveness: Double = 3
        var pacePreference: Double = 3
        var socialPreference: Double = 4
    }
    
    var recommendations: [FormatAnalytics] {
        analytics.sorted { first, second in
            scoreFormat(first) > scoreFormat(second)
        }.prefix(3).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: MastersLayout.standardSpacing) {
            Text("PERSONALIZED RECOMMENDATIONS")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Preference Sliders
            VStack(spacing: MastersLayout.standardSpacing) {
                PreferenceSlider(
                    title: "Your Skill Level",
                    value: $userPreferences.skillLevel,
                    range: 1...5,
                    labels: ["Beginner", "Expert"]
                )
                
                PreferenceSlider(
                    title: "Preferred Group Size",
                    value: $userPreferences.groupSize,
                    range: 2...4,
                    labels: ["2 Players", "4 Players"]
                )
                
                PreferenceSlider(
                    title: "Competitiveness",
                    value: $userPreferences.competitiveness,
                    range: 1...5,
                    labels: ["Casual", "Competitive"]
                )
                
                PreferenceSlider(
                    title: "Pace of Play",
                    value: $userPreferences.pacePreference,
                    range: 1...5,
                    labels: ["Relaxed", "Fast"]
                )
            }
            .padding(MastersLayout.standardSpacing)
            .background(MastersColors.fairwayMist)
            .cornerRadius(MastersLayout.cardRadius)
            
            // Recommendations
            VStack(spacing: MastersLayout.smallSpacing) {
                Text("BEST FORMATS FOR YOU")
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(recommendations, id: \.format.id) { data in
                    RecommendationCard(
                        data: data,
                        matchScore: scoreFormat(data)
                    )
                }
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
    
    private func scoreFormat(_ data: FormatAnalytics) -> Double {
        var score: Double = 0
        
        // Skill level match (higher weight)
        let skillDiff = abs(data.skillLevel - userPreferences.skillLevel)
        score += (5 - skillDiff) * 20
        
        // Group size match
        let groupDiff = abs(data.averageGroupSize - userPreferences.groupSize)
        score += (4 - groupDiff) * 10
        
        // Competitiveness match
        let compDiff = abs(data.competitiveness - userPreferences.competitiveness)
        score += (5 - compDiff) * 15
        
        // Pace preference
        let paceDiff = abs(data.paceOfPlay - userPreferences.pacePreference)
        score += (5 - paceDiff) * 10
        
        // Social preference
        let socialDiff = abs(data.socialAspect - userPreferences.socialPreference)
        score += (5 - socialDiff) * 10
        
        // Popularity bonus
        score += data.popularity * 0.3
        
        return score
    }
}

// MARK: - Supporting Components

struct FormatChip: View {
    let name: String
    let isSelected: Bool
    let popularity: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(name)
                    .font(MastersTypography.captionText())
                    .foregroundColor(isSelected ? .white : MastersColors.graphite)
                
                // Popularity indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Rectangle()
                            .fill(Double(index) < popularity/20 ? 
                                  (isSelected ? .white : MastersColors.augustaGold) : 
                                  MastersColors.pearl)
                            .frame(width: 8, height: 2)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: MastersLayout.smallRadius)
                    .fill(isSelected ? MastersColors.mastersGreen : MastersColors.fairwayMist)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MastersLayout.smallRadius)
                    .stroke(isSelected ? Color.clear : MastersColors.pearl, lineWidth: 1)
            )
        }
    }
}

struct QuickStatsRow: View {
    let analytics: [FormatAnalytics]
    let selectedFormats: Set<String>
    
    var body: some View {
        HStack(spacing: MastersLayout.standardSpacing) {
            QuickStatCard(
                title: "Most Popular",
                value: mostPopular?.format.name ?? "—",
                subtitle: String(format: "%.0f%% play rate", mostPopular?.popularity ?? 0)
            )
            
            QuickStatCard(
                title: "Easiest to Learn",
                value: easiestToLearn?.format.name ?? "—",
                subtitle: String(format: "%.1f/5 rating", easiestToLearn?.learning ?? 0)
            )
            
            QuickStatCard(
                title: "Most Social",
                value: mostSocial?.format.name ?? "—",
                subtitle: String(format: "%.1f/5 rating", mostSocial?.socialAspect ?? 0)
            )
        }
    }
    
    private var mostPopular: FormatAnalytics? {
        analytics
            .filter { selectedFormats.contains($0.format.name) }
            .max { $0.popularity < $1.popularity }
    }
    
    private var easiestToLearn: FormatAnalytics? {
        analytics
            .filter { selectedFormats.contains($0.format.name) }
            .max { $0.learning < $1.learning }
    }
    
    private var mostSocial: FormatAnalytics? {
        analytics
            .filter { selectedFormats.contains($0.format.name) }
            .max { $0.socialAspect < $1.socialAspect }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            Text(value)
                .font(MastersTypography.dataLabel())
                .foregroundColor(MastersColors.mastersGreen)
            
            Text(subtitle)
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.fog)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MastersLayout.smallSpacing)
        .background(MastersColors.fairwayMist)
        .cornerRadius(MastersLayout.smallRadius)
    }
}

struct DemographicsChart: View {
    let analytics: [FormatAnalytics]
    let selectedFormats: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
            Text("POPULARITY BY AGE GROUP")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            Chart {
                ForEach(AgeGroup.allCases, id: \.self) { ageGroup in
                    ForEach(analytics.filter { selectedFormats.contains($0.format.name) }, 
                            id: \.format.id) { data in
                        BarMark(
                            x: .value("Age Group", ageGroup.rawValue),
                            y: .value("Preference", data.ageGroupPreference[ageGroup] ?? 0),
                            width: .ratio(0.8)
                        )
                        .foregroundStyle(by: .value("Format", data.format.name))
                        .position(by: .value("Format", data.format.name))
                    }
                }
            }
            .frame(height: 200)
            .chartLegend(position: .bottom)
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
}

struct SkillDistribution: View {
    let analytics: [FormatAnalytics]
    let selectedFormats: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: MastersLayout.smallSpacing) {
            Text("SKILL LEVEL PREFERENCES")
                .font(MastersTypography.microText())
                .foregroundColor(MastersColors.silver)
            
            ForEach(analytics.filter { selectedFormats.contains($0.format.name) }, 
                    id: \.format.id) { data in
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.format.name)
                        .font(MastersTypography.captionText())
                        .foregroundColor(MastersColors.graphite)
                    
                    HStack(spacing: 2) {
                        ForEach(SkillLevel.allCases, id: \.self) { skill in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            MastersColors.mastersGreen.opacity(data.skillPreference[skill] ?? 0),
                                            MastersColors.mastersGreen.opacity((data.skillPreference[skill] ?? 0) * 0.3)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 40)
                                .overlay(
                                    Text(skill.rawValue)
                                        .font(MastersTypography.microText())
                                        .foregroundColor(.white)
                                        .rotationEffect(.degrees(-45))
                                )
                        }
                    }
                }
            }
        }
        .padding(MastersLayout.standardSpacing)
        .mastersCard()
    }
}

struct PreferenceSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let labels: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(MastersTypography.captionText())
                .foregroundColor(MastersColors.graphite)
            
            HStack {
                Text(labels[0])
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
                
                Slider(value: $value, in: range)
                    .accentColor(MastersColors.mastersGreen)
                
                Text(labels[1])
                    .font(MastersTypography.microText())
                    .foregroundColor(MastersColors.silver)
            }
        }
    }
}

struct RecommendationCard: View {
    let data: FormatAnalytics
    let matchScore: Double
    
    var matchPercentage: Int {
        min(100, Int(matchScore / 2))
    }
    
    var body: some View {
        HStack(spacing: MastersLayout.standardSpacing) {
            // Match percentage
            ZStack {
                Circle()
                    .stroke(MastersColors.pearl, lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat(matchPercentage) / 100)
                    .stroke(MastersColors.mastersGreen, lineWidth: 3)
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(matchPercentage)%")
                    .font(MastersTypography.captionText())
                    .fontWeight(.bold)
                    .foregroundColor(MastersColors.mastersGreen)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(data.format.name)
                    .font(MastersTypography.dataLabel())
                    .foregroundColor(MastersColors.graphite)
                
                Text(data.format.description.prefix(50) + "...")
                    .font(MastersTypography.captionText())
                    .foregroundColor(MastersColors.silver)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(MastersColors.fog)
        }
        .padding(MastersLayout.smallSpacing)
        .background(MastersColors.fairwayMist)
        .cornerRadius(MastersLayout.smallRadius)
    }
}

// MARK: - Analytics Provider
struct FormatAnalyticsProvider {
    static func generateAnalytics() -> [FormatAnalytics] {
        [
            FormatAnalytics(
                format: GolfFormat.allFormats[0], // Scramble
                popularity: 92,
                skillLevel: 2.0,
                socialAspect: 5.0,
                competitiveness: 3.0,
                paceOfPlay: 4.5,
                strategy: 3.5,
                funFactor: 4.8,
                learning: 4.5,
                weeklyPlays: 450,
                averageGroupSize: 4,
                preferredByHandicap: 10...25,
                tournamentUsage: 35,
                ageGroupPreference: [.youth: 0.7, .young: 0.9, .middle: 0.8, .senior: 0.6],
                skillPreference: [.beginner: 0.9, .intermediate: 0.8, .advanced: 0.5, .expert: 0.3]
            ),
            FormatAnalytics(
                format: GolfFormat.allFormats[1], // Best Ball
                popularity: 85,
                skillLevel: 2.5,
                socialAspect: 4.0,
                competitiveness: 3.5,
                paceOfPlay: 4.0,
                strategy: 3.0,
                funFactor: 4.2,
                learning: 4.0,
                weeklyPlays: 380,
                averageGroupSize: 4,
                preferredByHandicap: 5...20,
                tournamentUsage: 25,
                ageGroupPreference: [.youth: 0.8, .young: 0.85, .middle: 0.7, .senior: 0.5],
                skillPreference: [.beginner: 0.7, .intermediate: 0.9, .advanced: 0.7, .expert: 0.5]
            ),
            FormatAnalytics(
                format: GolfFormat.allFormats[2], // Match Play
                popularity: 75,
                skillLevel: 3.5,
                socialAspect: 3.5,
                competitiveness: 5.0,
                paceOfPlay: 3.5,
                strategy: 4.5,
                funFactor: 4.0,
                learning: 3.0,
                weeklyPlays: 280,
                averageGroupSize: 2,
                preferredByHandicap: 0...15,
                tournamentUsage: 20,
                ageGroupPreference: [.youth: 0.6, .young: 0.7, .middle: 0.8, .senior: 0.7],
                skillPreference: [.beginner: 0.3, .intermediate: 0.6, .advanced: 0.9, .expert: 0.95]
            ),
            FormatAnalytics(
                format: GolfFormat.allFormats[3], // Skins
                popularity: 68,
                skillLevel: 3.0,
                socialAspect: 4.5,
                competitiveness: 4.5,
                paceOfPlay: 3.8,
                strategy: 3.8,
                funFactor: 4.5,
                learning: 3.5,
                weeklyPlays: 220,
                averageGroupSize: 4,
                preferredByHandicap: 5...18,
                tournamentUsage: 15,
                ageGroupPreference: [.youth: 0.75, .young: 0.8, .middle: 0.65, .senior: 0.5],
                skillPreference: [.beginner: 0.4, .intermediate: 0.7, .advanced: 0.8, .expert: 0.7]
            ),
            // Add more format analytics as needed
        ] + GolfFormat.allFormats.dropFirst(4).map { format in
            FormatAnalytics(
                format: format,
                popularity: Double.random(in: 30...65),
                skillLevel: Double.random(in: 2...4),
                socialAspect: Double.random(in: 2...5),
                competitiveness: Double.random(in: 2...5),
                paceOfPlay: Double.random(in: 2...4.5),
                strategy: Double.random(in: 2...4.5),
                funFactor: Double.random(in: 3...4.5),
                learning: Double.random(in: 2...4),
                weeklyPlays: Int.random(in: 50...200),
                averageGroupSize: Double.random(in: 2...4),
                preferredByHandicap: 10...20,
                tournamentUsage: Double.random(in: 5...15),
                ageGroupPreference: Dictionary(uniqueKeysWithValues: 
                    AgeGroup.allCases.map { ($0, Double.random(in: 0.3...0.8)) }
                ),
                skillPreference: Dictionary(uniqueKeysWithValues:
                    SkillLevel.allCases.map { ($0, Double.random(in: 0.3...0.8)) }
                )
            )
        }
    }
}

#Preview {
    FormatComparisonVisualizer()
}