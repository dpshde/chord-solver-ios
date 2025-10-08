//
//  IntervalView.swift
//  Chord Solver
//
//  Created by Dylan Shade on 4/7/21.
//  Redesigned on 10/8/25 - Modern UI refresh
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
        VStack(spacing: 0) {

            // Input section
            VStack(spacing: Spacing.xl) {
                // Bottom Note Input
                VStack(spacing: Spacing.sm) {
                    HStack {
//                        Image(systemName: "arrow.down.circle.fill")
//                            .font(.title3)
//                            .foregroundColor(.textOnLight)
                        Text("Bottom Note")
                            .font(.headline)
                            .foregroundColor(.textOnLight)
                        Spacer()
                    }

                    Button(action: {
                        withAnimation(AppAnimation.quickSpring) {
                            showBottomKeyboard.toggle()
                            showTopKeyboard = false
                        }
                        HapticManager.shared.lightImpact()
                    }) {
                        HStack {
                            Text(bottomNote.isEmpty ? "Tap to enter" : bottomNote)
                                .foregroundColor(bottomNote.isEmpty ? Color.black.opacity(0.4) : .textOnLight)
                                .font(.noteName)

                            Spacer()

                            Image(systemName: showBottomKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
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

                    // Custom keyboard for bottom note
                    if showBottomKeyboard {
                        IntervalNoteKeyboard(noteText: $bottomNote)
                            .transition(.slideFromBottom)
                    }
                }

                // Visual separator
                HStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 2)

                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundColor(.textOnLight)
                        .padding(.horizontal, Spacing.sm)

                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 2)
                }
                .padding(.horizontal, Spacing.screenPadding)

                // Top Note Input
                VStack(spacing: Spacing.sm) {
                    HStack {
//                        Image(systemName: "arrow.up.circle.fill")
//                            .font(.title3)
//                            .foregroundColor(.textOnLight)
                        Text("Top Note")
                            .font(.headline)
                            .foregroundColor(.textOnLight)
                        Spacer()
                    }

                    Button(action: {
                        withAnimation(AppAnimation.quickSpring) {
                            showTopKeyboard.toggle()
                            showBottomKeyboard = false
                        }
                        HapticManager.shared.lightImpact()
                    }) {
                        HStack {
                            Text(topNote.isEmpty ? "Tap to enter" : topNote)
                                .foregroundColor(topNote.isEmpty ? Color.black.opacity(0.4) : .textOnLight)
                                .font(.noteName)

                            Spacer()

                            Image(systemName: showTopKeyboard ? "keyboard.chevron.compact.down" : "keyboard")
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

                    // Custom keyboard for top note
                    if showTopKeyboard {
                        IntervalNoteKeyboard(noteText: $topNote)
                            .transition(.slideFromBottom)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.md)

            // Result at bottom (like chord/scale screens)
            if !intervalResult.isEmpty {
                Spacer()

                VStack(spacing: Spacing.lg) {
                    Text(getIntervalLabel())
                        .font(.bodyRegular)
                        .foregroundColor(.textOnLight)

                    Text(intervalResult)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                                .fill(Color.brandAqua)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xxl)
                .transition(.scaleAndFade)

                Spacer()
            } else {
                Spacer()
            }
        }
        .onChange(of: bottomNote) { _ in
            calculateIntervalIfReady()
        }
        .onChange(of: topNote) { _ in
            calculateIntervalIfReady()
        }
    }

    private func calculateIntervalIfReady() {
        // Auto-calculate when both notes are entered
        if !bottomNote.isEmpty && !topNote.isEmpty {
            // Small delay to allow for smooth typing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !bottomNote.isEmpty && !topNote.isEmpty {
                    calculateInterval()
                    // Close keyboards when result is shown
                    withAnimation(AppAnimation.quickSpring) {
                        showBottomKeyboard = false
                        showTopKeyboard = false
                    }
                    HapticManager.shared.success()
                }
            }
        } else {
            // Clear result if either note is removed
            intervalResult = ""
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

    private func getIntervalLabel() -> String {
        if bottomNote.isEmpty || topNote.isEmpty {
            return "Interval"
        }
        return "\(bottomNote) → \(topNote)"
    }
}

// MARK: - Custom Interval Note Keyboard

struct IntervalNoteKeyboard: View {
    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: 8) {
            // Natural notes
            HStack(spacing: 6) {
                ForEach(naturalNotes, id: \.self) { note in
                    IntervalNoteButton(label: note, isPressed: pressedButton == note, isSelected: noteText.starts(with: note)) {
                        appendNote(note)
                    }
                }
            }

            // Accidentals and backspace
            HStack(spacing: 6) {
                IntervalNoteButton(label: "♯", isPressed: pressedButton == "♯", isSelected: noteText.contains("#"), backgroundColor: Color.white.opacity(0.3)) {
                    appendAccidental("#")
                }

                IntervalNoteButton(label: "♭", isPressed: pressedButton == "♭", isSelected: noteText.contains("b"), backgroundColor: Color.white.opacity(0.3)) {
                    appendAccidental("b")
                }

                Spacer()

                IntervalNoteButton(label: "⌫", isPressed: pressedButton == "⌫", backgroundColor: Color.brandAqua.opacity(0.3)) {
                    backspace()
                }
            }
        }
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

// Note: IntervalNoteButton is defined in InputAnsView.swift and reused here

struct IntervalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IntervalView()
                .preferredColorScheme(.light)
        }
    }
}
