//
//  FeatureButton.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Component - Enhanced Quality/Feature Button
//

import SwiftUI

/// A modern, interactive button for chord qualities and features
struct FeatureButton: View {

    // MARK: - Properties

    let title: String
    let isSelected: Bool
    let activeColor: Color
    let inactiveColor: Color
    let action: () -> Void

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Initializer

    init(
        title: String,
        isSelected: Bool,
        activeColor: Color = .brandPink,
        inactiveColor: Color = .brandCoral,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            HapticManager.shared.selectionChanged()
            withAnimation(AppAnimation.quickSpring) {
                action()
            }
        }) {
            ZStack {
                Spacing.shapeChip
                    .foregroundColor(isSelected ? activeColor : inactiveColor)
                    .shadow(
                        color: isSelected ? Color.black.opacity(0.2) : Color.clear,
                        radius: isSelected ? 4 : 0,
                        x: 0,
                        y: isSelected ? 2 : 0
                    )

                Text(title)
                    .font(.buttonLabel)
                    .foregroundColor(.textPrimary)
            }
            .frame(
                minWidth: 60,
                maxWidth: .infinity,
                minHeight: Spacing.qualityButtonHeight,
                maxHeight: Spacing.qualityButtonHeight
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AppAnimation.quickSpring, value: isPressed)
        .animation(AppAnimation.smoothSpring, value: isSelected)
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

struct FeatureButton_Previews: PreviewProvider {
    @State static var selectedButton = "Major"

    static var previews: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                FeatureButton(
                    title: "Major",
                    isSelected: selectedButton == "Major"
                ) {
                    selectedButton = "Major"
                }

                FeatureButton(
                    title: "Minor",
                    isSelected: selectedButton == "Minor"
                ) {
                    selectedButton = "Minor"
                }

                FeatureButton(
                    title: "+",
                    isSelected: selectedButton == "+"
                ) {
                    selectedButton = "+"
                }

                FeatureButton(
                    title: "o",
                    isSelected: selectedButton == "o"
                ) {
                    selectedButton = "o"
                }
            }

            HStack(spacing: Spacing.sm) {
                FeatureButton(
                    title: "MM7",
                    isSelected: selectedButton == "MM7"
                ) {
                    selectedButton = "MM7"
                }

                FeatureButton(
                    title: "Mm7",
                    isSelected: selectedButton == "Mm7"
                ) {
                    selectedButton = "Mm7"
                }

                FeatureButton(
                    title: "mm7",
                    isSelected: selectedButton == "mm7"
                ) {
                    selectedButton = "mm7"
                }
            }
        }
        .padding()
        .background(Color.brandCoral.ignoresSafeArea())
    }
}
