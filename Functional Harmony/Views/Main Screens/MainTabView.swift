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
        MainTabView()
    }
}
