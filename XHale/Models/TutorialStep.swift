import SwiftUI

/// One step in your tutorial

struct TutorialStep {
  /// `nil` means “no view to highlight” (a full‑screen instruction)
  let anchorID: String?
  let title: String
  let message: String
}

final class TutorialManager: ObservableObject {
  @Published var isActive     = true
  @Published var currentIndex = 0

  let steps: [TutorialStep] = [
    // 1) No button—just tell them to power on:
    .init(anchorID: nil,
          title: "Power On",
          message: "Press the Bluetooth button on your XHale device to turn it on."),

    // 2) Start Scan:
    .init(anchorID: "scanButton",
          title: "Start Scanning",
          message: "Tap here to begin scanning for devices."),

    // 3) Select XHale in the list:
    .init(anchorID: "xHaleItem",
          title: "Choose Your Device",
          message: "Tap on “XHale” in the list to connect."),

    // 4) Take a sample:
    .init(anchorID: "breathSampleButton",
          title: "Take a Breath Sample",
          message: "Now press here to start your 15‑second sample.")
  ]

  var currentStep: TutorialStep { steps[currentIndex] }

  func advance() {
    if currentIndex + 1 < steps.count {
      currentIndex += 1
    } else {
      isActive = false
    }
  }
}

extension View {
  @ViewBuilder
  func tutorialAnchorIf(_ id: String?) -> some View {
    if let id = id {
      self.tutorialAnchor(id: id)
    } else {
      self
    }
  }
}


