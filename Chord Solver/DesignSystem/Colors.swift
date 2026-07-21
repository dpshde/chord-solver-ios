//
//  Colors.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Design System - Semantic Color Tokens
//

import SwiftUI

extension Color {

    // MARK: - Brand Colors
    // Tuned for hierarchy: solid accents hold white text; soft tints for washes.

    /// Soft pink - Used for Chord Solver section
    static let brandPink = Color(red: 0.96, green: 0.75, blue: 0.75)

    /// Coral — Chords section accent / result panel (deep enough for white type)
    static let brandCoral = Color(red: 0.91, green: 0.42, blue: 0.46)

    /// Purple — Scales section accent (deep enough for white type)
    static let brandPurple = Color(red: 0.52, green: 0.50, blue: 0.90)

    /// Aqua — Intervals section accent (deep enough for white type)
    static let brandAqua = Color(red: 0.22, green: 0.58, blue: 0.64)

    /// Soft pastels for landing cards (kept light; labels use dark ink)
    static let brandCoralSoft = Color(red: 1.0, green: 0.62, blue: 0.62)
    static let brandPurpleSoft = Color(red: 0.78, green: 0.76, blue: 1.0)
    static let brandAquaSoft = Color(red: 0.62, green: 0.85, blue: 0.87)

    /// Vivace Theory tab — warm burnt orange (from Vivace DE6E4B, deepened for white type)
    static let brandVivace = Color(red: 0.82, green: 0.38, blue: 0.26)
    static let brandVivaceSoft = Color(red: 0.95, green: 0.72, blue: 0.62)

    /// App canvas — ghost white (CSS ghostwhite ≈ #F8F8FF)
    static let brandBeige = Color(red: 248 / 255, green: 248 / 255, blue: 255 / 255)

    /// Subtle secondary surface one step below ghost white
    static let darkBeige = Color(red: 0.94, green: 0.94, blue: 0.97)

    // MARK: - Surfaces & Ink (shared UI chrome)

    /// Elevated card / control surface on beige
    static let surfaceCard = Color.white

    /// Subtle hairline border on cards
    static let borderSubtle = Color.black.opacity(0.08)

    /// Stronger border for focused controls
    static let borderStrong = Color.black.opacity(0.14)

    /// Primary ink on light surfaces (warm near-black)
    static let inkPrimary = Color(red: 0.16, green: 0.12, blue: 0.11)

    /// Secondary captions / chevrons on light surfaces
    static let inkSecondary = Color.black.opacity(0.42)

    /// Tertiary / placeholder
    static let inkTertiary = Color.black.opacity(0.32)

    /// Text/icons on solid brand fills
    static let inkOnAccent = Color.white

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
        case .vivace:
            return brandVivace
        case .ask:
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
        case .vivace:
            return brandVivace
        case .ask:
            return brandAqua
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

    /// Neutral gray for non-selection buttons
    static let neutralGray = Color(red: 0.85, green: 0.85, blue: 0.85)

    /// Soft rose for active backspace (subtle, only when something can be deleted)
    static let mutedRed = Color(red: 0.92, green: 0.72, blue: 0.72)

    /// Idle backspace / empty destructive control
    static let backspaceIdle = Color(red: 0.93, green: 0.93, blue: 0.94)

    /// Legacy name used by keyboards — maps to muted red
    static let pastelRed = mutedRed

    // MARK: - Text Colors

    /// Primary text color (on colored backgrounds) - High contrast white
    static let textPrimary = Color.white

    /// Secondary text color (subtle) - Better contrast
    static let textSecondary = Color.white.opacity(0.95)

    /// Tertiary text color (very subtle) - Improved contrast
    static let textTertiary = Color.white.opacity(0.85)

    /// Text on light backgrounds - High contrast ink
    static let textOnLight = inkPrimary

    /// Text on very light backgrounds (like beige)
    static let textOnBeige = inkPrimary

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
    case vivace
    case ask
}
