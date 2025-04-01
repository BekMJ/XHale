import SwiftUI
import Charts

struct BreathSampleView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    @State private var isSampling = false
    @State private var timeLeft = 15
    @State private var sampleDone = false
    
    // Toggles for data display
    @State private var showTemperature = true
    @State private var showCO = true
    
    // Timer reference
    @State private var timer: Timer?
    
    // For CSV export
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    
    // State for showing the save alert after sampling
    @State private var showSaveAlert = false
    
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
                
                // Sampling state
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
                    // Display sample results
                    Text("Sample Finished!")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading) {
                        Toggle("Show Temperature", isOn: $showTemperature)
                        Toggle("Show CO", isOn: $showCO)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    
                    // Chart for sample data
                    chartView
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    // CSV Export button
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
        .sheet(isPresented: $showShareSheet) {
            if let fileURL = csvURL {
                CSVShareSheet(url: fileURL)
            }
        }
        // Alert asking user if they want to save the sample
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text("Save Sample"),
                message: Text("Do you want to save this 15-second sample?"),
                primaryButton: .default(Text("Save"), action: {
                    // Calculate average values and upload to Firestore
                    if !bleManager.temperatureData.isEmpty, !bleManager.coData.isEmpty {
                        let avgTemperature = bleManager.temperatureData.reduce(0, +) / Double(bleManager.temperatureData.count)
                        let avgCO = bleManager.coData.reduce(0, +) / Double(bleManager.coData.count)
                        bleManager.uploadSensorData(temperature: avgTemperature, co: avgCO)
                    }
                }),
                secondaryButton: .cancel(Text("Don't Save"))
            )
        }
    }
    
    // MARK: - Sampling Logic
    
    private func startSample() {
        // Reset states and clear previous data
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
        sampleDone = true           // display toggles, chart, export
        
        // Show the alert asking if the user wants to save the sample
        showSaveAlert = true
    }
    
    // MARK: - Chart
    
    @ViewBuilder
    private var chartView: some View {
        Chart {
            // Temperature data points
            if showTemperature {
                ForEach(bleManager.temperatureData.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Index", i),
                        y: .value("Temp", bleManager.temperatureData[i])
                    )
                    .foregroundStyle(.red)
                }
            }
            // CO data points
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
         let fileName = "BreathSample.csv"
         let tempDir = FileManager.default.temporaryDirectory
         let fileURL = tempDir.appendingPathComponent(fileName)
         
         var csvText = "Index,Temperature,CO\n"
         let maxCount = max(bleManager.temperatureData.count, bleManager.coData.count)
         
         for i in 0..<maxCount {
             let temp = i < bleManager.temperatureData.count ? bleManager.temperatureData[i] : 0
             let co   = i < bleManager.coData.count ? bleManager.coData[i] : 0
             csvText += "\(i),\(temp),\(co)\n"
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
