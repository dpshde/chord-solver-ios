//
//  scaleButtons.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/17/21.
//  Refactored on 10/8/25 - Added animations and haptics
//

import SwiftUI

struct scaleButtons: View {

    @EnvironmentObject var viewModel: scalesViewModel

    var name: String = "Major"
    @State var active: Bool = false
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Button(name) {
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
                        case "Natural\nMinor":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.minorNat.toggle()
                        case "Harmonic\nMinor":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.minorHarm.toggle()
                        case "Melodic\nMinor":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.minorMel.toggle()
                        case "Pentatonic":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.pentatonic.toggle()
                        case "Whole\nTone":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.wholeTone.toggle()
                        case "Octatonic":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.octatonic.toggle()
                        case "Dorian":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.dorian.toggle()
                        case "Phyrigian":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.phrygian.toggle()
                        case "Lydian":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.lydian.toggle()
                        case "Mixolydian":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.mixo.toggle()
                        case "Locrian":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.locrian.toggle()
                        case "Phrygian ♮6":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.dorB2.toggle()
                        case "Lydian\nAugmented":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.lydianAug.toggle()
                        case "Lydian\nDominant":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.lydDom.toggle()
                        case "Mixolydian ♭13", "Mixolydian ♭6", "Mixo ♭6":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.mixoB6.toggle()
                        case "Locrian #2", "Locrian ♮2":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.locNat2.toggle()
                        case "Altered":
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.supLoc.toggle()

                        default:
                            active.toggle()
                            viewModel.resetButtons()
                            viewModel.major = true
                    }
                }
            }.foregroundColor(.white)

        }
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

struct scaleButtons_Previews: PreviewProvider {
    static var previews: some View {
        scaleButtons()
    }
}
