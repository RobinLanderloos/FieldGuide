# Rotation by level

**Type:** AFK  
**User stories:** 24, 25, 26

## State

Open

## What to build

The typed `## Rotation` block is parsed into level-ranged parts (`@ 1-8`, `@ 26+`) and always-shown parts (`@ AoE`, text before the first `@`). The Guide window shows the part for the character's level plus the always-shown parts, with a toggle to show all parts.

## Acceptance criteria

- [ ] Parser builds Rotation parts and rejects malformed `@` lines with line numbers
- [ ] PartsForLevel picks the later part on overlap and always includes unranged parts
- [ ] Guide window updates on PLAYER_LEVEL_UP
- [ ] Show all toggle reveals every range
- [ ] Unit tests and smoke test pass

## Blocked by

- 001-import-a-guide-and-read-it-in-the-guide-window.md
