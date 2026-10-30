//
//  SubscriptionProductTests.swift
//  HUMMITests
//

import Testing
@testable import HUMMI

/// Product IDs are part of the App Store contract. A mismatch makes the
/// paywall look available while StoreKit cannot load or purchase anything.
struct SubscriptionProductTests {
    @Test func productIdentifiersMatchAppStoreConfiguration() {
        #expect(SubscriptionProduct.monthlyPro.rawValue ==
            "com.kirtidhwaj.voicestudio.pro.monthly")
        #expect(SubscriptionProduct.lifetimePro.rawValue ==
            "com.kirtidhwaj.voicestudio.pro.lifetime")
    }

    @Test func onlyMonthlyProductRenews() {
        #expect(SubscriptionProduct.monthlyPro.isAutoRenewable)
        #expect(!SubscriptionProduct.lifetimePro.isAutoRenewable)
    }
}
