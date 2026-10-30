//
//  ToastManager.swift
//  HUMMI
//
//  Central manager for app-wide status messages, plus the reward moment:
//  `celebrate(_:)` shows the toast with the logo's sparkle bursting and
//  one success haptic. Use it only for things the singer achieved — a
//  take recorded, a studio take saved, an export ready — so it keeps
//  meaning something.
//

import SwiftUI
import UIKit

@Observable
final class ToastManager {
    static let shared = ToastManager()

    var isShowing = false
    var message: String = ""
    var icon: String? = nil
    var isProcessing = false
    /// True while the current toast is a reward; drives the sparkle burst.
    var isCelebration = false
    /// Bumped on every celebration so the burst replays even when two
    /// rewards land back to back.
    var celebrationID = 0

    private var hideTask: Task<Void, Never>?

    private init() {}

    func show(message: String, icon: String? = nil, isProcessing: Bool = false, duration: TimeInterval = 3.0) {
        present(message: message, icon: icon, isProcessing: isProcessing, celebrate: false, duration: duration)
    }

    /// The reward: sparkle burst + success haptic + message.
    func celebrate(_ message: String, duration: TimeInterval = 2.6) {
        present(message: message, icon: nil, isProcessing: false, celebrate: true, duration: duration)
    }

    private func present(message: String, icon: String?, isProcessing: Bool, celebrate: Bool, duration: TimeInterval) {
        Task { @MainActor in
            self.message = message
            self.icon = icon
            self.isProcessing = isProcessing
            self.isCelebration = celebrate
            if celebrate {
                self.celebrationID += 1
                Haptics.shared.notify(.success)
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                self.isShowing = true
            }

            hideTask?.cancel()
            // Only auto-dismiss if it's not a continuous processing state.
            if !isProcessing {
                hideTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    hide()
                }
            }
        }
    }

    @MainActor
    func hide() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            self.isShowing = false
        }
    }
}
