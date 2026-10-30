//
//  PaywallTakeCard.swift
//  HUMMI
//
//  The export paywall's one visual: the user's own take, with play and
//  an Original / Studio switch so they hear exactly what they'd keep.
//  Deliberately flat — one surface, one hairline, no glow or shadow. The
//  only colour is the waveform's played portion while in Studio mode,
//  which doubles as the progress indicator.
//

import SwiftUI

/// The take the paywall should show and play.
struct PaywallTake {
    let name: String
    let peaks: [Float]
    let player: RealtimePreviewEngine
}

struct PaywallTakeCard: View {
    let take: PaywallTake

    private var player: RealtimePreviewEngine { take.player }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(take.name.isEmpty ? "Your take" : take.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(PaywallStyle.primary)
                    .lineLimit(1)
                Spacer()
                Text(timeString(player.duration))
                    .font(.system(size: 13, design: .rounded).monospacedDigit())
                    .foregroundStyle(PaywallStyle.secondary)
            }

            WaveformView(
                peaks: take.peaks,
                tint: PaywallStyle.hairline,
                progress: player.isPlaying ? nil : fraction,
                live: player.isPlaying ? { fraction } : nil,
                style: .bars,
                playedTint: player.listeningToProcessed ? Brand.sky : PaywallStyle.secondary)
                .frame(height: 44)

            HStack(spacing: Spacing.s) {
                Button {
                    Haptics.shared.play(.light)
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PaywallStyle.primary)
                        .frame(width: 40, height: 40)
                        .background(PaywallStyle.fill, in: Circle())
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(player.isPlaying ? "Pause your take" : "Play your take")

                Picker("Version", selection: Binding(
                    get: { player.listeningToProcessed },
                    set: { player.listeningToProcessed = $0 })) {
                    Text("Original").tag(false)
                    Text("Studio").tag(true)
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: player.listeningToProcessed)
            }
        }
        .padding(Spacing.m)
        .background(PaywallStyle.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear { player.listeningToProcessed = true }
        .onDisappear { if player.isPlaying { player.togglePlayPause() } }
    }

    private var fraction: Double {
        player.duration > 0 ? player.currentTime / player.duration : 0
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = max(Int(t.rounded()), 0)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// When the paywall opens without a take (from Settings): a still image
/// of a studio waveform, nothing moving.
struct PaywallStillPreview: View {
    private static let peaks: [Float] = (0..<40).map { i in
        let x = Float(i)
        return 0.35 + 0.55 * abs(sin(x * 0.42)) * (0.7 + 0.3 * abs(cos(x * 0.9)))
    }

    var body: some View {
        WaveformView(peaks: Self.peaks, tint: PaywallStyle.hairline, progress: 1, live: nil,
                     style: .bars, playedTint: Brand.lime.opacity(0.85))
            .frame(height: 44)
            .padding(Spacing.m)
            .background(PaywallStyle.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityHidden(true)
    }
}
