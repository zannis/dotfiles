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

## Git
- Never commit spec or plan documents (e.g. `docs/superpowers/specs/`, `docs/superpowers/plans/`)
- Never add `Co-Authored-By` lines to commit messages

## Testing
- TDD by default
- Prefer integration tests over unit tests; mock as little as possible
- Integration tests hit real infrastructure (real DB, real Redis) via test containers
- Never mock the database — use real connections (e.g. TimescaleDB)
- Always run tests with `cargo nextest run` — never `cargo test`
- Run integration tests through dotenvx: `dotenvx run -- cargo nextest run`

## Cargo
- Always pass `-q` to cargo commands
