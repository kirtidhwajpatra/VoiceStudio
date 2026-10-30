# HUMMI Design System

A research-backed, cohesive system for HUMMI — the app where a singer records
one take and one tap makes it sound studio-recorded. This document captures the
system, the reasoning behind it, and the research it is grounded in. It sits
alongside `BrandGuidelines.md` (the palette law) and the token files in
`Foundations/`.

---

## 1. Positioning & research

HUMMI competes with Voloco, BandLab, Dolby On, Smule, Moises, and Adobe Podcast
Enhance. Research into that category (2024–25) surfaced a consistent playbook:

| Pattern | Who does it | HUMMI's take |
|---|---|---|
| **One dominant hero accent, near-neutral everything else** | Linear, Arc, Adobe Podcast, Things | Lime is the one accent. The "5–10% lime" law. |
| **A dramatic before/after moment** | Adobe Podcast (A/B slider), Smule | A/B toggle in Studio; a live before/after proof on the paywall and onboarding. |
| **Named presets in a horizontal carousel** | Voloco, BandLab | Character orbs + space tiles, swiped horizontally. |
| **A tactile, breathing record control** | Dolby On, GarageBand | The lime record orb + Aurora that reacts to voice. |
| **Custom duotone/line iconography for brand actions** | Captions, premium creative apps | The `HummiIcon` "Rounded Stroke" family. |
| **Explicit, branded processing state** | Moises, Dolby On | `GlowPillButton` busy state narrates the render. |

**The differentiator:** nearly every competitor is neon-on-black. HUMMI's warm
off-white canvas + electric lime is distinctive in the category — so the system
leans into *restraint on a light canvas*, not another dark neon skin.

**Sources:** competitor scan + paywall/HIG synthesis in the research brief
(Voloco, BandLab, Smule, CapCut, Captions App Store/Wikipedia listings; Dolby
On, Adobe Podcast Enhance, Moises product patterns; Apple HIG In-App Purchase;
RevenueCat paywall guidance).

---

## 2. Foundations (tokens)

All in `Foundations/`. Views never hardcode values; they reference tokens.

- **Color** — `Brand.swift`. `lime → limeDeep` gradient (the one hero), `forest`
  (glyphs on lime), `ink` (text on canvas), `canvas` (off-white / forest-black).
  Record-red is reserved for the record control only.
- **Type** — `Typography.swift`. SF Pro Rounded, Dynamic Type driven. Weight
  carries hierarchy, not a sprawl of sizes.
- **Spacing** — `Spacing.swift`. `4 · 8 · 12 · 16 · 24 · 32 · 48`.
- **Radius** — `Radius.swift`. Always `.continuous`. `12` cards, `16` sheets, `22` CTA.
- **Motion** — `Motion.swift`. House spring for state, interactive for gestures,
  linear only for determinate progress; Reduce Motion → crossfade.
- **Haptics** — `Haptics.swift` + `Haptic` vocabulary. One event = one feedback.

---

## 3. Iconography — the "Rounded Stroke" family (`HummiIcon`)

Custom, code-drawn glyphs on a **24×24 grid, ~2pt stroke, fully rounded caps &
joins** — one visual voice that themes perfectly in light and forest-black dark.

- **When to use HummiIcon:** brand-defining glyphs — mic, waveform, sparkle
  (enhance), room (space), export, play/pause, folder, gear, script.
- **When to keep SF Symbols:** system affordances (share sheet, chevrons,
  close) where the platform glyph is expected.
- **Treatments:** `line(color)` for inactive/secondary · `active` (lime-gradient
  stroke) · `filled` (lime-gradient fill) for the one primary/selected mark.
- **Rule:** never two `filled` HummiIcons competing in one view.

## 4. Filter artwork — the data was always there

`FilterLibrary` defines an `OrbPalette` (core/mid/rim/glow + highlight material:
soft / gloss / metallic, optional grain) for each of the 12 characters, and a
`TilePalette` (gradient stops + glow + angled) for each of the 8 spaces. The
cards now render that data:

- **`OrbView`** — a lit sphere per character: radial body offset toward a
  seeded "sun", a material-specific specular highlight, a luminous rim, and
  grain where the palette asks for it. A row reads as twelve distinct worlds.
- **`SpaceEmblem`** — a source dot with reverberation rings whose count and
  spread grow with the room's decay (dry booth = 1 tight ring, cathedral = 4
  wide ones). One geometry, one colour: bigger room, more reverb.

Selection in both wraps the art in the brand lime ring and turns its light up.

## 5. Illustration motifs

Code-drawn (SwiftUI `Canvas`/`Shape`) so they theme across modes and never
pixelate: **mic**, **waveform**, **enhance sparkle**, **room/space**. They share
the `HummiIcon` 2pt rounded-stroke language, so icons and illustration feel like
one family. (`MicIllustration` is the existing empty-state piece; new work
routes through `HummiIcon` glyphs and the filter art.)

## 6. Components

