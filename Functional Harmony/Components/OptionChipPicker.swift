//
//  OptionChipPicker.swift
//  Functional Harmony
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
            // UI mutation first; haptic after paint so selection never trails feedback.
            action()
            HapticManager.shared.afterUIUpdate {
                HapticManager.shared.mediumImpact()
            }
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
        // Note: do NOT collapse on appear here. Chords/Scales wrap this picker in
        // different containers when the catalog expands (ScrollView vs intrinsic),
        // which remounts us. Collapsing on appear would immediately undo Change.
        // Parents collapse on their own onAppear for tab re-entry.
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

// MARK: - Shared result banner

/// Full-width accent banner for chord / scale / notes / interval answers.
struct AnswerResultPanel<Content: View>: View {
    let title: String
    let accent: Color
    /// When set, panel keeps at least this height (empty + filled banners can match).
    var minHeight: CGFloat? = nil
    /// Vertically center title + content inside the chrome.
    var verticallyCenterContent: Bool = false
    /// Stretch to fill the parent’s offered height (hero top region above controls).
    var expandsToFill: Bool = false
    /// Bleed accent into the top safe area (status bar region).
    var bleedTopSafeArea: Bool = false
    /// When set, shows a top-leading sound toggle and enables tap-to-play on the rest of the panel.
    var isSoundOn: Binding<Bool>? = nil
    /// Invoked when the user taps the result surface (not the sound toggle). Gated by `isSoundOn` at call sites.
    var onPlayTap: (() -> Void)? = nil
    /// When true, shows the loop-mode toggle beside the play indicator (scales).
    var showsLoopToggle: Bool = false
    @ViewBuilder let content: () -> Content

    private var centersContent: Bool {
        verticallyCenterContent || expandsToFill
    }

    private var isPlayable: Bool {
        isSoundOn != nil && onPlayTap != nil
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if centersContent { Spacer(minLength: 0) }

                // Title + body stay a tight unit (no spacer between them).
                VStack(spacing: Spacing.sm) {
                    ResultTitleText(
                        title: title,
                        scale: expandsToFill ? .hero : .compact
                    )
                    .foregroundColor(.inkOnAccent)
                    .frame(maxWidth: .infinity)

                    content()
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if centersContent { Spacer(minLength: 0) }
            }
            .frame(maxWidth: .infinity, minHeight: innerMinHeight, alignment: .center)
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: expandsToFill ? .infinity : nil, alignment: .center)
            .frame(minHeight: minHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isPlayable else { return }
                onPlayTap?()
            }
            .accessibilityAddTraits(isPlayable ? .isButton : [])
            .accessibilityHint(isPlayable ? "Plays the result when sound is on" : "")

        }
        .overlay(alignment: .topLeading) {
            if let isSoundOn {
                ResultSoundToggle(isOn: isSoundOn)
                    // Pull slightly into the margin so the 48pt hit box reaches the corner.
                    .padding(.leading, max(0, Spacing.screenPadding - 6))
                    .padding(.top, max(0, Spacing.sm - 4))
            }
        }
        .overlay(alignment: .topTrailing) {
            // Hide play chrome while muted — result taps also produce no audio.
            if isPlayable, let isSoundOn, isSoundOn.wrappedValue {
                ResultPlaybackChrome(showsLoopToggle: showsLoopToggle, onPlayTap: onPlayTap)
                    .padding(.trailing, max(0, Spacing.screenPadding - 6))
                    .padding(.top, max(0, Spacing.sm - 4))
            }
        }
        .background {
            Group {
                if bleedTopSafeArea {
                    accent.ignoresSafeArea(edges: .top)
                } else {
                    accent
                }
            }
            .shadow(color: accent.opacity(0.16), radius: 8, x: 0, y: 4)
        }
        .fixedSize(horizontal: false, vertical: !expandsToFill && minHeight == nil)
    }

    /// Min height for the stack inside padding so Spacers can absorb free vertical space.
    private var innerMinHeight: CGFloat? {
        guard let minHeight else { return nil }
        return max(0, minHeight - Spacing.md * 2)
    }
}

// MARK: - Result chrome controls

/// Shared hit target for result chrome buttons (icon stays ~18pt; pad is HIG-friendly).
private enum ResultChromeMetrics {
    static let hitSize: CGFloat = 48
    static let iconSize: CGFloat = 18
}

/// Speaker control for playable chord/scale result chrome (top-left).
struct ResultSoundToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
            if !isOn {
                PianoSamplePlayer.shared.stop()
            }
            HapticManager.shared.selectionChanged()
        } label: {
            Image(systemName: isOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: ResultChromeMetrics.iconSize, weight: .semibold))
                .foregroundColor(.inkOnAccent)
                .frame(width: ResultChromeMetrics.hitSize, height: ResultChromeMetrics.hitSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Sound on" : "Sound off")
        .accessibilityHint("Toggles audible playback for results")
        .accessibilityAddTraits(.isButton)
    }
}

/// Top-right play control / activity indicator (shown only when sound is on).
/// No spring animation — state must snap with the audio onset/release grid.
struct ResultPlayButton: View {
    @ObservedObject private var player = PianoSamplePlayer.shared
    var onPlayTap: (() -> Void)?

