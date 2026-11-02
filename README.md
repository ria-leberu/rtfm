# RTFM

An Ashita addon for displaying monster TP moves and spells, with selectable
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
- `/rtfm learn on` and `/rtfm learn off`: control observed TP-move learning.
- `/rtfm help`: list commands.
- `/rtfm config` or `/rtfm settings`: open or close the configuration window.
- `/rtfm debug on` and `/rtfm debug off`: log chat and decoded action results
  when troubleshooting missing affected-player subtitles.

Edit `config.lua` for durations, history limits, filters,
and sound rules. Reload the addon after editing it. Alerts fire when selected monster moves are readied. Repeated result lines within 0.5 seconds are
collapsed unless a new preparation was observed. Unknown single-word names still
use a player-name fallback; add exceptions to `guaranteed_mobs` when necessary.

Window visibility, alert rules, history limit, and learning preference
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

Choose **Browse families / notorious monsters** in Settings to open the catalogue.
**Common families** shows 148 reviewed generic categories, combining variants
such as the three Crab base lists. **Notorious monsters** includes source-flagged
NM entries and reviewed additions for omissions such as King Behemoth. Pet, trust, quest-NPC, and named-boss
skill lists are not mixed into the common-family menu.

Search for an entry and select it on the left. Lists show 25 entries per page
with **Previous / Next** controls. The right side shows its known moves and inline effect icons;
use **Track / Untrack** beside each move to change its alert. All moves for the selected entry are shown without a separate move search.
Each move name appears once, even when multiple underlying move IDs share it.
When those versions have different effect data, the row says **varies by version**.
The active catalogue tab is highlighted green.

Use the **Spells** tab to search for a spell such as **Breakga**, **Sleepga**, or
**Meteor**. Select it, then choose **Track** under **Any enemy casting this spell**,
or enter a name under **Specific enemy** and track only that caster. Spell alerts
play when casting starts, not when the spell completes. Existing blacklist and
party/alliance engagement filters still apply; player/trust casts are excluded.
Per-enemy disabled spell rules override an any-enemy spell selection.

The monster move list contains TP moves only. Its **Track spells** button opens
that enemy's known spells and any spells you previously added. Use **Track /
Untrack** beside a spell to save an alert for that enemy; King Behemoth's list
includes **Meteor**. Duplicate spell IDs with the same name share one choice.

Choose **Add another spell** to search the full spell catalogue, then **Add &
track** to save a missing spell and return to the enemy's spell list. Saved
additions remain available even when untracked. From a family entry, enter a
specific enemy name (for example, Moblin Topsman) to see and track its spells.
These choices apply to that enemy, rather than the whole family.

Monster selections include the template's known aliases. Family selections cover
the category's standard skill-list variants and apply to their known catalogue member
names; this is not a guarantee of every biological family member or custom-server
spawn. Common-monster log controls use the same rule as their family catalogue
when membership and move are known. **Moblin Topsman → Frypan** and **Moblin →
Frypan** are one saved family selection, and either control toggles it. Legacy
common-monster selections migrate to family rules; an existing explicit family
choice wins if old preferences disagree. Named NMs, unknown custom moves, and
spells retain their specific scopes. Individual named-monster rules still take
precedence over family rules.

Both scopes save immediately and survive reloads/logoffs. Saved family entries
are marked **Family:** and can be enabled, disabled, or removed there; select
different family moves through the browser. Existing per-monster entries retain
their Edit controls.
Any-enemy spell rules are marked with **Any enemy** and **(spell)**; toggle or
remove them there, and choose different spells through the catalogue. All spell
rules save immediately and restore across reloads/logoffs.

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
Only saved Track selections enable move alerts; there are no hardcoded monster
highlights or completion-sound rules.

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

The catalogue now includes 2,454 upstream move records and base mappings for
1,291 monster templates, with possible effects and damage types where directly
extractable. Reviewed Khimaira/Manticore/Aw'ghrah entries and local monster
overrides take precedence. Generated data is identified in icon tooltips and
remains unverified on custom servers. See `data/README.md` and the readable
`data/reference/MONSTERS.md` / `MOVES.md` indexes. Damage estimates remain deferred.

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
- `lib/catalogue_browser.lua`: searchable monster/family/move catalogue model.
- `lib/browser_window.lua`: catalogue selection and scoped alert controls.
- `lib/storage.lua`: deterministic serialization and recoverable saves.
- `data/moves.lua`: curated monster move descriptions.
- `data/catalogue.lua`: shared monster-move descriptions keyed by action ID.
- `data/generated/`: compact imported move, monster, and status indexes.
- `data/family_categories.lua`: reviewed common-family grouping and variant IDs.
- `data/notorious_additions.lua`: reviewed named NM additions with source references.
- `data/reference/`: sourced JSON/Markdown catalogue, provenance, and review queue.
- `data/reviewed_moves.lua`: reviewed descriptions overriding generated data.
- `data/statuses.lua`: FFXI status ID labels.
- `tests/regression.lua`: Lua 5.1/LuaJIT regression checks with host stubs.
- `tests/affected.lua`: multi-target packets, result matching, and subtitle checks.
- `tests/alerts.lua`: tracking-button interaction and shared selection state.
- `tests/settings.lua`: alert editing, history retention, and disk save/load checks.
- `tests/overlay.lua`: log order, pinned preparations, idle state, and scrolling.
- `tests/engagement.lua`: claims, combat targets, alliance members, and pets.
- `tests/descriptions.lua`: lookup precedence and inline description placement.
- `tests/icons.lua`: native resource loading, caching, fallback, and cleanup.
- `tests/catalogue_lookup.lua`: monster-specific lookup and ambiguous-name handling.
- `tests/test_catalogue_builder.py`: offline importer and generated-data validation.
- `tests/browser.lua`: catalogue selection, aliases, family exceptions, and persistence.

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

Offensive actions in the log and Readying / Casting area have a red text
background; defensive buffs and healing use light blue. Tracked actions keep
their green text. Classification uses local target/effect metadata; unknown
actions remain uncolored, and custom-server changes may differ.

Harmful spells with known status metadata (including Bio, Blind and Sleepga)
show the same native status icons as TP moves during casting and in the log.
Icons describe possible effects, including effects that may be resisted.
