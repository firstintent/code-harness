# Decisions

Claude writes questions here when human judgment is needed.
Humans reply in the "response" area. Claude checks for resolved decisions periodically.

## Pending

<!-- 
Format:

### D<id> [category] <ISO timestamp>
<Question with options and tradeoffs>
- Option A: ...
- Option B: ...
- Blocks: T<id> (which tasks are waiting on this)
> **Response:**

Categories: architecture, product, criteria, risk, dependency, conflict
-->

## Resolved

<!--
Resolved decisions are moved here with the response and resolution time.

### D001 [architecture] 2026-04-05T10:00 → resolved 2026-04-05T11:30
Database choice: PostgreSQL vs SQLite?
> PostgreSQL. Need concurrent writes.
-->
