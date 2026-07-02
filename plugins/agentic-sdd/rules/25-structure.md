# Rule: Project structure & conventions

- Organize by layer and by feature/domain — never a flat dump of files. Group cohesive code into named folders (`domain/`, `application/`, `infrastructure/`, `api/`, or feature folders); keep each layer together and dependencies one-directional (inner layers never import outer ones).
- Follow the ecosystem's idiomatic layout and naming (framework conventions, file/casing conventions, module boundaries) so the tree is predictable. Detect and match the repo's existing structure before adding new folders — extend the pattern, don't fork it.
- One responsibility per folder/module; split a folder when it mixes concerns or grows past comprehension. Colocate tests, types, and helpers with the code they serve. Cross-cutting/shared code lives in a clearly named place (`shared/`, `common/`, `lib/`), not scattered.
- Apply established design patterns and principles deliberately (SOLID, dependency inversion, repository / factory / strategy, ports & adapters) — but only where they earn their keep; no speculative structure (YAGNI).
- Keep the dependency direction clean: domain logic is framework-, I/O-, and DB-free; those concerns live at the edges behind interfaces.
