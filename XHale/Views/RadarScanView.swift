import SwiftUI

// MARK: - RadarScanView
/// A radar-like animation with expanding circles emanating from a text label.
struct RadarScanView: View {
    @State private var animateWave = false
    
    /// The label to display at the center of the waves.
    var label: String = "Scanning..."

    var body: some View {
        ZStack {
            // Wave 1
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 20, height: 20)
                .scaleEffect(animateWave ? 5 : 1)
                .opacity(animateWave ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: animateWave
                )

            // Wave 2 (delayed start)
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: 20, height: 20)
                .scaleEffect(animateWave ? 5 : 1)
                .opacity(animateWave ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.0)
                        .repeatForever(autoreverses: false)
                        .delay(1.0),
                    value: animateWave
                )

            // Center label
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .accessibilityLabel(label)
        }
        .onAppear {
            animateWave = true
        }
    }
}
