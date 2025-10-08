//
//  NavigationCard.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Component - Reusable Navigation Card
//

import SwiftUI

/// A reusable navigation card component that replaces the repeated ZStack pattern
struct NavigationCard<Destination: View>: View {

    // MARK: - Properties

    let title: String
    let backgroundColor: Color
    let destination: Destination
    let alignment: Alignment
    let isActive: Bool

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Initializer

    init(
        title: String,
        backgroundColor: Color,
        alignment: Alignment = .leading,
        isActive: Bool = false,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.alignment = alignment
        self.isActive = isActive
        self.destination = destination()
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: Spacing.navigationCardHeight
                )
                .foregroundColor(backgroundColor)

            if isActive {
                // Active state - just show the title
                Text(title)
                    .textStyle(.heading3)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: Spacing.navigationCardHeight,
                        alignment: alignment
                    )
                    .padding(.horizontal, Spacing.contentPadding)
            } else {
                // Inactive state - show navigation link
                NavigationLink(destination: destination) {
                    Text(title)
                        .textStyle(.heading3)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: Spacing.navigationCardHeight,
                            alignment: alignment
                        )
                        .padding(.horizontal, Spacing.contentPadding)
                }
                .simultaneousGesture(
                    TapGesture().onEnded { _ in
                        HapticManager.shared.navigate()
                    }
                )
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppAnimation.quickSpring, value: isPressed)
        .onLongPressGesture(
            minimumDuration: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}

// MARK: - Preview

struct NavigationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.cardSpacing) {
            NavigationCard(
                title: "Chords",
                backgroundColor: .brandCoral,
                alignment: .leading
            ) {
                Text("Chords View")
            }

            NavigationCard(
                title: "Chord Solver",
                backgroundColor: .brandPink,
                alignment: .trailing,
                isActive: true
            ) {
                Text("Active View")
            }

            NavigationCard(
                title: "Scales",
                backgroundColor: .brandPurple,
                alignment: .leading
            ) {
                Text("Scales View")
            }
        }
        .padding()
        .background(Color.brandBeige.ignoresSafeArea())
    }
}
