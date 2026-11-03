# RTFM

An Ashita addon that displays enemy TP moves and spells, their known effects,
and selected visual and sound alerts.

## Quick start

1. Place the `rtfm` folder in `ashita/addons/`.
2. Run `/addon load rtfm`.
3. Click the gear beside **RTFM Log** to open Settings.
4. Click an outlined star beside a move to track it. A green filled star means tracked.

Tracking alerts when a move is readied or a spell starts casting. Click a green
star to untrack. Use the speaker icon to choose its sound.

## Reading the log

Completed actions appear newest at the bottom. **Readying/Casting** stays visible
below the history. The upper-right minimize button shows only Readying/Casting;
click the restore button to bring history back. **X** hides the overlay, and
`/rtfm` toggles it back on or off. The minimized state survives reloads.

Readying/Casting stays visible
below the history, including when idle. Completed rows use fixed columns: timer, star, speaker, then action text. Timers, text
and effect icons share a horizontal centerline, including smaller player names.

| Display | Meaning |
|---|---|
| Light red background | Offensive action |
| Light blue background | Defensive buff or healing |
| Green action text | Tracked move or spell |
| Icons in `[ ]` | Physical or elemental damage |
| Icons in `( )` | Possible status effects; hover for names |
| Yellow arrow and names | Players confirmed affected by completed results |
| `-> Name` while preparing | Packet-confirmed primary target, not everyone an AoE may hit |
| `00:00.0` | Elapsed minutes, seconds and tenths; hover for the format |

The default layout keeps the move, description and affected players on one line.
Long rows scroll horizontally. Disable the single-line setting to put affected
players on a full-width second line, starting beneath the timer. No affected-player list appears when none is confirmed.

Preparing rows show a progress bar immediately after the move/spell text. Spell resource
cast times and upstream TP preparation times provide base estimates. Server
changes, Fast Cast and latency can alter them. Unknown durations use a moving
indicator; a full bar waits for a confirmed result or the existing timeout.
Hover the bar for details. Confirmed completions use a brief upward text glide
and a fading highlight on the new log row; interruptions and timeouts do not.

Tracked preparations also show large, waving yellow text with a black outline
at screen center, with the same preparation progress bar beneath each active
alert. The bar disappears once preparation ends. Banners remain for 5 extra seconds after a preparation clears;
adjust **Keep banner after preparation (seconds)** from 0–30 in Settings. During
that extension they show the action name without claiming it is still preparing.
Disable center alerts independently of sound. Pending spells
clear on completion, interruption or a 15-second timeout; TP moves time out after
10 seconds.

## Settings

| Setting | Default / range |
|---|---|
| Enable sound alerts | On; also controls previews |
| Flashing center-screen alerts | On |
| Keep banner after preparation | 5 seconds; adjustable from 0–30 |
| Single-line log | On |
| Compact log text | Off |
| Show all affected names as 3 letters | Off; hover shows full names |
| Log text size | 100%; adjustable from 75–200% |
| Moves in log | 25; adjustable from 1–250 |
| Log retention | 3 minutes; adjustable from 1–15 minutes |
| Only enemies engaged with my party/alliance | Off |

Both the move-count and time limits apply. Settings and selections save locally
and survive reloads and logoffs; the displayed history starts empty after reload.

**Compact text** shortens repeated wording and mob names: `Moblin Topsman readies
Frypan` becomes `M. Topsman ~ Frypan`; `Boss starts casting Fire III` becomes
`Boss cast~ Fire3`. Hover for full text and effect notes. Area labels, enmity changes and other
written descriptions appear only on hover. Colliding mob abbreviations expand to
full names. Player names, tracking rules and center alerts retain their full text.

**Show all affected names as 3 letters** keeps every confirmed player in the
list while shortening names, for example `Rialia, PartyMember1` -> `Ria, Par`.
Names group as `P1(Ria, Par) | P2(Gam) | P3(Del)` in the client's current
party/alliance slot order. Non-alliance players appear under `Other`. Hover for
full names grouped the same way and the affected count. Matching prefixes stay separate;
this option changes display only and works with either row layout.

