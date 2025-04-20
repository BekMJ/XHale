import Foundation
import Network
import Combine
import FirebaseFirestore  // ← add

final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let connected = (path.status == .satisfied)
                self?.isConnected = connected
                
                let db = Firestore.firestore()
                if connected {
                    db.enableNetwork { error in
                        if let e = error {
                            print("Firestore enableNetwork failed:", e)
                        }
                    }
                } else {
                    db.disableNetwork { error in
                        if let e = error {
                            print("Firestore disableNetwork failed:", e)
                        }
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
