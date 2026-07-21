//
//  InputTriadAns.swift
//  ChordSolver (iOS)
//
//  Created by Dylan Shade on 4/12/21.
//

import SwiftUI

struct InputTriadAns: View {

    var remove: (() -> Void)? = nil

    @EnvironmentObject var viewModel: triadBuildViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var showingKeyboard = false
    @State private var showMoreQualities = false
    @State private var rootCollapseWorkItem: DispatchWorkItem?

    private var hasQualitySelected: Bool {
        viewModel.major || viewModel.minor || viewModel.aug || viewModel.dim ||
        viewModel.MM7 || viewModel.Mm7 || viewModel.mm7 || viewModel.hd7 || viewModel.fd7 || viewModel.mM7 ||
        viewModel.sus2 || viewModel.sus4 || viewModel.itA6 || viewModel.frA6 || viewModel.gerA6 || viewModel.ct7
    }

    private var showResult: Bool {
        !viewModel.root.isEmpty && hasQualitySelected
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.root.isEmpty {
                    InputCoachingLine(text: "Choose a root, then a quality")
                }

                RootNoteField(
                    placeholder: "Root Note",
                    root: viewModel.root,
                    isKeyboardVisible: showingKeyboard,
                    accentTint: .brandCoral,
                    onToggleKeyboard: {
                        withAnimation(AppAnimation.quickSpring) {
                            showingKeyboard.toggle()
                        }
                        HapticManager.shared.lightImpact()
                    },
                    onClear: {
                        withAnimation(AppAnimation.quickSpring) {
                            viewModel.root = ""
                            showingKeyboard = false
                        }
                    }
                )
                .padding(.top, Spacing.md)

                if showingKeyboard {
                    TriadNotePickerKeyboard(noteText: $viewModel.root)
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.top, Spacing.sm)
                        .transition(.slideFromBottom)
                }

                if !viewModel.root.isEmpty {
                    GroupedOptionPicker(
                        sectionTitle: "Chord Quality",
                        common: commonQualityOptions,
                        moreGroups: moreQualityGroups,
                        activeFill: .brandCoral,
                        selectedAccent: .brandCoral,
                        showMore: $showMoreQualities
                    )
                    .padding(.top, Spacing.md)
                    .transition(.scaleAndFade)
                }

                if showResult {
                    AnswerResultPanel(title: getChordLabel(), accent: .brandCoral) {
                        chordNotesRow
                    }
                }

