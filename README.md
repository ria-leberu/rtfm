# RTFM

An Ashita addon for displaying monster TP moves and spells, with highlighting,
sound alerts, and optional move learning.

## Development status

Version `0.1.0` preserves the existing implementation as the baseline for a fresh
development cycle. The planned rebuild has not yet been implemented.

Development takes place directly in `ashita/addons/rtfm`.

## Versioning

RTFM uses semantic versioning (`MAJOR.MINOR.PATCH`). The version in `rtfm.lua`
is the authoritative addon version.

- During `0.x` development, increment MINOR for features or breaking changes.
- Increment PATCH for backward-compatible fixes within a minor release.
- Release `1.0.0` when the core behavior and configuration are stable.
- From `1.0.0`, increment MAJOR for breaking changes, MINOR for compatible
  features, and PATCH for compatible fixes.
- Record changes in `CHANGELOG.md` and tag releases as `vMAJOR.MINOR.PATCH`.
- Keep unreleased changes under `Unreleased` until the next release is ready.
