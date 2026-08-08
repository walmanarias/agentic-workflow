---
name: react-expert
description: React web expertise — components, hooks, state, performance, and React Testing Library tests. Load when implementing or testing React web UI. For Next.js App Router specifics use nextjs-expert; for mobile use react-native-expert.
---

# React (web)

Write accessible, performant, well-tested function components in TypeScript.

## Standards
- Function components + hooks only. Keep components small and presentational where possible; lift data-fetching and side effects into hooks/services.
- **Folder layout:** organize by feature/domain (`features/<name>/` holding its components, hooks, api, types) once the app outgrows a single screen; keep shared primitives in `components/ui/`, cross-cutting hooks in `hooks/`, and helpers in `lib/` — not one flat `components/` dump. Colocate each component with its test and styles. See `rules/25-structure.md`.
- **State:** local `useState`/`useReducer` first; Context for low-frequency global state; reach for a store (Zustand/Redux Toolkit) only when prop-drilling or cross-tree updates justify it. Server state belongs in TanStack Query, not in ad-hoc effects.
- **Effects:** `useEffect` is for synchronizing with external systems, not for deriving state. Derive during render; memoize with `useMemo`/`useCallback` only when profiling shows a need.
- **Performance:** stable keys, avoid inline object/array props on hot paths, split context, `React.memo` at proven boundaries, code-split with `lazy`/`Suspense`.
- **Accessibility:** semantic elements, label controls, manage focus, test by role/text not by test-id.
- **Types:** precise prop types, discriminated unions for variants, no `any`.

## Testing (TDD)
- React Testing Library + Jest/Vitest. Query by role/label/text; assert user-visible behavior. Use `userEvent`, not `fireEvent`, for interactions. Mock network at the boundary (MSW). No snapshot-only tests for logic.

## Process
Read existing components and conventions first → follow the repo's patterns → write/extend tests with `tdd-test-writer` discipline → implement → verify lint/types/tests. Flag accessibility and performance risks explicitly.
