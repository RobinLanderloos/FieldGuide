---
name: wow-guide-convert
description: Convert a web class guide (Mobalytics or similar, for WoW Forever) into a FieldGuide Guide Import (`!guide v1` text), validate it, save it in the FieldGuide repo and put it on the clipboard for pasting in-game with /guide import. Use when the user gives a guide URL and wants it in FieldGuide, or asks to update/re-convert a guide.
---

# Convert a web guide into a FieldGuide Guide Import

The FieldGuide addon lives in `C:\Users\robin\projects\FieldGuide`. Its decisions are in `docs/adr/`, its vocabulary in `CONTEXT.md`. Converted guides are the guide authors' content reworded for the user's own use, so they are **never committed** (the repo is public): they live in `C:/Users/robin/Documents/FieldGuide guides/` (worked example: `mage-arcane-mage-guide-progress-arcane-leveling-solo.guide.txt` there). The repo's own format example is `tests/fixtures/example-warrior.guide.txt`.

## Procedure

1. **Open the Source page in Chrome** (load the `chrome-browser` skill first; new tab). Mobalytics renders its content on the client, so `get_page_text` can come back empty right after navigating: wait a few seconds and read again.
2. **Find the Variants.** Guide pages often have several (for example "Arcane Leveling Solo", "Arcane Leveling Group", "Arcane Fire Endgame"), shown as tabs above Talents, Rotation and Gear. List them and **ask the user which one to convert** (AskUserQuestion). One import holds exactly one Variant (ADR 0003). Skip the question only when the page has a single Variant or the user already named one.
3. **Select that Variant's tab in every section** that has Variant tabs (click them, then read the text again). Shared sections (Overview, Races, Professions, Tips) are the same for all Variants.
4. **Write the Guide Import** to `C:/Users/robin/Documents/FieldGuide guides/<class>-<page-slug>-<variant-slug>.guide.txt` in the format below. Re-converting the same page and Variant overwrites the file.
5. **Validate**: from the repo root run `luajit tools/validate.lua "C:/Users/robin/Documents/FieldGuide guides/<file>.guide.txt"`. Fix every error (they come with line numbers) and run it again until it prints `OK`. Check the talent points add up: steps count up, and the totals should match the guide's "points spent".
6. **Clipboard**: `Get-Content -Raw "C:/Users/robin/Documents/FieldGuide guides/<file>.guide.txt" | Set-Clipboard` (PowerShell).
7. **Tell the user**: in-game, `/guide import`, Ctrl+V, Import. The import result lists talent names that don't match the character's tree. If it does, fix the names in the file and repeat from step 5. Do not commit the guide file.
8. Close the tabs you opened.

## Writing the content

- **Paraphrase and shorten; don't copy the author's prose word for word.** Keep every fact, number, level, name and recommendation. Short lists beat paragraphs; the Pin is small.
- Leave out site chrome: comments, "related guides", author bio, share buttons, ads. Keep the changelog only if it matters for play.
- Any heading can become a `## Section`. Keep the guide's own structure and order (ADR 0004).

## Guide Import format (v1)

```
!guide v1
title: <page title as shown>
variant: <Variant name as shown on the page>
class: <WARRIOR|PALADIN|HUNTER|ROGUE|PRIEST|SHAMAN|MAGE|WARLOCK|DRUID>
author: <author, optional>
updated: <YYYY-MM-DD from "Updated on", optional>
url: <page URL without #anchor or query string>

## <Any section>
Free text. "- " bullets and "1. " numbered lines are shown as written.

## Talents
<level>[-<level>]: <Talent Name> <targetRank>/<maxRank> [| <Other Talent> <rank>/<max>] [-- comment]

## Rotation
Text before the first @ is always shown.
@ 1-8
...
@ 26+
...
@ AoE
...
```

### Talents (the Leveling Path)

- One line per step, in the guide's order. **Every option needs `rank/max`.** The rank is the **cumulative** target ("Improved Channeling 4/5" means having 4 points), not the number of points added in that step.
- A level range with no rank stated means one point per level: `46-50: Accelerant` becomes `Accelerant 5/5` when that fills the talent.
- Max ranks: take them from the page's talent grid (`2/2`, `0/5`...) or the step text. If unsure, use the highest rank the guide reaches. The in-game name check catches wrong names, but not wrong max ranks.
- "A or B" choices: `Improved Fire Blast 2/2 | Improved Counterspell 2/2`.
- Talent names must be the game's names (Forever has new talents: Arcane Wrath, Accelerant, Incineration...). Copy them exactly from the page.
- The step's comment is the guide's "why", shortened, after ` -- `. No `[references]` inside the Talents block; plain names only.

### Rotation

- `@ from-to`, `@ from+` or `@ Label` (AoE, Cleave, Opener...) start a part. In-game the part for the character's level is shown with all labelled parts. Where ranges overlap, the later part wins.

### References and literals

- Mark spells, talents and items in text: `[Arcane Blast]` for spells and talents, `[item:Lesser Magic Wand]` for items. In-game they're highlighted, with a tooltip where the client can resolve them.
- Add an ID (`[spell:30451:Arcane Blast]`, `[item:11287:Lesser Magic Wand]`) **only when the page itself shows it** (ADR 0006). Never look IDs up in vanilla databases: Forever changes spells.
- Wrap macros and anything with literal square brackets in backticks: `` `/cast [target=NAME] Fire Blast` ``.
- Bare `https://` URLs become copyable links.
