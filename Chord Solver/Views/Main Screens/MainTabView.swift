//
//  MainTabView.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Modern Tab-based Navigation System
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        TabView(selection: $selectedTab) {
            // Chord Identifier Tab
            ChordIdentifierContainerView()
                .tabItem {
                    Label("Chords", systemImage: "music.note.list")
                }
                .tag(0)

            // Scales Tab
            ScalesContainerView()
                .tabItem {
                    Label("Scales", systemImage: "music.quarternote.3")
                }
                .tag(1)

            // Intervals Tab
            IntervalsContainerView()
                .tabItem {
                    Label("Intervals", systemImage: "arrow.left.and.right")
                }
                .tag(2)
        }
        .accentColor(.textPrimary)
        .onChange(of: selectedTab) { _ in
            HapticManager.shared.selectionChanged()
        }
    }
}

// MARK: - Container Views

struct ChordIdentifierContainerView: View {
    @StateObject var viewModel = triadBuildViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBrandCoral(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content
                    InputTriadAns()
                        .padding(.horizontal, Spacing.screenPadding)
                        .padding(.top, Spacing.md)
                }
            }
            .navigationBarHidden(true)
        }
        .environmentObject(viewModel)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ScalesContainerView: View {
    @StateObject var viewModel = scalesViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBrandPurple(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content
                    ScalesView()
                        .padding(.top, Spacing.md)
                }
            }
            .navigationBarHidden(true)
        }
        .environmentObject(viewModel)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct IntervalsContainerView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBrandAqua(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content
                    IntervalView()
                        .padding(.top, Spacing.md)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Preview

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
