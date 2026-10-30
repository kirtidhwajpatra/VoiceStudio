//
//  PaywallLegalFooter.swift
//  HUMMI
//
//  App Review 3.1.2: Terms of Use, Restore, Privacy and the renewal
//  disclosure for the selected plan. Small and quiet, but always on
//  screen and tappable.
//

import SwiftUI

struct PaywallLegalFooter: View {
    let selected: SubscriptionProduct
    let onRestore: () -> Void

    private let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacy = URL(string: "https://kirtidhwajpatra.github.io/Voice-Studio---Support/")!

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: Spacing.m) {
                Link("Terms", destination: terms)
                Button("Restore", action: onRestore)
                Link("Privacy", destination: privacy)
            }
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(PaywallStyle.tertiary)
            .buttonStyle(.plain)

            Text(disclosure)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(PaywallStyle.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var disclosure: String {
        selected.isAutoRenewable
            ? "Charged to your Apple ID at confirmation. Renews monthly unless canceled at least 24 hours before the period ends. Manage in Settings › Apple ID › Subscriptions."
            : "One-time purchase charged to your Apple ID. Never renews. Restores on any device with the same Apple ID."
    }
}
