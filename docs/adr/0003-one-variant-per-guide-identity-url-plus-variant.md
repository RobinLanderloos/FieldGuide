---
status: accepted
---

# One import is one Variant; a Guide's identity is Source page URL + Variant name

Guide pages differ a lot in structure, and a single page often has several Variants (for example Arcane Leveling Solo, Arcane Leveling Group, Arcane Fire Endgame), each with its own talents, rotation and gear. The converter finds the Variants and asks the user which one to convert, and each import holds exactly one. A Guide is identified by its Source page URL plus Variant name. Re-importing the same pair replaces the stored Guide in place, and characters that have it active keep it. Titles were rejected as the identity because authors rename guides.

A player may give a Guide a custom name when importing it. It is display only and never part of the identity: re-importing with the name left empty keeps the custom name, a new name replaces it.

## Amendment (2026-11-18): Update replaces a chosen guide

An updated guide can come back with a different Source page URL or Variant name (the author renamed the Variant, or an AI chat worded it differently), and would then land beside the old one. Each library row therefore has **Update**: it opens the import box aimed at that guide, and the import replaces it whatever its new identity. The custom name carries over unless a new one is given. The library records the old key → new key in `FieldGuideDB.moved`, so other characters that had the old guide active (or pinned) follow it the next time they read their active guide. Deleting a guide drops the moves that lead to it. A plain import still matches by URL + Variant only.
