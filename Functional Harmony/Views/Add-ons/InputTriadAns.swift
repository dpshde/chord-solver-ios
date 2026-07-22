//
//  InputTriadAns.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 4/12/21.
//

import SwiftUI

struct InputTriadAns: View {

    var remove: (() -> Void)? = nil

    @EnvironmentObject var viewModel: triadBuildViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var showMoreQualities = false
    @State private var qualityCatalogExpanded = true
    @State private var rootAttentionTick = 0
    /// Skip layout transitions on first paint / tab re-entry; enable after settle.
    @State private var enableLayoutAnimations = false
    /// Shared with Scales — calculator pad needs result pinned high.
    @AppStorage(RootNotePadLayout.storageKey) private var useCalculator = RootNotePadLayout.defaultUsesCalculator
    /// Global result audio mute; top-left toggle on the result chrome.
    @AppStorage(PianoSamplePlayer.soundEnabledKey) private var soundEnabled = true

    private var hasQualitySelected: Bool {
        viewModel.major || viewModel.minor || viewModel.aug || viewModel.dim ||
        viewModel.MM7 || viewModel.Mm7 || viewModel.mm7 || viewModel.hd7 || viewModel.fd7 || viewModel.mM7 ||
        viewModel.sus2 || viewModel.sus4 || viewModel.itA6 || viewModel.frA6 || viewModel.gerA6 || viewModel.ct7
    }

    private var showResult: Bool {
        !viewModel.root.isEmpty && hasQualitySelected
    }

    /// Browsing qualities (Change open) — pin result top and grow the options band.
    private var isBrowsingQualities: Bool {
        qualityCatalogExpanded
    }

