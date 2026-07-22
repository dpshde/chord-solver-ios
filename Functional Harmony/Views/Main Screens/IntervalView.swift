//
//  IntervalView.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/7/21.
//  Redesigned on 10/8/25 - Modern UI refresh
//

import SwiftUI

/// Which interval note field is active for the shared keyboard.
enum IntervalNoteFocus: Equatable {
    case lower
    case upper
}

struct IntervalView: View {

    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var session: IntervalSessionState
    @State private var focus: IntervalNoteFocus? = nil
    @State private var calcWorkItem: DispatchWorkItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if session.bottomNote.isEmpty && session.topNote.isEmpty {
                    InputCoachingLine(text: "Lower note → higher note")
                }

                VStack(spacing: Spacing.lg) {
                    // Lower note
                    intervalField(
                        title: "Lower note",
                        note: session.bottomNote,
                        isFocused: focus == .lower
                    ) {
                        withAnimation(AppAnimation.quickSpring) {
                            focus = focus == .lower ? nil : .lower
                        }
                        HapticManager.shared.lightImpact()
                    }

                    if focus == .lower {
                        IntervalNoteKeyboard(noteText: $session.bottomNote)
                            .transition(.slideFromBottom)
                    }

                    // Between fields: result or arrow
                    if !session.intervalResult.isEmpty {
                        AnswerResultPanel(title: getIntervalLabel(), accent: .brandAqua) {
                            Text(session.intervalResult)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.5)
                        }
                    } else {
                        HStack {
                            Rectangle()
                                .fill(Color.black.opacity(0.15))
                                .frame(height: 2)
                            Image(systemName: "arrow.down")
                                .font(.title3)
                                .foregroundColor(.textOnLight.opacity(0.6))
                                .padding(.horizontal, Spacing.sm)
                            Rectangle()
                                .fill(Color.black.opacity(0.15))
                                .frame(height: 2)
                        }
                    }

                    // Higher note
                    intervalField(
                        title: "Higher note",
                        note: session.topNote,
                        isFocused: focus == .upper
                    ) {
                        withAnimation(AppAnimation.quickSpring) {
                            focus = focus == .upper ? nil : .upper
                        }
                        HapticManager.shared.lightImpact()
                    }

                    if focus == .upper {
                        IntervalNoteKeyboard(noteText: $session.topNote)
                            .transition(.slideFromBottom)
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.md)

                Spacer(minLength: Spacing.xxxl)
            }
        }
        .onChange(of: session.bottomNote) { old, new in
            handleNoteChange(old: old, new: new, justFinished: .lower)
        }
        .onChange(of: session.topNote) { old, new in
            handleNoteChange(old: old, new: new, justFinished: .upper)
        }
    }

    @ViewBuilder
    private func intervalField(
        title: String,
        note: String,
        isFocused: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textOnLight)

            Button(action: onTap) {
                HStack {
                    Text(note.isEmpty ? "Note" : note)
                        .foregroundColor(note.isEmpty ? .inkTertiary : .inkPrimary)
                        .font(.noteName)

                    Spacer()

                    Image(systemName: isFocused ? "keyboard.chevron.compact.down" : "keyboard")
                        .foregroundColor(isFocused ? .brandAqua : .inkSecondary)
                }
                .padding(.horizontal, Spacing.contentPadding)
                .frame(minHeight: 56)
                .background(
                    Spacing.shapeSmall
                        .fill(Color.surfaceCard)
                        .overlay(
                            Spacing.shapeSmall
                                .strokeBorder(
                                    isFocused ? Color.brandAqua : Color.borderStrong,
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("\(title), \(note.isEmpty ? "empty" : note)")
        }
    }

    private func handleNoteChange(old: String, new: String, justFinished: IntervalNoteFocus) {
        // After setting a natural note (or completing lower), advance focus once.
        if old.isEmpty && !new.isEmpty && justFinished == .lower {
            // Allow accidentals briefly, then advance to upper.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard !session.bottomNote.isEmpty, focus == .lower else { return }
                withAnimation(AppAnimation.quickSpring) {
                    focus = .upper
                }
            }
        } else if !new.isEmpty && justFinished == .upper {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard !session.topNote.isEmpty, focus == .upper else { return }
                withAnimation(AppAnimation.quickSpring) {
                    focus = nil
                }
            }
        }

        scheduleCalculate()
    }

    private func scheduleCalculate() {
        calcWorkItem?.cancel()
        let work = DispatchWorkItem {
            calculateIntervalIfReady()
        }
        calcWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    private func calculateIntervalIfReady() {
        if !session.bottomNote.isEmpty && !session.topNote.isEmpty {
            calculateInterval()
        } else {
            session.intervalResult = ""
        }
    }

    private func calculateInterval() {
        let interval = Interval(bottom: session.bottomNote, top: session.topNote)
        let result = interval.dToName()
        let resolved = result.isEmpty ? "Invalid interval" : result
        withAnimation(AppAnimation.bouncySpring) {
            session.intervalResult = resolved
        }
        if result.isEmpty {
            HapticManager.shared.lightImpact()
        } else {
            HapticManager.shared.success()
        }
    }

    private func getIntervalLabel() -> String {
        if session.bottomNote.isEmpty || session.topNote.isEmpty {
            return "Interval"
        }
        return "\(session.bottomNote) → \(session.topNote)"
    }
}

