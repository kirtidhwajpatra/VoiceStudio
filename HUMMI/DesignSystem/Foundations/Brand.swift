//
//  Brand.swift
//  HUMMI
//
//  The palette, taken from the app icon: a coral microphone held by a
//  two-tone blue cradle, with a blue sparkle. Coral is the voice, blue is
//  the studio around it.
//
//    accent      studio blue — the one filled primary action per screen
//    accentText  blue for text, outlines and selection on the canvas;
//                lightens in dark mode so it stays readable
//    onAccent    labels and glyphs on accent fills (white)
//    voice       coral — the record button, the live voice, rewards
//    sky         light blue — quiet tints, selection washes, secondary art
//    ink         text on the canvas (deep navy / near-white)
//    canvas      screen background (cool off-white / studio navy-black)
//    night       the fixed dark canvas of always-dark screens
//
//  App colours use the logo's hues at higher saturation (the icon's own
//  coral and light blue are pastels and read as faded in UI). The exact
//  icon colours stay in `logo*` and are used only to draw the mark.
//
//  Contrast (WCAG): white on accent 5.9:1 · accentText 6.5:1 light,
//  7.2:1 dark · ink 19:1 light, 18:1 dark · white on voiceDeep 4.2:1.
//  Never use a fixed-dark colour as text on the canvas: it vanishes in
//  dark mode. Use `ink` or `accentText`.
//

import SwiftUI
import UIKit

enum Brand {
    // MARK: Logo colours (exact pixel values from AppIcon-1024, untagged = sRGB)

    /// Cradle and sparkle blue in the icon.
    static let logoBlue = Color(hex: 0x226CD7)
    /// Microphone coral in the icon.
    static let logoCoral = Color(hex: 0xFD7E80)
    /// Light cradle blue in the icon.
    static let logoSky = Color(hex: 0x89C1FF)

    // MARK: Roles

    /// Primary fill: vivid studio blue (white on it is 5.9:1).
    static let accent = Color(hex: 0x1458E6)
    static let accentGradient = LinearGradient(
        colors: [Color(hex: 0x2668F0), Color(hex: 0x0F4ED6)], startPoint: .top, endPoint: .bottom)
    /// Label/glyph colour on accent fills, in both modes.
    static let onAccent = Color.white

    /// Blue for text, outlines, selection rings and progress on the canvas.
    static let accentText = adaptive(light: 0x0F52D9, dark: 0x5C9BFF)

    /// The voice. Record button, live waveform, reward sparkles.
    static let voice = Color(hex: 0xFF4F5E)
    /// Deeper coral, the bottom of the record button's gradient.
    static let voiceDeep = Color(hex: 0xE8364A)
    static let voiceGradient = LinearGradient(
        colors: [voice, voiceDeep], startPoint: .top, endPoint: .bottom)
    /// Text on a coral fill.
    static let onVoice = Color.white

    /// Light blue: tints, washes, secondary illustration strokes.
    static let sky = Color(hex: 0x4FA3FF)

    /// Text and glyphs on the canvas.
    static let ink = adaptive(light: 0x070D1F, dark: 0xF5F7FC)
    /// Screen background.
    static let canvas = adaptive(light: 0xFFFFFF, dark: 0x060A14)
    /// One step above the canvas: cards, rows, tiles.
    static let surface = adaptive(light: 0xF1F3F8, dark: 0x141B2E)
    /// The always-dark canvas (paywall). Same as dark-mode `canvas`.
    static let night = Color(hex: 0x060A14)

    // MARK: Legacy names
    // Older views used the lime-era names; they now resolve to the new
    // roles so nothing renders in the old palette.

    static var lime: Color { accent }
    static var limeDeep: Color { accentText }
    static var limeGradient: LinearGradient { accentGradient }
    static var forest: Color { onAccent }

    // MARK: Helpers

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
