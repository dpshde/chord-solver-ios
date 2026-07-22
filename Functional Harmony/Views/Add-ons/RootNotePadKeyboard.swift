//
//  RootNotePadKeyboard.swift
//  Functional Harmony
//
//  Shared root note pad for Chords / Scales.
//  Linear row, or Notes-pad parity calculator (3×3 with ♭ B ♯ on the bottom).
//

import SwiftUI

// MARK: - Layout preference

/// Persisted via `@AppStorage(RootNotePadLayout.storageKey)`.
enum RootNotePadLayout: String, CaseIterable {
    case linear
    case calculator

    static let storageKey = "notePad.calculatorLayout"

    /// Default when the preference key has never been set: expanded 3×3 calculator.
    static let defaultUsesCalculator = true

    /// `true` → calculator (3×3). Stored as Bool for a simple AppStorage flag.
    static func fromCalculatorFlag(_ useCalculator: Bool) -> RootNotePadLayout {
        useCalculator ? .calculator : .linear
    }
}

// MARK: - Shared root pad

/// Single-root note entry with linear or calculator chrome.
/// Semantics stay root-only (not Notes multi-note).
struct RootNotePadKeyboard: View {
    @Binding var noteText: String
    /// Extra ⌫ on empty root clears quality/scale.
    var canClearQuality: Bool = false
    var onRootEmpty: (() -> Void)? = nil
    /// Swipe up while already on the calculator pad (e.g. open Quality/Scale Change).
    var onSwipeUpWhenExpanded: (() -> Void)? = nil
    /// Swipe down when already linear (or to peel Change first). Return `true` if handled.
    var onSwipeDownBack: (() -> Bool)? = nil
    /// Selection wash (e.g. lightTintCoral / lightTintPurple).
    var selectedFill: Color = .lightTintCoral
    /// Selection border (e.g. brandCoral / brandPurple).
    var selectedStroke: Color = .brandCoral

    @AppStorage(RootNotePadLayout.storageKey) private var useCalculator = RootNotePadLayout.defaultUsesCalculator
    @State private var pressedButton: String? = nil

    private let gap: CGFloat = 10
    private let utilRowHeight: CGFloat = 56
    private let naturalNotes = ["C", "D", "E", "F", "G", "A", "B"]

    /// Matches Notes pad: C-start 3×3 with accidentals on the bottom corners.
    private let calculatorGrid: [[String]] = [
        ["C", "D", "E"],
        ["F", "G", "A"],
        ["♭", "B", "♯"],
    ]

    /// Slightly deeper paper for ♭ / ♯ — same idea as Notes accent keys.
    private var accentKeyFill: Color {
        Color.darkBeige
    }

    private var layout: RootNotePadLayout {
        RootNotePadLayout.fromCalculatorFlag(useCalculator)
    }

