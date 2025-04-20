import FirebaseAuth
import SwiftUI

class SessionStore: ObservableObject {
    @Published var currentUser: User?
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        listen()
    }
    
    func listen() {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.currentUser = user
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
