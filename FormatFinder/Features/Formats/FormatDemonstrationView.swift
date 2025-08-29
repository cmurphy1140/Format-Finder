import SwiftUI

// MARK: - Format Demonstration View
struct FormatDemonstrationView: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    @State private var showBroadcastDemo = false
    @State private var selectedDemoType: DemoType = .broadcast
    
    enum DemoType: String, CaseIterable {
        case broadcast = "Broadcast Style"
        case interactive = "Interactive"
        case simple = "Simple Guide"
        
        var icon: String {
            switch self {
            case .broadcast: return "tv.fill"
            case .interactive: return "hand.tap.fill"
            case .simple: return "book.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Masters-inspired background
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.3, blue: 0.15).opacity(0.1),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Format header
                    FormatHeaderCard(format: format)
                        .padding(.horizontal)
                    
                    // Demo type selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Demonstration Style")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(DemoType.allCases, id: \.self) { type in
                                    DemoTypeCard(
                                        type: type,
                                        isSelected: selectedDemoType == type,
                                        action: {
                                            withAnimation(.spring()) {
                                                selectedDemoType = type
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Start demonstration button
                    Button(action: startDemonstration) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                            
                            Text("Start Demonstration")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.5, blue: 0.25),
                                    Color(red: 0.0, green: 0.4, blue: 0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    
                    // Key features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What You'll Learn")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            FeatureRow(icon: "flag.fill", text: "Basic rules and scoring")
                            FeatureRow(icon: "person.2.fill", text: "Player positions and strategy")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Win conditions and variations")
                            FeatureRow(icon: "lightbulb.fill", text: "Pro tips and best practices")
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Format Demonstration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showBroadcastDemo) {
            if format.name.lowercased().contains("match") {
                BroadcastMatchPlayDemo()
            } else {
                // For other formats, show a placeholder or different demo
                GenericFormatDemo(format: format)
            }
        }
    }
    
    private func startDemonstration() {
        switch selectedDemoType {
        case .broadcast:
            showBroadcastDemo = true
        case .interactive:
            // TODO: Show interactive demo
            showBroadcastDemo = true // For now, show broadcast
        case .simple:
            // TODO: Show simple guide
            showBroadcastDemo = true // For now, show broadcast
        }
    }
}

// MARK: - Format Header Card
struct FormatHeaderCard: View {
    let format: GolfFormat
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: getFormatIcon(format.name))
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Title and description
            VStack(spacing: 8) {
                Text(format.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(format.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatPill(icon: "person.2", value: format.players)
                StatPill(icon: "speedometer", value: format.difficulty)
                StatPill(icon: "clock", value: format.pace)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
    }
    
    private func getFormatIcon(_ name: String) -> String {
        switch name.lowercased() {
        case let n where n.contains("match"):
            return "person.2.square.stack"
        case let n where n.contains("scramble"):
            return "arrow.triangle.merge"
        case let n where n.contains("best ball"):
            return "star.circle.fill"
        case let n where n.contains("skins"):
            return "dollarsign.circle.fill"
        case let n where n.contains("stableford"):
            return "chart.line.uptrend.xyaxis"
        default:
            return "flag.fill"
        }
    }
}

// MARK: - Demo Type Card
struct DemoTypeCard: View {
    let type: FormatDemonstrationView.DemoType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(type.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .frame(width: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Generic Format Demo (Placeholder)
struct GenericFormatDemo: View {
    let format: GolfFormat
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.3, blue: 0.15),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
                
                Spacer()
                
                // Format icon and name
                VStack(spacing: 20) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(format.name)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Interactive demonstration coming soon")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Basic info
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(label: "Players", value: format.players)
                    InfoRow(label: "Difficulty", value: format.difficulty)
                    InfoRow(label: "Pace", value: format.pace)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}