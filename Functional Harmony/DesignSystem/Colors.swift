//
//  Colors.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Design System - Semantic Color Tokens
//  Light = warm paper; dark = warm espresso that matches the same hierarchy.
//

import SwiftUI
import UIKit

extension Color {

    // MARK: - Dynamic helpers

    /// Resolves light / dark values from the current trait collection.
    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: r, green: g, blue: b, alpha: alpha)
    }

    private static func hex(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }

    // MARK: - Brand Colors
    // Solid accents hold white text in both schemes (slightly brighter in dark).

    /// Soft pink — legacy chord-builder wash
    static let brandPink = adaptive(
        light: rgb(0.96, 0.75, 0.75),
        dark: rgb(0.72, 0.42, 0.45)
    )

    /// Coral — Chords section accent / result panel (deep enough for white type)
    static let brandCoral = adaptive(
        light: rgb(0.91, 0.42, 0.46),
        dark: rgb(0.95, 0.50, 0.54)
    )

    /// Purple — Scales section accent (deep enough for white type)
    static let brandPurple = adaptive(
        light: rgb(0.52, 0.50, 0.90),
        dark: rgb(0.62, 0.60, 0.96)
    )

    /// Aqua — Intervals / Ask section accent (deep enough for white type)
    static let brandAqua = adaptive(
        light: rgb(0.22, 0.58, 0.64),
        dark: rgb(0.35, 0.72, 0.78)
    )

    /// Soft pastels for landing cards (labels use inkPrimary)
    static let brandCoralSoft = adaptive(
        light: rgb(1.0, 0.62, 0.62),
        dark: rgb(0.55, 0.32, 0.34)
    )
    static let brandPurpleSoft = adaptive(
        light: rgb(0.78, 0.76, 1.0),
        dark: rgb(0.38, 0.36, 0.58)
    )
    static let brandAquaSoft = adaptive(
        light: rgb(0.62, 0.85, 0.87),
        dark: rgb(0.28, 0.42, 0.46)
    )

    /// Notes tab — warm burnt orange (deep enough for white type)
    static let brandNotes = adaptive(
        light: rgb(0.82, 0.38, 0.26),
        dark: rgb(0.92, 0.50, 0.36)
    )
    static let brandNotesSoft = adaptive(
        light: rgb(0.95, 0.72, 0.62),
        dark: rgb(0.48, 0.32, 0.26)
    )

    // Warm paper family (no pure white / pure black — pure extremes clash with the palette).
    // Light: canvas one step deeper than cards. Dark: canvas deep espresso; cards lift up.

    /// App canvas — warm paper / warm espresso
    static let brandBeige = adaptive(
        light: hex(0xF2ECE5),
        dark: hex(0x1A1612)
    )

    /// Subtle secondary surface (accent keys, recessed chrome)
    static let darkBeige = adaptive(
        light: hex(0xE8E0D7),
        dark: hex(0x2A2420)
    )

    // MARK: - Surfaces & Ink (shared UI chrome)

    /// Elevated card / control surface
    static let surfaceCard = adaptive(
        light: hex(0xF8F4EF),
        dark: hex(0x2C2620)
    )

    /// Soft fill for a note card while its sample is sounding (subtle vs surfaceCard).
    static let playingNoteFill = adaptive(
        light: hex(0xE8E0D7),
        dark: hex(0x3A342C)
    )

    /// Subtle hairline border on cards (warm-tinted)
    static let borderSubtle = adaptive(
        light: rgb(0.35, 0.28, 0.22, alpha: 0.10),
        dark: rgb(0.96, 0.92, 0.88, alpha: 0.12)
    )

    /// Stronger border for focused controls
    static let borderStrong = adaptive(
        light: rgb(0.35, 0.28, 0.22, alpha: 0.16),
        dark: rgb(0.96, 0.92, 0.88, alpha: 0.22)
    )

    /// Soft drop shadow (neutral, works on both schemes)
    static let shadowSoft = adaptive(
        light: UIColor.black.withAlphaComponent(0.10),
        dark: UIColor.black.withAlphaComponent(0.45)
    )

    /// Primary ink on canvas / cards
    static let inkPrimary = adaptive(
        light: rgb(0.16, 0.12, 0.11),
        dark: hex(0xF2ECE5)
    )

    /// Secondary captions / chevrons
    static let inkSecondary = adaptive(
        light: UIColor.black.withAlphaComponent(0.42),
        dark: UIColor.white.withAlphaComponent(0.55)
    )

    /// Tertiary / placeholder
    static let inkTertiary = adaptive(
        light: UIColor.black.withAlphaComponent(0.32),
        dark: UIColor.white.withAlphaComponent(0.38)
    )

    /// Text/icons on solid brand fills
    static let inkOnAccent = Color.white

    // MARK: - Semantic Colors

    /// Primary background for each section (context-aware)
    static func sectionBackground(for section: AppSection) -> Color {
        switch section {
        case .landing:
            return brandBeige
        case .chordBuilder:
            return brandPink
        case .chords:
            return brandCoral
        case .scales:
            return brandPurple
        case .intervals:
            return brandAqua
        case .notes:
            return brandNotes
        case .ask:
            return brandAqua
        }
    }

    /// Secondary/accent color for each section
    static func sectionAccent(for section: AppSection) -> Color {
        switch section {
        case .landing:
            return brandCoral
        case .chordBuilder:
            return brandCoral
        case .chords:
            return brandPink
        case .scales:
            return brandCoral
        case .intervals:
            return brandPurple
        case .notes:
            return brandNotes
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

    /// Accent color for chord view buttons
    static let accentCoral = adaptive(
        light: rgb(0.95, 0.65, 0.65),
        dark: rgb(0.70, 0.40, 0.42)
    )

    /// Accent color for scale view buttons
    static let accentPurple = adaptive(
        light: rgb(0.75, 0.70, 0.95),
        dark: rgb(0.48, 0.44, 0.72)
    )

    /// Accent color for interval view buttons
    static let accentAqua = adaptive(
        light: rgb(0.60, 0.80, 0.85),
        dark: rgb(0.32, 0.50, 0.54)
    )

    // MARK: - Very Light Tints for Input Selections

    /// Very light coral tint for subtle selections (input buttons)
    static let lightTintCoral = adaptive(
        light: rgb(1.0, 0.95, 0.95),
        dark: rgb(0.42, 0.28, 0.28)
    )

    /// Very light purple tint for subtle selections (input buttons)
    static let lightTintPurple = adaptive(
        light: rgb(0.96, 0.96, 1.0),
        dark: rgb(0.30, 0.28, 0.45)
    )

    /// Very light aqua tint for subtle selections (input buttons)
    static let lightTintAqua = adaptive(
        light: rgb(0.95, 0.98, 0.99),
        dark: rgb(0.24, 0.36, 0.40)
    )

    // MARK: - Tab Highlight Colors (slightly more contrast than input selections)

    /// Tab highlight coral - slightly more visible than input selection tint
    static let tabHighlightCoral = adaptive(
        light: rgb(1.0, 0.92, 0.92),
        dark: rgb(0.48, 0.32, 0.32)
    )

    /// Tab highlight purple - slightly more visible than input selection tint
    static let tabHighlightPurple = adaptive(
        light: rgb(0.93, 0.93, 1.0),
        dark: rgb(0.34, 0.32, 0.50)
    )

    /// Tab highlight aqua - slightly more visible than input selection tint
    static let tabHighlightAqua = adaptive(
        light: rgb(0.90, 0.96, 0.97),
        dark: rgb(0.28, 0.40, 0.44)
    )

    /// Neutral warm gray for non-selection buttons
    static let neutralGray = adaptive(
        light: rgb(0.86, 0.83, 0.79),
        dark: rgb(0.38, 0.34, 0.30)
    )

    /// Soft rose for active backspace (subtle, only when something can be deleted)
    static let mutedRed = adaptive(
        light: rgb(0.92, 0.72, 0.72),
        dark: rgb(0.55, 0.32, 0.34)
    )

    /// Idle backspace / empty destructive control (warm, matches paper family)
    static let backspaceIdle = adaptive(
        light: rgb(0.91, 0.88, 0.84),
        dark: rgb(0.32, 0.28, 0.25)
    )

    /// Legacy name used by keyboards — maps to muted red
    static let pastelRed = mutedRed

    // MARK: - Text Colors

    /// Primary text color (on colored backgrounds) - High contrast white
    static let textPrimary = Color.white

    /// Secondary text color (subtle) - Better contrast
    static let textSecondary = Color.white.opacity(0.95)

    /// Tertiary text color (very subtle) - Improved contrast
    static let textTertiary = Color.white.opacity(0.85)

    /// Text on light/dark canvas cards - High contrast ink
    static let textOnLight = inkPrimary

    /// Text on canvas (beige / espresso)
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
    case chordBuilder
    case chords
    case scales
    case intervals
    case notes
    case ask
}
