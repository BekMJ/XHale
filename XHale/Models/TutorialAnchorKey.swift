import SwiftUI

/// Collects [anchorID: frame] in global coords
struct TutorialAnchorKey: PreferenceKey {
  static var defaultValue: [String: CGRect] = [:]
  static func reduce(value: inout [String: CGRect],
                     nextValue: () -> [String: CGRect]) {
    value.merge(nextValue(), uniquingKeysWith: { $1 })
  }
}


/// A helper modifier to tag & record a view’s frame
extension View {
  func tutorialAnchor(id: String) -> some View {
    background(
      GeometryReader { proxy in
        Color.clear
          .preference(key: TutorialAnchorKey.self,
                      value: [id: proxy.frame(in: .global)])
      }
    )
  }
}
