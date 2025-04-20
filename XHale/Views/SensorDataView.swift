import SwiftUI
import Charts   // Only if you still want to keep Charts somewhere else

struct SensorDataView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    // Local state to track whether we're displaying data
    @State private var displayData = false
    
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
                Text("Sensor Data")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // MARK: - Start/Stop Display Buttons
                HStack(spacing: 20) {
                    Button("Start Display") {
                        displayData = true
                        bleManager.startSampling()   // sets isSampling = true internally
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    
                    Button("Stop Display") {
                        displayData = false
                        bleManager.stopSampling()    // sets isSampling = false
                    }
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                }
                
                if bleManager.connectedPeripheral != nil {
                NavigationLink("Take 15‑Second Breath Sample", destination: BreathSampleView())
                .padding()
                .background(Color.orange.opacity(0.3))
                .cornerRadius(8)
                .foregroundColor(.white)
                }
                
                // MARK: - Show Gauges & Data If displayData == true
                if displayData {
                    if #available(iOS 16.0, *) {
                        // Gauges in rows
                        VStack(spacing: 20) {
                            // First row: Temperature + Humidity
                            HStack(spacing: 30) {
                                // 1) Temperature gauge
                                let temp = bleManager.temperatureData.last ?? 0
                                Gauge(value: temp, in: -10...50) {
                                    Text("Temp")
                                }
                                .gaugeStyle(.accessoryCircular)
                                .tint(.red)
                                .frame(width: 80, height: 80)
                                /*
                                // 2) Humidity gauge
                                let hum = bleManager.humidityData.last ?? 0
                                Gauge(value: hum, in: 0...100) {
                                    Text("Humidity")
                                }
                                .gaugeStyle(.accessoryCircular)
                                .tint(.blue)
                                .frame(width: 80, height: 80)*/
                            }
                            
                            // Second row: Pressure + CO
                            HStack(spacing: 30) {
                                /*
                                // 3) Pressure gauge
                                let pres = bleManager.pressureData.last ?? 0
                                Gauge(value: pres, in: 90000...110000) {
                                    Text("Pressure")
                                }
                                .gaugeStyle(.accessoryCircular)
                                .tint(.green)
                                .frame(width: 80, height: 80)*/
                                
                                // 4) CO gauge
                                let coValue = bleManager.coData.last ?? 0
                                Gauge(value: coValue, in: 0...1000) {
                                    Text("CO")
                                }
                                .gaugeStyle(.accessoryCircular)
                                .tint(.purple)
                                .frame(width: 80, height: 80)
                            }
                        }
                    } else {
                        // Fallback for iOS < 16
                        Text("Gauges require iOS 16+.")
                            .foregroundColor(.white)
                    }
                    
                    // MARK: - Latest Readings (Text)
                    Text("Temperature: \(latestTemperature, specifier: "%.2f") °C")
                        .foregroundColor(.white)
                    /*
                    Text("Humidity: \(latestHumidity, specifier: "%.2f") %")
                        .foregroundColor(.white)
                    Text("Pressure: \(latestPressure, specifier: "%.2f") Pa")
                        .foregroundColor(.white) */
                    Text("CO: \(latestCO, specifier: "%.2f") ppm")
                        .foregroundColor(.white)
                    
                    // MARK: - Historical Readings
                    List {
                        Section(header: Text("Temperature History")) {
                            ForEach(bleManager.temperatureData, id: \.self) { value in
                                Text("\(value, specifier: "%.2f") °C")
                            }
                        }
                        /*
                        Section(header: Text("Humidity History")) {
                            ForEach(bleManager.humidityData, id: \.self) { value in
                                Text("\(value, specifier: "%.2f") %")
                            }
                        }
                        Section(header: Text("Pressure History")) {
                            ForEach(bleManager.pressureData, id: \.self) { value in
                                Text("\(value, specifier: "%.2f") Pa")
                            }
                        }*/
                        Section(header: Text("CO History")) {
                            ForEach(bleManager.coData, id: \.self) { value in
                                Text("\(value, specifier: "%.2f") ppm")
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                    // For iOS 16+ if you want the list background to be transparent:
                    // .scrollContentBackground(.hidden)
                    // .background(Color.clear)
                } else {
                    // If displayData is false, show a placeholder
                    Text("Data display is off. Press 'Start Display' to begin sampling.")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Sensor Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)

    }
    
    // MARK: - Computed Properties
    private var latestTemperature: Double {
        bleManager.temperatureData.last ?? 0.0
    }
    
    private var latestHumidity: Double {
        bleManager.humidityData.last ?? 0.0
    }
    
    private var latestPressure: Double {
        bleManager.pressureData.last ?? 0.0
    }
    
    private var latestCO: Double {
        bleManager.coData.last ?? 0.0
    }
}
