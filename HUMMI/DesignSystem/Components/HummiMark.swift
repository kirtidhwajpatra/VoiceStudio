//
//  HummiMark.swift
//  HUMMI
//
//  The app-icon logo, drawn in code from AppIcon-1024's geometry so it is
//  crisp at any size and its parts can move independently: the coral mic
//  ring, the two-tone blue cradle (dark left, light right, overlapping at
//  the bottom), the base pill and the sparkle.
//
//  `micScale`, `cradleProgress` and `sparkle` (0…1) let the splash build
//  the mark piece by piece; at their defaults it is the finished logo.
//

import SwiftUI

struct HummiMark: View {
    var size: CGFloat = 120
    /// 0…1 scale of the mic ring.
    var micScale: CGFloat = 1
    /// 0…1 how much of the cradle is drawn.
    var cradleProgress: CGFloat = 1
    /// 0…1 sparkle scale.
    var sparkle: CGFloat = 1
    /// Draws the mark in one colour (e.g. on a coloured background).
    var monochrome: Color? = nil

    var body: some View {
        Canvas { ctx, canvas in
            // Geometry is on the icon's 1024 grid; the mark spans x 260–764,
            // y 178–852, so crop to that box and scale it into the frame.
            let box = CGRect(x: 250, y: 170, width: 524, height: 690)
            let k = min(canvas.width / box.width, canvas.height / box.height)
            ctx.translateBy(x: (canvas.width - box.width * k) / 2, y: (canvas.height - box.height * k) / 2)
            ctx.scaleBy(x: k, y: k)
            ctx.translateBy(x: -box.minX, y: -box.minY)

            let blue = monochrome ?? Brand.logoBlue
            let sky = monochrome ?? Brand.logoSky
            let coral = monochrome ?? Brand.logoCoral
            let thick = StrokeStyle(lineWidth: 88, lineCap: .round)

            // Cradle: a semicircle under the mic. Left half dark blue, right
            // half light blue drawn on top, starting just left of centre so
            // its round end overlaps the blue — as in the icon.
            let center = CGPoint(x: 512, y: 482)
            var left = Path()
            left.addArc(center: center, radius: 208, startAngle: .degrees(180),
                        endAngle: .degrees(180 - 90 * Double(min(cradleProgress * 2, 1))), clockwise: true)
            ctx.stroke(left, with: .color(blue), style: thick)
            if cradleProgress > 0.5 {
                var right = Path()
                right.addArc(center: center, radius: 208, startAngle: .degrees(100),
                             endAngle: .degrees(100 - 100 * Double((cradleProgress - 0.5) * 2)), clockwise: true)
                ctx.stroke(right, with: .color(sky), style: thick)
            }

            // Base pill.
            ctx.fill(Path(roundedRect: CGRect(x: 398, y: 765, width: 227, height: 87), cornerRadius: 43.5),
                     with: .color(blue))

            // Mic ring, scaled about its own centre.
            var mic = ctx
            mic.translateBy(x: 511, y: 426)
            mic.scaleBy(x: micScale, y: micScale)
            mic.translateBy(x: -511, y: -426)
            mic.stroke(Path(roundedRect: CGRect(x: 417, y: 265, width: 188, height: 322), cornerRadius: 94),
                       with: .color(coral), style: StrokeStyle(lineWidth: 90))

            // Sparkle.
            var star = ctx
            star.translateBy(x: 646, y: 221)
            star.scaleBy(x: sparkle, y: sparkle)
            let starPath = Self.sparklePath(radius: 44)
            star.fill(starPath, with: .color(blue))
            star.stroke(starPath, with: .color(blue), style: StrokeStyle(lineWidth: 12, lineJoin: .round))
        }
        .frame(width: size, height: size * 690 / 524)
        .accessibilityHidden(true)
    }

    /// The icon's four-point star: straight sides to a small waist,
    /// rounded tips (drawn as a fill plus a same-colour round-join stroke).
    static func sparklePath(radius r: CGFloat) -> Path {
        let tip = r * 0.84, waist = r * 0.2
        var p = Path()
        p.move(to: CGPoint(x: 0, y: -tip))
        p.addLine(to: CGPoint(x: waist, y: -waist))
        p.addLine(to: CGPoint(x: tip, y: 0))
        p.addLine(to: CGPoint(x: waist, y: waist))
        p.addLine(to: CGPoint(x: 0, y: tip))
        p.addLine(to: CGPoint(x: -waist, y: waist))
        p.addLine(to: CGPoint(x: -tip, y: 0))
        p.addLine(to: CGPoint(x: -waist, y: -waist))
        p.closeSubpath()
        return p
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 40) {
        HummiMark(size: 120)
        HummiMark(size: 60, monochrome: .white).padding(20).background(Brand.accent, in: Circle())
    }
    .padding(40)
    .background(Brand.canvas)
}
#endif
