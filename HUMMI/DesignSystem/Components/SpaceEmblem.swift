//
//  SpaceEmblem.swift
//  HUMMI
//
//  A space filter drawn as the room itself: a bright source dot with
//  reverberation rings radiating out of it. The number of rings and how
//  far they spread grow with the room's decay time — a dry booth shows
//  one tight ring, a cathedral shows four wide ones. The source and rings
//  take the tile's own glow colour, so each space keeps its identity. One
//  geometry, one colour: bigger room, more reverb.
//

import SwiftUI

struct SpaceEmblem: View {
    let palette: TilePalette
    /// Reverb decay in seconds — drives ring count and spread.
    let decay: Double
    var isActive: Bool = false
    var size: CGFloat = 52

    /// Decay maps to a ring count of 1…4.
    private var ringCount: Int {
        switch decay {
        case ..<0.5:  return 1
        case ..<1.2:  return 2
        case ..<2.4:  return 3
        default:      return 4
        }
    }

    /// The room keeps its own colour when selected; the tile's outline
    /// shows selection. Pale lime on the light canvas was hard to see.
    private var tint: Color { palette.glow }

    var body: some View {
        ZStack {
            // Reverberation rings — each further out is fainter and thinner,
            // like energy bleeding into the room.
            ForEach(0..<ringCount, id: \.self) { i in
                let t = Double(i + 1) / Double(ringCount)
                Circle()
                    .strokeBorder(tint.opacity(0.9 - t * 0.6),
                                  lineWidth: max(1, 2.2 - t * 1.4))
                    .frame(width: size * (0.42 + t * 0.58),
                           height: size * (0.42 + t * 0.58))
            }

            // The source: where the voice sits in the room.
            Circle()
                .fill(tint)
                .frame(width: size * 0.2, height: size * 0.2)
        }
        .frame(width: size, height: size)
        .animation(Motion.standard, value: isActive)
        .animation(Motion.standard, value: ringCount)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 20) {
        ForEach(FilterLibrary.spaces.prefix(4)) { s in
            VStack {
                SpaceEmblem(palette: s.tile, decay: s.decay, isActive: s.id == "hall")
                Text(s.name).font(.caption2)
            }
        }
    }
    .padding(40)
    .background(Color(white: 0.1))
}
#endif
