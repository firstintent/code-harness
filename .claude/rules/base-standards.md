# Base Standards

These apply to all code in the project. Each has an id for log.tsv tracking.
No `paths` frontmatter = always loaded into context.

## B001: No dead code
No unused functions, unreachable branches, or large commented-out blocks.
A few lines of commented-out code during active development are acceptable.
Entire commented-out functions or classes are not.
- weight: low
- source: base
- context_acquisition: grep -rn "# TODO\|# FIXME\|# HACK" src/

## B002: Consistent error handling
The project uses ONE error handling pattern. Identify which pattern is used
(try/catch, Result types, error codes, etc.) and enforce it everywhere.
Do not mix patterns. Do not swallow errors silently.
- weight: high
- source: base
- context_acquisition: grep -rn "except\|catch\|\.catch\|raise\|throw\|Error(" src/

## B003: Boundary validation
All external input (API requests, user input, file reads, environment variables)
must be validated before entering business logic. "External" means anything
that crosses a trust boundary.
- weight: high
- source: base

## B004: Critical path tests
Core business logic must have tests covering:
- Happy path (normal operation)
- Main error path (expected failures)
Not every function needs a test. But every user-facing workflow's core logic does.
- weight: medium
- source: base

## B005: Single responsibility
One function/module does one thing. If describing what it does requires "and"
connecting two distinct actions, consider splitting.
This is advisory — don't over-split trivially connected logic.
- weight: low
- source: base
