//
//  PaywallView.swift
//  HUMMI
//
//  Studio Pro: the purchase flow in one full-screen cover. Everything is
//  free except exporting, so this opens from the save screen with the
//  user's own take as its one visual.
//
//  Layout, top to bottom: close · headline · the take · three benefits ·
//  two plans · one lime CTA · legal. Flat canvas, no glow, no shadows, no
//  entrance animation. Lime marks only the CTA, the selected plan, the
//  checks and the waveform's progress. (Apple HIG: one prominent button
//  per view; NN/g: animate feedback, not decoration.)
//
//  States: browsing → purchasing → success | one alternative-plan offer
//  after a cancel | pending | failed. See HUMMI_DESIGN_SYSTEM.md.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    var context: PaywallContext = .general
    /// The user's take, when opened from the save screen.
    var take: PaywallTake? = nil

    @Environment(\.dismiss) private var dismiss

    private enum Phase: Equatable {
        case browsing, purchasing, success
        case outcome(PaywallOutcomeCard.Kind)
    }

    @State private var phase: Phase = .browsing
    @State private var selected: SubscriptionProduct = .lifetimePro
    /// The alternative-plan offer is shown at most once per visit.
    @State private var offeredAlternative = false

    private let store = SubscriptionManager.shared

    var body: some View {
        ZStack {
            PaywallStyle.canvas.ignoresSafeArea()
            if phase == .success || (store.isProUser && phase == .browsing) {
                PaywallSuccessView(plan: store.activePlan, context: context,
                                   celebrate: phase == .success) { dismiss() }
                    .overlay(alignment: .topTrailing) { closeButton.padding(.horizontal, Spacing.s) }
                    .transition(.opacity)
            } else {
                browsing
            }
        }
        .overlay(alignment: .bottom) { outcomeOverlay }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(phase == .purchasing)
        .onAppear {
            if store.loadState == .failed { Task { await store.loadProducts() } }
        }
    }

    // MARK: - Browsing

    private var browsing: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    header
                    if let take { PaywallTakeCard(take: take) } else { PaywallStillPreview() }
                    PaywallBenefitList()
                    PaywallPlanPicker(selected: $selected, store: store)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.m)
            }
            .disabled(phase == .purchasing)

            ctaDock
        }
        .frame(maxWidth: Spacing.contentMaxWidth)
        .frame(maxWidth: .infinity)
    }

    private var closeButton: some View {
        Button {
            Haptics.shared.play(.light)
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PaywallStyle.secondary)
                .frame(width: 30, height: 30)
                .background(PaywallStyle.fill, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(phase == .purchasing)
        .accessibilityLabel("Close")
    }

    private var header: some View {
        // Eyebrow and close share one row, so the headline starts higher
        // and the whole paywall fits without scrolling on most iPhones.
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text("STUDIO PRO")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(PaywallStyle.tertiary)
                Spacer()
                closeButton.padding(.trailing, -Spacing.s)
            }
            Text(context.headline)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PaywallStyle.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - CTA dock

    private var ctaDock: some View {
        VStack(spacing: Spacing.s) {
            Button { Task { await buy() } } label: {
                HStack(spacing: Spacing.xs) {
                    if phase == .purchasing { ProgressView().tint(Brand.forest).controlSize(.small) }
                    Text(ctaTitle)
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Brand.forest)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Brand.lime, in: Capsule())
            }
            .buttonStyle(PressScaleStyle())
            .disabled(phase == .purchasing || store.loadState != .loaded)
            .opacity(store.loadState == .loaded ? 1 : 0.4)

            if let reassurance {
                Text(reassurance)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(PaywallStyle.primary)
            }

            PaywallLegalFooter(selected: selected) { Task { await restore() } }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.s)
        .padding(.bottom, Spacing.xs)
        .background(PaywallStyle.canvas)
        .overlay(alignment: .top) { Rectangle().fill(PaywallStyle.hairline).frame(height: 0.5) }
    }

    private var trialDays: Int? {
        selected == .monthlyPro ? store.trialDays(for: .monthlyPro) : nil
    }

    private var ctaTitle: String {
        if phase == .purchasing { return "Opening App Store…" }
        if trialDays != nil { return "Start Free Trial" }
        return selected == .lifetimePro ? "Unlock Lifetime" : "Continue with Monthly"
    }

    /// Only the trial needs a line here ("nothing is charged today");
    /// every other term is already on the plan row.
    private var reassurance: String? {
        trialDays != nil ? "No payment due today" : nil
    }

    // MARK: - Outcome overlay

    @ViewBuilder
    private var outcomeOverlay: some View {
        if case .outcome(let kind) = phase {
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.4).ignoresSafeArea()
                    .onTapGesture { phase = .browsing }
                PaywallOutcomeCard(kind: kind, onRetry: {
                    if case .alternative(let alt) = kind { selected = alt.product }
                    Task { await buy() }
                }, onDismiss: { phase = .browsing })
                .transition(.move(edge: .bottom))
            }
        }
    }

    // MARK: - Actions

    private func buy() async {
        guard phase != .purchasing else { return }
        Haptics.shared.play(.medium)
        phase = .purchasing
        switch await store.purchase(selected) {
        case .success:
            phase = .success
        case .cancelled:
            if !offeredAlternative,
               let alt = PaywallOutcomeCard.PlanAlternative.offer(after: selected, store: store) {
                offeredAlternative = true
                phase = .outcome(.alternative(alt))
            } else {
                phase = .browsing
            }
        case .pending:
            phase = .outcome(.pending)
        case .failed(let failure):
            phase = .outcome(.failed(failure)); Haptics.shared.notify(.error)
        }
    }

    private func restore() async {
        Haptics.shared.play(.light)
        switch await store.restorePurchases() {
        case .restored: phase = .success
        case .nothingFound: phase = .outcome(.nothingToRestore)
        case .cancelled: break
        case .failed(let failure): phase = .outcome(.failed(failure))
        }
    }
}

// MARK: - Presentation

extension View {
    /// Presents the Studio Pro flow. `onUnlocked` runs after the cover
    /// closes with Pro active (e.g. resume the export); `onDeclined` runs
    /// when it closes without a purchase.
    func paywall(isPresented: Binding<Bool>,
                 context: PaywallContext = .general,
                 take: PaywallTake? = nil,
                 onUnlocked: (() -> Void)? = nil,
                 onDeclined: (() -> Void)? = nil) -> some View {
        fullScreenCover(isPresented: isPresented, onDismiss: {
            if SubscriptionManager.shared.isProUser { onUnlocked?() } else { onDeclined?() }
        }) {
            PaywallView(context: context, take: take)
        }
    }
}

#if DEBUG
#Preview("General") { PaywallView() }
#Preview("From WAV export") { PaywallView(context: .export(.audio(format: "WAV"))) }
#endif
