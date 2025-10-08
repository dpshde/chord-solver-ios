//
//  Animations.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Design System - Reusable Animation Definitions
//

import SwiftUI

/// Standard animation definitions for consistent motion across the app
enum AppAnimation {

    // MARK: - Basic Animations

    /// Quick spring animation for button taps and interactions
    static let quickSpring = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0
    )

    /// Smooth spring animation for card movements
    static let smoothSpring = Animation.spring(
        response: 0.5,
        dampingFraction: 0.75,
        blendDuration: 0
    )

    /// Bouncy spring animation for playful effects
    static let bouncySpring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6,
        blendDuration: 0
    )

    /// Gentle ease for subtle transitions
    static let gentleEase = Animation.easeInOut(duration: 0.3)

    /// Smooth ease for page transitions
    static let smoothEase = Animation.easeInOut(duration: 0.5)

    // MARK: - Complex Animations

    /// Animation for button press
    static let buttonPress = quickSpring

    /// Animation for page transitions
    static let pageTransition = smoothSpring

    /// Animation for modal presentations
    static let modalPresentation = smoothEase

    /// Animation for result appearance
    static let resultAppearance = bouncySpring

    /// Animation for error shake
    static let errorShake = Animation.default.repeatCount(3, autoreverses: true).speed(2)
}

// MARK: - Animation View Modifiers

struct ScaleOnPressModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AppAnimation.quickSpring, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

// MARK: - Transition Definitions

extension AnyTransition {

    /// Slide and fade transition from bottom
    static let slideFromBottom = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )

    /// Slide and fade transition from leading
    static let slideFromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )

    /// Scale and fade transition
    static let scaleAndFade = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
}

// MARK: - View Extensions

extension View {
    /// Applies a scale effect when pressed
    func scaleOnPress() -> some View {
        modifier(ScaleOnPressModifier())
    }

    /// Applies a shake animation
    func shake(isShaking: Bool) -> some View {
        modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
    }

    /// Animates appearance with spring
    func springAppear() -> some View {
        self.transition(.scaleAndFade)
            .animation(AppAnimation.bouncySpring, value: UUID())
    }
}
