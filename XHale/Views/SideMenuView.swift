import SwiftUI
import CoreBluetooth
import FirebaseAuth

// MARK: - SideMenuView
struct SideMenuView: View {
    @Binding var isShowingMenu: Bool

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
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
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

                // Log Out Button at bottom
                Button {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                } label: {
                    Label("Log Out", systemImage: "arrow.backward.square")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                .padding(.leading, 20)
                .simultaneousGesture(
                    TapGesture().onEnded { isShowingMenu = false }
                )
                .padding(.bottom, 30)
            }
            .padding(.leading, 20)
            .padding(.top, 20)
        }
    }
}
