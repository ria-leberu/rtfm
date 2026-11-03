# Changelog

## Unreleased

- Add eight CatsEyeXI Dragonslaying NMs with the requested family templates,
  documented custom effects and a Brjorta alias for Brjota.

- Add a Tracked only catalogue/search filter for enabled moves, spells,
  families and enemies.

- Put catalogue/spell controls and global search first in Settings; group
  appearance, history, alerts and filters into collapsible sections.
- Search enemies, families, NMs, moves and spells across catalogue tabs;
  support persistent spell rules for an NM, a family or all enemies.

- Add all 13 named Domain Invasion bosses and NMs from the CatsEyeXI page,
  with sourced move effects and a corrected Tchakka moveset.

- Add minimize/restore and close controls; minimized mode shows only
  Readying/Casting, and `/rtfm` toggles overlay visibility.

- Save move diagnostics to rotating local text logs, including packet IDs,
  targets, filter decisions, interruptions and preparation timeouts.

- Keep effect descriptions icon-only inline; move area, enmity and other
  written notes to action/icon hover tooltips.

- Add shared Omega status/effect overrides, sourced elemental damage and
  explicit uncertainty notes in both live descriptions and the catalogue.

- Add Proto-Omega and Neo-Omega to the NM catalogue with a shared, phase-complete
  moveset including Pod Ejection and Discharger.

- Group compact affected-player names by party/alliance UI slot order, retaining
  other players separately and showing grouped full names on hover.

- Add a saved option to show all affected players using three-letter names,
  with full names and a count on hover.

- Show matching preparation progress bars beneath active center-screen alerts.

- Place Settings to the right of an enlarged RTFM Log title with matching height.

- Place preparation bars after move/spell text and animate confirmed completions
  upward into the log with a brief destination highlight.

- Replace pending elapsed timers with estimated spell/TP preparation bars,
  using a moving indicator when no reliable duration is available.

- Center-align timers, action/target text and effect icons within each row,
  including smaller affected-player text.

- Keep center banners for 5 extra seconds by default, adjustable from 0–30.
- Align fixed columns as timer, star, speaker and action; use 00:00.0 consistently without a column header.

- Add a scrollable action log with damage/status icons, confirmed affected-player
  lists, primary preparation targets and duplicate-result merging.
- Keep Readying/Casting visible; clear spells on completion, interruption or a
  15-second timeout. Add optional waving center alerts with a black text outline.
- Add persistent family, named-enemy and spell tracking through star controls,
  searchable catalogue pages and Tracked/Untracked spell tabs.
- Add per-move/spell WAV selection, folder listing, Refresh, Preview and master
  mute. Default to `alert.wav`; remove `benediction.wav`.
- Add adjustable text size, single-line layout, optional compact wording and
  collision-safe mob abbreviations. Replace per-action text buttons with icons.
- Add configurable log retention: 3 minutes by default, 15 minutes maximum.
  Timers use minutes, seconds and tenths.
- Add party/alliance engagement filtering, local preferences, optional move
  learning, save recovery and `/rtfm reload`.
- Expand the sourced catalogue with family grouping, deduplicated moves, reviewed
  NM additions and spell metadata. Preserve custom-server verification limits.
- Refactor runtime modules and remove obsolete resources and the development suite.
- Consolidate user documentation, separate development notes and add a screenshot
  capture checklist.

## 0.1.0 - 2026-11-01

- Establish a fresh repository and semantic-version baseline.
- Preserve the original addon implementation for redevelopment.
