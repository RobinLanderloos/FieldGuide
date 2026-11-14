---
status: accepted
---

# Conversion happens outside the game; pasting is the only way in

An addon cannot fetch web pages, so a Claude skill (`converter/`, `wow-guide-convert`) does the conversion. It reads the guide page in Chrome, writes `<class>-<slug>-<variant>.guide.txt`, validates it with the addon's own Core parser under LuaJIT, and puts it on the clipboard. In-game the player runs `/guide import` and pastes. The imported Guide is stored in SavedVariables, so a new guide needs no code change and no `/reload`.

## Considered Options

- **An `Inbox.lua` data file loaded by the .toc, picked up on `/reload`.** No clipboard needed, but it only works on the PC that holds the repo, and an import can't be shared with another player. Rejected.

Converted guides are the guide authors' content reworded for personal use, so they are kept outside the public repository (in the user's Documents folder) and never committed; `guides/` is ignored. Players without Claude Code use the AI prompt shipped with the addon (`AI_PROMPT.txt`, the import box's AI prompt button).
