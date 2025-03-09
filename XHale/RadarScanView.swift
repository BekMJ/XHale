import SwiftUI
import CoreBluetooth

// MARK: - RadarScanView
/// A radar-like animation with expanding circles emanating from a center icon.
struct RadarScanView: View {
    @State private var animateWave = false
    
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
            
            // Central icon (white to match the text color)
            Image(systemName: "dot.radiowaves.right")
                .font(.system(size: 36))
                .foregroundColor(.white)
        }
        .onAppear {
            animateWave = true
        }
    }
}

