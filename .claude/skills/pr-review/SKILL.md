---
name: pr-review
description: Peer-review a GitHub PR end-to-end — pull it into a predictable per-PR worktree, run an independent codex-backed review, self-verify every finding, then present draft comments and selectable verdict options for user approval before anything is posted. Handles first rounds and follow-up rounds (tracks prior findings, withheld nits, and disputed items in memory so they are never re-flagged). Use when invoked as /pr-review [pr-url], or when asked to review, re-review, or "check" a pull request.
---

# pr-review

Review `$1` (a PR URL or bare number; optional `--no-ocr`, see §3b). NOTHING is posted to GitHub without
explicit user approval via a selectable options prompt.

## 1. Resolve PR + round

- Parse owner/repo/number from the URL (bare number → current repo's origin).
- `gh pr view <N> --json title,body,author,headRefName,baseRefName,state,headRefOid,files`.
- **Read the PR description in full** — it drives the intent (step 3) and the
  completeness pass (step 4). Note its claimed scope, testing claims, risk
  notes, and any linked ticket (fetch the ticket when referenced — Linear
  via MCP, `SEC-`/`PERP-`/`DEFI-` etc.).
- Determine the round: check memory index for `pr<N>-*-review-state*` AND
  `gh api repos/<o>/<r>/pulls/<N>/reviews` for my prior reviews.
  - **First round**: no prior state.
  - **Follow-up**: load the memory file. It lists posted findings, withheld
    nits, and disputed items — the disputed/withheld lists must NEVER be
    re-flagged (see PR #653 lesson: long disputed list, never re-flag).

## 2. Worktree (predictable, reused across rounds)

- Path: `../<repo>-worktrees/pr<N>-review` relative to the main checkout.
- `git fetch origin main <headRefName>` first — always fetch before any
  worktree work.
- If the worktree exists (follow-up): `git -C <wt> checkout --detach origin/<headRefName>`.
  If not: `git worktree add <wt> origin/<headRefName>` (detached).
- Never `git stash` anywhere during the review — `refs/stash` is shared
  across worktrees.
- Only if the round requires building/clippy in a fresh perpetuals worktree:
  copy `contracts/out` from the main checkout (or `forge build`) —
  pre-commit clippy `include_str!`s Foundry artifacts.

## 3. Independent review (codex)

- Follow the `codex-review` skill in **advise mode**: write an UNBIASED intent
  (goal, requirements, acceptance criteria, constraints — never the
  implementation) from the PR title/body/linked ticket, and pipe it through
  `~/.claude/skills/codex-review/scripts/codex-review.sh --base origin/main`
  run inside the worktree. **Always background it** — the Bash tool caps at
  600s and a review may take up to 1200s. Default timeout is 600s; raise with
  `--timeout` up to 1200 for a large PR.
- Advise mode means: report findings, never edit the PR's code, no fix loop.
- All four intent sections are required and non-empty or the script rejects it.
  State repo facts as **constraints** to prevent false positives (e.g. nextest
  is process-per-test; no-panic + no-unchecked-arithmetic rules; SBE codecs are
  generated; OpenAPI 3.0.3 limits). See memory
  `codex-review-repo-facts-in-intent`.
- Exit codes: 2 usage, 3 precondition, 4 timeout, 5 codex failure, 6 bad output.
  On any failure, stop and ask — never post a review claiming codex ran.
- If it reports findings citing files outside the reviewed set, verify those
  explicitly rather than dropping them — an untouched sibling is exactly the
  #732 omission pattern.
- While codex runs, do my own pass so triage is independent, and note anything
  codex might miss — §3b says how.
- Follow-up rounds: additionally diff against the previously reviewed head
  SHA (from the memory file) and verify each previously-posted finding is
  actually fixed — do not take the PR description's word for it.

## 3b. Own pass, structured by OCR (default on; `--no-ocr` turns it off)

If the invocation carries `--no-ocr`: skip this section and read the full diff
unaided (`git diff origin/<baseRefName>...HEAD`). Otherwise, while codex runs,
inside the worktree:

1. `ocr delegate preview --from origin/<baseRefName> --to HEAD -b "<goal line of the step-3 intent>"`
   → the reviewable file list and the `merge_base`.
2. `ocr delegate rule <every reviewable path>` → the checklist for each file group.
3. Per reviewable file: `git diff <merge_base>..HEAD -- <path>`, read against its
   checklist. Comment on changed lines only.
4. Files OCR excluded (tests, docs, generated, binary) still get a plain read —
   an exclusion narrows OCR's checklist, not the review.

Run the `ocr delegate` commands; do NOT load the `open-code-review:delegate-review`
skill. That skill ends by fixing what it finds, and a review never edits the PR.
`ocr` not installed, or either command failing → stop and ask, exactly as for
codex. Never write a review that says OCR ran when it did not.
Findings from this pass enter step 4 like any other: unverified until checked
against the real code.

## 4. Verify + triage (no false positives)

For every codex finding AND my own: verify against the real code (read the
macro/helper/callee it implicates) before it may appear in a draft comment.
Classify each: **agree** (with severity), **nit**, **dispute** (with
reasoning), or **needs-user-call**. Drop anything that doesn't survive
verification; carry disputes into the output rather than silently dropping.

**Completeness pass** (description vs diff — codex won't catch omissions):

- Every claim in the description is delivered by the diff (promised tests
  exist, promised asserts/guards present, stated scope fully covered).
- Testing claims spot-checked, not trusted (do the named tests exist and
  test what's claimed?).
- Things the change *implies* but omits: sibling code paths with the same
  defect (the #732 pattern — pricer fixed, oracle forgotten), definitions/
  docs sync, metrics/alerts for new failure modes, migration/backfill needs.
- Anything left out that shouldn't be, flag it as a finding even if the
  diff itself is flawless.

## 5. Approval gate (ALWAYS, every round)

Present, in the final message before any posting:

1. A triage table: id, severity, finding, `file:line`, classification, note.
2. **Verbatim draft comment text** for each proposed inline comment.
3. Verified-clean areas (what was checked and passed).

Then `AskUserQuestion`:

- **Question 1 — verdict**: if genuinely torn between resolutions, spread
  them as separate options (e.g. "APPROVE", "COMMENT", "REQUEST_CHANGES"),
  each with a one-line rationale, recommended one first with
  "(Recommended)". If prior round was my CHANGES_REQUESTED and this round is
  clean, include "Dismiss stale block + APPROVE" (a stale request-changes
  gates the PR until dismissed — PR #703 lesson).
- **Question 2 — comment selection**: when nits exist, offer skip options
  ("post all", "substantive only, drop nits", "pick per-comment" via
  multiSelect of the comment ids, "post none").

Never post on a timeout, a task notification, or my own assumption —
only on an actual answer.

## 6. Post (only after approval)

- `gh api repos/<o>/<r>/pulls/<N>/reviews -f commit_id=<headRefOid>
  -f event=<VERDICT> -f body=<summary>` with a `comments[]` entry per
  approved inline comment (`path`, `line` [RIGHT side], `body`).
- Line anchors must be inside the diff; re-check line numbers against the
  head commit right before posting.
- Follow-up fix-verification notes belong as replies in the existing threads
  where possible, not new top-level comments.

## 7. Persist round state (memory)

Write/update `pr<N>-<slug>-review-state.md` in the memory directory + one
index line in `MEMORY.md`: verdict + review id, posted findings, withheld
nits, disputed list (with reasons), reviewed head SHA, worktree path
(kept). This file is what makes round N+1 cheap and consistent.

## Bookkeeping

- Keep the worktree between rounds; only suggest removal after merge/close.
- If the PR was updated mid-review (head SHA changed since step 1), stop and
  tell the user instead of posting against a stale commit.
