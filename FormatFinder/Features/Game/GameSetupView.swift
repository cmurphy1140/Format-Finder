import SwiftUI

struct GameSetupView: View {
    let format: GolfFormat
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var players: [Player] = []
    @State private var courseSelection = "Default Course"
    @State private var teeBox = "White"
    @State private var showAddPlayer = false
    @State private var newPlayerName = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Format Info
                Section {
                    HStack {
                        Image(systemName: format.icon)
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text(format.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(format.shortDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Players Section
                Section("Players (\(players.count)/\(getMaxPlayers()))") {
                    ForEach(players) { player in
                        PlayerRow(player: player, onRemove: {
                            removePlayer(player)
                        })
                    }
                    
                    if players.count < getMaxPlayers() {
                        Button(action: { showAddPlayer = true }) {
                            Label("Add Player", systemImage: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Course Settings
                Section("Course Settings") {
                    Picker("Course", selection: $courseSelection) {
                        Text("Default Course").tag("Default Course")
                        Text("Custom Course").tag("Custom Course")
                    }
                    
                    Picker("Tee Box", selection: $teeBox) {
                        Text("Black").tag("Black")
                        Text("Blue").tag("Blue")
                        Text("White").tag("White")
                        Text("Red").tag("Red")
                    }
                }
                
                // Game Options
                Section("Game Options") {
                    Toggle("Track Statistics", isOn: .constant(true))
                    Toggle("Enable GPS", isOn: .constant(false))
                    Toggle("Weather Updates", isOn: .constant(true))
                }
            }
            .navigationTitle("Game Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        startGame()
                    }
                    .fontWeight(.semibold)
                    .disabled(players.isEmpty)
                }
            }
            .sheet(isPresented: $showAddPlayer) {
                AddPlayerSheet(
                    playerName: $newPlayerName,
                    onAdd: { name in
                        addPlayer(name: name)
                        showAddPlayer = false
                    }
                )
            }
            .onAppear {
                setupDefaultPlayers()
            }
        }
    }
    
    private func getMaxPlayers() -> Int {
        // Parse player range from format
        if let lastChar = format.playerRange.last,
           let max = Int(String(lastChar)) {
            return max
        }
        return 4
    }
    
    private func setupDefaultPlayers() {
        if let user = appState.currentUser {
            players.append(
                Player(
                    id: user.id,
                    name: user.name,
                    handicap: user.handicap,
                    color: .blue,
                    isGuest: false
                )
            )
        }
    }
    
    private func addPlayer(name: String) {
        let color = Player.PlayerColor.allCases[players.count % Player.PlayerColor.allCases.count]
        let player = Player.guest(name: name, color: color)
        players.append(player)
    }
    
    private func removePlayer(_ player: Player) {
        players.removeAll { $0.id == player.id }
    }
    
    private func startGame() {
        appState.startNewGame(format: format, players: players)
        dismiss()
    }
}

struct PlayerRow: View {
    let player: Player
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(player.color.color)
                .frame(width: 30, height: 30)
                .overlay(
                    Text(String(player.name.prefix(1)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let handicap = player.handicap {
                    Text("Handicap: \(handicap)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if player.isGuest {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct AddPlayerSheet: View {
    @Binding var playerName: String
    let onAdd: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Player Details") {
                    TextField("Player Name", text: $playerName)
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(playerName)
                        playerName = ""
                    }
                    .disabled(playerName.isEmpty)
                }
            }
        }
    }
}