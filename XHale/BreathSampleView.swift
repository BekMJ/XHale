import SwiftUI
import Charts

struct BreathSampleView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    @State private var isSampling = false
    @State private var timeLeft = 15
    @State private var sampleDone = false
    
    // Toggles for each data type
    @State private var showTemperature = true
    @State private var showHumidity    = true
    @State private var showPressure    = true
    @State private var showCO          = true
    
    // Timer reference
    @State private var timer: Timer?
    
    // For CSV export
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    
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
                // Instruction box
                VStack(alignment: .leading, spacing: 8) {
                    Text("Breath Sample Instructions:")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("• Hold the device in front of your mouth.\n• Blow steadily for 15 seconds.\n• Keep your phone nearby during sampling.")
                        .font(.body)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.horizontal)
                
                // If sampling not started or in progress
                if !sampleDone {
                    if !isSampling {
                        Button("Start 15-Second Sample") {
                            startSample()
                        }
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    } else {
                        Text("Sampling... \(timeLeft) seconds left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                } else {
                    // Once the 15s sample is done, show toggles + chart + export
                    Text("Sample Finished!")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    // Toggles for each data set
                    VStack(alignment: .leading) {
                        Toggle("Show Temperature", isOn: $showTemperature)
                        Toggle("Show Humidity", isOn: $showHumidity)
                        Toggle("Show Pressure", isOn: $showPressure)
                        Toggle("Show CO", isOn: $showCO)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Chart
                    chartView
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    // Export CSV button
                    Button("Export CSV") {
                        exportCSV()
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("15s Breath Sample")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        // For share sheet
        .sheet(isPresented: $showShareSheet) {
            if let fileURL = csvURL {
                CSVShareSheet(url: fileURL)
            }
        }
    }
    
    // MARK: - Sampling Logic
    
    private func startSample() {
        // Clear old data, set isSampling = true in BLE
        timeLeft = 15
        isSampling = true
        sampleDone = false
        
        bleManager.startSampling()  // Clears arrays, sets isSampling = true internally
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeLeft -= 1
            if timeLeft <= 0 {
                stopSample()
            }
        }
    }
    
    private func stopSample() {
        isSampling = false
        timer?.invalidate()
        timer = nil
        
        bleManager.stopSampling()   // sets isSampling = false
        sampleDone = true           // show toggles, chart, export
    }
    
    // MARK: - Chart
    
    @ViewBuilder
    private var chartView: some View {
        // Use Swift Charts
        Chart {
            // Temperature
            if showTemperature {
                ForEach(bleManager.temperatureData.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Index", i),
                        y: .value("Temp", bleManager.temperatureData[i])
                    )
                    .foregroundStyle(.red)
                }
            }
            // Humidity
            if showHumidity {
                ForEach(bleManager.humidityData.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Index", i),
                        y: .value("Humidity", bleManager.humidityData[i])
                    )
                    .foregroundStyle(.blue)
                }
            }
            // Pressure
            if showPressure {
                ForEach(bleManager.pressureData.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Index", i),
                        y: .value("Pressure", bleManager.pressureData[i])
                    )
                    .foregroundStyle(.green)
                }
            }
            // CO
            if showCO {
                ForEach(bleManager.coData.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Index", i),
                        y: .value("CO", bleManager.coData[i])
                    )
                    .foregroundStyle(.purple)
                }
            }
        }
        .chartYAxisLabel("Sensor Values")
        .chartXAxisLabel("Sample Index")
    }
    
    // MARK: - CSV Export
    
    private func exportCSV() {
         // Build CSV from the arrays in BLEManager
         let fileName = "BreathSample.csv"
         let tempDir = FileManager.default.temporaryDirectory
         let fileURL = tempDir.appendingPathComponent(fileName)
         
         var csvText = "Index,Temperature,Humidity,Pressure,CO\n"
         let maxCount = max(bleManager.temperatureData.count,
                            bleManager.humidityData.count,
                            bleManager.pressureData.count,
                            bleManager.coData.count)
         
         for i in 0..<maxCount {
             let temp = i < bleManager.temperatureData.count ? bleManager.temperatureData[i] : 0
             let hum  = i < bleManager.humidityData.count    ? bleManager.humidityData[i] : 0
             let pres = i < bleManager.pressureData.count    ? bleManager.pressureData[i] : 0
             let co   = i < bleManager.coData.count          ? bleManager.coData[i] : 0
             
             csvText += "\(i),\(temp),\(hum),\(pres),\(co)\n"
         }
         
         do {
             try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
             csvURL = fileURL
             showShareSheet = true
         } catch {
             print("Error writing CSV: \(error)")
         }
     }
 }

 // MARK: - CSVShareSheet for exporting
