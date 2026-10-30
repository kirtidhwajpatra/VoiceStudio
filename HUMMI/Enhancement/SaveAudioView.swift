//
//  SaveAudioView.swift
//  HUMMI
//
//  The save/share screen reached from the Result screen's "Save" action.
//  Shows the (editable) take name over its waveform, and exports the
//  enhanced render as audio or a share video.
//

import SwiftUI

struct SaveAudioView: View {
    @Bindable var viewModel: ResultViewModel
    @Binding var path: [AppRoute]
    /// Opens the "All recordings" library.
    var onOpenPlaylist: () -> Void = {}

    @FocusState private var nameFocused: Bool
    @State private var showPaywall = false
    @State private var pendingExport: PaywallExport?

    var body: some View {
        VStack(spacing: 0) {
            customTopBar

            // A capped top gap lifts the title clear of vertical centre.
            Spacer(minLength: Spacing.l).frame(maxHeight: 48)

            nameField
                .padding(.horizontal, Spacing.l)

            // The take's identity — what character + space made this sound.
            // Fills what used to be dead air with the story of the take.
            TakeIdentityRow(character: viewModel.selectedCharacter, space: viewModel.selectedSpace)
                .padding(.top, Spacing.m)
                .padding(.horizontal, Spacing.l)

            // Flexible gap: floats the player toward the screen's centre.
            Spacer(minLength: Spacing.l)

            VStack(spacing: Spacing.m) {
                GeometryReader { geometry in
                    WaveformView(
                        peaks: viewModel.peaks,
                        progress: viewModel.abPlayer.isPlaying ? nil : (viewModel.abPlayer.duration > 0 ? viewModel.abPlayer.currentTime / viewModel.abPlayer.duration : 0),
                        live: viewModel.abPlayer.isPlaying ? { viewModel.abPlayer.duration > 0 ? viewModel.abPlayer.currentTime / viewModel.abPlayer.duration : 0 } : nil,
                        style: .bars,
                        playedTint: Brand.accentText
                    )
                }
                .frame(height: 80)

                HStack(spacing: Spacing.xl) {
                    Text(timeString(viewModel.abPlayer.currentTime))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)

                    GlowIconButton(
                        icon: viewModel.abPlayer.isPlaying ? "pause.fill" : "play.fill",
                        label: viewModel.abPlayer.isPlaying ? "Pause" : "Play",
                        feel: .quiet) {
                        viewModel.abPlayer.togglePlayPause()
                    }

                    Text(timeString(viewModel.duration))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Spacing.l)

            Spacer(minLength: Spacing.xl)

            exportButtons
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: Spacing.contentMaxWidth)
        // Fill the whole screen so the opaque backdrop reaches every edge and
        // the Studio screen behind never peeks through at the bottom.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(screenBackground.ignoresSafeArea())
        .sheet(item: shareBinding) { item in
            ShareSheet(url: item.url)
                .presentationDetents([.medium, .large])
        }
        .paywall(isPresented: $showPaywall,
                 context: .export(pendingExport ?? .audio(format: exportFormatLabel)),
                 take: paywallTake,
                 onUnlocked: resumePendingExport,
                 onDeclined: handleDeclined)
        .onDisappear { viewModel.commitName() }
        .task {
            await viewModel.onAppear()
        }
    }

    /// Screen backdrop — a near-white (or near-black) plate that fills the
    /// whole screen, shared by the top bar so there is no seam.
    private var screenBackground: Color { Brand.canvas }

    // MARK: - Editable name

