# HUMMI Git Workflow

Trunk-based development. This is what Google, Stripe, Uber, and Airbnb run, in
various dialects. It is not "gitflow with fewer branches" — the underlying model
is different, and mixing them produces the worst of both.

---

## 1. The model in one picture

```
                 (short-lived, hours to 2 days)
        feat/subscriptions ──●──●──┐
                                   │  squash merge, PR, CI green
main ──●───────●───────────────────●────●────●────●──────────────●──▶
       │                           │                             │
    v1.0.0                    TestFlight                     v1.1.0
   (baseline)                (every merge)                 (tag = release)
                                                                 │
                                            hotfix/1.1.1 ──●─────┤
                                                            cherry-pick
                                                                 ▼
                                                              v1.1.1
```

**One long-lived branch: `main`.** Everything else lives for hours, not weeks.

### Why no `develop` branch

Gitflow's `develop` exists to answer "what is integrated but not released?" That
question only mattered when releases were quarterly and integration was painful.
With CI on every PR and TestFlight on every merge, `develop` becomes a second
place for code to rot, a second set of merge conflicts, and a permanent
"which branch do I branch from?" tax. Every hour of divergence is an hour of
merge conflict you are buying on credit.

The replacement for `develop` is **feature flags**. Merge unfinished work behind
a flag that is off. It is integrated, tested, and shipped-but-dark. That is how
you get main-always-shippable without long-lived branches.

### The rule that makes it work

> **`main` is always shippable.** Any commit on `main` could go to the App Store
> today without a discussion.

Every other rule below exists to protect that one.

---

## 2. Branch naming

| Prefix | Use | Lifetime | Example |
|---|---|---|---|
| `feat/` | New user-visible capability | ≤ 2 days | `feat/subscriptions` |
| `fix/` | Bug in `main`, not yet released | ≤ 1 day | `fix/export-clips-on-pause` |
| `hotfix/` | Bug in a **released** version | hours | `hotfix/1.1.1-crash-on-launch` |
| `chore/` | Tooling, deps, CI, refactors | ≤ 1 day | `chore/bump-fastlane` |
| `docs/` | Docs only | minutes | `docs/audio-graph-notes` |
| `spike/` | Throwaway experiment, never merged | any | `spike/coreml-denoise-v2` |
| `release/` | Only when you must stabilise a version while `main` moves on | days | `release/1.2` |

Names are lowercase, hyphenated, and describe the **outcome**, not the activity.
`feat/subscriptions` not `feat/working-on-subs`.

### On `release/` branches

You mostly should not need them. Tag `main` and ship. Create a `release/1.2`
branch only when a version is in App Review and you need to keep landing 1.3
work on `main` at the same time. It is a pressure valve, not a routine.

---

## 3. The everyday loop

```bash
# 1. Start from the freshest main. Never branch from a stale local main.
git switch main
git pull --ff-only

# 2. Branch.
git switch -c feat/subscriptions

# 3. Work. Commit small and often — commits are your undo history, not a
#    presentation. You will clean them up before merge.
git add -p                      # stage hunks, not whole files; forces you to
                                # read your own diff before committing
git commit -m "feat(paywall): add StoreKit2 product loading"

# 4. Stay close to main. Rebase, do not merge, while the branch is private.
git fetch origin
git rebase origin/main
#    Rebase replays your commits on top of the new main, so history stays
#    linear and your PR diff shows only YOUR changes. A merge commit here would
#    pollute the PR with unrelated work.

# 5. Push. --force-with-lease is mandatory after a rebase: it refuses to push
#    if someone else pushed to your branch in the meantime. Plain --force does
#    not check, and silently destroys their work.
git push --force-with-lease -u origin feat/subscriptions

# 6. Open the PR.
gh pr create --fill --base main
```

**Golden rule of rebasing:** rebase branches only you have. Once someone else
has pulled your branch, rebasing rewrites history under them. Merge instead.

---

## 4. Commit messages

