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
- `/rtfm config` or `/rtfm settings`: open or close the configuration window.
- `/rtfm debug on` and `/rtfm debug off`: log chat and decoded action results
  when troubleshooting missing affected-player subtitles.

Edit `config.lua` for durations, history limits, filters, default highlights,
and sound rules. Reload the addon after editing it. Alerts fire on completed TP
moves for highlighted monsters. Repeated result lines within 0.5 seconds are
collapsed unless a new preparation was observed. Unknown single-word names still
use a player-name fallback; add exceptions to `guaranteed_mobs` when necessary.

Window visibility, highlights, alert rules, history limit, and learning preference
persist locally in `data/preferences.lua` and override their defaults. Preference
changes save immediately; pending data also saves on unload and zone departure
(including logout). Learned moves are stored in `data/mobs_learned.lua` and save
every ten seconds when needed. Saving works while the overlay is hidden.
The previous save is retained as `.bak`.
Learning records observations, not inferred move effects.

Click **Track** beside a completed move to play an alert when that monster readies
the move again. Spell entries alert when casting starts. The button changes to a green **Untrack** and the move text turns green; click it to disable
that selected alert. Selections apply to the monster name and move name, so
repeated log entries share the same tracking state and identically named monsters
share the rule. Selections persist after the log entry leaves the history and
across reloads, unloads, and logoffs. Selecting a move does not play a sound immediately.

The scrollable log retains the last 25 completed moves by default, oldest first.
New moves appear at the bottom and scroll older moves upward. You can browse the
history between new moves. The **Readying / Casting** area always remains visible
beneath the history, shows both TP preparations and spell casts, and displays an
idle message when empty. Entries do not fade while pending.
Rows remain readable until replaced by newer moves; the session log starts empty
when the addon loads. Resize the overlay as needed.

Use the gear to the left of **RTFM Log** or `/rtfm config` to review all previously selected
enemy/move pairs, including disabled ones. Enable or disable each rule, use
**Edit** to change its enemy or move name, or **Remove** to delete it permanently.
Edit fields apply with **Save entry**; **Cancel** discards the form changes.
**Moves in log** changes the saved history limit (1–250).

Enable **Only enemies engaged with my party/alliance** in Settings to filter new
log entries, preparations, learning, and alerts. It is off by default and saves
with your preferences. An enemy qualifies when it is claimed by a party/alliance
member, currently in combat targeting a member or their pet, or its result packet
targets one of them. This includes all three alliance parties and trusts in those
parties. Existing history is kept when the filter changes.

This is a client-side engagement estimate, not the server's full enmity list.
Unclaimed enemies whose current target or action recipients are unknown can be
missed. Disable the filter when testing unrelated monsters with GM commands.

Selected preparation alerts use `selected_alert_sound` in `config.lua` (default
`alert.wav` from the addon sounds folder) and work while the overlay is hidden.
Repeated preparation lines do not replay the alert while the action is pending.
Selected moves skip their existing completion sound to avoid alerting twice;
unselected moves retain the existing configured completion-sound rules.

Completed monster moves and spells show a smaller line beneath the action:
`>> Alpha, Zeta <<` Names come from incoming action-result packets
and are deduplicated and sorted. Damage, drains, dispels, and status effects count;
misses, full resists, healing, pets, and trusts do not. No subtitle appears when there are no confirmed player hits or a result
cannot be resolved. Confirmed packet results create completed action rows directly,
including when the corresponding chat is filtered or injected by another addon.
Chat supplies preparation entries only; completed actions come exclusively from
packets to prevent duplicate packet/chat rows.
Repeated or split result packets within the result window merge into one row,
combining their hit lists. A new preparation starts a separate execution.

`affected_font_scale` controls subtitle size (default `0.85`), and
`affected_match_window` controls merging of repeated completion packets
(default one second). The subtitle requires an ImGui build supporting sized
`PushFont`. Unresolved entities, unknown result message IDs, and unavailable
custom move names are omitted. Moves with identical names from identically named
enemies retain the text tracker's existing ambiguity.

Known move descriptions appear on the action line: a sword for physical damage,
an elemental icon for its damage element, a short area label, and native FFXI
status icons. Hover icons for their names. Missing icons fall back to readable
labels. Status icons come from the installed game; elemental/sword assets are
bundled with RTFM. There is no dependency on another addon and no runtime network
lookup. Texture resources are cached and released on unload.

Initial coverage is 20 moves across Khimaira, Greater Manticore, and Aw'ghrah.
See `data/README.md` for catalogue fields and sources. Damage estimates are deferred.

## Code layout

- `rtfm.lua`: initialization, commands, and event wiring.
- `config.lua`: configuration defaults and encounter rules.
- `lib/actions.lua`: chat parsing, duplicate suppression, and action lifetimes.
- `lib/actors.lua`: player/pet filtering and cached entity classification.
- `lib/engagement.lua`: optional party/alliance engagement filtering.
- `lib/affected.lua`: action-result packets and confirmed affected players.
- `lib/alerts.lua`: saved monster/move alert selections.
- `lib/names.lua`: shared name normalization.
- `lib/overlay.lua`: ImGui presentation and curated effect descriptions.
- `lib/descriptions.lua`: ID/name lookup and inline move metadata.
- `lib/icons.lua`: native status and bundled damage icon textures.
- `lib/config_window.lua`: history limit and editable saved alert rules.
- `lib/storage.lua`: deterministic serialization and recoverable saves.
- `data/moves.lua`: curated monster move descriptions.
- `data/catalogue.lua`: shared monster-move descriptions keyed by action ID.
- `data/statuses.lua`: FFXI status ID labels.
- `tests/regression.lua`: Lua 5.1/LuaJIT regression checks with host stubs.
- `tests/affected.lua`: multi-target packets, result matching, and subtitle checks.
- `tests/alerts.lua`: tracking-button interaction and shared selection state.
- `tests/settings.lua`: alert editing, history retention, and disk save/load checks.
- `tests/overlay.lua`: log order, pinned preparations, idle state, and scrolling.
- `tests/engagement.lua`: claims, combat targets, alliance members, and pets.
- `tests/descriptions.lua`: lookup precedence and inline description placement.
- `tests/icons.lua`: native resource loading, caching, fallback, and cleanup.

Run `lua tests/regression.lua` and `lua tests/affected.lua` from the addon directory. In-game verification
should cover actual entity classification, ImGui rendering, sound playback,
multi-target results, hiding/closing the overlay, and reload persistence.
Verify affected-player subtitles with a damaging AoE, a status move, misses and
resists, repeated moves, and two different monsters acting at once.
Run `lua tests/alerts.lua` for tracking-button checks. Verify selected alerts in-game by
tracking a past Khimaira move, forcing that move again, disabling tracking, and repeating.
Run `lua tests/settings.lua` for settings and persistence checks. Verify in-game
that saved rules survive reload, unload/load, and logout/login, and that the history
scrolls after enough completed moves.

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
