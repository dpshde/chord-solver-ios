//
//  InputAnsView.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Input view for interval calculator
//  Updated 10/8/25 - Added custom note picker keyboards
//

import SwiftUI

struct InputView: View {

    @ObservedObject var viewModel: AnsViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingBottomKeyboard = false
    @State private var showingTopKeyboard = false

    var body: some View {
        VStack(spacing: 16) {

            // Bottom note input
            Button(action: {
                showingTopKeyboard = false
                withAnimation(AppAnimation.smoothSpring) {
                    showingBottomKeyboard.toggle()
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                ZStack {
                    Spacing.shapeSmall
                        .foregroundColor(.white)
                        .frame(maxWidth: 350, maxHeight: 50)

                    Text(viewModel.bottom.isEmpty ? "Bottom note" : viewModel.bottom)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(viewModel.bottom.isEmpty ? .gray.opacity(0.6) : .black)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Bottom note keyboard
            if showingBottomKeyboard {
                IntervalNotePickerKeyboard(noteText: $viewModel.bottom)
                    .frame(height: 180)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Top note input
            Button(action: {
                showingBottomKeyboard = false
                withAnimation(AppAnimation.smoothSpring) {
                    showingTopKeyboard.toggle()
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                ZStack {
                    Spacing.shapeSmall
                        .foregroundColor(.white)
                        .frame(maxWidth: 350, maxHeight: 50)

                    Text(viewModel.top.isEmpty ? "Top note" : viewModel.top)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(viewModel.top.isEmpty ? .gray.opacity(0.6) : .black)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Top note keyboard
            if showingTopKeyboard {
                IntervalNotePickerKeyboard(noteText: $viewModel.top)
                    .frame(height: 180)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()

            // Result display
            VStack {
                Text(viewModel.answerInt())
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(minWidth: 0, idealWidth: 100, maxWidth: .infinity, minHeight: 0, idealHeight: 100, maxHeight: .infinity, alignment: .center)
            .animation(.easeInOut, value: viewModel.answerInt())
        }
        .padding()
    }
}

// MARK: - Interval Note Picker Keyboard
struct IntervalNotePickerKeyboard: View {

    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]
    private let accidentals = ["♯", "♭", "×", "♮"]

    var body: some View {
        VStack(spacing: 12) {

            // Display current input (use ⌫ on the pad to edit)
            Text(noteText.isEmpty ? "Tap notes below" : noteText)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundColor(noteText.isEmpty ? .white.opacity(0.5) : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    Spacing.shapeSmall
                        .fill(Color.white.opacity(0.1))
                )

            // Natural notes (C D E F G A B)
            HStack(spacing: 8) {
                ForEach(naturalNotes, id: \.self) { note in
                    IntervalNoteButton(
                        label: note,
                        isPressed: pressedButton == note
                    ) {
                        appendNote(note)
                    }
                }
            }

            // Accidentals (# b)
            HStack(spacing: 8) {
                IntervalNoteButton(
                    label: "♯",
                    isPressed: pressedButton == "♯",
                    backgroundColor: Color.white.opacity(0.15)
                ) {
                    appendAccidental("#")
                }

                IntervalNoteButton(
                    label: "♭",
                    isPressed: pressedButton == "♭",
                    backgroundColor: Color.white.opacity(0.15)
                ) {
                    appendAccidental("b")
                }

                Spacer()

                // Backspace button
                IntervalNoteButton(
                    label: "⌫",
                    isPressed: pressedButton == "⌫",
                    backgroundColor: Color.pastelRed
                ) {
                    backspace()
                }
            }
        }
        .padding()
    }

    private func appendNote(_ note: String) {
        withAnimation(AppAnimation.quickSpring) {
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

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func backspace() {
        if !noteText.isEmpty {
            withAnimation(AppAnimation.quickSpring) {
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

// MARK: - Interval Note Button
struct IntervalNoteButton: View {
    let label: String
    let isPressed: Bool
    var isSelected: Bool = false
    var backgroundColor: Color = Color.white.opacity(0.72)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.textOnLight)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(
                    Spacing.shapeSmall
                        .fill(isSelected ? Color.lightTintAqua : backgroundColor)
                        .overlay(
                            Spacing.shapeSmall
                                .strokeBorder(
                                    isSelected ? Color.brandAqua.opacity(0.7) : Color.black.opacity(0.1),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        InputView(viewModel: AnsViewModel())
            .background(Color(red: 0.62, green: 0.85, blue: 0.87).ignoresSafeArea())
    }
}
