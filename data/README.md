# Catalogue data

RTFM bundles upstream metadata plus reviewed overrides. It does not download
catalogue data during gameplay. Unknown effects stay unspecified; damage
estimates are not included.

## Lookup and overrides

`catalogue.lua` combines `generated/moves.lua` with `reviewed_moves.lua`, keyed
by monster action ID. Reviewed records win. `moves.lua` supplies monster-specific
overrides using keys normalized by `lib.names.normalize`.

Completed TP moves use packet IDs. Preparations use known monster lists and
unambiguous names. Conflicting same-name variants are not guessed. Spell IDs
are separate from TP-move IDs.

| Field | Content |
|---|---|
| `name` | Exact English move name |
| `damage` | `physical`, an element, `magical` (unknown element) or `unknown` (unresolved type) |
| `area` | Short targeting label, such as `AoE` or `Cone` |
| `statuses` | Possible effects on targets, as native status IDs |
| `self_statuses` | Possible effects on the acting monster |
| `note` | Other concise effects, such as `TP reset` |
| `source` | Upstream mobskill script basename |
| `reference_note` | Source differences or uncertainties shown on hover |

Omit uncertain fields. Tooltips identify automated data as unverified; an icon
indicates a possible effect, not confirmation it landed.

## Files

| Location | Purpose |
|---|---|
| `generated/` | Runtime Lua tables: moves, monsters, browser lists, spells, statuses and action roles |
| `reviewed_moves.lua`, `reviewed_statuses.lua` | Reviewed replacements for generated records |
| `family_categories.lua`, `family_members.lua` | Family groups and known membership corrections |
| `notorious_additions.lua` | Reviewed NM omissions, including King Behemoth and Absolute Virtue |
| `spell_statuses.lua` | Additional status mappings for enemy spell variants |
| [reference/MONSTERS.md](reference/MONSTERS.md), [reference/MOVES.md](reference/MOVES.md) | Human-readable indexes |
| [reference/COVERAGE.md](reference/COVERAGE.md) | Import coverage and known gaps |
| `reference/*.json` | Detailed source records, skill/spell lists and review queue |
| [reference/manifest.json](reference/manifest.json) | Source revision, hashes, counts and limitations |

The base import contains 2,454 moves, 1,291 monster templates, 959 skill lists,
482 spell lists and 668 statuses. These counts do not represent every spawn or
scripted encounter. Of the moves, 532 have missing source scripts.

Common-family groups combine base-list variants. NM classification uses upstream
flags plus reviewed additions. Move rows deduplicate names while retaining
variant IDs; differing effects are marked as varying by version. Monster spell
lists can omit script-driven casts.

`generated/preparation_times.lua` stores upstream TP preparation seconds by
move ID. `generated/spell_cast_times.lua` stores unambiguous base cast times by
spell name; packet-specific Ashita resources take precedence. These estimate
progress only and do not determine completion or model Fast Cast/server overrides.

## Sources and limits

The base catalogue is pinned to LandSandBoat/server revision
`858bd9d7cb1d4b8a57db9be132282e7505a5bea4`. The manifest records SQL, mobskill and
status source hashes. Names and spell metadata come from local metrics/Windower
resources; see [source notices](THIRD_PARTY.md). Icon provenance is documented
[separately](../assets/icons/README.md).

Static extraction does not resolve every conditional effect, dynamic expression
or scripted list change. Custom-server behavior, including CatsEyeXI, requires
separate verification. Keep confirmed server-specific differences in reviewed
overrides rather than assuming retail or upstream behavior.

## Rebuilding

Run from the addon directory with Python 3.12+, an offline upstream checkout and
the indicated local resources:

```text
python tools/build_catalogue.py --source PATH_TO_SERVER --revision COMMIT_SHA --client-resources ../metrics/resources
python tools/build_action_roles.py --source PATH_TO_SERVER --spells ../metrics/resources/spells.lua
python tools/build_spell_statuses.py --spells ../metrics/resources/spells.lua
```

The catalogue builder's `--client-resources` argument is optional. All builders
use Python's standard library; they do not execute source Lua/SQL or download
files. `.catalogue-cache/` holds ignored source snapshots. Review generated diffs
and the review queue before accepting a rebuild.

Proto-Omega and Neo-Omega use a shared reviewed catalogue mapping: upstream
skill lists 727 (normal), 1188 (standing) and 1189 (final), plus Pod Ejection
(1532) and Discharger (1537). Neo-Omega shares this mapping by user request.
Each NM retains separate tracking choices. Reviewed additions also participate
in name-based description and preparation-time lookup.

See [Omega overrides](OMEGA.md) for their shared effects, elemental mappings,
uncertainties and retail/upstream differences.

## CatsEyeXI encounter additions

See [DOMAIN_INVASION.md](DOMAIN_INVASION.md) for the reviewed Domain Invasion
roster, effect sources and unverified retail fallbacks.

See [DRAGONSLAYING.md](DRAGONSLAYING.md) for the eight Dragonslaying NMs,
family templates, custom effects and unresolved action mappings.
