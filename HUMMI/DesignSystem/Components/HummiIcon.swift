//
//  HummiIcon.swift
//  HUMMI
//
//  The house icon family — "Rounded Stroke". Every glyph is drawn in code
//  on a 24×24 grid with a uniform ~2pt stroke and fully rounded caps and
//  joins, so the whole set shares one voice and themes perfectly across
//  the light and forest-black canvases. SF Symbols still cover system
//  affordances (share sheet, chevrons) — HummiIcon is for the glyphs that
//  should feel like HUMMI: the mic, the waveform, the enhance sparkle, the
//  room, export and playback.
//
//  Two renderings per glyph:
//   • line   — forest ink stroke, for inactive / secondary states
//   • filled — lime-gradient, for the active / selected state and the one
//              primary action per screen
//  Never put two filled HummiIcons in competition in a single view.
//

import SwiftUI

struct HummiIcon: View {
    enum Glyph {
        case mic
        case waveform
        case sparkle
        case room
        case play
        case pause
        case exportArrow
        case folder
        case gear
        case script
    }

    enum Treatment {
        /// Stroked outline in the given colour.
        case line(Color)
        /// Lime-gradient fill — the active / primary treatment.
        case filled
        /// Stroked with the lime gradient — active, but lighter than filled.
        case active
    }

    let glyph: Glyph
    var treatment: Treatment = .line(Brand.ink)
    var size: CGFloat = 24
    /// Stroke weight, expressed on the 24-grid; scales with `size`.
    var weight: CGFloat = 2

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = canvasSize.width / 24.0            // grid → point scale
            let lineW = weight * s
            let style = StrokeStyle(lineWidth: lineW, lineCap: .round, lineJoin: .round)
            let path = HummiIcon.path(for: glyph).applying(.init(scaleX: s, y: s))

