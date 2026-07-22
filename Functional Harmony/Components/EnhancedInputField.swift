//
//  EnhancedInputField.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Component - Enhanced Input Field with Validation
//

import SwiftUI

/// A modern input field with validation feedback and animations
struct EnhancedInputField: View {

    // MARK: - Properties

    let placeholder: String
    @Binding var text: String
    let validationState: ValidationState
    let onCommit: () -> Void

    // MARK: - State

    @State private var isFocused = false
    @State private var shouldShake = false

    // MARK: - Initializer

    init(
        placeholder: String,
        text: Binding<String>,
        validationState: ValidationState = .neutral,
        onCommit: @escaping () -> Void = {}
    ) {
        self.placeholder = placeholder
        self._text = text
        self.validationState = validationState
        self.onCommit = onCommit
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ZStack {
                Spacing.shapeSmall
                    .foregroundColor(.interactiveActive)
                    .shadow(
                        color: shadowColor,
                        radius: isFocused ? 8 : 4,
                        x: 0,
                        y: 2
                    )

                TextField(placeholder, text: $text, onCommit: {
                    onCommit()
                    HapticManager.shared.inputSelect()
                })
                .font(.input)
                .foregroundColor(.textOnLight)
                .padding(.horizontal, Spacing.contentPadding)
                .frame(
                    maxWidth: .infinity,
                    minHeight: Spacing.inputHeight,
                    maxHeight: Spacing.inputHeight
                )
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }
            .modifier(ShakeEffect(animatableData: shouldShake ? 1 : 0))
            .animation(AppAnimation.quickSpring, value: isFocused)

            // Validation feedback
            if case .invalid(let message) = validationState {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.error)
                    .transition(.slideFromBottom)
            }
        }
        .onChange(of: validationState) { newState in
            if case .invalid = newState {
                shouldShake = true
                HapticManager.shared.warning()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shouldShake = false
                }
            } else if case .valid = newState {
                HapticManager.shared.success()
            }
        }
    }

    // MARK: - Computed Properties

    private var shadowColor: Color {
        switch validationState {
        case .neutral:
            return Color.shadowSoft
        case .valid:
            return Color.success.opacity(0.3)
        case .invalid:
            return Color.error.opacity(0.3)
        }
    }
}

// MARK: - Validation State

enum ValidationState: Equatable {
    case neutral
    case valid
    case invalid(message: String)
}

// MARK: - Preview

struct EnhancedInputField_Previews: PreviewProvider {
    @State static var text1 = ""
    @State static var text2 = "C#"
    @State static var text3 = "Invalid"

    static var previews: some View {
        VStack(spacing: Spacing.xl) {
            EnhancedInputField(
                placeholder: "Enter a note:",
                text: $text1,
                validationState: .neutral
            )

            EnhancedInputField(
                placeholder: "Enter a note:",
                text: $text2,
                validationState: .valid
            )

            EnhancedInputField(
                placeholder: "Enter a note:",
                text: $text3,
                validationState: .invalid(message: "Please enter a valid note name")
            )
        }
        .padding()
        .background(Color.brandCoral.ignoresSafeArea())
    }
}
