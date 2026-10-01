---
name: spec-writes-testable-contract
tags: [spec, sdd]
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Agent]
runs: 3
max_turns: 15
---

/agentic-sdd:spec A `slugify(title)` utility for blog post URLs: lowercase, ASCII only (strip accents, e.g. "Canción" → "cancion"), words joined by single hyphens, no leading/trailing hyphens, max 60 characters without cutting a word in half, and a clear error for empty input. The feature name is `slugify`.
