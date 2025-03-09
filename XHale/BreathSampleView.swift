import SwiftUI
import Charts

struct BreathSampleView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    @State private var isSampling = false
    @State private var timeLeft = 15
    
    // Toggles for each data type
    @State private var showTemperature = true
    @State private var showHumidity    = true
    @State private var showPressure    = true
    @State private var showCO          = true
    
    @State private var timer: Timer?
    
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
                
                // Start/Stop sampling
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
                
                // Toggling chart data sets, chart display, etc.
                // (Your existing code for toggles and chart here)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("15s Breath Sample")
    }
    
    private func startSample() {
        timeLeft = 15
        isSampling = true
        bleManager.startSampling()
        
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
        bleManager.stopSampling()
    }
}
