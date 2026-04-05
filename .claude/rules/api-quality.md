---
paths:
  - "src/api/**"
  - "src/routes/**"
  - "src/handlers/**"
  - "app/api/**"
---

# API Quality Standards

These standards only load when working on API-related files.

## A001: Response format consistency
All API endpoints return a consistent response structure.
Pick one format for the project (e.g. `{ data, error, meta }`) and use it everywhere.
- weight: high
- source: base
- context_acquisition: grep -rn "res.json\|Response(\|jsonify\|JsonResponse" src/api/ src/routes/

## A002: Input validation at boundary
Every API endpoint must validate its input parameters (types, ranges, required fields)
before processing. Use the project's validation library consistently.
- weight: high
- source: base

<!-- 
Example of a standard added from a reject signal:

## A003: OAuth lifecycle completeness
All OAuth integrations must handle: user cancellation, access token expiry, 
refresh token expiry. Token expiry must trigger re-auth flow, never 5xx.
- weight: high
- source: reject @ 2026-04-05, "refresh token expiry returned 500"
- context_acquisition: grep -rn "oauth\|callback\|authorize\|token" src/api/
-->
