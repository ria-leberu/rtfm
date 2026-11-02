# Move descriptions

`catalogue.lua` merges generated upstream descriptions with `reviewed_moves.lua`,
keyed by the monster action ID from the result packet (category 11). Reviewed
records take precedence. Preparation lookup uses the monster's base skill list
where available. Ambiguous same-name variants are omitted unless their visible
metadata agrees, rather than choosing an arbitrary variant.
`moves.lua` provides monster-name-specific overrides and the existing Manticore
and Aw'ghrah descriptions. Override keys use `lib.names.normalize`.

Each entry may contain:

- `name`: exact English move name, required in the shared ID catalogue.
- `damage`: `physical`, `fire`, `ice`, `wind`, `earth`, `lightning`, `water`,
  `light`, or `dark`. Omit it when there is no damage or the type is uncertain.
- `area`: short targeting label such as `AoE`, `Cone`, or `Rear cone`.
- `statuses`: list of native FFXI status IDs, with labels in `statuses.lua`.
- `self_statuses`: possible status applications to the monster itself.
- `note`: a short remaining effect such as `TP reset`.
- `source`: matching upstream mobskill script basename.

Descriptions are shown inline on both preparing and completed move rows. Hover
icons for their meaning. Unknown moves retain their normal log row without
invented descriptions. Damage estimates and severity levels are intentionally
not part of this schema.

## Generated reference catalogue

Start with [monster skill lists](reference/MONSTERS.md), [move catalogue](reference/MOVES.md),
and [coverage](reference/COVERAGE.md).

The initial bulk import contains 2,454 move records, 1,291 monster pool templates,
959 skill lists, 482 spell lists, and 668 status definitions. These are base SQL
records, not a count of every spawn or every possible scripted encounter variant.
Of the moves, 1,077 have an extracted damage type and 686 have possible target
effects. There are 532 missing move scripts; those records retain their IDs and
SQL properties with an explicit missing-script marker.

- `reference/moves.json`: damage/element, possible target and self effects, raw
  targeting code/range/radius, preparation and animation timing, shadows,
  family hints, source script name, and review markers.
- `reference/monsters.json`: pool IDs, aliases, species IDs, base move lists,
  spell-list references, and zone IDs.
- `reference/statuses.json`: status IDs, labels, enum symbols, elements, icon IDs
  where applicable, and custom-effect markers.
- `reference/skill_lists.json` and `spell_lists.json`: named lists and spell level
  ranges; names from local resources where available.
- `reference/review_queue.json`: missing, dynamic, and uncertain fields needing review.
- `reference/manifest.json`: pinned upstream revision, source hashes, local-name
  resource hashes, row counts, and limitations.
- `generated/*.lua`: compact data used by the addon; JSON/Markdown is not loaded
  during gameplay. No network access occurs during gameplay.
- `generated/browser.lua`: searchable monster names/aliases, base moves, and
  family/skill-list groups with known members for scoped alert selection.
- `family_categories.lua`: reviewed generic-family groups used by the menu;
  raw named/NPC/pet/trust lists remain in reference data but are not family categories.
- `family_members.lua`: reviewed local-server memberships omitted from the imported
  pool table, including Moblin Topsman in Moblin list 184.

The NM browser uses the upstream `mobType` notorious bit (`0x02`) defined in
`data/enums/mob_type.yaml`, rather than guessing from a monster's name. The raw
flag and classification are retained in `reference/monsters.json`. This flag may
differ on a customized server. Common-family selections expand across the grouped
base-list IDs; existing individual list selections remain compatible.
`notorious_additions.lua` supplements omissions in the imported pool table using
reviewed source references. King Behemoth uses upstream skill list 479 and its
zone script's explicit HNM identification. The raw imported reference is preserved.
Absolute Virtue is another reviewed addition: its zone script identifies it as an
HNM and its TP list is 329, despite its omission from this imported pool table.
King Behemoth's scripted Meteor is explicitly attached as spell ID 218.
Browser rows are deduplicated by normalized move name while retaining all variant
IDs; conflicting effect metadata is not presented as one arbitrarily chosen version.
`generated/spells.lua` contains spell names from the local client resource set.
The browser attaches SQL spell-list entries to monster templates and merges
reviewed scripted additions; this is not an exhaustive account of scripted casts.

All generated metadata is automated extraction from upstream LandSandBoat. It is
not in-game verification, and it does not establish CatsEyeXI/custom-server behavior.
Direct status applications are recorded as possible effects; conditional branches,
dynamic status expressions, scripted list additions, and encounter overrides are
not fully resolved. Self effects are kept separate from target effects. Only the
well-established radial AoE code is rendered automatically; raw shape codes remain
in the reference for review. Tooltips identify generated effects as unverified upstream data.

Sources are pinned to revision `858bd9d7cb1d4b8a57db9be132282e7505a5bea4`:
`https://github.com/LandSandBoat/server/blob/<revision>/scripts/actions/mobskills/<source>.lua`.
SQL references are the matching `sql/mob_*.sql` files and status symbols come from
`data/status_effects.yaml`. Display names come from local metrics/Windower resources;
see [source notices](THIRD_PARTY.md).

## Rebuilding

Run from the addon directory with Python 3.12+ and an offline upstream checkout:

```text
python tools/build_catalogue.py --source PATH_TO_SERVER --revision COMMIT_SHA --client-resources ../metrics/resources
```

`--client-resources` is optional. The builder uses only Python's standard library,
does not execute source Lua/SQL, and does not download anything. The temporary
source snapshot used here is ignored under `.catalogue-cache/`.

Core Meltdown's element is unresolved upstream, so its entry does not claim an
element. Additional server differences should use monster-specific overrides.