    var body: some View {
        LandscapeResultContainer(hasResult: showResult) { size in
            portraitLayout(height: size.height)
        } landscape: {
            FullscreenAnswerView(
                title: getChordLabel(),
                accent: .brandCoral,
                isSoundOn: $soundEnabled,
                onPlayTap: playChordResult
            ) {
                chordNotesRow(prominent: true)
            }
        }
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: showResult)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: qualityCatalogExpanded)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: showMoreQualities)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: useCalculator)
        // Autoplay when a new chord result appears (sound on); stop when cleared or leaving.
        .onChange(of: playableChordNotes) { _, notes in
            guard soundEnabled, !notes.isEmpty, showResult else {
                if PianoSamplePlayer.shared.isPlaying {
                    PianoSamplePlayer.shared.stop()
                }
                return
            }
            playChordResult()
        }
        .onDisappear {
            if PianoSamplePlayer.shared.isPlaying {
                PianoSamplePlayer.shared.stop()
            }
        }
        .onAppear {
            // Restore collapsed catalog instantly when re-entering with a selection.
            if hasQualitySelected {
                qualityCatalogExpanded = false
                showMoreQualities = false
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
            title: getChordLabel(),
            accent: .brandCoral,
            verticallyCenterContent: true,
            expandsToFill: true,
            bleedTopSafeArea: true,
            isSoundOn: $soundEnabled,
            onPlayTap: playChordResult
        ) {
            chordNotesRow(prominent: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Pitch classes currently shown in the result (root-position / special stacks).
    private var playableChordNotes: [String] {
        chordTones.map(\.note).filter { !$0.isEmpty }
    }

    private func playChordResult() {
        guard soundEnabled else { return }
        let notes = playableChordNotes
        guard !notes.isEmpty else { return }
        HapticManager.shared.lightImpact()
        PianoSamplePlayer.shared.playChord(pitchClasses: notes)
    }

    /// Matches the Quality “Change” control (second swipe-up on expanded pad).
    private func openQualityChangeMenu() {
        guard !qualityCatalogExpanded else { return }
        withAnimation(AppAnimation.quickSpring) {
            qualityCatalogExpanded = true
            // Same as Change: open full advanced list when browsing.
            showMoreQualities = !moreQualityGroups.isEmpty
        }
        HapticManager.shared.lightImpact()
    }

    /// Swipe-down “back”: close the Change catalog when it’s open (and a quality is set).
    /// Returns true when handled so the pad does not also collapse in the same gesture.
    private func handleQualitySwipeDownBack() -> Bool {
        // Only “back” from Change when there is something to return to (collapsed chip).
        guard qualityCatalogExpanded, hasQualitySelected else { return false }
        withAnimation(AppAnimation.quickSpring) {
            qualityCatalogExpanded = false
            showMoreQualities = false
        }
        HapticManager.shared.lightImpact()
        return true
    }

    /// Controls hug their content so ROOT + pad + Quality always stay on-screen.
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
            .scrollDisabled(!isBrowsingQualities)
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(isBrowsingQualities ? .bottom : .top)
            // Collapsed: size to content (no flex). Expanded: cap height so result stays visible.
            .frame(maxHeight: isBrowsingQualities ? catalogCap : nil)
            .fixedSize(horizontal: false, vertical: !isBrowsingQualities)

            if isBrowsingQualities {
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
                sectionTitle: "Quality",
                common: commonQualityOptions,
                moreGroups: moreQualityGroups,
                activeFill: .brandCoral,
                selectedAccent: .brandCoral,
                isCatalogExpanded: $qualityCatalogExpanded,
                showMore: $showMoreQualities
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

            TriadNotePickerKeyboard(
                noteText: $viewModel.root,
                canClearQuality: hasQualitySelected,
                onRootEmpty: {
                    withAnimation(AppAnimation.quickSpring) {
                        viewModel.resetButtons()
                        // Re-open catalog to pick again, but keep controls bottom-anchored.
                        qualityCatalogExpanded = true
                        showMoreQualities = false
                    }
                },
                onSwipeUpWhenExpanded: openQualityChangeMenu,
                onSwipeDownBack: handleQualitySwipeDownBack
            )
            .padding(.horizontal, Spacing.screenPadding)
        }
        .attentionPulse(tick: rootAttentionTick, accent: .brandCoral)
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
        }
        // Quality chosen before a root — standard attention pulse on notes UI.
        if viewModel.root.isEmpty {
            HapticManager.shared.warning()
            rootAttentionTick += 1
        }
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
    private func chordNotesRow(prominent: Bool) -> some View {
        let context = playableChordNotes
        HStack(spacing: prominent ? Spacing.md : Spacing.sm) {
            ForEach(Array(chordTones.enumerated()), id: \.offset) { index, tone in
                NoteCard(
                    note: tone.note,
                    interval: tone.interval,
                    prominent: prominent,
                    contextNotes: context,
                    contextIndex: index,
                    voicingStyle: .chord
                )
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
/// Tapping always plays that pitch (not gated by the result sound toggle),
/// using the same octave placement as the full chord/scale voicing.
struct NoteCard: View {
    let note: String
    /// Compact interval from root (e.g. `R`, `M3`, `P5`). Optional for previews.
    var interval: String? = nil
    /// Landscape fullscreen — larger type and chrome.
    var prominent: Bool = false
    /// Full ordered pitch set in the result (for relative octave placement).
    var contextNotes: [String] = []
    /// Index within `contextNotes` when available.
    var contextIndex: Int? = nil
    var voicingStyle: NoteVoicing.Style = .chord

    @ObservedObject private var player = PianoSamplePlayer.shared

    private var isSounding: Bool {
        player.isHighlighting(pitchClass: note)
    }

    var body: some View {
        Button {
            playThisNote()
        } label: {
            VStack(spacing: prominent ? 10 : 6) {
                Text(note)
                    .font(.system(size: prominent ? 44 : 28, weight: .bold, design: .rounded))
                    .foregroundColor(.inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity)

                if let interval, !interval.isEmpty {
                    Text(interval)
                        .font(.system(size: prominent ? 16 : 11, weight: .medium, design: .rounded))
                        .foregroundColor(.inkTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .accessibilityLabel(Self.accessibilityName(for: interval))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: prominent ? (interval == nil ? 96 : 110) : (interval == nil ? 64 : 72))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, prominent ? Spacing.md : Spacing.sm)
            .background(
                Spacing.shapeMedium
                    .fill(isSounding ? Color.playingNoteFill : Color.surfaceCard)
            )
            .overlay(
                Spacing.shapeMedium
                    .strokeBorder(Color.inkPrimary.opacity(isSounding ? 0.14 : 0), lineWidth: 1.5)
            )
            .scaleEffect(isSounding ? 1.045 : 1.0)
            .animation(AppAnimation.bouncySpring, value: isSounding)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            interval.map { "\(note), \(Self.accessibilityName(for: $0))" } ?? note
        )
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
            style: voicingStyle
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

// TriadNotePickerKeyboard lives in RootNotePadKeyboard.swift (shared pad).

struct InputTriadAns_Previews: PreviewProvider {
    static var previews: some View {
        InputTriadAns()
            .environmentObject(triadBuildViewModel())
    }
}
