//
//  HeadphoneMonitor.swift
//  Voice Studio
//
//  Read-only observation of the current output route, so the UI can nudge
//  the user toward headphones only while they're actually on the speaker.
//  This never configures, activates or mutates the audio session — it only
//  reads `currentRoute` and listens for route-change notifications, so it
//  cannot affect capture or processing in any way.
//

import AVFoundation
import Observation

/// Tracks whether audio is currently heading to headphones (wired,
/// Bluetooth, USB or AirPlay) rather than the built-in speaker.
@MainActor
@Observable
final class HeadphoneMonitor {
    /// True while the active output route is a headphone-like device.
    private(set) var isConnected: Bool = false

    private let session = AVAudioSession.sharedInstance()
    // nonisolated(unsafe) so deinit can remove the observer; only ever
    // written from the main actor in init.
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    /// Output port types that put the mix in the listener's ears.
    private static let headphonePorts: Set<AVAudioSession.Port> = [
        .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE,
        .usbAudio, .airPlay,
    ]

    init() {
        refresh()
        observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Re-reads the current output route. Cheap and side-effect free.
    func refresh() {
        isConnected = session.currentRoute.outputs.contains {
            Self.headphonePorts.contains($0.portType)
        }
    }
}
