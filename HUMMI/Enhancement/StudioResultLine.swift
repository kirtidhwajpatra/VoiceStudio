//
//  StudioResultLine.swift
//  HUMMI
//
//  The reward moment when a take reaches Studio: one line naming what
//  changed in *this* take, measured, not generic ("Studio take ready ·
//  20% steadier · Clarity +3 dB"). It appears once with a single success
//  haptic and then stays put as a quiet caption. Specific, earned
//  feedback beats confetti: it tells the singer their take improved and
//  by how much, which is the reason to come back and record the next one.
//

import SwiftUI

struct StudioResultLine: View {
    let report: PolishReport?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        Group {
            if let report {
                HStack(spacing: Spacing.xs) {
                    HummiIcon(glyph: .sparkle, treatment: .filled, size: 14)
                    Text(text(for: report))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(StudioTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .opacity(shown ? 1 : 0)
                .offset(y: shown || reduceMotion ? 0 : 4)
                .onAppear(perform: reveal)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(height: 20)
    }

    private func text(for report: PolishReport) -> String {
        (["Studio take ready"] + report.highlights).joined(separator: " · ")
    }

    private func reveal() {
        guard !shown else { return }
        Haptics.shared.notify(.success)
        withAnimation(.easeOut(duration: 0.35)) { shown = true }
    }
}
