//
//  SpaceIllustration.swift
//  HUMMI
//
//  Each space drawn as the place itself, so a singer understands at a
//  glance how much room it adds: a close mic (Dry), a foam-lined booth,
//  then rooms drawn in perspective that get deeper as they get bigger
//  (Studio Room → Live Room), a concert hall, a cathedral window, a
//  hanging reverb plate and a dream cloud. Line art in the house style:
//  2pt rounded strokes on a 64×44 grid, ink lines, and one accent — the
//  singer's voice — in the space's own colour.
//
//  `RoomSizeMeter` sits under it: five dots filled by how big the room is.
//

import SwiftUI

struct SpaceIllustration: View {
    enum Kind: CaseIterable {
        case dry, booth, studioRoom, liveRoom, hall, cathedral, plate, dream

        init(spaceID: String) {
            switch spaceID {
            case "dry": self = .dry
            case "booth": self = .booth
            case "studio-room": self = .studioRoom
            case "live-room": self = .liveRoom
            case "hall": self = .hall
            case "cathedral": self = .cathedral
            case "plate": self = .plate
            default: self = .dream
            }
        }

        /// 0…5 — how much room this space adds, for the size meter.
        var size: Int {
            switch self {
            case .dry: 0
            case .booth: 1
            case .studioRoom, .plate: 2
            case .liveRoom: 3
            case .hall, .dream: 4
            case .cathedral: 5
            }
        }
    }

    let kind: Kind
    var ink: Color = Brand.ink
    var accent: Color = Brand.limeDeep
    var width: CGFloat = 64

    @Environment(\.colorScheme) private var colorScheme

