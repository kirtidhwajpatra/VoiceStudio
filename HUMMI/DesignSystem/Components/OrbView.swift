//
//  OrbView.swift
//  HUMMI
//
//  A character filter rendered as a small lit world: a deep sphere tinted
//  with its OrbPalette (core → mid → rim), lit by a luminous highlight
//  that burns hottest along one arc — like a planet catching its sun. The
//  highlight style sells the material: `.soft` skin, `.gloss` wet chrome,
//  `.metallic` brushed steel. A seeded light angle gives every filter its
//  own sun, so a row of them reads as a dozen distinct worlds rather than
//  a dozen copies. This is the art the Studio screen always promised; the
//  palette already lives in FilterLibrary — this draws it.
//

import SwiftUI

struct OrbView: View {
    let palette: OrbPalette
    /// Stable per-filter light angle so the sun never jumps between launches.
    let seed: String
    /// 0…1 — selection energy. Turns the light up and tightens the rim.
    var energy: Double = 0
    var diameter: CGFloat = 76

    var body: some View {
        ZStack {
            sphereBody
            highlight
            if palette.grain {
                StudioNoise(opacity: 0.10)
                    .clipShape(Circle())
                    .blendMode(.softLight)
            }
            rimLight
        }
        .frame(width: diameter, height: diameter)
        .compositingGroup()
        // One soft contact shadow, the same for every orb. Coloured glows
        // on a row of twelve read as noise.
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }

    // MARK: - Layers

    /// The planet's body: a radial fall-off from a lit core, offset toward
    /// the sun so the sphere reads as a solid ball, not a flat disc.
    private var sphereBody: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [palette.core, palette.mid, palette.rim],
                    center: sunPoint(scale: 0.7),
                    startRadius: 0,
                    endRadius: diameter * 0.72
                )
            )
            .overlay(
                // Terminator: the dark limb opposite the sun.
                Circle().fill(
                    RadialGradient(
                        colors: [.clear, .black.opacity(0.28)],
                        center: sunPoint(scale: -0.5),
                        startRadius: diameter * 0.2,
                        endRadius: diameter * 0.62
                    )
                )
            )
    }

    /// The specular highlight — the lit kiss of the sun. Its size and
    /// sharpness are what read as skin / gloss / metal.
    private var highlight: some View {
        let spec: (blur: CGFloat, size: CGFloat, opacity: Double) = {
            switch palette.highlight {
            case .soft:     return (diameter * 0.12, diameter * 0.34, 0.55)
            case .gloss:    return (diameter * 0.02, diameter * 0.22, 0.95)
            case .metallic: return (diameter * 0.06, diameter * 0.46, 0.7)
            }
        }()
        return Circle()
            .fill(Color.white)
            .frame(width: spec.size, height: spec.size)
            .blur(radius: spec.blur)
            .opacity(spec.opacity + energy * 0.2)
            .offset(x: cos(radians) * diameter * 0.22,
                    y: sin(radians) * diameter * 0.22)
            .blendMode(palette.highlight == .metallic ? .plusLighter : .screen)
    }

    /// A thin luminous rim that burns brightest on the far arc, selling
    /// the sphere's edge against the dark canvas.
    private var rimLight: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        palette.glow.opacity(0),
                        palette.glow.opacity(0.9 + energy * 0.1),
                        palette.glow.opacity(0)
                    ]),
                    center: .center,
                    angle: .degrees(lightAngle + 180)
                ),
                lineWidth: 1.5 + energy * 1.0
            )
            .blur(radius: 0.5)
    }

    // MARK: - Geometry

    /// The sun's angle, derived from the filter id so it is stable and
    /// every filter gets its own.
    private var lightAngle: Double {
        let s = seed.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Double((s * 37) % 360)
    }

    private var radians: Double { lightAngle * .pi / 180 }

    /// A unit point on the sphere in the sun's direction, used to offset
    /// the radial gradient centre.
    private func sunPoint(scale: Double) -> UnitPoint {
        UnitPoint(x: 0.5 + cos(radians) * 0.5 * scale,
                  y: 0.5 + sin(radians) * 0.5 * scale)
    }
}

#if DEBUG
#Preview {
    let samples = FilterLibrary.characters.prefix(6)
    return ScrollView(.horizontal) {
        HStack(spacing: 20) {
            ForEach(Array(samples)) { c in
                VStack {
                    OrbView(palette: c.orb, seed: c.id, energy: c.id == "studio" ? 1 : 0)
                    Text(c.name).font(.caption)
                }
            }
        }
        .padding(40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
#endif
