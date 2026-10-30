//
//  SpaceTile.swift
//  HUMMI
//
//  A space filter as a small picture of the place: a close mic for Dry,
//  a foam booth, rooms that get deeper as they grow, a hall, a cathedral,
//  a reverb plate, a dream cloud. A five-step bar under the name shows
//  how much room it adds. Selection is a lime outline.
//

import SwiftUI

struct SpaceTile: View {
    let filter: SpaceFilter
    let isActive: Bool
    /// Position in the row — staggers the entrance.
    let index: Int
    let action: () -> Void
    var onLongPress: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var kind: SpaceIllustration.Kind { .init(spaceID: filter.id) }

    var body: some View {
        Button(action: action) {

            
            // The place itself (mic, booth, room, hall…) plus a five-step
            // size bar, so it's obvious how much room each space adds.
            VStack(spacing: Spacing.xs) {
                SpaceIllustration(kind: kind, accent: filter.tile.glow, width: 64)

                Text(filter.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isActive ? Brand.ink : Brand.ink.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, Spacing.s)

                RoomSizeMeter(size: kind.size)
            }
            .frame(width: 116, height: 124)
            // Flat neutral tile: the emblem carries the room's colour, the
            // lime outline carries selection. No glass, tint or scale.
            .background(Brand.ink.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isActive ? Brand.limeDeep : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in onLongPress() })
        // No entrance animation: tiles are simply there as the row scrolls.
        .animation(Motion.adaptive(Motion.standard, reduceMotion: reduceMotion), value: isActive)
        .accessibilityLabel("\(filter.name). \(filter.tagline)")
        .accessibilityHint("Applies the \(filter.name) space filter.")
        .accessibilityValue(isActive ? "Selected" : "")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
