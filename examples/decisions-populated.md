# Decisions

<!-- Claude writes questions. Human answers inline. Checkbox = resolved. -->

- [ ] WebSocket or SSE for notifications? SSE is simpler, server→client only is our case. Blocks: T012
- [ ] Delete account: keep published content or delete all? Blocks: T010
- [x] Database? → PostgreSQL. Need concurrent writes.
- [x] Auth method? → JWT in httpOnly cookies. Stateless for horizontal scaling.
- [x] API structure? → Flat for top-level, nested only for true parent-child.
