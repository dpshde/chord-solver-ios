//
//  MainTabView.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Tab-based navigation — system tab bar uses Liquid Glass on supported OS.
//  App root: sections switch via tabs only (no landing / home button).
//

import SwiftUI

// MARK: - Section routing (testable, separate from chrome styling)

/// Primary switchable sections in the main tab chrome.
/// Ask maps free text onto Chords / Scales / Notes state.
enum MainSectionTab: Int, CaseIterable, Hashable, Identifiable {
    case chords = 0
    case scales = 1
    case notes = 2
    case ask = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .chords: return "Chords"
        case .scales: return "Scales"
        case .notes: return "Notes"
        case .ask: return "Ask"
        }
    }

    var systemImage: String {
        switch self {
        case .chords: return "music.note.list"
        case .scales: return "music.quarternote.3"
        case .notes: return "music.note"
        case .ask: return "text.magnifyingglass"
        }
    }

    var tintColor: Color {
        switch self {
        case .chords: return .brandCoral
        case .scales: return .brandPurple
        case .notes: return .brandNotes
        case .ask: return .brandAqua
        }
    }

    /// Maps a landing / deep-link tab index to a valid section (out-of-range → chords).
    static func resolving(initialTab: Int) -> MainSectionTab {
        MainSectionTab(rawValue: initialTab) ?? .chords
    }

    /// Section titles (same labels as the tab bar).
    static var landingSectionTitles: [String] {
        allCases.map(\.title)
    }

    /// Resolves a section title to a tab; unknown titles return nil.
    /// Accepts legacy "Vivace" as an alias for the Notes tab.
    static func tab(forLandingTitle title: String) -> MainSectionTab? {
        if let match = allCases.first(where: { $0.title == title }) {
            return match
        }
        if title == "Vivace" { return .notes }
        return nil
    }

    /// Ordered tab to the left (nil at first section).
    var previous: MainSectionTab? {
        MainSectionTab(rawValue: rawValue - 1)
    }

    /// Ordered tab to the right (nil at last section).
    var next: MainSectionTab? {
        MainSectionTab(rawValue: rawValue + 1)
    }
}

// MARK: - Interval session (legacy support for IntervalView if linked elsewhere)

final class IntervalSessionState: ObservableObject {
    @Published var bottomNote: String = ""
    @Published var topNote: String = ""
    @Published var intervalResult: String = ""
}

// MARK: - MainTabView

struct MainTabView: View {

    @AppStorage("functionalHarmony.lastSectionRaw") private var lastSectionRaw: Int = 0
    @State private var selectedTab: MainSectionTab
    /// True while a section is presenting landscape fullscreen result.
    @State private var landscapeResultFullscreen = false

    @StateObject private var triadVM = triadBuildViewModel()
    @StateObject private var scalesVM = scalesViewModel()
    @StateObject private var notesSession = NotesSessionState()

    init(initialTab: Int? = nil) {
        let resolved = MainSectionTab.resolving(initialTab: initialTab ?? 0)
        _selectedTab = State(initialValue: resolved)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(
                MainSectionTab.chords.title,
                systemImage: MainSectionTab.chords.systemImage,
                value: MainSectionTab.chords
            ) {
                ChordIdentifierContainerView()
            }

            Tab(
                MainSectionTab.scales.title,
                systemImage: MainSectionTab.scales.systemImage,
                value: MainSectionTab.scales
            ) {
                ScalesContainerView()
            }

            Tab(
                MainSectionTab.notes.title,
                systemImage: MainSectionTab.notes.systemImage,
                value: MainSectionTab.notes
            ) {
                NotesContainerView()
            }

            Tab(
                MainSectionTab.ask.title,
                systemImage: MainSectionTab.ask.systemImage,
                value: MainSectionTab.ask
            ) {
                MusicQueryContainerView(selectedTab: $selectedTab)
            }
        }
        .environmentObject(triadVM)
        .environmentObject(scalesVM)
        .environmentObject(notesSession)
        .tint(selectedTab.tintColor)
        // Edge-only so center vertical pad swipes and scrolling stay free.
        .overlay {
            if !landscapeResultFullscreen {
                TabEdgeSwipeOverlay(selectedTab: $selectedTab)
            }
        }
        .onPreferenceChange(LandscapeResultFullscreenKey.self) { landscapeResultFullscreen = $0 }
        .toolbar(landscapeResultFullscreen ? .hidden : .automatic, for: .tabBar)
        .onAppear {
            // Restore last-used tab on cold launch.
            selectedTab = MainSectionTab.resolving(initialTab: lastSectionRaw)
        }
        .onChange(of: selectedTab) { _, newTab in
            lastSectionRaw = newTab.rawValue
            HapticManager.shared.selectionChanged()
            // Clear stale fullscreen preference when switching sections.
            landscapeResultFullscreen = false
        }
        .accessibilityHint("Swipe from the left or right edge to switch sections")
    }
}

