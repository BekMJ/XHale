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
            if tutorial.isActive {
              // If this step has no anchor, show a full‑screen callout
              if tutorial.currentStep.anchorID == nil {
                VStack(spacing: 16) {
                  Text(tutorial.currentStep.title)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                  Text(tutorial.currentStep.message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                  Button("Next") { tutorial.advance() }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.6))
              } else {
                // Otherwise just show the Next button in the corner
                Button("Next") { tutorial.advance() }
                  .padding()
                  .background(Color.blue)
                  .foregroundColor(.white)
                  .cornerRadius(8)
                  .padding(.top, 50)
                  .padding(.trailing, 20)
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
              }
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
            Button(action: { isShowingMenu.toggle() }) {
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
        Button(action: {
            if bleManager.isScanning { bleManager.stopScanning() }
            else { bleManager.startScanning() }
        }) {
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

    // MARK: - Device List or Placeholder
    @ViewBuilder
    private var deviceListSection: some View {
        if bleManager.discoveredPeripherals.isEmpty && !bleManager.isScanning {
            Text("No devices found.\nTap 'Start Scan' to discover devices.")
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        } else {
            List(bleManager.discoveredPeripherals, id: \.identifier) { peripheral in
                Button(action: { bleManager.connect(peripheral) }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(peripheral.name ?? "Unknown Device")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
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
                .coachMark(
                  id: "xHaleItem",
                  title: "Choose Your Device",
                  message: "Tap on “XHale” in the list to connect."
                )
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .cornerRadius(8)
        }
    }
    

    // MARK: - Connected Section
    @ViewBuilder
    private var connectedSection: some View {
        if let connected = bleManager.connectedPeripheral {
            NavigationLink(
                "Take 15‑Second Breath Sample",
                destination: BreathSampleView()
            )
            .padding()
            .background(Color.orange.opacity(0.3))
            .cornerRadius(8)
            .foregroundColor(.white)
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
