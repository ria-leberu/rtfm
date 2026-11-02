# RTFM

An Ashita addon for displaying monster TP moves and spells, with highlighting,
sound alerts, and optional move learning.

## Development status

Version `0.1.0` is the initial baseline. Unreleased development separates action
tracking, actor filtering, rendering, and persistence into modules and fixes
several tracking issues. Detection currently uses English chat text; simultaneous
enemies with identical names cannot be distinguished reliably.

Development takes place directly in `ashita/addons/rtfm`.

## Usage

Load with `/addon load rtfm`.

- `/rtfm`, `/rtfm toggle`, `/rtfm show`, `/rtfm hide`: control the overlay.
- `/rtfm highlight <mob>` and `/rtfm unhighlight <mob>`: change highlighting.
  Multiword names work with or without quotes.
- `/rtfm learn on` and `/rtfm learn off`: control observed TP-move learning.
- `/rtfm help`: list commands.
- `/rtfm debug on` and `/rtfm debug off`: log chat and decoded action results
  when troubleshooting missing affected-player subtitles.

Edit `config.lua` for durations, history limits, filters, default highlights,
and sound rules. Reload the addon after editing it. Alerts fire on completed TP
moves for highlighted monsters. Repeated result lines within 0.5 seconds are
collapsed unless a new preparation was observed. Unknown single-word names still
use a player-name fallback; add exceptions to `guaranteed_mobs` when necessary.

Window visibility, highlight changes, and learning preference persist locally in
`data/preferences.lua` and override their defaults. Learned moves are stored in
`data/mobs_learned.lua`. Saves run every ten seconds when needed and on unload,
including when the overlay is hidden. The previous save is retained as `.bak`.
Learning records observations, not inferred move effects.

Completed monster moves and spells show a smaller line beneath the action:
`Hit: Alpha, Zeta.` Names come from incoming action-result packets
and are deduplicated and sorted. Damage, drains, dispels, and status effects count;
misses, full resists, healing, pets, and trusts do not. No subtitle appears when there are no confirmed player hits or a result
cannot be resolved. Confirmed packet results create completed action rows directly,
including when the corresponding chat is filtered or injected by another addon.

`affected_font_scale` controls subtitle size (default `0.85`), and
`affected_match_window` controls merging of duplicate packet/chat completion rows
(default one second). The subtitle requires an ImGui build supporting sized
`PushFont`. Unresolved entities, unknown result message IDs, and unavailable
custom move names are omitted. Moves with identical names from identically named
enemies retain the text tracker's existing ambiguity.

## Code layout

- `rtfm.lua`: initialization, commands, and event wiring.
- `config.lua`: configuration defaults and encounter rules.
- `lib/actions.lua`: chat parsing, duplicate suppression, and action lifetimes.
- `lib/actors.lua`: player/pet filtering and cached entity classification.
- `lib/affected.lua`: action-result packets and confirmed affected players.
- `lib/names.lua`: shared name normalization.
- `lib/overlay.lua`: ImGui presentation and curated effect descriptions.
- `lib/storage.lua`: deterministic serialization and recoverable saves.
- `data/moves.lua`: curated monster move descriptions.
- `tests/regression.lua`: Lua 5.1/LuaJIT regression checks with host stubs.
- `tests/affected.lua`: multi-target packets, result matching, and subtitle checks.

Run `lua tests/regression.lua` and `lua tests/affected.lua` from the addon directory. In-game verification
should cover actual entity classification, ImGui rendering, sound playback,
multi-target results, hiding/closing the overlay, and reload persistence.
Verify affected-player subtitles with a damaging AoE, a status move, misses and
resists, repeated moves, and two different monsters acting at once.

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
