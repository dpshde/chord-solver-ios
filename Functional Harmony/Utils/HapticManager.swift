//
//  HapticManager.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Utility - Haptic Feedback Management
//

import UIKit
import SwiftUI

/// Centralized manager for haptic feedback across the app.
/// Generators are reused and prepared so impact is cheap when UI needs to paint first.
final class HapticManager {

    static let shared = HapticManager()

    private let notification = UINotificationFeedbackGenerator()
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        prepareAll()
    }

    /// Warm generators so the next impact is not delayed by first-use setup.
    func prepareAll() {
        notification.prepare()
        light.prepare()
        medium.prepare()
        heavy.prepare()
        rigid.prepare()
        soft.prepare()
        selection.prepare()
    }

    // MARK: - Notification Feedback

    /// Plays a success haptic (for correct answers, completions)
    func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// Plays a warning haptic (for invalid input)
    func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    /// Plays an error haptic (for errors, failures)
    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    // MARK: - Impact Feedback

    /// Light impact (for subtle interactions like hovering)
    func lightImpact() {
        light.impactOccurred()
        light.prepare()
    }

    /// Medium impact (for button taps, selections)
    func mediumImpact() {
        medium.impactOccurred()
        medium.prepare()
    }

    /// Heavy impact (for major actions, confirmations)
    func heavyImpact() {
        heavy.impactOccurred()
        heavy.prepare()
    }

    /// Rigid impact (for precise actions)
    func rigidImpact() {
        rigid.impactOccurred()
        rigid.prepare()
    }

    /// Soft impact (for gentle interactions)
    func softImpact() {
        soft.impactOccurred()
        soft.prepare()
    }

    // MARK: - Selection Feedback

    /// Selection changed haptic (for picker/segmented control changes)
    func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }

    // MARK: - Deferred feedback

    /// Run side effects (haptics, audio) after the current main-runloop turn so
    /// SwiftUI can paint optimistic state first. Use after mutating selection UI.
    func afterUIUpdate(_ work: @escaping () -> Void) {
        DispatchQueue.main.async(execute: work)
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
