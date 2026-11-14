# FieldGuide: class guides and talent plans in the WoW Forever client

## Problem Statement

While leveling in WoW Forever I follow a web class guide (for example the Mobalytics "Arcane Mage Guide | <Progress> Avoid"). It has a talent Leveling Path, a rotation that changes with level, gear advice, races, professions and tips. In-game I can't see any of it without alt-tabbing. When I level up I have to look up which talent the point goes into, and when I want the guide's URL (to check for updates or share it) I have to find it again in the browser. The game can't open web pages, and I can't copy text out of the game either.

## Solution

FieldGuide is a WoW Forever addon plus a conversion step outside the game.

- **Conversion**: Claude, using a `wow-guide-convert` skill, reads a Source page in Chrome, asks which Variant I want, and writes a readable plain-text Guide Import (`!guide v1`). It validates the import with the addon's own parser and puts it on my clipboard.
- **Import**: in-game I run `/guide import`, paste and click Import. The Guide goes into an account-wide library and the import result lists what was found and any talent names that don't match.
- **Guide window**: shows every Section of the active Guide, with a link button that opens a Copy box holding the Source page URL.
- **Pin**: a small heads-up frame shows one Section I choose (Rotation shows only my current level range) plus a "Next talent" line. It opens and closes with a keybind.
- **Talent panel**: docked beside the open talent window (EllesmereUI's classic one or Blizzard's). It shows the next Leveling Path steps with comments, ticks off reached steps, and lists off-plan points.
- **Level-up notice**: on level-up a chat line says where the talent point goes.

## User Stories

1. As a player, I want to give Claude a guide URL and get an importable text, so that I don't have to retype a guide.
2. As a player, I want the converter to list the guide's Variants and ask me which to convert, so that I get the build I'm actually following.
3. As a player, I want the converter to put the import on my clipboard, so that importing is a single Ctrl+V.
4. As a player, I want the converter to validate the import before handing it over, so that I don't discover syntax errors in-game.
5. As a player, I want converted imports saved as files in the repo, so that I can diff guide updates over time.
6. As a player, I want to read and edit the Guide Import as plain text, so that I can fix a typo without re-running the converter.
7. As a player, I want `/guide import` to open a paste box, so that I can import anywhere.
8. As a player, I want an import result showing the title, Variant, sections found and Leveling Path step count, so that I know the import worked.
9. As a player, I want talent names that don't match my class tree listed right after import, so that mistakes surface at once, not at level 47.
10. As a player, I want to import a guide for another class on any character, so that I can prepare guides for my alts; its name check waits until I log in on that class.
11. As a player, I want a malformed import rejected with a line number and reason, so that I know what to fix.
12. As a player, I want an import with an unknown format version rejected with a clear message, so that old addon versions don't misread new imports.
13. As a player, I want re-importing the same Source page + Variant to replace the old Guide in place, so that updates don't create duplicates.
14. As a player, I want the import result to say "Updated" with the old and new dates when replacing, so that I know a guide changed.
15. As a player, I want my Guides stored account-wide, so that every alt can use them.
16. As a player, I want each character to have its own active Guide, so that my mage and warrior follow different guides.
17. As a player, I want a character without an active Guide to be offered library Guides of its class, so that picking one is quick.
18. As a player, I want to delete a Guide from the library with an in-addon confirm, so that old guides don't pile up.
19. As a player, I want a Guide window listing the Sections on the left and showing the content on the right, so that I can browse the guide like the web page.
20. As a player, I want free-form Sections shown as written, with paragraphs, bullets and numbered lists, so that any guide's structure survives.
21. As a player, I want the Guide window header to show the title, Variant, author and updated date, so that I know what I'm reading.
22. As a player, I want a link button that opens a Copy box with the Source page URL selected, so that I can Ctrl+C it.
23. As a player, I want URLs inside Section text to open the same Copy box when clicked, so that I can copy them too.
24. As a player, I want the Rotation Section to show the part for my current level plus always-shown parts (like AoE), so that I see what applies now.
25. As a player, I want to see the other rotation ranges on request in the Guide window, so that I can read ahead.
26. As a player, I want overlapping rotation ranges resolved predictably (the later one wins), so that level 8 doesn't show two rotations.
27. As a player, I want spell, talent and item References highlighted, so that key abilities stand out.
28. As a player, I want hovering a Reference to show the game tooltip when the client can resolve it, so that I can read what a spell does.
29. As a player, I want unresolved References shown as a coloured name with no tooltip, so that nothing is ever wrong, only missing.
30. As a player, I want to pin any Section to the Pin with one click, so that I can focus on rotation now and gear later.
31. As a player, I want pinning another Section to replace the current one, so that the Pin stays small.
32. As a player, I want the Pin to show a "Next talent" line that I can toggle, so that I always know where my next point goes.
33. As a player, I want to close and open the Pin with a close button, a keybind and `/guide pin`, so that it's out of the way when I don't need it.
34. As a player, I want the Pin's position, size and pinned Section remembered per character, so that I set it up once.
35. As a player, I want long pinned Sections to scroll inside the Pin, so that it doesn't grow down the screen.
36. As a player, I want a link icon on the Pin too, so that I can copy the URL mid-dungeon.
37. As a player, I want a Talent panel docked beside the open talent window, so that the plan is in front of me while I spend points.
38. As a player using EllesmereUI's classic talent window, I want the Talent panel to dock to it, so that it works with my UI.
39. As a player using Blizzard's talent window, I want the panel to dock there instead, so that it works without EllesmereUI.
40. As a player, I want the Talent panel to show the next few steps with their comments, so that I know why a talent is taken.
41. As a player, I want reached steps ticked off, so that I see my progress.
42. As a player, I want the next talent to be the first step not yet reached, whatever my level, so that taking talents early or out of order doesn't confuse it.
43. As a player, I want choice steps ("Improved Fire Blast or Improved Counterspell") reached when any option is reached, so that both choices count.
44. As a player, I want points in talents the plan never mentions, or more ranks than it asks for, listed as off-plan, so that I notice deviations without nagging.
45. As a player, I want unmatched talent names shown as "?" in the panel, so that a bad step is visible.
46. As a player, I want a chat line on level-up naming the next talent, so that I spend the point right away.
47. As a player, I want no chat line when my next talent is already reached or the Guide is finished, so that it's not noise.
48. As a player, I want `/guide` to toggle the Guide window and `/guide help` to list commands, so that the addon is discoverable.
49. As a player, I want a `/guide debug` report written to SavedVariables, so that Claude can read in-game state after a `/reload`.
50. As a future publisher, I want all addon labels in a locale file, so that the addon can be translated.

