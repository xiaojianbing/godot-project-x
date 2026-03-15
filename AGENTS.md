# Godot Project Agent Instructions

These instructions apply to the whole repository unless a deeper `AGENTS.md` overrides them.

## Project Context

- This repository is a `Godot` game project, not a `Unity` project.
- Prefer `Godot 4.x` conventions, scene composition, and `GDScript`-first workflows unless the repository clearly adopts `C#` for a subsystem.
- This project targets a `Metroidvania-like` action platformer. Default decisions should support exploration, traversal ability gating, combat readability, and interconnected world progression.
- Preserve existing project structure and naming when extending features.

## Genre Direction

- Treat the game as a `Metroidvania-like`, not a pure stage-based action game or a pure roguelike.
- Favor a connected world structure with unlock-based backtracking, route planning, and clear spatial identity between regions.
- Design progression around ability gates such as double jump, air dash, wall climb, morph-style traversal, key items, switches, and combat skill checks.
- Keep exploration rewards meaningful: traversal upgrades, combat upgrades, map knowledge, shortcuts, health or resource expansions, and optional challenge rooms.
- When proposing systems or content, prioritize the gameplay loop of explore -> fight -> unlock -> revisit -> discover.

## World Design Priorities

- Prefer interconnected levels over isolated stages unless a specific subsystem requires a contained test map.
- Include support for shortcuts, one-way unlocks, hub connections, save rooms, checkpoints, and fast-travel only when it strengthens pacing.
- Make biome and room roles legible: traversal challenge, combat arena, secret route, upgrade room, narrative space, or connector.
- Gate progress clearly enough that players remember blocked paths, but avoid excessive hard-lock confusion.

## Progression And Ability Gating

- Model progression through persistent unlocks and world-state changes rather than disposable run-based upgrades.
- Tie new traversal abilities to both player expression and world readability so that old spaces gain new meaning when revisited.
- When implementing new abilities, consider required hooks for room design, camera framing, enemy interactions, save data, and map markers.
- Avoid adding upgrades that do not open meaningful choices in combat, movement, exploration, or routing.

## Combat And Exploration Balance

- Combat should support room-to-room exploration pacing rather than only long arena encounters.
- Keep recovery, checkpointing, and enemy density aligned with a game that expects repeated traversal through familiar spaces.
- Favor enemies and hazards that reinforce room identity and movement mastery.
- When suggesting difficulty tuning, account for travel friction, save-point distance, and the cost of failed exploration.

## Design References

- When analyzing requests or proposing changes, benchmark against these reference games.
- Movement and platforming references: `Celeste`, `Hollow Knight`, `Prince of Persia: The Lost Crown`. Focus on coyote time, jump buffer, corner correction, acceleration curves, and air control.
- Combat and action references: `Ninja Gaiden`, `Devil May Cry`, `Sekiro`, `Nioh`. Focus on hit stop, cancel windows, input queueing, invulnerability timing, and readable feedback.
- If the user asks to improve game feel, respond with concrete mechanics and tunable parameters rather than vague polish advice.
- If the user suggests a direction that conflicts with genre best practice, explain the tradeoff and recommend a stronger default.

## Architecture Constraints

### Scene Structure

- Build features with reusable scenes and child nodes rather than monolithic all-in-one scenes.
- Keep scene ownership clear: one scene should have one main responsibility.
- Prefer composition through child scenes, resources, and signals over deep inheritance chains.
- Put entry scenes under `scenes/main/`, gameplay scenes under `scenes/levels/`, actor scenes under folders such as `scenes/player/` or `scenes/enemies/`, and shared pieces under `scenes/common/`.

### Scripts

- Prefer `GDScript` unless the repository already standardizes on `C#` for the touched area.
- Keep one primary class per script and keep file names aligned with `class_name` when used.
- Favor small, focused scripts over large god objects.
- Shared helpers belong in `scripts/core/` or `scripts/systems/`; feature-specific logic stays near the owning feature folder.

### State Management

