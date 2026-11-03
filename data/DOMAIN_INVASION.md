# CatsEyeXI Domain Invasion

Reviewed 2026-11-02 against the [CatsEyeXI Domain Invasion page](https://www.bg-wiki.com/ffxi/CatsEyeXI_Content/Domain_Invasion)
(page last edited 2026-08-02). This replaces the obsolete original DI roster.

## Coverage

| Group | Entries |
|---|---|
| Rotation bosses | Colkhab, Tchakka, Achuka, Yumcax, Hurkan, Kumhau |
| Lesser Domain NM | Velkk Intruder |
| Greater Domain NMs | Amphisbaena, Battosai, Tortuga |
| Greater HQ variants | Tamandua, Gensai, Cryptodira |

Each has its own NM tracking entry. HQ pairs share effect tables but retain
separate tracking rules. Reinforcements are not classified as additional bosses.
Bahamut and Helga belong to an older version and are not added by this profile.

`domain_invasion.lua` contains the roster, explicit move IDs and monster-specific
effects. It replaces imported lists for these entries rather than merging
unrelated abilities. In particular, the upstream Tchakka pool incorrectly points
to Achuka's move list. Its six shark moves now replace that list in both the
browser and live name lookup.

## Sources and confidence

- The CatsEyeXI page supplies all six rotation move lists, Velkk Intruder's
  Glutinous Dart and Mighty Strikes, and the custom Greater/HQ effects:
  Shock on Thunderbolt, Paralysis/Poison on Trembling, and Drown on Aqua Breath.
- Colkhab, Tchakka and Achuka effects follow the CatsEyeXI descriptions and
  damage/element images. Carcharian Verve is deliberately water damage here,
  following this custom encounter description rather than retail assumptions.
- The page leaves Yumcax, Hurkan and Kumhau effects blank. These use
  [Yggdreant](https://www.bg-wiki.com/ffxi/Category:Yggdreant),
  [Waktza](https://www.bg-wiki.com/ffxi/Category:Waktza), and
  [Kumhau](https://www.bg-wiki.com/ffxi/Kumhau) retail references. Their tooltips
  explicitly identify this fallback; CatsEyeXI behavior still needs live checks.
- Root of the Problem has magical damage with no specified element, so displays
  the existing unknown-damage indicator. Incisive Apotheosis is documented as
  Weakness/enmity reset without inventing a damage element or damage amount.
- Basic Behemoth, Hydra and Adamantoise abilities use the pinned upstream
  [mobskill scripts](https://github.com/LandSandBoat/server/tree/858bd9d7cb1d4b8a57db9be132282e7505a5bea4/scripts/actions/mobskills),
  supplemented by the original [CatsEyeXI DI reference](https://github-wiki-see.page/m/HaxPrime/catseyexi/wiki/Domain-Invasion)
  for their listed repertoire. The current page confirms that Greater NMs are
  based on those original bosses. These base abilities remain inferred until
  verified against the current server; its explicitly documented custom effects
  take precedence.
- Glutinous Dart's physical classification is supplemented by its
  [spell reference](https://www.bg-wiki.com/ffxi/Glutinous_Dart).
- Crashing Thunder ID 3072 is a commented-out melee special in the pinned
  `mob_skills.sql`, absent from the generated active move catalogue. A reviewed
  entry makes it selectable without inventing a new ID. Its live packet behavior
  should be checked; the selection cannot force the server to send a preparation.

The current page does not enumerate exact spell IDs for these encounters.
No guessed high-tier water spell list is added for Tortuga/Cryptodira; use the
existing Add Spell control for observed spells. Permanent auras and en-spells
are encounter mechanics, not additional cast/ready events.

Damage and status icons remain inline. AoE, enmity changes, dispels, aura notes
and reference limitations remain in hover tooltips. No damage estimates added.
