# Guide library: re-import, delete and choosing a Guide

**Type:** AFK  
**User stories:** 13, 14, 15, 16, 17, 18

## State

Open

## What to build

Guides are identified by Source page URL + Variant. Re-importing the same pair replaces the Guide in place and the import result says Updated with the old and new dates. The Guide window lists library Guides (the character's class first), lets the character pick its Active guide, and deletes a Guide after an in-addon confirm. A character without an Active guide is offered Guides of its class.

## Acceptance criteria

- [ ] Same URL + Variant replaces, different Variant adds
- [ ] Import result says Added or Updated (with dates)
- [ ] Library list filters/sorts by class; picking sets the per-character Active guide
- [ ] Delete asks for confirmation inside the addon (no StaticPopup) and clears Active guide references
- [ ] Tests cover Library add/replace/delete/list

## Blocked by

- 001-import-a-guide-and-read-it-in-the-guide-window.md
