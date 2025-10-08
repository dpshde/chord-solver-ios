//
//  scalesAnsView.swift
//  ChordSolver (iOS)
//
//  Created by Dylan Shade on 4/17/21.
//  Redesigned on 10/8/25 - Modern UI refresh
//

import SwiftUI

struct scalesAnsView: View {

    @EnvironmentObject var viewModel: scalesViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingKeyboard = false

    var body: some View {
        VStack(spacing: 0) {

            // Note input section
            VStack(spacing: Spacing.md) {
                Button(action: {
                    withAnimation(AppAnimation.quickSpring) {
                        showingKeyboard.toggle()
                    }
                    HapticManager.shared.lightImpact()
                }) {
                    HStack {
                        Text(viewModel.root.isEmpty ? "Root Note" : viewModel.root)
                            .foregroundColor(viewModel.root.isEmpty ? Color.black.opacity(0.4) : .textOnLight)
                            .font(.noteName)

                        Spacer()

                        Image(systemName: showingKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
                            .foregroundColor(.textOnLight)
                    }
                    .padding(Spacing.contentPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                            .fill(Color.white.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                                    .stroke(Color.black.opacity(0.4), lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Custom note keyboard (shown when active)
                if showingKeyboard {
                    ScaleNotePickerKeyboard(noteText: $viewModel.root)
                        .transition(.slideFromBottom)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.md)

            // Scale Type - Single horizontal scroll with all options
            if !viewModel.root.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Scale Type")
                        .font(.caption)
                        .foregroundColor(.textOnLight)
                        .padding(.horizontal, Spacing.screenPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            // Common scales
                            ScaleTypeButton(label: "Major", isActive: viewModel.major) {
                                viewModel.resetButtons()
                                viewModel.major = true
                            }
                            ScaleTypeButton(label: "Natural Minor", isActive: viewModel.minorNat) {
                                viewModel.resetButtons()
                                viewModel.minorNat = true
                            }
                            ScaleTypeButton(label: "Harmonic Minor", isActive: viewModel.minorHarm) {
                                viewModel.resetButtons()
                                viewModel.minorHarm = true
                            }
                            ScaleTypeButton(label: "Melodic Minor", isActive: viewModel.minorMel) {
                                viewModel.resetButtons()
                                viewModel.minorMel = true
                            }

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.3))

                            // Modes
                            ScaleTypeButton(label: "Dorian", isActive: viewModel.dorian) {
                                viewModel.resetButtons()
                                viewModel.dorian = true
                            }
                            ScaleTypeButton(label: "Phrygian", isActive: viewModel.phrygian) {
                                viewModel.resetButtons()
                                viewModel.phrygian = true
                            }
                            ScaleTypeButton(label: "Lydian", isActive: viewModel.lydian) {
                                viewModel.resetButtons()
                                viewModel.lydian = true
                            }
                            ScaleTypeButton(label: "Mixolydian", isActive: viewModel.mixo) {
                                viewModel.resetButtons()
                                viewModel.mixo = true
                            }
                            ScaleTypeButton(label: "Locrian", isActive: viewModel.locrian) {
                                viewModel.resetButtons()
                                viewModel.locrian = true
                            }

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.3))

                            // Special scales
                            ScaleTypeButton(label: "Pentatonic", isActive: viewModel.pentatonic) {
                                viewModel.resetButtons()
                                viewModel.pentatonic = true
                            }
                            ScaleTypeButton(label: "Whole Tone", isActive: viewModel.wholeTone) {
                                viewModel.resetButtons()
                                viewModel.wholeTone = true
                            }
                            ScaleTypeButton(label: "Octatonic", isActive: viewModel.octatonic) {
                                viewModel.resetButtons()
                                viewModel.octatonic = true
                            }

                            Divider()
                                .frame(height: 30)
                                .background(Color.white.opacity(0.3))

                            // Jazz scales
                            ScaleTypeButton(label: "Phrygian ♮6", isActive: viewModel.dorB2) {
                                viewModel.resetButtons()
                                viewModel.dorB2 = true
                            }
                            ScaleTypeButton(label: "Lydian Augmented", isActive: viewModel.lydianAug) {
                                viewModel.resetButtons()
                                viewModel.lydianAug = true
                            }
                            ScaleTypeButton(label: "Lydian Dominant", isActive: viewModel.lydDom) {
                                viewModel.resetButtons()
                                viewModel.lydDom = true
                            }
                            ScaleTypeButton(label: "Altered", isActive: viewModel.supLoc) {
                                viewModel.resetButtons()
                                viewModel.supLoc = true
                            }
                        }
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.vertical, Spacing.sm)
                    }
                }
                .padding(.top, Spacing.md)
                .transition(.scaleAndFade)
            }

