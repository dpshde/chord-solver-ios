//
//  Colors.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Design System - Semantic Color Tokens
//

import SwiftUI

extension Color {

    // MARK: - Brand Colors (Existing Palette)

    /// Soft pink - Used for Chord Solver section
    static let brandPink = Color(red: 0.96, green: 0.75, blue: 0.75)

    /// Vibrant coral - Used for Chords/Triads section (lightened for better readability)
    static let brandCoral = Color(red: 1.0, green: 0.58, blue: 0.58)

    /// Lavender purple - Used for Scales section
    static let brandPurple = Color(red: 0.72, green: 0.71, blue: 1.0)

    /// Soft aqua - Used for Intervals section
    static let brandAqua = Color(red: 0.62, green: 0.85, blue: 0.87)

    /// Warm beige - Used for landing page
    static let brandBeige = Color(red: 0.94, green: 0.89, blue: 0.84)

    /// Darker beige - Used for tab bar background to contrast with main beige
    static let darkBeige = Color(red: 0.88, green: 0.82, blue: 0.76)

    // MARK: - Semantic Colors

    /// Primary background for each section (context-aware)
    static func sectionBackground(for section: AppSection) -> Color {
        switch section {
        case .landing:
            return brandBeige
        case .chordSolver:
            return brandPink
        case .chords:
            return brandCoral
        case .scales:
            return brandPurple
        case .intervals:
            return brandAqua
        }
    }

    /// Secondary/accent color for each section
    static func sectionAccent(for section: AppSection) -> Color {
        switch section {
        case .landing:
            return brandCoral
        case .chordSolver:
            return brandCoral
        case .chords:
            return brandPink
        case .scales:
            return brandCoral
        case .intervals:
            return brandPurple
        }
    }

    // MARK: - Interactive States

    /// Button/interactive element in active state
    static let interactiveActive = Color.white.opacity(0.95)

    /// Button/interactive element in inactive state
    static let interactiveInactive = Color.white.opacity(0.6)

    /// Button/interactive element pressed state
    static let interactivePressed = Color.white.opacity(0.85)

    // MARK: - Accent Colors for Interactive Elements

    /// Accent color for chord view buttons (darker pastel pink/coral for better contrast with white text)
    static let accentCoral = Color(red: 0.95, green: 0.65, blue: 0.65)

    /// Accent color for scale view buttons (darker pastel purple for better contrast with white text)
    static let accentPurple = Color(red: 0.75, green: 0.70, blue: 0.95)

    /// Accent color for interval view buttons (darker pastel aqua for better contrast with white text)
    static let accentAqua = Color(red: 0.60, green: 0.80, blue: 0.85)

    // MARK: - Very Light Tints for Input Selections

    /// Very light coral tint for subtle selections (input buttons)
    static let lightTintCoral = Color(red: 1.0, green: 0.95, blue: 0.95)

    /// Very light purple tint for subtle selections (input buttons)
    static let lightTintPurple = Color(red: 0.96, green: 0.96, blue: 1.0)

    /// Very light aqua tint for subtle selections (input buttons)
    static let lightTintAqua = Color(red: 0.95, green: 0.98, blue: 0.99)

    // MARK: - Tab Highlight Colors (slightly more contrast than input selections)

    /// Tab highlight coral - slightly more visible than input selection tint
    static let tabHighlightCoral = Color(red: 1.0, green: 0.92, blue: 0.92)

    /// Tab highlight purple - slightly more visible than input selection tint
    static let tabHighlightPurple = Color(red: 0.93, green: 0.93, blue: 1.0)

    /// Tab highlight aqua - slightly more visible than input selection tint
    static let tabHighlightAqua = Color(red: 0.90, green: 0.96, blue: 0.97)

    /// Neutral gray for non-selection buttons (like backspace)
    static let neutralGray = Color(red: 0.85, green: 0.85, blue: 0.85)

    /// Darker grey for backspace button
    static let pastelRed = Color(red: 0.75, green: 0.75, blue: 0.75)

    // MARK: - Text Colors

    /// Primary text color (on colored backgrounds) - High contrast white
    static let textPrimary = Color.white

    /// Secondary text color (subtle) - Better contrast
    static let textSecondary = Color.white.opacity(0.95)

    /// Tertiary text color (very subtle) - Improved contrast
    static let textTertiary = Color.white.opacity(0.85)

    /// Text on light backgrounds - High contrast black
    static let textOnLight = Color.black.opacity(0.9)

    /// Text on very light backgrounds (like beige)
    static let textOnBeige = Color.black.opacity(0.85)

    // MARK: - Feedback Colors

    /// Success state
    static let success = Color.green.opacity(0.8)

    /// Warning state
    static let warning = Color.orange.opacity(0.8)

    /// Error state
    static let error = Color.red.opacity(0.8)

}

// MARK: - App Section Enum

enum AppSection {
    case landing
    case chordSolver
    case chords
    case scales
    case intervals
}
