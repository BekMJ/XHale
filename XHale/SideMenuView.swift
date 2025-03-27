import SwiftUI
import CoreBluetooth

// MARK: - SideMenuView
struct SideMenuView: View {
    
    @Binding var isShowingMenu: Bool
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
                .simultaneousGesture(
                    TapGesture().onEnded {
                        isShowingMenu = false
                    }
                )
                
               
                // In SideMenuView or HomeView:
                NavigationLink(destination: SensorDataView()) {
                    Label("Dataview", systemImage: "speedometer")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .simultaneousGesture(
                    TapGesture().onEnded {
                        isShowingMenu = false
                    }
                )
                
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .simultaneousGesture(
                    TapGesture().onEnded {
                        isShowingMenu = false
                    }
                )

                


                
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.top, 20)
        }
    }
}
