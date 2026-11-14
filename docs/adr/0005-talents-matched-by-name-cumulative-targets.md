---
status: accepted
---

# Talents are matched by name against the live C_Traits tree; next = first step not yet reached

Forever's talents are vanilla-style trees running on the retail `C_Traits` system. Leveling Path steps name talents (`12-14: Improved Channeling 3/5`) and every step carries an explicit target rank. Names are resolved against the character's live class tree. A step is reached when the live rank is at least its target (a `|` choice is reached when any option is). The next talent is the first step not yet reached, whatever the character's level, so taking talents early or out of order is not an error. Points the plan never asks for are reported as "off-plan" and never corrected. Names that don't match are listed right after import (when the guide's class matches the logged-in character, otherwise the check waits until it does) and shown as "?".

## Considered Options

- **Node IDs in the import.** Exact, but unreadable, and the converter can't get them from a guide page. Rejected.
- **Spending points automatically.** Committing talents is hard to undo and can clash with points staged in EllesmereUI's talent window. Left out of v1.
