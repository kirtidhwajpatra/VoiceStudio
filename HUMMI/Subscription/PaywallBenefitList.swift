//
//  PaywallBenefitList.swift
//  HUMMI
//
//  What Pro adds: three outcome-led lines, each with a small custom icon
//  in the house line style. A last, quieter line says what stays free,
//  so the paywall never implies the user lost something they had.
//

import SwiftUI

struct PaywallBenefitList: View {
    private let rows: [(HummiIcon.Glyph, String)] = [
        (.exportArrow, "Save every take, in M4A or lossless WAV"),
        (.waveform, "Share your takes as video"),
        (.sparkle, "Unlimited exports, no caps")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: Spacing.s) {
                    // Neutral: accent is kept for the CTA and the selected plan.
                    HummiIcon(glyph: row.0, treatment: .line(PaywallStyle.secondary), size: 20)
                        .frame(width: 24)
                    Text(row.1)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(PaywallStyle.primary)
                }
            }
            Text("Recording, every voice and every space stay free.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(PaywallStyle.tertiary)
                .padding(.leading, 24 + Spacing.s)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
