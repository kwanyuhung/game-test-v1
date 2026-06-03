# Pixel Supermarket

A 2D pixel art game built with Godot.

## Engine

- **Godot 4.6** with Forward Plus renderer
- Resolution: 1920x1080, fullscreen
- Pixel-perfect rendering (`snap_2d_transforms_to_pixel=true`)

## Controls

| Action | Keys |
|--------|------|
| Move | WASD / Arrow keys |
| Interact | E |
| Toggle cart | Tab |
| Pause | Escape |

## Architecture

- Main scene: `res://scenes/main.tscn`
- Scripts located in `res://scripts/`
- Key systems: elevator, stairs, floor management, proximity detection

## Credits

Based on collaboration guidelines by yahah
Source: https://www.zhihu.com/question/1979609139266213083/answer/2009429788666909340

---

# CLAUDE.md

## Usage

This file has two layers: Default Rules and On-Demand Modes.
- Default Rules are always active.
- On-Demand Modes are only enabled when the user explicitly requests them, or when the task clearly requires them and the user has confirmed.
- For project/system design, documentation system design, or high-risk changes, clarify with the user whether to enable relevant On-Demand Modes at the start.

## Default Rules

### Work Principles

- For non-trivial changes, explain the approach first.
- When requirements are ambiguous, risky, or have large impact, clarify and get approval before starting implementation.
- Stick to Spec Coding, not Vibe Coding. Plans only include approach, scope, risks, and acceptance criteria — not implementation code.
- Prefer small, incremental steps. Separate implementation from review.
- After completion, you may run `/simplify`; use `/loop` when necessary.

### Coding Constraints

- Use English only in code.
- Comments explain intent, constraints, and boundaries — not development process notes.
- Use concepts, modules, responsibilities, and symbol names to locate code. Don't rely solely on line numbers that can drift.
- Specs should not depend on line numbers for code location.
- Don't pre-abstract, generalize, or expose configuration for unrequested future requirements.

### Godot 4 API Rules

- `TileMap.cell_size` is **read-only** — derived from the TileSet automatically. Do not assign to it.
- `Control.Preset` enum: use `Control.PRESET_*` directly (e.g., `Control.PRESET_TOP_LEFT`). `Control.Preset.PRESET_*` does NOT work.
- `Control.PRESET_BOTTOM_CENTER` and `Control.PRESET_CENTER_BOTTOM` **do not exist** in Godot 4. Use `PRESET_BOTTOM_WIDE` with offset narrowing, or `PRESET_CENTER` with computed viewport-relative offsets.
- `Node.get_viewport_rect()` does not exist. Use `get_viewport().get_visible_rect()` instead.
- **Autoloads are singletons**: `PanelManager` is registered in `project.godot` and accessed directly by name — do NOT `preload()` it or assign to a `const`. Same applies to all other autoloads (e.g., `SaveSystem`).
- **Static methods**: `FloorManagerScript.get_floor_y()` is static, but `FloorConfigScript.get_floor_y()` does not exist. Verify the correct class before calling.
- **Private method calls**: `_private_method()` cannot be called with dot syntax on another object. Use `other_object.call("_private_method")` instead.
- Before setting properties that were writable in Godot 3, check the Godot 4 API docs — many read-only restrictions apply.

### Initialization & Null Safety

- When using `_main.set("property", value)` or similar cross-object state updates, always guard with null checks on the target object. Objects may not be fully initialized when called via deferred calls or signal connections.
- Pattern: if an object `_main` is set via `setup(main)`, add `if _main == null: push_error(...); return` at the start of any public method that accesses it.
- **Deferred calls (`call_deferred`) execute after the current call stack returns** — ensure all initialization is complete before deferred functions can reference uninitialized state.

### Quality & Verification

- In early-stage projects, keep only minimum necessary quality standards: runnable, verifiable, rollbackable.
- Critical paths, high-risk changes, and external interfaces must be verifiable.
- When fixing bugs: reproduce first, then fix, then verify.
- Any "done," "fixed," or "passed" conclusion must include verification method, command, or result summary.
- If verification is not currently possible, explicitly state the reason, risk, and uncovered scope.

