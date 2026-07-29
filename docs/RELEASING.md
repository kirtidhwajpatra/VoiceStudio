# HUMMI Release Runbook

Everything I could not do for you from here, in the order you should do it.
Budget ~45 minutes for the one-time setup. After that, releasing is two commands.

---

## Part 0 — One-time local setup (5 min)

```bash
cd ~/Documents/HUMMI

# Identity on your commits
git config user.name  "Kirtidhwaj Patra"
git config user.email "kirtidhwajpatra@gmail.com"

# Never create an accidental merge commit when pulling. If your local main has
# diverged from origin, you want to be TOLD, not silently merged.
git config pull.ff only

# `git push` on a new branch just works, no -u incantation
git config push.autoSetupRemote true

# Remember how you resolved a conflict, and replay it automatically if the same
# conflict reappears (which it does constantly when rebasing a branch repeatedly)
git config rerere.enabled true

# Ruby toolchain for fastlane
brew install rbenv xcbeautify
rbenv install 3.3.5 && rbenv global 3.3.5
gem install bundler
bundle install       # generates Gemfile.lock — COMMIT IT
```

Verify:

```bash
bundle exec fastlane lanes     # should list test / beta / release / certs
```

---

## Part 1 — App Store Connect API key (10 min)

This replaces your Apple ID for all automation. 2FA cannot be answered by a CI
runner; an API key sidesteps it entirely and is independently revocable.

1. <https://appstoreconnect.apple.com> → **Users and Access** → **Integrations** → **App Store Connect API**
2. **Team Keys** tab → **+**
3. Name: `HUMMI CI`. Access: **App Manager**
   *(Not Admin. App Manager can upload builds and submit for review, which is
   everything CI needs. If this key leaks, the blast radius is one app, not your
   whole account.)*
4. **Generate**, then **Download** the `.p8`.
   **Apple lets you download it exactly once.** Put it somewhere safe outside
   the repo — `~/.appstoreconnect/private_keys/`.
5. Note the **Key ID** (10 chars) and the **Issuer ID** (a UUID, top of the page).

Base64 the key so it survives GitHub's secret storage, which mangles newlines:

```bash
base64 -i ~/Downloads/AuthKey_XXXXXXXXXX.p8 | pbcopy
```

Now add three repository secrets — **Settings → Secrets and variables → Actions → New repository secret**:

| Name | Value |
|---|---|
| `ASC_KEY_ID` | the 10-char Key ID |
| `ASC_ISSUER_ID` | the issuer UUID |
| `ASC_KEY_CONTENT` | the base64 blob you just copied |

> If that `.p8` ever lands in a commit, revoke it in App Store Connect and
> generate a new one. Deleting the file is not enough — git history is permanent
> and the repo is public.

---

## Part 2 — Code signing with fastlane match (15 min)

1. Create a **new private** GitHub repo: `kirtidhwajpatra/hummi-certificates`.
   Private is not optional — it holds your encrypted signing identity.

2. From your Mac:

```bash
export MATCH_GIT_URL="https://github.com/kirtidhwajpatra/hummi-certificates.git"
bundle exec fastlane certs
```

   It will ask you to invent an encryption passphrase. **Save it in your password
   manager.** Lose it and the stored certificates are unrecoverable — you would
   have to revoke and regenerate everything.

3. Give CI read access to that private repo. Create a fine-grained PAT
   (**Settings → Developer settings → Personal access tokens → Fine-grained**)
   scoped to *only* `hummi-certificates`, with **Contents: Read-only**.

```bash
echo -n "kirtidhwajpatra:github_pat_XXXX" | base64 | pbcopy
```

4. Add three more repository secrets:

| Name | Value |
|---|---|
| `MATCH_GIT_URL` | `https://github.com/kirtidhwajpatra/hummi-certificates.git` |
| `MATCH_PASSWORD` | the encryption passphrase from step 2 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | the base64 blob from step 3 |

The `Matchfile` forces `readonly` whenever `CI=true`, so a runner can fetch
certificates but can never revoke or regenerate them.

---

## Part 3 — Branch protection (5 min)

**Settings → Rules → Rulesets → New branch ruleset**

- Name: `main protection`
- Enforcement status: **Active**
- Target branches: **Include default branch**

Enable:

