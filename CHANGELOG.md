# Changelog

## Unreleased

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
