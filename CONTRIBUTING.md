# Contributing to HUMMI

## The 60-second version

```bash
git switch main && git pull --ff-only
git switch -c feat/thing
# work, commit small
git rebase origin/main
git push --force-with-lease
gh pr create --fill
# CI green -> gh pr merge --squash --delete-branch
```

Nothing reaches `main` except through a pull request with green CI.

## Before your first PR

```bash
bundle install
git config pull.ff only
git config push.autoSetupRemote true
git config rerere.enabled true
```

## Non-negotiables

These are enforced by the `Repo hygiene` CI job, not by good intentions:

- No file over **300 lines**
- No **force unwraps** in `HUMMI/AudioEngine/`
- **Views never reference `AVAudioEngine`** — only view models do
- No signing credentials (`.p8`, `.p12`, `.mobileprovision`) in the repo, ever
- The shared Xcode scheme must stay committed

## Commits

Conventional Commits: `type(scope): imperative summary`

Types: `feat` `fix` `perf` `refactor` `test` `docs` `chore` `ci` `build` `revert`
Scopes: `audio` `enhance` `record` `export` `paywall` `ui` `ds` `settings` `ci`

The body explains **why**. The diff already shows what.

## Pull requests

- Under ~400 lines of diff. Bigger changes ship as a stack of small PRs.
- Fill in the template — especially **Verification** and **Rollback plan**.
- Anything touching `AudioEngine/` must be tested on a physical device.
- Squash merge only. One PR = one revertible commit on `main`.

## Deeper reading

- Branching, tags, hotfixes, conflict recovery → [`docs/GIT_WORKFLOW.md`](docs/GIT_WORKFLOW.md)
- Secrets, signing, TestFlight, App Store → [`docs/RELEASING.md`](docs/RELEASING.md)
- Architecture rules → [`CLAUDE.md`](CLAUDE.md)
