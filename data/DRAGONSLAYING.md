# CatsEyeXI Dragonslaying

Reviewed 2026-11-02. Encounter source:
[CatsEyeXI Dragonslaying](https://www.bg-wiki.com/ffxi/CatsEyeXI_Content/Dragonslaying)
(last edited 2026-10-22).

| NM | Requested family | Template |
|---|---|---|
| Glacial Wyvern | [Wyvern](https://www.bg-wiki.com/ffxi/Category:Wyvern) | List 266 plus Thunder Breath |
| Searing Eldrake | [Dragon](https://www.bg-wiki.com/ffxi/Category:Dragon) | List 87 |
| Blight Wyrm | Dragon | List 87 |
| Venomous Drake | Dragon | List 87 |
| Midgardsormr | [Wyrm](https://www.bg-wiki.com/ffxi/Category:Wyrm) | List 260 plus flying Flame Blast |
| Arfarvegr | Wyrm | List 260 plus flying Flame Blast |
| Skrudningr | Wyrm | List 260 plus flying Flame Blast |
| Brjota | [Zilant](https://www.bg-wiki.com/ffxi/Category:Zilant) | List 470 plus Mighty Strikes |

The wiki spells the Zilant **Brjota**. **Brjorta**, supplied in the request, is an
alias for search, descriptions and tracking, not a second NM.

These are family-template repertoires, not verified server-script inventories.
Tooltips flag that distinction. The three greater wyrms use the shared
Hurricane Wing/Dragon Breath template; unrelated named-wyrm variants such as
Gregale Wing and Sable Breath are not assumed to be used by these encounters.
Family categories and spell scopes include Wyrm and Zilant. Named NM tracking
remains separate from family TP rules.

## Custom effects

- Searing Eldrake: Burn on Body Slam and Heavy Stomp; Petro Eyes changes hate.
- Glacial Wyvern: Frost added to Dread Shriek; Blink added to Wind Wall.
  The encounter page says “Deadly Shriek”; the family/client resource name is
  Dread Shriek, used for selection and live matching.
- Blight Wyrm: Body Slam drains HP. The page also reports Doom but does not
  identify its action, so no guessed Doom icon is attached to a family move.
- Venomous Drake: the page reports Poison, Bio and Plague without identifying
  the latter two actions. Poison Breath retains its sourced Poison; the unknown
  Bio/Plague triggers are noted on hover rather than assigned arbitrarily.
- Hurricane Wing adds Slow/Stoneskin for Midgardsormr, Drown/Blood Weapon for
  Arfarvegr, and Stun/Shock Spikes for Skrudningr. Family-reference Blind is
  retained; live testing should confirm whether the custom effects replace it.
- The page specifies earth/water/lightning flying breath damage respectively.
  Assigning those elements to the template's Flame Blast action is an explicit
  assumption, stated on hover. Ground Dragon Breath retains its family fire
  reference because the page only specifies the flying element.
- Brjota includes its documented Mighty Strikes and Soul Douse/Doom. Its wind
  affinity does not reclassify every Zilant attack as wind. Abyssic Buster remains
  magical with an unknown element because the family source flags lightning as
  unverified.

Unspecified two-hour abilities and spell lists are not guessed. En-spells,
staggering, summoned helpers and damage resistance are encounter mechanics,
not additional readying/casting rows. No numeric damage estimates are added.

Client move IDs and template lists come from the pinned upstream SQL described
in [README.md](README.md). Changes live in `dragonslaying.lua`; generated data
is preserved. Both live descriptions and catalogue rows use these overrides.
