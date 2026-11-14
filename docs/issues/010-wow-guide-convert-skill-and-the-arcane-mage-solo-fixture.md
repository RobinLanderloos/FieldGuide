# wow-guide-convert skill and the Arcane Mage Solo fixture

**Type:** HITL  
**User stories:** 1, 2, 3, 4, 5

## State

Open

## What to build

A Claude skill in the repo holds the Guide Import spec and the conversion procedure: open the Source page in Chrome, wait for render, list Variants and ask which one, extract that Variant's tabs, write `guides/<class>-<slug>-<variant>.guide.txt`, validate with a LuaJIT CLI that runs the Core ImportParser, and copy to the clipboard. The first conversion is the Mobalytics Arcane Mage Leveling Solo Variant, which becomes a test fixture.

## Acceptance criteria

- [ ] Skill linked into ~/.claude/skills
- [ ] Validation CLI prints errors with line numbers and exits non-zero on failure
- [ ] Arcane Mage Solo import parses with zero errors and is used as a test fixture
- [ ] Import is placed on the clipboard

## Blocked by

- 004-rotation-by-level.md
- 005-leveling-path-parse-evaluate-and-check-talent-names.md
- 009-references-highlighted-names-with-tooltips.md
