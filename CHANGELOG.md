# Changelog

## Unreleased

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