// MARK: - Edge swipe between tabs

/// Invisible hit zones on the screen edges for horizontal tab navigation.
/// - Swipe right from the left edge → previous tab
/// - Swipe left from the right edge → next tab
private struct TabEdgeSwipeOverlay: View {
    @Binding var selectedTab: MainSectionTab

    /// Wide enough to grab from slightly in from the bezel; still leaves pad/content free.
    private let edgeWidth: CGFloat = 36
    private let minDistance: CGFloat = 24
    private let minHorizontal: CGFloat = 56
    private let horizontalDominance: CGFloat = 1.2

    var body: some View {
        HStack(spacing: 0) {
            edgeStrip(leading: true)
            Spacer(minLength: 0)
            edgeStrip(leading: false)
        }
        .allowsHitTesting(true)
        // Don’t block layout or painting of the tab content underneath.
        .accessibilityHidden(true)
    }

    private func edgeStrip(leading: Bool) -> some View {
        Color.clear
            .frame(width: edgeWidth)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            // High priority so edge drags win over nested gestures near the bezel.
            .highPriorityGesture(
                DragGesture(minimumDistance: minDistance, coordinateSpace: .global)
                    .onEnded { value in
                        handleSwipe(value, leadingEdge: leading)
                    }
            )
    }

    private func handleSwipe(_ value: DragGesture.Value, leadingEdge: Bool) {
        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dx) >= minHorizontal else { return }
        guard abs(dx) >= abs(dy) * horizontalDominance else { return }

        // Leading edge: expect swipe right (dx > 0) → previous.
        // Trailing edge: expect swipe left (dx < 0) → next.
        // Also accept the matching direction from either edge for forgiveness.
        let goPrevious = dx > 0
        let goNext = dx < 0

        if leadingEdge {
            // Prefer previous when swiping inward from the left; still allow next if
            // the user dragged the wrong way on that edge.
            if goPrevious {
                navigate(to: selectedTab.previous)
            } else if goNext {
                navigate(to: selectedTab.next)
            }
        } else {
            if goNext {
                navigate(to: selectedTab.next)
            } else if goPrevious {
                navigate(to: selectedTab.previous)
            }
        }
    }

    private func navigate(to tab: MainSectionTab?) {
        guard let tab, tab != selectedTab else {
            // Soft reject at ends (Chords← or →Ask).
            if tab == nil {
                HapticManager.shared.rigidImpact()
            }
            return
        }
        withAnimation(AppAnimation.smoothSpring) {
            selectedTab = tab
        }
        // Haptic also fires from MainTabView.onChange(of: selectedTab).
    }
}

// MARK: - Container Views

struct ChordIdentifierContainerView: View {
    @EnvironmentObject var viewModel: triadBuildViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()
                InputTriadAns()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(viewModel)
    }
}

struct ScalesContainerView: View {
    @EnvironmentObject var viewModel: scalesViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()
                ScalesView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(viewModel)
    }
}

struct NotesContainerView: View {
    @EnvironmentObject var notesSession: NotesSessionState

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()
                NotesTheoryView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(notesSession)
    }
}

struct MusicQueryContainerView: View {
    @Binding var selectedTab: MainSectionTab

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()
                MusicQueryView(selectedTab: $selectedTab)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainTabView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light")
            MainTabView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
