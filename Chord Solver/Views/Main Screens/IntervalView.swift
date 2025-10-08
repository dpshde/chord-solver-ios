//
//  IntervalView.swift
//  Chord Solver
//
//  Created by Dylan Shade on 4/7/21.
//  Redesigned on 10/8/25 - Custom UI
//

import SwiftUI

struct IntervalView: View {

    @Environment(\.colorScheme) var colorScheme
    @State private var bottomNote: String = ""
    @State private var topNote: String = ""
    @State private var showBottomKeyboard = false
    @State private var showTopKeyboard = false
    @State private var intervalResult: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {

                Spacer().frame(height: Spacing.xl)

                // Instructions
                Text("Enter two notes to find the interval")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, Spacing.screenPadding)

                // Bottom Note Input
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Bottom Note")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Button(action: {
                        withAnimation(AppAnimation.quickSpring) {
                            showBottomKeyboard.toggle()
                            showTopKeyboard = false
                        }
                        HapticManager.shared.lightImpact()
                    }) {
                        HStack {
                            Text(bottomNote.isEmpty ? "Tap to enter" : bottomNote)
                                .foregroundColor(bottomNote.isEmpty ? .textTertiary : .textPrimary)
                                .font(.noteName)

                            Spacer()

                            Image(systemName: showBottomKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
                                .foregroundColor(.textSecondary)
                        }
                        .padding(Spacing.contentPadding)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                                .fill(Color.white.opacity(0.25))
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, Spacing.screenPadding)

                // Custom keyboard for bottom note
                if showBottomKeyboard {
                    IntervalNoteKeyboard(noteText: $bottomNote)
                        .transition(.slideFromBottom)
                        .padding(.horizontal, Spacing.screenPadding)
                }

                // Top Note Input
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Top Note")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    Button(action: {
                        withAnimation(AppAnimation.quickSpring) {
                            showTopKeyboard.toggle()
                            showBottomKeyboard = false
                        }
                        HapticManager.shared.lightImpact()
                    }) {
                        HStack {
                            Text(topNote.isEmpty ? "Tap to enter" : topNote)
                                .foregroundColor(topNote.isEmpty ? .textTertiary : .textPrimary)
                                .font(.noteName)

                            Spacer()

                            Image(systemName: showTopKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
                                .foregroundColor(.textSecondary)
                        }
                        .padding(Spacing.contentPadding)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                                .fill(Color.white.opacity(0.25))
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, Spacing.screenPadding)

                // Custom keyboard for top note
                if showTopKeyboard {
                    IntervalNoteKeyboard(noteText: $topNote)
                        .transition(.slideFromBottom)
                        .padding(.horizontal, Spacing.screenPadding)
                }

                // Calculate Button
                if !bottomNote.isEmpty && !topNote.isEmpty {
                    Button(action: {
                        calculateInterval()
                        HapticManager.shared.success()
                    }) {
                        Text("Calculate Interval")
                            .font(.buttonLabel)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.contentPadding)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                                    .fill(Color.white.opacity(0.3))
                            )
                    }
                    .padding(.horizontal, Spacing.screenPadding)
                    .transition(.scaleAndFade)
                }

                // Result Display
                if !intervalResult.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Text("Interval")
                            .font(.caption)
                            .foregroundColor(.textSecondary)

                        Text(intervalResult)
                            .font(.displayMedium)
                            .foregroundColor(.textPrimary)
                            .padding(Spacing.xl)
                            .background(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                                    .fill(Color.white.opacity(0.2))
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.xl)
                    .transition(.scaleAndFade)
                }

                Spacer()
            }
        }
    }

    private func calculateInterval() {
        // Calculate interval between bottom and top notes
        let interval = Interval(bottom: bottomNote, top: topNote)
        let result = interval.dToName()

        withAnimation(AppAnimation.bouncySpring) {
            intervalResult = result.isEmpty ? "Invalid interval" : result
        }
    }
}

// MARK: - Custom Interval Note Keyboard

struct IntervalNoteKeyboard: View {
    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Natural notes
            HStack(spacing: Spacing.xs) {
                ForEach(naturalNotes, id: \.self) { note in
                    IntervalNoteButton(label: note, isPressed: pressedButton == note) {
                        appendNote(note)
                    }
                }
            }

            // Accidentals and backspace
            HStack(spacing: Spacing.xs) {
                IntervalNoteButton(label: "♯", isPressed: pressedButton == "♯", backgroundColor: Color.white.opacity(0.15)) {
                    appendAccidental("#")
                }

                IntervalNoteButton(label: "♭", isPressed: pressedButton == "♭", backgroundColor: Color.white.opacity(0.15)) {
                    appendAccidental("b")
                }

                Spacer()

                IntervalNoteButton(label: "⌫", isPressed: pressedButton == "⌫", backgroundColor: Color.red.opacity(0.3)) {
                    backspace()
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                .fill(Color.white.opacity(0.1))
        )
    }

    private func appendNote(_ note: String) {
        withAnimation(AppAnimation.quickSpring) {
            noteText = note
        }
        pressedButton = note
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        HapticManager.shared.mediumImpact()
    }

    private func appendAccidental(_ accidental: String) {
        if !noteText.isEmpty {
            let hasSharp = noteText.contains("#")
            let hasFlat = noteText.contains("b")

            // If switching between sharps and flats, replace all existing accidentals with one of the new type
            if (accidental == "#" && hasFlat) {
                withAnimation(AppAnimation.quickSpring) {
                    // Remove all flats and add one sharp
                    noteText = String(noteText.filter { $0 != "b" }) + "#"
                }
            } else if (accidental == "b" && hasSharp) {
                withAnimation(AppAnimation.quickSpring) {
                    // Remove all sharps and add one flat
                    noteText = String(noteText.filter { $0 != "#" }) + "b"
                }
            } else if noteText.filter({ $0 == "#" || $0 == "b" }).count < 3 {
                // Same accidental type, just append if under limit
                withAnimation(AppAnimation.quickSpring) {
                    noteText += accidental
                }
            }
        }
        pressedButton = accidental == "#" ? "♯" : "♭"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        HapticManager.shared.lightImpact()
    }

    private func backspace() {
        if !noteText.isEmpty {
            _ = withAnimation(AppAnimation.quickSpring) {
                noteText.removeLast()
            }
        }
        pressedButton = "⌫"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
        HapticManager.shared.rigidImpact()
    }
}

// IntervalNoteButton is now defined in InputAnsView.swift and reused here

struct IntervalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IntervalView()
                .preferredColorScheme(.light)
        }
    }
}

