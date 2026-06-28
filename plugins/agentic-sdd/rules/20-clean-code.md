# Rule: Clean, maintainable, scalable code

- Intention-revealing names; small single-responsibility functions; early returns over deep nesting; no flag args.
- SOLID; domain logic decoupled from frameworks, I/O, and the database (hexagonal). Side effects live at the edges.
- Errors are typed and handled explicitly; validate inputs at boundaries; avoid `any`; make illegal states unrepresentable.
- DRY, but no premature abstraction (YAGNI). Clarity over cleverness. Measure before optimizing.
- No dead/commented-out code, no leftover `console.log`/`debugger`, no magic numbers.
