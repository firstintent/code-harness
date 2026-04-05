# Decisions

## Pending

### D007 [architecture] 2026-04-05T14:32
WebSocket vs SSE for real-time notifications?
- WebSocket: bidirectional, server can push, but must maintain connection state
- SSE: unidirectional (server→client), simpler, but reconnection logic needed client-side
- For our use case (notifications are server→client only), SSE is sufficient
- Blocks: T012 (real-time notifications)
> **Response:**

### D006 [product] 2026-04-05T14:15
When a user deletes their account, what happens to their published content?
- Option A: Content stays, author shows "Deleted User"
- Option B: All content deleted with the account
- Option C: Let the user choose during deletion
- Blocks: T010 (account deletion)
> **Response:**

### D008 [criteria] 2026-04-05T15:20
Evaluator found an uncovered gap: pagination parameters are inconsistent across endpoints.
Some use page/pageSize, others use offset/limit.
Suggest adding standard: unify on page/pageSize.
- Accept → write to rules/api-quality.md
- Reject → log as intentional, stop flagging
> **Response:**

## Resolved

### D005 [architecture] 2026-04-04T09:00 → resolved 2026-04-04T09:25
Database: PostgreSQL vs SQLite?
> PostgreSQL. We need concurrent writes and full-text search later.

### D004 [product] 2026-04-03T13:00 → resolved 2026-04-03T13:10
Should comments require approval before publishing?
> No, publish immediately. We'll add moderation later if needed.

### D003 [dependency] 2026-04-02T11:30 → resolved 2026-04-02T11:45
Image processing: use sharp (npm) or Pillow (Python)?
> Sharp. We're already in the Node ecosystem for the frontend build.

### D002 [architecture] 2026-04-01T14:00 → resolved 2026-04-01T14:30
API structure: flat routes (/api/users, /api/posts) or nested (/api/users/:id/posts)?
> Flat for top-level resources, nested only when there's a true parent-child relationship.

### D001 [product] 2026-04-01T10:00 → resolved 2026-04-01T10:15
Auth method: session cookies or JWT?
> JWT in httpOnly cookies. Need stateless auth for horizontal scaling.
