//
//  NotePickerKeyboard.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Custom keyboard for note input
//

import SwiftUI

struct NotePickerKeyboard: View {

    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]
    private let accidentals = ["♯", "♭", "×", "♮"]  // Sharp, Flat, Double-sharp, Natural

    var body: some View {
        VStack(spacing: 12) {

            // Display current input
            HStack {
                Text(noteText.isEmpty ? "Tap notes below" : noteText)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(noteText.isEmpty ? .white.opacity(0.5) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Clear button
                if !noteText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            noteText = ""
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )

            // Natural notes (C D E F G A B)
            HStack(spacing: 8) {
                ForEach(naturalNotes, id: \.self) { note in
                    NoteButton(
                        label: note,
                        isPressed: pressedButton == note
                    ) {
                        appendNote(note)
                    }
                }
            }

            // Accidentals (# b)
            HStack(spacing: 8) {
                NoteButton(
                    label: "♯",
                    isPressed: pressedButton == "♯",
                    backgroundColor: Color.white.opacity(0.15)
                ) {
                    appendAccidental("#")
                }

                NoteButton(
                    label: "♭",
                    isPressed: pressedButton == "♭",
                    backgroundColor: Color.white.opacity(0.15)
                ) {
                    appendAccidental("b")
                }

                Spacer()

                // Backspace button
                NoteButton(
                    label: "⌫",
                    isPressed: pressedButton == "⌫",
                    backgroundColor: Color.red.opacity(0.3)
                ) {
                    backspace()
                }
            }
        }
        .padding()
    }

    private func appendNote(_ note: String) {
        // Reset when adding a new natural note
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // If the current note text is complete, start fresh
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
        // Only add accidental if there's a natural note and not too many accidentals
        if !noteText.isEmpty && noteText.filter({ $0 == "#" || $0 == "b" }).count < 3 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                noteText += accidental
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

// Custom Note Button
struct NoteButton: View {
    let label: String
    let isPressed: Bool
    var backgroundColor: Color = Color.white.opacity(0.2)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .shadow(
                            color: Color.black.opacity(isPressed ? 0.3 : 0.1),
                            radius: isPressed ? 2 : 4,
                            x: 0,
                            y: isPressed ? 1 : 2
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Preview
struct NotePickerKeyboard_Previews: PreviewProvider {
    @State static var noteText = "C#"

    static var previews: some View {
        VStack {
            Spacer()
            NotePickerKeyboard(noteText: $noteText)
                .background(Color(red: 1.0, green: 0.44, blue: 0.44))
        }
        .background(Color(red: 1.0, green: 0.44, blue: 0.44).ignoresSafeArea())
    }
}
