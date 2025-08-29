import SwiftUI

struct QuickStartView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFormat: GolfFormat?
    @State private var playerCount = 4
    @State private var showGameSetup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.green.opacity(0.1), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Quick Start")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Start a new game in seconds")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Player Count Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Number of Players")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(1...4, id: \.self) { count in
                                PlayerCountButton(
                                    count: count,
                                    isSelected: playerCount == count,
                                    action: {
                                        playerCount = count
                                        appState.hapticManager.impact(style: .light)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Popular Formats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Formats")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(appState.availableFormats.prefix(5)) { format in
                                    QuickFormatCard(
                                        format: format,
                                        isSelected: selectedFormat?.id == format.id,
                                        action: {
                                            selectedFormat = format
                                            appState.hapticManager.impact(style: .light)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Start Button
                    Button(action: startGame) {
                        HStack {
                            Image(systemName: "flag.checkered")
                            Text("Start Game")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedFormat != nil ? Color.green : Color.gray
                        )
                        .cornerRadius(12)
                    }
                    .disabled(selectedFormat == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Play")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showGameSetup) {
            if let format = selectedFormat {
                GameSetupView(format: format)
            }
        }
    }
    
    private func startGame() {
        guard let format = selectedFormat else { return }
        
        // Create players
        let players = (1...playerCount).map { index in
            Player.guest(
                name: "Player \(index)",
                color: Player.PlayerColor.allCases[index - 1]
            )
        }
        
        // Start game
        appState.startNewGame(format: format, players: players)
        appState.hapticManager.notification(type: .success)
    }
}

struct PlayerCountButton: View {
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "\(count).circle.fill")
                    .font(.title2)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.green : Color(.secondarySystemBackground)
            )
            .cornerRadius(10)
        }
    }
}

struct QuickFormatCard: View {
    let format: GolfFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .green)
                
                Text(format.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(format.difficulty)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(width: 100, height: 100)
            .background(
                isSelected ? Color.green : Color(.secondarySystemBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
}