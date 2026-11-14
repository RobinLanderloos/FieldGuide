# Leveling Path: parse, evaluate and check talent names

**Type:** AFK  
**User stories:** 9, 10, 41, 42, 43, 44, 45

## State

Open

## What to build

The typed `## Talents` block is parsed into Steps with target ranks, `|` choices and `--` comments. The Talents adapter reads the live C_Traits tree into a name to rank/max map. Evaluate marks reached Steps, finds the Next talent, lists off-plan points and unknown names. The import result lists unmatched talent names when the Guide's class matches the character, and says the check is deferred otherwise. The Guide window's Talents Section shows Steps ticked and the Next talent marked.

## Acceptance criteria

- [ ] Step syntax errors carry line numbers
- [ ] Next talent = first Step not reached, regardless of level
- [ ] Choice Steps are reached when any option is
- [ ] Off-plan lists unplanned talents and ranks above the highest target
- [ ] Unknown names reported on import (same class) and shown as ?
- [ ] Name matching ignores case and extra whitespace
- [ ] Unit tests cover Evaluate scenarios; smoke test uses a stubbed C_Traits

## Blocked by

- 001-import-a-guide-and-read-it-in-the-guide-window.md