- **`GlowPillButton` / `GlowIconButton`** — the gel capsule system. One primary
  lime pill per screen; inverted (forest fill / lime glyph) for secondary;
  quiet ink chrome for recede. Busy state narrates work.
- **`OrbView` / `SpaceEmblem`** — filter artwork (above).
- **`HummiIcon`** — the icon family (above).
- **`WaveformView`** — bars & line, playhead-aware; the before/after proof.
- **`AuroraBackground` / `VoiceGlowBars`** — the living home canvas.

## 7. Paywall principles (applied in `PaywallView`)

Grounded in Apple HIG (In-App Purchase) + RevenueCat paywall consensus:

- On-brand forest canvas + one lime aura — not an arbitrary black.
- A **live before/after proof** at the top (product doing its job) instead of a
  dead gap.
- **Two clear plan cards**, the recommended one (Lifetime) **preselected** and
  badged "BEST VALUE"; honest per-period framing.
- Benefit-led copy (what you unlock), not a feature wall.
- One primary CTA; Restore / Terms / Privacy always visible and de-emphasized.
- **Compliance:** auto-renew disclosure, price via StoreKit, Restore, Terms,
  Privacy — always present.
- Premium, not scammy: whitespace, honest pricing, easy dismiss, no fake urgency.

### Purchase flow — free to make, Pro to keep

**Model:** recording, Studio, every character and space are free. The only
gate is **export** (Save Audio / Share as Video) on the save screen.

| Step | What the user sees | File |
|---|---|---|
| Before | One quiet line under the export buttons: "Saving and sharing are part of Studio Pro." No badge, no lock icons, no Home upsell | `SaveAudioView` |
| Paywall | Context headline ("Your studio take is ready to save") → **their own take** with Original ↔ Studio playback → 3-row "what Pro adds" checklist + "what stays free" → Lifetime / Monthly cards (Lifetime preselected, anchored "same as N months") → vertical "How your free trial works" timeline (only if eligible) → sticky CTA + "No payment due now" (trial) | `PaywallView`, `PaywallTakeCard`, `PaywallBenefitList`, `PaywallPlanPicker`, `TrialTimeline` |
| Purchasing | CTA reads "Opening the App Store…"; close, scroll and swipe-dismiss locked | `PaywallView` |
| Backed out | **One** alternative plan offer (Lifetime ↔ Monthly), then silence | `PaywallOutcomeCard.PlanAlternative` |
| Ask to Buy | "Waiting for approval" — unlocks automatically later | `PaywallOutcomeCard` |
| Failed | Amber card, "No charge was made", Try Again if retryable | `PaywallOutcomeCard`, `PurchaseFailure` |
| Plans won't load | Skeleton → retry card; CTA disabled | `PaywallPlanPicker` |
| Restore | Restored → success; nothing found → Apple ID explanation | `PaywallView` |
| Success | One lime check settles in with a success haptic, plain unlock list, plan line, **"Save My Take" resumes the exact export** | `PaywallSuccessView`, `SaveAudioView.resumePendingExport` |
| Closed without buying | Toast: "Your take is still here. Export whenever you're ready." No re-prompt | `SaveAudioView.handleDeclined` |
| Already Pro | Calm "You're already Pro"; Settings shows plan, renewal, Manage Subscription, Restore | `PaywallSuccessView(celebrate: false)`, `SettingsProCard` |

**Evidence behind each decision**

