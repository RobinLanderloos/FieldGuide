---
status: accepted
---

# The next talent glows through our own overlay on the talent window's buttons

The v1 PRD left node glow out. It is now in: the next Leveling Path step's talent nodes (every option of a choice) glow inside whichever talent window is open. The glow is a frame of ours parented to the window's talent button, kept in our own weak table. Nothing is written into the other window's frames, and no talent is ever bought or staged (ADR 0005 still holds).

Finding the button means reading another window's internals, one provider per window, tried in order:

- **EllesmereUI's classic talent window**: `EUI_ClassicTalents.talents`, whose buttons carry `nodeID`. This is EllesmereUI's private structure; if it changes, the glow silently stops there and the docked Talent panel still works.
- **Blizzard's Talents & Spellbook**: `PlayerSpellsFrame.TalentsFrame:GetTalentButtonByNodeID(nodeID)` (the retail talent frame API), called through `pcall`.
- **ElvUI** skins Blizzard's window rather than replacing it, so the Blizzard provider covers it. It has no provider of its own.

Windows are found by the same 4-times-a-second check the Talent panel uses, rather than by hooking frames that load on demand or belong to other addons. `/guide glow` turns the glow off (saved account-wide).

## Considered Options

- **Changing the window's own highlight** (`LockHighlight`, their textures): fights the other addon's own painting and skins. Rejected.
- **Hooking each window's refresh functions**: exact timing, but ties us to more internals than reading one list. Rejected.
