//
//  PaywallPlanPicker.swift
//  HUMMI
//
//  Lifetime (preselected, "Best value") over Monthly, as two flat rows.
//  Every row states its price and billing period; Monthly's terms line
//  always says what happens after any free trial (App Review 3.1.2). If
//  plans fail to load, a calm retry row replaces them.
//

import SwiftUI

struct PaywallPlanPicker: View {
    @Binding var selected: SubscriptionProduct
    let store: SubscriptionManager

    var body: some View {
        switch store.loadState {
        case .failed:
            retryRow
        case .loading where store.products.isEmpty:
            VStack(spacing: Spacing.xs) { placeholder; placeholder }
        default:
            VStack(spacing: Spacing.xs) {
                PaywallPlanRow(title: "Lifetime", terms: lifetimeTerms,
                               price: price(.lifetimePro), period: "one time",
                               badge: "Best value", isSelected: selected == .lifetimePro) {
                    select(.lifetimePro)
                }
                PaywallPlanRow(title: "Monthly", terms: monthlyTerms,
                               price: price(.monthlyPro), period: "per month",
                               isSelected: selected == .monthlyPro) {
                    select(.monthlyPro)
                }
            }
        }
    }

    private func select(_ product: SubscriptionProduct) {
        guard selected != product else { return }
        Haptics.shared.play(.light)
        selected = product
    }

    private func price(_ product: SubscriptionProduct) -> String {
        store.displayPrice(for: product) ?? "—"
    }

    private var lifetimeTerms: String {
        if let months = store.lifetimeBreakEvenMonths {
            return "Pay once, keep forever. Costs the same as \(months) months."
        }
        return "Pay once, keep forever. Never renews."
    }

    private var monthlyTerms: String {
        if let days = store.trialDays(for: .monthlyPro) {
            return "\(days) days free, then \(price(.monthlyPro))/month. Cancel anytime."
        }
        return "Renews monthly. Cancel anytime."
    }

    // MARK: - Loading & failure

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(PaywallStyle.surface)
            .frame(height: 64)
            .overlay(ProgressView().tint(PaywallStyle.tertiary))
    }

    private var retryRow: some View {
        VStack(spacing: Spacing.xs) {
            Text("Couldn't load plans")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(PaywallStyle.primary)
            Text("Check your connection. Prices come from the App Store.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(PaywallStyle.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Haptics.shared.play(.light)
                Task { await store.loadProducts() }
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Brand.sky)
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.m)
        .background(PaywallStyle.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
