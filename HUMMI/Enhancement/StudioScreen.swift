//
//  StudioScreen.swift
//  HUMMI
//
//  The Aurora Orb studio: a near-black canvas where the 12 character
//  orbs and 8 space tiles ARE the colour. Everything else — toolbar,
//  A/B toggle, playback — is white glass. Scoped dark; the rest of the
//  app stays light.
//

import SwiftUI

struct StudioScreen: View {
    let viewModel: ResultViewModel
    let onDiscard: () -> Void
    let onSaved: () -> Void

    @State private var showPanel = false
    @State private var showDiscardAlert = false
    @State private var scrubFocus: Double? = nil
    @State private var tooltip: String?
    @State private var tooltipDismiss: Task<Void, Never>?
    @State private var headphones = HeadphoneMonitor()
    @AppStorage("studioCoachmarkCharacter") private var dismissedCharacterCoachmark = false
    @AppStorage("studioCoachmarkSwipe") private var dismissedSpaceCoachmark = false
    @AppStorage("studioCoachmarkPanel") private var dismissedPanelCoachmark = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            StudioTheme.canvas.ignoresSafeArea()
            StudioTheme.vignette.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    playbackSection
                    if !headphones.isConnected {
                        headphoneHint
                            .padding(.top, Spacing.s)
                            .transition(.opacity)
                    }
                    characterSection
                    spaceSection
                    panelRow
                }
                .animation(reduceMotion ? .none : Motion.standard,
                           value: headphones.isConnected)
                // Clears the floating tab pill so the panel row stays reachable.
                .padding(.bottom, Spacing.xxl * 2.5)
                // Centre the controls on wide (iPad / landscape) screens; the
                // dark canvas behind still fills edge to edge.
                .frame(maxWidth: Spacing.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 60)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .top) {
            HStack {
                // Secondary action: plain text, no fill. Save is the one
                // filled button on this screen.
                Button {
                    Haptics.shared.play(.light)
                    showDiscardAlert = true
                } label: {
                    Text("Discard")
                        .font(.body.weight(.medium))
                        .foregroundStyle(StudioTheme.textSecondary)
                        .padding(.horizontal, Spacing.xs)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                GlowPillButton(title: "Save", feel: .prominent,
                               compact: true, isBusy: viewModel.isSavingStudio,
                               busyTitle: "Saving…") {
                    saveStudio()
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.s)
            .frame(maxWidth: Spacing.contentMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog("Discard this studio session?",
                            isPresented: $showDiscardAlert, titleVisibility: .visible) {
            Button("Discard Session", role: .destructive) {
                Haptics.shared.notify(.warning)
                onDiscard()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your recording stays in your library. Only the voice and space choices here are lost.")
        }
        .sheet(isPresented: $showPanel) {
            StudioPanelSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .overlay(alignment: .bottom) {
            if let tooltip {
                coachPill(tooltip)
                    .padding(.bottom, Spacing.xl)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.filterTapCount)
        .task { await viewModel.prepareRealtimePreview() }
        .onDisappear { viewModel.tearDown() }
    }

    // MARK: - Playback

    private var playbackSection: some View {
        VStack(spacing: Spacing.s) {
            abToggle.padding(.top, Spacing.m)
            StudioResultLine(report: viewModel.polishReport)
            waveform
                .frame(maxWidth: 300)
                .frame(height: 150)
            playbackControls
        }
        .padding(.horizontal, Spacing.l)
    }

    /// One-line nudge toward headphones, sitting between the playback
    /// controls and the character row. Brand lime on an adaptive capsule so
    /// it reads on both the light and dark studio canvas; it removes itself
    /// the moment headphones are actually plugged in.
    private var headphoneHint: some View {
        // A quiet hint, not a banner: secondary text, no fill or border.
        Label("Use headphones for the truest studio sound", systemImage: "headphones")
            .font(.footnote)
            .foregroundStyle(StudioTheme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, Spacing.l)
        .accessibilityElement(children: .combine)
    }

    private var abToggle: some View {
        HStack(spacing: Spacing.xxs) {
            abSegment("Original", isOn: !viewModel.abPlayer.listeningToProcessed) {
                viewModel.abPlayer.listeningToProcessed = false
            }
            abSegment("Studio", isOn: viewModel.abPlayer.listeningToProcessed) {
                viewModel.abPlayer.listeningToProcessed = true
            }
        }
        .padding(Spacing.xxs)
        .background(.ultraThinMaterial, in: Capsule())
        // Compact: the toggle is a switch, not a banner.
        .frame(maxWidth: 240)
        .animation(Motion.micro, value: viewModel.abPlayer.listeningToProcessed)
    }

    private func abSegment(_ label: String, isOn: Bool, select: @escaping () -> Void) -> some View {
        Button(action: select) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isOn ? .black : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background {
                    if isOn {
                        Capsule().fill(.white)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var waveform: some View {
        GeometryReader { geometry in
            WaveformView(
                peaks: viewModel.peaks,
                tint: .primary.opacity(0.22),
                progress: viewModel.abPlayer.isPlaying ? nil : (viewModel.abPlayer.duration > 0 ? viewModel.abPlayer.currentTime / viewModel.abPlayer.duration : 0),
                live: viewModel.abPlayer.isPlaying ? { viewModel.abPlayer.duration > 0 ? viewModel.abPlayer.currentTime / viewModel.abPlayer.duration : 0 } : nil,
                style: .bars,
                playedTint: viewModel.abPlayer.listeningToProcessed ? Brand.limeDeep : .primary,
                focusFraction: scrubFocus
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.abPlayer.setScrubbing(true)
                        let fraction = min(max(value.location.x / geometry.size.width, 0), 1)
                        viewModel.abPlayer.currentTime = fraction * viewModel.abPlayer.duration
                        scrubFocus = fraction
                    }
                    .onEnded { _ in
                        viewModel.abPlayer.setScrubbing(false)
                        scrubFocus = nil
                    }
            )
        }
    }

    private var playbackControls: some View {
        HStack(spacing: Spacing.xl) {
            Text(timeString(viewModel.abPlayer.currentTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(StudioTheme.textSecondary)
            GlowIconButton(
                icon: viewModel.abPlayer.isPlaying ? "pause.fill" : "play.fill",
                label: viewModel.abPlayer.isPlaying ? "Pause" : "Play",
                feel: .quiet) {
                viewModel.abPlayer.togglePlayPause()
            }
            Text(timeString(viewModel.abPlayer.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(StudioTheme.textSecondary)
        }
        .padding(.bottom, Spacing.m)
    }

    // MARK: - Filter rows

    private var characterSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionHeader("Character", caption: viewModel.selectedCharacter.tagline)
            if !dismissedCharacterCoachmark {
                coachPill("Tap any character to try a voice").padding(.horizontal, Spacing.l)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Spacing.s) {
                    ForEach(Array(FilterLibrary.characters.enumerated()), id: \.element.id) { index, filter in
                        CharacterCard(filter: filter,
                                      isActive: viewModel.selectedCharacterID == filter.id,
                                      index: index) {
                            dismissedCharacterCoachmark = true
                            viewModel.selectCharacter(filter.id)
                        } onLongPress: {
                            showTooltip("\(filter.name) · \(filter.tagline)")
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
        .padding(.top, Spacing.l)
    }

    private var spaceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionHeader(
                "Space",
                caption: "\(viewModel.selectedSpace.name) · \(String(format: "%.1f", viewModel.reverbDecay))s decay")
            if dismissedCharacterCoachmark, viewModel.filterTapCount >= 2, !dismissedSpaceCoachmark {
                coachPill("Combine with a space").padding(.horizontal, Spacing.l)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.m) {
                    ForEach(Array(FilterLibrary.spaces.enumerated()), id: \.element.id) { index, filter in
                        SpaceTile(filter: filter,
                                  isActive: viewModel.selectedSpaceID == filter.id,
                                  index: index) {
                            dismissedSpaceCoachmark = true
                            viewModel.selectSpace(filter.id)
                        } onLongPress: {
                            showTooltip("\(filter.name) · \(filter.tagline)")
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.s)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
        .padding(.top, Spacing.l)
    }

    private func sectionHeader(_ title: String, caption: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(StudioTheme.textPrimary)
            Spacer()
            Text(caption)
                .font(.caption)
                .foregroundStyle(StudioTheme.textSecondary)
                .lineLimit(1)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: caption)
        }
        .padding(.horizontal, Spacing.l)
    }

    // MARK: - Studio Panel row

    private var panelRow: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button {
                dismissedPanelCoachmark = true
                showPanel = true
            } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                        .background(.primary.opacity(0.06), in: Circle())
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack(spacing: Spacing.xs) {
                            Text("Studio Panel").font(.headline).foregroundStyle(.primary)
                            if viewModel.isCustomized {
                                Circle()
                                    .fill(Brand.limeDeep)
                                    .frame(width: 7, height: 7)
                                    .accessibilityLabel("Custom adjustments active")
                            }
                        }
                        Text(viewModel.isCustomized ? "Custom adjustments active" : "Advanced controls · Voice, EQ, Reverb")
                            .font(.callout)
                            .foregroundStyle(StudioTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(StudioTheme.textTertiary)
                }
                .padding(Spacing.m)
                .background(Brand.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            if !dismissedPanelCoachmark, dismissedSpaceCoachmark {
                coachPill("Advanced controls here")
            }
        }
        .padding(.horizontal, Spacing.l)
        .padding(.top, Spacing.l)
    }

    // MARK: - Chrome

    private func coachPill(_ text: String) -> some View {
        // A one-time hint as plain secondary text — no floating chip.
        Label(text, systemImage: "hand.tap")
            .font(.footnote)
            .foregroundStyle(StudioTheme.textSecondary)
    }

    /// Renders the final take with the shared top status strip — the same
    /// "Preparing… / ready" toast the export screen uses — as the bridge
    /// between Studio and the export screen. The strip carries the wait, so
    /// we only advance once the render is done and the take is clean.
    private func saveStudio() {
        guard !viewModel.isSavingStudio else { return }
        Haptics.shared.play(.light)
        Task {
            ToastManager.shared.show(message: "Preparing your take…", isProcessing: true)
            let ok = await viewModel.renderFinalStudioVersion()
            if ok {
                ToastManager.shared.celebrate("Studio take saved")
                onSaved()
            } else {
                ToastManager.shared.hide()
            }
        }
    }

    private func showTooltip(_ text: String) {
        tooltipDismiss?.cancel()
        withAnimation(.easeInOut(duration: 0.15)) { tooltip = text }
        tooltipDismiss = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) { tooltip = nil }
        }
    }

    private func timeString(_ time: Double) -> String {
        let total = Int(time.rounded(.down))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
