//
//  SplashScreen.swift
//  HUMMI
//
//  The launch moment, built from the app icon: the blue cradle draws in
//  like a stand being set up, the coral mic springs into it, the sparkle
//  twinkles once. About 1.3 seconds;
//  tap to skip. Reduce Motion shows the finished mark with a short fade.
//  Follows the device appearance (studio navy in dark, off-white in light).
//  Purely presentational; calls `onFinish` exactly once.
//

import SwiftUI

struct SplashScreen: View {
    /// Called once when the intro completes or the user taps to skip.
    var onFinish: () -> Void

    private let reduceMotionPreference: Bool
    @Environment(\.accessibilityReduceMotion) private var envReduceMotion
    private var reduceMotion: Bool { reduceMotionPreference || envReduceMotion }

    @State private var cradle: CGFloat = 0
    @State private var mic: CGFloat = 0
    @State private var sparkle: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var finished = false

    init(reduceMotion: Bool = false, onFinish: @escaping () -> Void) {
        self.reduceMotionPreference = reduceMotion
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            Brand.canvas.ignoresSafeArea()

            HummiMark(size: 140, micScale: mic, cradleProgress: cradle, sparkle: sparkle)
                .opacity(opacity)
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .accessibilityElement()
        .accessibilityLabel(Text(AppBranding.name))
        .accessibilityAddTraits(.isImage)
        .task { await run() }
    }

    private func run() async {
        if reduceMotion {
            cradle = 1; mic = 1; sparkle = 1
            withAnimation(.easeOut(duration: 0.25)) { opacity = 1 }
            try? await sleep(1.0)
            finish()
            return
        }

        opacity = 1
        // 1. The stand draws in.
        withAnimation(.easeOut(duration: 0.4)) { cradle = 1 }
        try? await sleep(0.22)
        // 2. The mic springs into it.
        withAnimation(.spring(response: 0.42, dampingFraction: 0.55)) { mic = 1 }
        try? await sleep(0.32)
        // 3. One twinkle, with a soft tick.
        Haptics.shared.play(.soft)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { sparkle = 1 }
        try? await sleep(0.75)
        finish()
    }

    private func sleep(_ seconds: Double) async throws {
        try await Task.sleep(for: .seconds(seconds))
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }
}

#Preview {
    SplashScreen(onFinish: {})
}
