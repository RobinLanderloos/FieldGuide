---
status: accepted
---

# Spell and item IDs come only from the guide page itself; otherwise references resolve by name

Spell, talent and item names in a Guide Import may be marked as references: `[Arcane Blast]`, `[item:Lesser Magic Wand]`, or `[spell:30451:Arcane Blast]` with an ID. The converter adds an ID only when the Source page provides one. In-game a reference is resolved by name where the client allows (spells in the spellbook, talents in the tree) and otherwise stays a coloured name with no tooltip. We rejected looking IDs up in vanilla databases (wowhead and similar) because Forever adds and changes spells (Arcane Wrath, Accelerant, Eureka!), so a vanilla ID can point to the wrong spell. A wrong tooltip is worse than none.
