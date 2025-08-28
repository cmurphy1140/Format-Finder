import SwiftUI

struct GameConfigurationView: View {
    @Binding var configuration: GameConfiguration
    let onStart: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Game Configuration")
                    .font(.largeTitle.bold())
                    .foregroundColor(AppColors.darkGreen)
                
                if let format = configuration.selectedFormat {
                    Text(format.name)
                        .font(.title2)
                        .foregroundColor(AppColors.primaryGreen)
                }
                
                // Number of holes selector
                VStack(alignment: .leading) {
                    Text("Number of Holes")
                        .font(.headline)
                        .foregroundColor(AppColors.darkGreen)
                    
                    Picker("Holes", selection: $configuration.numberOfHoles) {
                        Text("9 Holes").tag(9)
                        Text("18 Holes").tag(18)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                
                Spacer()
                
                Button(action: onStart) {
                    Text("Start Game")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primaryGreen)
                        .cornerRadius(15)
                }
                .padding()
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
}