### Splitting &沉淀

- Split tasks into loosely coupled, independently verifiable subtasks; use `/batch` when needed.
- Repeated processes with stable boundaries should be refined into Skills, scripts, or checklists.
- Common rules are better refined into docs, tests, or automation — not just left in conversation.

### Collaboration & Correction

- When corrected, verify the issue applies to the current codebase first, then adjust approach.
- External suggestions: verify applicability before deciding whether to adopt.
- For repeated issues, refine into explicit rules, tests, or automated checks.

### Codex Collaboration

- Codex is a supplementary capability, not the default executor. The current Agent is responsible for: main-line progress, requirement clarification, key decisions, first-round implementation, and final acceptance.
- Only use Codex in these scenarios: independent read-only code review, adversarial review, clearly bounded and parallelizable subtasks, or long-running investigation and background continuation. Before delegation, define: goals, constraints, acceptance criteria, and boundaries.
- Do NOT hand off to Codex: requirement clarification, approach convergence, architectural trade-offs, small and focused direct implementation, or main-line tasks requiring ongoing user interaction. Codex results must be integrated and reviewed by the current Agent.
- Available commands: `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`, `/codex:status`, `/codex:result`, `/codex:cancel` (requires [codex-plugin-cc](https://github.com/openai/codex-plugin-cc))

### Prohibited

- Never use `/init` unless the project explicitly requires it.
- CLAUDE.md must be written for actual project needs — do not use generic templates.
- Do not use development progress descriptors in code comments, commit messages, or PR bodies: FIXED, Step, Week, Section, Phase, AC-x.
- Do not mention AI tool names in code comments, commit messages, or PR bodies: Codex, Claude, Grok, Gemini, etc.
- Do not directly promote external implementation details, external docs, or external skill trees as hard constraints for the current project.

## On-Demand Modes

### Architecture & Evolution Mode

- Applicable when: user requests project or system design with layered structure, stable interfaces, and evolvability; or explicitly requests following an architecture process.
- Prioritize layered design. Different layers maintain separated responsibilities, interacting only through clear, stable interfaces.
- Do not let upper layers depend on lower-layer implementation details. Do not establish unnecessary cross-layer coupling. If coupling is required,收敛 as unidirectional with minimal dependencies.
- Within each layer, prioritize primitive design. Primitives should be: independent, replaceable, composable, and verifiable minimal functional units.
- If the project uses multi-Agent collaboration, design specialized agents and skills per layer with clear responsibilities, inputs, outputs, and boundaries.
- Architectural evolution must be verified incrementally. For each new feature or refactor, confirm it does not break existing interfaces, behavior, or critical paths.

### Agent-Native Documentation Mode

- Applicable when: user requests docs serving both humans and Agents; or explicitly requests Agent-Native documentation system.
- Use two-layer structure to avoid duplication:
  - Canonical skill docs (`.claude/docs/`): detailed, long-term maintained formal content for humans and Agents.
  - Agent-facing index (`.claude/skills/`): routes Agents to correct content. Does not repeat content or require one-to-one correspondence with each document.
- Docs should be readable by both humans and Agents: clearly state capabilities, prerequisites, boundaries, dependencies, interfaces, and typical usage. Avoid implicit context only valid for one audience.
- Only skill docs require frontmatter: type, tags, requires (only hard dependencies).
- When an Agent reads docs, first locate the topic through the index, then read the body. Only recursively read hard dependencies referenced by `requires`; other adjacent or reference docs are read as needed.
- Local docs are the current repository's contract. External resources, external skills, or example implementations are for reference only — they do not override local conventions.
- Quantitative conclusions must include test conditions and scope of application.

### Strict Verification Mode

- Applicable when: changes are high-risk, regression cost is high, or user requires verification at every step.
- Split work into small steps that can be independently verified. After each step completes, verify before continuing to the next.
- For new features, refactors, or fixes, confirm they do not break existing functionality, interfaces, or critical paths.
- If necessary verification cannot be completed, pause further expansion and explicitly state: blockers, risks, and uncovered scope.
