//
//  scalesAnsView.swift
//  Functional Harmony
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
    /// Skip layout transitions on first paint / tab re-entry; enable after settle.
    @State private var enableLayoutAnimations = false
    /// Shared with Chords — calculator pad needs result pinned high.
    @AppStorage(RootNotePadLayout.storageKey) private var useCalculator = RootNotePadLayout.defaultUsesCalculator
    /// Global result audio mute; top-left toggle on the result chrome.
    @AppStorage(PianoSamplePlayer.soundEnabledKey) private var soundEnabled = true

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
        LandscapeResultContainer(hasResult: showResult) { size in
            portraitLayout(height: size.height)
        } landscape: {
            FullscreenAnswerView(
                title: getScaleLabel(),
                accent: .brandPurple,
                isSoundOn: $soundEnabled,
                onPlayTap: { playScaleResult() },
                showsLoopToggle: true
            ) {
                ScaleNotesStrip(notes: scaleNotesList.filter { !$0.isEmpty }, prominent: true)
            }
        }
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: showResult)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: scaleCatalogExpanded)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: showMoreScales)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: useCalculator)
        // Autoplay when a new scale result appears (sound on); stop when cleared or leaving.
        // Defer audio so root-pad selection / result strip can paint first.
        .onChange(of: scaleNotesList) { _, newNotes in
            let notes = newNotes.filter { !$0.isEmpty }
            guard soundEnabled, !notes.isEmpty else {
                if PianoSamplePlayer.shared.isPlaying {
                    PianoSamplePlayer.shared.stop()
                }
                return
            }
            HapticManager.shared.afterUIUpdate {
                playScaleResult(playHaptic: false)
            }
        }
        .onDisappear {
            if PianoSamplePlayer.shared.isPlaying {
                PianoSamplePlayer.shared.stop()
            }
        }
        .onAppear {
            // Restore collapsed catalog instantly when re-entering with a selection.
            if hasScaleSelected {
                scaleCatalogExpanded = false
                showMoreScales = false
            }
            DispatchQueue.main.async {
                enableLayoutAnimations = true
            }
        }
    }

    @ViewBuilder
    private func portraitLayout(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            if showResult {
                // Fills whatever is left above the controls’ intrinsic height.
                resultBand
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyResultWordmark()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            controlsBand(in: height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var resultBand: some View {
        AnswerResultPanel(
            title: getScaleLabel(),
            accent: .brandPurple,
            verticallyCenterContent: true,
            expandsToFill: true,
            bleedTopSafeArea: true,
            isSoundOn: $soundEnabled,
            onPlayTap: { playScaleResult() },
            showsLoopToggle: true
        ) {
            ScaleNotesStrip(notes: scaleNotesList.filter { !$0.isEmpty }, prominent: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Play surface: ascending once, or up-and-back once when loop mode is on.
    /// - Parameter playHaptic: false for autoplay (pad/chip already gave feedback).
    private func playScaleResult(playHaptic: Bool = true) {
        guard soundEnabled else { return }
        let notes = scaleNotesList.filter { !$0.isEmpty }
        guard !notes.isEmpty else { return }
        if playHaptic {
            HapticManager.shared.lightImpact()
        }
        PianoSamplePlayer.shared.playScale(pitchClasses: notes)
    }

    /// Matches the Scale “Change” control (second swipe-up on expanded pad).
    private func openScaleChangeMenu() {
        guard !scaleCatalogExpanded else { return }
        withAnimation(AppAnimation.quickSpring) {
            scaleCatalogExpanded = true
            // Same as Change: open full advanced list when browsing.
            showMoreScales = !moreScaleGroups.isEmpty
        }
        HapticManager.shared.lightImpact()
    }

    /// Swipe-down “back”: close the Change catalog when it’s open (and a scale is set).
    private func handleScaleSwipeDownBack() -> Bool {
        guard scaleCatalogExpanded, hasScaleSelected else { return false }
        withAnimation(AppAnimation.quickSpring) {
            scaleCatalogExpanded = false
            showMoreScales = false
        }
        HapticManager.shared.lightImpact()
        return true
    }

    /// Controls hug their content so ROOT + pad + Scale always stay on-screen.
    /// Expanded catalog is height-capped and scrollable. Always keep one ScrollView
    /// host so GroupedOptionPicker is not remounted when tapping Change.
    private func controlsBand(in totalHeight: CGFloat) -> some View {
        let catalogCap = max(300, totalHeight * (showResult ? 0.82 : 0.88))

        return ZStack(alignment: .top) {
            ScrollView {
                controlsColumn
                    // Small air between result banner edge and ROOT.
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.tabBarClearanceGlass)
            }
            // Collapsed catalog fits on screen — disable scroll so pad swipes cannot rubber-band.
            .scrollDisabled(!isBrowsingScales)
            .scrollBounceBehavior(.basedOnSize)
            // Bottom-anchor only when Change is open *with* a selection (options near pad).
            // After backspace clears scale, stay top so Root/pad do not jump down.
            .defaultScrollAnchor((isBrowsingScales && hasScaleSelected) ? .bottom : .top)
            // Collapsed: size to content (no flex). Expanded: cap height so result stays visible.
            .frame(maxHeight: isBrowsingScales ? catalogCap : nil)
            .fixedSize(horizontal: false, vertical: !isBrowsingScales)

            if isBrowsingScales {
                CanvasEdgeFade(edge: .top, height: 24)
                    .opacity(0.9)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity)
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
                canClearQuality: hasScaleSelected,
                onRootEmpty: {
                    // Deselect scale and reopen common catalog; keep scroll at Root/pad
                    // (defaultScrollAnchor stays .top when hasScaleSelected is false).
                    withAnimation(AppAnimation.quickSpring) {
                        viewModel.resetButtons()
                        scaleCatalogExpanded = true
                        showMoreScales = false
                    }
                },
                onSwipeUpWhenExpanded: openScaleChangeMenu,
                onSwipeDownBack: handleScaleSwipeDownBack
            )
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
        // Commit scale choice immediately; layout collapse can still spring via the picker.
        viewModel.resetButtons()
        mutate(viewModel)
        if viewModel.root.isEmpty {
            rootAttentionTick += 1
            HapticManager.shared.afterUIUpdate {
                HapticManager.shared.warning()
            }
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

/// Ascending scale tones with degree captions. Sizing adapts to note count
/// so 5–8 tone scales stay readable in the hero banner.
struct ScaleNotesStrip: View {
    let notes: [String]
    /// Hero / landscape — larger type and chrome.
    var prominent: Bool = false

    private var count: Int { max(notes.count, 1) }

    /// Tighter gaps as the strip grows; keep a little air at 5–7.
    private var rowSpacing: CGFloat {
        guard prominent else { return Spacing.xs }
        switch count {
        case ...4: return Spacing.sm
        case 5, 6: return 6
        default: return 5
        }
    }

    private var metrics: ScaleDegreeMetrics {
        ScaleDegreeMetrics(count: count, prominent: prominent)
    }

    var body: some View {
        HStack(spacing: rowSpacing) {
            ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                ScaleDegreeCell(
                    note: note,
                    degree: index + 1,
                    metrics: metrics,
                    contextNotes: notes,
                    contextIndex: index
                )
            }
        }
        // Keep cells as separate accessibility buttons (each plays its pitch).
        .accessibilityElement(children: .contain)
    }
}

/// Shared type/chrome for one scale step, tuned by how many notes are showing.
private struct ScaleDegreeMetrics {
    let count: Int
    let prominent: Bool

    var noteSize: CGFloat {
        guard prominent else { return 17 }
        switch count {
        case ...4: return 30
        case 5: return 26
        case 6: return 24
        case 7: return 22
        default: return 20 // 8+
        }
    }

    var degreeSize: CGFloat {
        guard prominent else { return 11 }
        switch count {
        case ...4: return 13
        case 5, 6: return 12
        default: return 11
        }
    }

    var minHeight: CGFloat {
        guard prominent else { return 52 }
        switch count {
        case ...4: return 88
        case 5, 6: return 80
        case 7: return 74
        default: return 68
        }
    }

    var stackSpacing: CGFloat {
        prominent ? (count <= 5 ? 6 : 4) : 3
    }

    var horizontalPadding: CGFloat {
        guard prominent else { return 2 }
        return count <= 5 ? Spacing.xs : 2
    }

    var verticalPadding: CGFloat {
        guard prominent else { return Spacing.sm }
        return count <= 6 ? Spacing.md : Spacing.sm + 2
    }
}

/// One scale step: pitch class with quiet degree caption (chord NoteCard language).
/// Tapping always plays that pitch (not gated by the result sound toggle),
/// using the same octave as the full ascending scale voicing.
private struct ScaleDegreeCell: View {
    let note: String
    let degree: Int
    let metrics: ScaleDegreeMetrics
    let contextNotes: [String]
    let contextIndex: Int

    @ObservedObject private var player = PianoSamplePlayer.shared

    private var isSounding: Bool {
        player.isHighlighting(pitchClass: note)
    }

    var body: some View {
        Button {
            playThisNote()
        } label: {
            VStack(spacing: metrics.stackSpacing) {
                Text(note)
                    .font(.system(size: metrics.noteSize, weight: .bold, design: .rounded))
                    .foregroundColor(.inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)

                Text("\(degree)")
                    .font(.system(size: metrics.degreeSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.inkTertiary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: metrics.minHeight)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.vertical, metrics.verticalPadding)
            .background(
                Spacing.shapeMedium
                    .fill(isSounding ? Color.playingNoteFill : Color.surfaceCard)
            )
            .overlay(
                Spacing.shapeMedium
                    .strokeBorder(Color.inkPrimary.opacity(isSounding ? 0.14 : 0), lineWidth: 1.5)
            )
            .scaleEffect(isSounding ? 1.05 : 1.0)
            .animation(AppAnimation.bouncySpring, value: isSounding)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Degree \(degree), \(note)")
        .accessibilityHint("Plays this note")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isSounding ? "Playing" : "")
    }

    private func playThisNote() {
        guard !note.isEmpty else { return }
        HapticManager.shared.lightImpact()
        let among = contextNotes.isEmpty ? [note] : contextNotes
        PianoSamplePlayer.shared.playNote(
            pitchClass: note,
            at: contextIndex,
            among: among,
            style: .scale
        )
    }
}

/// Legacy alias kept for any external references.
struct ScaleNoteCard: View {
    let note: String

    var body: some View {
        ScaleDegreeCell(
            note: note,
            degree: 1,
            metrics: ScaleDegreeMetrics(count: 1, prominent: false),
            contextNotes: [note],
            contextIndex: 0
        )
    }
}

// ScaleNotePickerKeyboard lives in RootNotePadKeyboard.swift (shared pad).

struct scalesAnsView_Previews: PreviewProvider {
    static var previews: some View {
        scalesAnsView()
            .environmentObject(scalesViewModel())
    }
}