    /// Some space colours (Dry grey, Booth red) are dark; lift them on the
    /// dark canvas so the singer's dot stays visible.
    private var voiceColor: Color {
        colorScheme == .dark ? accent.mix(with: .white, by: 0.35) : accent
    }

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 64
            let line = StrokeStyle(lineWidth: 2 * s, lineCap: .round, lineJoin: .round)
            let thin = StrokeStyle(lineWidth: 1.4 * s, lineCap: .round, lineJoin: .round)
            func t(_ p: Path) -> Path { p.applying(.init(scaleX: s, y: s)) }
            let drawing = Self.drawing(for: kind)
            ctx.stroke(t(drawing.lines), with: .color(ink), style: line)
            ctx.stroke(t(drawing.detail), with: .color(ink.opacity(0.45)), style: thin)
            ctx.fill(t(drawing.voiceFill), with: .color(voiceColor))
            ctx.stroke(t(drawing.voiceStroke), with: .color(voiceColor), style: thin)
        }
        .frame(width: width, height: width * 44 / 64)
        .accessibilityHidden(true)
    }

    // MARK: - Drawings (64×44 grid)

    private struct Drawing {
        var lines = Path()       // main ink strokes
        var detail = Path()      // lighter ink: foam, seats, panels
        var voiceFill = Path()   // the singer, in the space's colour
        var voiceStroke = Path() // sound waves, in the space's colour
    }

    private static func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat = 2.6) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    /// A room in one-point perspective: the smaller the back wall, the
    /// deeper (bigger) the room reads.
    private static func room(inset: CGFloat, into d: inout Drawing) {
        let outer = CGRect(x: 6, y: 3, width: 52, height: 38)
        let back = outer.insetBy(dx: inset * 1.25, dy: inset)
        d.lines.addRoundedRect(in: outer, cornerSize: CGSize(width: 5, height: 5))
        d.lines.addRect(back)
        for (a, b) in [(CGPoint(x: outer.minX + 1.5, y: outer.minY + 1.5), CGPoint(x: back.minX, y: back.minY)),
                       (CGPoint(x: outer.maxX - 1.5, y: outer.minY + 1.5), CGPoint(x: back.maxX, y: back.minY)),
                       (CGPoint(x: outer.minX + 1.5, y: outer.maxY - 1.5), CGPoint(x: back.minX, y: back.maxY)),
                       (CGPoint(x: outer.maxX - 1.5, y: outer.maxY - 1.5), CGPoint(x: back.maxX, y: back.maxY))] {
            d.detail.move(to: a); d.detail.addLine(to: b)
        }
        d.voiceFill.addPath(dot(back.midX, back.maxY - 5))
    }

    private static func drawing(for kind: Kind) -> Drawing {
        var d = Drawing()
        switch kind {
        case .dry:
            // A close mic, nothing around it: no room at all.
            d.lines.addRoundedRect(in: CGRect(x: 26, y: 4, width: 12, height: 20), cornerSize: CGSize(width: 6, height: 6))
            d.lines.move(to: CGPoint(x: 21, y: 18))
            d.lines.addQuadCurve(to: CGPoint(x: 43, y: 18), control: CGPoint(x: 32, y: 36))
            d.lines.move(to: CGPoint(x: 32, y: 29)); d.lines.addLine(to: CGPoint(x: 32, y: 38))
            d.lines.move(to: CGPoint(x: 25, y: 39)); d.lines.addLine(to: CGPoint(x: 39, y: 39))
            for y in [10.0, 15.0] {
                d.detail.move(to: CGPoint(x: 29, y: y)); d.detail.addLine(to: CGPoint(x: 35, y: y))
            }
            d.voiceStroke.move(to: CGPoint(x: 47, y: 10)); d.voiceStroke.addLine(to: CGPoint(x: 51, y: 10))
            d.voiceStroke.move(to: CGPoint(x: 47, y: 15)); d.voiceStroke.addLine(to: CGPoint(x: 54, y: 15))

        case .booth:
            // A small box lined with foam wedges.
            let box = CGRect(x: 14, y: 4, width: 36, height: 36)
            d.lines.addRoundedRect(in: box, cornerSize: CGSize(width: 5, height: 5))
            d.detail.move(to: CGPoint(x: 18, y: 10))
            for i in 0..<7 {
                let x = 18 + CGFloat(i) * 4
                d.detail.addLine(to: CGPoint(x: x + 2, y: 7.5)); d.detail.addLine(to: CGPoint(x: x + 4, y: 10))
            }
            for side in [CGFloat(18), 46] {
                d.detail.move(to: CGPoint(x: side, y: 14))
                for i in 0..<5 {
                    let y = 14 + CGFloat(i) * 4.6
                    d.detail.addLine(to: CGPoint(x: side == 18 ? 20.5 : 43.5, y: y + 2.3))
                    d.detail.addLine(to: CGPoint(x: side, y: y + 4.6))
                }
            }
            d.voiceFill.addPath(dot(32, 30))
            d.voiceStroke.addArc(center: CGPoint(x: 32, y: 30), radius: 6,
                                 startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)

        case .studioRoom:
            room(inset: 8, into: &d)
            // An acoustic panel on the back wall.
            d.detail.addRect(CGRect(x: 26, y: 15, width: 12, height: 6))

        case .liveRoom:
            room(inset: 12.5, into: &d)
            // Wider, deeper room with a window on the side wall.
            d.detail.move(to: CGPoint(x: 13, y: 14)); d.detail.addLine(to: CGPoint(x: 13, y: 26))
            d.detail.move(to: CGPoint(x: 17, y: 16)); d.detail.addLine(to: CGPoint(x: 17, y: 25))

        case .hall:
            // A proscenium arch over a stage, rows of seats in front.
            d.lines.move(to: CGPoint(x: 8, y: 40))
            d.lines.addLine(to: CGPoint(x: 8, y: 18))
            d.lines.addArc(center: CGPoint(x: 32, y: 18), radius: 24,
                           startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            d.lines.addLine(to: CGPoint(x: 56, y: 40))
            d.lines.move(to: CGPoint(x: 16, y: 24)); d.lines.addLine(to: CGPoint(x: 48, y: 24))
            // Rows of seats, each row wider than the one in front.
            for (row, y) in [CGFloat(29), 34, 39].enumerated() {
                let count = 4 + row
                let span = CGFloat(18 + row * 6)
                for i in 0..<count {
                    let x = 32 - span / 2 + span * CGFloat(i) / CGFloat(count - 1)
                    d.detail.move(to: CGPoint(x: x - 1.2, y: y)); d.detail.addLine(to: CGPoint(x: x + 1.2, y: y))
                }
            }
            d.voiceFill.addPath(dot(32, 19.5, 2.4))

        case .cathedral:
            // A tall pointed gothic window with a rose at the top.
            d.lines.move(to: CGPoint(x: 18, y: 41))
            d.lines.addLine(to: CGPoint(x: 18, y: 20))
            d.lines.addQuadCurve(to: CGPoint(x: 32, y: 2), control: CGPoint(x: 18, y: 7))
            d.lines.addQuadCurve(to: CGPoint(x: 46, y: 20), control: CGPoint(x: 46, y: 7))
            d.lines.addLine(to: CGPoint(x: 46, y: 41))
            d.detail.addEllipse(in: CGRect(x: 27, y: 10, width: 10, height: 10))
            d.detail.move(to: CGPoint(x: 32, y: 24)); d.detail.addLine(to: CGPoint(x: 32, y: 41))
            d.detail.move(to: CGPoint(x: 18, y: 30)); d.detail.addLine(to: CGPoint(x: 46, y: 30))
            d.voiceFill.addPath(dot(32, 36, 2.4))
            d.voiceStroke.addArc(center: CGPoint(x: 32, y: 36), radius: 6,
                                 startAngle: .degrees(205), endAngle: .degrees(335), clockwise: false)

        case .plate:
            // A metal reverb plate hanging from two springs.
            d.lines.move(to: CGPoint(x: 10, y: 5)); d.lines.addLine(to: CGPoint(x: 54, y: 5))
            d.lines.addRoundedRect(in: CGRect(x: 14, y: 14, width: 36, height: 24), cornerSize: CGSize(width: 3, height: 3))
            for x in [CGFloat(20), 44] {
                d.detail.move(to: CGPoint(x: x, y: 5))
                for i in 0..<4 { d.detail.addLine(to: CGPoint(x: x + (i % 2 == 0 ? 2 : -2), y: 7 + CGFloat(i) * 1.8)) }
                d.detail.addLine(to: CGPoint(x: x, y: 14))
            }
            // The plate shimmering: a voice dot and short vibration lines.
            d.voiceFill.addPath(dot(32, 26))
            for x in [CGFloat(22), 42] {
                d.voiceStroke.move(to: CGPoint(x: x, y: 22)); d.voiceStroke.addLine(to: CGPoint(x: x, y: 30))
            }
            for x in [CGFloat(18), 46] {
                d.voiceStroke.move(to: CGPoint(x: x, y: 24)); d.voiceStroke.addLine(to: CGPoint(x: x, y: 28))
            }

        case .dream:
            // A soft cloud with sparkles drifting off it.
            d.lines.move(to: CGPoint(x: 14, y: 34))
            d.lines.addCurve(to: CGPoint(x: 18, y: 20), control1: CGPoint(x: 7, y: 34), control2: CGPoint(x: 8, y: 20))
            d.lines.addCurve(to: CGPoint(x: 36, y: 13), control1: CGPoint(x: 20, y: 11), control2: CGPoint(x: 32, y: 8))
            d.lines.addCurve(to: CGPoint(x: 50, y: 23), control1: CGPoint(x: 44, y: 11), control2: CGPoint(x: 52, y: 16))
            d.lines.addCurve(to: CGPoint(x: 48, y: 34), control1: CGPoint(x: 57, y: 25), control2: CGPoint(x: 56, y: 34))
            d.lines.closeSubpath()
            for (x, y, r) in [(CGFloat(54), CGFloat(8), CGFloat(4)), (12, 9, 3)] {
                d.voiceStroke.move(to: CGPoint(x: x, y: y - r)); d.voiceStroke.addLine(to: CGPoint(x: x, y: y + r))
                d.voiceStroke.move(to: CGPoint(x: x - r, y: y)); d.voiceStroke.addLine(to: CGPoint(x: x + r, y: y))
            }
            d.voiceFill.addPath(dot(32, 26))
            d.detail.move(to: CGPoint(x: 22, y: 40)); d.detail.addLine(to: CGPoint(x: 30, y: 40))
            d.detail.move(to: CGPoint(x: 36, y: 40)); d.detail.addLine(to: CGPoint(x: 42, y: 40))
        }
        return d
    }
}

/// Five dots: how much room a space adds, from none (Dry) to the most
/// (Cathedral). The quickest way to compare spaces without reading.
struct RoomSizeMeter: View {
    let size: Int
    var color: Color = Brand.ink

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(i < size ? color : color.opacity(0.15))
                    .frame(width: 8, height: 3)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(size == 0 ? "No room" : "Room size \(size) of 5")
    }
}
