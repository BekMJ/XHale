import SwiftUI

/// Represents a single tutorial step, optionally anchored to a view.
struct TutorialStep {
    let anchorID: String?
    let title: String
    let message: String
}

final class TutorialManager: ObservableObject {
    @Published var isActive = true
    @Published var currentIndex = 0

    /// The ordered list of steps in your tutorial flow.
    let steps: [TutorialStep] = [
        // Step 1: Power on the device (no specific anchor)
        .init(anchorID: nil,
              title: "Power On",
              message: "Press the Bluetooth button on your XHale device to turn it on."),

        // Step 2: Scan for peripherals
        .init(anchorID: "scanButton",
              title: "Start Scan",
              message: "Tap here to begin scanning."),

        // Step 3: Choose your XHale device
        .init(anchorID: "xHaleItem",
              title: "Choose Device",
              message: "Tap on \"XHale\" to connect."),

        // Step 4: Navigate to sampling screen
        .init(anchorID: "breathSampleButton",
              title: "Go to Sampling",
              message: "Press here to start your breath sample."),

        // Step 5: Position the device
        .init(anchorID: nil,
              title: "Position Device",
              message: "Hold your XHale device in front of your mouth as shown."),

        // Step 6: Begin the sample countdown
        .init(anchorID: "startSampleButton",
              title: "Start Sampling",
              message: "Tap to begin your 15‑second sample."),

        // Step 7: Save your sample
        .init(anchorID: "saveSampleAction",
              title: "Save Sample",
              message: "Tap Save to upload your average readings.")
    ]

    /// The currently active tutorial step
    var currentStep: TutorialStep {
        steps[currentIndex]
    }

    /// Advance to the next step, or finish if at the end
    func advance() {
        if currentIndex + 1 < steps.count {
            currentIndex += 1
        } else {
            isActive = false
        }
    }
}
