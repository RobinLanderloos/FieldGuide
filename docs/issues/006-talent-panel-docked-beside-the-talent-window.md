# Talent panel docked beside the talent window

**Type:** AFK  
**User stories:** 37, 38, 39, 40, 41, 44, 45

## State

Completed (passes outside the game; not yet seen in the live client)

## What to build

When EllesmereUI's classic talent window (EUI_ClassicTalents) or Blizzard's talent window is shown, a Talent panel docks beside it showing the next few Steps with comments, reached Steps ticked, off-plan points and unknown names. It updates when talents change.

## Acceptance criteria

- [x] Docks to EUI_ClassicTalents when shown, else Blizzard's talent frame
- [x] Hidden when no Active guide or the talent window closes
- [x] Updates on TRAIT_CONFIG_UPDATED / talent change events
- [x] Smoke test shows the panel next to a stub window

## Blocked by

- 005-leveling-path-parse-evaluate-and-check-talent-names.md
