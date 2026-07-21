//
//  qualityButton.swift
//  ChordSolver (iOS)
//
//  Created by Dylan Shade on 4/13/21.
//  Refactored on 10/8/25 - Added animations and haptics
//

import SwiftUI

struct qualityButton: View {

    @EnvironmentObject var viewModel: triadBuildViewModel

    var name: String = "Major"
    @State var active: Bool = false
    @State private var isPressed = false

    // Colors
    private let activeColor = Color(red: 0.96, green: 0.75, blue: 0.75)
    private let inactiveColor = Color(red: 1.0, green: 0.44, blue: 0.44)

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            // Execute action with animation
            withAnimation(AppAnimation.quickSpring) {
                switch name {
                    case "Major":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.major.toggle()
                    case "Minor":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.minor.toggle()
                    case "+":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.aug.toggle()
                    case "o":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.dim.toggle()
                    case "MM7":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.MM7.toggle()
                    case "Mm7":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.Mm7.toggle()
                    case "mM7":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.mM7.toggle()
                    case "mm7":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.mm7.toggle()
                    case "ø7":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.hd7.toggle()
                    case "o7":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.fd7.toggle()
                    case "It+6":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.itA6.toggle()
                    case "Fr+6":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.frA6.toggle()
                    case "Ger+6":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.gerA6.toggle()
                    case "Sus2":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.sus2.toggle()
                    case "Sus4":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.sus4.toggle()
                    case "CT°7":
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.ct7.toggle()
                    default:
                        active.toggle()
                        viewModel.resetButtons()
                        viewModel.major = true
                }
            }
        }) {
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AppAnimation.quickSpring, value: isPressed)
        .onLongPressGesture(
            minimumDuration: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

struct qualityButton_Previews: PreviewProvider {
    static var previews: some View {
        qualityButton()
    }
}
