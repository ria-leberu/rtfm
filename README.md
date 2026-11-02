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

The monster move list contains TP moves only. **Track spells** opens the general
spell menu. Its **Tracked spells** tab shows spells with at least one enabled
casting rule; **Untracked spells** shows the remaining catalogue. Search either
list, select a spell, and track it for any enemy or a specific named enemy.
Saved casting rules can be toggled or removed from that spell's panel.

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

Selections save immediately and survive reloads/logoffs. Settings groups active
move rules by family or named enemy. **Edit** opens its moves; **Remove** removes
all move rules in that group without deleting its spell rules. **Track spells**
opens the separate general spell menu.

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
A yellow arrow icon followed by `Alpha, Zeta`. Names come from incoming action-result packets
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
- `tools/`: offline Python scripts for rebuilding catalogue and effect metadata; not required by Ashita.

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

## Appearance settings

Use the gear in RTFM Log to set log text size from 75% to 200%; Track buttons,
status icons, and affected-player text scale with it. Action backgrounds now use
a much lighter tint. Red denotes offensive actions and light blue denotes
support actions. These settings save immediately and persist across reloads
and logoffs.

Enable **Move, description and affected players on one line** in Settings for a
compact log row. The yellow arrow and player list follows the description, with elapsed
time last. Long rows can be scrolled horizontally. Single-line mode is the default for new settings; disable it to place affected
players beneath the move. This preference survives reloads and logoffs.

Damage icons appear in square brackets and status icons in parentheses. Known
elemental damage spells such as Fire III also display their element icon.

Enemy spells stay in Readying / Casting until their completion packet or a
confirmed casting interruption, with a 15-second timeout. TP preparations retain
their separate 10-second timeout. Timed-out or interrupted casts do not create
completed log entries.

Tracked preparations also show large, pulsing yellow text at the screen center,
including tracked spells while casting. Disable **Flashing center-screen alerts
for tracked moves / spells** in Settings to turn this off. The preference is
saved, and the alert stops when the pending action clears. It remains available
when the main log is hidden and does not intercept mouse or keyboard input.

Log entries expire after 3 minutes by default. Adjust **Log retention (minutes)**
in Settings from 1 to 15 minutes; the 15-minute ceiling also applies to manually
edited preferences. The move-count limit still applies. Timers show seconds with hundredths, such as `119.99s`,
until 2 minutes, then minutes and seconds, such as `2m 00.00s`. Readying and casting timeouts are unchanged.

Center-screen alerts use a black text outline instead of a background panel,
while retaining their yellow wave and pulse animation.

Preparing moves and spells show `-> TargetName` when an incoming preparation
packet identifies a target that the client can resolve. This appears in both
Readying/Casting and center alerts. It is the primary intended target, not a
prediction of everyone an AoE will hit. Unknown targets are omitted; completed
affected-player lists continue to use actual action results.