// MARK: - Custom Interval Note Keyboard

struct IntervalNoteKeyboard: View {
    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                IntervalNoteButton(label: "♭", isPressed: pressedButton == "♭", isSelected: hasFlatAccidental, backgroundColor: Color.surfaceCard.opacity(0.55)) {
                    appendAccidental("b")
                }
                .opacity(canApplyAccidental ? 1 : 0.45)
                .disabled(!canApplyAccidental)

                IntervalNoteButton(label: "♯", isPressed: pressedButton == "♯", isSelected: hasSharpAccidental, backgroundColor: Color.surfaceCard.opacity(0.55)) {
                    appendAccidental("#")
                }
                .opacity(canApplyAccidental ? 1 : 0.45)
                .disabled(!canApplyAccidental)

                Spacer(minLength: 12)

                IntervalNoteButton(label: "⌫", isPressed: pressedButton == "⌫", backgroundColor: Color.brandAqua.opacity(0.35)) {
                    backspace()
                }
                .frame(maxWidth: 88)
            }

            HStack(spacing: 8) {
                ForEach(naturalNotes, id: \.self) { note in
                    IntervalNoteButton(label: note, isPressed: pressedButton == note, isSelected: noteText.starts(with: note)) {
                        appendNote(note)
                    }
                }
            }
        }
    }

    private var canApplyAccidental: Bool {
        !noteText.isEmpty
    }

    private var accidentalSuffix: String {
        guard noteText.count > 1 else { return "" }
        return String(noteText.dropFirst())
    }

    private var hasSharpAccidental: Bool {
        accidentalSuffix.contains("#") || accidentalSuffix.contains("♯")
    }

    private var hasFlatAccidental: Bool {
        accidentalSuffix.contains("b") || accidentalSuffix.contains("♭")
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
        guard !noteText.isEmpty else {
            pressedButton = accidental == "#" ? "♯" : "♭"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { pressedButton = nil }
            HapticManager.shared.lightImpact()
            return
        }

        let letter = String(noteText.prefix(1))
        var marks: [Character] = Array(
            accidentalSuffix
                .replacingOccurrences(of: "♯", with: "#")
                .replacingOccurrences(of: "♭", with: "b")
                .filter { $0 == "#" || $0 == "b" }
        )

        if accidental == "#" {
            if marks.contains("b") {
                marks = ["#"]
            } else if marks.filter({ $0 == "#" }).count < 3 {
                marks.append("#")
            }
        } else {
            if marks.contains("#") {
                marks = ["b"]
            } else if marks.filter({ $0 == "b" }).count < 3 {
                marks.append("b")
            }
        }

        withAnimation(AppAnimation.quickSpring) {
            noteText = letter + String(marks)
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

struct IntervalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IntervalView()
                .environmentObject(IntervalSessionState())
                .preferredColorScheme(.light)
        }
    }
}
