# GC Report — 2026-04-05

## Standards Usage (from log.tsv, 11 entries)

| Standard | Triggered | Failed | Missed | Health |
|----------|-----------|--------|--------|--------|
| B001     | 10        | 0      | 0      | ✓ healthy |
| B002     | 9         | 0      | 1      | ⚠ 1 miss — see below |
| B003     | 9         | 1      | 1      | ⚠ 1 miss — tightened context_acquisition |
| B004     | 9         | 1      | 0      | ✓ evaluator caught it |
| B005     | 7         | 0      | 0      | ✓ healthy |
| A001     | 6         | 0      | 0      | ✓ healthy |
| A002     | 2         | 0      | 0      | ✓ healthy (low sample) |
| F001     | 1         | 0      | 0      | ✓ healthy (low sample) |
| F002     | 1         | 0      | 0      | ✓ healthy (low sample) |
| P001     | 2         | 0      | 0      | ✓ promoted to hook |

## B002 Miss Analysis

The miss on T004 (comments): evaluator didn't check src/api/validators/ directory
for error handling patterns. It only checked src/api/routes/.

**Recommendation:** Update B002 context_acquisition to:
```
grep -rn "except\|catch\|\.catch\|raise\|throw\|Error(" src/ --include="*.py" --include="*.ts"
```
(Changed from src/api/ to src/ to catch all directories)

## Inbox Review

3 items in inbox.md ready for action:

1. **DRAFT-A003 (pagination consistency)** — Ready to move to api-quality.md.
   Has been observed across 3 endpoints. Clear and mechanical.

2. **DRAFT-F004 (form validation feedback)** — Ready to move to frontend-quality.md.
   Came from a direct reject signal.

3. **DRAFT-B006 (no hardcoded secrets)** — Ready to move to base-standards.md.
   High priority. Consider promoting to PreToolUse hook immediately
   since it can be checked with a simple grep.

## Codebase Scan Findings

1. **3 date formatting approaches** found in:
   - src/utils/format.ts: uses `Intl.DateTimeFormat`
   - src/api/serializers.py: uses `strftime`
   - src/ui/components/DateDisplay.tsx: uses `dayjs`
   → Suggest new standard or accept as intentional (Python vs JS difference)

2. **Duplicate email validation** in:
   - src/api/validators/user.py (regex-based)
   - src/ui/components/EmailInput.tsx (HTML5 type=email)
   → Backend regex is stricter than HTML5. Could cause UX confusion.

## Promotion Candidates

- **DRAFT-B006 (no hardcoded secrets)**: can be checked with grep in a PreToolUse hook.
  Mechanical enough to promote immediately.

## Actions Taken

- [ ] Move DRAFT-A003 to api-quality.md (needs human approval)
- [ ] Move DRAFT-F004 to frontend-quality.md (needs human approval)
- [ ] Move DRAFT-B006 to base-standards.md AND promote to hook (needs human approval)
- [ ] Update B002 context_acquisition (needs human approval)
