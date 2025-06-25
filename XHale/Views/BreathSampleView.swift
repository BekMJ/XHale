import SwiftUI
import Charts

struct BreathSampleView: View {
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var tutorial: TutorialManager

    /// Duration from Settings (5–60 s)
    @AppStorage("sampleDuration") private var totalTime: Int = 15

    @State private var isSampling = false
    @State private var timeLeft = 0
    @State private var sampleDone = false

    @State private var showTemperature = true
    @State private var showCO = true

    @State private var timer: Timer?
    @State private var showShareSheet = false
    @State private var csvURL: URL?
    @State private var showSaveAlert = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Breath Sample Instructions:")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .accessibilityLabel("Breath Sample Instructions")
                    Text("""
• Hold the device in front of your mouth.
• Blow steadily for \(totalTime) seconds.
• Keep your phone nearby during sampling.
""")
                        .font(.body)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.horizontal)

                // Sampling / Countdown
                if !sampleDone {
                    if !isSampling {
                        Button("Start \(totalTime)-Second Sample") {
                            startSample()
                            if tutorial.isActive && tutorial.currentStep.anchorID == "startSampleButton" {
                                tutorial.advance()
                            }
                        }
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .coachMark(
                            id: "startSampleButton",
                            title: "Start Sampling",
                            message: "Tap to begin your \(totalTime)-second sample."
                        )
                    } else {
                        // Countdown
                        let fraction = Double(timeLeft) / Double(totalTime)
                        FriendlyCountdownView(progress: fraction, timeLeft: timeLeft)
                            .padding()

                        // Live readings
                        HStack(spacing: 24) {
                            Text("CO: \(bleManager.coData.last ?? 0.0, specifier: "%.2f") ppm")
                            Text("Temp: \(bleManager.temperatureData.last ?? 0.0, specifier: "%.2f") °C")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                    }
                } else {
                    // Sample complete UI
                    Text("Sample Finished!")
                        .font(.title3)
                        .foregroundColor(.white)

                    // Toggles
                    VStack(alignment: .leading) {
                        Toggle("Show Temp", isOn: $showTemperature)
                        Toggle("Show CO", isOn: $showCO)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                    // Chart
                    chartView
                        .frame(height: 300)
                        .padding(.horizontal)

                    // Data history lists
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if showCO {
                                Text("CO History:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                ForEach(bleManager.coData.indices, id: \.self) { i in
                                    Text("\(i): \(bleManager.coData[i], specifier: "%.2f") ppm")
                                        .foregroundColor(.white)
                                }
                            }
                            if showTemperature {
                                Divider().background(Color.white)
                                Text("Temp History:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                ForEach(bleManager.temperatureData.indices, id: \.self) { i in
                                    Text("\(i): \(bleManager.temperatureData[i], specifier: "%.2f") °C")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .frame(maxHeight: 200)

                    // Export
                    Button("Export CSV") {
                        exportCSV()
                        if tutorial.isActive && tutorial.currentStep.anchorID == "exportCSVButton" {
                            tutorial.advance()
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .coachMark(
                        id: "exportCSVButton",
                        title: "Export Data",
                        message: "Tap here to export your sample data as CSV."
                    )
                }

                Spacer()
            }
            .padding()
        }
        // Tutorial overlay
        .overlay(
            Group {
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
        )
        .navigationTitle("\(totalTime)s Breath Sample")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        // Share sheet
        .sheet(isPresented: $showShareSheet) {
            if let url = csvURL {
                CSVShareSheet(url: url)
            }
        }
        // Save alert
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text("Save Sample"),
                message: Text("Do you want to save this \(totalTime)-second sample?"),
                primaryButton: .default(Text("Save")) {
                    let avgTemp = bleManager.temperatureData.reduce(0, +) /
                                  Double(bleManager.temperatureData.count)
                    let avgCO   = bleManager.coData.reduce(0, +) /
                                  Double(bleManager.coData.count)
                    
                           if let connected = bleManager.connectedPeripheral,
                              let mac = bleManager.peripheralMACs[connected.identifier] {
                               bleManager.uploadSensorData(
                                 mac: mac,
                                 temperature: avgTemp,
                                 co: avgCO
                               )
                           } else {
                               print("⚠️ No MAC found; uploading without MAC")
                               // optional fallback:
                               bleManager.uploadSensorData(
                                 mac: "<unknown>",
                                 temperature: avgTemp,
                                 co: avgCO
                               )
                           }

                    
                    
                    if tutorial.isActive && tutorial.currentStep.anchorID == "saveSampleAction" {
                        tutorial.advance()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onDisappear { cleanupTimer() }
    }

    // MARK: - Sampling logic
    private func startSample() {
        timeLeft = totalTime
        isSampling = true
        sampleDone = false
        bleManager.startSampling()
        cleanupTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeLeft -= 1
            if timeLeft <= 0 { stopSample() }
        }
    }

    private func stopSample() {
        isSampling = false
        cleanupTimer()
        bleManager.stopSampling()
        sampleDone = true
        showSaveAlert = true
    }

    private func cleanupTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Chart rendering
    @ViewBuilder
    private var chartView: some View {
        let coCount   = bleManager.coData.count
        let tempCount = bleManager.temperatureData.count
        let coMax     = (bleManager.coData.max() ?? 0) * 1.1
        let tempMaxRaw = bleManager.temperatureData.max() ?? 0
        let tempMin   = tempMaxRaw * 0.5
        let tempMax   = tempMaxRaw * 1.5

        let coPositions: [Double] = bleManager.coData.indices.map { Double($0) }
        let tempPositions: [Double] = bleManager.temperatureData.indices.map { i in
            guard tempCount > 1 else { return 0 }
            return Double(i) * Double(coCount - 1) / Double(max(tempCount - 1, 1))
        }

        ZStack {
            if showCO {
                COChartView(coPositions: coPositions, coData: bleManager.coData, coMax: coMax, coCount: coCount)
            }
            if showTemperature {
                TemperatureChartView(tempPositions: tempPositions, temperatureData: bleManager.temperatureData, tempMin: tempMin, tempMax: tempMax, coCount: coCount)
            }
        }
    }

    // MARK: - CO Chart Subview
    private struct COChartView: View {
        let coPositions: [Double]
        let coData: [Double]
        let coMax: Double
        let coCount: Int

        var body: some View {
            let points = Array(zip(coPositions, coData))
            Chart {
                ForEach(points, id: \.0) { xPos, ppm in
                    LineMark(
                        x: .value("Sample", xPos),
                        y: .value("CO (ppm)", ppm)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .chartYScale(domain: 0...coMax)
            .chartXScale(domain: 0...Double(max(coCount - 1, 0)))
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                    .foregroundStyle(.white)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(); AxisTick()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v)) ppm")
                            .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Temperature Chart Subview
    private struct TemperatureChartView: View {
        let tempPositions: [Double]
        let temperatureData: [Double]
        let tempMin: Double
        let tempMax: Double
        let coCount: Int

        var body: some View {
            let points = Array(zip(tempPositions, temperatureData))
            Chart {
                ForEach(points, id: \.0) { xPos, temp in
                    LineMark(
                        x: .value("Sample", xPos),
                        y: .value("Temp (°C)", temp)
                    )
                    .foregroundStyle(Color.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .chartYScale(domain: tempMin...tempMax)
            .chartXScale(domain: 0...Double(max(coCount - 1, 0)))
            .chartXAxis(.hidden) // Hide x-axis for overlay
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisGridLine(); AxisTick()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v)) °C")
                            .foregroundStyle(.white)
                        }
                    }
                }
            }
            .background(Color.clear)
            .allowsHitTesting(false) // Prevent overlay from blocking interaction
        }
    }

    // MARK: - CSV Export

    private func exportCSV() {
        let fileName = "BreathSample.csv"
        let fileURL  = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csv = "Index,Temperature,CO\n"
        let count = max(bleManager.temperatureData.count, bleManager.coData.count)
        for i in 0..<count {
            let t = i < bleManager.temperatureData.count ? bleManager.temperatureData[i] : 0
            let c = i < bleManager.coData.count          ? bleManager.coData[i] : 0
            csv += "\(i),\(t),\(c)\n"
        }

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            csvURL = fileURL
            showShareSheet = true
        } catch {
            print("CSV write error:", error)
        }
    }
}
