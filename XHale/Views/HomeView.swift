import SwiftUI
import CoreBluetooth
import UIKit

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject private var tutorial: TutorialManager

    @AppStorage("batteryStartTime") private var batteryStartTime: Double = Date().timeIntervalSince1970
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted: Bool = false
    @State private var showDisclaimer: Bool = false

    @State private var isShowingMenu = false
    private let menuWidth: CGFloat = 250

    @State private var showBluetoothAlert: Bool = false
    @State private var bluetoothAlertMessage: String = ""
    @State private var lastBluetoothState: CBManagerState = .unknown

    var body: some View {
        ZStack(alignment: .leading) {
            sideMenu
            mainContent
                .offset(x: isShowingMenu ? menuWidth : 0)
                .animation(.easeInOut, value: isShowingMenu)
        }
        .navigationBarHidden(true)
        .overlay(tutorialOverlay)
        .sheet(isPresented: $showDisclaimer) {
            disclaimerSheet
        }
        .onAppear {
            // Show disclaimer only if not accepted and not already showing
            if !disclaimerAccepted && !showDisclaimer {
                showDisclaimer = true
            }
        }
        .onReceive(bleManager.$bluetoothState) { state in
            // Only show alert if state changed to a problematic state and we're not already showing an alert
            if (state == .poweredOff || state == .unauthorized) && !showBluetoothAlert && lastBluetoothState != state {
                if state == .poweredOff {
                    bluetoothAlertMessage = "Bluetooth is currently turned off. Please turn on Bluetooth in Control Center or Settings to use this app.\n\nThis app uses Bluetooth to discover and connect to the Carbon Monoxide sensor so you can receive real-time carbon monoxide (CO) and temperature readings."
                } else if state == .unauthorized {
                    bluetoothAlertMessage = "Bluetooth access is currently denied. Please enable Bluetooth permissions for this app in Settings.\n\nThis app uses Bluetooth to discover and connect to the Carbon Monoxide sensor so you can receive real-time carbon monoxide (CO) and temperature readings."
                }
                showBluetoothAlert = true
            }
            
            // Hide alert if Bluetooth state becomes valid
            if (state == .poweredOn || state == .resetting) && showBluetoothAlert {
                showBluetoothAlert = false
            }
            
            lastBluetoothState = state
        }
        .alert("Bluetooth Required", isPresented: $showBluetoothAlert) {
            if bleManager.bluetoothState == .unauthorized {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(bluetoothAlertMessage)
        }
    }

    // MARK: - Side Menu
    private var sideMenu: some View {
        SideMenuView(isShowingMenu: $isShowingMenu)
            .frame(width: menuWidth)
            .offset(x: isShowingMenu ? 0 : -menuWidth)
            .animation(.easeInOut, value: isShowingMenu)
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            contentVStack
        }
    }

    // MARK: - Content Stack
    @ViewBuilder
    private var contentVStack: some View {
        VStack(spacing: 16) {
            headerBar
            scanningStatus
            scanButtonSection
            deviceListSection
            TransparentView()
                .frame(width: 250, height: 250)
            connectedSection
            Spacer()
        }
        .padding()
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Button { isShowingMenu.toggle() } label: {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Scanning Status
    @ViewBuilder
    private var scanningStatus: some View {
        if bleManager.isScanning {
            RadarScanView(label: "Scanning…")
                .font(.title2)
                .frame(height: 40)
        } else {
            Text("Not Scanning")
                .font(.title2)
                .foregroundColor(.white)
        }
    }

    // MARK: - Scan Button
    private var scanButtonSection: some View {
        Button {
            // Check Bluetooth state before scanning
            if bleManager.bluetoothState == .poweredOff {
                bluetoothAlertMessage = "Bluetooth is currently turned off. Please turn on Bluetooth in Control Center or Settings to use this app.\n\nThis app uses Bluetooth to discover and connect to the Carbon Monoxide sensor so you can receive real-time carbon monoxide (CO) and temperature readings."
                showBluetoothAlert = true
                return
            } else if bleManager.bluetoothState == .unauthorized {
                bluetoothAlertMessage = "Bluetooth access is currently denied. Please enable Bluetooth permissions for this app in Settings.\n\nThis app uses Bluetooth to discover and connect to the Carbon Monoxide sensor so you can receive real-time carbon monoxide (CO) and temperature readings."
                showBluetoothAlert = true
                return
            }
            
            // If Bluetooth is available, proceed with scanning
            if bleManager.isScanning { bleManager.stopScanning() }
            else { bleManager.startScanning() }
            if tutorial.isActive && tutorial.currentStep.anchorID == "scanButton" {
                tutorial.advance()
            }
        } label: {
            Text(bleManager.isScanning ? "Stop Scan" : "Start Scan")
                .fontWeight(.semibold)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .foregroundColor(.white)
        }
        .coachMark(
            id: "scanButton",
            title: "Start Scanning",
            message: "Tap here to begin scanning for devices."
        )
    }

    // MARK: - Device List Section
    @ViewBuilder
    private var deviceListSection: some View {
        if bleManager.discoveredPeripherals.isEmpty && !bleManager.isScanning {
            Text("No devices found.\nTap 'Start Scan' to discover devices.")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                            Button {
                                bleManager.connect(peripheral)
                                if tutorial.isActive && tutorial.currentStep.anchorID == "xHaleItem" {
                                    tutorial.advance()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    // Device name and connection status
                                    HStack {
                                        Text(peripheral.name ?? "Unknown Device")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .minimumScaleFactor(0.8)
                                            .lineLimit(1)
                                            .accessibilityLabel("Device name: \(peripheral.name ?? "Unknown Device")")
                                        Spacer()
                                        if bleManager.connectedPeripheral == peripheral {
                                            Text("Connected")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    // Device details in compact format
                                    if bleManager.connectedPeripheral == peripheral {
                                        VStack(alignment: .leading, spacing: 1) {
                                            // Serial and MAC on same line
                                            HStack {
                                                if let sn = bleManager.deviceSerial {
                                                    Text("SN: \(sn)")
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                                if let mac = bleManager.peripheralMACs[peripheral.identifier] {
                                                    Text("MAC: \(mac)")
                                                        .font(.caption2)
                                                        .foregroundColor(.white)
                                                }
                                                Spacer()
                                                BatteryIconView(startTime: batteryStartTime)
                                            }
                                            
                                            // CO and Temp on same line
                                            HStack(spacing: 16) {
                                                Text("CO: \(bleManager.coData.last ?? 0.0, specifier: "%.2f") ppm")
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                                Text("Temp: \(bleManager.temperatureData.last ?? 0.0, specifier: "%.2f") °C")
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    } else {
                                        // Show MAC for unconnected devices
                                        if let mac = bleManager.peripheralMACs[peripheral.identifier] {
                                            Text("MAC: \(mac)")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                            .id(peripheral.identifier)
                            .coachMark(
                                id: "xHaleItem",
                                title: "Choose Your Device",
                                message: "Tap on \"XHale Health\" in the list to connect."
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 120)
                .onChange(of: tutorial.currentStep.anchorID) { id in
                    if id == "xHaleItem" {
                        // Scroll to the first matching XHale Health peripheral
                        if let target = bleManager.discoveredPeripherals.first(where: { $0.name == "XHale Health" }) {
                            proxy.scrollTo(target.identifier, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Connected Section
    @ViewBuilder
    private var connectedSection: some View {
        if let connected = bleManager.connectedPeripheral {
            @AppStorage("sampleDuration") var sampleDuration: Int = 15
            NavigationLink(destination: BreathSampleView()
                                .environmentObject(bleManager)
                                .environmentObject(tutorial)) {
                                    Text("Take \(sampleDuration)-Second Breath Sample")
                    .padding()
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
            .environmentObject(tutorial)
            .simultaneousGesture(
                TapGesture().onEnded {
                    if tutorial.isActive && tutorial.currentStep.anchorID == "breathSampleButton" {
                        tutorial.advance()
                    }
                }
            )
            .coachMark(
                id: "breathSampleButton",
                title: "Take a Breath Sample",
                message: "Press here to start your \(sampleDuration)-second sample."
            )

            Text("Connected to \(connected.name ?? "Unknown")")
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

    // MARK: - Tutorial Overlay
    @ViewBuilder
    private var tutorialOverlay: some View {
        if tutorial.isActive && tutorial.currentStep.anchorID == nil {
            VStack(spacing: 16) {
                Image("Step5")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .shadow(radius: 10)

                Text(tutorial.currentStep.title)
                    .font(.largeTitle)
                    .foregroundColor(.white)

                Text(tutorial.currentStep.message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                Button("Next") {
                    tutorial.advance()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.6))
        }
    }

    // MARK: - Disclaimer Sheet
    private var disclaimerSheet: some View {
        VStack(spacing: 24) {
            Text("Disclaimer")
                .font(.title2)
                .bold()
                .padding(.top)
            ScrollView {
                Text("This app is intended for informational and wellness purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Button(action: { 
                disclaimerAccepted = true
                showDisclaimer = false
            }) {
                Text("I Understand")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            Spacer()
        }
        .presentationDetents([.medium, .large])
    }
}
