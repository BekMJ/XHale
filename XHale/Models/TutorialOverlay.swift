import SwiftUI

struct TutorialOverlay: View {
  @EnvironmentObject var manager: TutorialManager
  let anchors: [String: CGRect]

  var body: some View {
    GeometryReader { geo in
      ZStack {
        // Dim the screen…
        Color.black.opacity(0.6)
          .ignoresSafeArea()
          .mask {
            // …but punch a hole if we have a frame
            if let hole = highlightFrame {
              Rectangle()
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .frame(width: hole.width, height: hole.height)
                    .offset(x: hole.minX,    y: hole.minY)
                    .blendMode(.destinationOut)
                )
                .compositingGroup()
            }
          }
          // ⇢ Only block taps when there is NO hole (first step)
          .allowsHitTesting(highlightFrame == nil)

        // Instruction + Next
        VStack(spacing: 8) {
          Text(manager.currentStep.title)
            .font(.headline)
            .foregroundColor(.white)
          Text(manager.currentStep.message)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .padding(.horizontal, 24)

          Button("Next") {
            manager.advance()
          }
          .padding(.vertical, 6)
          .padding(.horizontal, 24)
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(6)
        }
        // Position above hole, or center when there is none
        .position(
          x: highlightFrame?.midX ?? geo.size.width  / 2,
          y: highlightFrame.map { max($0.minY - 80, 100) }
               ?? geo.size.height / 2
        )
      }
    }
  }

  private var highlightFrame: CGRect? {
    guard let id = manager.currentStep.anchorID else { return nil }
    return anchors[id]
  }
}