                Spacer(minLength: Spacing.xxxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.root) { _, newValue in
            scheduleKeyboardCollapseIfNeeded(root: newValue)
        }
    }

    // MARK: - Quality options

    private var commonQualityOptions: [ChipOption] {
        [
            chip("major", "Major", nil, viewModel.major) { select { $0.major = true } },
            chip("minor", "Minor", nil, viewModel.minor) { select { $0.minor = true } },
            chip("aug", "Aug", "+", viewModel.aug) { select { $0.aug = true } },
            chip("dim", "Dim", "°", viewModel.dim) { select { $0.dim = true } },
        ]
    }

    private var moreQualityGroups: [(title: String, options: [ChipOption])] {
        [
            (
                "Sevenths",
                [
                    chip("mm7full", "Major 7", "MM7", viewModel.MM7) { select { $0.MM7 = true } },
                    chip("dom7", "Dom 7", "Mm7", viewModel.Mm7) { select { $0.Mm7 = true } },
                    chip("min7", "Minor 7", "mm7", viewModel.mm7) { select { $0.mm7 = true } },
                    chip("hd7", "Half-dim 7", "ø7", viewModel.hd7) { select { $0.hd7 = true } },
                    chip("fd7", "Fully dim 7", "°7", viewModel.fd7) { select { $0.fd7 = true } },
                    chip("mM7", "Min-Maj 7", "mM7", viewModel.mM7) { select { $0.mM7 = true } },
                ]
            ),
            (
                "Suspended",
                [
                    chip("sus2", "Sus2", nil, viewModel.sus2) { select { $0.sus2 = true } },
                    chip("sus4", "Sus4", nil, viewModel.sus4) { select { $0.sus4 = true } },
                ]
            ),
            (
                "Augmented 6ths & CT",
                [
                    chip("it6", "Italian +6", "It+6", viewModel.itA6) { select { $0.itA6 = true } },
                    chip("fr6", "French +6", "Fr+6", viewModel.frA6) { select { $0.frA6 = true } },
                    chip("ger6", "German +6", "Ger+6", viewModel.gerA6) { select { $0.gerA6 = true } },
                    chip("ct7", "CT °7", "CT°7", viewModel.ct7) { select { $0.ct7 = true } },
                ]
            ),
        ]
    }

    private func chip(
        _ id: String,
        _ title: String,
        _ detail: String?,
        _ isActive: Bool,
        action: @escaping () -> Void
    ) -> ChipOption {
        ChipOption(id: id, title: title, detail: detail, isActive: isActive, action: action)
    }

    private func select(_ mutate: (triadBuildViewModel) -> Void) {
        withAnimation(AppAnimation.quickSpring) {
            viewModel.resetButtons()
            mutate(viewModel)
            showingKeyboard = false
            // Always collapse advanced; selection is pinned into the preview tiles.
            showMoreQualities = false
        }
    }

    private func scheduleKeyboardCollapseIfNeeded(root: String) {
        rootCollapseWorkItem?.cancel()
        guard !root.isEmpty else { return }
        let work = DispatchWorkItem {
            withAnimation(AppAnimation.quickSpring) {
                showingKeyboard = false
            }
        }
        rootCollapseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
    }

    // MARK: - Notes + intervals (aligned under each tone)

    /// Note name paired with its interval from the chord root (or role label for special stacks).
    private var chordTones: [(note: String, interval: String)] {
        if viewModel.itA6 {
            // Spelling order for +6: ♭6 – 1 – ♯4
            return [
                (viewModel.find6th(), "m6"),
                (viewModel.returnRoot(), "R"),
                (viewModel.find4th(), "A4"),
            ]
        }
        if viewModel.gerA6 {
            return [
                (viewModel.find6th(), "m6"),
                (viewModel.returnRoot(), "R"),
                (viewModel.augSpic(), "M3"),
                (viewModel.find4th(), "A4"),
            ]
        }
        if viewModel.frA6 {
            return [
                (viewModel.find6th(), "m6"),
                (viewModel.returnRoot(), "R"),
                (viewModel.augSpic2(), "M2"),
                (viewModel.find4th(), "A4"),
            ]
        }
        if viewModel.sus2 {
            return [
                (viewModel.returnRoot(), "R"),
                (viewModel.sus2nd(), "M2"),
                (viewModel.sus2fifth(), "P5"),
            ]
        }
        if viewModel.sus4 {
            return [
                (viewModel.returnRoot(), "R"),
                (viewModel.find4th(), "P4"),
                (viewModel.sus4fifth(), "P5"),
            ]
        }
        if viewModel.ct7 {
            // CT°7: tones around the common-tone root
            return [
                (viewModel.ct2nd(), "A2"),
                (viewModel.ct4th(), "A4"),
                (viewModel.ct6th(), "M6"),
                (viewModel.returnRoot(), "R"),
            ]
        }

        // Standard root-position triads / sevenths — zip notes with interval stack.
        var notes = [
            viewModel.returnRoot(),
            viewModel.triadThird(),
            viewModel.triadFifth(),
        ]
        if viewModel.MM7 || viewModel.Mm7 || viewModel.mm7 || viewModel.fd7 || viewModel.hd7 || viewModel.mM7 {
            notes.append(viewModel.triadSev())
        }
        let intervals = viewModel.chordIntervalStack()
        return zip(notes, intervals).map { (note: $0.0, interval: $0.1) }
    }

    @ViewBuilder
    private var chordNotesRow: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(chordTones.enumerated()), id: \.offset) { _, tone in
                NoteCard(note: tone.note, interval: tone.interval)
            }
        }
    }

    private func getChordLabel() -> String {
        let root = viewModel.root

        if viewModel.major { return "\(root) Major" }
        if viewModel.minor { return "\(root) Minor" }
        if viewModel.aug { return "\(root) Augmented" }
        if viewModel.dim { return "\(root) Diminished" }
        if viewModel.MM7 { return "\(root) Major 7" }
        if viewModel.Mm7 { return "\(root) Dominant 7" }
        if viewModel.mm7 { return "\(root) Minor 7" }
        if viewModel.hd7 { return "\(root) Half Diminished 7" }
        if viewModel.fd7 { return "\(root) Fully Diminished 7" }
        if viewModel.mM7 { return "\(root) Minor Major 7" }
        if viewModel.sus2 { return "\(root) Sus2" }
        if viewModel.sus4 { return "\(root) Sus4" }
        if viewModel.itA6 { return "\(root) Italian +6" }
        if viewModel.frA6 { return "\(root) French +6" }
        if viewModel.gerA6 { return "\(root) German +6" }
        if viewModel.ct7 { return "\(root) Common Tone °7" }
        return "Chord Notes"
    }
}

