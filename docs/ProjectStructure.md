# Godot Project Structure

This project uses a feature-oriented structure with clear separation between scenes, scripts, resources, and raw assets.

## Top-level layout

- `addons/`: Third-party or custom Godot plugins.
- `assets/`: Source art, audio, fonts, shaders, and UI media.
- `autoload/`: Global singleton scripts and bootstrapping helpers.
- `data/`: Config files and gameplay definitions.
- `docs/`: Design notes, task breakdowns, and technical docs.
- `resources/`: Reusable `.tres` and `.res` data assets.
- `scenes/`: All `.tscn` scenes grouped by purpose.
- `scripts/`: Game logic scripts grouped by domain.
- `tests/`: Automated test assets and test scenes.
- `tools/`: Editor scripts and one-off development tools.

## Scene conventions

- `scenes/main/`: Entry scenes and boot flow.
- `scenes/common/`: Shared scene pieces, helpers, and reusable sub-scenes.
- `scenes/levels/`: Map and level scenes.
- `scenes/player/`: Player character scenes.
- `scenes/ui/`: UI scenes and menus.

## Script conventions

- `scripts/core/`: Core framework code such as state, save, and event systems.
- `scripts/player/`: Player controller, state logic, and combat code.
- `scripts/systems/`: Cross-feature systems such as camera, audio, and interaction.
- `scripts/ui/`: UI logic and menu scripts.

## Recommended next steps

1. Create an autoload game manager under `autoload/`.
2. Build the player root scene under `scenes/player/`.
3. Add a level test scene under `scenes/levels/`.
4. Split raw media imports into the matching `assets/` folders.
