//
//  PaywallOutcomeCard.swift
//  HUMMI
//
//  The calm card that rises over the paywall when a purchase doesn't
//  simply succeed: a failure (with retry when it makes sense), Ask to Buy
//  waiting for approval, or a restore result. One shape for all of them,
//  so the user learns it once. Copy always says whether money moved and
//  what to do next. A cancelled App Store sheet never shows this — backing
//  out is not an error.
//

import SwiftUI

struct PaywallOutcomeCard: View {
    enum Kind: Equatable {
        case failed(PurchaseFailure)
        case pending
        case nothingToRestore
        /// Shown once after the user backs out of the App Store sheet: the
        /// other plan, as a genuine alternative. Apple allows one such
        /// offer; looping or re-showing it is rejected.
        case alternative(PlanAlternative)
    }

    struct PlanAlternative: Equatable {
        let product: SubscriptionProduct
        let title: String
        let message: String
        let cta: String
    }

    let kind: Kind
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(iconColor)
                .padding(.top, Spacing.xs)

            VStack(spacing: Spacing.xxs) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(PaywallStyle.primary)
                Text(message)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(PaywallStyle.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.xxs) {
                if let retryTitle {
                    Button(action: onRetry) {
                        Text(retryTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Brand.forest)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Brand.lime, in: Capsule())
                    }
                    .buttonStyle(PressScaleStyle())
                }
                Button(action: onDismiss) {
                    Text(dismissTitle)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(PaywallStyle.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.l)
        .background(Color(hex: 0x141B2E),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(PaywallStyle.hairline, lineWidth: 0.5))
        .padding(.horizontal, Spacing.s)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Copy

    private var icon: String {
        switch kind {
        case .failed(let f) where f == .offline: return "wifi.slash"
        case .failed: return "exclamationmark.arrow.circlepath"
        case .pending: return "hourglass"
        case .nothingToRestore: return "magnifyingglass"
        case .alternative(let a): return a.product == .lifetimePro ? "infinity" : "calendar"
        }
    }

    /// Lime for neutral states; a soft amber for failures. Never red —
    /// red belongs to the record control alone.
    private var iconColor: Color {
        if case .failed = kind { return PaywallStyle.caution }
        return Brand.sky
    }

    private var title: String {
        switch kind {
        case .failed(let f): return f.title
        case .pending: return "Waiting for approval"
        case .nothingToRestore: return "No purchase found"
        case .alternative(let a): return a.title
        }
    }

    private var message: String {
        switch kind {
        case .failed(let f): return f.message
        case .pending:
            return "Your request was sent. Pro unlocks automatically as soon as it's approved — you don't need to stay on this screen."
        case .nothingToRestore:
            return "There's no Studio Pro purchase on this Apple ID. If you bought it with a different Apple ID, sign in with that one in Settings and restore again."
        case .alternative(let a): return a.message
        }
    }

    private var retryTitle: String? {
        switch kind {
        case .failed(let f): return f.isRetryable ? "Try Again" : nil
        case .pending: return nil
        case .nothingToRestore: return nil
        case .alternative(let a): return a.cta
        }
    }

    private var dismissTitle: String {
        switch kind {
        case .pending: return "Got It"
        case .nothingToRestore: return "OK"
        case .failed: return "Not Now"
        case .alternative: return "Maybe Later"
        }
    }
}

extension PaywallOutcomeCard.PlanAlternative {
    /// The other plan, framed as a genuine alternative — not pressure.
    @MainActor
    static func offer(after product: SubscriptionProduct, store: SubscriptionManager) -> Self? {
        switch product {
        case .lifetimePro:
            guard let price = store.displayPrice(for: .monthlyPro) else { return nil }
            if let days = store.trialDays(for: .monthlyPro) {
                return Self(product: .monthlyPro, title: "Not ready to pay once?",
                             message: "Try Monthly free for \(days) days, then \(price)/month. Cancel anytime in Settings.",
                             cta: "Start Free Trial")
            }
            return Self(product: .monthlyPro, title: "Not ready to pay once?",
                         message: "Start with Monthly at \(price)/month and cancel anytime in Settings.",
                         cta: "Switch to Monthly")
        case .monthlyPro:
            guard let price = store.displayPrice(for: .lifetimePro) else { return nil }
            return Self(product: .lifetimePro, title: "Rather skip the subscription?",
                         message: "Lifetime is \(price), paid once. It never renews and restores on every device.",
                         cta: "Get Lifetime Instead")
        }
    }
}

#if DEBUG
#Preview("Outcome states") {
    ScrollView {
        VStack(spacing: 24) {
            PaywallOutcomeCard(kind: .failed(.generic), onRetry: {}, onDismiss: {})
            PaywallOutcomeCard(kind: .failed(.offline), onRetry: {}, onDismiss: {})
            PaywallOutcomeCard(kind: .pending, onRetry: {}, onDismiss: {})
            PaywallOutcomeCard(kind: .nothingToRestore, onRetry: {}, onDismiss: {})
            PaywallOutcomeCard(kind: .alternative(.init(product: .monthlyPro, title: "Not ready to pay once?", message: "Start with Monthly for $4.99. Cancel anytime in Settings.", cta: "Switch to Monthly")), onRetry: {}, onDismiss: {})
        }
        .padding(.vertical, 24)
    }
    .background(Brand.night)
    .preferredColorScheme(.dark)
}
#endif
