//
//  MusicQueryView.swift
//  Functional Harmony
//
//  Natural-language entry → Chords / Scales / Notes.
//  Same shell as other tabs: hero result + bottom controls.
//  No recommendations — type, see answer, open.
//

import SwiftUI

struct MusicQueryView: View {
    @EnvironmentObject private var triadVM: triadBuildViewModel
    @EnvironmentObject private var scalesVM: scalesViewModel
    @EnvironmentObject private var notesSession: NotesSessionState

    @Binding var selectedTab: MainSectionTab

    @State private var query: String = ""
    @State private var enableLayoutAnimations = false
    @FocusState private var fieldFocused: Bool

    // MARK: - Derived

    private var liveMatch: MusicQueryMatch? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return MusicQueryParser.parse(trimmed)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool { liveMatch != nil }
    private var isEmptyState: Bool { trimmedQuery.isEmpty }
    private var isNoMatch: Bool { !isEmptyState && liveMatch == nil }
    private var showResult: Bool { canSubmit }

    private var activeAccent: Color {
        if let match = liveMatch {
            return destinationColor(match.destination)
        }
        return .brandAqua
    }

    // MARK: - Body

    var body: some View {
        LandscapeResultContainer(hasResult: showResult) { _ in
            portraitLayout
        } landscape: {
            if let match = liveMatch {
                landscapeResult(match)
            }
        }
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: showResult)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: isNoMatch)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: liveMatch?.summary)
        .onAppear {
            DispatchQueue.main.async {
                enableLayoutAnimations = true
                fieldFocused = true
            }
        }
    }

    // MARK: - Portrait shell

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            if showResult, let match = liveMatch {
                resultBand(match)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isNoMatch {
                noMatchBand
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyHero
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            controlsBand
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - Heroes

    /// Idle: brand wordmark on canvas — no accent chrome until a match appears.
    private var emptyHero: some View {
        EmptyResultWordmark()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Functional Harmony. Type a chord, scale, or notes.")
    }

    private func resultBand(_ match: MusicQueryMatch) -> some View {
        let preview = MusicQueryPreviewResolver.resolve(match)
        let accent = destinationColor(match.destination)
        let captions = intervalCaptions(from: preview)

        return AnswerResultPanel(
            title: preview.title,
            accent: accent,
            verticallyCenterContent: true,
            expandsToFill: true,
            bleedTopSafeArea: true
        ) {
            VStack(spacing: Spacing.sm) {
                if !preview.notes.isEmpty {
                    answerNotes(
                        match: match,
                        notes: preview.notes,
                        captions: captions
                    )
                }

                if match.destination == .notes,
                   let detail = preview.detail,
                   !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.inkOnAccent.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(destinationLabel(match.destination)). \(preview.title). \(preview.notes.joined(separator: ", "))"
        )
    }

    private var noMatchBand: some View {
        AnswerResultPanel(
            title: "No match",
            accent: Color.inkSecondary.opacity(0.55),
            verticallyCenterContent: true,
            expandsToFill: true,
            bleedTopSafeArea: true
        ) {
            EmptyView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func answerNotes(
        match: MusicQueryMatch,
        notes: [String],
        captions: [String]
    ) -> some View {
        switch match.destination {
        case .scales:
            ScaleNotesStrip(notes: notes, prominent: true)
        case .chords:
            HStack(spacing: Spacing.md) {
                ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                    let caption = index < captions.count ? captions[index] : nil
                    NoteCard(note: note, interval: caption, prominent: true)
                }
            }
        case .notes:
            HStack(spacing: notes.count > 4 ? Spacing.sm : Spacing.md) {
                ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                    NoteCard(note: note, prominent: true)
                }
            }
        }
    }

    private func landscapeResult(_ match: MusicQueryMatch) -> some View {
        let preview = MusicQueryPreviewResolver.resolve(match)
        let accent = destinationColor(match.destination)
        let captions = intervalCaptions(from: preview)

        return FullscreenAnswerView(title: preview.title, accent: accent) {
            answerNotes(match: match, notes: preview.notes, captions: captions)
        }
    }

    // MARK: - Controls (field + optional Open only)

    private var controlsBand: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Type anything music")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, Spacing.screenPadding)

            searchField
                .padding(.horizontal, Spacing.screenPadding)

            if canSubmit {
                openButton
            }
        }
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.tabBarClearanceGlass)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandBeige)
        .contentShape(Rectangle())
        .onTapGesture { /* keep keyboard; don't steal focus */ }
    }

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            // Explicit prompt color — system placeholder defaults to near-white and
            // vanishes on the light surfaceCard field in light mode.
            TextField(
                "",
                text: $query,
                prompt: Text("C major 7…")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.inkSecondary)
            )
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundColor(.inkPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($fieldFocused)
            .submitLabel(.go)
            .onSubmit { submit() }

            if !query.isEmpty {
                Button {
                    query = ""
                    fieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.inkTertiary)
                }
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(minHeight: 64)
        .background(
            Spacing.shapeMedium
                .fill(Color.surfaceCard)
        )
    }

    private var openButton: some View {
        Button(action: submit) {
            HStack(spacing: Spacing.sm) {
                Text(openTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.inkOnAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Spacing.shapeMedium
                    .fill(activeAccent)
            )
        }
        .buttonStyle(PressableOpenStyle())
        .padding(.horizontal, Spacing.screenPadding)
        .accessibilityHint("Opens the matching tool with this answer")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var openTitle: String {
        guard let match = liveMatch else { return "Open" }
        return "Open \(match.tab.title)"
    }

    // MARK: - Actions

    private func submit() {
        fieldFocused = false
        guard let match = liveMatch else {
            if !trimmedQuery.isEmpty {
                HapticManager.shared.warning()
            }
            return
        }
        match.apply(triad: triadVM, scales: scalesVM, notes: notesSession)
        withAnimation(AppAnimation.quickSpring) {
            selectedTab = match.tab
        }
        HapticManager.shared.navigate()
    }

    private func intervalCaptions(from preview: MusicQueryPreview) -> [String] {
        guard let detail = preview.detail, !detail.isEmpty else { return [] }
        let parts = detail
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard parts.count == preview.notes.count else { return [] }
        return parts
    }

    private func destinationColor(_ d: MusicQueryDestination) -> Color {
        switch d {
        case .chords: return .brandCoral
        case .scales: return .brandPurple
        case .notes: return .brandNotes
        }
    }

    private func destinationLabel(_ d: MusicQueryDestination) -> String {
        switch d {
        case .chords: return "Chord"
        case .scales: return "Scale"
        case .notes: return "Notes"
        }
    }
}

// MARK: - Press

private struct PressableOpenStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(AppAnimation.press, value: configuration.isPressed)
    }
}

// MARK: - Preview

struct MusicQueryView_Previews: PreviewProvider {
    static var previews: some View {
        MusicQueryView(selectedTab: .constant(.ask))
            .environmentObject(triadBuildViewModel())
            .environmentObject(scalesViewModel())
            .environmentObject(NotesSessionState())
            .background(Color.brandBeige.ignoresSafeArea())
    }
}
