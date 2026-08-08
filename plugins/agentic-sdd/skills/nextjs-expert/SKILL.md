---
name: nextjs-expert
description: Next.js App Router expertise — Server/Client Components, server actions, route handlers, rendering/caching strategy, and metadata/SEO. Load for Next.js work; react-expert covers generic React.
---

# Next.js (App Router)

Write performant, correctly-rendered TypeScript apps on the App Router.

## Standards
- **Server vs Client:** default to Server Components; add `"use client"` only when you need state, effects, or browser APIs. Keep client bundles small — push data fetching and secrets to the server. Never import server-only code into client components.
- **Folder layout:** keep `app/` for routing only (route segments with their `loading.tsx`/`error.tsx`, colocated route-specific pieces); put non-route code under `src/` in `components/`, `features/`, `lib/`, and `server/` (server-only) — never dump shared code into `app/`. Match the repo's existing structure — see `rules/25-structure.md`.
- **Data fetching:** fetch in Server Components / route handlers; use the `fetch` cache and `revalidate`/tags deliberately; understand static vs dynamic rendering and when `cookies()`/`headers()` opt you into dynamic. Stream with Suspense for slow data.
- **Mutations:** Server Actions or route handlers with input validation (Zod); revalidate affected paths/tags after writes; protect actions with authz checks (treat them like public endpoints).
- **Route handlers** (`app/api/.../route.ts`) for webhooks/external APIs — validate input, return typed responses, set caching headers intentionally.
- **Performance/SEO:** `next/image`, `next/font`, route-level code splitting, `generateMetadata`, proper `loading.tsx`/`error.tsx`. Watch for waterfalls and over-fetching.
- **State:** server state via fetch/cache or TanStack Query in client islands; URL/searchParams as state where appropriate.

## Testing (TDD)
- Unit/component: Jest/Vitest + React Testing Library for client components; test server logic (actions, handlers, data functions) as plain functions.
- E2E: Playwright for full flows (SSR, navigation, forms/actions) — hand the harness to `e2e-tester`.

## Process
Detect router type and conventions first → keep the server/client boundary clean → tests first → implement → verify rendering mode, caching correctness, lint, types.
