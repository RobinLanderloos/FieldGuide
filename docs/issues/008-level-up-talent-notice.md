# Level-up talent notice

**Type:** AFK  
**User stories:** 46, 47

## State

Open

## What to build

On PLAYER_LEVEL_UP the addon prints one chat line naming the Next talent (and target rank), unless the Leveling Path is finished or no talent point is available.

## Acceptance criteria

- [ ] One line per level-up, using locale strings
- [ ] No line when the Guide is finished or there is no Active guide
- [ ] Smoke test fires PLAYER_LEVEL_UP and reads the printed line

## Blocked by

- 005-leveling-path-parse-evaluate-and-check-talent-names.md
