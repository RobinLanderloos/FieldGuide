-- Runs an import (parse + store) and builds the result lines shown to the
-- player. Pure Lua: no game calls.
local addonName, ns = ...

local ImportReport = {}
ns.ImportReport = ImportReport

-- The game reads "|" as the start of an escape code; "||" shows one.
local function escape(text) return (text:gsub("|", "||")) end

local function talentSteps(guide)
  for _, section in ipairs(guide.sections) do
    if section.kind == "talents" then return section.steps end
  end
end

-- Talent step count and the names this character's tree doesn't have.
local function talentLines(guide, context, lines)
  local steps = talentSteps(guide)
  if not steps then return end
  local L = ns.L
  lines[#lines + 1] = L.TALENT_STEPS:format(#steps)
  if not context then return end
  if context.class ~= guide.class then
    lines[#lines + 1] = L.TALENTS_CHECKED_LATER:format(guide.class)
    return
  end
  local ev = ns.LevelingPath.Evaluate(steps, context.live)
  if ev.checked and #ev.unknown > 0 then
    lines[#lines + 1] = L.UNKNOWN_TALENTS:format(escape(table.concat(ev.unknown, ", ")))
  end
end

-- context (optional): { class = player's class token, live = live talents }.
-- customName (optional): the player's name for the guide.
-- Returns ok, lines.
function ImportReport.Import(text, library, context, customName)
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
  local _, status, previous = library:Add(guide, customName)
  local lines
  local title, variant = escape(ns.Library.DisplayName(guide)), escape(guide.variant)
  if status == "updated" then
    lines = { L.UPDATED:format(title, variant,
      previous.updated or "?", guide.updated or "?", #guide.sections) }
  else
    lines = { L.IMPORTED:format(title, variant, #guide.sections) }
  end
  talentLines(guide, context, lines)
  return true, lines
end
