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
    @State private var showMoreScales = false
    @State private var rootCollapseWorkItem: DispatchWorkItem?

    private var hasScaleSelected: Bool {
        viewModel.major || viewModel.minorNat || viewModel.minorHarm ||
        viewModel.minorMel || viewModel.dorian || viewModel.phrygian || viewModel.lydian ||
        viewModel.mixo || viewModel.locrian || viewModel.pentatonic || viewModel.wholeTone ||
        viewModel.octatonic || viewModel.dorB2 || viewModel.lydianAug || viewModel.lydDom || viewModel.supLoc
    }

    private var showResult: Bool {
        !viewModel.root.isEmpty && hasScaleSelected
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.root.isEmpty {
                    InputCoachingLine(text: "Choose a root, then a scale type")
                }

                RootNoteField(
                    placeholder: "Root Note",
                    root: viewModel.root,
                    isKeyboardVisible: showingKeyboard,
                    accentTint: .brandPurple,
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
                    ScaleNotePickerKeyboard(noteText: $viewModel.root)
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.top, Spacing.sm)
                        .transition(.slideFromBottom)
                }

                if !viewModel.root.isEmpty {
                    GroupedOptionPicker(
                        sectionTitle: "Scale Type",
                        common: commonScaleOptions,
                        moreGroups: moreScaleGroups,
                        activeFill: .brandPurple,
                        selectedAccent: .brandPurple,
                        showMore: $showMoreScales
                    )
                    .padding(.top, Spacing.md)
                    .transition(.scaleAndFade)
                }

                if showResult {
                    AnswerResultPanel(title: getScaleLabel(), accent: .brandPurple) {
                        scaleNotesContent
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

    private var commonScaleOptions: [ChipOption] {
        [
            chip("major", "Major", nil, viewModel.major) { select { $0.major = true } },
            chip("natMin", "Nat. Minor", nil, viewModel.minorNat) { select { $0.minorNat = true } },
            chip("harmMin", "Harm. Minor", nil, viewModel.minorHarm) { select { $0.minorHarm = true } },
            chip("melMin", "Mel. Minor", nil, viewModel.minorMel) { select { $0.minorMel = true } },
        ]
    }

    private var moreScaleGroups: [(title: String, options: [ChipOption])] {
        [
            (
                "Modes",
                [
                    chip("dor", "Dorian", nil, viewModel.dorian) { select { $0.dorian = true } },
                    chip("phr", "Phrygian", nil, viewModel.phrygian) { select { $0.phrygian = true } },
                    chip("lyd", "Lydian", nil, viewModel.lydian) { select { $0.lydian = true } },
                    chip("mix", "Mixolydian", nil, viewModel.mixo) { select { $0.mixo = true } },
                    chip("loc", "Locrian", nil, viewModel.locrian) { select { $0.locrian = true } },
                ]
            ),
            (
                "Other",
                [
                    chip("pent", "Pentatonic", nil, viewModel.pentatonic) { select { $0.pentatonic = true } },
                    chip("wt", "Whole Tone", nil, viewModel.wholeTone) { select { $0.wholeTone = true } },
                    chip("oct", "Octatonic", nil, viewModel.octatonic) { select { $0.octatonic = true } },
                ]
            ),
            (
                "Jazz / Melodic minor modes",
                [
                    chip("dorB2", "Phrygian ♮6", nil, viewModel.dorB2) { select { $0.dorB2 = true } },
                    chip("lydAug", "Lydian Aug", nil, viewModel.lydianAug) { select { $0.lydianAug = true } },
                    chip("lydDom", "Lydian Dom", nil, viewModel.lydDom) { select { $0.lydDom = true } },
                    chip("alt", "Altered", nil, viewModel.supLoc) { select { $0.supLoc = true } },
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

    private func select(_ mutate: (scalesViewModel) -> Void) {
        withAnimation(AppAnimation.quickSpring) {
            viewModel.resetButtons()
            mutate(viewModel)
            showingKeyboard = false
            // Always collapse advanced; selection is pinned into the preview tiles.
            showMoreScales = false
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

    @ViewBuilder
    private var scaleNotesContent: some View {
        if viewModel.pentatonic {
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

    private func getScaleLabel() -> String {
        let root = viewModel.root
        if viewModel.major { return "\(root) Major" }
        if viewModel.minorNat { return "\(root) Natural Minor" }
        if viewModel.minorHarm { return "\(root) Harmonic Minor" }
        if viewModel.minorMel { return "\(root) Melodic Minor" }
        if viewModel.dorian { return "\(root) Dorian" }
        if viewModel.phrygian { return "\(root) Phrygian" }
        if viewModel.lydian { return "\(root) Lydian" }
        if viewModel.mixo { return "\(root) Mixolydian" }
        if viewModel.locrian { return "\(root) Locrian" }
        if viewModel.pentatonic { return "\(root) Pentatonic" }
        if viewModel.wholeTone { return "\(root) Whole Tone" }
        if viewModel.octatonic { return "\(root) Octatonic" }
        if viewModel.dorB2 { return "\(root) Phrygian ♮6" }
        if viewModel.lydianAug { return "\(root) Lydian Augmented" }
        if viewModel.lydDom { return "\(root) Lydian Dominant" }
        if viewModel.supLoc { return "\(root) Altered" }
        return "Scale Notes"
    }
}

// MARK: - Scale Note Card Component

struct ScaleNoteCard: View {
    let note: String
    @State private var appeared = false

    var body: some View {
        Text(note)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.inkPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal, Spacing.xs)
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
    }
}

// MARK: - Scale Note Picker Keyboard

struct ScaleNotePickerKeyboard: View {
    @Binding var noteText: String
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(naturalNotes, id: \.self) { note in
                    ScaleNoteButton(label: note, isPressed: pressedButton == note, isSelected: noteText.starts(with: note)) {
                        appendNote(note)
                    }
                }
            }

            HStack(spacing: 8) {
                ScaleNoteButton(label: "♯", isPressed: pressedButton == "♯", isSelected: noteText.contains("#"), backgroundColor: Color.white.opacity(0.55)) {
                    appendAccidental("#")
                }

                ScaleNoteButton(label: "♭", isPressed: pressedButton == "♭", isSelected: noteText.contains("b"), backgroundColor: Color.white.opacity(0.55)) {
                    appendAccidental("b")
                }

                Spacer(minLength: 12)

                ScaleNoteButton(label: "⌫", isPressed: pressedButton == "⌫", backgroundColor: Color.pastelRed.opacity(0.85)) {
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

struct ScaleNoteButton: View {
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
                        .fill(isSelected ? Color.lightTintPurple : backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    isSelected ? Color.brandPurple.opacity(0.7) : Color.black.opacity(0.1),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct scalesAnsView_Previews: PreviewProvider {
    static var previews: some View {
        scalesAnsView()
            .environmentObject(scalesViewModel())
    }
}