- Manage character behavior with a clear state model. A lightweight FSM or HFSM is preferred for player and enemy action logic.
- Avoid piling large conditional branches into a single controller script when state objects or sub-state handlers would keep behavior clearer.
- Respect interrupt priority for actions such as attack, dash, hurt, knockback, and death.

### Physics

- Use `CharacterBody2D` for character locomotion by default unless the project already uses a custom kinematic controller.
- Run gameplay movement in `_physics_process()` and keep render-only updates in `_process()`.
- Derive jump gravity, jump velocity, acceleration, and deceleration from tunable design targets when possible; avoid unexplained magic numbers.
- Prefer explicit floor and wall checks, coyote time, and jump buffering for platforming characters.

### Input

- Use Godot `InputMap` actions instead of hardcoded key checks.
- Decouple raw input reading from higher-level gameplay decisions when combat, combos, or buffered actions are involved.
- Use input buffering for action-heavy gameplay so combos and cancels remain responsive.

## Code And Debug Rules

- Add Chinese comments for complex logic blocks that would otherwise be hard to understand quickly.
- Use `push_warning()`, `push_error()`, or project logging helpers already present in the repo; do not introduce inconsistent ad hoc logging styles.
- When the user reports a bug, inspect relevant local logs and error output before editing code if such logs exist in the repository.
- After every code change or new script file, proactively check for obvious syntax, scene reference, and configuration issues.

## Godot Asset Safety

- Do not hand-edit complex binary or generated import data inside `.godot/`.
- Avoid manually editing `.import`-generated cache content unless the task explicitly requires it.
- For `.tscn` and `.tres` files, make minimal, precise edits and keep references stable.
- Do not rename or move scenes, scripts, or resources casually because it can break serialized references.

## Directory Conventions

- `addons/`: plugins and editor extensions.
- `assets/`: raw art, audio, shaders, fonts, and UI source assets.
- `autoload/`: global singleton scripts and bootstrapping helpers.
- `data/`: game definitions, config data, and balancing values.
- `docs/`: design and technical documentation.
- `resources/`: reusable `.tres` and `.res` assets.
- `scenes/`: playable and reusable scenes.
- `scripts/`: game logic grouped by domain.
- `tests/`: test scenes and automated test assets.
- `tools/`: editor tools and development-only scripts.

## Working Rules

- For new features, create or update lightweight documentation in `docs/` before implementing when the request is broad or system-level.
- For small bug fixes or tightly scoped tasks, implementation can proceed directly.
- Keep terminology consistent with existing docs and folder names.
- If a requested change carries significant technical or design risk, call out the risk clearly and propose a safer alternative.
- When building or extending test rooms, default to separate themed rooms rather than mixed-purpose spaces.
- Test room construction rule: each room should default to a width of `800`, and each room should validate exactly one gameplay theme or mechanic.
- Separate adjacent test rooms with walls or equivalent blockers so that hazards, enemies, and traversal setups do not interfere across themes.

### Standard Development Flow

- Default to the following delivery sequence for gameplay systems and non-trivial features unless the user explicitly asks to skip or reorder a step.
- Step 1: complete feature discussion and produce or update the corresponding `FeatureSpecs` document.
- Step 2: complete technical design and produce or update the corresponding `ModuleDesign` document.
- Step 3: implement code and complete local self-checks until the changed scope is basically runnable.
- Step 4: complete `TestCase` design for the implemented scope.
- Step 5: execute testing and verification against the agreed design and test cases.
- Steps 3 and 4 may proceed in parallel when it improves iteration speed, but implementation must still remain aligned with the approved feature and module design.
- Do not move into the next major gameplay module until the current module's feature/design/test scope is sufficiently complete and validated, unless the user explicitly changes priority.

## Validation

- After changing scripts, check for obvious parse issues and broken resource paths.
- After changing scenes or project settings, verify that the intended main scene, node paths, and script attachments still make sense.
- If `Godot` CLI is available, prefer targeted validation such as headless project checks before broad testing.
