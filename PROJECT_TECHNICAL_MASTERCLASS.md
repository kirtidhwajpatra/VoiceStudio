# HUMMI (Voice Studio / StudioVocals) — Comprehensive Technical Masterclass

> **Document Purpose**: This document provides a complete, deep-dive technical blueprint of the HUMMI project. It covers system architecture, DSP math, Core ML integration, real-time audio graphs, SwiftUI design patterns, export pipelines, and App Store review strategies to prepare you for any technical interview, architecture review, or deep code examination.

---

## 1. Executive Summary & Core Value Proposition

* **Project Name**: HUMMI (Internal Repo Name: `HUMMI` / Product Name: **Voice Studio** or **StudioVocals**)
* **Target Concept**: "Adobe Podcast Enhance, specifically engineered for vocalists and singers on iOS."
* **System Requirements**: iOS 17.0+, macOS 14+ (for development), Xcode 15.0+, Swift 5.9+.
* **Core Technological Pillars**:
  1. **100% On-Device & Privacy-Centric**: Zero external API calls, zero cloud dependencies. Works completely in Airplane Mode.
  2. **Neural Audio Enhancement**: Core ML port of **DeepFilterNet3 (DFN3)** (~2M parameters, FP16 quantization) running locally on Apple Neural Engine (ANE).
  3. **Studio-Grade DSP Pipeline**: Custom C/Swift DSP algorithms for Pitch Tracking (YIN), Auto-Tune (PSOLA), Biquad EQ, Multiband & Glue Compression, De-Essing, Saturation, and Convolution Reverb.
  4. **Dual Audio Engine Strategy**: Instantaneous low-latency auditioning via `AVAudioEngine` node graph paired with sample-accurate 48 kHz mono Float32 offline rendering.
  5. **Modern Design System**: SwiftUI-only, MVVM + `@Observable`, custom Liquid Glass tokens, full WCAG AA contrast compliance, and custom video exporter (`AVAssetWriter`).

---

## 2. Architecture & System Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            UI LAYER (SwiftUI)                               │
│  [RecordView]    [StudioScreen]    [SaveAudioView]    [OnboardingScreens]   │
└──────────────────────┬──────────────────────────────────────────────────────┘
                       │ Observation (@Observable)
┌──────────────────────▼──────────────────────────────────────────────────────┐
│                         VIEW MODEL LAYER (MVVM)                             │
│     [RecordingViewModel]       [ResultViewModel]       [PlaybackViewModel]   │
└──────────────────────┬─────────────────────────┬────────────────────────────┘
                       │                         │
      Audition / Live  │                         │ Offline Render / Export
                       ▼                         ▼
┌──────────────────────────────────────┐ ┌────────────────────────────────────┐
│      REALTIME PREVIEW ENGINE         │ │     OFFLINE PROCESSING PIPELINE    │
│  AVAudioEngine Graph (Node-based)    │ │  16-Stage Processing Chain         │
│  - AVAudioPlayerNode                 │ │  - MLEnhanceStage (Core ML DFN3)   │
│  - AVAudioUnitTimePitch              │ │  - PitchCorrectionStage (PSOLA)    │
│  - AVAudioUnitEQ (3-band)            │ │  - Surgical EQ / De-Esser / Comp  │
│  - AVAudioUnitDistortion / Reverb    │ │  - Loudness Normalize (EBU R128)   │
└──────────────────────────────────────┘ └─────────────────┬──────────────────┘
                                                           │
                                                           ▼
                                         ┌────────────────────────────────────┐
                                         │            EXPORT ENGINE           │
                                         │  [AudioExporter] (WAV / AAC)       │
                                         │  [VideoExporter] (AVAssetWriter)  │
                                         └────────────────────────────────────┘
```

---

## 3. DeepFilterNet3 (DFN3) Core ML & DSP Preprocessing

### 3.1 Neural Model Overview
- **Model Bundle**: `DeepFilterNet3.mlpackage` (~2 MB footprint).
- **Execution Target**: Apple Neural Engine (ANE) & GPU (`computeUnits = .all`).
- **Precision**: Float16 (`mlprogram`) for optimal ANE throughput and low memory bandwidth usage.

### 3.2 Audio Specification & Preprocessing Contract
All audio inside HUMMI is standardized to **48,000 Hz, mono, Float32 PCM**.

```
Audio Input (48kHz Mono Float32)
   │
   ├──> 1. Pad trailing 960 zero samples (Delay Compensation)
   ├──> 2. Apply Vorbis Analysis Window (N=960, Hop H=480)
   ├──> 3. Compute Real FFT (rfft -> 481 complex bins, scaled by 1/960)
   │
   ├──> 4. Feature Extraction:
   │      ├──> ERB Log-Power (32 non-linear bands, α=0.99 exp-mean norm)
   │      └──> Complex Spectrum (First 96 bins, α=0.99 unit-power norm)
   │
   ├──> 5. Execute Core ML Model (DeepFilterNet3.mlpackage)
   │
   ├──> 6. Compute Synthesis iSTFT (Vorbis Window, Overlap-Add, scale x960)
   │
   └──> 7. Trim 480-sample algorithmic delay -> Enhanced Waveform Output
