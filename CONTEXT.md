# FieldGuide glossary

- **Source page**: a class guide on the web (Mobalytics or similar), identified by its URL. Several Guides can share one Source page.
- **Variant**: one build or path on a Source page (e.g. "Arcane Leveling Solo"), with its own talents, rotation and gear.
- **Guide Import**: the plain-text `!guide v1` document the converter produces for one Variant. It is pasted in-game.
- **Guide**: one imported Variant, stored in the account-wide library. Identity = Source page URL + Variant name.
- **Custom name**: an optional name the player gives a Guide at import. Display only; it replaces the title in the window, Guides list and Talent panel, and survives re-imports that leave the name empty. Renamed later from the Guides list; an empty name goes back to the title.
- **Active guide**: the Guide a character currently follows (stored per character).
- **Section**: a `## Heading` block of a Guide. Free-form unless typed.
- **Leveling Path**: the typed `## Talents` block, an ordered list of **Steps** (`level[-level]: Talent Name rank/max [| alternative] [-- comment]`).
- **Step reached**: the live talent rank is at least the Step's target rank (any option, for a choice).
- **Next talent**: the first Step not yet reached.
- **Off-plan**: points in a talent the Leveling Path never asks for, or more ranks than it ever targets.
- **Rotation**: the typed `## Rotation` block, split into level-ranged parts plus always-shown parts.
- **Reference**: a marked spell, talent or item name in section text (`[Name]`, `[spell:id:Name]`, `[item:Name]`).
- **Guide window**: the main window (section list, content, link button).
- **Pin**: the small heads-up frame showing one pinned Section plus an optional next-talent line.
- **Talent panel**: the panel docked beside the open talent window (EllesmereUI's classic one or Blizzard's).
- **Copy box**: the read-only text box with a URL pre-selected for Ctrl+C.
