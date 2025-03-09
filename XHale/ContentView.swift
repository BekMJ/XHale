import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
               
            
                
                // 2) Scanning status
                Text(bleManager.isScanning ? "Scanning..." : "Not Scanning")
                    .font(.title2)
                    .foregroundColor(.white)
                
                // 3) Radar animation only if scanning (if you added RadarScanView)
                if bleManager.isScanning {
                    RadarScanView()
                        .frame(width: 200, height: 200)
                        .padding(.bottom, 8)
                }
                
                // 4) Scan/Stop button
                Button(action: {
                    if bleManager.isScanning {
                        bleManager.stopScanning()
                    } else {
                        bleManager.startScanning()
                    }
                }) {
                    Text(bleManager.isScanning ? "Stop Scan" : "Start Scan")
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                
                // 5) Device list or friendly message
                if bleManager.discoveredPeripherals.isEmpty && !bleManager.isScanning {
                    Text("No devices found.\nTap 'Start Scan' to discover devices.")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                } else {
                    List(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                        Button(action: {
                            bleManager.connect(peripheral)
                        }) {
                            HStack {
                                Text(peripheral.name ?? "Unknown Device")
                                    .font(.headline)
                                
                                Spacer()
                                if bleManager.connectedPeripheral == peripheral {
                                    Text("Connected")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .cornerRadius(8)
                }
                
                // 6) Connected device info
                if let connectedPeripheral = bleManager.connectedPeripheral {
                    Text("Connected to \(connectedPeripheral.name ?? "Unknown")")
                        .foregroundColor(.white)
                    
                    Button("Disconnect") {
                        bleManager.disconnect()
                    }
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                }
            }
            .padding()
        }
        .navigationTitle("Scanner")
    }
}
