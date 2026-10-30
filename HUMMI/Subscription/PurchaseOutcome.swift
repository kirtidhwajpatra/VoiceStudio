//
//  PurchaseOutcome.swift
//  HUMMI
//
//  Typed results for every step of the purchase flow, so the paywall can
//  show a distinct, calm state for each one instead of a single error
//  string. Copy lives here so the tone stays consistent: no blame, say
//  whether money moved, offer the next step.
//

import StoreKit

/// What happened when the user tried to buy.
enum PurchaseOutcome: Equatable {
    /// Verified and finished — Pro is unlocked.
    case success
    /// The user closed the App Store sheet. Handled silently.
    case cancelled
    /// Ask to Buy / parental approval — not unlocked yet.
    case pending
    /// Something went wrong; carries user-facing copy.
    case failed(PurchaseFailure)
}

/// What happened when the user tapped Restore.
enum RestoreOutcome: Equatable {
    case restored
    case nothingFound
    case cancelled
    case failed(PurchaseFailure)
}

/// Whether the plans could be fetched from the App Store.
enum ProductLoadState: Equatable {
    case loading
    case loaded
    case failed
}

/// The plan the user currently owns.
enum ActivePlan: Equatable {
    case none
    case lifetime
    /// `renewsOn` is the current period's end; `willRenew` is false once
    /// the user has turned auto-renew off.
    case monthly(renewsOn: Date?, willRenew: Bool)
}

/// A purchase failure, already translated into human copy.
struct PurchaseFailure: Equatable {
    let title: String
    let message: String
    /// Whether a plain "Try again" makes sense for this failure.
    let isRetryable: Bool

    static let offline = PurchaseFailure(
        title: "You're offline",
        message: "Connect to the internet and try again. No charge was made.",
        isRetryable: true)

    static let notAllowed = PurchaseFailure(
        title: "Purchases are turned off",
        message: "In-app purchases are restricted on this device. Check Screen Time settings.",
        isRetryable: false)

    static let unavailable = PurchaseFailure(
        title: "Plans aren't ready yet",
        message: "We couldn't reach the App Store. Give it a moment and try again.",
        isRetryable: true)

    static let unverified = PurchaseFailure(
        title: "We couldn't confirm that purchase",
        message: "Apple didn't verify the transaction, so nothing was unlocked. Try Restore, or try again.",
        isRetryable: true)

    static let generic = PurchaseFailure(
        title: "That didn't go through",
        message: "No charge was made. Want to try again?",
        isRetryable: true)

    static let restoreFailed = PurchaseFailure(
        title: "Restore didn't finish",
        message: "We couldn't reach the App Store. Check your connection and try again.",
        isRetryable: true)

    /// Maps StoreKit's thrown errors onto the copy above.
    static func from(_ error: Error) -> PurchaseFailure {
        if let storeError = error as? StoreKitError {
            switch storeError {
            case .networkError: return .offline
            case .notAvailableInStorefront: return .unavailable
            case .notEntitled: return .unverified
            default: return .generic
            }
        }
        if let purchaseError = error as? Product.PurchaseError {
            switch purchaseError {
            case .purchaseNotAllowed: return .notAllowed
            case .productUnavailable: return .unavailable
            default: return .generic
            }
        }
        return .generic
    }

    /// True when StoreKit's error just means the user backed out.
    static func isCancellation(_ error: Error) -> Bool {
        if let storeError = error as? StoreKitError, case .userCancelled = storeError { return true }
        return false
    }
}
