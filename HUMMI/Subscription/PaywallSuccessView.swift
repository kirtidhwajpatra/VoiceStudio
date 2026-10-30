//
//  PaywallSuccessView.swift
//  HUMMI
//
//  After payment: one clear confirmation, then straight back to work.
//  A lime check settles in once with a success haptic — the only motion,
//  because it is feedback (NN/g: animate feedback, not decoration). A
//  plain list says what's now unlocked, one line confirms the plan, and a
//  single button resumes the export the user asked for. Also used, calmer
//  and without the haptic, as the "already Pro" screen.
//

import SwiftUI

struct PaywallSuccessView: View {
    let plan: ActivePlan
    let context: PaywallContext
    /// False for the "already Pro" variant.
    var celebrate = true
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmed = false

    private let unlocks = [
        "Save every take in M4A or WAV",
        "Share takes as video",
        "Unlimited exports"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Spacer()

            ZStack {
                Circle().fill(Brand.lime)
                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Brand.forest)
            }
            .frame(width: 64, height: 64)
            .scaleEffect(confirmed || reduceMotion ? 1 : 0.6)
            .opacity(confirmed || reduceMotion ? 1 : 0)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(celebrate ? "You're all set." : "You already have Pro.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PaywallStyle.primary)
                Text(summary)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(PaywallStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(unlocks, id: \.self) { item in
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Brand.sky)
                            .frame(width: 18)
                        Text(item)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(PaywallStyle.primary)
                    }
                }
            }
            .accessibilityElement(children: .combine)

            Spacer()

            Button {
                Haptics.shared.play(.light)
                onDone()
            } label: {
                Text(celebrate ? context.successCTA : "Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Brand.forest)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Brand.lime, in: Capsule())
            }
            .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, Spacing.l)
        .padding(.bottom, Spacing.m)
        .frame(maxWidth: Spacing.contentMaxWidth)
        .frame(maxWidth: .infinity)
        .onAppear {
            guard celebrate else { confirmed = true; return }
            Haptics.shared.notify(.success)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { confirmed = true }
        }
    }

    private var summary: String {
        switch plan {
        case .lifetime:
            return "Studio Pro Lifetime. Paid once, never renews."
        case .monthly(let renewsOn, let willRenew):
            guard let renewsOn else { return "Studio Pro Monthly. Manage it anytime in Settings." }
            let date = renewsOn.formatted(date: .abbreviated, time: .omitted)
            return willRenew ? "Studio Pro Monthly. Renews \(date); cancel anytime."
                             : "Studio Pro Monthly. Active until \(date)."
        case .none:
            return "Studio Pro is active on this Apple ID."
        }
    }
}

#if DEBUG
#Preview("Success · Lifetime") {
    PaywallSuccessView(plan: .lifetime, context: .export(.audio(format: "WAV"))) {}
        .background(Brand.night)
        .preferredColorScheme(.dark)
}

#Preview("Already Pro · Monthly") {
    PaywallSuccessView(plan: .monthly(renewsOn: .now.addingTimeInterval(86_400 * 21), willRenew: true),
                       context: .general, celebrate: false) {}
        .background(Brand.night)
        .preferredColorScheme(.dark)
}
#endif
