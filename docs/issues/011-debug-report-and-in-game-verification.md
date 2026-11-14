# Debug report and in-game verification

**Type:** HITL  
**User stories:** 49

## State

Open

## What to build

`/guide debug` writes the Active guide, live talent map, Evaluate result and frame anchors into SavedVariables. The user imports the Arcane Mage fixture in the live client and checks the window, Pin, Talent panel (EllesmereUI) and level-up line; Claude reads the report after `/reload` and fixes mismatches with the stand-in.

## Acceptance criteria

- [ ] Debug report lines in FieldGuideDB.report
- [ ] C_Traits talent reading confirmed in the live client
- [ ] Docking to EUI_ClassicTalents confirmed
- [ ] api-notes.md in the wow-forever-addon skill updated with verified facts

## Blocked by

- 006-talent-panel-docked-beside-the-talent-window.md
- 007-pin-one-pinned-section-plus-the-next-talent-line.md
- 008-level-up-talent-notice.md