| Decision | Evidence |
|---|---|
| Gate the outcome (export), keep creation free | RevenueCat SOSA 2025: hard-paywall apps convert downloads→paid at 12.11% median vs 2.18% freemium; median 14-day revenue ~8× higher. Gating only the export keeps the free creative loop while asking at the moment of value. [RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2025/) |
| Ask right after the user made something | 80–90% of trials start on Day 0; first impressions decide. [RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2025/) |
| Hero = the user's own take | Endowment/IKEA effect; Strava Premium Preview case (preview with the user's own data). [growth.design](https://growth.design/case-studies) |
| "How your free trial works" timeline | Blinkist: +23% trial conversions, fewer complaints. [growth.design](https://growth.design/case-studies) |
| No trial toggle | Apple bans trial toggles outright. [Superwall](https://superwall.com/blog/external-checkout-a-b-testing-and-trial-toggles-confirmed-apples-rules-for-ios) |
| One offer after a cancelled purchase, never looped | Apple: one tasteful transaction-abandon offer is allowed; nagging is rejected. [Superwall](https://superwall.com/blog/external-checkout-a-b-testing-and-trial-toggles-confirmed-apples-rules-for-ios) |
| Lifetime offered and anchored honestly | 35%+ of apps mix subscriptions with one-time/lifetime purchases. [RevenueCat](https://www.revenuecat.com/state-of-subscription-apps-2025/) |
| Full price, period, Restore, Terms, Privacy on screen; visible close; no fake urgency or fake reviews | [App Review Guidelines 3.1.1 / 3.1.2](https://developer.apple.com/app-store/review/guidelines/) |

**Not shipped on purpose:** star ratings, "loved by N singers" and
testimonials. HUMMI has no verified numbers yet, and invented social proof
breaks App Review's misleading-claims rules. Add real App Store ratings once
they exist — they slot in above the plan cards.

## 7b. Minimal pass — colour roles and restraint

Sources: Apple HIG Buttons ("keep prominent buttons to one or two per view";
"use style, not size, to distinguish the preferred choice"), Apple HIG Alerts
(confirm only uncommon destructive actions), NN/g on animation (animate
feedback, not decoration) and the aesthetic-usability effect.

| Role | Light | Dark | Rule |
|---|---|---|---|
| Canvas | off-white / system background | forest-black (`Brand.night` in the purchase flow) | Flat. No glow, grain or breathing light |
| Surface / card | `Brand.ink` 5% | white 6% | One surface step; no stacked borders |
| Hairline | `Brand.ink` 10% | white 12% | Dividers and unselected outlines only |
| Primary text | `Brand.ink` | white | — |
| Secondary text | `Brand.ink` 55–60% | white 62% | Hierarchy by opacity, never a second hue |
| Lime | one filled primary button per screen, the selected item's outline, progress | same | Never decorative, never two lime fills side by side |
| Forest | text and glyphs on lime | same | — |
| Red | the record button only | same | Destructive = system dialog role, not a red pill |
| Caution | — | amber (`PaywallStyle.caution`) | Purchase failures only |

**Buttons:** primary = flat lime fill, forest label (`GlowPillButton` default);
secondary = ink 8% tint (`GlowPillButton.secondaryTint`); low-stakes toolbar
actions = plain text (Studio "Discard"). No glass layer, glow or pulsing rim on pills.

**Motion:** only for state change and feedback — record start/stop, the A/B
switch, selection, the purchase check. No entrance animation on lists or
scroll rows, no looping ambient glow, no confetti.

**Shadows:** one soft contact shadow at most (orbs, record button). No
coloured glows.

**Upsell:** two entry points only — the export buttons and the Studio Pro
row in Settings.

## 8. Do / Don't (system-level)

- **DO** let the canvas breathe — restraint is what makes lime loud.
- **DO** render filter art from its palette; never fall back to a grey glyph.
- **DO** use `HummiIcon` for brand glyphs, SF Symbols for system affordances.
- **DON'T** add a second chromatic accent. One hero (lime) only.
- **DON'T** use red anywhere but the record control. Destructive = warning
  haptic + wording, and the *safe* choice gets the brand pill.
- **DON'T** leave big flexible spacers as "layout"; fill space with content
  that tells the take's story (see `TakeIdentityRow`).

## 9. Sound — Studio Mic Polish and the reward line

**Finding:** the Studio/export path played the raw take through only a
3-band EQ, saturation and reverb (`RealtimePreviewEngine`). The app's real
vocal chain (high-pass, mud cut, de-esser, compression, presence, air) lived
in `ProcessingPipeline` and was used only by the debug screen.

**Change:** `AudioEngine/VocalPolishChain.swift` now runs on every Studio
take before characters and spaces: gain staging → high-pass 80 Hz → mud/box
cut → de-esser (new `deEsserMarginDB`, 4 dB here; other callers keep 8) →
3-band compression → gentle presence/air → 2:1 glue → −16 LUFS, −1 dBFS
ceiling. Pure DSP, toggleable in Studio Panel › Cleanup › Studio Mic Polish.

**Measured on the 8 clips in `TestClips/`** (loudness-matched, before → after):

| Clip | Loudness range (dB) | Rumble <80 Hz | Presence 2–5k | Sibilance 5–9k |
|---|---|---|---|---|
| echoey-room | 26.3 → 21.3 | −3.7 | +3.4 | +3.6 |
| fan-noise | 26.8 → 23.2 | −5.1 | +4.7 | +2.4 |
| fast-runs | 19.3 → 15.7 | −3.1 | +4.5 | +2.3 |
| quiet-room-soft | 9.2 → 9.9 | −4.6 | +4.3 | +1.9 |
| quiet-room-loud | 10.0 → 8.5 | −4.6 | +4.6 | +3.6 |
| speech-control | 21.9 → 19.9 | −3.3 | +5.1 | +2.5 |
| traffic-window | 23.9 → 18.7 | −5.0 | +4.5 | +1.4 |
| vibrato | 24.9 → 20.9 | −6.5 | +4.2 | +3.1 |

Runs at roughly 1% of real time (0.2–1.5 s per clip on a Mac).
Listening files: `TestClips/output/studio-polish/` (`-1-before` is
loudness-matched to `-2-polished`). **Not yet judged by ear on device.**

**Reward line:** `PolishReport` measures each take and Studio shows one line,
e.g. "Studio take ready · 20% steadier · Clarity +3 dB", with one success
haptic. Only changes ≥ 1 dB / ≥ 5% are shown, and nothing is invented.