    var body: some View {
        Button {
            onPlayTap?()
        } label: {
            Image(systemName: player.isPlaying ? "waveform" : "play.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.inkOnAccent.opacity(player.isPlaying ? 1 : 0.85))
                .frame(width: ResultChromeMetrics.hitSize, height: ResultChromeMetrics.hitSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(onPlayTap == nil)
        .accessibilityLabel(player.isPlaying ? "Playing" : "Play result")
        .accessibilityHint("Plays the result")
        .accessibilityAddTraits(.isButton)
    }
}

/// Loop-mode toggle + play control for scale result chrome.
/// Loop is a mode switch for the play surface — it never starts or stops audio by itself.
struct ResultPlaybackChrome: View {
    @ObservedObject private var player = PianoSamplePlayer.shared
    var showsLoopToggle: Bool = false
    var onPlayTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            if showsLoopToggle {
                Button {
                    player.toggleLoopEnabled()
                    HapticManager.shared.selectionChanged()
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.inkOnAccent.opacity(player.isLoopEnabled ? 1 : 0.8))
                        .frame(width: ResultChromeMetrics.hitSize, height: ResultChromeMetrics.hitSize)
                        .background {
                            if player.isLoopEnabled {
                                Circle()
                                    .fill(Color.inkOnAccent.opacity(0.24))
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .animation(AppAnimation.quickSpring, value: player.isLoopEnabled)
                .accessibilityLabel("Loop scale up and back")
                .accessibilityValue(player.isLoopEnabled ? "On" : "Off")
                .accessibilityHint("When on, play runs the scale up then back once")
                .accessibilityAddTraits(.isButton)
            }
            ResultPlayButton(onPlayTap: onPlayTap)
        }
    }
}

// MARK: - Landscape fullscreen result

/// Prefer geometry over size class: iPad landscape stays `.regular`, and some
/// tab shells report compact inconsistently. Wider-than-tall is unambiguous.
enum LayoutContext {
    static func isLandscape(size: CGSize) -> Bool {
        size.width > size.height
    }

    static func isLandscapeResult(size: CGSize, hasResult: Bool) -> Bool {
        hasResult && isLandscape(size: size)
    }
}

/// Full-bleed answer presentation for landscape — hides controls and chrome.
struct FullscreenAnswerView<Content: View>: View {
    let title: String
    let accent: Color
    /// When set, shows a top-leading sound toggle and enables tap-to-play on the rest of the surface.
    var isSoundOn: Binding<Bool>? = nil
    var onPlayTap: (() -> Void)? = nil
    /// When true, shows the loop-mode toggle beside the play indicator (scales).
    var showsLoopToggle: Bool = false
    @ViewBuilder let content: () -> Content

    private var isPlayable: Bool {
        isSoundOn != nil && onPlayTap != nil
    }

    var body: some View {
        ZStack {
            accent.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                ResultTitleText(title: title, scale: .fullscreen)
                    .foregroundColor(.inkOnAccent)
                    .padding(.horizontal, Spacing.lg)

                content()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, Spacing.lg)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isPlayable else { return }
                onPlayTap?()
            }
            .accessibilityAddTraits(isPlayable ? .isButton : [])
            .accessibilityHint(isPlayable ? "Plays the result when sound is on" : "")

        }
        .overlay(alignment: .topLeading) {
            if let isSoundOn {
                ResultSoundToggle(isOn: isSoundOn)
                    .padding(.leading, max(0, Spacing.lg - 6))
                    .padding(.top, max(0, Spacing.md - 4))
            }
        }
        .overlay(alignment: .topTrailing) {
            if isPlayable, let isSoundOn, isSoundOn.wrappedValue {
                ResultPlaybackChrome(showsLoopToggle: showsLoopToggle, onPlayTap: onPlayTap)
                    .padding(.trailing, max(0, Spacing.lg - 6))
                    .padding(.top, max(0, Spacing.md - 4))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

/// Bubbles landscape-result fullscreen up so the tab shell can hide the tab bar.
struct LandscapeResultFullscreenKey: PreferenceKey {
    static var defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

/// Switches to a landscape-only result layout when the view is wider than tall
/// and `hasResult` is true. Publishes fullscreen so the tab bar can hide.
struct LandscapeResultContainer<Portrait: View, Landscape: View>: View {
    let hasResult: Bool
    @ViewBuilder var portrait: (_ size: CGSize) -> Portrait
    @ViewBuilder var landscape: () -> Landscape

    var body: some View {
        GeometryReader { geo in
            let fullscreen = LayoutContext.isLandscapeResult(size: geo.size, hasResult: hasResult)

            Group {
                if fullscreen {
                    landscape()
                        .transition(.opacity)
                } else {
                    portrait(geo.size)
                        .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .preference(key: LandscapeResultFullscreenKey.self, value: fullscreen)
            .toolbar(fullscreen ? .hidden : .automatic, for: .tabBar)
            .animation(AppAnimation.smoothSpring, value: fullscreen)
        }
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

// MARK: - Empty result wordmark

/// Brand wordmark shown in the result-banner slot when there is no answer yet.
/// Right-justified condensed title on the app canvas — no accent chrome.
struct EmptyResultWordmark: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("FUNCTIONAL")
            Text("HARMONY")
        }
        .font(.emptyResultWordmark)
        .foregroundColor(.inkPrimary)
        .multilineTextAlignment(.trailing)
        .lineLimit(1)
        .minimumScaleFactor(0.45)
        .tracking(1.2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.vertical, Spacing.md)
        .background {
            Color.brandBeige.ignoresSafeArea(edges: .top)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Functional Harmony")
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
