#!/usr/bin/env bash
# =============================================================================
# Mechanically enforce the architecture rules in CLAUDE.md.
#
# THE RATCHET PATTERN
# Five files already exceed the 300-line rule. A gate that is red on day one
# teaches everyone to ignore the gate, which is worse than having no gate. So
# instead of failing on the existing debt, we freeze it:
#
#   - a NEW file over 300 lines           -> fail
#   - a baselined file that GROWS         -> fail
#   - a baselined file that SHRINKS       -> pass, and tell you to update the
#                                            baseline so the ratchet tightens
#
# Debt can only ever go down. This is how large codebases adopt a rule without
# a big-bang refactor, and it is why the baseline file is checked in.
# =============================================================================
set -uo pipefail

LIMIT=300
BASELINE="$(dirname "$0")/../file-size-baseline.txt"
fail=0
shrunk=0

note() { echo "::notice::$*"; }
err()  { echo "::error::$*"; fail=1; }

# -----------------------------------------------------------------------------
# Rule 1: file length
# -----------------------------------------------------------------------------
while IFS= read -r f; do
  n=$(wc -l < "$f" | tr -d ' ')
  [ "$n" -le "$LIMIT" ] && continue

  allowed=$(awk -v k="$f" '$0 !~ /^#/ && $2 == k { print $1 }' "$BASELINE" 2>/dev/null | head -1)

  if [ -z "$allowed" ]; then
    err "file=$f::$f is $n lines (limit $LIMIT). Split it before merging."
  elif [ "$n" -gt "$allowed" ]; then
    err "file=$f::$f grew to $n lines (was $allowed, limit $LIMIT). Existing debt may not increase."
  elif [ "$n" -lt "$allowed" ]; then
    note "$f shrank to $n (baseline $allowed). Update .github/file-size-baseline.txt to lock the gain in."
    shrunk=1
  fi
done < <(git ls-files '*.swift')

# -----------------------------------------------------------------------------
# Rule 2: no force unwraps in audio code
# A force unwrap on the audio render thread is a crash while the user is
# recording -- the single worst failure this app has.
# -----------------------------------------------------------------------------
if git ls-files 'HUMMI/AudioEngine/*.swift' \
   | xargs -r grep -nE '[A-Za-z0-9_\)\]]![[:space:]]*($|[.,\)])' ; then
  err "Force unwrap found in AudioEngine/. Audio code must not force unwrap."
fi

# -----------------------------------------------------------------------------
# Rule 3: the UI never touches AVAudioEngine directly
# -----------------------------------------------------------------------------
if git ls-files '*View.swift' | xargs -r grep -ln 'AVAudioEngine' ; then
  err "A SwiftUI View references AVAudioEngine. Only view models may."
fi

# -----------------------------------------------------------------------------
# Rule 4: no credentials, ever
# -----------------------------------------------------------------------------
if git ls-files | grep -Ei '\.(p8|p12|mobileprovision|cer|certSigningRequest)$'; then
  err "Signing credentials are committed. Git history is permanent -- REVOKE the key, do not just delete the file."
fi

if git ls-files | grep -E '(^|/)xcuserdata/|\.xcuserstate$'; then
  err "User-specific Xcode state is committed. Check .gitignore."
fi

# -----------------------------------------------------------------------------
# Rule 5: CI cannot build without a shared scheme
# -----------------------------------------------------------------------------
[ -f HUMMI.xcodeproj/xcshareddata/xcschemes/HUMMI.xcscheme ] \
  || err "Shared scheme is missing. CI cannot resolve -scheme HUMMI without it."

[ "$shrunk" = "1" ] && [ "$fail" = "0" ] && echo "Architecture checks passed (with baseline improvements available)."
[ "$fail" = "0" ] && echo "Architecture checks passed."
exit $fail
