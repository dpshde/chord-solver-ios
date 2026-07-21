//
//  OptionChipPicker.swift
//  Chord Solver
//
//  Large, easy-to-tap option tiles for chord qualities / scale types.
//  iOS HIG: ≥44pt touch targets, breathing room, clear selected state.
//

import SwiftUI

/// A single selectable option.
struct ChipOption: Identifiable, Equatable {
    let id: String
    /// Primary label (friendly name when possible).
    let title: String
    /// Optional theory shorthand shown under the title.
    var detail: String? = nil
    let isActive: Bool
    let action: () -> Void

    static func == (lhs: ChipOption, rhs: ChipOption) -> Bool {
        lhs.id == rhs.id && lhs.isActive == rhs.isActive && lhs.title == rhs.title
    }
}

// MARK: - Tile grid (primary control)

/// Adaptive grid: 2 columns for choices, full-width when a single selected option is shown.
struct OptionTileGrid: View {
    let options: [ChipOption]
    let activeFill: Color
    /// Optional stronger fill for selected state (section accent).
    var selectedAccent: Color? = nil
    /// When true, show a checkmark on the active tile (collapsed selection mode).
    var showsSelectionCheckmark: Bool = false

    private var columns: [GridItem] {
        if options.count <= 1 {
            return [GridItem(.flexible(), spacing: Spacing.sm)]
        }
        return [
            GridItem(.flexible(), spacing: Spacing.sm),
            GridItem(.flexible(), spacing: Spacing.sm),
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(options) { option in
                OptionTileButton(
                    title: option.title,
                    detail: option.detail,
                    isActive: option.isActive,
                    activeFill: activeFill,
                    selectedAccent: selectedAccent,
                    showsCheckmark: showsSelectionCheckmark && option.isActive,
                    action: option.action
                )
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
    }
}

/// Large tappable tile (≥52pt height, full half-width).
/// Selected = solid brand fill + white ink; idle = white card + dark ink.
struct OptionTileButton: View {
    let title: String
    var detail: String? = nil
    let isActive: Bool
    /// Solid brand color when selected (must support white text).
    let activeFill: Color
    var selectedAccent: Color? = nil
    var showsCheckmark: Bool = false
    let action: () -> Void

    private var fill: Color {
        isActive ? (selectedAccent ?? activeFill) : Color.surfaceCard
    }

    private var labelColor: Color {
        isActive ? .inkOnAccent : .inkPrimary
    }

    private var detailColor: Color {
        isActive ? Color.white.opacity(0.85) : .inkSecondary
    }

    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.mediumImpact()
        }) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: showsCheckmark ? .leading : .center, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    if let detail, !detail.isEmpty, detail != title {
                        Text(detail)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(detailColor)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: showsCheckmark ? .leading : .center)

                if showsCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.inkOnAccent)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, showsCheckmark ? Spacing.contentPadding : Spacing.sm)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
                    .strokeBorder(
                        isActive ? Color.clear : Color.borderSubtle,
                        lineWidth: 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous))
        }
        .buttonStyle(PressableTileStyle())
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .animation(AppAnimation.quickSpring, value: isActive)
    }
}

/// Slight press scale — no bouncy overshoot.
private struct PressableTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Grouped picker (Common + More)

/// Option picker with Apple-style progressive disclosure:
/// - Browsing: common tiles + trailing “Show More / Show Less” disclosure
/// - After selection: only the selected option + “Change” (results shown by parent)
///
/// Disclosure follows HIG: label leading, chevron trailing; paired “Show More/Less”
/// wording; chevron.down rotates 180° when expanded (system-like disclosure).
struct GroupedOptionPicker: View {
    let sectionTitle: String
    let common: [ChipOption]
    let moreGroups: [(title: String, options: [ChipOption])]
    let activeFill: Color
    var selectedAccent: Color? = nil
    /// Bound for parent convenience; mirrors expanded advanced section while browsing.
    @Binding var showMore: Bool

    /// When false and something is selected, collapse to the single selected option.
    @State private var isBrowsing: Bool = true

    private var allMoreOptions: [ChipOption] {
        moreGroups.flatMap(\.options)
    }

    private var activeOption: ChipOption? {
        if let commonActive = common.first(where: \.isActive) {
            return commonActive
        }
        return allMoreOptions.first(where: \.isActive)
    }

    private var activeOptionID: String? {
        activeOption?.id
    }

    private var hasSelection: Bool {
        activeOption != nil
    }

    /// Collapsed: only the selected option. Browsing: full common set.
    private var displayedPrimaryOptions: [ChipOption] {
        if !isBrowsing, let active = activeOption {
            return [commitWrapped(active)]
        }
        return common.map(commitWrapped)
    }

    private var moreGroupsForDisplay: [(title: String, options: [ChipOption])] {
        moreGroups.map { group in
            (title: group.title, options: group.options.map(commitWrapped))
        }
    }

