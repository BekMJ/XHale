import SwiftUI
import CoreBluetooth

// MARK: - SideMenuView
struct SideMenuView: View {
    var body: some View {
        ZStack {
            // Background (could be gradient, solid color, etc.)
            LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.blue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 32) {
                // Title or Logo at the top
                Text("Menu")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                // Navigation Links or Buttons
                NavigationLink(destination: HomeView()) {
                    Label("Home", systemImage: "house.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // 1) Instructions
                NavigationLink(destination: InstructionView()) {
                    Label("Instructions", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // 2) Breath Sample
                NavigationLink(destination: BreathSampleView()) {
                    Label("Breath Sample", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.top, 20)
        }
    }
}
