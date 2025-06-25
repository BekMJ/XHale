import SwiftUI
import CoreBluetooth
import UIKit

struct BluetoothPermissionModal: View {
    let state: CBManagerState
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
            
            Text("Bluetooth Required")
                .font(.title2)
                .bold()
            
            Text("This app uses Bluetooth to discover and connect to the Carbon Monoxide sensor so you can receive real-time carbon monoxide (CO) and temperature readings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            if state == .unauthorized {
                Text("Bluetooth access is currently denied. Please enable Bluetooth permissions for this app in Settings.")
                    .font(.body)
                    .foregroundColor(.red)
                
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Open Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            } else if state == .poweredOff {
                Text("Bluetooth is currently turned off. Please turn on Bluetooth in Control Center or Settings to use this app.")
                    .font(.body)
                    .foregroundColor(.orange)
            }
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
} 