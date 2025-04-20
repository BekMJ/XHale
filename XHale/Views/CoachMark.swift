//
//  CoachMark.swift
//  XHale
//
//  Created by NPL-Weng on 4/20/25.
//


import SwiftUI

/// Draws a yellow border + callout when `manager.currentStep.id == id`
struct CoachMark: ViewModifier {
  @EnvironmentObject var manager: TutorialManager
  let id: String
  let title: String
  let message: String

  func body(content: Content) -> some View {
    ZStack {
      content

      // Only overlay the highlight + callout on the active step
      if manager.isActive && manager.currentStep.anchorID == id {
        // ① highlight border
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.yellow, lineWidth: 3)
          .padding(-4)

        // ② callout box
        VStack(spacing: 4) {
          Text(title)
            .font(.headline)
            .foregroundColor(.white)
          Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(6)
        // position it above the content
        .offset(y: -60)
        
        // ③ “tap the real button” arrow
        Image(systemName: "arrowtriangle.down.fill")
          .font(.system(size: 20))
          .foregroundColor(.yellow)
          .offset(y: -30)
      }
    }
  }
}

extension View {
  func coachMark(id: String, title: String, message: String) -> some View {
    modifier(CoachMark(id: id, title: title, message: message))
  }
}
