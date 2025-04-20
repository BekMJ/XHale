//
//  FriendlyCountdownView.swift
//  XHale
//
//  Created by NPL-Weng on 4/20/25.
//


import SwiftUI

struct FriendlyCountdownView: View {
    /// fraction of time remaining (0…1)
    let progress: Double
    /// seconds left
    let timeLeft: Int

    var body: some View {
        ZStack {
            // 1) Background ring
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 12)

            // 2) Gradient progress ring
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.green, Color.yellow, Color.red]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.5), value: progress)

            // 3) Center label
            VStack(spacing: 4) {
                Text("\(timeLeft)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("seconds")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(width: 180, height: 180)
    }
}