The engagement filter uses party/alliance claims, enemy combat targets and action
recipients. It is an estimate, not the server's full enmity list.

## Track families, NMs and spells

Open **Browse families / notorious monsters** in Settings. Search and select a
family or named NM, then use the stars beside its moves. Family rules cover known
catalogue members; named rules can override them. Known common-mob selections in
the log share their family's rule—for example, Moblin Topsman and Moblin Frypan.

Browse and Track spells controls sit at the top of Settings, followed by global
search and tracked groups. Other options are grouped into collapsible sections.
Type a query and press Enter or Search. Catalogue search also searches all
enemies, families, NMs, moves and spells, regardless of the active tab. Results
show their type; move matches open the owning enemy/family and matching moves.
Enable **Tracked only** to limit results and move lists to enabled tracking rules.
It also includes spells tracked for an NM or family. Selecting Untracked spells
turns this filter off.

Settings groups tracked moves by family or named enemy. **Edit** opens its moves;
**Remove** deletes the group's move rules without deleting spell rules.

**Track spells** opens the general spell menu:

- **Tracked spells:** spells with at least one enabled casting rule.
- **Untracked spells:** the remaining spells.

Select a spell, then choose **All enemies**, **Specific NM**, or **Family**.
NM and family scopes have searchable selectors. Family spell rules cover known
catalogue members and remain separate from TP moves. Saved casting rules can be
toggled or removed there. A disabled specific-enemy rule overrides an all-enemies
selection. Catalogue results use 25-entry pages.

## Choose alert sounds

Click a speaker beside a move or spell. The choice applies to that action name
across enemies; TP moves and spells have separate choices. Sound selection does
not enable tracking.

1. Copy Windows-playable WAV files into `rtfm/sounds/` (PCM recommended, up to 32 MB).
2. Open **Manage sounds** or a speaker icon; the window shows the full folder path.
3. Click **Refresh**, select a file, and optionally **Preview** it.
4. For a move or spell, click **Use selected sound**.

**Use default alert.wav** clears a custom choice. Missing custom files fall back
to `alert.wav`. Open the displayed folder path manually in Windows Explorer;
RTFM does not launch folders or browse your drives. User WAV files are ignored
by Git. Turn off **Enable sound alerts** to mute audio while keeping visual alerts.

## Commands

| Command | Action |
|---|---|
| `/rtfm` or `/rtfm toggle` | Toggle the log |
| `/rtfm show` / `/rtfm hide` | Show or hide the log |
| `/rtfm config` or `/rtfm settings` | Toggle Settings |
| `/rtfm reload` | Save pending settings and reload |
| `/rtfm learn on` / `/rtfm learn off` | Record observed TP-move names |
| `/rtfm debug on` / `/rtfm debug off` | Save and print move diagnostics; setting survives reloads |
| `/rtfm help` | List commands |

## Limits and troubleshooting

- Descriptions are sourced metadata, not proof an effect landed. Custom servers
  may change moves, spell lists and effects. No damage estimates are provided.
- Unknown targets, effects or result messages may be omitted. A primary target
  does not predict an AoE's affected players.
- Preparation packets and English chat feed pending rows; completion packets feed
  history. Chat-only events can be ambiguous for identically named enemies.
- Alerts continue while the log is hidden. Disable sound and center alerts in
  Settings if you want both off.
- For missing actions, temporarily disable the engagement filter and use
  `/rtfm debug on`. Logs are saved in `rtfm/logs/rtfm-debug.txt`, with timestamps,
  move packets, target IDs, affected names, filter decisions, interruptions and
  preparation timeouts. Only move-related chat is included. At 5 MB, the file
  rotates to `rtfm-debug-previous.txt`. Share both files when reporting an issue.
  Turn diagnostics off with `/rtfm debug off` when finished.

RTFM reads incoming game data, draws locally, plays local audio and saves local
files. It does not inject game packets or perform gameplay actions.

## More documentation

- [Catalogue data and sources](data/README.md)
- [Development and versioning](docs/DEVELOPMENT.md)
- [Screenshot checklist](docs/SCREENSHOTS.md)
- [Changelog](CHANGELOG.md)
