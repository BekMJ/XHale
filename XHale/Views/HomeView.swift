import SwiftUI
import CoreBluetooth

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject private var tutorial: TutorialManager

    @State private var isShowingMenu = false
    private let menuWidth: CGFloat = 250

    var body: some View {
        ZStack(alignment: .leading) {
            sideMenu
            mainContent
                .offset(x: isShowingMenu ? menuWidth : 0)
                .animation(.easeInOut, value: isShowingMenu)
        }
        .navigationBarHidden(true)
        .overlay(
          Group {
            if tutorial.isActive && tutorial.currentStep.anchorID == nil {
              VStack(spacing: 16) {
                // ← Your popup image

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
                  Image("Step1")       // <-- add this
                    .resizable()                  // make it scale
                    .scaledToFit()                // keep aspect ratio
                    .frame(width: 200, height: 200)
                    .shadow(radius: 10)
              }
              .padding() // give some breathing room
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .background(Color.black.opacity(0.6))
            }
          }
        )

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
                    LazyVStack(spacing: 12) {
                        ForEach(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                            Button {
                                bleManager.connect(peripheral)
                                if tutorial.isActive && tutorial.currentStep.anchorID == "xHaleItem" {
                                    tutorial.advance()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(peripheral.name ?? "Unknown Device")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if let sn = bleManager.deviceSerial {
                                          Text((sn))
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        }

                                        if bleManager.connectedPeripheral == peripheral {
                                            Text("Connected")
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                        }
                                        if let seconds = bleManager.connectionDurations[peripheral.identifier] {
                                            Text("\(Int(seconds))s")
                                                .font(.subheadline)
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    if bleManager.connectedPeripheral == peripheral {
                                        HStack(spacing: 16) {
                                            Text("CO: \(bleManager.coData.last ?? 0.0, specifier: "%.2f") ppm")
                                            Text("Temp: \(bleManager.temperatureData.last ?? 0.0, specifier: "%.2f") °C")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                            .id(peripheral.identifier)
                            .coachMark(
                                id: "xHaleItem",
                                title: "Choose Your Device",
                                message: "Tap on \"XHale\" in the list to connect."
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: tutorial.currentStep.anchorID) { id in
                    if id == "xHaleItem" {
                        // Scroll to the first matching XHale peripheral
                        if let target = bleManager.discoveredPeripherals.first(where: { $0.name == "XHale" }) {
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
            NavigationLink(destination: BreathSampleView()
                                .environmentObject(bleManager)
                                .environmentObject(tutorial)) {
                Text("Take 15‑Second Breath Sample")
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
                message: "Press here to start your 15‑second sample."
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
}