```

#### Mathematical Formulas:
1. **Vorbis Window Function**:
   $$w[n] = \sin\left(\frac{\pi}{2} \sin^2\left(\frac{\pi (n + 0.5)}{960}\right)\right), \quad n \in [0, 959]$$
   *Note*: The Vorbis window satisfies the Princen-Bradley condition: $w^2[n] + w^2[n + H] = 1$.

2. **STFT Spectrogram Analysis**:
   $$\text{spec}[k] = \frac{1}{960} \cdot \text{rfft}\left(w \cdot x_{\text{padded}}[k \cdot 480 : k \cdot 480 + 960]\right)$$

3. **ERB Log-Power Feature ($32$ bands)**:
   $$E[k, b] = 10 \cdot \log_{10}\left( \text{mean}(|\text{spec}[k, \text{bins of } b]|^2) + 10^{-10} \right)$$
   Stateful exponential mean update ($\alpha = 0.99$):
   $$s[b] \leftarrow (1 - \alpha) \cdot E[k, b] + \alpha \cdot s[b]$$
   $$\text{feat\_erb}[k, b] = \frac{E[k, b] - s[b]}{40}$$

4. **Complex Spectrum Feature ($96$ bins)**:
   $$s[f] \leftarrow (1 - \alpha) \cdot |\text{spec}[k, f]| + \alpha \cdot s[f]$$
   $$\text{feat\_spec}[k, f] = \frac{\text{spec}[k, f]}{\sqrt{s[f]}}$$

### 3.3 Adaptive Floor & Voiced Rescue
To eliminate "robotic" metallic artifacts or phase smearing on sustained vocal notes:
- **Adaptive Floor (`AdaptiveFloor.swift`)**: Blends the neural enhanced signal with the raw recording based on signal energy.
- **Voiced Detector (`VoicedDetector.swift`)**: Detects voiced speech/singing intervals using autocorrelation and energy thresholds to protect soft vocal consonants.

---

## 4. The 16-Stage DSP Enhancement Pipeline

Processing is executed in strict sequence by `ProcessingPipeline.swift`:

| Order | Stage | File | Purpose & Algorithm |
|---|---|---|---|
| **1** | `MLEnhanceStage` | `MLEnhanceStage.swift` | Executes Core ML DeepFilterNet3 inference and dry/wet suppression blending. |
| **2** | `DFNRestorationStage` | `DFNRestorationStage.swift` | Alternative adaptive-floor restoration stage (selectable in A/B test). |
| **3** | `PitchCorrectionStage` | `PitchCorrectionStage.swift` | Pitch tracking via YIN algorithm + pitch correction via PSOLA (Pitch-Synchronous Overlap-Add). |
| **4** | `HighPassStage` | `HighPassStage.swift` | 2nd-order Biquad Butterworth High-Pass Filter ($f_c = 55\text{ Hz} - 750\text{ Hz}$) removing mic rumble. |
| **5** | `EQStage` | `EQStage.swift` | 3-band parametric EQ (Low Shelf, Mid Peaking with Q, High Shelf Air). |
| **6** | `CompressorStage` | `CompressorStage.swift` | Dynamic range peak compressor with attack, release, threshold, and ratio settings. |
| **7** | `DeEsserStage` | `DeEsserStage.swift` | Dynamic notch filter targeting vocal sibilance ($4\text{ kHz} - 9\text{ kHz}$). |
| **8** | `MultibandCompressorStage` | `MultibandCompressorStage.swift` | 3-band crossover network compressing low, mid, and high bands independently. |
| **9** | `SaturationStage` | `SaturationStage.swift` | Soft-clipping harmonic warmth generator using $y = \tanh(\text{drive} \cdot x)$. |
| **10** | `PresenceAirStage` | `PresenceAirStage.swift` | High-frequency shelf boost (> 10 kHz) adding broadcast sparkle. |
| **11** | `EchoStage` | `EchoStage.swift` | Delay line with feedback and wet/dry mix for spatial echo effects. |
| **12** | `ConvolutionReverbStage` | `ConvolutionReverbStage.swift` | Impulse response (IR) convolution reverb for realistic studio space simulation. |
| **13** | `ReverbStage` | `ReverbStage.swift` | Algorithmic reverb alternative. |
| **14** | `GlueCompressorStage` | `GlueCompressorStage.swift` | Low-ratio, slow-attack master compressor for unifying vocal dynamics. |
| **15** | `LoudnessNormalizeStage` | `LoudnessNormalizeStage.swift` | EBU R128 / ITU-R BS.1770 LUFS measurement + peak limiter targeting standard LUFS. |
| **16** | `VoiceShapeStage` | `VoiceShapeStage.swift` | Formant/pitch/speed transformation stage for special voice characters. |

---

## 5. Dual Engine Strategy: Auditioning vs Render

### 5.1 Realtime Preview Engine (`RealtimePreviewEngine.swift`)
- Built on Apple's `AVAudioEngine` node graph.
- Integrates `AVAudioPlayerNode`, `AVAudioUnitTimePitch`, `AVAudioUnitEQ`, `AVAudioUnitDistortion`, and `AVAudioUnitReverb`.
- **Zero-Latency Parameter Updates**: Modifying EQ, reverb decay, or saturation instantly updates node parameters without re-rendering the full audio buffer.
- **Debounced Autotune Preview**: Since PSOLA pitch correction is a custom C/Swift algorithm (not a built-in `AVAudioUnit`), slider movements trigger a debounced background task that re-renders pitch correction and hot-swaps the `studioBuffer` seamlessly without stopping playback.

### 5.2 Offline Renderer (`ProcessingPipeline.swift` & `AudioExporter.swift`)
- Operates on Float32 arrays completely off the main thread (`nonisolated` / `Task.detached`).
- Applies all 16 DSP stages with sample accuracy.
- Normalizes output loudness to target LUFS before writing final WAV or encoding AAC.

---

## 6. Presets & Filter Library System

### 6.1 Studio Presets (`StudioPreset.swift`)
HUMMI offers 13 distinct studio presets, categorized into **Character** and **Space** filters:
- **Default (Balanced)**: Gentle tuning (0.35), light room, natural warmth.
- **Studio**: Flagship radio-ready vocal with dense dynamics and presence.
- **Hard Tune**: 100% PSOLA snap for pop autotune effects.
- **Warm**: Cozy low-shelf body (220 Hz +9dB) with rolled-off top.
- **Bright**: Crisp sparkle with big air shelf (+10dB > 10kHz).
- **Dream (Airy)**: Ethereal wash with long delay (260ms) and large hall reverb.
- **Stadium (Concert)**: Massive hall reverb with short slapback echo (150ms).
- **Canyon**: Long regenerating delay (340ms, 50% feedback).
- **Tape (Vintage)**: Saturated tape character with harmonic drive ($y = \tanh$).
- **AM Radio / Telephone / Megaphone**: Aggressive bandpass filtering ($280\text{Hz} - 2500\text{Hz}$) with heavy distortion drive.
- **Deep**: Rich sub-bass body with subdued highs.

---

## 7. Export Engine & Social Media Video Generation

### 7.1 Audio Exporter (`AudioExporter.swift`)
- Exports uncompressed **WAV** (48kHz 24-bit/32-bit Float) or **AAC** (M4A) compressed at 256kbps/320kbps with full ID3 metadata and album artwork tags.

### 7.2 Video Exporter (`VideoExporter.swift`)
- **Size**: ~29 KB of custom rendering logic.
- **Core Technology**: Uses `AVAssetWriter`, `AVAssetWriterInput`, and `AVAssetWriterInputPixelBufferAdaptor` to write hardware-accelerated H.264/HEVC MP4 video.
- **Features**:
  - Render modes: Vertical Portrait (1080x1920 for Instagram Reels / TikTok) & Square (1080x1080).
  - Real-time Visuals: Animated audio spectrum bars, voice glow aura, gradient backgrounds, lyric/text overlays, and custom album artwork backdrop.
  - High performance: Off-screen rendering using Core Graphics / Core Image into CoreVideo pixel buffers (`CVPixelBuffer`).

---

## 8. Design System & UI Architecture

### 8.1 UI Tech Stack
- **Framework**: SwiftUI (iOS 17+ minimum target).
- **State Management**: Swift Concurrency (`async/await`) + Observation (`@Observable`).
- **Third-Party UI**: **0 dependencies**. 100% first-party native components.

### 8.2 Design Tokens (`HUMMI/DesignSystem/`)
- **Spacing**: Rigid token scale: `4, 8, 12, 16, 24, 32, 48` (`xxs` to `xxl`).
- **Corner Radii**: `.continuous` standard: Card (`12pt`), Sheet (`16pt`), CTA (`22pt`).
- **Typography**: SF Pro / GT Walsheim display tracking, Dynamic Type scaling up to `.accessibility3`.
- **Color Palette**: Dark-canvas native (`#090909`), Surface 1 (`#141414`), Surface 2 (`#1C1C1C`), Accent Color (Electric Indigo).
- **Materials**: `.ultraThinMaterial` for floating controls, `.thinMaterial` for chips/sheets. Elevation via material contrast and hairline borders (no heavy drop shadows).
- **Motion & Haptics**: Standard spring (`response: 0.35, dampingFraction: 0.82`), custom sensory feedback (`.impact(.light)`, `.success`, `.selection`).

