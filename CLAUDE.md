# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

FieldGuide is a World of Warcraft addon for the **WoW Forever** client (interface 16001, retail-style API). It shows an imported class guide in-game: sections, a talent Leveling Path that ticks off as you level, the rotation for your level, a Pin, a panel beside the talent window, and a copyable source link. The `wow-forever-addon` skill holds verified client API facts and known pitfalls; load it before changing game-facing code.

## Commands

All run from the repo root with LuaJIT:

- `luajit tests/run.lua` — unit tests for the pure `Core/` files (prints `N passed, M failed`, exits non-zero on failure). To run one suite, temporarily trim the test-file list at the bottom of `tests/run.lua`; there is no per-test filter. `tests/run.lua` has two hard-coded lists — the Core files to load and the `tests/*_test.lua` files to run — so a new Core file or test file must be added there by hand. Each test file is a chunk receiving `(ns, test, eq)`.
- `luajit tests/smoke_test.lua` — loads every file the `.toc` lists, in order, against a stand-in for the game API and drives the UI (clicks buttons via `widget.scripts.OnClick`, checks shown text). Prints `load check passed` on success. It reads the file list from the `.toc`, so new `Game/` files are covered automatically once listed there; if new code calls a game API the stand-in lacks, extend the stub in `smoke_test.lua`.
- `luajit tools/validate.lua <file.guide.txt>` — validate a Guide Import with the addon's own parser.
- `luajit tools/print_prompt.lua` — regenerate `AI_PROMPT.txt` after editing `Core/AIPrompt.lua`.
- `pwsh scripts/package.ps1` — build `dist/FieldGuide-<version>.zip` and `release.json` (version from `## Version:` in `FieldGuide.toc`; bump it there for a release). The zip contains only the `.toc`, `Core/`, `Game/`, `Locales/`, `README.md`, `LICENSE`, `Bindings.xml` and `AI_PROMPT.txt`; the script fails if a `.toc`-listed file is missing. `dist/` is git-ignored.

## Architecture

- **`Core/`** is pure Lua with no game calls (parser, library, markup, rotation, leveling path, display text, AI prompt, minimap math). It is unit-tested by `tests/run.lua`, which loads a fixed list of Core files — add new Core files there.
- **`Game/`** holds frames and game-API code; it is only exercised by the smoke test. New files must be added to `FieldGuide.toc` (load order matters: Locales, then Core, then Game).
- Every file starts with `local addonName, ns = ...` and publishes its module on `ns` (e.g. `ns.Library`, `ns.GuideWindow`). All user-facing strings live in `Locales/enUS.lua` as `ns.L`.
- **Saved variables**: `FieldGuideDB` (account-wide guide library, keyed by `url .. "#" .. variant`) and `FieldGuideCharDB` (per character: active guide key, Pin state). `Game/Main.lua` builds `ns.library` on `ADDON_LOADED`. `FieldGuideDB` also holds account-wide settings (`glow`, `minimap`) and `report`.
- **Data flow**: a Guide Import (`!guide v1` plain text) is pasted into `ImportBox` → `ImportParser` produces a Guide table → `Library:Add` stores it and makes it active → `GuideWindow`, `Pin`, `TalentPanel`, `Glow` read the active guide. Sections are free-form except two typed blocks: `## Talents` (Leveling Path) and `## Rotation`.
- **In-game debugging**: the user cannot copy chat, so `/guide debug` (`Game/Report.lua`) both prints and stores its lines in `FieldGuideDB.report`; read them from the SavedVariables file after `/reload`. Extend this report rather than asking for chat output.
- **Talent glow** (`Game/Glow.lua`, ADR 0007) overlays our own frames on another window's talent buttons via per-window providers (EllesmereUI, then Blizzard `PlayerSpellsFrame`, which also covers ElvUI), found by the same 4×/second poll the Talent panel uses. It never writes into other addons' frames and never buys or stages talents.
- Guide text escapes `|` as `||` whenever it is shown in a FontString or EditBox (WoW's escape character).

## Docs and conventions

- `CONTEXT.md` is the glossary (Guide, Variant, Guide Import, Active guide, Leveling Path, Step, Off-plan, Pin, …); use these terms in code, comments and commits.
- `docs/adr/` records the decisions (plain-text import, conversion outside the game, identity = URL + Variant, free-form sections with two typed blocks, talents matched by name with cumulative targets, IDs only from the source page, talent glow overlays). `docs/prd/` and `docs/issues/` hold the PRD and its work items.
- `AI_PROMPT.txt` is generated (see Commands) and shipped in the package; never edit it by hand.
- User-facing docs for slash commands and the import flow are in `README.md`; keep it in sync when commands change.
- Converting a web guide into a Guide Import is done outside the game via the `wow-guide-convert` skill (`converter/wow-guide-convert/SKILL.md`). Converted guides go in `guides/`, which is git-ignored (other authors' content).
