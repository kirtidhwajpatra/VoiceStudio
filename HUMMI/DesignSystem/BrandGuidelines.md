# HUMMI Brand Guidelines

The brand comes from the app icon: a **coral microphone** held by a
**two-tone blue cradle**, with a **blue sparkle**. Coral is the voice; blue is
the studio around it; the sparkle is the moment it sounds great.

Tokens live in `Foundations/Brand.swift`. Never use raw hex in views.

## Palette

| Token | Light | Dark | Role |
|---|---|---|---|
| `Brand.accent` | #1458E6 | #1458E6 | The one filled primary action per screen (vivid logo blue) |
| `Brand.onAccent` | white | white | Labels and glyphs on accent fills (5.9:1) |
| `Brand.accentText` | #0F52D9 | #5C9BFF | Blue text, outlines, selection rings, progress on the canvas |
| `Brand.voice` → `voiceDeep` | #FF4F5E → #E8364A | same | Record button, live voice waveform, reward sparkles |
| `Brand.onVoice` | white | same | Text on a coral fill (use on `voiceDeep`) |
| `Brand.sky` | #4FA3FF | same | Light blue tints, waveform progress on the dark paywall, illustration accents |
| `Brand.ink` | #070D1F | #F5F7FC | Text and glyphs on the canvas (19:1 / 18:1) |
| `Brand.canvas` | #FFFFFF | #060A14 | Screen background (white / deep studio navy) |
| `Brand.surface` | #F1F3F8 | #141B2E | Cards, rows, toasts, small round buttons |
| `Brand.night` | #060A14 | #060A14 | Always-dark screens (paywall) |

`logoBlue`, `logoCoral`, `logoSky` are the exact icon colours, used only to
draw the mark. The icon's coral and light blue are pastels, so the UI uses
the same hues at higher saturation.
The old names `lime`, `limeDeep`, `limeGradient`, `forest` still compile and
resolve to `accent`, `accentText`, `accentGradient`, `onAccent`.

## Rules

- **One filled blue button per screen.** Secondary actions use `ink` at 8%
  with `ink` labels; low-stakes toolbar actions are plain text.
- **Coral is the voice, and only the voice:** the record button, the live
  waveform, reward sparkles. Never a button fill, never an error colour.
- **Text on the canvas is `ink` or `accentText`.** Never use a fixed colour
  (white, `night`, `accent`) as text on the canvas; it fails in one of the
  two appearances. Secondary text is `ink` at 55–60%.
- **Backgrounds are `canvas`, cards are `surface`.** Do not use
  `Color(.systemBackground)`, which is pure black in dark mode and breaks the
  navy studio feel.
- **Failures are amber** (`PaywallStyle.caution`), not red or coral.
- **Shadows:** one soft contact shadow at most. No coloured glows.

## The mark

- `HummiMark` draws the icon in code (crisp at any size, parts animate).
  The splash builds it: cradle draws in, mic springs in, sparkle twinkles.
- There is no wordmark. Where the brand needs to appear, use `HummiMark`.

## Rewards

Use `ToastManager.shared.celebrate(_:)` only for something the singer
achieved: a take recorded, a studio take saved, an export ready. It shows
the logo's sparkle bursting with coral and sky sparks, plus one success
haptic. Studio also shows a measured result line ("20% steadier · Clarity
+3 dB"). Ordinary status uses `show(message:)`.

## Iconography & illustration

- Brand glyphs use `HummiIcon` (24-grid, 2pt rounded stroke).
- Spaces use `SpaceIllustration` + `RoomSizeMeter`; their accent dot uses the
  space's own colour, lifted 35% toward white in dark mode.
- System affordances (share, chevron, close) stay SF Symbols.
