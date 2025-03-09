import SwiftUI

struct SensorDataView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sensor Data")
                .font(.headline)
            
            // Latest readings at a glance
            Text("Temperature: \(latestTemperature, specifier: "%.2f") °C")
            Text("Humidity: \(latestHumidity, specifier: "%.2f") %")
            Text("Pressure: \(latestPressure, specifier: "%.2f") Pa")
            Text("CO: \(latestCO, specifier: "%.2f") ppm")
            
            // Historical readings in a grouped List
            List {
                Section(header: Text("Temperature History")) {
                    ForEach(bleManager.temperatureData, id: \.self) { value in
                        Text("\(value, specifier: "%.2f") °C")
                    }
                }
                Section(header: Text("Humidity History")) {
                    ForEach(bleManager.humidityData, id: \.self) { value in
                        Text("\(value, specifier: "%.2f") %")
                    }
                }
                Section(header: Text("Pressure History")) {
                    ForEach(bleManager.pressureData, id: \.self) { value in
                        Text("\(value, specifier: "%.2f") Pa")
                    }
                }
                Section(header: Text("CO History")) {
                    ForEach(bleManager.coData, id: \.self) { value in
                        Text("\(value, specifier: "%.2f") ppm")
                    }
                }
            }
            .listStyle(GroupedListStyle())  // or .insetGroupedListStyle() on iOS 14+
        }
        .padding()
        .navigationTitle("Sensor Data")
    }
    
    // Computed properties to get the latest reading from each array
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
