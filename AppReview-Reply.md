# Voice Studio — resubmission notes

Submission ID: e8d88bc7-312f-47cd-8f12-a528533ff8bb
Reviewed: 1.0 (2) · Resubmitting as 1.0 (3)

---

## 1. Reply to paste into the App Store Connect message thread

Hello,

Thank you for the review. Here is how each item has been addressed.

**Guideline 5.1.1(i) and 5.1.2(i) — Data Use**

Voice Studio does not send user data to a third-party AI service, and does not
include any third-party AI service. The app performs no network requests of any
kind.

All audio enhancement runs entirely on device. The noise-reduction model is a
DeepFilterNet3 model converted to Core ML and bundled inside the app; it is
executed locally through Core ML. Every other stage (EQ, compression, reverb,
pitch correction, loudness) is local DSP written with AVAudioEngine and vDSP.

Recordings never leave the device. There is no account system, no analytics, no
tracking, and no advertising identifier. The app's PrivacyInfo.xcprivacy declares
NSPrivacyTracking as false with no collected data types.

We have added this information to the App Review Information section.

**Guideline 5.1.1(iv) — Data Collection and Storage**

The microphone permission screen no longer directs the user to grant access. The
button previously labelled "Enable Microphone" is now labelled "Continue". The
screen only explains why the microphone is needed; the system prompt does the
asking. The supporting VoiceOver hint was changed from "Double tap to allow
microphone access" to "Double tap to continue".

**Guideline 2.3.7 — Accurate Metadata**

All price references have been removed from the screenshots and metadata.

Thank you,
Kirtidhwaj

---

## 2. Text for the App Review Information → Notes field

Voice Studio processes all audio entirely on device and makes no network
requests. No third-party AI service is used.

The noise-reduction step uses a DeepFilterNet3 model converted to Core ML and
bundled in the app binary, executed locally via Core ML. All other processing
(EQ, compression, reverb, pitch correction, loudness normalisation) is local DSP
using AVAudioEngine and vDSP.

No user data is collected, transmitted, or shared. No account, no analytics, no
tracking, no advertising identifier.

To test: launch the app, tap Continue on the microphone screen, allow microphone
access at the system prompt, record a few seconds of singing, then tap the record
button again to open the Studio screen and try the character and space filters.
The app can be tested fully in Airplane Mode, which demonstrates that no network
access is involved.

---

## 3. Checklist before uploading

- [ ] Build number is 1.0 (3) — build 2 was already used by the rejected submission
- [ ] Screenshots re-exported with all "free" / price wording removed
- [ ] App description and promotional text checked for price references
- [ ] Privacy policy URL set in App Store Connect
- [ ] App Review Information notes filled in with section 2 above
- [ ] Archive validates and uploads cleanly
