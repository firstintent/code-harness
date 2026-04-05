# Inbox

## DRAFT-A003: Pagination parameter consistency
All list API endpoints must use `page` (1-indexed) and `pageSize` (default 20, max 100).
Do not use offset/limit.
- source: uncovered gap @ 2026-04-05, evaluator found 3 endpoints using offset/limit
- suggested_paths: src/api/**, src/routes/**
- suggested_weight: medium
- suggested_file: api-quality.md

## DRAFT-F004: Form validation feedback
All forms must show inline validation errors next to the relevant field,
not a single error banner at the top. Errors must appear on blur, not only on submit.
- source: reject @ 2026-04-04, "settings page shows errors only after submit"
- suggested_paths: src/ui/**, src/components/**
- suggested_weight: medium
- suggested_file: frontend-quality.md

## DRAFT-B006: No hardcoded secrets
No API keys, database URLs, or secrets in source code. All must come from
environment variables or a secrets manager. Grep pattern: anything that looks
like a key/token/password string literal.
- source: uncovered gap @ 2026-04-03, evaluator found S3 bucket name hardcoded
- suggested_paths: (global, no path restriction)
- suggested_weight: high
- suggested_file: base-standards.md
- context_acquisition: grep -rn "sk-\|password.*=.*['\"]" src/
