# MODE: BUILDING — IMPLEMENT ONE TASK FROM THE PLAN

## Orientation

0a. Study `specs/*` with up to 500 parallel Sonnet-level subagents to understand the flight controller requirements.
0b. Study `@REV-009-plan.md` to see the current prioritized task list.
0c. For reference, atopile source code is in `src/*.ato`. Each spec maps 1:1 to a source file.
0d. Use only 1 subagent for build and test operations (e.g. `ato build`).

## Your Task

1. Read `@REV-009-plan.md` and select the single highest-priority 
   incomplete task. State the task ID and description before starting any work.

2. Before writing any code, search the codebase to understand the current state 
   relevant to this task. **Do not assume code is missing — search and read first.** 
   Use grep and file reads to confirm what exists and what doesn't.
   - You may use up to 500 parallel Sonnet-level subagents for searches/reads, and only 1 subagent for builds and tests. Use Opus-level subagents when complex reasoning is needed (debugging, architectural decisions).

3. Implement the task completely. This means:
   - Full, production-quality implementation (no stubs, no placeholders, no TODOs)
   - Follows patterns established in `@AGENTS.md` and existing code
   - Includes appropriate error handling and edge cases per the spec
   - Code is clean, well-structured, and would pass professional review

4. Run `ato build` to verify the design compiles. This is the only validation
   — Fix any build errors before proceeding.
   - Document WHY design decisions were made in code comments (pin selections,
     constraint rationale — future iterations won't have your current context)

5. If `ato build` errors are unrelated to your work and quick to fix, fix them.
   If they require significant work, document them in `@REV-009-plan.md`
   as a new task item — do not derail your current task.

6. Once `ato build` passes:
   - Update `@REV-009-plan.md`: mark your task complete, note any
     discoveries or new tasks uncovered during implementation
   - Update `@AGENTS.md` if you learned something operational (e.g., an atopile
     pattern that works differently than expected)
   - Stage and commit: `git add -A && git commit -m "<descriptive message>"`

7. When you discover issues, immediately update `@REV-009-plan.md` with your findings using a subagent. When resolved, update and remove the item.

## Quality Standards

- Write code that is **high-performance and faithful to the specification**. 
  Do not take shortcuts for the sake of getting something working quickly. 
  The spec defines the target behavior — match it precisely.
- Prefer clarity over cleverness. Future iterations (and humans) need to 
  understand this code.
- Follow the project's established atopile patterns. Reuse existing modules
  and interfaces rather than creating ad-hoc alternatives.
- When you face an ambiguity not covered by the spec, make the conservative 
  choice and document your decision in a code comment.

## Scope Discipline

- **Only implement the one task you selected.** Resist the urge to fix 
  adjacent things, refactor unrelated code, or "quickly add" another feature.
- If you notice bugs, missing features, or improvement opportunities outside 
  your current task, add them to `@REV-009-plan.md` and move on.
- The only exception: if your task literally cannot work without fixing 
  something else first, fix the blocker as part of your task and document it.

## Anti-Patterns to Avoid

- Do NOT create placeholder or minimal implementations. Implement fully or 
  not at all. If a task is too large for one pass, it should be split in the 
  plan — not half-implemented.
- Do NOT skip running `ato build`. A passing build is your proof of correctness, and future iterations' protection against regressions.
- Do NOT mark a task complete without a passing `ato build`.
- Do NOT modify specs unless you find a genuine inconsistency (and if you do, 
  document the change clearly).
- Keep `@AGENTS.md` operational only - status updates and progress notes belong in `@REV-009-plan.md`. A bloaded AGENTS.md pollutes every future loop's context.
