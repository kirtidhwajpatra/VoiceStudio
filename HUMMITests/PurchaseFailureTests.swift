//
//  PurchaseFailureTests.swift
//  HUMMITests
//
//  The purchase flow's copy depends on mapping StoreKit errors correctly:
//  a cancel must stay silent, and offline must say no charge was made.
//

import Foundation
import StoreKit
import Testing
@testable import HUMMI

struct PurchaseFailureTests {
    @Test func userCancelIsNotAnError() {
        #expect(PurchaseFailure.isCancellation(StoreKitError.userCancelled))
        #expect(!PurchaseFailure.isCancellation(StoreKitError.unknown))
    }

    @Test func networkErrorMapsToOffline() {
        let error = StoreKitError.networkError(URLError(.notConnectedToInternet))
        #expect(PurchaseFailure.from(error) == .offline)
    }

    @Test func purchaseNotAllowedIsNotRetryable() {
        let failure = PurchaseFailure.from(Product.PurchaseError.purchaseNotAllowed)
        #expect(failure == .notAllowed)
        #expect(!failure.isRetryable)
    }

    @Test func unknownErrorsFallBackToGenericRetry() {
        struct Boom: Error {}
        let failure = PurchaseFailure.from(Boom())
        #expect(failure == .generic)
        #expect(failure.isRetryable)
    }
}
