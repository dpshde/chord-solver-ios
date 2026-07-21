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

/// Shared control height for option tiles and collapsed Change control.
enum OptionControlMetrics {
    static let height: CGFloat = 56
}

/// Large tappable tile (fixed control height, full half-width).
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
            .frame(height: OptionControlMetrics.height)
            .padding(.horizontal, showsCheckmark ? Spacing.contentPadding : Spacing.sm)
            .background(
                Spacing.shapeSmall
                    .fill(fill)
            )
            .overlay(
                Spacing.shapeSmall
                    .strokeBorder(
                        isActive ? Color.clear : Color.borderSubtle,
                        lineWidth: 1
                    )
            )
            .contentShape(Spacing.shapeSmall)
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
            .animation(AppAnimation.press, value: configuration.isPressed)
    }
}

// MARK: - Grouped picker (select → collapse to selected only)

/// Common + optional More. Selecting any option collapses More and shows only
/// the selected tile; “Change” re-opens the full catalog.
struct GroupedOptionPicker: View {
    let sectionTitle: String
    let common: [ChipOption]
    let moreGroups: [(title: String, options: [ChipOption])]
    let activeFill: Color
    var selectedAccent: Color? = nil
    /// Full option catalog is open (vs collapsed Change + selected chip).
    @Binding var isCatalogExpanded: Bool
    @Binding var showMore: Bool

    private var allMoreOptions: [ChipOption] {
        moreGroups.flatMap(\.options)
    }

    private var activeOption: ChipOption? {
        if let commonActive = common.first(where: \.isActive) {
            return commonActive
        }
        return allMoreOptions.first(where: \.isActive)
    }

    private var hasSelection: Bool {
        activeOption != nil
    }

    /// Expanded: full common set. Collapsed: single selected tile only.
    private var displayedPrimaryOptions: [ChipOption] {
        if !isCatalogExpanded, let active = activeOption {
            return [commitWrapped(active)]
        }
        return common.map(commitWrapped)
    }

    private var moreGroupsWrapped: [(title: String, options: [ChipOption])] {
        moreGroups.map { group in
            (title: group.title, options: group.options.map(commitWrapped))
        }
    }

    /// Tapping any option commits and collapses catalog + More.
    private func commitWrapped(_ option: ChipOption) -> ChipOption {
        ChipOption(
            id: option.id,
            title: option.title,
            detail: option.detail,
            isActive: option.isActive
        ) {
            option.action()
            withAnimation(AppAnimation.quickSpring) {
                isCatalogExpanded = false
                showMore = false
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(sectionTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.inkSecondary)
                .textCase(.uppercase)
                .tracking(0.4)
                .padding(.horizontal, Spacing.screenPadding)

            if isCatalogExpanded {
                OptionTileGrid(
                    options: displayedPrimaryOptions,
                    activeFill: activeFill,
                    selectedAccent: selectedAccent,
                    showsSelectionCheckmark: false
                )

                // Advanced groups first, then Show More/Less at the bottom.
                if showMore && !moreGroups.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        ForEach(Array(moreGroupsWrapped.enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(group.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.inkSecondary)
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

                if !moreGroups.isEmpty {
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
                }
            } else if let active = activeOption {
                // One row: Change (left) · selected quality (right).
                collapsedSelectionRow(active: active)
            }
        }
        .onChange(of: activeOption?.id) { _, newID in
            // Cleared selection → expand catalog again.
            if newID == nil {
                withAnimation(AppAnimation.quickSpring) {
                    isCatalogExpanded = true
                    showMore = false
                }
            }
        }
        .onAppear {
            // After tab switch, keep collapsed if a quality is already chosen.
            if hasSelection {
                isCatalogExpanded = false
                showMore = false
            }
        }
    }

    /// Collapsed chrome: Change (compact, left) · selected quality (fills right).
    /// Both controls share `OptionControlMetrics.height`.
    private func collapsedSelectionRow(active: ChipOption) -> some View {
        HStack(alignment: .center, spacing: Spacing.sm) {
            Button(action: expandCatalog) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.inkSecondary)
                    Text("Change")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.inkPrimary)
                        .lineLimit(1)
                }
                .padding(.horizontal, Spacing.md)
                .frame(height: OptionControlMetrics.height)
                .background(
                    Spacing.shapeSmall
                        .fill(Color.surfaceCard)
                )
                .overlay(
                    Spacing.shapeSmall
                        .strokeBorder(Color.borderSubtle, lineWidth: 1)
                )
                .contentShape(Spacing.shapeSmall)
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: true, vertical: true)
            .zIndex(1)
            .accessibilityLabel("Change selection")
            .accessibilityAddTraits(.isButton)

            OptionTileButton(
                title: active.title,
                detail: active.detail,
                isActive: true,
                activeFill: activeFill,
                selectedAccent: selectedAccent,
                showsCheckmark: true,
                // Re-tapping selected quality also re-opens the catalog (same as Change).
                action: expandCatalog
            )
            .frame(maxWidth: .infinity)
            .frame(height: OptionControlMetrics.height)
            .layoutPriority(-1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: OptionControlMetrics.height)
        .padding(.horizontal, Spacing.screenPadding)
    }

