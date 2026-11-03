# Development

Work takes place directly in `ashita/addons/rtfm`. Load with
`/addon load rtfm`; use `/rtfm reload` after edits.

## Code map

| Area | Files |
|---|---|
| Startup, commands, events and saves | `rtfm.lua`, `config.lua` |
| Action lifetimes and packet decoding | `lib/actions.lua`, `lib/affected.lua`, `lib/timing.lua`, `lib/preparation_bar.lua` |
| Actor and engagement filters | `lib/actors.lua`, `lib/engagement.lua` |
| Saved tracking rules and catalogue | `lib/alerts.lua`, `lib/catalogue_browser.lua` |
| Log, Settings and catalogue UI | `lib/overlay.lua`, `lib/config_window.lua`, `lib/browser_window.lua` |
| Center alert animation | `lib/center_alert.lua` |
| Effects, icons and compact text | `lib/descriptions.lua`, `lib/icons.lua`, `lib/icon_buttons.lua`, `lib/display_text.lua`, `lib/appearance.lua`, `lib/row_layout.lua` |
| Sound selection, files and UI | `lib/sounds.lua`, `lib/sound_files.lua`, `lib/sound_window.lua` |
| Normalization and storage | `lib/names.lua`, `lib/storage.lua` |
| Catalogue records and provenance | [data guide](../data/README.md) |

## Local state

`data/preferences.lua` holds visibility, Settings, tracking rules and sound
assignments. Changes save immediately and on unload or zone departure.
`data/mobs_learned.lua` stores optional observations and saves periodically when
dirty. Both retain `.bak` recovery files. Learning records names, not effects.

Defaults live in `config.lua`; saved preferences override them. User audio belongs
in `sounds/`. Keep user data and audio out of commits.

## Catalogue tools

`tools/` contains offline Python builders, not addon runtime dependencies:

- `build_catalogue.py`: move, monster, skill-list and status records.
- `build_action_roles.py`: offensive/support classifications.
- `build_spell_statuses.py`: harmful spell statuses, damaging-spell elements and base cast times.

See [rebuild commands](../data/README.md#rebuilding). Never present extracted
upstream data as confirmed behavior on a custom server.

## Releases

Use semantic versions: `MAJOR.MINOR.PATCH`. `addon.version` in `rtfm.lua` is the
source of truth; keep unreleased work under **Unreleased** in the changelog.

- During `0.x`, bump MINOR for features or breaking changes and PATCH for fixes.
- From `1.0.0`, bump MAJOR for breaking changes, MINOR for features, PATCH for fixes.
- Bump once when preparing a release, date its changelog section, and tag
  `vMAJOR.MINOR.PATCH`. Commits and merges do not each require a version bump.

The declared version remains `0.1.0`; subsequent development is unreleased.