## Implementation Decisions

Decisions recorded as ADRs 0001–0006 (readable format, paste-only delivery, one Variant per Guide with URL + Variant identity, free-form sections with two typed blocks, talents by name with cumulative targets, IDs only from the Source page). The vocabulary is in the glossary (CONTEXT.md).

### Guide Import format v1

```
!guide v1
title: Arcane Mage Guide | <Progress> Avoid
variant: Arcane Leveling Solo
class: MAGE
author: <Progress> Avoid
updated: 2026-11-14
url: https://mobalytics.gg/wow-forever/classes/arcane-mage-guide-progress

## Overview
Free text with [Arcane Blast] and [item:Lesser Magic Wand] references.
- bullets
1. numbered

## Talents
10-11: Wand Specialization 2/2 -- Early levels will be wanding a lot
12-14: Improved Channeling 3/5
59-60: Improved Fire Blast 2/2 | Improved Counterspell 2/2

## Rotation
@ 1-8
1. Cast [Fireball]
@ 26-60
1. Open with [Arcane Wrath]
@ AoE
1. Cast 4x [Arcane Explosion]
```

- Header: `key: value` lines before the first section; `title`, `variant`, `class` (English class token) and `url` are required; `author` and `updated` are optional. Unknown keys are kept and ignored.
- The first line must be `!guide v<n>`; versions above 1 are rejected.
- `## Talents` and `## Rotation` are typed, matched case-insensitively. Every other `## Heading` is a free-form Section, kept in order.
- Leveling Path step: `<level>[-<level>]: <Talent> <rank>/<max> [| <Talent> <rank>/<max> ...] [-- comment]`. The level range is informational (used for the level-up notice and display), the target rank drives progress.
- Rotation parts: `@ <from>-<to>` or `@ <from>+` (level-ranged) or `@ <label>` (always shown). Text before the first `@` is always shown.
- References: `[Name]`, `[spell:<id>:Name]`, `[item:Name]`, `[item:<id>:Name]`. Bare `http(s)://` URLs are detected as links.

