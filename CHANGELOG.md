# Changelog

## Unreleased

- Use green Untrack buttons and green move text for selected alerts.

- Replace log alert checkboxes with Track/Tracked toggle buttons.

- Keep the Readying / Casting panel visible while idle and accept monster spell
  preparation messages independently of chat mode numbers.
- Add a saved, optional party/alliance engagement filter using claim ownership,
  combat targets, and packet recipients; include member pets and trusts.

- Use an RTFM Log header with a gear settings button and remove the move counter.
- Append new moves at the bottom with automatic scrolling, and reserve a separate
  visible area for current preparations while browsing the completed log.

- Use numeric child/window flags for the installed ImGui scrolling-window API.

- Save preference changes immediately and flush pending data on unload and zone
  departure; retain saved alerts through reloads, unloads, and logoffs.
- Show a scrollable, resizable log with the last 25 moves by default, newest first,
  retaining rows by count rather than expiring them with time.
- Add a Settings button and `/rtfm config` window with a saved history limit and
  editable enemy/move alert rules, including disabled entries and permanent removal.
- Preserve readable alert labels and migrate existing saved selections.

- Add checkboxes beside completed moves to select persistent monster/move alerts
  that play when a TP move is readied or a spell starts casting.
- Share selections across repeated rows, save them in local preferences, and
  suppress the existing completion sound for selected moves.

- Merge repeated/split completion packets for the same monster and move within
  the result window, combining hit-player names without duplicate rows or alerts.
- Preserve separate executions after a new preparation and distinguish packet
  actors by server ID.

- Prevent duplicate completed moves by using packets as the sole completion
  source and chat only for preparation entries.

- Label affected-player subtitles `Hit:` and hide the line when no players were hit.

- Create completed move rows directly from confirmed packet results, so affected
  players remain visible when matching chat is filtered, injected, or absent.

- Strip complete chat color controls so affected-player results match formatted
  move names; read the action ID separately from the unknown packet field.
- Add Khimaira Dreadstorm/Fossilizing Breath regression fixtures and optional
  `/rtfm debug on|off` result diagnostics.

- Show sorted, deduplicated affected-player names beneath completed monster moves
  and spells in a smaller font, using successful action-packet outcomes.
- Add bounded packet/chat result matching and regression coverage for multi-target
  hits, status effects, misses, resists, pet filtering, and subtitle font sizing.

- Split configuration, parsing/tracking, actor filtering, rendering, and storage
  into focused modules; removed obsolete commented code and unused resources.
- Consolidated window state and commands; support multiword highlight names.
- Match pending actions by both monster and move, allow repeated moves and alerts,
  strip target suffixes, and preserve spell numerals during normalization.
- Bound action lists and run expiration and save maintenance while hidden.
- Normalize encounter rules consistently and cache entity classification.
- Connect curated move descriptions to the overlay.
- Add learning commands, local preferences, unload saves, and recoverable writes.
- Update local editor paths and add Lua regression checks.

## 0.1.0 - 2026-11-01

- Established a fresh repository and semantic-version baseline.
- Preserved the existing addon implementation for the upcoming rebuild.
- Documented the release versioning policy.
