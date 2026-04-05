# Tasks

## Active

- [ ] T012: Implement real-time notifications [mode: team, blocked by D007]
      teammates: backend(SSE server), frontend(notification UI), test(E2E tests)
      owns: src/realtime/**, src/ui/notifications/**

- [~] T011: User profile page with avatar upload [mode: single, claimed: A, since: 2026-04-05T14:30]
      owns: src/ui/profile/**, src/api/profile.py

- [ ] T010: Account deletion with data export [mode: single, blocked by D006]
      owns: src/api/account.py, src/services/export.py

- [ ] T009: Add rate limiting to all public endpoints [mode: swarm]
      15 endpoints, each independent

## Backlog

- T013: Full-text search with Postgres tsvector [mode: single]
- T014: Admin dashboard [mode: parallel]
      subtasks:
        - api: Admin CRUD endpoints (~10 min)
        - ui: Admin panel components (~10 min)
        - auth: Role-based access control (~10 min)
- T015: Data export as CSV/JSON [mode: single]
- T016: Email notification system [mode: single]

## Done

- [x] T001: Project scaffold with routing [done: A, at: 2026-04-01T10:30]
- [x] T002: User authentication with JWT [done: A, at: 2026-04-01T15:20]
- [x] T003: Article CRUD [done: A, at: 2026-04-02T09:45]
- [x] T004: Comment system [done: B, at: 2026-04-02T14:00]
- [x] T005: Image upload to S3 [done: A, at: 2026-04-03T11:15]
- [x] T006: Pagination for all list endpoints [done: B, at: 2026-04-03T16:30]
- [x] T007: User settings page [done: A, at: 2026-04-04T10:00]
- [x] T008: Password reset flow [done: B, at: 2026-04-04T14:45]
