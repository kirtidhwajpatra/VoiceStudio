//
//  PaywallPlanRow.swift
//  HUMMI
//
//  One plan, as a flat row: check · name (+ badge) · terms line · price
//  and billing period on the right. Price and period are the largest
//  pricing text on the row, as App Review 3.1.2 expects; the terms line
//  always says what happens after any trial. Selection is the only
//  colour: a lime outline and a lime check.
//

import SwiftUI

struct PaywallPlanRow: View {
    let title: String
    let terms: String
    let price: String
    let period: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                check

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: Spacing.xs) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(PaywallStyle.primary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Brand.forest)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Brand.lime, in: Capsule())
                        }
                    }
                    Text(terms)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(PaywallStyle.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.xs)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PaywallStyle.primary)
                    Text(period)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(PaywallStyle.tertiary)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, 14)
            .frame(minHeight: 64)
            .background(isSelected ? PaywallStyle.fill : PaywallStyle.surface,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Brand.lime : PaywallStyle.hairline,
                                  lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(price) \(period). \(terms)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var check: some View {
        ZStack {
            Circle().strokeBorder(isSelected ? Brand.lime : PaywallStyle.tertiary, lineWidth: 1.5)
            if isSelected {
                Circle().fill(Brand.lime)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Brand.forest)
            }
        }
        .frame(width: 22, height: 22)
    }
}

/// A light press-down response for tappable controls.
struct PressScaleStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(reduceMotion || !configuration.isPressed ? 1 : 0.98)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
