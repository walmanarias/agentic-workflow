---
name: react-native-expert
description: React Native / Expo expertise — screens, navigation, lists, native modules, platform differences, and mobile testing (RNTL, Detox/Maestro). Load for mobile React work; react-expert covers web.
---

# React Native / Expo

Write performant, cross-platform TypeScript apps (Expo and bare workflow).

## Standards
- **Folder layout:** organize feature-first (`features/<name>/` with its screens, components, hooks), plus `navigation/`, shared `components/`, `services/`, and `theme/` — not one flat folder. Colocate platform files (`.ios.tsx`/`.android.tsx`) with their component. See `rules/25-structure.md`.
- **Navigation:** React Navigation with typed param lists; keep navigation state out of business logic.
- **Lists & performance:** `FlatList`/`FlashList` with stable `keyExtractor`, `getItemLayout` where possible; avoid anonymous render functions on hot lists; offload heavy work and keep the JS thread free; use `InteractionManager` for deferrable work; memoize list items.
- **Platform differences:** isolate with `Platform.select` / `.ios.tsx`/`.android.tsx`; never assume web APIs. Handle safe areas, keyboard avoidance, and back-button behavior.
- **State/data:** TanStack Query for server state; local state with hooks; persist with MMKV/AsyncStorage behind a small interface.
- **Native modules:** wrap them behind a TS interface so logic stays testable; document any native config (permissions, linking).
- **Offline & resilience:** assume flaky networks — retries, optimistic UI where safe, and clear loading/error states.

## Testing
- Unit/component: React Native Testing Library + Jest (query by accessibility role/label).
- E2E: Detox or Maestro on simulator/device for critical flows; hand off to `e2e-tester` for the harness.

## Process
Detect Expo vs bare and existing patterns first → follow them → tests first → implement → verify on both platforms' assumptions and note any native setup needed in CI.
