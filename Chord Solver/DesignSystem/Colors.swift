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

    // MARK: - Dark Mode Variants

    /// Dark mode variant of brand pink
    static let brandPinkDark = Color(red: 0.85, green: 0.60, blue: 0.60)

    /// Dark mode variant of brand coral (lightened for better readability)
    static let brandCoralDark = Color(red: 0.92, green: 0.48, blue: 0.48)

    /// Dark mode variant of brand purple
    static let brandPurpleDark = Color(red: 0.60, green: 0.58, blue: 0.85)

    /// Dark mode variant of brand aqua
    static let brandAquaDark = Color(red: 0.50, green: 0.70, blue: 0.72)

    /// Dark mode variant of brand beige
    static let brandBeigeDark = Color(red: 0.25, green: 0.23, blue: 0.21)
}

// MARK: - App Section Enum

enum AppSection {
    case landing
    case chordSolver
    case chords
    case scales
    case intervals
}

// MARK: - Color Scheme Aware Extension

extension Color {
    /// Returns the appropriate color based on current color scheme
    static func adaptive(light: Color, dark: Color, colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? dark : light
    }

    // MARK: - Adaptive Brand Colors

    /// Adaptive beige color for landing screen background
    static func adaptiveBrandBeige(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? brandBeigeDark : brandBeige
    }

    /// Adaptive coral color for chord identifier section
    static func adaptiveBrandCoral(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? brandCoralDark : brandCoral
    }

    /// Adaptive purple color for scales section
    static func adaptiveBrandPurple(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? brandPurpleDark : brandPurple
    }

    /// Adaptive aqua color for intervals section
    static func adaptiveBrandAqua(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? brandAquaDark : brandAqua
    }

    /// Adaptive pink color
    static func adaptiveBrandPink(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? brandPinkDark : brandPink
    }
}
