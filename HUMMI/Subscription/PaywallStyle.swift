//
//  PaywallStyle.swift
//  HUMMI
//
//  Colour roles for the always-dark purchase flow, so every piece of it
//  uses the same five neutrals and blue appears only where it carries
//  meaning: the one filled CTA, the selected plan, and progress.
//
//    canvas    — Brand.night, flat, no glow or grain
//    surface   — one step up, for cards
//    fill      — neutral control fill (play button, unselected chips)
//    hairline  — dividers and unselected outlines
//    primary / secondary / tertiary — text by importance, via opacity
//

import SwiftUI

enum PaywallStyle {
    static let canvas = Brand.night
    static let surface = Color.white.opacity(0.06)
    static let fill = Color.white.opacity(0.10)
    static let hairline = Color.white.opacity(0.12)
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.62)
    static let tertiary = Color.white.opacity(0.40)
    /// Failures: a calm amber. Red is reserved for the record button.
    static let caution = Color(red: 1.0, green: 0.78, blue: 0.35)
}
