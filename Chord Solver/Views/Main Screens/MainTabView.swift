//
//  MainTabView.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Modern Tab-based Navigation System
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int

    init(initialTab: Int = 0) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content
            ZStack {
                ChordIdentifierContainerView()
                    .opacity(selectedTab == 0 ? 1 : 0)

                ScalesContainerView()
                    .opacity(selectedTab == 1 ? 1 : 0)

                IntervalsContainerView()
                    .opacity(selectedTab == 2 ? 1 : 0)
            }

            // Custom Tab Bar
            HStack(spacing: 0) {
                CustomTabButton(
                    icon: "music.note.list",
                    label: "Chords",
                    isSelected: selectedTab == 0,
                    accentColor: .brandCoral
                ) {
                    selectedTab = 0
                    HapticManager.shared.selectionChanged()
                }

                CustomTabButton(
                    icon: "music.quarternote.3",
                    label: "Scales",
                    isSelected: selectedTab == 1,
                    accentColor: .brandPurple
                ) {
                    selectedTab = 1
                    HapticManager.shared.selectionChanged()
                }

                CustomTabButton(
                    icon: "arrow.left.and.right",
                    label: "Intervals",
                    isSelected: selectedTab == 2,
                    accentColor: .brandAqua
                ) {
                    selectedTab = 2
                    HapticManager.shared.selectionChanged()
                }
            }
            .padding(.top, 8)
            .background(
                Color.brandBeige
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

// MARK: - Custom Tab Button

struct CustomTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .textOnLight)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .textOnLight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor : Color.clear)
            )
            .padding(.horizontal, 4)
        }
        .frame(height: 72)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Container Views

struct ChordIdentifierContainerView: View {
    @StateObject var viewModel = triadBuildViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content (padding handled internally by InputTriadAns)
                    InputTriadAns()
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .environmentObject(viewModel)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ScalesContainerView: View {
    @StateObject var viewModel = scalesViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content (padding handled internally by ScalesView)
                    ScalesView()
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
        }
        .environmentObject(viewModel)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct IntervalsContainerView: View {

    var body: some View {
        NavigationView {
            ZStack {
                Color.brandBeige
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content
                    IntervalView()
                        .padding(.top, Spacing.md)
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
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
