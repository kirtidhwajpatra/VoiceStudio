//
//  PolishReport.swift
//  HUMMI
//
//  Measures what the studio-mic polish did to one take, so Studio can
//  show the singer a real, take-specific result ("20% steadier ·
//  Clarity +3 dB") instead of a generic "Enhanced!". Every
//  number is measured on their audio; nothing is shown that didn't happen.
//
//  The comparison is made at equal loudness, so "clarity" means tonal
//  balance, not just "louder".
//

import Accelerate
import Foundation

nonisolated struct PolishReport: Equatable, Sendable {
    /// How much smaller the take's loudness range became, 0…1.
    let steadierFraction: Double
    /// 2–5 kHz presence gained relative to the whole take, in dB.
    let clarityGainDB: Double

    /// Only the changes big enough to hear, worded for the UI.
    var highlights: [String] {
        var out: [String] = []
        if steadierFraction >= 0.05 { out.append("\(Int((steadierFraction * 100).rounded()))% steadier") }
        if clarityGainDB >= 1 { out.append(String(format: "Clarity +%.0f dB", clarityGainDB)) }
        return out
    }

    static func measure(before raw: [Float], after polished: [Float]) -> PolishReport? {
        guard raw.count > 48_000, raw.count == polished.count else { return nil }
        // Match loudness first so the tonal comparison is fair.
        let gain = Float((rms(raw) / max(rms(polished), 1e-9)))
        let after = vDSP.multiply(gain, polished)

        let lraBefore = loudnessRange(raw), lraAfter = loudnessRange(after)
        let steadier = lraBefore > 1 ? max(0, (lraBefore - lraAfter) / lraBefore) : 0
        let clarity = db(presenceEnergy(after) / energy(after)) - db(presenceEnergy(raw) / energy(raw))
        return PolishReport(steadierFraction: steadier, clarityGainDB: clarity)
    }

    // MARK: - Measurements

    private static func energy(_ x: [Float]) -> Double { Double(vDSP.meanSquare(x)) }
    private static func rms(_ x: [Float]) -> Double { energy(x).squareRoot() }
    private static func db(_ v: Double) -> Double { 10 * log10(max(v, 1e-12)) }

    /// 2–5 kHz content: the difference a strong 3.2 kHz peak filter makes
    /// is proportional to the energy already in that band.
    private static func presenceEnergy(_ x: [Float]) -> Double {
        let boosted = Biquad.peak(frequency: 3_200, gainDB: 12, q: 0.9).apply(x)
        return energy(vDSP.subtract(boosted, x))
    }

    /// Spread between loud and soft passages: 95th − 10th percentile of
    /// 400 ms block loudness, ignoring silence.
    private static func loudnessRange(_ x: [Float]) -> Double {
        let block = 19_200, hop = 9_600
        var levels: [Double] = []
        var i = 0
        while i + block <= x.count {
            levels.append(db(Double(vDSP.meanSquare(x[i..<i + block]))))
            i += hop
        }
        let voiced = levels.filter { $0 > -50 }.sorted()
        guard voiced.count > 4 else { return 0 }
        return voiced[Int(Double(voiced.count - 1) * 0.95)] - voiced[Int(Double(voiced.count - 1) * 0.10)]
    }
}
