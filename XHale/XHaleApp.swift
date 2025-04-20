import SwiftUI
import Firebase

@main
struct XHaleApp: App {
    init() { FirebaseApp.configure() }

    @AppStorage("tutorialEnabled") private var tutorialEnabled = true
    @StateObject private var tutorial       = TutorialManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var bleManager     = BLEManager()
    @State private   var anchors: [String: CGRect] = [:]

    var body: some Scene {
        WindowGroup {
            // ① Wrap everything in NavigationView
            NavigationView {
                ZStack {
                    // ② This view and all its children can now see bleManager & networkMonitor
                    AuthView()
                        .onPreferenceChange(TutorialAnchorKey.self) { anchors = $0 }

                    if tutorialEnabled && tutorial.isActive {
                        TutorialOverlay(anchors: anchors)
                            .environmentObject(tutorial)
                    }
                }
                .navigationBarHidden(true)
            }
            // ③ Provide your environment objects here
            .environmentObject(networkMonitor)
            .environmentObject(bleManager)
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                if tutorialEnabled {
                    tutorial.currentIndex = 0
                    tutorial.isActive     = true
                }
            }
            .onChange(of: tutorialEnabled) { enabled in
                if enabled {
                    tutorial.currentIndex = 0
                    tutorial.isActive     = true
                }
            }
        }
    }
}