    private func expandCatalog() {
        withAnimation(AppAnimation.quickSpring) {
            isCatalogExpanded = true
            // Always open full advanced list when changing.
            showMore = !moreGroups.isEmpty
        }
        HapticManager.shared.lightImpact()
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
            .frame(height: OptionControlMetrics.height)
            .padding(.horizontal, Spacing.contentPadding)
            .background(
                Spacing.shapeSmall
                    .fill(Color.surfaceCard)
            )
            .overlay(
                Spacing.shapeSmall
                    .strokeBorder(Color.borderSubtle, lineWidth: 1)
            )
            .contentShape(
                Spacing.shapeSmall
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
    /// When set, panel keeps at least this height (empty + filled banners can match).
    var minHeight: CGFloat? = nil
    /// Vertically center title + content inside the min-height chrome (instruction banners).
    var verticallyCenterContent: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if verticallyCenterContent { Spacer(minLength: 0) }

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.inkOnAccent)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            content()
                .frame(maxWidth: .infinity, alignment: .center)

            if verticallyCenterContent { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, minHeight: innerMinHeight, alignment: .center)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .center)
        .background(
            Spacing.shapeMedium
                .fill(accent)
                .shadow(color: accent.opacity(0.18), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, Spacing.screenPadding)
        .fixedSize(horizontal: false, vertical: minHeight == nil)
        .transition(.opacity)
    }

    /// Min height for the stack inside padding so Spacers can absorb free vertical space.
    private var innerMinHeight: CGFloat? {
        guard let minHeight else { return nil }
        return max(0, minHeight - Spacing.md * 2)
    }
}

// MARK: - Canvas edge fade (soften result / controls split)

/// Vertical gradient that blends content into the app canvas color.
struct CanvasEdgeFade: View {
    enum Edge {
        case top
        case bottom
    }

    var edge: Edge = .top
    var height: CGFloat = 36
    var color: Color = .brandBeige

    var body: some View {
        LinearGradient(
            colors: edge == .top
                ? [color, color.opacity(0)]
                : [color.opacity(0), color],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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

// MARK: - Root field (large target; use keyboard ⌫ to edit)

struct RootNoteField: View {
    let placeholder: String
    let root: String
    let isKeyboardVisible: Bool
    let accentTint: Color
    let onToggleKeyboard: () -> Void

    var body: some View {
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
                Spacing.shapeSmall
                    .fill(Color.surfaceCard)
                    .overlay(
                        Spacing.shapeSmall
                            .strokeBorder(
                                isKeyboardVisible ? accentTint : Color.borderStrong,
                                lineWidth: isKeyboardVisible ? 2 : 1
                            )
                    )
            )
            .contentShape(Spacing.shapeSmall)
        }
        .buttonStyle(PressableTileStyle())
        .padding(.horizontal, Spacing.screenPadding)
    }
}