    private var canBackspace: Bool {
        !noteText.isEmpty || canClearQuality
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

    var body: some View {
        VStack(spacing: gap) {
            if layout == .calculator {
                calculatorUtilRow
                calculatorPad
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                linearUtilRow
                linearPad
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(AppAnimation.quickSpring, value: useCalculator)
        .contentShape(Rectangle())
        .notePadSwipeLayout(
            useCalculator: $useCalculator,
            onSwipeUpWhenExpanded: onSwipeUpWhenExpanded,
            onSwipeDownBack: onSwipeDownBack,
            onSwipeDownWhenCollapsed: { backspace() }
        )
        .accessibilityHint(swipeAccessibilityHint)
    }

    private var swipeAccessibilityHint: String {
        if onSwipeUpWhenExpanded != nil {
            return "Swipe up for calculator, again to change selection; swipe down to collapse or backspace"
        }
        return "Swipe up for calculator pad, swipe down to collapse or backspace"
    }

    // MARK: Util rows

    /// Linear: ♭ · ♯ · layout · ⌫
    private var linearUtilRow: some View {
        HStack(spacing: gap) {
            padKey(
                label: "♭",
                isSelected: hasFlatAccidental,
                fill: Color.surfaceCard.opacity(0.55),
                enabled: canApplyAccidental
            ) {
                appendAccidental("b")
            }

            padKey(
                label: "♯",
                isSelected: hasSharpAccidental,
                fill: Color.surfaceCard.opacity(0.55),
                enabled: canApplyAccidental
            ) {
                appendAccidental("#")
            }

            Spacer(minLength: 8)

            layoutToggle(compact: true)
                .frame(maxWidth: 56)

            padKey(
                label: "⌫",
                fill: canBackspace ? Color.mutedRed : Color.backspaceIdle,
                enabled: canBackspace
            ) {
                backspace()
            }
            .frame(maxWidth: 88)
        }
        .frame(height: utilRowHeight)
    }

    /// Calculator (Notes pad parity): layout toggle | ⌫ — full-width util pair above the 3×3.
    private var calculatorUtilRow: some View {
        HStack(spacing: gap) {
            layoutToggle(compact: false)
            padKey(
                label: "⌫",
                fill: canBackspace ? Color.mutedRed : Color.backspaceIdle,
                enabled: canBackspace,
                expands: true
            ) {
                backspace()
            }
        }
        .frame(height: utilRowHeight)
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
                                .strokeBorder(Color.borderSubtle, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(useCalculator ? "Switch to linear note row" : "Switch to calculator pad")
        .accessibilityHint("Or swipe down to collapse, swipe up to expand")
    }

    // MARK: Pads

    private var linearPad: some View {
        HStack(spacing: gap) {
            ForEach(naturalNotes, id: \.self) { note in
                padKey(
                    label: note,
                    isSelected: noteText.starts(with: note),
                    fill: Color.surfaceCard.opacity(0.72)
                ) {
                    appendNote(note)
                }
            }
        }
        .frame(height: utilRowHeight)
    }

    private var calculatorPad: some View {
        // Compact enough that Quality stays above the liquid-glass tab bar.
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
                label: "♭",
                isSelected: hasFlatAccidental,
                fill: accentKeyFill,
                enabled: canApplyAccidental,
                expands: true,
                fontSize: 26
            ) {
                appendAccidental("b")
            }
        case "♯":
            padKey(
                label: "♯",
                isSelected: hasSharpAccidental,
                fill: accentKeyFill,
                enabled: canApplyAccidental,
                expands: true,
                fontSize: 26
            ) {
                appendAccidental("#")
            }
        default:
            padKey(
                label: cell,
                isSelected: noteText.starts(with: cell),
                fill: Color.surfaceCard.opacity(0.72),
                expands: true,
                fontSize: 24
            ) {
                appendNote(cell)
            }
        }
    }

    // MARK: Key chrome

    private func padKey(
        label: String,
        isSelected: Bool = false,
        fill: Color,
        enabled: Bool = true,
        expands: Bool = false,
        fontSize: CGFloat? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let isMusicSymbol = label == "♭" || label == "♯" || label == "⌫"
        let size = fontSize ?? (isMusicSymbol ? 26 : 22)
        let isPressed = pressedButton == label

        return Button(action: action) {
            Text(verbatim: label)
                .font(.system(
                    size: size,
                    weight: .bold,
                    design: isMusicSymbol ? .default : .rounded
                ))
                .foregroundColor(.textOnLight)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: expands ? .infinity : nil)
                .frame(minHeight: expands ? nil : utilRowHeight)
                .background(
                    Spacing.shapeMedium
                        .fill(isSelected ? selectedFill : fill)
                        .overlay(
                            Spacing.shapeMedium
                                .strokeBorder(
                                    isSelected ? selectedStroke.opacity(0.7) : Color.borderSubtle,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : (label == "⌫" ? 0.65 : 0.45))
    }

    // MARK: Actions

    private func appendNote(_ note: String) {
        withAnimation(AppAnimation.quickSpring) {
            noteText = note
        }
        flash(note)
        HapticManager.shared.mediumImpact()
    }

    private func appendAccidental(_ accidental: String) {
        guard !noteText.isEmpty else {
            flash(accidental == "#" ? "♯" : "♭")
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
        flash(accidental == "#" ? "♯" : "♭")
        HapticManager.shared.lightImpact()
    }

    private func backspace() {
        if !noteText.isEmpty {
            withAnimation(AppAnimation.quickSpring) {
                noteText.removeLast()
            }
        } else if canClearQuality {
            onRootEmpty?()
        }
        flash("⌫")
        HapticManager.shared.rigidImpact()
    }

    private func flash(_ key: String) {
        pressedButton = key
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pressedButton = nil
        }
    }
}

// MARK: - Swipe expand / collapse

extension View {
    /// Progressive pad gestures (pad owns the drag so parent ScrollViews do not bounce):
    /// - Swipe up: linear → calculator → `onSwipeUpWhenExpanded` (Change)
    /// - Swipe down: calculator → linear; linear → `onSwipeDownBack` (optional) or backspace
    ///
    /// `highPriorityGesture` + `minimumDistance` keeps short taps on keys working while
    /// vertical flicks never fall through to a ScrollView rubber-band.
    func notePadSwipeLayout(
        useCalculator: Binding<Bool>,
        onSwipeUpWhenExpanded: (() -> Void)? = nil,
        onSwipeDownBack: (() -> Bool)? = nil,
        onSwipeDownWhenCollapsed: (() -> Void)? = nil
    ) -> some View {
        modifier(
            NotePadSwipeLayoutModifier(
                useCalculator: useCalculator,
                onSwipeUpWhenExpanded: onSwipeUpWhenExpanded,
                onSwipeDownBack: onSwipeDownBack,
                onSwipeDownWhenCollapsed: onSwipeDownWhenCollapsed
            )
        )
    }
}

private struct NotePadSwipeLayoutModifier: ViewModifier {
    @Binding var useCalculator: Bool
    var onSwipeUpWhenExpanded: (() -> Void)?
    var onSwipeDownBack: (() -> Bool)?
    var onSwipeDownWhenCollapsed: (() -> Void)?

    /// Ignore tiny flicks; require a deliberate vertical drag (taps still hit keys).
    private let minDistance: CGFloat = 28
    private let minVertical: CGFloat = 48
    /// Prefer vertical over diagonal (dy must dominate dx).
    private let verticalDominance: CGFloat = 1.15

    func body(content: Content) -> some View {
        content.highPriorityGesture(
            DragGesture(minimumDistance: minDistance, coordinateSpace: .local)
                .onEnded { value in
                    let dy = value.translation.height
                    let dx = value.translation.width
                    guard abs(dy) >= minVertical else { return }
                    guard abs(dy) >= abs(dx) * verticalDominance else { return }

                    if dy < 0 {
                        // Swipe up → expand calculator, or second swipe → Change menu
                        if !useCalculator {
                            withAnimation(AppAnimation.quickSpring) {
                                useCalculator = true
                            }
                            HapticManager.shared.selectionChanged()
                        } else if let onSwipeUpWhenExpanded {
                            onSwipeUpWhenExpanded()
                        }
                    } else {
                        // Swipe down → collapse calculator, else optional Change-back, else backspace
                        if useCalculator {
                            withAnimation(AppAnimation.quickSpring) {
                                useCalculator = false
                            }
                            HapticManager.shared.selectionChanged()
                            return
                        }
                        if let onSwipeDownBack, onSwipeDownBack() {
                            return
                        }
                        onSwipeDownWhenCollapsed?()
                    }
                }
        )
    }
}

// MARK: - Chords / Scales thin wrappers

struct TriadNotePickerKeyboard: View {
    @Binding var noteText: String
    var canClearQuality: Bool = false
    var onRootEmpty: (() -> Void)? = nil
    var onSwipeUpWhenExpanded: (() -> Void)? = nil
    var onSwipeDownBack: (() -> Bool)? = nil

    var body: some View {
        RootNotePadKeyboard(
            noteText: $noteText,
            canClearQuality: canClearQuality,
            onRootEmpty: onRootEmpty,
            onSwipeUpWhenExpanded: onSwipeUpWhenExpanded,
            onSwipeDownBack: onSwipeDownBack,
            selectedFill: .lightTintCoral,
            selectedStroke: .brandCoral
        )
    }
}

struct ScaleNotePickerKeyboard: View {
    @Binding var noteText: String
    var canClearQuality: Bool = false
    var onRootEmpty: (() -> Void)? = nil
    var onSwipeUpWhenExpanded: (() -> Void)? = nil
    var onSwipeDownBack: (() -> Bool)? = nil

    var body: some View {
        RootNotePadKeyboard(
            noteText: $noteText,
            canClearQuality: canClearQuality,
            onRootEmpty: onRootEmpty,
            onSwipeUpWhenExpanded: onSwipeUpWhenExpanded,
            onSwipeDownBack: onSwipeDownBack,
            selectedFill: .lightTintPurple,
            selectedStroke: .brandPurple
        )
    }
}
