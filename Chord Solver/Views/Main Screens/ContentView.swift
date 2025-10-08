//
//  ContentView.swift
//  Shared
//
//  Created by Dylan Shade on 4/7/21.
//  Modernized on 10/8/25 - UI Revival 2025
//

import SwiftUI

// MARK: - ContentView

struct ContentView: View {

    @State private var titleLettersAnimated = false
    @State private var cardsAnimated = false

    init() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white // Back button and other tint items
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient overlay for depth
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

                    // Animated Hero Title
                    VStack(alignment: .leading, spacing: -Spacing.md) {
                        AnimatedTitleText(text: "Chord", delay: 0.0)
                            .opacity(titleLettersAnimated ? 1 : 0)
                            .offset(y: titleLettersAnimated ? 0 : 20)

                        AnimatedTitleText(text: "Solver", delay: 0.15)
                            .opacity(titleLettersAnimated ? 1 : 0)
                            .offset(y: titleLettersAnimated ? 0 : 20)
                    }
                    .padding(.horizontal, Spacing.screenPadding)

                    Spacer()

                    // Attribution
//                    Text("app by dylan shade")
//                        .font(.caption)
//                        .fontWeight(.bold)
//                        .foregroundColor(Color.black.opacity(0.5))
//                        .padding(.horizontal, Spacing.screenPadding)
//                        .padding(.bottom, Spacing.xl)
//                        .opacity(titleLettersAnimated ? 1 : 0)

                    // Single Launch Button to enter the app
                    NavigationLink(destination: MainTabView()) {
                        VStack(spacing: Spacing.cardSpacing) {
                            ZStack {
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                                    .foregroundColor(Color.brandCoral)
                                    .frame(height: Spacing.navigationCardHeight)

                                Text("Chords")
                                    .textStyle(.heading3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Spacing.contentPadding)
                            }

                            ZStack {
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                                    .foregroundColor(Color.brandPurple)
                                    .frame(height: Spacing.navigationCardHeight)

                                Text("Scales")
                                    .textStyle(.heading3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Spacing.contentPadding)
                            }

                            ZStack {
                                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                                    .foregroundColor(Color.brandAqua)
                                    .frame(height: Spacing.navigationCardHeight)

                                Text("Intervals")
                                    .textStyle(.heading3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, Spacing.contentPadding)
                            }
                        }
                        .opacity(cardsAnimated ? 1 : 0)
                        .offset(y: cardsAnimated ? 0 : 30)
                        .animation(
                            AppAnimation.smoothSpring.delay(0.3),
                            value: cardsAnimated
                        )
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded { _ in
                            HapticManager.shared.navigate()
                        }
                    )
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.bottom, Spacing.screenPadding)
                }
                .navigationBarHidden(true)
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
        .navigationViewStyle(StackNavigationViewStyle())
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