            // Result Display - Scale Notes
            if !viewModel.root.isEmpty && (viewModel.major || viewModel.minorNat || viewModel.minorHarm ||
                viewModel.minorMel || viewModel.dorian || viewModel.phrygian || viewModel.lydian ||
                viewModel.mixo || viewModel.locrian || viewModel.pentatonic || viewModel.wholeTone ||
                viewModel.octatonic || viewModel.dorB2 || viewModel.lydianAug || viewModel.lydDom || viewModel.supLoc) {

                Spacer()

                VStack(spacing: Spacing.md) {
                    Text(getScaleLabel())
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    if viewModel.pentatonic {
                        // Pentatonic scale (5 notes)
                        VStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.returnRoot())
                                ScaleNoteCard(note: viewModel.two())
                                ScaleNoteCard(note: viewModel.three())
                            }
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.five())
                                ScaleNoteCard(note: viewModel.six())
                            }
                        }
                    } else if viewModel.wholeTone {
                        // Whole tone scale (6 notes)
                        VStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.returnRoot())
                                ScaleNoteCard(note: viewModel.two())
                                ScaleNoteCard(note: viewModel.three())
                            }
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.four())
                                ScaleNoteCard(note: viewModel.five())
                                ScaleNoteCard(note: viewModel.six())
                            }
                        }
                    } else if viewModel.octatonic {
                        // Octatonic scale (8 notes)
                        VStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.returnRoot())
                                ScaleNoteCard(note: viewModel.two())
                                ScaleNoteCard(note: viewModel.three())
                                ScaleNoteCard(note: viewModel.four())
                            }
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.octFive())
                                ScaleNoteCard(note: viewModel.octSix())
                                ScaleNoteCard(note: viewModel.octSev())
                                ScaleNoteCard(note: viewModel.octEight())
                            }
                        }
                    } else {
                        // Standard 7-note scales
                        VStack(spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.returnRoot())
                                ScaleNoteCard(note: viewModel.two())
                                ScaleNoteCard(note: viewModel.three())
                                ScaleNoteCard(note: viewModel.four())
                            }
                            HStack(spacing: Spacing.sm) {
                                ScaleNoteCard(note: viewModel.five())
                                ScaleNoteCard(note: viewModel.six())
                                ScaleNoteCard(note: viewModel.sev())
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                        .fill(Color.brandPurple)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xxl)
                .transition(.scaleAndFade)

                Spacer()
            }
        }
    }

    private func getScaleLabel() -> String {
        let root = viewModel.root

        if viewModel.major {
            return "\(root) Major"
        } else if viewModel.minorNat {
            return "\(root) Natural Minor"
        } else if viewModel.minorHarm {
            return "\(root) Harmonic Minor"
        } else if viewModel.minorMel {
            return "\(root) Melodic Minor"
        } else if viewModel.dorian {
            return "\(root) Dorian"
        } else if viewModel.phrygian {
            return "\(root) Phrygian"
        } else if viewModel.lydian {
            return "\(root) Lydian"
        } else if viewModel.mixo {
            return "\(root) Mixolydian"
        } else if viewModel.locrian {
            return "\(root) Locrian"
        } else if viewModel.pentatonic {
            return "\(root) Pentatonic"
        } else if viewModel.wholeTone {
            return "\(root) Whole Tone"
        } else if viewModel.octatonic {
            return "\(root) Octatonic"
        } else if viewModel.dorB2 {
            return "\(root) Phrygian ♮6"
        } else if viewModel.lydianAug {
            return "\(root) Lydian Augmented"
        } else if viewModel.lydDom {
            return "\(root) Lydian Dominant"
        } else if viewModel.supLoc {
            return "\(root) Altered"
        }

        return "Scale Notes"
    }
}

