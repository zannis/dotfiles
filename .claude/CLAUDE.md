# Global Instructions

## Coding
- Analyze before coding; ask for clarifications when requirements or architecture are ambiguous
- DRY, KISS, security-first
- No fallbacks — they hide real failures
- No dummy data — I'll handle that
- Do exactly what's asked, nothing more
- Inline comments only when absolutely necessary — a non-obvious constraint, invariant, or gotcha the code can't express itself. Keep them terse (one short line). Never narrate what the code does or why a change was made
- Flag obsolete files for removal
- New dependencies are a last resort — triple-check first; audit the stdlib and current deps for the capability before adding one
- Before adding a dep, check whether an existing one already covers it via a feature flag / optional feature / submodule — enabling that beats a new package

## Rust
- Never write code that can panic on the runtime path — no `unwrap()`, `expect()`, `panic!`, `unreachable!`, `todo!`, indexing that can go out of bounds, or arithmetic that can overflow/divide-by-zero. Propagate errors with `?` and typed error enums (`thiserror`), or handle them explicitly. If a case is truly impossible, encode it in the type system instead of asserting it at runtime.
- The only place a panic is acceptable is fail-fast startup/init (config load, connection pool setup, `main`/`build`-time wiring) where crashing before serving traffic is the correct behavior — and even there, prefer returning `Result` from `main` with context. Tests and build scripts may `unwrap`/`expect` freely.
- Zero tolerance for unchecked arithmetic on runtime paths — no bare `+`/`-`/`*`/`/`/`%` that can overflow, underflow, wrap, or divide by zero, including `Decimal` and other bignum types (their operators panic or silently saturate too). Use `checked_*`/`saturating_*`/`try_*` with explicit error handling; this applies to pre-existing code touched by a change, not just new lines — fix it, don't inherit it.

## Git
- Never commit spec or plan documents (e.g. `docs/superpowers/specs/`, `docs/superpowers/plans/`)
- Branches are `zannis/<type>/<slug>` — `<type>` a Conventional-Commit type, `<slug>` kebab-case, at most five words, describing the change. Never a ticket id, agent name, date or Paperclip identifier
- Nothing internal to this setup reaches a real repository — not in a branch, a commit, a PR title or body, or a comment: `GIA-<n>` and other Paperclip ids, `Giant`/`Paperclip`/agent names, generated-by trailers (`Co-Authored-By`, `🤖 Generated with …`), or references to spec/plan docs. Those reviewers have no context on it. Linear ids belong on the PR body's `Closes:` line and nowhere else
- When starting work in a new worktree, always fetch the latest main first and base the worktree/branch on it, unless explicitly asked to use a different base

## Testing
- TDD by default
- Prefer integration tests over unit tests; mock as little as possible
- Integration tests hit real infrastructure (real DB, real Redis) via test containers
- Never mock the database — use real connections (e.g. TimescaleDB)
- Always run tests with `cargo nextest run` — never `cargo test`
- Run integration tests through dotenvx: `dotenvx run -- cargo nextest run`

## Cargo
- Always pass `-q` to cargo commands

## Shell — quiet by default
Context is re-read on every turn, so progress chatter is paid for hundreds of times.
Suppress output that carries no information; never suppress output you need to read.

- `git`: pass `-q` to `fetch` `clone` `checkout` `switch` `add` `commit` `push` `merge`
  `worktree add` `stash`. Never to `diff` `log` `show` `status` — those *are* the answer.
- `cargo -q`, `pnpm --silent`, `npm --silent`, `curl -sS`. For `gh`, use
  `--json <fields> -q <jq>` rather than piping full output.
- Bound anything unbounded: `| head -n N`, `--stat` before a full `diff`, `-l`/`-c` on
  `grep` when you only need which files or how many.
- On success, prefer no output — `&& echo ok` beats a wall of progress lines.
- Redirect known-noisy stdout to a file and grep the file, rather than reading it inline.

## GitNexus — the default for symbol relationships
Repos are indexed into a symbol/call graph served over MCP. Grep finds the *name*; every
question about the name's *relationships* goes to the graph first, not to more grep/Read.
One call returns exact callers with file:line for a few hundred tokens, where opening the
files costs tens of thousands. The tools are deferred — load them once per session with
`ToolSearch("select:mcp__gitnexus__context,mcp__gitnexus__impact,mcp__gitnexus__trace")`.

Three moments where the graph call is the next step, not an option:

- Have a symbol name, need who calls it / what it calls → `mcp__gitnexus__context`.
  Then read only the files it names.
- About to edit a shared symbol → `mcp__gitnexus__impact` (direction `upstream`)
  **before** the edit; a HIGH/CRITICAL blast radius goes in the plan and the PR.
- Connecting an entry point to a suspect symbol (bug mechanism, "how does A reach B") →
  `mcp__gitnexus__trace` — one call instead of hopping files.

A graph error or a symbol missing from the index → say so and fall back to grep; never
silently skip the graph.

Never reach for `query`. It is advertised as semantic search but returns plain keyword
hits: its vector half is dead — the VECTOR extension is never loaded on the read path,
so the embedding index is unreachable and the results are BM25 alone. Loading it makes
ranking measurably *worse*, because a third of the index is one-token struct-field and
const nodes that outscore real function bodies. Grep is the honest version of this tool.
Also empty: `explain` and `pdg_query` (need `analyze --pdg`, not built), `tool_map`,
`shape_check`.

Every call needs a `repo`. Each worktree is its own index, and the alias is path-derived:
`repos/<name>` → `<name>`, `worktrees/<repo>/<slug>` → `<repo>--<slug>` (so
`worktrees/perpetuals/oracle-fix` → `perpetuals--oracle-fix`). Querying the wrong alias
returns another tree's code — confirm with `list_repos` rather than guessing. If your own
worktree is not listed yet, fall back to the base repo alias (`perpetuals`, `e2e-defi`)
and treat the answer as base-branch code — still far cheaper than reading files.

Never run `gitnexus analyze` by hand: it appends to tracked `CLAUDE.md`/`AGENTS.md` and
writes skills into the repo. Git hooks keep the index current; if it looks stale, say so
instead of re-indexing.

@RTK.md
