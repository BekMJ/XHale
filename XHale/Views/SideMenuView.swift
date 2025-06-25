import SwiftUI
import CoreBluetooth
import FirebaseAuth

// MARK: - SideMenuView
struct SideMenuView: View {
    @Binding var isShowingMenu: Bool
    @EnvironmentObject var session: SessionStore

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.purple, Color.blue]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 32) {
                // Title or Logo at the top
                Text("Menu")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityLabel("Main menu")
                    .padding(.top, 60)

                // Navigation Links
                NavigationLink(destination: HomeView()) {
                    Label("Home", systemImage: "house.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .simultaneousGesture(
                    TapGesture().onEnded { isShowingMenu = false }
                )

                NavigationLink(destination: InstructionView()) {
                    Label("Instructions", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .simultaneousGesture(
                    TapGesture().onEnded { isShowingMenu = false }
                )

                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .simultaneousGesture(
                    TapGesture().onEnded { isShowingMenu = false }
                )

                Spacer()
                
                // Logout Button
                Button(action: {
                    session.signOut()
                    isShowingMenu = false
                }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 20)
            .padding(.top, 20)
        }
    }
}
