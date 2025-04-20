import SwiftUI
import Charts

struct BreathSampleView: View {
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var tutorial: TutorialManager

    /// Pull this from your Settings stepper (5–60 s)
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
            // Background gradient
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
                        .font(.title3).bold()
                    Text("""
                        • Hold the device in front of your mouth.
                        • Blow steadily for \(totalTime) seconds.
                        • Keep your phone nearby during sampling.
                        """
                    )
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
                            message: "Tap to begin your 15‑second sample."
                        )
                    } else {
                        let fraction = Double(timeLeft) / Double(totalTime)
                        FriendlyCountdownView(progress: fraction, timeLeft: timeLeft)
                            .padding()
                    }
                } else {
                    // Results, Toggles, Chart, Export
                    Text("Sample Finished!")
                        .font(.title3)
                        .foregroundColor(.white)

                    VStack(alignment: .leading) {
                        Toggle("Show Temp", isOn: $showTemperature)
                        Toggle("Show CO", isOn: $showCO)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                    chartView
                        .frame(height: 300)
                        .padding(.horizontal)

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
        // Step 5 overlay: Position Device (anchorID nil)
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

        .sheet(isPresented: $showShareSheet) {
            if let url = csvURL {
                CSVShareSheet(url: url)
            }
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text("Save Sample"),
                message: Text("Do you want to save this \(totalTime)-second sample?"),
                primaryButton: .default(Text("Save")) {
                    let avgTemp = bleManager.temperatureData.reduce(0, +) /
                                  Double(bleManager.temperatureData.count)
                    let avgCO   = bleManager.coData.reduce(0, +) /
                                  Double(bleManager.coData.count)
                    bleManager.uploadSensorData(temperature: avgTemp, co: avgCO)
                    if tutorial.isActive && tutorial.currentStep.anchorID == "saveSampleAction" {
                        tutorial.advance()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onDisappear { cleanupTimer() }
    }

    // MARK: - Sampling

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

    // MARK: - Chart

    @ViewBuilder
    private var chartView: some View {
        let coMax   = (bleManager.coData.max() ?? 0) * 1.1
        let tempMax = (bleManager.temperatureData.max() ?? 0) * 1.1

        Chart {
            if showCO {
                ForEach(bleManager.coData.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Sample", i),
                        y: .value("CO (ppm)", bleManager.coData[i])
                    )
                    .symbolSize(100)
                }
            }
            if showTemperature {
                ForEach(bleManager.temperatureData.indices, id: \.self) { i in
                    let temp = bleManager.temperatureData[i]
                    let scaled = (temp / tempMax) * coMax
                    PointMark(
                        x: .value("Sample", i),
                        y: .value("Temp (scaled)", scaled)
                    )
                    .symbolSize(100)
                }
            }
        }
        .chartYScale(domain: 0...coMax)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(); AxisTick()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine(); AxisTick()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        let t = v / coMax * tempMax
                        Text("\(Int(t))°C")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { _ in
                AxisGridLine(); AxisTick()
            }
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
