//
//  VivaceTheoryView.swift
//  Chord Solver
//
//  Vivace — letter grid C–B (3×3) plus Clear + ⌫ row.
//  Tap a note chip to remove that note.
//

import SwiftUI

// MARK: - Session

final class VivaceSessionState: ObservableObject {
    static let maxNotes = 4

    @Published var notes: [String] = []
    @Published var answer: String = ""

    var canAddNote: Bool { notes.count < Self.maxNotes }
    var canEditLast: Bool { !notes.isEmpty }

    func appendNote(_ letter: String) {
        guard canAddNote else {
            HapticManager.shared.rigidImpact()
            return
        }
        notes.append(letter)
        refreshAnswer()
        HapticManager.shared.mediumImpact()
    }

    func applyAccidental(_ mark: String) {
        guard canEditLast, var last = notes.last else {
            HapticManager.shared.rigidImpact()
            return
        }
        if mark == "♯" || mark == "#" { last += "♯" }
        else if mark == "♭" || mark == "b" { last += "♭" }
        notes[notes.count - 1] = last
        refreshAnswer()
        HapticManager.shared.lightImpact()
    }

    func removeNote(at index: Int) {
        guard notes.indices.contains(index) else {
            HapticManager.shared.rigidImpact()
            return
        }
        notes.remove(at: index)
        refreshAnswer()
        HapticManager.shared.rigidImpact()
    }

    /// Remove the most recently entered note (pad ⌫).
    func backspace() {
        guard canEditLast else {
            HapticManager.shared.rigidImpact()
            return
        }
        notes.removeLast()
        refreshAnswer()
        HapticManager.shared.rigidImpact()
    }

    /// Wipe all notes (pad Clear).
    func clear() {
        guard !notes.isEmpty else {
            HapticManager.shared.rigidImpact()
            return
        }
        notes = []
        answer = ""
        HapticManager.shared.lightImpact()
    }

    private func refreshAnswer() {
        answer = VivaceChordIdentifier.identify(notes: notes)
    }
}

// MARK: - Parsed result for Chord Solver panel

private struct VivaceParsedResult {
    let title: String
    let detail: String?
    let isSuccess: Bool
    let isPlaceholder: Bool
}

