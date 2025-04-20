//
//  TutorialManager.swift
//  XHale
//
//  Created by NPL-Weng on 4/20/25.
//
import SwiftUI

// TutorialManager.swift
final class TutorialManager: ObservableObject {
  @Published var isActive = true
  @Published var currentIndex = 0

  let steps = [
    (anchorID: "scanButton",      title: "Start Scan",   message: "Tap here to scan."),
    (anchorID: "xHaleItem",       title: "Choose Device",message: "Select XHale."),
    (anchorID: "breathSampleButton", title: "Take Sample", message: "Press to sample.")
  ]

  var currentStep: (anchorID: String, title: String, message: String) {
    steps[currentIndex]
  }

  func advance() {
    if currentIndex + 1 < steps.count { currentIndex += 1 }
    else                            { isActive = false }
  }
}
