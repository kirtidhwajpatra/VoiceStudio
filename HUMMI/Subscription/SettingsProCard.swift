//
//  SettingsProCard.swift
//  HUMMI
//
//  Studio Pro in Settings — styled exactly like every other Settings
//  section (quiet ink card, eyebrow header), so it is findable without
//  shouting. This and the export button are the app's only two ways into
//  the paywall.
//   • Free: one row, "Studio Pro", opens the plans.
//   • Pro:  the plan and its renewal state, Manage Subscription (Apple's
//           own sheet) for Monthly, and Restore Purchases.
//

import StoreKit
import SwiftUI

struct SettingsProCard: View {
    @State private var showPaywall = false
    @State private var showManage = false
    @State private var restoreNote: String?

    private let store = SubscriptionManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("STUDIO PRO")
                .font(.footnote.weight(.semibold))
                .tracking(1.6)
                .foregroundStyle(Brand.ink.opacity(0.55))
                .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                if store.isProUser { proRows } else { freeRow }
            }
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Brand.ink.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Brand.ink.opacity(0.1), lineWidth: 1))

            if let restoreNote {
                Text(restoreNote)
                    .font(.dsCaption)
                    .foregroundStyle(Brand.ink.opacity(0.45))
                    .padding(.horizontal, Spacing.xs)
            }
        }
        .paywall(isPresented: $showPaywall)
        .manageSubscriptionsSheet(isPresented: $showManage)
        .onChange(of: showManage) { _, open in
            if !open { Task { await store.refreshEntitlements() } }
        }
    }

    // MARK: - Rows

    private var freeRow: some View {
        Button {
            Haptics.shared.play(.light)
            showPaywall = true
        } label: {
            row(icon: "sparkles", title: "Studio Pro", detail: "Save and share your takes") {
                chevron
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Shows the Studio Pro plans")
    }

    @ViewBuilder
    private var proRows: some View {
        row(icon: "checkmark.seal", title: "Studio Pro · \(planName)", detail: planDetail) {
            EmptyView()
        }
        if case .monthly = store.activePlan {
            divider
            Button { showManage = true } label: {
                row(icon: "creditcard", title: "Manage Subscription", detail: nil) { chevron }
            }
            .buttonStyle(.plain)
        }
        divider
        Button {
            Task {
                let result = await store.restorePurchases()
                restoreNote = result == .restored ? "Purchases are up to date." : nil
            }
        } label: {
            row(icon: "arrow.clockwise", title: store.isRestoring ? "Restoring…" : "Restore Purchases",
                detail: nil) { EmptyView() }
        }
        .buttonStyle(.plain)
        .disabled(store.isRestoring)
    }

    private func row(icon: String, title: String, detail: String?,
                     @ViewBuilder trailing: () -> some View) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.ink)
                .frame(width: 36, height: 36)
                .background(Brand.surface, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.ink)
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Brand.ink.opacity(0.5))
                }
            }
            Spacer(minLength: Spacing.s)
            trailing()
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .contentShape(Rectangle())
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Brand.ink.opacity(0.3))
    }

    private var divider: some View {
        Divider()
            .overlay(Brand.ink.opacity(0.08))
            .padding(.leading, Spacing.m + 36 + Spacing.s)
    }

    // MARK: - Copy

    private var planName: String {
        switch store.activePlan {
        case .lifetime: return "Lifetime"
        case .monthly: return "Monthly"
        case .none: return "Active"
        }
    }

    private var planDetail: String {
        switch store.activePlan {
        case .lifetime:
            return "Paid once · never renews"
        case .monthly(let renewsOn, let willRenew):
            guard let renewsOn else { return "Renews monthly" }
            let date = renewsOn.formatted(date: .abbreviated, time: .omitted)
            return willRenew ? "Renews \(date)" : "Ends \(date) · won't renew"
        case .none:
            return "Active on this Apple ID"
        }
    }
}
