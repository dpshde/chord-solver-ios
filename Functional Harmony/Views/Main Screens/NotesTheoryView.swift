//
//  NotesTheoryView.swift
//  Functional Harmony
//
//  Notes — multi-note entry. Shell matches Chords/Scales:
//  result banner (hero linear / compact calculator) + bottom controls band with pad.
//

import SwiftUI

// MARK: - Session

final class NotesSessionState: ObservableObject {
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

    func backspace() {
        guard canEditLast else {
            HapticManager.shared.rigidImpact()
            return
        }
        notes.removeLast()
        refreshAnswer()
        HapticManager.shared.rigidImpact()
    }

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
        answer = NotesChordIdentifier.identify(notes: notes)
    }
}

// MARK: - Parsed result

private struct NotesParsedResult {
    let title: String
    let detail: String?
    let isSuccess: Bool
    let isPlaceholder: Bool
}

private func parseNotesAnswer(_ raw: String, noteCount: Int) -> NotesParsedResult {
    if noteCount == 0 {
        return NotesParsedResult(title: "", detail: nil, isSuccess: false, isPlaceholder: true)
    }
    if noteCount == 1 {
        return NotesParsedResult(title: "Enter more notes", detail: nil, isSuccess: false, isPlaceholder: true)
    }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return NotesParsedResult(title: "…", detail: nil, isSuccess: false, isPlaceholder: true)
    }
    let failures = ["No chord", "No interval", "Use up to", "Enter more", "Faulty"]
    if failures.contains(where: { trimmed.hasPrefix($0) }) {
        return NotesParsedResult(title: trimmed, detail: nil, isSuccess: false, isPlaceholder: false)
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
    return NotesParsedResult(title: primary, detail: detail, isSuccess: true, isPlaceholder: false)
}

// MARK: - View (shell mirrors Chords / Scales)

struct NotesTheoryView: View {
    @EnvironmentObject private var session: NotesSessionState
    @AppStorage(RootNotePadLayout.storageKey) private var useCalculator = false
    @State private var enableLayoutAnimations = false

