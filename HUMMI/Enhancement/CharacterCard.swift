//
//  CharacterCard.swift
//  HUMMI
//
//  A character filter as a night orb: a deep sphere tinted with the
//  filter's palette, lit by a luminous rim that burns hottest along one
//  arc — like a planet catching its sun. No glyphs; the name floats in
//  the centre of the sphere. Every filter keeps its own hue and its own
//  light angle (seeded from its id), so the row reads as twelve small
//  worlds. Selection adds the brand's lime ring and turns the light up.
//

import SwiftUI

struct CharacterCard: View {
    let filter: CharacterFilter
    let isActive: Bool
    /// Position in the row — staggers the entrance.
    let index: Int
    let action: () -> Void
    var onLongPress: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let diameter: CGFloat = 76

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.s) {
                // The orb: a small lit world tinted with this filter's
                // palette. Selection wraps it in the brand lime ring and
                // turns the light up.
                ZStack {
                    OrbView(palette: filter.orb,
                            seed: filter.id,
                            energy: isActive ? 1 : 0,
                            diameter: diameter)
                }
                .frame(width: 88, height: 88)
                .overlay {
                    if isActive {
                        Circle()
                            .strokeBorder(Brand.limeDeep, lineWidth: 2.5)
                            .frame(width: 86, height: 86)
                            .transition(.opacity)
                    }
                }
                .scaleEffect(isActive ? 1.06 : 1)

                Text(filter.name)
                    .font(.caption.weight(isActive ? .bold : .semibold))
                    .foregroundStyle(isActive ? Brand.ink : Brand.ink.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 96)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in onLongPress() })
        // No entrance animation: cards are simply there as the row scrolls.
        // Only selection animates.
        .animation(Motion.adaptive(Motion.standard, reduceMotion: reduceMotion), value: isActive)
        .accessibilityLabel("\(filter.name). \(filter.tagline)")
        .accessibilityHint("Applies the \(filter.name) voice character filter.")
        .accessibilityValue(isActive ? "Selected" : "")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
