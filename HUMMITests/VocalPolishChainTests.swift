//
//  VocalPolishChainTests.swift
//  HUMMITests
//
//  The studio-mic polish runs on every Studio take, so it must never
//  change the take's length, clip, emit NaNs, or blow up silence.
//

import Foundation
import Testing
@testable import HUMMI

struct VocalPolishChainTests {
    /// A quiet, vocal-like test signal: 220 Hz + harmonics with a slow
    /// swell, plus 40 Hz rumble that the high-pass should remove.
    private func quietTake(seconds: Double = 2) -> [Float] {
        (0..<Int(seconds * 48_000)).map { n in
            let t = Double(n) / 48_000
            let swell = 0.5 + 0.5 * sin(2 * .pi * 0.5 * t)
            let voice = sin(2 * .pi * 220 * t) + 0.4 * sin(2 * .pi * 440 * t) + 0.2 * sin(2 * .pi * 660 * t)
            let rumble = 0.3 * sin(2 * .pi * 40 * t)
            return Float(0.03 * (swell * voice + rumble))
        }
    }

    @Test func keepsLengthAndStaysFinite() throws {
        let input = quietTake()
        let output = try VocalPolishChain.process(input)
        #expect(output.count == input.count)
        #expect(output.allSatisfy { $0.isFinite })
    }

    @Test func peaksStayBelowCeiling() throws {
        let output = try VocalPolishChain.process(quietTake())
        let peak = output.map(abs).max() ?? 0
        let ceiling = Float(pow(10, -1.0 / 20)) + 1e-3  // −1 dBFS
        #expect(peak <= ceiling)
    }

    @Test func quietTakeIsBroughtUp() throws {
        let input = quietTake()
        let output = try VocalPolishChain.process(input)
        let rms = { (x: [Float]) in sqrt(x.reduce(0) { $0 + $1 * $1 } / Float(x.count)) }
        #expect(rms(output) > rms(input))
    }

    @Test func silenceStaysSilent() throws {
        let output = try VocalPolishChain.process([Float](repeating: 0, count: 48_000))
        #expect(output.allSatisfy { $0 == 0 })
    }

    @Test func everyStageIsToggleable() {
        let stages = VocalPolishChain.makeStages()
        #expect(stages.count == 8)
        #expect(stages.allSatisfy { $0.isEnabled })
    }
}