### Modules

**Core (pure Lua, no game calls, tested under LuaJIT):**

- **ImportParser**: `Parse(text) -> guide | nil, errors`. Turns a Guide Import into a Guide table (header fields, ordered sections, parsed Leveling Path, parsed Rotation). Errors carry line numbers. This is the deepest module and the contract shared with the converter.
- **LevelingPath**: `ParseStep(line)` and `Evaluate(steps, liveRanks) -> { reached = {...}, nextIndex, offPlan = {...}, unknown = {...} }`. `liveRanks` maps talent name to `{ rank, max }` (or is nil when the class doesn't match, which means "not checked"). Name matching is case- and whitespace-insensitive.
- **Rotation**: `PartsForLevel(rotation, level)` returns the always-shown parts plus the one ranged part that applies (the later part wins on overlap).
- **Markup**: `Tokenize(line)` returns runs of plain text, References and URLs. `Render(section, resolver)` turns Section lines into display lines with WoW colour and hyperlink codes, with the resolver deciding whether a Reference gets a tooltip link.
- **Library**: account-wide store operations on a plain table: `Add(guide) -> "added" | "updated", old`, `Delete(key)`, `List(classFilter)`, `Key(guide)` (URL + Variant), plus per-character active guide and Pin state helpers.
- **ImportReport**: builds the import result lines (new/updated, counts, unmatched talents) from parser output, Library result and LevelingPath evaluation.

**Game (client glue):**

- **Talents adapter**: reads the active `C_Traits` config and turns the class tree into a talent name → `{ rank, max }` map (pattern taken from EllesmereUI's classic talent window). Fires a callback on talent and level changes.
- **References adapter**: resolves names to spell links/tooltips via the client (spellbook and talent tree), items by ID only.
- **GuideWindow**, **ImportBox**, **CopyBox**, **Pin**, **TalentPanel** (docks to `EUI_ClassicTalents` when shown, else Blizzard's talent frame), **LevelUpNotice**, **Slash** (`/guide`, `/fg`), **Bindings** (toggle Pin, toggle window), **Report** (debug lines to SavedVariables).
- SavedVariables: `FieldGuideDB` (library, account); SavedVariablesPerCharacter: `FieldGuideCharDB` (active guide key, Pin state).

**Converter (`wow-guide-convert` skill in the repo):** format spec, procedure (Chrome, wait for render, detect Variants, ask, click the Variant's tabs, extract), output to `guides/`, validation by running the Core ImportParser through a LuaJIT CLI script, `Set-Clipboard`.

## Testing Decisions

- Tests check behaviour through each module's public interface (input text or tables in, result tables out), never internal helpers, so refactors don't break them.
- All Core modules get unit tests, written test-first: ImportParser, LevelingPath, Rotation, Markup, Library, ImportReport.
- The real Arcane Mage Solo import is used as a fixture: it must parse with zero errors and yield the exact Leveling Path step count of the converted file.
- A smoke test loads every file in the .toc against a game stand-in, fires `ADDON_LOADED`/`PLAYER_LOGIN`, runs `/guide import` with the fixture, and checks the window, Pin and Talent panel text.
- Prior art: DustOrGold's `tests/run.lua` (loads Core files like the client does, small `test(name, fn)` cases) and `tests/smoke_test.lua`.
- A passing smoke test does not prove the real client behaves like the stand-in. Talent reading via `C_Traits` and docking to EllesmereUI must be checked in-game.

## Out of Scope

- Highlighting or glowing talent nodes inside a talent window.
- Spending talent points automatically.
- More than one Pin at a time.
- An in-game pass that learns spell/item IDs over time.
- Editing Guides in-game (beyond importing a corrected text).
- Checking equipped gear against the guide.
- Looking up IDs in external databases during conversion.
- An encoded/compressed import format.

## Further Notes

- The first real Source page is the Mobalytics Arcane Mage guide; its text only appears after client-side rendering, and its References are hover widgets without IDs in the DOM.
- New files added to the .toc need a full client restart; content changes need `/reload`.
- Diagnostics follow the wow-forever-addon skill: the user can't copy chat, so `/guide debug` writes to SavedVariables.
