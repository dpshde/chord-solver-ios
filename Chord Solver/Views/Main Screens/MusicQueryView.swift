//
//  MusicQueryView.swift
//  Chord Solver
//
//  Natural-language entry → maps onto Chords / Scales / Vivace.
//  Live answer preview; open destination only on submit.
//

import SwiftUI

struct MusicQueryView: View {
    @EnvironmentObject private var triadVM: triadBuildViewModel
    @EnvironmentObject private var scalesVM: scalesViewModel
    @EnvironmentObject private var vivaceSession: VivaceSessionState

    @Binding var selectedTab: MainSectionTab

    @State private var query: String = ""
    @FocusState private var fieldFocused: Bool

    private let exampleGroups: [(title: String, accent: Color, samples: [String])] = [
        ("Chords", .brandCoral, ["C major 7", "Bb minor", "G sus4", "C major minor 7"]),
        ("Scales", .brandPurple, ["F# dorian", "Eb harmonic minor", "G mixolydian"]),
        ("Notes", .brandVivace, ["C E G", "Bb D F A"]),
    ]

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

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    searchField

                    if isEmptyState {
                        emptyState
                            .transition(.opacity)
                    } else if liveMatch == nil {
                        Text("No match")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.inkTertiary)
                            .padding(.horizontal, Spacing.screenPadding)
                            .transition(.opacity)
                    }

                    if let match = liveMatch {
                        answerPreview(match)
                            .transition(.opacity)
                    }

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)
                .animation(AppAnimation.quickSpring, value: liveMatch?.summary)
                .animation(AppAnimation.quickSpring, value: canSubmit)
                .animation(AppAnimation.quickSpring, value: trimmedQuery.isEmpty)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { fieldFocused = false }

            // Pin CTA just above the tab bar.
            if canSubmit {
                openButton
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.tabBarClearance)
                    .background(Color.brandBeige)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(AppAnimation.quickSpring, value: canSubmit)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(fieldFocused || canSubmit ? .brandAqua : .inkTertiary)

            TextField("C major 7, F# dorian, C E G…", text: $query)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.inkPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($fieldFocused)
                .submitLabel(.go)
                .onSubmit { submit() }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.inkTertiary)
                }
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, Spacing.md)
        .frame(minHeight: 52)
        .background(
            Spacing.shapeMedium
                .fill(Color.surfaceCard)
                .overlay(
                    Spacing.shapeMedium
                        .strokeBorder(
                            fieldFocused || canSubmit ? Color.brandAqua : Color.borderStrong,
                            lineWidth: fieldFocused || canSubmit ? 2 : 1
                        )
                )
        )
        .padding(.horizontal, Spacing.screenPadding)
    }

    private var openButton: some View {
        Button(action: submit) {
            HStack(spacing: Spacing.sm) {
                Text(openTitle)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.inkOnAccent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .background(Spacing.shapeMedium.fill(destinationColor(liveMatch?.destination ?? .chords)))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.screenPadding)
        .accessibilityHint("Opens the matching tool with this answer")
    }

    private var openTitle: String {
        guard let match = liveMatch else { return "Open" }
        return "Open \(match.tab.title)"
    }

    // MARK: - Answer preview

    private func answerPreview(_ match: MusicQueryMatch) -> some View {
        let preview = MusicQueryPreviewResolver.resolve(match)
        let accent = destinationColor(match.destination)

        return AnswerResultPanel(title: preview.title, accent: accent) {
            VStack(spacing: Spacing.sm) {
                if !preview.notes.isEmpty {
                    if match.destination == .scales {
                        ScaleNotesStrip(notes: preview.notes)
                    } else {
                        HStack(spacing: Spacing.sm) {
                            ForEach(Array(preview.notes.enumerated()), id: \.offset) { _, note in
                                previewNoteChip(note)
                            }
                        }
                    }
                }

                if let detail = preview.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.inkOnAccent.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preview.title). \(preview.notes.joined(separator: ", "))")
    }

    private func previewNoteChip(_ note: String) -> some View {
        Text(note)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(.inkPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                Spacing.shapeMedium
                    .fill(Color.surfaceCard)
            )
            .accessibilityLabel("Note \(note)")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Ask anything musical")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.inkPrimary)
                Text("Chords, scales, or a stack of notes — we’ll open the right tool.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.screenPadding)

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array(exampleGroups.enumerated()), id: \.offset) { _, group in
                    exampleGroupRow(title: group.title, accent: group.accent, samples: group.samples)
                }
            }
        }
        .padding(.top, Spacing.sm)
    }

    private func exampleGroupRow(title: String, accent: Color, samples: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.inkSecondary)
            }
            .padding(.horizontal, Spacing.screenPadding)

            FlowExampleChips(examples: samples) { example in
                query = example
                fieldFocused = true
                HapticManager.shared.lightImpact()
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }

    // MARK: - Submit

    private func submit() {
        fieldFocused = false
        guard let match = liveMatch else {
            if !trimmedQuery.isEmpty {
                HapticManager.shared.warning()
            }
            return
        }
        match.apply(triad: triadVM, scales: scalesVM, vivace: vivaceSession)
        withAnimation(AppAnimation.quickSpring) {
            selectedTab = match.tab
        }
        HapticManager.shared.navigate()
    }

    private func destinationColor(_ d: MusicQueryDestination) -> Color {
        switch d {
        case .chords: return .brandCoral
        case .scales: return .brandPurple
        case .vivace: return .brandVivace
        }
    }
}

// MARK: - Suggestion chips

private struct FlowExampleChips: View {
    let examples: [String]
    let onTap: (String) -> Void

    private let chipHeight: CGFloat = 40

    var body: some View {
        ExampleChipFlow(spacing: Spacing.sm) {
            ForEach(examples, id: \.self) { example in
                Button {
                    onTap(example)
                } label: {
                    Text(example)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.inkSecondary)
                        .lineLimit(1)
                        .padding(.horizontal, Spacing.md)
                        .frame(height: chipHeight)
                        .background(
                            Spacing.shapeSmall
                                .fill(Color.surfaceCard)
                                .overlay(
                                    Spacing.shapeSmall
                                        .strokeBorder(Color.borderSubtle, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: true, vertical: true)
                .accessibilityLabel(example)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExampleChipFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(maxWidth: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(maxWidth: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint], sizes: [CGSize]) {
        var origins: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widthUsed: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            sizes.append(size)
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            widthUsed = max(widthUsed, x - spacing)
        }

        return (CGSize(width: maxWidth.isFinite ? maxWidth : widthUsed, height: y + rowHeight), origins, sizes)
    }
}

struct MusicQueryView_Previews: PreviewProvider {
    static var previews: some View {
        MusicQueryView(selectedTab: .constant(.ask))
            .environmentObject(triadBuildViewModel())
            .environmentObject(scalesViewModel())
            .environmentObject(VivaceSessionState())
            .background(Color.brandBeige.ignoresSafeArea())
    }
}
