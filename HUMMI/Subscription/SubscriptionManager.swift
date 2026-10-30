//
//  SubscriptionManager.swift
//  HUMMI
//
//  StoreKit 2 subscription engine. Manages product loading, purchasing,
//  and entitlement verification for Voice Studio Pro. The single source
//  of truth for "is the user subscribed?" — every gate in the app reads
//  `SubscriptionManager.shared.isProUser`.
//
//  Every action returns a typed outcome (see PurchaseOutcome.swift) so the
//  paywall can show a distinct state for success, cancel, Ask to Buy,
//  failure and restore — never a single catch-all error string.
//
//  Product IDs must match your App Store Connect configuration.
//

import StoreKit
import SwiftUI

/// The product identifiers configured in App Store Connect.
enum SubscriptionProduct: String, CaseIterable {
    /// Must stay in sync with the products submitted in App Store Connect.
    case monthlyPro = "com.kirtidhwaj.voicestudio.pro.monthly"
    case lifetimePro = "com.kirtidhwaj.voicestudio.pro.lifetime"

    var isAutoRenewable: Bool {
        self == .monthlyPro
    }
}

@MainActor @Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    // MARK: - Public state

    /// True when any Pro entitlement is active.
    private(set) var isProUser = false

    /// Which plan the user owns, for the Pro state in Settings.
    private(set) var activePlan: ActivePlan = .none

    /// Loaded StoreKit products, keyed by our enum for fast lookup.
    private(set) var products: [SubscriptionProduct: Product] = [:]

    /// Whether the plans could be fetched. Drives the paywall's retry state.
    private(set) var loadState: ProductLoadState = .loading

    /// True while a purchase or restore is in flight.
    private(set) var isPurchasing = false
    private(set) var isRestoring = false

    /// Intro-offer (free trial) eligibility per product, checked on load.
    private(set) var introEligible: [SubscriptionProduct: Bool] = [:]

    // MARK: - Private

    @ObservationIgnored
    private nonisolated(unsafe) var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshEntitlements() }
    }

    deinit { transactionListener?.cancel() }

    // MARK: - Products

    func loadProducts() async {
        loadState = .loading
        do {
            let ids = SubscriptionProduct.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: Set(ids))
            for product in storeProducts {
                guard let sub = SubscriptionProduct(rawValue: product.id) else { continue }
                products[sub] = product
                if let info = product.subscription {
                    introEligible[sub] = await info.isEligibleForIntroOffer
                }
            }
            loadState = products.isEmpty ? .failed : .loaded
        } catch {
            loadState = .failed
            print("[SubscriptionManager] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ subscription: SubscriptionProduct) async -> PurchaseOutcome {
        guard !isPurchasing else { return .cancelled }
        guard let product = products[subscription] else {
            await loadProducts()
            return .failed(.unavailable)
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return .failed(.unverified)
                }
                await transaction.finish()
                await refreshEntitlements()
                return isProUser ? .success : .failed(.unverified)
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed(.generic)
            }
        } catch {
            if PurchaseFailure.isCancellation(error) { return .cancelled }
            print("[SubscriptionManager] Purchase error: \(error)")
            return .failed(.from(error))
        }
    }

    /// Restore purchases. StoreKit 2 syncs automatically, but an explicit
    /// button is required by App Review and builds trust — especially for
    /// Lifetime on an app with no account.
    @discardableResult
    func restorePurchases() async -> RestoreOutcome {
        guard !isRestoring else { return .cancelled }
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
        } catch {
            if PurchaseFailure.isCancellation(error) { return .cancelled }
            return .failed(.restoreFailed)
        }
        await refreshEntitlements()
        return isProUser ? .restored : .nothingFound
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var plan: ActivePlan = .none
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  let product = SubscriptionProduct(rawValue: transaction.productID) else { continue }

            switch product {
            case .lifetimePro:
                plan = .lifetime
            case .monthlyPro:
                // Lifetime wins if both exist.
                if plan != .lifetime {
                    plan = .monthly(renewsOn: transaction.expirationDate,
                                    willRenew: await willAutoRenew(product))
                }
            }
        }
        activePlan = plan
        isProUser = plan != .none
    }

    private func willAutoRenew(_ product: SubscriptionProduct) async -> Bool {
        guard let subscription = products[product]?.subscription,
              let statuses = try? await subscription.status,
              let status = statuses.first,
              case .verified(let info) = status.renewalInfo else { return true }
        return info.willAutoRenew
    }

    // MARK: - Transaction listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { @Sendable [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }

    // MARK: - Display helpers

    /// Prices are always supplied by StoreKit so they remain accurate for the
    /// customer's storefront, currency, taxes, and any current offer.
    func displayPrice(for product: SubscriptionProduct) -> String? {
        products[product]?.displayPrice
    }

    /// "7-day free trial" when the user is eligible for the Monthly intro
    /// offer, otherwise nil. Only shown when App Store Connect has one.
    func trialDescription(for product: SubscriptionProduct) -> String? {
        guard introEligible[product] == true,
              let offer = products[product]?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let period = offer.period
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "day"
        }
        return "\(period.value)-\(unit) free trial"
    }

    /// Free-trial length in days when the user is eligible, else nil.
    func trialDays(for product: SubscriptionProduct) -> Int? {
        guard introEligible[product] == true,
              let offer = products[product]?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let value = offer.period.value
        switch offer.period.unit {
        case .day: return value
        case .week: return value * 7
        case .month: return value * 30
        case .year: return value * 365
        @unknown default: return value
        }
    }

    /// How many months of Monthly the Lifetime price equals, for honest
    /// anchoring ("Same as 6 months of Monthly"). Nil until both load.
    var lifetimeBreakEvenMonths: Int? {
        guard let lifetime = products[.lifetimePro]?.price,
              let monthly = products[.monthlyPro]?.price,
              monthly > 0 else { return nil }
        let months = NSDecimalNumber(decimal: lifetime / monthly).doubleValue
        guard months.isFinite, months > 1 else { return nil }
        return Int(months.rounded(.up))
    }
}
