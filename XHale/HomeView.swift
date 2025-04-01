//
//  HomeView.swift
//  XHale
//
//  Created by NPL-Weng on 3/9/25.
//

import SwiftUI
import CoreBluetooth

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    
    // Controls whether the side menu is visible
    @State private var isShowingMenu = false
    
    // Width of the side menu
    private let menuWidth: CGFloat = 250
    
    var body: some View {
        // ZStack so we can layer the menu behind the main content
        ZStack(alignment: .leading) {
            
            // 1) The side menu (always present, but usually hidden off-screen)
            SideMenuView(isShowingMenu: $isShowingMenu)
                .frame(width: menuWidth)
                .offset(x: isShowingMenu ? 0 : -menuWidth) // slide in/out
                .animation(.easeInOut, value: isShowingMenu)
            
            // 2) The main scanning content
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Top bar with hamburger icon
                    HStack {
                        Button(action: {
                            // Toggle the menu
                            isShowingMenu.toggle()
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    // SCANNING STATUS
                    Text(bleManager.isScanning ? "Scanning..." : "Not Scanning")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    // RADAR ANIMATION (only if scanning)
                    if bleManager.isScanning {
                        RadarScanView()
                            .frame(width: 200, height: 200)
                            .padding(.bottom, 8)
                    }
                    
                    // Start/Stop scan button
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
                    
                    // If no devices found and not scanning, show a friendly message
                    if bleManager.discoveredPeripherals.isEmpty && !bleManager.isScanning {
                        Text("No devices found.\nTap 'Start Scan' to discover devices.")
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    } else {
                        // Device list
                        List(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                            Button(action: {
                                bleManager.connect(peripheral)
                            }) {
                                HStack {
                                    Text(peripheral.name ?? "Unknown Device")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Show "Connected" if this peripheral is the connected one
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
                    
                    // If connected, show the connected peripheral name + disconnect
                    if let connectedPeripheral = bleManager.connectedPeripheral {
                        Text("Connected to \(connectedPeripheral.name ?? "Unknown")")
                            .foregroundColor(.white)
                        
                        


                        // 2) Navigation link to the sensor data
                        NavigationLink("View Data", destination: SensorDataView())
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                        
                        Button("Disconnect") {
                            bleManager.disconnect()
                        }
                        .padding()
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            // Slide the main content to the right when the menu is showing
            .offset(x: isShowingMenu ? menuWidth : 0)
            .animation(.easeInOut, value: isShowingMenu)
        }
        .navigationBarHidden(true)  // Hide default navigation bar
    }
}
