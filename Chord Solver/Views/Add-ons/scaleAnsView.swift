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
    @State private var showMoreScales = false
    @State private var scaleCatalogExpanded = true
    @State private var rootAttentionTick = 0

    private var hasScaleSelected: Bool {
        viewModel.major || viewModel.minorNat || viewModel.minorHarm ||
        viewModel.minorMel || viewModel.dorian || viewModel.phrygian || viewModel.lydian ||
        viewModel.mixo || viewModel.locrian || viewModel.pentatonic || viewModel.wholeTone ||
        viewModel.octatonic || viewModel.dorB2 || viewModel.lydianAug || viewModel.lydDom ||
        viewModel.mixoB6 || viewModel.locNat2 || viewModel.supLoc
    }

    private var showResult: Bool {
        !viewModel.root.isEmpty && hasScaleSelected
    }

    private var isBrowsingScales: Bool {
        scaleCatalogExpanded
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if showResult {
                    // Settled: sit result just above controls. Browsing: pin top.
                    Group {
                        if isBrowsingScales {
                            resultBand
                                .frame(maxWidth: .infinity, alignment: .top)
                        } else {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                resultBand
                                Spacer()
                                    .frame(height: Spacing.sm)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                } else {
                    Spacer(minLength: 0)
                }

                controlsBand(maxHeight: controlsMaxHeight(in: geo.size.height))
            }
            .padding(.top, Spacing.sm)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(AppAnimation.quickSpring, value: showResult)
        .animation(AppAnimation.quickSpring, value: scaleCatalogExpanded)
        .animation(AppAnimation.quickSpring, value: showMoreScales)
    }

    private func controlsMaxHeight(in total: CGFloat) -> CGFloat {
        if isBrowsingScales {
            return max(300, total * (showResult ? 0.82 : 0.88))
        }
        if showResult {
            return max(240, total * 0.48)
        }
        return max(280, total * 0.55)
    }

    private var resultBand: some View {
        AnswerResultPanel(title: getScaleLabel(), accent: .brandPurple) {
            scaleNotesContent
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }

    private func controlsBand(maxHeight: CGFloat) -> some View {
        ZStack(alignment: .top) {
            ScrollView {
                controlsColumn
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.tabBarClearance)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.bottom)

            if showResult && isBrowsingScales {
                CanvasEdgeFade(edge: .top, height: 24)
                    .opacity(0.9)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .bottom)
        .background(Color.brandBeige)
    }

    private var controlsColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            rootBlock
            GroupedOptionPicker(
                sectionTitle: "Scale",
                common: commonScaleOptions,
                moreGroups: moreScaleGroups,
                activeFill: .brandPurple,
                selectedAccent: .brandPurple,
                isCatalogExpanded: $scaleCatalogExpanded,
                showMore: $showMoreScales
            )
        }
    }

    private var rootBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Root")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, Spacing.screenPadding)

            Text(viewModel.root.isEmpty ? "—" : viewModel.root)
                .font(.noteName)
                .foregroundColor(viewModel.root.isEmpty ? .inkTertiary : .inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.screenPadding)

            ScaleNotePickerKeyboard(
                noteText: $viewModel.root,
                canClearQuality: hasScaleSelected
            ) {
                withAnimation(AppAnimation.quickSpring) {
                    viewModel.resetButtons()
                    scaleCatalogExpanded = true
                    showMoreScales = false
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
        .attentionPulse(tick: rootAttentionTick, accent: .brandPurple)
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
                    chip("mixoB6", "Mixo ♭6", "♭13", viewModel.mixoB6) { select { $0.mixoB6 = true } },
                    chip("locNat2", "Locrian ♮2", nil, viewModel.locNat2) { select { $0.locNat2 = true } },
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
        }
        if viewModel.root.isEmpty {
            HapticManager.shared.warning()
            rootAttentionTick += 1
        }
    }

    /// Ordered scale tones for the result strip (root → … → leading tone).
    private var scaleNotesList: [String] {
        if viewModel.pentatonic {
            return [viewModel.returnRoot(), viewModel.two(), viewModel.three(),
                    viewModel.five(), viewModel.six()]
        }
        if viewModel.wholeTone {
            return [viewModel.returnRoot(), viewModel.two(), viewModel.three(),
                    viewModel.four(), viewModel.five(), viewModel.six()]
        }
        if viewModel.octatonic {
            return [
                viewModel.returnRoot(), viewModel.two(), viewModel.three(), viewModel.four(),
                viewModel.octFive(), viewModel.octSix(), viewModel.octSev(), viewModel.octEight(),
            ]
        }
        return [
            viewModel.returnRoot(), viewModel.two(), viewModel.three(), viewModel.four(),
            viewModel.five(), viewModel.six(), viewModel.sev(),
        ]
    }

    private var scaleNotesContent: some View {
        ScaleNotesStrip(notes: scaleNotesList.filter { !$0.isEmpty })
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
        if viewModel.mixoB6 { return "\(root) Mixolydian ♭6" }
        if viewModel.locNat2 { return "\(root) Locrian ♮2" }
        if viewModel.supLoc { return "\(root) Altered" }
        return "Scale Notes"
    }
}