### 8.3 Onboarding & Mic Permission Pattern
- **Explainer-First Strategy**: iOS permission prompts must be preceded by a custom explainer card that communicates value *before* triggering the system permission alert (`AVAudioApplication.requestRecordPermission`).
- **Graceful Fallback**: If the user denies microphone permission, the app never locks up; it offers an "Open Settings" button and graceful navigation paths.

---

## 9. App Store Review & Privacy Compliance

- **Guideline 5.1.1(i) & 5.1.2(i) (Data Use & AI)**:
  - App Store Review clarification in `AppReview-Reply.md`.
  - Proves 100% on-device AI processing via bundled Core ML (`DeepFilterNet3.mlpackage`).
  - `PrivacyInfo.xcprivacy` declares `NSPrivacyTracking = false` with 0 collected data types.
- **Guideline 5.1.1(iv) (Permission Coercion)**:
  - Button text on mic permission screen uses non-coercive label ("Continue" instead of "Enable Microphone"). System alert handles explicit consent.

---

## 10. Technical Interview & Architectural Q&A Cheat Sheet

### Q1: How does HUMMI run a neural noise suppression model on iOS without draining battery or dropping frames?
> **Answer**: HUMMI converts DeepFilterNet3 into a quantized **Float16 Core ML model** (`DeepFilterNet3.mlpackage`, ~2M parameters). It executes via Core ML configured with `.all` compute units, allowing iOS to delegate model execution to the **Apple Neural Engine (ANE)**. This achieves sub-10ms inference per audio chunk with minimal CPU usage and negligible thermal impact.

