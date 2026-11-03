# Omega move overrides

Proto-Omega and Neo-Omega share `omega_moves.lua`. These overrides apply only
to those two names and are used by both the catalogue and live descriptions.
Numeric damage estimates are omitted. HP-cut mechanics remain descriptive notes.

| Move | Damage | Target effects / other behavior |
|---|---|---|
| Hyper Pulse | Physical per retail reference | AoE Gravity and short Bind |
| Rear Lasers | Type/element unresolved | Rear target; Petrification |
| Ion Efflux | Magical; element unresolved | Cone Paralysis |
| Stun Cannon | Thunder in upstream implementation; unverified | Cone Paralysis |
| Target Analysis | Attribute drain | AoE STR/DEX/VIT/AGI/INT/MND/CHR Down; absorbed by shadows |
| Floodlight | Light in upstream implementation | AoE Blind and Silence per supplied list; bypasses shadows |
| Pod Ejection | None listed | Summons Gunpod |
| Colossal Blow | Physical | HP cut, knockback, enmity reset; bypasses shadows |
| Laser Shower | Light in upstream implementation | Cone Defense Down; positioning affects breath damage |
| Guided Missile | Physical | Target-centered AoE; shadows absorb; Bind unconfirmed |
| Guided Missile II | Magical; element unresolved | Target-centered AoE; bypasses shadows; Bind unconfirmed |
| Pile Pitch | Physical | HP reduced to 10%, Bind and enmity loss; bypasses shadows |
| Discharger | Self buff | Shock Spikes and Magic Shield |

Unknown damage types/elements display `[?]` rather than an invented elemental
icon; hover explains the uncertainty. Area and other written notes, including
unconfirmed Missile Bind, appear only on hover rather than as confirmed icons. Effects are possible outcomes, not proof they land.

## Reference differences

The user-supplied retail list takes precedence for the requested ailments:

- Hyper Pulse's [retail page](https://ffxiclopedia.fandom.com/wiki/Hyper_Pulse)
  describes physical damage. The pinned upstream script uses magical damage
  with an unresolved element.
- Floodlight's supplied list specifies Blind and Silence. Pinned upstream uses
  Flash and Silence instead.
- Rear Lasers and Ion Efflux include reported damage in the retail descriptions;
  pinned upstream currently implements status application only.
- Stun Cannon's upstream Thunder element is explicitly marked for verification.
- Guided Missile II's element is unresolved upstream. Neither missile's possible
  Bind is promoted to a confirmed effect.

These differences are included in relevant hover tooltips. They do not establish
which implementation a customized server uses.

## Sources

The supplied [Proto-Omega](https://ffxiclopedia.fandom.com/wiki/Proto-Omega)
move list and linked ability descriptions provide the retail effects. Entries
are expressed as concise facts rather than copied article text.

Implementation cross-checks use the local LandSandBoat snapshot at
`858bd9d7cb1d4b8a57db9be132282e7505a5bea4`, under
`scripts/actions/mobskills/`: `hyper_pulse.lua`, `rear_lasers.lua`,
`ion_efflux.lua`, `stun_cannon.lua`, `target_analysis.lua`, `floodlight.lua`,
`colossal_blow.lua`, `laser_shower.lua`, `guided_missile.lua`,
`guided_missile_ii.lua`, `pile_pitch.lua` and `discharger.lua`.

Neo-Omega's shared mapping is by user request, not a claim of independent
verification against a current CatsEyeXI encounter.
