---
name: remix-expert
description: Remix / React Router 7 framework-mode expertise — loaders, actions, nested routes, progressive enhancement, and web-standard Request/Response APIs. Load for Remix or React Router framework-mode work; react-expert covers the component layer and loads alongside; nextjs-expert covers Next.js.
---

# Remix (React Router framework mode)

Write server-first, progressively-enhanced TypeScript apps on Remix v2 or React Router 7 framework mode.

## Works alongside, not instead of
This skill owns the **framework layer**: routing, loaders/actions, the server/client boundary. Load `react-expert` **alongside** it for the **component layer** (hooks, local state, accessibility, RTL idioms) — inside a component, react-expert's rules apply; at the route/data boundary, this skill's rules apply. Process skills (`tdd-workflow`, plus superpowers' TDD/brainstorming skills when installed) govern *how* you work; stack skills only supply idioms — neither overrides the other.

## Standards
- **Detect the flavor first:** `@remix-run/*` deps = classic Remix v2; `react-router` v7 + `@react-router/dev` (with `app/routes.ts`) = React Router framework mode — Remix's official continuation with renamed imports. Same idioms either way; never mix the two package families in one app.
- **Route modules are the unit:** `loader` (read) + `action` (write) + `Component` + `ErrorBoundary` + `meta`/`links` per route; compose layouts and data with nested routes.
- **Server/client boundary:** data fetching and secrets live in loaders/actions and `.server.ts` modules — they must never reach the client bundle. No client fetching library for route data: loaders + automatic revalidation are the server-state store.
- **Web standards:** work with `Request`/`Response`, `FormData`, `URLSearchParams`; `redirect()` after successful writes; type loader/action data end-to-end.
- **Progressive enhancement:** mutations go through `<Form>`/`useFetcher`, never onClick + fetch — the flow must work without JS; pending/optimistic UI via `useNavigation`/fetcher state.
- **Every loader/action is a public endpoint:** validate input (Zod) and enforce authz inside it; sessions via cookie session storage.
- **Folder layout:** routes in `app/routes/` (flat-route conventions) or `app/routes.ts` config; shared code in `app/` modules (`components/`, `lib/`, `models/*.server.ts`) — follow the repo's existing structure and `rules/25-structure.md`.

## Testing (TDD)
- Unit: loaders/actions as plain functions — build a `Request`, assert on the `Response`/returned data.
- Component: Jest/Vitest + React Testing Library with `createRemixStub` (`@remix-run/testing`) or `createRoutesStub` (`react-router`) for anything using `useLoaderData`/`useFetcher`; react-expert's RTL rules apply.
- E2E: Playwright — run the critical flow with JS disabled too (progressive-enhancement check); hand the harness to `e2e-tester`.

## Process
Detect the flavor and conventions first → load `react-expert` for component work → tests first → implement → verify the server/client boundary, revalidation after writes, lint, types.