// MARK: - Scale Type Button Component

struct ScaleTypeButton: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.mediumImpact()
        }) {
            Text(label)
                .font(.buttonLabel)
                .foregroundColor(isActive ? .textOnLight : .textOnLight)
                .padding(.horizontal, Spacing.contentPadding)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                        .fill(isActive ? Color.lightTintPurple : Color.white.opacity(0.5))
                        .shadow(color: Color.white.opacity(isActive ? 0.5 : 0.3), radius: isActive ? 6 : 4, x: 0, y: isActive ? 3 : 2)
                )
                .scaleEffect(isActive ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(AppAnimation.quickSpring, value: isActive)
    }
}

// MARK: - Scale Note Card Component

struct ScaleNoteCard: View {
    let note: String
    @State private var appeared = false

    var body: some View {
        Text(note)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundColor(.brandPurple)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(AppAnimation.bouncySpring) {
                    appeared = true
                }
            }
    }
}

// MARK: - Scale Note Picker Keyboard

struct ScaleNotePickerKeyboard: View {
    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: 8) {
            // Natural notes (C D E F G A B)
            HStack(spacing: 6) {
                ForEach(naturalNotes, id: \.self) { note in
                    ScaleNoteButton(label: note, isPressed: pressedButton == note, isSelected: noteText.starts(with: note)) {
                        appendNote(note)
                    }
                }
            }

            // Accidentals (# b) and backspace
            HStack(spacing: 6) {
                ScaleNoteButton(label: "♯", isPressed: pressedButton == "♯", isSelected: noteText.contains("#"), backgroundColor: Color.white.opacity(0.3)) {
                    appendAccidental("#")
                }

                ScaleNoteButton(label: "♭", isPressed: pressedButton == "♭", isSelected: noteText.contains("b"), backgroundColor: Color.white.opacity(0.3)) {
                    appendAccidental("b")
                }

                Spacer()

                ScaleNoteButton(label: "⌫", isPressed: pressedButton == "⌫", backgroundColor: Color.pastelRed) {
                    backspace()
                }
            }
        }
    }

    private func appendNote(_ note: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            noteText = note
        }
        pressedButton = note
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func appendAccidental(_ accidental: String) {
        if !noteText.isEmpty {
            let hasSharp = noteText.contains("#")
            let hasFlat = noteText.contains("b")

            // If switching between sharps and flats, replace all existing accidentals with one of the new type
            if (accidental == "#" && hasFlat) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // Remove all flats and add one sharp
                    noteText = String(noteText.filter { $0 != "b" }) + "#"
                }
            } else if (accidental == "b" && hasSharp) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // Remove all sharps and add one flat
                    noteText = String(noteText.filter { $0 != "#" }) + "b"
                }
            } else if noteText.filter({ $0 == "#" || $0 == "b" }).count < 3 {
                // Same accidental type, just append if under limit
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    noteText += accidental
                }
            }
        }
        pressedButton = accidental == "#" ? "♯" : "♭"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func backspace() {
        if !noteText.isEmpty {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                noteText.removeLast()
            }
        }
        pressedButton = "⌫"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
}

// MARK: - Scale Note Button

struct ScaleNoteButton: View {
    let label: String
    let isPressed: Bool
    var isSelected: Bool = false
    var backgroundColor: Color = Color.white.opacity(0.5)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isSelected ? .textOnLight : .textOnLight)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.lightTintPurple : backgroundColor)
                        .shadow(color: Color.black.opacity(isPressed ? 0.3 : 0.15), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct scalesAnsView_Previews: PreviewProvider {
    static var previews: some View {
        scalesAnsView()
    }
}
