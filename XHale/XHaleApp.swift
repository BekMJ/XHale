import SwiftUI
import Firebase

@main
struct XHaleApp: App {
    // Initialize Firebase
    init() {
        FirebaseApp.configure()
    }

    // Persist whether the inline tutorial (coach marks) should run
    @AppStorage("tutorialEnabled") private var tutorialEnabled = true

    // Shared state objects
    @StateObject private var tutorial       = TutorialManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var bleManager     = BLEManager()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                AuthView()

            }
            .environmentObject(networkMonitor)
            .environmentObject(bleManager)
            .environmentObject(tutorial)
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                // Reset or disable tutorial based on user setting
                tutorial.isActive = tutorialEnabled
                if tutorialEnabled {
                    tutorial.currentIndex = 0
                }
            }
            .onChange(of: tutorialEnabled) { enabled in
                tutorial.isActive = enabled
                if enabled {
                    tutorial.currentIndex = 0
                }
            }
        }
    }
}