private func parseVivaceAnswer(_ raw: String, noteCount: Int) -> VivaceParsedResult {
    // Empty state: no instruction banner (pad stands alone).
    if noteCount == 0 {
        return VivaceParsedResult(
            title: "",
            detail: nil,
            isSuccess: false,
            isPlaceholder: true
        )
    }
    if noteCount == 1 {
        return VivaceParsedResult(
            title: "Enter more notes",
            detail: nil,
            isSuccess: false,
            isPlaceholder: true
        )
    }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return VivaceParsedResult(title: "…", detail: nil, isSuccess: false, isPlaceholder: true)
    }
    let failures = ["No chord", "No interval", "Use up to", "Enter more", "Faulty"]
    if failures.contains(where: { trimmed.hasPrefix($0) }) {
        return VivaceParsedResult(title: trimmed, detail: nil, isSuccess: false, isPlaceholder: false)
    }
    let parts = trimmed
        .components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    let primary = parts.first ?? trimmed
    var detail: String?
    if parts.count > 1 {
        detail = parts.dropFirst()
            .map { $0.replacingOccurrences(of: "also", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
    return VivaceParsedResult(title: primary, detail: detail, isSuccess: true, isPlaceholder: false)
}

// MARK: - View

struct VivaceTheoryView: View {
    @EnvironmentObject private var session: VivaceSessionState

    private let gap: CGFloat = 10
    private let inset: CGFloat = 16

    private var parsed: VivaceParsedResult {
        parseVivaceAnswer(session.answer, noteCount: session.notes.count)
    }

    /// Letter grid starts at C (C–B), 3 columns × 3 rows.
    private let grid: [[(String, KeyStyle)]] = [
        [("C", .note), ("D", .note), ("E", .note)],
        [("F", .note), ("G", .note), ("A", .note)],
        [("♭", .accent), ("B", .note), ("♯", .accent)],
    ]

    /// Fixed control row height (Clear + ⌫) — does not compete with letter pad.
    private let utilRowHeight: CGFloat = 56

    /// Compact note chips (aligned with Scales `ScaleNoteCard`, not oversized Chords cards).
    private let noteChipHeight: CGFloat = 60

    /// Compact banner when notes are present (no empty-state banner).
    private let resultBannerMinHeight: CGFloat = 72

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: Spacing.md) {
                resultRegion
                    .frame(maxWidth: .infinity)
                    .layoutPriority(0)

                // 3×3 letter pad fills leftover height; Clear | ⌫ fixed below.
                VStack(spacing: gap) {
                    ForEach(Array(grid.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: gap) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                padKey(title: cell.0, style: cell.1)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    HStack(spacing: gap) {
                        clearKey
                        backspaceKey
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: utilRowHeight)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, inset)
                .padding(.bottom, inset + Spacing.tabBarClearance)
                .frame(maxHeight: .infinity)
            }
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: Result (Chord Solver panel language)

    @ViewBuilder
    private var resultRegion: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("\(session.notes.count)/\(VivaceSessionState.maxNotes)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.inkTertiary)
                Spacer()
                if !session.notes.isEmpty {
                    Text("Clear / ⌫ or tap note")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.inkTertiary)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .frame(minHeight: 16)

            // Reserve result slot height always so the pad doesn't expand into it.
            // Empty: leave blank (no coaching fill). With notes: show result panel.
            ZStack {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: resultBannerMinHeight)

                if !session.notes.isEmpty {
                    AnswerResultPanel(
                        title: parsed.title,
                        accent: panelAccent,
                        minHeight: resultBannerMinHeight
                    ) {
                        panelBody
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: resultBannerMinHeight)
        }
        .animation(AppAnimation.quickSpring, value: session.notes.count)
    }

    private var panelAccent: Color {
        if parsed.isSuccess { return .brandVivace }
        if parsed.isPlaceholder { return Color.brandVivace.opacity(0.45) }
        return Color.inkSecondary.opacity(0.7)
    }

    @ViewBuilder
    private var panelBody: some View {
        VStack(spacing: Spacing.xs) {
            notesRow

            if parsed.isSuccess, let detail = parsed.detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.inkOnAccent.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var notesRow: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(session.notes.enumerated()), id: \.offset) { index, note in
                Button {
                    withAnimation(AppAnimation.quickSpring) {
                        session.removeNote(at: index)
                    }
                } label: {
                    VivaceResultNoteCard(note: note, height: noteChipHeight)
                }
                .buttonStyle(CalcPressStyle())
                .accessibilityLabel("Remove note \(note)")
                .accessibilityHint("Removes this note from the chord")
            }
        }
    }

    // MARK: Keys (Chords/Scales surface language)

    private enum KeyStyle {
        case note    // white card, dark ink
        case accent  // soft vivace tint for ♭ / ♯ (less saturated than primary brand)
        case util    // slate util (Clear / backspace)
    }

    /// Cool slate for Clear.
    private var clearKeyFill: Color {
        Color(red: 0.42, green: 0.44, blue: 0.48)
    }

    private var clearKey: some View {
        utilKey(
            title: "Clear",
            fill: clearKeyFill,
            ink: .inkOnAccent,
            enabled: session.canEditLast,
            accessibility: "Clear all notes"
        ) {
            withAnimation(AppAnimation.quickSpring) {
                session.clear()
            }
        }
    }

    private var backspaceKey: some View {
        let active = session.canEditLast
        return utilKey(
            title: "⌫",
            fill: active ? Color.mutedRed : Color.backspaceIdle,
            ink: active ? Color.inkPrimary : Color.inkTertiary,
            enabled: active,
            accessibility: "Delete last note"
        ) {
            withAnimation(AppAnimation.quickSpring) {
                session.backspace()
            }
        }
    }

    private func utilKey(
        title: String,
        fill: Color,
        ink: Color,
        enabled: Bool,
        accessibility: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(ink)
                .frame(maxWidth: .infinity)
                .frame(height: utilRowHeight)
                .background(
                    Spacing.shapeMedium
                        .fill(fill)
                )
        }
        .buttonStyle(CalcPressStyle())
        .disabled(!enabled)
        .accessibilityLabel(accessibility)
    }

    private func padKey(title: String, style: KeyStyle) -> some View {
        let enabled = isEnabled(style: style)

        return Button {
            handle(title)
        } label: {
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(foreground(style))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Spacing.shapeMedium
                        .fill(fill(style))
                )
                .overlay(
                    Spacing.shapeMedium
                        .strokeBorder(border(style), lineWidth: 1)
                )
        }
        .buttonStyle(CalcPressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(a11y(title))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func isEnabled(style: KeyStyle) -> Bool {
        if style == .note { return session.canAddNote }
        return session.canEditLast
    }

    private func handle(_ title: String) {
        switch title {
        case "♯": session.applyAccidental("♯")
        case "♭": session.applyAccidental("♭")
        default: session.appendNote(title)
        }
    }

    private func fill(_ style: KeyStyle) -> Color {
        switch style {
        case .note: return .surfaceCard
        case .accent: return .brandVivaceSoft
        case .util: return clearKeyFill
        }
    }

    private func foreground(_ style: KeyStyle) -> Color {
        switch style {
        case .note, .accent: return .inkPrimary
        case .util: return .inkOnAccent
        }
    }

    private func border(_ style: KeyStyle) -> Color {
        switch style {
        case .note: return .borderSubtle
        case .accent: return Color.brandVivace.opacity(0.22)
        case .util: return .clear
        }
    }

    private func a11y(_ title: String) -> String {
        switch title {
        case "♯": return "Sharp"
        case "♭": return "Flat"
        default: return "Note \(title)"
        }
    }
}

// Compact note chip — denser than Chords NoteCard so the calculator pad stays primary.
private struct VivaceResultNoteCard: View {
    let note: String
    var height: CGFloat = 60

    var body: some View {
        Text(note)
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundColor(.inkPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                Spacing.shapeMedium
                    .fill(Color.surfaceCard)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Note \(note)")
    }
}

private struct CalcPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(AppAnimation.press, value: configuration.isPressed)
    }
}

struct VivaceTheoryView_Previews: PreviewProvider {
    static var previews: some View {
        VivaceTheoryView()
            .environmentObject(VivaceSessionState())
            .background(Color.brandBeige.ignoresSafeArea())
    }
}
