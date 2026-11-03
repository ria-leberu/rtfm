# Screenshot checklist

Capture the current UI at 100% log text size. Crop to the relevant window, keep
labels readable, and save PNGs in `docs/images/`. Use the same window width for
comparison shots. These are capture recommendations; no screenshots are bundled yet.

## Recommended captures

| Priority | File | What to capture | Suggested caption / placement |
|---|---|---|---|
| 1 | `01-log.png` | A completed offensive action with `[damage]` and `(status)` icons, yellow affected-player names, a green tracked star and speaker. Keep the left-aligned timer/control columns, gear and Readying/Casting header visible. Khimaira's Fossilizing Breath is a useful candidate. | “Moves, effects, tracking and confirmed affected players in one line.” Place after Reading the log. |
| 2 | `02-preparation.png` | A tracked Fire III cast in Readying/Casting with its fire icon, progress bar after the spell text and `-> TargetName`. Include a few completed rows above it. | “The pending target is the intended recipient, not the full AoE hit list.” Place beside the target explanation. |
| 3 | `03-family-tracking.png` | Common families selected, Moblin selected, Frypan starred green and another move untracked. Keep the family name and row icons visible. | “Track a family's moves from the catalogue.” Place after Track families, NMs and spells. |
| 4 | `04-spell-tracking.png` | Tracked spells tab selected, Meteor selected, and its Any enemy / Specific enemy controls plus saved rules visible. Take a second shot of Untracked spells if needed. | “Track a spell globally or for one named enemy.” Place with the spell instructions. |
| 5 | `05-sound-selection.png` | Open a move's speaker window with `alert.wav` and an added `warning.wav` listed. Include the folder path, Refresh, Preview and Use selected sound controls. | “Copy a WAV into the shown folder, refresh, then assign it.” Place after Choose alert sounds. |
| 6 | `06-settings.png` | Settings showing the audio and center-alert toggles, compact mode, text size, retention and tracked family Edit/Remove controls. Enlarge the window if needed rather than shrinking text. | “Adjust display, retention and alert preferences.” Place with Settings. |

## Useful comparisons

- **Compact mode:** capture the same rows with compact mode off and on. Use
  `The Greater Manticore`, `Moblin Topsman` or a long spell name. Keep the window
  width identical. Save `07-full-text.png` and `08-compact-text.png`.
- **Center alert:** record a short GIF or video of a tracked preparation. Show
  the yellow wave/pulse, black outline and preparation bar over the game scene. A still image can
  show appearance but cannot explain motion. Save a still as `09-center-alert.png`.
- **Hover help:** capture a status icon tooltip or a compact action's full-text
  tooltip only if readers need more explanation; it is optional.

## Capture sequence

1. Enable tracking for a known move and one spell; add a valid WAV to `sounds/`.
2. Trigger the relevant actions in your private-server session.
3. Capture the log, pending target and center alert while each state is visible.
4. Open catalogue, sound and Settings windows for the remaining shots.
5. Compare each image against its caption before adding it to the README.

Keep text descriptions in the guide even after adding images, so screenshots
supplement the instructions rather than becoming the only explanation.

- **Completion transition:** record a preparation through its confirmed completion
  to show the upward text glide and the new log row highlight.
