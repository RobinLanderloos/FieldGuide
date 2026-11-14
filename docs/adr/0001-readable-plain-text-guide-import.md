---
status: accepted
---

# Guide Imports are readable plain text, not encoded strings

A Guide Import is a plain-text markup document that starts with a version line (`!guide v1`), followed by `key: value` header lines and `## Section` blocks. We rejected the WeakAuras-style serialized + compressed + base64 string. A guide is only a few KB, so compression buys nothing. Readable text lets the player check an import before pasting, fix a typo without re-running the converter, and diff guide updates in git. The version line lets the format change later without breaking older imports.
