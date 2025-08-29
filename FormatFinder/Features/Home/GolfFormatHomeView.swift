import SwiftUI

struct GolfFormatHomeView: View {
    @State private var animateContent = false
    @State private var selectedSection: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // App Title Section
                        headerSection
                            .padding(.top, 20)
                        
                        // Introduction Section
                        introductionSection
                        
                        // How to Use Section
                        howToUseSection
                        
                        // Format Types Explanation
                        formatTypesSection
                        
                        // Casual vs Competitive
                        playStyleSection
                        
                        // Action Buttons
                        actionButtonsSection
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateContent = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.golf")
                .font(.system(size: 48))
                .foregroundColor(MastersColors.mastersGreen)
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
            
            Text("Format Finder")
                .font(.system(size: 36, weight: .thin, design: .serif))
                .foregroundColor(.primary)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
            
            Text("Elevate Your Golf Experience")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.secondary)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Introduction Section
    
    var introductionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Welcome", icon: "hand.wave")
            
            Text("Format Finder transforms your golf rounds with exciting game formats that add strategy, competition, and fun to every hole.")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Whether you're playing casually with friends or in a competitive setting, discover the perfect format for your group.")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.secondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
    }
    
    // MARK: - How to Use Section
    
    var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "How to Use", icon: "questionmark.circle")
            
            VStack(alignment: .leading, spacing: 12) {
                StepRow(number: "1", text: "Browse available formats or use filters to find the perfect match")
                StepRow(number: "2", text: "Select a format to view detailed rules and scoring")
                StepRow(number: "3", text: "Start playing with automatic scoring and live leaderboards")
                StepRow(number: "4", text: "Track statistics and share results with your group")
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateContent)
    }
    
    // MARK: - Format Types Section
    
    var formatTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Format Categories", icon: "square.grid.2x2")
            
            VStack(spacing: 12) {
                FormatTypeCard(
                    icon: "person.fill",
                    title: "Individual",
                    description: "Stroke play, Stableford, and other solo competitions"
                )
                
                FormatTypeCard(
                    icon: "person.2.fill",
                    title: "Team",
                    description: "Best ball, scrambles, and partner formats"
                )
                
                FormatTypeCard(
                    icon: "flag.fill",
                    title: "Match Play",
                    description: "Hole-by-hole competitions and skins games"
                )
                
                FormatTypeCard(
                    icon: "star.fill",
                    title: "Points-Based",
                    description: "Accumulate points through various achievements"
                )
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
    }
    
    // MARK: - Play Style Section
    
    var playStyleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Play Styles", icon: "slider.horizontal.3")
            
            HStack(spacing: 16) {
                PlayStyleCard(
                    title: "Casual",
                    icon: "sun.max.fill",
                    color: Color.orange,
                    points: [
                        "Focus on fun and camaraderie",
                        "Flexible rules and scoring",
                        "Great for mixed skill levels",
                        "Emphasis on enjoyment"
                    ]
                )
                
                PlayStyleCard(
                    title: "Competitive",
                    icon: "trophy.fill",
                    color: MastersColors.mastersGreen,
                    points: [
                        "Strict rules and scoring",
                        "Tournament-style formats",
                        "Handicap integration",
                        "Official leaderboards"
                    ]
                )
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.7), value: animateContent)
    }
    
    // MARK: - Action Buttons Section
    
    var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical, 8)
            
            Text("Ready to play?")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                NavigationLink(destination: FormatsTabView()) {
                    ActionButton(
                        title: "Find Format",
                        subtitle: "Browse all formats",
                        icon: "magnifyingglass",
                        color: MastersColors.mastersGreen
                    )
                }
                
                NavigationLink(destination: PlayTabView()) {
                    ActionButton(
                        title: "Play Format",
                        subtitle: "Start a round",
                        icon: "play.fill",
                        color: Color.blue
                    )
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .scaleEffect(animateContent ? 1 : 0.9)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: animateContent)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(MastersColors.mastersGreen)
            
            Text(title)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct StepRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(MastersColors.mastersGreen)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct FormatTypeCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(MastersColors.mastersGreen)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PlayStyleCard: View {
    let title: String
    let icon: String
    let color: Color
    let points: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 6) {
                        Circle()
                            .fill(color.opacity(0.3))
                            .frame(width: 4, height: 4)
                            .offset(y: 6)
                        
                        Text(point)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color)
        .cornerRadius(16)
    }
}

// MARK: - Placeholder Views for Navigation

struct FormatsTabView: View {
    var body: some View {
        // This will be replaced with the actual Formats tab content
        AnimatedGolfFormatsView()
    }
}

struct PlayTabView: View {
    var body: some View {
        // This will be replaced with the actual Play tab content
        Text("Play Format View")
            .navigationTitle("Play")
    }
}