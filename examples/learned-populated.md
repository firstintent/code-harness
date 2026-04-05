# Learned

## Build & Test
- Run tests: `pnpm test` (NOT npm test — pnpm workspaces)
- Run single test file: `pnpm test -- --grep "auth"`
- Database migration: `pnpm db:migrate` — must run before tests
- Dev server: `pnpm dev` — port 3000 (frontend), port 8000 (API)
- Type check: `pnpm typecheck` — runs tsc --noEmit
- Lint: `pnpm lint` — eslint + prettier

## Known Pitfalls
- PostgreSQL connection pool max is 20 in dev, silently queues above that. Set PG_POOL_MAX.
- S3 upload in dev uses localstack on port 4566. Must start docker before running tests.
- JWT_SECRET must be at least 32 chars or jsonwebtoken silently falls back to HS256.
- The `src/utils/date.ts` formatDate function has a timezone bug with DST transitions — use dayjs.
- Image resize with sharp: must install vips on Linux (`apt install libvips-dev`), macOS has it via brew.

## User Preferences
- Prefers functional style, avoid classes except for Error subclasses
- Error messages must be user-readable, no stack traces in API responses
- Commit messages in English, conventional commits format (feat:, fix:, chore:)
- Prefers named exports over default exports
- Prefers early returns over nested if/else
- TypeScript strict mode, no `any` types unless explicitly justified with a comment

## Architecture Decisions (from resolved decisions)
- Auth: JWT in httpOnly cookies, stateless for horizontal scaling
- Database: PostgreSQL for concurrent writes + full-text search
- API: flat routes for top-level resources, nested only for true parent-child
- Images: sharp for processing, S3 for storage
- Comments: publish immediately, no approval queue