Conventional Commits. Not because the format is beautiful, but because it is
parseable — it feeds release notes, TestFlight "What to Test", and changelog
generation for free.

```
<type>(<scope>): <imperative summary, ≤ 72 chars, no trailing period>

<why this change exists — the diff already shows what changed>

Refs: #42
```

**Types:** `feat` `fix` `perf` `refactor` `test` `docs` `chore` `ci` `build` `revert`

**Scopes for HUMMI:** `audio` `enhance` `record` `export` `paywall` `ui` `ds`
(design system) `settings` `ci`

Good:

```
fix(audio): prevent buffer underrun when export is cancelled mid-render

AVAudioEngine kept the render thread alive after stop() because the tap was
never removed, so the next export saw a stale buffer and dropped ~40ms of
audio at the head. Remove the tap in the cancellation path.

Fixes #87
```

Bad: `fixed stuff`, `WIP`, `Update ResultViewModel.swift`, `addressed review
comments` (squash that into the commit it fixes).

---

## 5. Pull requests

**Keep them under ~400 lines of diff.** This is not style policing. Review
quality falls off a cliff past that — reviewers switch from reading to skimming,
and skimmed code is unreviewed code. If your change is large, ship it as a
stack of small PRs.

**Merge strategy: squash and merge.** One PR becomes one commit on `main`. This
gives you a `main` history where every commit is a complete, tested, revertible
unit — which is precisely what you need at 2am when you must undo something.
The messy 14-commit development history stays on the PR page where it belongs.

**Reviewing your own PRs (solo).** This feels like theatre. It is not. Open the
"Files changed" tab and read the diff as a stranger would. You will catch
leftover `print()`s, commented-out code, and "wait, why did I do that" roughly
every third PR. CI is your second reviewer; that is why the hygiene job enforces
your CLAUDE.md rules mechanically.

**What review actually looks for**, in priority order:

1. Does it do what the description says?
2. Is there a failure mode nobody handled? (audio interruption, no mic
   permission, disk full, app backgrounded mid-render)
3. Does it violate an architecture rule? (UI touching AVAudioEngine, force
   unwrap in audio code, file over 300 lines)
4. Will this be understandable in six months?
5. Style. Last. Automate it so it never occupies a human.

---

## 6. Versioning

**Marketing version** (`1.2.0`) — Semantic Versioning, and it is a *product*
decision. You bump it in a PR, by hand, in `HUMMI.xcodeproj`.

- **MAJOR** — a redesign or migration users must notice
- **MINOR** — new features (subscriptions → `1.1.0`)
- **PATCH** — bug fixes only

**Build number** (`CURRENT_PROJECT_VERSION`) — *not* a product decision. It is
bookkeeping: Apple only requires it to be unique and increasing. CI derives it
from `latest_testflight_build_number + 1` and injects it at build time via
`xcargs`.

This matters more than it sounds. The common alternative — CI bumps the build
number and commits it back to `main` — creates a commit that retriggers CI,
fights branch protection, and makes your history a wall of "bump build". Deriving
it means **nothing on disk changes during a build**, so a build is a pure
function of a commit. Rebuild `v1.1.0` next year and you get the same app.

### Tags

```bash
# Annotated (-a), never lightweight. Annotated tags carry an author, date, and
# message, and are real objects in the repo. Lightweight tags are just a pointer
# and tell you nothing about who released what, or when.
git tag -a v1.1.0 -m "Release 1.1.0 — subscriptions"
git push origin v1.1.0     # this push is what triggers the release workflow
```

Tags are immutable. If `v1.1.0` was wrong, you ship `v1.1.1`. You never move a
tag — someone has already fetched it, and moving it means two people have
different code under the same name.

---

## 7. Hotfixes

A released version is broken and users are hitting it right now.

