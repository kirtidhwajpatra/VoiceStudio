//
//  ToastView.swift
//  HUMMI
//
//  A floating pill for transient status messages. As a reward
//  (`celebration`), its leading mark is the logo's sparkle: it pops in
//  with a quarter turn while three small coral and blue sparkles fly
//  out of it and fade — about half a second, then it rests.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String?
    let isProcessing: Bool
    var celebration = false
    /// Changes on every celebration to replay the burst.
    var celebrationID = 0

    var body: some View {
        HStack(spacing: Spacing.s) {
            if isProcessing {
                ProgressView()
                    .tint(Brand.accentText)
                    .controlSize(.small)
            } else if celebration {
                SparkleBurst(trigger: celebrationID)
                    .frame(width: 22, height: 22)
            } else if let icon {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.accentText)
            }

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.ink)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
        .background(Brand.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Brand.ink.opacity(0.08), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.10), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
    }
}

/// The logo's sparkle as a reward: pops in, and three small sparkles fly
/// out of it. Holds still under Reduce Motion.
struct SparkleBurst: View {
    var trigger: Int
    var color: Color = Brand.accent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var popped = false
    @State private var flown = false

    private let bits: [(angle: Double, color: Color)] = [
        (-60, Brand.voice), (200, Brand.sky), (75, Brand.voice)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(bits.enumerated()), id: \.offset) { _, bit in
                star(size: 7, color: bit.color)
                    .offset(x: flown ? cos(bit.angle * .pi / 180) * 16 : 0,
                            y: flown ? sin(bit.angle * .pi / 180) * 16 : 0)
                    .scaleEffect(flown ? 1 : 0.2)
                    .opacity(flown ? 0 : 1)
            }
            star(size: 20, color: color)
                .scaleEffect(popped || reduceMotion ? 1 : 0.2)
                .rotationEffect(.degrees(popped || reduceMotion ? 0 : -90))
        }
        .onAppear(perform: play)
        .onChange(of: trigger) { _, _ in play() }
        .accessibilityHidden(true)
    }

    private func star(size: CGFloat, color: Color) -> some View {
        Canvas { ctx, s in
            ctx.translateBy(x: s.width / 2, y: s.height / 2)
            let path = HummiMark.sparklePath(radius: s.width / 2 * 0.9)
            ctx.fill(path, with: .color(color))
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: s.width * 0.12, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }

    private func play() {
        guard !reduceMotion else { popped = true; return }
        popped = false; flown = false
        withAnimation(.spring(response: 0.38, dampingFraction: 0.5)) { popped = true }
        withAnimation(.easeOut(duration: 0.55).delay(0.08)) { flown = true }
    }
}
