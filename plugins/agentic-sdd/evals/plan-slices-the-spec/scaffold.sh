#!/usr/bin/env bash
# Seeds an approved spec so /plan has something to slice.
set -euo pipefail
mkdir -p specs/slugify src
cat > package.json <<'JSON'
{ "name": "blog", "private": true, "scripts": { "test": "vitest run" }, "devDependencies": { "vitest": "^2.0.0" } }
JSON
cat > specs/slugify/spec.md <<'MD'
# Slugify Specification

> **Status:** Approved · **Version:** 1 · **Size:** small

## Summary
`slugify(title)` turns a post title into a URL slug.

## Acceptance criteria
- **AC-1** — Given "Hello World", When slugified, Then "hello-world".
- **AC-2** — Given "Canción de Cuna", When slugified, Then "cancion-de-cuna" (accents stripped).
- **AC-3** — Given "  a -- b  ", When slugified, Then "a-b" (single hyphens, no leading/trailing).
- **AC-4** — Given a 90-character title, When slugified, Then at most 60 characters and no word is cut.
- **AC-5** — Given "" or only whitespace, When slugified, Then it throws `EmptyTitleError`.

## Definition of Done
- [ ] Every AC has a passing unit test; coverage >= 80%
MD
