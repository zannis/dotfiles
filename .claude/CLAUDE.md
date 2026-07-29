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
- Never add `Co-Authored-By` lines to commit messages
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
