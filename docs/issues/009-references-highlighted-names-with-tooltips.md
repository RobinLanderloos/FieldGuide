# References: highlighted names with tooltips

**Type:** AFK  
**User stories:** 27, 28, 29

## State

Open

## What to build

Markup tokenizes `[Name]`, `[spell:id:Name]`, `[item:Name]` and `[item:id:Name]`. Section text shows References in a highlight colour. Hovering shows the game tooltip when the References adapter can resolve it (spell IDs, items with IDs, known spells and talents by name); otherwise it stays a coloured name.

## Acceptance criteria

- [ ] Tokenizer handles plain text, References and URLs in one line, including brackets that are not References
- [ ] Resolver chooses tooltip vs plain colour
- [ ] Hover shows a GameTooltip for resolvable References only
- [ ] Unit tests for Tokenize and Render; smoke test hovers a Reference

## Blocked by

- 001-import-a-guide-and-read-it-in-the-guide-window.md
