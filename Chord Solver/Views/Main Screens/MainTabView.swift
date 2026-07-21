//
//  MainTabView.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Tab-based navigation — system tab bar uses Liquid Glass on supported OS.
//  Section view models live here so root/selection state survives tab switches.
//

import SwiftUI

// MARK: - Section routing (testable, separate from chrome styling)

/// Primary switchable sections in the main tab chrome.
enum MainSectionTab: Int, CaseIterable, Hashable, Identifiable {
    case chords = 0
    case scales = 1
    case intervals = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .chords: return "Chords"
        case .scales: return "Scales"
        case .intervals: return "Intervals"
        }
    }

    var systemImage: String {
        switch self {
        case .chords: return "music.note.list"
        case .scales: return "music.quarternote.3"
        case .intervals: return "arrow.left.and.right"
        }
    }

    var tintColor: Color {
        switch self {
        case .chords: return .brandCoral
        case .scales: return .brandPurple
        case .intervals: return .brandAqua
        }
    }

    /// Maps a landing / deep-link tab index to a valid section (out-of-range → chords).
    static func resolving(initialTab: Int) -> MainSectionTab {
        MainSectionTab(rawValue: initialTab) ?? .chords
    }

    /// Landing card titles that open this tab (same labels as section switcher).
    static var landingSectionTitles: [String] {
        allCases.map(\.title)
    }

    /// Resolves a landing card title to a tab; unknown titles return nil.
    static func tab(forLandingTitle title: String) -> MainSectionTab? {
        allCases.first { $0.title == title }
    }
}

// MARK: - Interval session (persists across tab switches)

/// Interval note pair held at tab-shell level so values survive leaving the Intervals tab.
final class IntervalSessionState: ObservableObject {
    @Published var bottomNote: String = ""
    @Published var topNote: String = ""
    @Published var intervalResult: String = ""
}

// MARK: - MainTabView

struct MainTabView: View {

    @State private var selectedTab: MainSectionTab

    /// Optional return to landing (single entry path from ContentView).
    var onRequestHome: (() -> Void)? = nil

    /// Owned here so chord root / quality survive switching away from Chords.
    @StateObject private var triadVM = triadBuildViewModel()
    /// Owned here so scale root / mode survive switching away from Scales.
    @StateObject private var scalesVM = scalesViewModel()
    /// Owned here so interval notes survive switching away from Intervals.
    @StateObject private var intervalSession = IntervalSessionState()

    init(initialTab: Int = 0, onRequestHome: (() -> Void)? = nil) {
        _selectedTab = State(initialValue: MainSectionTab.resolving(initialTab: initialTab))
        self.onRequestHome = onRequestHome
    }

    var body: some View {
        // Native TabView so the system tab bar is the primary nav chrome.
        // On iOS 26+ the system tab bar uses Liquid Glass automatically.
        // View models stay on this shell so tab content can be recreated without
        // clearing the musical root / section selections.
        TabView(selection: $selectedTab) {
            Tab(
                MainSectionTab.chords.title,
                systemImage: MainSectionTab.chords.systemImage,
                value: MainSectionTab.chords
            ) {
                ChordIdentifierContainerView(onRequestHome: onRequestHome)
            }

            Tab(
                MainSectionTab.scales.title,
                systemImage: MainSectionTab.scales.systemImage,
                value: MainSectionTab.scales
            ) {
                ScalesContainerView(onRequestHome: onRequestHome)
            }

            Tab(
                MainSectionTab.intervals.title,
                systemImage: MainSectionTab.intervals.systemImage,
                value: MainSectionTab.intervals
            ) {
                IntervalsContainerView(onRequestHome: onRequestHome)
            }
        }
        .environmentObject(triadVM)
        .environmentObject(scalesVM)
        .environmentObject(intervalSession)
        .tint(selectedTab.tintColor)
        .onChange(of: selectedTab) { _, _ in
            HapticManager.shared.selectionChanged()
        }
    }
}

// MARK: - Container Views

struct ChordIdentifierContainerView: View {
    @EnvironmentObject var viewModel: triadBuildViewModel
    var onRequestHome: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    sectionHomeBar(tint: .brandCoral, onRequestHome: onRequestHome)
                    InputTriadAns()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(viewModel)
    }
}

struct ScalesContainerView: View {
    @EnvironmentObject var viewModel: scalesViewModel
    var onRequestHome: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    sectionHomeBar(tint: .brandPurple, onRequestHome: onRequestHome)
                    ScalesView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(viewModel)
    }
}

struct IntervalsContainerView: View {
    @EnvironmentObject var intervalSession: IntervalSessionState
    var onRequestHome: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    sectionHomeBar(tint: .brandAqua, onRequestHome: onRequestHome)
                    IntervalView()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .environmentObject(intervalSession)
    }
}

/// Subtle home control so landing is only for first entry, not a second nav system.
@ViewBuilder
private func sectionHomeBar(tint: Color, onRequestHome: (() -> Void)?) -> some View {
    if let onRequestHome {
        HStack {
            Button {
                HapticManager.shared.navigate()
                onRequestHome()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Home")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.textOnLight.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                        .overlay(
                            Capsule()
                                .stroke(tint.opacity(0.35), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
        .padding(.horizontal, Spacing.screenPadding)
        .padding(.top, Spacing.sm)
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
