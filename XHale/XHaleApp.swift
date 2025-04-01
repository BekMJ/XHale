import SwiftUI
import Firebase

@main
struct XHaleApp: App {
    @StateObject private var bleManager = BLEManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                AuthView()  // Start with the authentication view
            }
            .environmentObject(bleManager)
        }
    }
}
