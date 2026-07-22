//
//  Typography.swift
//  Functional Harmony
//
//  Created by Dylan Shade on 10/8/25.
//  Design System - Typography Scale
//

import SwiftUI

extension Font {

    // MARK: - Display (Extra Large - Hero Text)

    /// 100pt - Landing page title
    static let displayHero = Font.system(size: 100, weight: .bold, design: .default)

    /// 72pt - Large display text
    static let displayLarge = Font.system(size: 72, weight: .bold, design: .default)

    /// 56pt - Medium display text
    static let displayMedium = Font.system(size: 56, weight: .bold, design: .default)

    // MARK: - Headings

    /// 40pt - H1 main section titles
    static let heading1 = Font.system(size: 40, weight: .bold, design: .default)

    /// 32pt - H2 sub-section titles
    static let heading2 = Font.system(size: 32, weight: .bold, design: .default)

    /// 24pt - H3 card titles (current .title usage)
    static let heading3 = Font.system(size: 24, weight: .bold, design: .default)

    /// 20pt - H4 small headings
    static let heading4 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body Text

    /// 18pt - Large body text
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .default)

    /// 16pt - Regular body text
    static let bodyRegular = Font.system(size: 16, weight: .regular, design: .default)

    /// 14pt - Small body text
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

    // MARK: - Special Use

    /// For note names (musical notation)
    static let noteName = Font.system(size: 28, weight: .bold, design: .monospaced)

    /// For chord quality buttons
    static let buttonLabel = Font.system(size: 16, weight: .semibold, design: .default)

    /// For input fields
    static let input = Font.system(size: 18, weight: .regular, design: .default)

    /// For captions and small labels
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    // MARK: - Result Titles (Bebas Neue — display only)

    /// PostScript name registered via `UIAppFonts` → `BebasNeue-Regular.ttf`.
    private static let resultDisplayFamily = "BebasNeue-Regular"

    /// Compact answer banner title (portrait, non-hero).
    static let resultTitle = Font.custom(resultDisplayFamily, size: 30)

    /// Hero answer banner title (expands-to-fill portrait band).
    static let resultTitleHero = Font.custom(resultDisplayFamily, size: 44)

    /// Full-bleed landscape answer title.
    static let resultTitleFullscreen = Font.custom(resultDisplayFamily, size: 72)
}

// MARK: - Dynamic Type Support

extension Font {
    /// Returns a scaled version of the font that respects Dynamic Type
    static func scaled(_ font: Font, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        return font
    }
}

// MARK: - Text Styles (SwiftUI View Modifier)

struct AppTextStyle: ViewModifier {
    let style: TextStyleType

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(style.color)
    }
}

enum TextStyleType {
    case displayHero
    case heading1
    case heading2
    case heading3
    case body
    case caption
    case noteName
    case button

    var font: Font {
        switch self {
        case .displayHero: return .displayHero
        case .heading1: return .heading1
        case .heading2: return .heading2
        case .heading3: return .heading3
        case .body: return .bodyRegular
        case .caption: return .caption
        case .noteName: return .noteName
        case .button: return .buttonLabel
        }
    }

    var color: Color {
        switch self {
        case .displayHero, .heading1, .heading2, .heading3, .button:
            return .textPrimary
        case .body, .noteName:
            return .textPrimary
        case .caption:
            return .textSecondary
        }
    }
}

extension View {
    func textStyle(_ style: TextStyleType) -> some View {
        modifier(AppTextStyle(style: style))
    }
}