    private var nameField: some View {
        HStack(spacing: 3) {
            TextField("Recording", text: $viewModel.displayName)
                .font(.title2.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                // Hug the text so the caret sits right at the name's end.
                .fixedSize(horizontal: true, vertical: false)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .lineLimit(1)
                .focused($nameFocused)
                .accessibilityLabel("Recording name")
                .accessibilityHint("Tap to rename")

            // A blinking cursor at the end signals the title is a text
            // field. Hidden while focused, when the real caret takes over.
            if !nameFocused {
                BlinkingCaret()
            }
        }
    }

    private var exportButtons: some View {
        let locked = !SubscriptionManager.shared.isProUser
        return VStack(spacing: Spacing.s) {
            // One primary (lime) and one neutral secondary — never two
            // filled brand buttons side by side.
            GlowPillButton(
                title: "Save Audio", icon: "arrow.down.document",
                feel: .prominent,
                isBusy: viewModel.isExporting && viewModel.videoProgress == nil,
                busyTitle: "Exporting…") {
                export(.audio(format: exportFormatLabel))
            }
            .disabled(viewModel.isExporting)

            GlowPillButton(
                title: "Share as Video", icon: "play.rectangle",
                tint: GlowPillButton.secondaryTint, foreground: GlowPillButton.secondaryForeground,
                feel: .standard,
                isBusy: viewModel.isExporting && viewModel.videoProgress != nil,
                busyTitle: "Exporting Video", progress: viewModel.videoProgress) {
                export(.video)
            }
            .disabled(viewModel.isExporting)

            // One quiet line so the paywall is never a surprise. No badge.
            Text(locked ? "Saving and sharing are part of Studio Pro."
                        : "Your enhanced take, ready to send anywhere.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.xxs)
        }
        .animation(Motion.standard, value: viewModel.isExporting)
    }

    // MARK: - Export gate

    private var exportFormatLabel: String {
        let raw = UserDefaults.standard.string(forKey: "exportFormat") ?? ExportFormat.m4a.rawValue
        return raw == ExportFormat.wav.rawValue ? "WAV" : "M4A"
    }

    /// Free users meet the paywall here — at the moment they have a finished
    /// take worth keeping. Pro users export straight away.
    private func export(_ kind: PaywallExport) {
        guard SubscriptionManager.shared.isProUser else {
            pendingExport = kind
            showPaywall = true
            return
        }
        run(kind)
    }

    private func run(_ kind: PaywallExport) {
        Task {
            switch kind {
            case .audio: await viewModel.saveAudio()
            case .video: await viewModel.shareVideo()
            }
        }
    }

    /// After purchase: pick up exactly where the user left off.
    private func resumePendingExport() {
        guard let kind = pendingExport else { return }
        pendingExport = nil
        run(kind)
    }

    /// Closed without buying: no nagging, just reassurance the work is safe.
    private func handleDeclined() {
        pendingExport = nil
        ToastManager.shared.show(message: "Your take is still here. Export whenever you're ready.",
                                 icon: "checkmark.circle.fill")
    }

    private var paywallTake: PaywallTake {
        PaywallTake(name: viewModel.displayName, peaks: viewModel.peaks, player: viewModel.abPlayer)
    }

    private func timeString(_ time: TimeInterval) -> String {
        guard time.isFinite, !time.isNaN else { return "0:00" }
        let totalSeconds = max(Int(time.rounded()), 0)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private var shareBinding: Binding<ShareItem?> {
        Binding(get: { viewModel.shareItem }, set: { viewModel.shareItem = $0 })
    }

    private var customTopBar: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    _ = path.popLast()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                    .frame(width: 44, height: 44)
                    .background(Brand.surface)
                    .clipShape(Circle())
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            
            Spacer()
            
            Button {
                path.append(.library)
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                    .frame(width: 44, height: 44)
                    .background(Brand.surface)
                    .clipShape(Circle())
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(screenBackground)
    }
}

/// A text-cursor caret that fades on and off, marking the recording title
/// as editable. Holds steady when Reduce Motion is on.
private struct BlinkingCaret: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = true

    var body: some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .fill(Brand.limeDeep)
            .frame(width: 2.5, height: 22)
            .opacity(visible ? 1 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
            .accessibilityHidden(true)
    }
}
