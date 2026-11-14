# Import a Guide and read it in the Guide window

**Type:** AFK  
**User stories:** 6, 7, 8, 11, 12, 15, 19, 20, 21, 48, 50

## State

Completed (passes outside the game; not yet seen in the live client)

## What to build

Tracer bullet through every layer. The ImportParser reads the `!guide v1` header and free-form Sections (Talents and Rotation are kept as plain Sections for now). `/guide import` opens the ImportBox. Pasting and clicking Import stores the Guide in the account-wide library, makes it the character's Active guide, and shows an import result. `/guide` toggles the Guide window: header (title, Variant, author, updated) plus a Section list and content pane showing paragraphs, bullets and numbered lists as written. Labels live in the locale file.

## Acceptance criteria

- [x] ImportParser rejects a missing or unknown version line, and missing title/variant/class/url, with line numbers
- [x] Free-form Sections keep their order and text
- [x] Import stores the Guide in FieldGuideDB and sets the Active guide in FieldGuideCharDB
- [x] Import result shows title, Variant and Section count
- [x] Guide window shows the header and switches Sections from the list
- [x] `/guide`, `/guide import` and `/guide help` work
- [x] Unit tests and the smoke test pass

## Blocked by

None - can start immediately
