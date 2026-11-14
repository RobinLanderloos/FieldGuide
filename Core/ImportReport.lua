-- Runs an import (parse + store) and builds the result lines shown to the
-- player. Pure Lua: no game calls.
local addonName, ns = ...

local ImportReport = {}
ns.ImportReport = ImportReport

-- Returns ok, lines.
function ImportReport.Import(text, library)
  local L = ns.L
  if not text or not text:find("%S") then
    return false, { L.NOTHING_TO_IMPORT }
  end
  local guide, errors = ns.ImportParser.Parse(text)
  if not guide then
    local lines = { L.IMPORT_FAILED }
    for _, err in ipairs(errors) do
      lines[#lines + 1] = L.IMPORT_ERROR_LINE:format(err.line, err.message)
    end
    return false, lines
  end
  local _, status, previous = library:Add(guide)
  if status == "updated" then
    return true, { L.UPDATED:format(guide.title, guide.variant,
      previous.updated or "?", guide.updated or "?", #guide.sections) }
  end
  return true, { L.IMPORTED:format(guide.title, guide.variant, #guide.sections) }
end
