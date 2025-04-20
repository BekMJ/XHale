import SwiftUI

/// Represents a single tutorial step, optionally anchored to a view.
struct TutorialStep {
    let anchorID: String?
    let title: String
    let message: String
}

/// Manages the inline coach‑mark tutorial steps.
final class TutorialManager: ObservableObject {
    @Published var isActive = true
    @Published var currentIndex = 0

    /// Define your tutorial steps in order:
    /// 1) No anchor (full‑screen instruction), then anchored steps.
    let steps: [TutorialStep] = [
        .init(anchorID: nil,
              title: "Power On",
              message: "Press the Bluetooth button on your XHale device to turn it on."),
        .init(anchorID: "scanButton",
              title: "Start Scanning",
              message: "Tap here to begin scanning for devices."),
        .init(anchorID: "xHaleItem",
              title: "Choose Your Device",
              message: "Tap on \"XHale\" in the list to connect."),
        .init(anchorID: "breathSampleButton",
              title: "Take a Breath Sample",
              message: "Press here to start your 15‑second sample.")
    ]

    /// The currently active step.
    var currentStep: TutorialStep {
        steps[currentIndex]
    }

    /// Advance to the next step, or finish the tutorial.
    func advance() {
        if currentIndex + 1 < steps.count {
            currentIndex += 1
        } else {
            isActive = false
        }
    }
}