// MARK: - Scale notes strip (single left-to-right sequence)

/// Beginner-friendly scale display: one ascending row with scale-degree numbers.
struct ScaleNotesStrip: View {
    let notes: [String]

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                ScaleDegreeCell(note: note, degree: index + 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            notes.enumerated()
                .map { "\($0.offset + 1), \($0.element)" }
                .joined(separator: "; ")
        )
    }
}

/// Compact note + degree (1…n) for a single scale step.
private struct ScaleDegreeCell: View {
    let note: String
    let degree: Int
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 3) {
            Text(note)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.45)

            Text("\(degree)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.inkTertiary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, 2)
        .background(
            Spacing.shapeSmall
                .fill(Color.surfaceCard)
        )
        .scaleEffect(appeared ? 1.0 : 0.92)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(AppAnimation.quickSpring.delay(Double(degree - 1) * 0.03)) {
                appeared = true
            }
        }
        .accessibilityLabel("Degree \(degree), \(note)")
    }
}

/// Legacy alias kept for any external references.
struct ScaleNoteCard: View {
    let note: String

    var body: some View {
        ScaleDegreeCell(note: note, degree: 1)
    }
}

// MARK: - Scale Note Picker Keyboard

struct ScaleNotePickerKeyboard: View {
    @Binding var noteText: String
    /// True when a scale is selected — extra ⌫ on empty root clears scale.
    var canClearQuality: Bool = false
    /// Called when ⌫ is pressed while root is already empty (clear scale).
    var onRootEmpty: (() -> Void)? = nil
    @State private var pressedButton: String? = nil

    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    private var canBackspace: Bool {
        !noteText.isEmpty || canClearQuality
    }

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

                ScaleNoteButton(
                    label: "⌫",
                    isPressed: pressedButton == "⌫",
                    backgroundColor: canBackspace ? Color.mutedRed : Color.backspaceIdle
                ) {
                    backspace()
                }
                .frame(maxWidth: 88)
                .opacity(canBackspace ? 1 : 0.65)
                .disabled(!canBackspace)
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
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func appendAccidental(_ accidental: String) {
        if !noteText.isEmpty {
            let hasSharp = noteText.contains("#")
            let hasFlat = noteText.contains("b")

            if accidental == "#" && hasFlat {
                withAnimation(AppAnimation.quickSpring) {
                    noteText = String(noteText.filter { $0 != "b" }) + "#"
                }
            } else if accidental == "b" && hasSharp {
                withAnimation(AppAnimation.quickSpring) {
                    noteText = String(noteText.filter { $0 != "#" }) + "b"
                }
            } else if noteText.filter({ $0 == "#" || $0 == "b" }).count < 3 {
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
            // Remove letters only — scale clears on a later press when root is already empty.
            withAnimation(AppAnimation.quickSpring) {
                noteText.removeLast()
            }
        } else if canClearQuality {
            onRootEmpty?()
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
                    Spacing.shapeSmall
                        .fill(isSelected ? Color.lightTintPurple : backgroundColor)
                        .overlay(
                            Spacing.shapeSmall
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
