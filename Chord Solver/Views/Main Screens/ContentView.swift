//
//  ContentView.swift
//  Shared
//
//  Created by Dylan Shade on 4/7/21.
//  Modernized on 10/8/25 - UI Revival 2025
//  Landing is a one-shot entry; tabs own section switching after that.
//

import SwiftUI

// MARK: - ContentView

struct ContentView: View {

    /// When set, MainTabView is the app root (no nested NavigationLink stack).
    @State private var activeSection: MainSectionTab?
    @State private var titleLettersAnimated = false
    @State private var cardsAnimated = false

    @AppStorage("chordSolver.lastSectionRaw") private var lastSectionRaw: Int = 0

    var body: some View {
        Group {
            if let section = activeSection {
                MainTabView(initialTab: section.rawValue) {
                    withAnimation(AppAnimation.smoothSpring) {
                        activeSection = nil
                    }
                }
                .transition(.opacity)
            } else {
                landing
                    .transition(.opacity)
            }
        }
        .animation(AppAnimation.smoothSpring, value: activeSection != nil)
    }

    // MARK: - Landing

    private var landing: some View {
        ZStack {
            Color.brandBeige
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.02)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: -Spacing.md) {
                    AnimatedTitleText(text: "Chord", delay: 0.0)
                        .opacity(titleLettersAnimated ? 1 : 0)
                        .offset(y: titleLettersAnimated ? 0 : 20)

                    AnimatedTitleText(text: "Solver", delay: 0.15)
                        .opacity(titleLettersAnimated ? 1 : 0)
                        .offset(y: titleLettersAnimated ? 0 : 20)
                }
                .padding(.horizontal, Spacing.screenPadding)

                Text("Pick a section — switch anytime with tabs")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textOnBeige.opacity(0.55))
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.lg)
                    .opacity(titleLettersAnimated ? 1 : 0)

                Spacer()

                VStack(spacing: Spacing.cardSpacing) {
                    landingCard(
                        title: MainSectionTab.chords.title,
                        color: .brandCoralSoft,
                        tab: .chords
                    )
                    landingCard(
                        title: MainSectionTab.scales.title,
                        color: .brandPurpleSoft,
                        tab: .scales
                    )
                    landingCard(
                        title: MainSectionTab.intervals.title,
                        color: .brandAquaSoft,
                        tab: .intervals
                    )
                }
                .opacity(cardsAnimated ? 1 : 0)
                .offset(y: cardsAnimated ? 0 : 30)
                .animation(AppAnimation.smoothSpring.delay(0.3), value: cardsAnimated)
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.screenPadding)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.smoothSpring.delay(0.1)) {
                titleLettersAnimated = true
            }
            withAnimation(AppAnimation.smoothSpring.delay(0.2)) {
                cardsAnimated = true
            }
        }
    }

    private func landingCard(title: String, color: Color, tab: MainSectionTab) -> some View {
        Button {
            HapticManager.shared.navigate()
            lastSectionRaw = tab.rawValue
            withAnimation(AppAnimation.smoothSpring) {
                activeSection = tab
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .foregroundColor(color)
                    .frame(height: Spacing.navigationCardHeight)

                Text(title)
                    .textStyle(.heading3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.contentPadding)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Animated Title Component

struct AnimatedTitleText: View {
    let text: String
    let delay: Double

    var body: some View {
        Text(text)
            .font(.displayHero)
            .foregroundColor(.textOnBeige)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
