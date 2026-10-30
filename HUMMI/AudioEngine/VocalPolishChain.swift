//
//  VocalPolishChain.swift
//  HUMMI
//
//  The "studio mic" base every Studio take now gets before any character
//  or space is applied. Until now the Studio path played the raw take
//  through only a 3-band EQ, saturation and reverb; the app's proper
//  vocal chain (high-pass, mud cut, de-esser, compression, presence,
//  air) existed but was never used outside the debug pipeline.
//
//  Order follows a standard vocal mix chain:
//    1. gain staging   — bring quiet phone takes to a working level so
//                        the compressors' thresholds actually engage
//    2. high-pass 80Hz — removes handling rumble and plosive thumps
//    3. corrective EQ  — a little body, cuts the 300 Hz mud and 500 Hz box
//                        that make phone mics sound boxy
//    4. de-esser       — tames harsh "s" before the top end is lifted
//    5. multiband comp — evens out loud and soft notes per band
//    6. presence + air — the clarity and sheen of a large-diaphragm
//                        condenser, kept gentle because characters add EQ
//    7. glue comp      — one gentle 2:1 pass so it sits like a record
//    8. output level   — consistent loudness with a −1 dBFS peak ceiling
//
//  Pure DSP, no ML: deterministic and fast. Every stage is toggleable.
//

import Foundation

nonisolated enum VocalPolishChain {
    /// Tuned for a solo vocal recorded on a phone mic.
    static var parameters: PresetParameters {
        var p = PresetParameters()
        p.normalizeTargetDB = -20          // gain-staging target
        p.normalizePeakCeilingDB = -3
        p.highPassFrequency = 80
        p.warmthGainDB = 0.5
        p.mudGainDB = -4
        p.boxGainDB = -2
        p.deEsserRatio = 6
        p.deEsserMarginDB = 4
        p.multibandRatio = 3
        p.presenceGainDB = 1
        p.airGainDB = 0.5
        p.glueThresholdDB = -22            // relative to the −20 working level
        p.glueRatio = 2
        return p
    }

    static func makeStages(parameters p: PresetParameters = parameters) -> [any ProcessingStage] {
        var output = p
        output.normalizeTargetDB = -16
        output.normalizePeakCeilingDB = -1
        return [
            LoudnessNormalizeStage(parameters: p),
            HighPassStage(parameters: p),
            EQStage(parameters: p),
            DeEsserStage(parameters: p),
            MultibandCompressorStage(parameters: p),
            PresenceAirStage(parameters: p),
            GlueCompressorStage(parameters: p),
            LoudnessNormalizeStage(parameters: output),
        ]
    }

    /// Runs the chain. Silent or empty input is returned unchanged.
    static func process(_ samples: [Float]) throws -> [Float] {
        guard !samples.isEmpty else { return samples }
        var output = samples
        for stage in makeStages() where stage.isEnabled {
            output = try stage.process(output)
        }
        return output
    }
}
