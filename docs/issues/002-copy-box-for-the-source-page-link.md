# Copy box for the Source page link

**Type:** AFK  
**User stories:** 22, 23

## State

Completed (passes outside the game; not yet seen in the live client)

## What to build

A link button in the Guide window header opens the Copy box with the Source page URL selected for Ctrl+C. Bare URLs inside Section text are shown as clickable links that open the same Copy box.

## Acceptance criteria

- [x] Link button opens the Copy box with the full URL highlighted and focused
- [x] Esc or clicking away closes it
- [x] URLs in Section text are detected (Markup) and clickable
- [x] Tests cover URL detection; smoke test opens the Copy box

## Blocked by

- 001-import-a-guide-and-read-it-in-the-guide-window.md
