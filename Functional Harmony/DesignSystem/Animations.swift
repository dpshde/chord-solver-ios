//
//  Animations.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Design System - Reusable Animation Definitions
//  Bias: quick settle, high damping (smooth, not floaty).
//

import SwiftUI

/// Standard animation definitions for consistent motion across the app
enum AppAnimation {

    // MARK: - Basic Animations

    /// Snappy spring for taps, collapse/expand, selection (most UI).
    static let quickSpring = Animation.spring(
        response: 0.22,
        dampingFraction: 0.9,
        blendDuration: 0
    )

    /// Slightly longer spring for layout shifts (result band, catalog).
    static let smoothSpring = Animation.spring(
        response: 0.3,
        dampingFraction: 0.92,
        blendDuration: 0
    )

    /// Light pop for note chips — damped enough to avoid wobble.
    static let bouncySpring = Animation.spring(
        response: 0.26,
        dampingFraction: 0.82,
        blendDuration: 0
    )

    /// Short ease for subtle fades
    static let gentleEase = Animation.easeInOut(duration: 0.18)

    /// Page / panel ease
    static let smoothEase = Animation.easeInOut(duration: 0.26)

    /// Press feedback (buttons, tiles)
    static let press = Animation.easeOut(duration: 0.08)

    // MARK: - Semantic aliases

    static let buttonPress = quickSpring
    static let pageTransition = smoothSpring
    static let modalPresentation = smoothEase
    static let resultAppearance = smoothSpring

    /// Legacy alias — prefer `attentionPulse` for “needs input” cues.
    static let errorShake = Animation.easeOut(duration: 0.2)
}

// MARK: - Animation View Modifiers

struct ScaleOnPressModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(AppAnimation.press, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

/// Standard attention cue: brief scale pulse only (no border flash).
/// Trigger by bumping `tick` (e.g. `attentionTick += 1`).
struct AttentionPulseModifier: ViewModifier {
    let tick: Int
    var accent: Color = .brandCoral

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var active = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && !reduceMotion ? 1.02 : 1.0)
            .animation(AppAnimation.quickSpring, value: active)
            .onChange(of: tick) { _, _ in
                guard tick > 0 else { return }
                active = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    active = false
                }
            }
            // `accent` retained for call-site compatibility (ring removed).
            .onAppear { _ = accent }
    }
}

/// Kept for EnhancedInputField and any legacy callers; prefer AttentionPulseModifier.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 4
    var shakesPerUnit = 2
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

    /// Subtle scale + fade
    static let scaleAndFade = AnyTransition.scale(scale: 0.96).combined(with: .opacity)
}

// MARK: - View Extensions

extension View {
    /// Applies a scale effect when pressed
    func scaleOnPress() -> some View {
        modifier(ScaleOnPressModifier())
    }

    /// Applies a shake animation (legacy)
    func shake(isShaking: Bool) -> some View {
        modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
    }

    /// Standard “needs attention” pulse (scale + accent ring). Bump `tick` to fire.
    func attentionPulse(tick: Int, accent: Color = .brandCoral) -> some View {
        modifier(AttentionPulseModifier(tick: tick, accent: accent))
    }

    /// Animates appearance with spring
    func springAppear() -> some View {
        self.transition(.scaleAndFade)
            .animation(AppAnimation.smoothSpring, value: UUID())
    }
}