| Rule | Setting | Why |
|---|---|---|
| Restrict deletions | ✅ | `main` cannot be deleted |
| Block force pushes | ✅ | History on `main` is append-only |
| Require linear history | ✅ | Enforces squash/rebase merges; `main` stays a readable line |
| Require a pull request before merging | ✅ | Nothing reaches `main` unreviewed |
| — Required approvals | **0** | You are solo; a self-approval is theatre. CI is the real gate. Change to **1** the day someone joins. |
| — Dismiss stale approvals | ✅ | An approval applies to a diff, not a branch |
| — Require conversation resolution | ✅ | No merging over unanswered questions |
| Require status checks to pass | ✅ | |
| — Required checks | `Repo hygiene`, `Build & test` | These are the job *names* from `ci.yml` |
| — Require branches up to date | ✅ | Prevents "both PRs were green, main is red" |
| Require signed commits | optional | Good hygiene; set up `gpg`/SSH signing first or you will lock yourself out |

Leave **bypass list empty**. The moment you can bypass under pressure, you will,
and that is exactly when the guardrail was earning its keep.

**Also:** Settings → General → Pull Requests → check **Allow squash merging**,
uncheck **Allow merge commits** and **Allow rebase merging**. Set the squash
commit message default to **Pull request title and description**. And check
**Automatically delete head branches** — branch hygiene you never have to think
about.

---

## Part 4 — Deployment environments (5 min)

**Settings → Environments → New environment**

Create **`testflight`**:
- No required reviewers (every merge should reach beta testers automatically)
- Deployment branches: **Selected branches** → `main`

Create **`app-store`**:
- **Required reviewers: yourself** ← the important one. This means pushing a
  `v*` tag *proposes* an App Store submission and waits for you to click
  Approve. A fat-fingered `git push --tags` cannot submit to Apple by itself.
- Deployment branches: **Protected branches only**

Environment-scoped secrets also mean the App Store credentials are not visible
to every workflow in the repo.

---

## Part 5 — Your first real release

### Ship a feature (the loop you will run hundreds of times)

```bash
git switch main && git pull --ff-only
git switch -c feat/subscriptions
# ... build subscriptions ...
git add -p && git commit -m "feat(paywall): add StoreKit2 subscription tiers"
git push
gh pr create --fill

# CI runs. Merge when green:
gh pr merge --squash --delete-branch

# → Beta workflow fires automatically → TestFlight in ~15 min
```

### Cut the release

```bash
git switch main && git pull --ff-only

# 1. Bump the marketing version — this is a product decision, so it is a commit.
#    Xcode → HUMMI target → General → Version: 1.1.0
git switch -c chore/bump-1.1.0
git commit -am "chore(release): bump version to 1.1.0"
gh pr create --fill && gh pr merge --squash --delete-branch

# 2. Wait for the TestFlight build. Install it. Actually use the app.
#    Record something. Enhance it. Export it. Subscribe.

# 3. Tag the exact commit that produced the build you just tested.
git switch main && git pull --ff-only
git tag -a v1.1.0 -m "Release 1.1.0 — subscriptions"
git push origin v1.1.0
```

The tag triggers `release.yml`. It verifies the tag matches `MARKETING_VERSION`,
waits for your environment approval, then submits the **already-tested
TestFlight binary** for review. It does not rebuild — the binary Apple reviews
is byte-identical to the one you just tested.

### After approval

App Store Connect → **Release this version** (manual, on purpose — you choose
the moment). Then consider **Phased Release**: 1% of users day 1, ramping over
7 days. If crash reports spike on day 2, you pause it and 99% of your users
never saw the bug.

---

## Part 6 — When something goes wrong

**Build rejected: "build number already used"**
Apple saw that build number before. `latest_testflight_build_number` normally
prevents this; if the API call failed, the lane fell back to
`GITHUB_RUN_NUMBER`. Re-run the workflow.

**`match` fails: "Could not decrypt"**
`MATCH_PASSWORD` is wrong, or the certs repo was regenerated with a new
passphrase. Re-run `bundle exec fastlane certs` locally and update the secret.

**Signing fails after adding a capability** (StoreKit, push, etc.)
The provisioning profile predates the capability. Locally:
`bundle exec fastlane certs` regenerates and pushes it, and CI picks it up.

**App Review rejection**
Do *not* delete the tag. Fix on a `fix/` branch → PR → merge → new TestFlight
build → bump to `1.1.1` → tag `v1.1.1`. The rejected version stays in history
where it belongs.

**Crash in production**
Follow the hotfix procedure in `docs/GIT_WORKFLOW.md` §7. Request expedited
review in App Store Connect and describe the crash concretely — Apple grants
these routinely for real crashes and rarely for anything else.

---

## Cost note

`macos-26` minutes bill at **10×**. The 2,000-minute free tier is ~200 macOS
minutes/month. The workflows here already defend against that: cheap Linux
hygiene checks gate the expensive macOS job, `paths-ignore` skips doc commits,
and `cancel-in-progress` kills superseded runs. Expect roughly 6–10 minutes per
PR. If you outgrow the free tier, the fallback is a self-hosted runner on your
own Mac — same YAML, change `runs-on`.
