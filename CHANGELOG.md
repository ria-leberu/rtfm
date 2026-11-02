# Changelog

## Unreleased

- Replace the center-alert background panel with a black text outline.

- Expire log entries after a configurable 3 minutes by default, capped at 15.
- Show explicit timer units: 119.99s, switching to 2m 00.00s at 2 minutes.

- Remove color vision presets and Attack/Support labels. Group Settings move
  rules by tracked family or enemy, with Edit and Remove actions.
- Route Track spells to the general spell menu with Tracked and Untracked tabs
  and editable saved casting rules.

- Animate center alerts with a per-character wave over a dark translucent panel.

- Add configurable, persistent center-screen flashing alerts for tracked
  readied moves and spells, following pending-action completion and timeouts.

- Use bundled blue Bind and green Terror status icon variants.

- Replace the affected-player HIT>> prefix with a scalable drawn arrow icon.

- Keep casts pending for up to 15 seconds, clearing on confirmed completion or
  interruption packets/messages without creating false completed entries.

- Default to single-line rows, add elemental damage spell icons, and group
  damage icons in brackets and status icons in parentheses.

- Add a persistent single-line log option for moves, descriptions and yellow
  affected-player lists, with horizontal scrolling for longer entries.

- Show affected party members as a yellow `HIT>> Name, Name` line.

- Lighten action backgrounds and add persistent log text scaling with proportional
  Track buttons and icons.
- Add color vision palettes and optional Attack / Support labels; alternative
  palettes always include labels and update tracked colors throughout the UI.

- Remove the development test suite and its documentation references.

- Show native status icons beside harmful spells such as Bio, Blind and Sleepga
  during casting and in completed log entries.

- Distinguish offensive actions with red text backgrounds and defensive buffs
  or healing with light blue in the log and preparation area.

- Keep TP moves separate from spells, with a Track spells button showing the
  selected enemy's known and saved spells.
- Add a searchable Add another spell option for missing enemy-specific spells.

- Map Moblin Topsman to the Moblin family and share known common-monster move
  selections between the log and family catalogue, including Frypan.
- Migrate legacy per-common-monster selections while preserving existing explicit
  family choices; keep named-NM and spell scopes separate.

- Highlight the active catalogue tab and add a Spells tab with any-enemy and
  specific-enemy casting alerts, saved scopes, and per-enemy exceptions.
- Show known spell lists with NM moves, including King Behemoth's scripted Meteor.
- Add Absolute Virtue as a reviewed NM omission using its zone script and list 329.

- Remove the catalogue move-list search field; show all moves for the selection.

- Deduplicate catalogue move names while retaining their underlying variant IDs;
  show a variant note instead of arbitrary effects when versions differ.
- Add a reviewed King Behemoth NM entry using its upstream HNM script and skill list.

- Separate the catalogue into 148 common-family categories and 293 source-flagged
  notorious monsters, with 25-entry pages and search.
- Group standard family variants without mixing named boss, pet, trust, or quest
  lists into the family menu; preserve existing saved family selections.

- Add a searchable monster/family catalogue browser in Settings with per-move
  Track/Untrack controls and inline descriptions.
- Persist alias-aware monster selections and family/skill-list alert rules;
  individual monster exceptions override family selections.

- Remove hardcoded monster highlighting, highlight commands, and their legacy
  completion alerts; green styling and alerts now follow saved Track selections.

- Import a pinned upstream reference catalogue with 2,454 moves, 1,291 monster
  templates, 959 skill lists, 482 spell lists, and 668 status definitions.
- Add readable indexes, source hashes, review flags/queue, and a reproducible
  offline builder; preserve unknown and missing-script fields explicitly.
- Use generated descriptions as a baseline beneath reviewed/server overrides,
  resolve preparation variants by monster skill list, and avoid ambiguous matches.
- Distinguish possible self effects from target effects in icon tooltips.

- Show compact move descriptions inline with completed and preparing actions,
  using sword/element damage icons and native FFXI status icons with tooltips.
- Seed an ID-based Khimaira catalogue and expand Manticore/Aw'ghrah metadata
  against upstream sources; omit unknown effects and defer damage estimates.
- Replace the affected-player label with `>> names <<`, shorten elapsed-time
  labels, and allow horizontal scrolling for longer action lines.

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
- Add optional `/rtfm debug on|off` result diagnostics.

- Show sorted, deduplicated affected-player names beneath completed monster moves
  and spells in a smaller font, using successful action-packet outcomes.
- Add bounded packet/chat result matching for multi-target hits and status effects.

- Split configuration, parsing/tracking, actor filtering, rendering, and storage
  into focused modules; removed obsolete commented code and unused resources.
- Consolidated window state and commands; support multiword highlight names.
- Match pending actions by both monster and move, allow repeated moves and alerts,
  strip target suffixes, and preserve spell numerals during normalization.
- Bound action lists and run expiration and save maintenance while hidden.
- Normalize encounter rules consistently and cache entity classification.
- Connect curated move descriptions to the overlay.
- Add learning commands, local preferences, unload saves, and recoverable writes.
- Update local editor paths.

## 0.1.0 - 2026-11-01

- Established a fresh repository and semantic-version baseline.
- Preserved the existing addon implementation for the upcoming rebuild.
- Documented the release versioning policy.