```bash
# 1. Branch from the TAG, not from main. main has unreleased work on it; you
#    want to change exactly one thing relative to what users actually have.
git switch -c hotfix/1.1.1-crash-on-launch v1.1.0

# 2. Make the smallest possible fix. A hotfix is not a chance to also clean up.
git commit -m "fix(audio): guard nil format when session activates during a call"

# 3. Bump PATCH in the project (1.1.0 -> 1.1.1), commit.

# 4. PR into main first, so the fix cannot be lost.
git push -u origin hotfix/1.1.1-crash-on-launch
gh pr create --base main --title "hotfix: crash on launch during active call"

# 5. Once merged and CI is green, tag main — assuming main has nothing
#    unshippable on it. If it does, tag the hotfix branch instead and
#    cherry-pick onto main.
git switch main && git pull --ff-only
git tag -a v1.1.1 -m "Hotfix 1.1.1 — crash on launch"
git push origin v1.1.1

# 6. In App Store Connect, request expedited review and explain the crash.
```

**The one mistake to avoid:** fixing it only on the hotfix branch and shipping.
The next release regresses the same bug, and users hit it twice. The fix must
land on `main`, always.

---

## 8. Undoing things

```bash
# Not committed yet — throw away changes to one file
git restore HUMMI/Enhancement/ResultView.swift

# Committed locally, not pushed — undo the commit, keep the changes staged
git reset --soft HEAD~1

# Pushed to a shared branch — revert. Creates a NEW commit that undoes the old
# one. Never rewrite history that others have pulled.
git revert <sha>

# Reverting a squash-merged PR (it is one commit, so this just works)
git revert -m 1 <merge-sha>    # -m 1 only if it is a true merge commit

# "I have destroyed everything" — reflog remembers every position HEAD held
# for ~90 days, including commits you thought you deleted.
git reflog
git switch -c rescue <sha-from-reflog>

# What actually shipped in 1.1.0?
git log v1.0.0..v1.1.0 --oneline --no-merges

# Which release first contained this commit?
git tag --contains <sha>

# Who changed this line and why?
git log -L 40,60:HUMMI/AudioEngine/Enhancer.swift
```

`git bisect` for "this worked in 1.0.0 and is broken now":

```bash
git bisect start
git bisect bad main
git bisect good v1.0.0
# build, test, then: git bisect good  |  git bisect bad
git bisect reset
```

---

## 9. Xcode project file conflicts

`project.pbxproj` conflicts are the #1 iOS-specific git pain. `.gitattributes`
sets `merge=union` on it, which auto-resolves the common case (two branches each
added files) by keeping both sides.

When it still conflicts:

```bash
# 1. Close Xcode. It will rewrite the file under you otherwise.
# 2. Accept main's version and re-add your files through Xcode:
git checkout --theirs HUMMI.xcodeproj/project.pbxproj
git add HUMMI.xcodeproj/project.pbxproj
# 3. Open Xcode, drag your new files back into the target, verify it builds.
```

Hand-editing `pbxproj` to resolve a conflict works about 70% of the time and
fails invisibly the other 30%. Re-adding through Xcode is slower and always
correct.

**Always open Xcode and build after any `pbxproj` merge**, even a clean one.

---

## 10. Anti-patterns

| Don't | Why | Instead |
|---|---|---|
| Long-lived feature branches | Merge cost grows superlinearly with divergence | Feature flags, merge daily |
| Commit directly to `main` | No CI gate, no review, no revert point | Always a PR, even solo |
| `git push --force` | Silently destroys others' commits | `--force-with-lease` |
| Rebase a shared branch | Rewrites history under people who pulled it | Merge, or ask first |
| Merge commits into a PR branch | Pollutes the diff with unrelated changes | `git rebase origin/main` |
| Moving a tag | Two people get different code for one name | Ship a new patch version |
| CI committing version bumps | Retriggers CI, fights branch protection | Derive build numbers |
| Committing `.p8` / `.p12` | Git history is permanent; the key is burned | Secrets in CI, rotate if leaked |
| Rebuilding at release time | Ships a binary nobody tested | Promote the TestFlight build |
| 2000-line PRs | Reviewers skim, and skimmed code is unreviewed | Stack of small PRs |