// MARK: - Note Card Component

/// Chord tone card: large pitch class with quiet interval caption beneath.
struct NoteCard: View {
    let note: String
    /// Compact interval from root (e.g. `R`, `M3`, `P5`). Optional for previews.
    var interval: String? = nil
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 6) {
            Text(note)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity)

            if let interval, !interval.isEmpty {
                Text(interval)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.inkTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel(Self.accessibilityName(for: interval))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: interval == nil ? 80 : 92)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                .fill(Color.surfaceCard)
        )
        .scaleEffect(appeared ? 1.0 : 0.8)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(AppAnimation.bouncySpring) {
                appeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            interval.map { "\(note), \(Self.accessibilityName(for: $0))" } ?? note
        )
    }

    private static func accessibilityName(for label: String) -> String {
        switch label {
        case "R": return "root"
        case "M2": return "major second"
        case "m2": return "minor second"
        case "M3": return "major third"
        case "m3": return "minor third"
        case "P4": return "perfect fourth"
        case "A4": return "augmented fourth"
        case "d5": return "diminished fifth"
        case "P5": return "perfect fifth"
        case "A5": return "augmented fifth"
        case "m6": return "minor sixth"
        case "M6": return "major sixth"
        case "m7": return "minor seventh"
        case "M7": return "major seventh"
        case "d7": return "diminished seventh"
        case "A2": return "augmented second"
        default: return label
        }
    }
}

// Custom Note Picker Keyboard
struct TriadNotePickerKeyboard: View {
    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(naturalNotes, id: \.self) { note in
                    TriadNoteButton(label: note, isPressed: pressedButton == note, isSelected: noteText.starts(with: note)) {
                        appendNote(note)
                    }
                }
            }

            HStack(spacing: 8) {
                TriadNoteButton(label: "♯", isPressed: pressedButton == "♯", isSelected: noteText.contains("#"), backgroundColor: Color.white.opacity(0.55)) {
                    appendAccidental("#")
                }

                TriadNoteButton(label: "♭", isPressed: pressedButton == "♭", isSelected: noteText.contains("b"), backgroundColor: Color.white.opacity(0.55)) {
                    appendAccidental("b")
                }

                Spacer(minLength: 12)

                TriadNoteButton(label: "⌫", isPressed: pressedButton == "⌫", backgroundColor: Color.pastelRed.opacity(0.85)) {
                    backspace()
                }
                .frame(maxWidth: 88)
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

            if accidental == "#" && hasFlat {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    noteText = String(noteText.filter { $0 != "b" }) + "#"
                }
            } else if accidental == "b" && hasSharp {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    noteText = String(noteText.filter { $0 != "#" }) + "b"
                }
            } else if noteText.filter({ $0 == "#" || $0 == "b" }).count < 3 {
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

struct TriadNoteButton: View {
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
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.lightTintCoral : backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    isSelected ? Color.brandCoral.opacity(0.7) : Color.black.opacity(0.1),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InputTriadAns_Previews: PreviewProvider {
    static var previews: some View {
        InputTriadAns()
            .environmentObject(triadBuildViewModel())
    }
}
