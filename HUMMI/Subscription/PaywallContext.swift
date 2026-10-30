//
//  PaywallContext.swift
//  HUMMI
//
//  Why the paywall opened. Everything in HUMMI is free except exporting,
//  so the paywall almost always opens at the export step — the moment the
//  user has a finished take they want to keep. The context lets the
//  headline name that exact action, and lets the success screen resume it.
//

import Foundation

/// The export the user reached for.
enum PaywallExport: Equatable {
    /// Save the audio in a format ("M4A" or "WAV").
    case audio(format: String)
    /// Share the take as a video.
    case video
}

enum PaywallContext: Equatable {
    /// Opened from the PRO chip or Settings — no specific action.
    case general
    /// Opened by tapping an export button on the save screen.
    case export(PaywallExport)

    /// Small chip above the headline; nil for `.general`.
    var eyebrow: String? {
        switch self {
        case .general: return nil
        case .export(.audio(let format)): return "Saving \(format) is part of Pro"
        case .export(.video): return "Video sharing is part of Pro"
        }
    }

    var headline: String {
        switch self {
        case .general: return "Keep everything you make."
        case .export(.audio): return "Save your studio take."
        case .export(.video): return "Share your take as a video."
        }
    }

    /// The success screen's main button — resumes the blocked action.
    var successCTA: String {
        switch self {
        case .general: return "Start Creating"
        case .export(.audio): return "Save My Take"
        case .export(.video): return "Make My Video"
        }
    }
}
