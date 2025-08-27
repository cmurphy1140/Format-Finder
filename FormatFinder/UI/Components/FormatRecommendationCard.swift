import SwiftUI

// MARK: - Format Recommendation Card
struct FormatRecommendationCard: View {
    let recommendation: FormatRecommendationEngine.FormatRecommendation
    let onSelect: () -> Void
    
    @State private var isExpanded = false
    @State private var isPressed = false
    
    private var confidenceColor: Color {
        if recommendation.confidence >= 0.8 {
            return .green
        } else if recommendation.confidence >= 0.6 {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var confidenceText: String {
        if recommendation.confidence >= 0.8 {
            return "Highly Recommended"
        } else if recommendation.confidence >= 0.6 {
            return "Good Match"
        } else {
            return "Alternative Option"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Card Content
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with confidence indicator
                    HStack {
                        // Format Icon and Name
                        HStack(spacing: 12) {
                            Image(systemName: recommendation.format.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(recommendation.format.color)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recommendation.format.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(confidenceText)
                                    .font(.caption)
                                    .foregroundColor(confidenceColor)
                            }
                        }
                        
                        Spacer()
                        
                        // Confidence Meter
                        ConfidenceMeter(confidence: recommendation.confidence)
                    }
                    
                    // Reason
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .frame(width: 20, height: 20)
                            .background(Color.yellow.opacity(0.2))
                            .clipShape(Circle())
                        
                        Text(recommendation.reason)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Expand/Collapse Indicator
                    HStack {
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    // Pros
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why this format works")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        ForEach(recommendation.pros, id: \.self) { pro in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Text(pro)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Considerations
                    if let considerations = recommendation.considerations {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Consider")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            ForEach(considerations, id: \.self) { consideration in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text(consideration)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Select Button
                    Button(action: onSelect) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Select \(recommendation.format.name)")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(recommendation.format.color)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            recommendation.isHighlyRecommended ? confidenceColor.opacity(0.3) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .shadow(
            color: recommendation.isHighlyRecommended ? confidenceColor.opacity(0.2) : Color.black.opacity(0.1),
            radius: recommendation.isHighlyRecommended ? 8 : 4,
            y: 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Confidence Meter
struct ConfidenceMeter: View {
    let confidence: Double
    
    private var fillColor: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(Double(index) < confidence * 5 ? fillColor : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 20 - Double(index) * 2)
                    .cornerRadius(2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - Format Recommendations Section
struct FormatRecommendationsSection: View {
    let players: [Player]
    @Binding var selectedFormat: GolfFormat?
    @State private var recommendations: [FormatRecommendationEngine.FormatRecommendation] = []
    @State private var showAllRecommendations = false
    
    var topRecommendations: [FormatRecommendationEngine.FormatRecommendation] {
        Array(recommendations.prefix(showAllRecommendations ? recommendations.count : 3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended Formats")
                        .font(.headline)
                    
                    Text("Based on your group of \(players.count) players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.yellow.opacity(0.1),
                        Color.orange.opacity(0.05)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            
            // Recommendation Cards
            ForEach(topRecommendations) { recommendation in
                FormatRecommendationCard(
                    recommendation: recommendation,
                    onSelect: {
                        selectedFormat = recommendation.format
                    }
                )
            }
            
            // Show More/Less Button
            if recommendations.count > 3 {
                Button(action: {
                    withAnimation {
                        showAllRecommendations.toggle()
                    }
                }) {
                    HStack {
                        Text(showAllRecommendations ? "Show Less" : "Show More Formats")
                            .font(.subheadline)
                        Image(systemName: showAllRecommendations ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            generateRecommendations()
        }
        .onChange(of: players) { _ in
            generateRecommendations()
        }
    }
    
    private func generateRecommendations() {
        recommendations = FormatRecommendationEngine.recommendFormats(
            for: players,
            preferences: FormatPreferences()
        )
    }
}

// MARK: - Enhanced Search Bar
struct EnhancedSearchBar: View {
    @Binding var searchText: String
    @StateObject private var searchService = SearchService()
    @State private var isFocused = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search formats or try 'team', 'betting', 'beginner'...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        if !searchText.isEmpty {
                            searchService.addRecentSearch(searchText)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Recent Searches
            if searchText.isEmpty && !searchService.recentSearches.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text("Recent:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(searchService.recentSearches, id: \.self) { recent in
                            Button(action: {
                                searchText = recent
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption2)
                                    Text(recent)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(15)
                            }
                        }
                        
                        Button(action: {
                            searchService.clearRecentSearches()
                        }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // Search Suggestions
            if !searchText.isEmpty {
                let suggestions = searchService.getSuggestions(for: searchText)
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                searchText = suggestion
                                searchService.addRecentSearch(suggestion)
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(suggestion)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
}