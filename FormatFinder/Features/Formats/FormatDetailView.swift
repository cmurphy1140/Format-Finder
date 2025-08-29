import SwiftUI

struct FormatDetailView: View {
    let format: GolfFormat
    @EnvironmentObject var appState: AppState
    @State private var showGameSetup = false
    
    var isFavorite: Bool {
        appState.favoriteFormats.contains(format.id)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Card
                VStack(spacing: 16) {
                    Image(systemName: format.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text(format.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(format.shortDescription)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        InfoPill(icon: "person.2", text: format.playerRange)
                        InfoPill(icon: "clock", text: format.duration)
                        InfoPill(icon: "speedometer", text: format.difficulty)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .padding(.horizontal)
                
                // How to Play Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Play")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(format.rules.enumerated()), id: \.offset) { index, rule in
                            RuleRow(number: index + 1, text: rule)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Tags Section
                if !format.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(format.tags, id: \.self) { tag in
                                    TagChip(text: tag)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showGameSetup = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Game")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        appState.toggleFavoriteFormat(format)
                    }) {
                        HStack {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                            Text(isFavorite ? "Remove from Favorites" : "Add to Favorites")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(isFavorite ? .red : .primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showGameSetup) {
            GameSetupView(format: format)
        }
    }
}

struct InfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.3))
        .cornerRadius(20)
        .foregroundColor(.white)
    }
}

struct RuleRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TagChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.1))
            .foregroundColor(.green)
            .cornerRadius(20)
    }
}