            switch treatment {
            case .line(let color):
                ctx.stroke(path, with: .color(color), style: style)
            case .active:
                ctx.stroke(path, with: shading(canvasSize), style: style)
            case .filled:
                // Fill the closed/body glyphs; stroke the linear ones so a
                // "fill" still reads for a waveform or a play triangle.
                if glyph.prefersFill {
                    ctx.fill(path, with: shading(canvasSize))
                } else {
                    ctx.stroke(path, with: shading(canvasSize),
                               style: StrokeStyle(lineWidth: lineW * 1.25, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func shading(_ size: CGSize) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(colors: [Brand.lime, Brand.limeDeep]),
            startPoint: .zero,
            endPoint: CGPoint(x: size.width, y: size.height))
    }

    // MARK: - Paths (24×24 grid)

    static func path(for glyph: Glyph) -> Path {
        var p = Path()
        switch glyph {
        case .mic:
            // Capsule mic body.
            p.addRoundedRect(in: CGRect(x: 9, y: 3, width: 6, height: 11),
                             cornerSize: CGSize(width: 3, height: 3))
            // Cradle arc.
            p.addArc(center: CGPoint(x: 12, y: 11), radius: 5,
                     startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
            // Stem + base.
            p.move(to: CGPoint(x: 12, y: 16)); p.addLine(to: CGPoint(x: 12, y: 20))
            p.move(to: CGPoint(x: 8, y: 20));  p.addLine(to: CGPoint(x: 16, y: 20))

        case .waveform:
            // Five rounded bars of varying height — the brand waveform.
            let heights: [CGFloat] = [6, 12, 18, 10, 7]
            for (i, h) in heights.enumerated() {
                let x = 3 + CGFloat(i) * 4.5
                p.move(to: CGPoint(x: x, y: 12 - h / 2))
                p.addLine(to: CGPoint(x: x, y: 12 + h / 2))
            }

        case .sparkle:
            // Four-point rounded star — the enhance mark.
            p.move(to: CGPoint(x: 12, y: 2))
            p.addQuadCurve(to: CGPoint(x: 14, y: 10), control: CGPoint(x: 13, y: 8))
            p.addQuadCurve(to: CGPoint(x: 22, y: 12), control: CGPoint(x: 16, y: 11))
            p.addQuadCurve(to: CGPoint(x: 14, y: 14), control: CGPoint(x: 16, y: 13))
            p.addQuadCurve(to: CGPoint(x: 12, y: 22), control: CGPoint(x: 13, y: 16))
            p.addQuadCurve(to: CGPoint(x: 10, y: 14), control: CGPoint(x: 11, y: 16))
            p.addQuadCurve(to: CGPoint(x: 2, y: 12), control: CGPoint(x: 8, y: 13))
            p.addQuadCurve(to: CGPoint(x: 10, y: 10), control: CGPoint(x: 8, y: 11))
            p.addQuadCurve(to: CGPoint(x: 12, y: 2), control: CGPoint(x: 11, y: 8))
            p.closeSubpath()

        case .room:
            // A voice filling a room: a source dot and two reverb rings,
            // the same mark the Space tiles use.
            p.addEllipse(in: CGRect(x: 10.5, y: 10.5, width: 3, height: 3))
            p.addEllipse(in: CGRect(x: 7, y: 7, width: 10, height: 10))
            p.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))

        case .play:
            p.move(to: CGPoint(x: 7, y: 4))
            p.addLine(to: CGPoint(x: 20, y: 12))
            p.addLine(to: CGPoint(x: 7, y: 20))
            p.closeSubpath()

        case .pause:
            p.addRoundedRect(in: CGRect(x: 6, y: 4, width: 4, height: 16),
                             cornerSize: CGSize(width: 2, height: 2))
            p.addRoundedRect(in: CGRect(x: 14, y: 4, width: 4, height: 16),
                             cornerSize: CGSize(width: 2, height: 2))

        case .exportArrow:
            // Down-into-tray export mark.
            p.move(to: CGPoint(x: 12, y: 3)); p.addLine(to: CGPoint(x: 12, y: 14))
            p.move(to: CGPoint(x: 8, y: 10)); p.addLine(to: CGPoint(x: 12, y: 14))
            p.addLine(to: CGPoint(x: 16, y: 10))
            p.move(to: CGPoint(x: 4, y: 17))
            p.addLine(to: CGPoint(x: 4, y: 20)); p.addLine(to: CGPoint(x: 20, y: 20))
            p.addLine(to: CGPoint(x: 20, y: 17))

        case .folder:
            // Rounded folder with a soft tab, matching the 2pt round family.
            p.move(to: CGPoint(x: 3, y: 8))
            p.addQuadCurve(to: CGPoint(x: 5.5, y: 5.5), control: CGPoint(x: 3, y: 5.5))
            p.addLine(to: CGPoint(x: 9, y: 5.5))
            p.addLine(to: CGPoint(x: 11, y: 7.5))
            p.addLine(to: CGPoint(x: 18.5, y: 7.5))
            p.addQuadCurve(to: CGPoint(x: 21, y: 10), control: CGPoint(x: 21, y: 7.5))
            p.addLine(to: CGPoint(x: 21, y: 16.5))
            p.addQuadCurve(to: CGPoint(x: 18.5, y: 19), control: CGPoint(x: 21, y: 19))
            p.addLine(to: CGPoint(x: 5.5, y: 19))
            p.addQuadCurve(to: CGPoint(x: 3, y: 16.5), control: CGPoint(x: 3, y: 19))
            p.closeSubpath()

        case .gear:
            // Settings as two mixer faders — on-theme for a studio app and
            // cleaner than a toothed gear at small sizes.
            p.move(to: CGPoint(x: 4, y: 8)); p.addLine(to: CGPoint(x: 20, y: 8))
            p.move(to: CGPoint(x: 4, y: 16)); p.addLine(to: CGPoint(x: 20, y: 16))
            p.addEllipse(in: CGRect(x: 12.5, y: 5.5, width: 5, height: 5))
            p.addEllipse(in: CGRect(x: 6.5, y: 13.5, width: 5, height: 5))

        case .script:
            // A lyric sheet: soft page, three lines, the last one shorter.
            p.addRoundedRect(in: CGRect(x: 5, y: 3, width: 14, height: 18),
                             cornerSize: CGSize(width: 3.5, height: 3.5))
            for (y, end) in [(8.5, 15.0), (12.0, 15.0), (15.5, 12.5)] {
                p.move(to: CGPoint(x: 9, y: y)); p.addLine(to: CGPoint(x: end, y: y))
            }
        }
        return p
    }
}

private extension HummiIcon.Glyph {
    /// Glyphs whose `.filled` treatment should fill a closed body rather
    /// than stroke (sparkle, play, pause read better filled).
    var prefersFill: Bool {
        switch self {
        case .sparkle, .play, .pause: return true
        default: return false
        }
    }
}

#if DEBUG
#Preview {
    let glyphs: [HummiIcon.Glyph] = [.mic, .waveform, .sparkle, .room, .play, .pause, .exportArrow, .folder, .gear, .script]
    return ScrollView {
        VStack(spacing: 28) {
            ForEach(Array(glyphs.enumerated()), id: \.offset) { _, g in
                HStack(spacing: 28) {
                    HummiIcon(glyph: g, treatment: .line(Brand.ink), size: 32)
                    HummiIcon(glyph: g, treatment: .active, size: 32)
                    HummiIcon(glyph: g, treatment: .filled, size: 32)
                }
            }
        }
        .padding(40)
    }
    .background(Brand.canvas)
}
#endif
