import SwiftUI

struct CircularCountdownView: View {
    /// fraction of time remaining (0…1)
    let progress: Double
    /// seconds left
    let timeLeft: Int

    var body: some View {
        ZStack {
            // Elapsed arc (inner, grey)
            Circle()
                .trim(from: 0, to: CGFloat(1 - progress))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundColor(Color.white.opacity(0.2))
                .rotationEffect(.degrees(-90))

            // Remaining arc (outer, bright)
            Circle()
                .trim(from: CGFloat(1 - progress), to: 1)
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .foregroundColor(.white)
                .rotationEffect(.degrees(-90))

            // Central countdown text
            Text("\(timeLeft)")
                .font(.body)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .accessibilityLabel("Time left: \(timeLeft) seconds")
        }
        .frame(width: 150, height: 150)
        // smooth linear transition each second
        .animation(.linear(duration: 1), value: progress)
    }
}
