//
//  HapticManager.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Utility - Haptic Feedback Management
//

import UIKit
import SwiftUI

/// Centralized manager for haptic feedback across the app
class HapticManager {

    static let shared = HapticManager()

    private init() {}

    // MARK: - Notification Feedback

    /// Plays a success haptic (for correct answers, completions)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Plays a warning haptic (for invalid input)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Plays an error haptic (for errors, failures)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Impact Feedback

    /// Light impact (for subtle interactions like hovering)
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact (for button taps, selections)
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact (for major actions, confirmations)
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Rigid impact (for precise actions)
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    /// Soft impact (for gentle interactions)
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    // MARK: - Selection Feedback

    /// Selection changed haptic (for picker/segmented control changes)
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Convenience Methods

    /// Haptic for button tap
    func buttonTap() {
        mediumImpact()
    }

    /// Haptic for toggle switch
    func toggle() {
        selectionChanged()
    }

    /// Haptic for navigation
    func navigate() {
        lightImpact()
    }

    /// Haptic for input selection
    func inputSelect() {
        selectionChanged()
    }

    /// Haptic for correct chord/scale identification
    func correctAnswer() {
        success()
    }

    /// Haptic for incorrect input
    func incorrectInput() {
        warning()
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds haptic feedback to any view on tap
    func hapticFeedback(_ type: HapticFeedbackType = .medium) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            case .success:
                HapticManager.shared.success()
            case .warning:
                HapticManager.shared.warning()
            case .error:
                HapticManager.shared.error()
            case .selection:
                HapticManager.shared.selectionChanged()
            }
        }
    }
}

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}
