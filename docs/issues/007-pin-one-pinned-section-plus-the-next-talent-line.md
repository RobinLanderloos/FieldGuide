# Pin: one pinned Section plus the Next talent line

**Type:** AFK  
**User stories:** 30, 31, 32, 33, 34, 35, 36

## State

Completed (passes outside the game; not yet seen in the live client)

## What to build

Each Section header in the Guide window gets a pin button. The Pin shows the pinned Section (Rotation filtered by level) in a resizable, scrolling frame, with an optional Next talent line and a link icon. It opens and closes with its close button, a keybind and `/guide pin`. Position, size, pinned Section and visibility are saved per character.

## Acceptance criteria

- [x] Pinning another Section replaces the current one
- [x] Next talent line toggles independently and works with no pinned Section
- [x] Keybinds appear under Key Bindings > AddOns
- [x] State saved in FieldGuideCharDB and restored on login
- [x] Smoke test pins a Section and toggles the Pin

## Blocked by

- 004-rotation-by-level.md
- 005-leveling-path-parse-evaluate-and-check-talent-names.md
