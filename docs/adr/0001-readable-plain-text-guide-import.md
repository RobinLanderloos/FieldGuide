---
status: accepted
---

# Guide Imports are readable plain text, not encoded strings

A Guide Import is a plain-text markup document that starts with a version line (`!guide v1`), followed by `key: value` header lines and `## Section` blocks. We rejected the WeakAuras-style serialized + compressed + base64 string. A guide is only a few KB, so compression buys nothing. Readable text lets the player check an import before pasting, fix a typo without re-running the converter, and diff guide updates in git. The version line lets the format change later without breaking older imports.

**Amendment (2026-11-14): lenient reading.** Friends paste output from any AI chat, and those chats drift towards Markdown. The parser therefore accepts what they tend to produce instead of rejecting it: chat text and a code fence before `!guide v1` (a closing fence ends the import), indented, bulleted or bold header lines, `=` instead of `:`, `#` to `###` headings with bold or a trailing colon, loose text before the first section (kept as a "Notes" section), and talent steps with a bullet, "Level"/"Lvl", bold names or en dashes. The canonical format the converter and the AI prompt write is unchanged; errors quote the offending line.
Also: empty sections are dropped, and when there is no `## Talents`, the first section with "talent" in its name whose every line is a step becomes the talent plan.
