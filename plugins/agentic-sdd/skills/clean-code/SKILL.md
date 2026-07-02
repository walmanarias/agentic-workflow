---
name: clean-code
description: Use when writing, reviewing, or refactoring code to apply clean-code, SOLID, and maintainability standards for TypeScript/JavaScript. Trigger on "clean code", "refactor", "code smell", "maintainable", "SOLID", "review", or whenever assessing whether code is well-written.
---

# Clean Code Standards

Code is read far more than written. Optimize for the next reader.

## Naming
- Intention-revealing, pronounceable, searchable. Verbs for functions, nouns for values. No abbreviations or `data`/`tmp`/`mgr` vagueness. Booleans read as predicates (`isActive`, `hasAccess`).

## Functions
- Small, do one thing, one level of abstraction. Few parameters (group into an object past 3). No flag arguments — split into two functions. Early returns over nested `if`. No side effects hidden behind innocuous names.

## Structure & SOLID
- **S**ingle responsibility per module/class. **O**pen for extension via composition/interfaces. **L**iskov-safe substitutes. **I**nterface segregation — small focused contracts. **D**ependency inversion — domain depends on interfaces, infrastructure is injected.
- Keep business logic free of framework, I/O, and DB concerns (hexagonal). Side effects live at the edges.
- Organize files into folders by layer and feature/domain — never a flat dump. Follow the ecosystem's idiomatic layout and the repo's existing conventions, and apply design patterns (repository, factory, strategy, ports & adapters) only where they earn their keep.

## Errors & types
- Handle errors explicitly; never swallow. Throw/return typed errors; validate at boundaries. Avoid `any`; model states with discriminated unions; make illegal states unrepresentable.

## Smells to remove
- Duplication, long functions, deep nesting, primitive obsession, feature envy, shotgun surgery, god objects, leaky abstractions, dead/commented-out code, magic numbers, boolean blindness.

## Comments
- Prefer self-explanatory code. Comment the *why*, not the *what*. Delete commented-out code — that's what version control is for.

## Don'ts
- Don't over-abstract for a single use (YAGNI). Don't gold-plate. Prefer clarity over cleverness. Premature optimization is a smell; measure first.

## Definition of clean (checklist)
- [ ] Reads top-to-bottom without surprises
- [ ] Names explain intent; no comments needed to understand *what*
- [ ] Functions small + single-purpose; nesting shallow
- [ ] No duplication; abstractions earn their keep
- [ ] Errors typed + handled; inputs validated at edges
- [ ] Domain logic decoupled from frameworks/IO
- [ ] Covered by behavior-focused tests