### Q2: Why use a dual-engine approach (`RealtimePreviewEngine` vs `ProcessingPipeline`)?
> **Answer**: `AVAudioEngine` node graphs allow instantaneous real-time manipulation of EQ, reverb, and pitch-rate parameters via hardware AU units without re-rendering audio files. However, offline DSP (like 16-stage serial compression, PSOLA pitch snapping, and Core ML STFT inference) requires exact sample-by-sample array math. Using `RealtimePreviewEngine` for auditioning gives zero UI lag, while `ProcessingPipeline` ensures sample-accurate, studio-grade offline rendering.

### Q3: How is DeepFilterNet3 STFT preprocessing implemented in Swift?
> **Answer**: We implemented a Swift STFT layer (`VorbisSTFT.swift` & `RealFFT.swift`) that matches the reference Python implementation (`libdf`) to $\le 1\text{e-}5$ accuracy. It uses an FFT size of 960 (20ms) with a 480 (10ms) hop size, shaped by a Vorbis window $w[n] = \sin(\frac{\pi}{2} \sin^2(\frac{\pi(n+0.5)}{960}))$. It extracts 32 ERB log-power features and 96 complex spectrum features using stateful exponential mean normalization ($\alpha = 0.99$).

### Q4: How does pitch tracking and autotune work in HUMMI?
> **Answer**: Pitch tracking uses the **YIN algorithm** (`PitchTracker.swift`) to detect fundamental frequency ($F_0$) and voiced probability per audio frame. `KeyEstimator.swift` computes a chromagram to estimate the song's musical key. Pitch correction then applies **PSOLA (Pitch-Synchronous Overlap-Add)** to shift pitch periods toward scale degrees without altering vocal speed or introducing phase distortion.

### Q5: How do you guarantee audio session safety and prevent background crashes?
> **Answer**: Audio session setup is isolated inside `AudioSessionManager.swift`. We explicitly switch categories (`AVAudioSession.Category.playAndRecord` for recording vs `.playback` for auditioning/export) and handle OS interruptions (`AVAudioSession.interruptionNotification`) cleanly by pausing engines and saving state.

---

*Document compiled for HUMMI (Voice Studio / StudioVocals) technical mastery.*
