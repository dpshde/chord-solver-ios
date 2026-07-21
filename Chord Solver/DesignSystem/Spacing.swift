//
//  Spacing.swift
//  Chord Solver
//
//  Created by Dylan Shade on 10/8/25.
//  Design System - Layout Spacing Constants
//

import SwiftUI

/// Consistent spacing system based on 4pt grid
enum Spacing {

    // MARK: - Base Units

    /// 4pt - Extra small spacing
    static let xs: CGFloat = 4

    /// 8pt - Small spacing
    static let sm: CGFloat = 8

    /// 12pt - Small-medium spacing
    static let md: CGFloat = 12

    /// 16pt - Medium spacing (most common)
    static let lg: CGFloat = 16

    /// 24pt - Large spacing
    static let xl: CGFloat = 24

    /// 32pt - Extra large spacing
    static let xxl: CGFloat = 32

    /// 48pt - Huge spacing
    static let xxxl: CGFloat = 48

    /// 64pt - Massive spacing
    static let xxxxl: CGFloat = 64

    // MARK: - Semantic Spacing

    /// Standard padding for content within cards/containers
    static let contentPadding: CGFloat = lg

    /// Padding for screen edges
    static let screenPadding: CGFloat = xl

    /// Space between sections
    static let sectionSpacing: CGFloat = xxxl

    /// Space between cards/elements
    static let cardSpacing: CGFloat = md

    /// Space between interactive elements (buttons)
    static let buttonSpacing: CGFloat = sm

    /// Breathing room above the tab bar so bottom-anchored controls don’t sit flush.
    static let tabBarClearance: CGFloat = xl

    // MARK: - Component Specific

    /// Height for navigation cards/buttons
    static let navigationCardHeight: CGFloat = 75

    /// Height for input fields
    static let inputHeight: CGFloat = 50

    /// Height for quality buttons
    static let qualityButtonHeight: CGFloat = 50

    // MARK: - Corner radius tokens (single source of truth)

    /// 12pt — controls, keys, tiles, input fields, disclosure rows
    static let cornerRadiusSmall: CGFloat = 12

    /// 16pt — cards, result panels, note result tiles, calculator keys
    static let cornerRadiusMedium: CGFloat = 16

    /// 20pt — large chips / feature buttons
    static let cornerRadiusLarge: CGFloat = 20

    /// Alias for chips (maps to large)
    static let cornerRadiusChip: CGFloat = cornerRadiusLarge

    // MARK: - Corner shapes (always continuous — use these, not raw RoundedRectangle)

    /// Controls, keys, tiles, inputs, disclosure rows
    static var shapeSmall: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadiusSmall, style: .continuous)
    }

    /// Cards, result panels, note tiles, calculator keys
    static var shapeMedium: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadiusMedium, style: .continuous)
    }

    /// Large chips / feature buttons
    static var shapeLarge: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadiusLarge, style: .continuous)
    }

    /// Feature / quality chips
    static var shapeChip: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadiusChip, style: .continuous)
    }
}

// MARK: - EdgeInsets Presets

extension EdgeInsets {
    /// Standard content padding on all sides
    static let content = EdgeInsets(
        top: Spacing.contentPadding,
        leading: Spacing.contentPadding,
        bottom: Spacing.contentPadding,
        trailing: Spacing.contentPadding
    )

    /// Screen edge padding
    static let screen = EdgeInsets(
        top: Spacing.screenPadding,
        leading: Spacing.screenPadding,
        bottom: Spacing.screenPadding,
        trailing: Spacing.screenPadding
    )

    /// Horizontal-only padding
    static let horizontal = EdgeInsets(
        top: 0,
        leading: Spacing.contentPadding,
        bottom: 0,
        trailing: Spacing.contentPadding
    )

    /// Vertical-only padding
    static let vertical = EdgeInsets(
        top: Spacing.contentPadding,
        leading: 0,
        bottom: Spacing.contentPadding,
        trailing: 0
    )
}