    private let gap: CGFloat = 10
    private let utilRowHeight: CGFloat = 56
    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]
    /// Matches Chords/Scales calculator: C-start 3×3 with ♭ / ♯ on the bottom corners.
    private let calculatorGrid: [[String]] = [
        ["C", "D", "E"],
        ["F", "G", "A"],
        ["♭", "B", "♯"],
    ]

    private var parsed: NotesParsedResult {
        parseNotesAnswer(session.answer, noteCount: session.notes.count)
    }

    private var showResult: Bool {
        !session.notes.isEmpty
    }

    private var panelAccent: Color {
        if parsed.isSuccess { return .brandNotes }
        if parsed.isPlaceholder { return Color.brandNotes.opacity(0.45) }
        return Color.inkSecondary.opacity(0.7)
    }

    private var accentKeyFill: Color {
        Color.darkBeige
    }

    private var clearKeyFill: Color {
        Color(red: 0.42, green: 0.44, blue: 0.48)
    }

    var body: some View {
        LandscapeResultContainer(hasResult: parsed.isSuccess) { size in
            portraitLayout(height: size.height)
        } landscape: {
            FullscreenAnswerView(title: parsed.title, accent: .brandNotes) {
                VStack(spacing: Spacing.md) {
                    notesRow(chipHeight: 96)
                    if let detail = parsed.detail, !detail.isEmpty {
                        Text(detail)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.inkOnAccent.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: showResult)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: useCalculator)
        .animation(enableLayoutAnimations ? AppAnimation.quickSpring : nil, value: session.notes.count)
        .onAppear {
            DispatchQueue.main.async { enableLayoutAnimations = true }
        }
    }

    // MARK: Portrait shell (identical structure to Chords/Scales)

    @ViewBuilder
    private func portraitLayout(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            if showResult {
                // Fills whatever is left above the controls’ intrinsic height.
                resultBand
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Spacer(minLength: 0)
            }

            controlsBand
        }
        .padding(.top, showResult ? 0 : Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var resultBand: some View {
        ZStack(alignment: .bottom) {
            AnswerResultPanel(
                title: parsed.title,
                accent: panelAccent,
                expandsToFill: true,
                bleedTopSafeArea: true
            ) {
                VStack(spacing: Spacing.sm) {
                    notesRow(chipHeight: 72)
                    if parsed.isSuccess, let detail = parsed.detail, !detail.isEmpty {
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

            // Meta footer — bottom of banner, separate from title/notes cluster.
            HStack {
                Text("\(session.notes.count)/\(NotesSessionState.maxNotes)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.inkOnAccent.opacity(0.75))
                Spacer()
                Text("Clear / ⌫ or tap note")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.inkOnAccent.opacity(0.7))
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Intrinsic height — Notes + pad always fully visible; result expands above.
    private var controlsBand: some View {
        controlsColumn
            // Small air between result banner edge and Notes.
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.tabBarClearanceGlass)
            .frame(maxWidth: .infinity)
            .background(Color.brandBeige)
    }

    private var controlsColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Notes")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, Spacing.screenPadding)

            Text(session.notes.isEmpty ? "—" : session.notes.joined(separator: "  "))
                .font(.noteName)
                .foregroundColor(session.notes.isEmpty ? .inkTertiary : .inkPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.screenPadding)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            notesPad
                .padding(.horizontal, Spacing.screenPadding)
        }
    }

    // MARK: Pad (mirrors RootNotePadKeyboard + Clear)

    private var notesPad: some View {
        VStack(spacing: gap) {
            if useCalculator {
                calculatorUtilRow
                calculatorPad
            } else {
                linearUtilRow
                linearPad
            }
        }
        .animation(AppAnimation.quickSpring, value: useCalculator)
    }

    /// Linear (like Chords/Scales): ♭ · ♯ · Clear · layout · ⌫
    private var linearUtilRow: some View {
        HStack(spacing: gap) {
            padKey(
                title: "♭",
                fill: Color.surfaceCard.opacity(0.55),
                enabled: session.canEditLast,
                fontSize: 26
            ) {
                session.applyAccidental("♭")
            }

            padKey(
                title: "♯",
                fill: Color.surfaceCard.opacity(0.55),
                enabled: session.canEditLast,
                fontSize: 26
            ) {
                session.applyAccidental("♯")
            }

            utilKey(
                title: "Clear",
                fill: session.canEditLast ? clearKeyFill : Color.backspaceIdle,
                ink: session.canEditLast ? .inkOnAccent : .inkTertiary,
                enabled: session.canEditLast
            ) {
                withAnimation(AppAnimation.quickSpring) { session.clear() }
            }

            Spacer(minLength: 8)

            layoutToggle(compact: true)
                .frame(maxWidth: 56)

            padKey(
                title: "⌫",
                fill: session.canEditLast ? Color.mutedRed : Color.backspaceIdle,
                enabled: session.canEditLast
            ) {
                withAnimation(AppAnimation.quickSpring) { session.backspace() }
            }
            .frame(maxWidth: 88)
        }
        .frame(height: utilRowHeight)
    }

    /// Calculator (like Chords/Scales + Clear): Clear · layout · ⌫
    private var calculatorUtilRow: some View {
        HStack(spacing: gap) {
            utilKey(
                title: "Clear",
                fill: session.canEditLast ? clearKeyFill : Color.backspaceIdle,
                ink: session.canEditLast ? .inkOnAccent : .inkTertiary,
                enabled: session.canEditLast
            ) {
                withAnimation(AppAnimation.quickSpring) { session.clear() }
            }
            layoutToggle(compact: false)
            padKey(
                title: "⌫",
                fill: session.canEditLast ? Color.mutedRed : Color.backspaceIdle,
                enabled: session.canEditLast,
                expands: true
            ) {
                withAnimation(AppAnimation.quickSpring) { session.backspace() }
            }
        }
        .frame(height: utilRowHeight)
    }

    private var linearPad: some View {
        HStack(spacing: gap) {
            ForEach(naturalNotes, id: \.self) { note in
                padKey(
                    title: note,
                    fill: Color.surfaceCard.opacity(0.72),
                    enabled: session.canAddNote
                ) {
                    session.appendNote(note)
                }
            }
        }
        .frame(height: utilRowHeight)
    }

    private var calculatorPad: some View {
        let cellHeight: CGFloat = 56
        return VStack(spacing: gap) {
            ForEach(Array(calculatorGrid.enumerated()), id: \.offset) { _, row in
                HStack(spacing: gap) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        calculatorCell(cell)
                    }
                }
                .frame(height: cellHeight)
            }
        }
    }

    @ViewBuilder
    private func calculatorCell(_ cell: String) -> some View {
        switch cell {
        case "♭":
            padKey(
                title: "♭",
                fill: accentKeyFill,
                enabled: session.canEditLast,
                expands: true,
                fontSize: 26
            ) {
                session.applyAccidental("♭")
            }
        case "♯":
            padKey(
                title: "♯",
                fill: accentKeyFill,
                enabled: session.canEditLast,
                expands: true,
                fontSize: 26
            ) {
                session.applyAccidental("♯")
            }
        default:
            padKey(
                title: cell,
                fill: Color.surfaceCard.opacity(0.72),
                enabled: session.canAddNote,
                expands: true,
                fontSize: 24
            ) {
                session.appendNote(cell)
            }
        }
    }

    private func layoutToggle(compact: Bool) -> some View {
        Button {
            withAnimation(AppAnimation.quickSpring) {
                useCalculator.toggle()
            }
            HapticManager.shared.selectionChanged()
        } label: {
            Image(systemName: useCalculator ? "rectangle.split.3x1" : "square.grid.3x3")
                .font(.system(size: compact ? 18 : 20, weight: .semibold))
                .foregroundColor(.inkSecondary)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(
                    Spacing.shapeMedium
                        .fill(Color.surfaceCard.opacity(0.55))
                        .overlay(
                            Spacing.shapeMedium
                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(useCalculator ? "Switch to linear note row" : "Switch to calculator pad")
    }

    // MARK: Keys

    private func utilKey(
        title: String,
        fill: Color,
        ink: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(ink)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(Spacing.shapeMedium.fill(fill))
        }
        .buttonStyle(CalcPressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.65)
        .accessibilityLabel(title == "Clear" ? "Clear all notes" : title)
    }

    private func padKey(
        title: String,
        fill: Color,
        enabled: Bool,
        expands: Bool = false,
        fontSize: CGFloat? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let isMusicSymbol = title == "♭" || title == "♯" || title == "⌫"
        let size = fontSize ?? (isMusicSymbol ? 26 : 22)

        return Button(action: action) {
            Text(verbatim: title)
                .font(.system(size: size, weight: .bold, design: isMusicSymbol ? .default : .rounded))
                .foregroundColor(.textOnLight)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: expands ? .infinity : nil)
                .frame(minHeight: expands ? nil : utilRowHeight)
                .background(
                    Spacing.shapeMedium
                        .fill(fill)
                        .overlay(
                            Spacing.shapeMedium
                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(CalcPressStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : (title == "⌫" ? 0.65 : 0.45))
        .accessibilityLabel(a11y(title))
    }

    private func a11y(_ title: String) -> String {
        switch title {
        case "♯": return "Sharp"
        case "♭": return "Flat"
        case "⌫": return "Delete last note"
        default: return "Note \(title)"
        }
    }

    // MARK: Notes row in result

    private func notesRow(chipHeight: CGFloat) -> some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Array(session.notes.enumerated()), id: \.offset) { index, note in
                Button {
                    withAnimation(AppAnimation.quickSpring) {
                        session.removeNote(at: index)
                    }
                } label: {
                    NotesResultNoteCard(note: note, height: chipHeight)
                }
                .buttonStyle(CalcPressStyle())
                .accessibilityLabel("Remove note \(note)")
            }
        }
    }
}

// MARK: - Supporting views

private struct NotesResultNoteCard: View {
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

struct NotesTheoryView_Previews: PreviewProvider {
    static var previews: some View {
        NotesTheoryView()
            .environmentObject(NotesSessionState())
            .background(Color.brandBeige.ignoresSafeArea())
    }
}
