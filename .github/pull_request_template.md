## What & why

<!-- One paragraph. What changes, and what problem it solves. Assume the
     reviewer is you in six months with no memory of this week. -->

Closes #

## How it works

<!-- Only the non-obvious parts. If a decision could reasonably have gone the
     other way, say why it went this way. -->

## Audio impact

<!-- Delete if this PR does not touch AudioEngine/. -->

- [ ] Processing stage is individually toggleable (required by CLAUDE.md)
- [ ] No force unwraps in audio code
- [ ] Pure DSP math has unit tests
- [ ] Verified on a physical device, not just the simulator
- Test clips used:

## Verification

<!-- What you actually did to convince yourself this works. "It builds" is not
     verification. -->

- [ ] `xcodebuild test` passes locally
- [ ] Tested on device (model / iOS version: )
- [ ] Checked light and dark mode

## Screenshots / audio

<!-- Before and after, for anything a user can see or hear. -->

## Risk

- [ ] Low - additive, easy to revert
- [ ] Medium - touches shared code paths
- [ ] High - changes the audio graph, export format, or persisted data

**Rollback plan:**

---

<!-- Reminder: this branch should be short-lived. If it has been open more than
     ~2 days, consider splitting it. Long-lived branches are how trunk-based
     development quietly turns back into gitflow. -->
