# Move descriptions

`catalogue.lua` contains shared descriptions keyed by the monster action ID from
the result packet (category 11). Names provide a fallback for preparation chat.
`moves.lua` provides monster-name-specific overrides and the existing Manticore
and Aw'ghrah descriptions. Override keys use `lib.names.normalize`.

Each entry may contain:

- `name`: exact English move name, required in the shared ID catalogue.
- `damage`: `physical`, `fire`, `ice`, `wind`, `earth`, `lightning`, `water`,
  `light`, or `dark`. Omit it when there is no damage or the type is uncertain.
- `area`: short targeting label such as `AoE`, `Cone`, or `Rear cone`.
- `statuses`: list of native FFXI status IDs, with labels in `statuses.lua`.
- `note`: a short remaining effect such as `TP reset`.
- `source`: matching upstream mobskill script basename.

Descriptions are shown inline on both preparing and completed move rows. Hover
icons for their meaning. Unknown moves retain their normal log row without
invented descriptions. Damage estimates and severity levels are intentionally
not part of this schema.

Initial coverage: seven Khimaira moves, seven Greater Manticore moves, and six
Aw'ghrah moves. Upstream source for every entry:
`https://github.com/LandSandBoat/server/blob/base/scripts/actions/mobskills/<source>.lua`.
The metadata was checked against upstream scripts during this implementation;
it is not a claim of verified behavior on CatsEyeXI or a customized private server.

Core Meltdown's element is unresolved upstream, so its entry does not claim an
element. Additional server differences should use monster-specific overrides.
