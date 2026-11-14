-- The addon's own labels. Spell, talent and item names come from the guide.
local addonName, ns = ...

ns.L = {
  NOTHING_TO_IMPORT = "Nothing to import: paste a Guide Import first.",
  IMPORT_FAILED = "Import failed:",
  IMPORT_ERROR_LINE = "Line %d: %s",
  IMPORTED = "Imported %s - %s (%d sections).",
  UPDATED = "Updated %s - %s (%s -> %s, %d sections).",
  WINDOW_TITLE = "FieldGuide",
  NO_ACTIVE_GUIDE = "No guide yet. Type /guide import and paste a Guide Import.",
  IMPORT_TITLE = "Import a guide",
  IMPORT_HINT = "Paste a Guide Import (Ctrl+V), then click Import.",
  IMPORT_BUTTON = "Import",
  UPDATED_ON = "updated %s",
  BY = "by %s",
  COPY_TITLE = "Copy link",
  COPY_HINT = "Ctrl+C to copy, Esc to close",
  LINK_BUTTON = "Link",
  GUIDES_BUTTON = "Guides",
  LIBRARY_TITLE = "Your guides",
  USE = "Use",
  DELETE = "Delete",
  CONFIRM_DELETE = "Sure?",
  HELP = {
    "/guide - show or hide the guide window",
    "/guide import - paste a Guide Import",
    "/guide help - this list",
  },
}