    /// Every option tap commits the selection and collapses (even re-tapping the same id).
    private func commitWrapped(_ option: ChipOption) -> ChipOption {
        ChipOption(
            id: option.id,
            title: option.title,
            detail: option.detail,
            isActive: option.isActive
        ) {
            option.action()
            withAnimation(AppAnimation.quickSpring) {
                isBrowsing = false
                showMore = false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(sectionTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.textOnLight.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, Spacing.screenPadding)

            OptionTileGrid(
                options: displayedPrimaryOptions,
                activeFill: activeFill,
                selectedAccent: selectedAccent,
                showsSelectionCheckmark: !isBrowsing && hasSelection
            )

            if isBrowsing {
                browsingChrome
            } else if hasSelection {
                // HIG: explicit “Change” control after a committed selection (Settings-style).
                DisclosureControlButton(
                    title: "Change",
                    isExpanded: false,
                    showsChevron: true,
                    chevronSystemName: "chevron.right"
                ) {
                    withAnimation(AppAnimation.quickSpring) {
                        isBrowsing = true
                        // Jump straight into the full catalog (common + advanced).
                        showMore = true
                    }
                    HapticManager.shared.lightImpact()
                }
            }
        }
        .onChange(of: activeOptionID) { oldID, newID in
            if newID == nil, oldID != nil {
                // Selection cleared — return to browsing.
                withAnimation(AppAnimation.quickSpring) {
                    isBrowsing = true
                    showMore = false
                }
            }
        }
        .onAppear {
            // Restore collapsed selection state if we already have a pick (tab switch).
            if hasSelection {
                isBrowsing = false
                showMore = false
            }
        }
    }

    @ViewBuilder
    private var browsingChrome: some View {
        if !moreGroups.isEmpty {
            // HIG disclosure: trailing chevron, Show More / Show Less pair.
            DisclosureControlButton(
                title: showMore ? "Show Less" : "Show More",
                isExpanded: showMore,
                showsChevron: true,
                chevronSystemName: "chevron.down"
            ) {
                withAnimation(AppAnimation.quickSpring) {
                    showMore.toggle()
                }
                HapticManager.shared.lightImpact()
            }

            if showMore {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(Array(moreGroupsForDisplay.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(group.title)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.textOnLight.opacity(0.5))
                                .padding(.horizontal, Spacing.screenPadding)

                            OptionTileGrid(
                                options: group.options,
                                activeFill: activeFill,
                                selectedAccent: selectedAccent
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - HIG-style disclosure control

/// Full-width list row inside a single rounded container so the entire width
/// reads as one tappable control (Settings / inset-grouped row pattern).
/// - Show More / Show Less: rotating chevron.down
/// - Change: chevron.right (opens the full option list)
private struct DisclosureControlButton: View {
    let title: String
    let isExpanded: Bool
    var showsChevron: Bool = true
    var chevronSystemName: String = "chevron.down"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.inkPrimary)

                Spacer(minLength: 0)

                if showsChevron {
                    Image(systemName: chevronSystemName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                        .rotationEffect(
                            .degrees(
                                chevronSystemName == "chevron.down" && isExpanded ? 180 : 0
                            )
                        )
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 52)
            .padding(.horizontal, Spacing.contentPadding)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
                    .fill(Color.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
            )
            .contentShape(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
            )
        }
        .buttonStyle(PressableTileStyle())
        .padding(.horizontal, Spacing.screenPadding)
        .accessibilityLabel(title)
        .accessibilityHint(
            chevronSystemName == "chevron.down"
                ? (isExpanded ? "Collapses additional options" : "Expands additional options")
                : "Shows all options"
        )
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Shared result panel

struct AnswerResultPanel<Content: View>: View {
    let title: String
    let accent: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.inkOnAccent)
                .multilineTextAlignment(.center)

            content()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium, style: .continuous)
                .fill(accent)
                .shadow(color: accent.opacity(0.35), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.top, Spacing.lg)
        .transition(.scaleAndFade)
    }
}

// MARK: - Empty-state coaching

struct InputCoachingLine: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.textOnLight.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.top, Spacing.sm)
    }
}

// MARK: - Root field with clear (large target)

struct RootNoteField: View {
    let placeholder: String
    let root: String
    let isKeyboardVisible: Bool
    let accentTint: Color
    let onToggleKeyboard: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: onToggleKeyboard) {
                HStack {
                    Text(root.isEmpty ? placeholder : root)
                        .foregroundColor(root.isEmpty ? .inkTertiary : .inkPrimary)
                        .font(.noteName)

                    Spacer()

                    Image(systemName: isKeyboardVisible ? "keyboard.chevron.compact.down" : "keyboard")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isKeyboardVisible ? accentTint : .inkSecondary)
                        .frame(width: 28, height: 28)
                }
                .padding(.horizontal, Spacing.contentPadding)
                .frame(minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
                        .fill(Color.surfaceCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous)
                                .strokeBorder(
                                    isKeyboardVisible ? accentTint : Color.borderStrong,
                                    lineWidth: isKeyboardVisible ? 2 : 1
                                )
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall, style: .continuous))
            }
            .buttonStyle(PressableTileStyle())

            if !root.isEmpty {
                Button(action: {
                    onClear()
                    HapticManager.shared.lightImpact()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.inkTertiary)
                        .frame(width: 48, height: 56)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableTileStyle())
                .accessibilityLabel("Clear root")
            }
        }
        .padding(.horizontal, Spacing.screenPadding)
    }
}
