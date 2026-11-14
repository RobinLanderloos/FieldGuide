# Rotation by level

**Type:** AFK  
**User stories:** 24, 25, 26

## State

Completed (passes outside the game; not yet seen in the live client)

## What to build

The typed `## Rotation` block is parsed into level-ranged parts (`@ 1-8`, `@ 26+`) and always-shown parts (`@ AoE`, text before the first `@`). The Guide window shows the part for the character's level plus the always-shown parts, with a toggle to show all parts.

## Acceptance criteria

- [x] Parser builds Rotation parts and rejects malformed `@` lines with line numbers
- [x] PartsForLevel picks the later part on overlap and always includes unranged parts
- [x] Guide window updates on PLAYER_LEVEL_UP
- [x] Show all toggle reveals every range
- [x] Unit tests and smoke test pass

## Blocked by

- 001-import-a-guide-and-read-it-in-the-guide-window.md
