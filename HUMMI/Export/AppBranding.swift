//
//  AppBranding.swift
//  HUMMI
//

import SwiftUI

/// Single source of truth for the product name and accent used across the
/// app and in exported media.
nonisolated enum AppBranding {
    static let name = "Voice Studio"

    /// Accent RGB (studio blue, Brand.accent), for CoreGraphics export.
    static let accentRGBA: (r: Double, g: Double, b: Double, a: Double) =
        (0x14 / 255.0, 0x58 / 255.0, 0xE6 / 255.0, 1.0)

    static var accentColor: Color {
        Color(red: accentRGBA.r, green: accentRGBA.g, blue: accentRGBA.b)
    }

    static let watermarkText = "Made with \(name)"
}
