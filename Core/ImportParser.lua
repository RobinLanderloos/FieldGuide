-- Turns a Guide Import (plain text, ADR 0001) into a Guide table.
-- Pure Lua: no game calls.
local addonName, ns = ...

local ImportParser = {}
ns.ImportParser = ImportParser

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function lines(text)
  local out, start = {}, 1
  text = text:gsub("\r\n?", "\n")
  while start <= #text + 1 do
    local stop = text:find("\n", start, true)
    if not stop then out[#out + 1] = text:sub(start); break end
    out[#out + 1] = text:sub(start, stop - 1)
    start = stop + 1
  end
  return out
end

ImportParser.VERSION = 1

local REQUIRED = { "title", "variant", "class", "url" }

local function fail(line, message)
  return nil, { { line = line, message = message } }
end

function ImportParser.Parse(text)
  local all = lines(text)
  local version = trim(all[1] or ""):match("^!guide%s+v(%d+)$")
  if not version then
    return fail(1, "The first line must be \"!guide v1\".")
  end
  if tonumber(version) > ImportParser.VERSION then
    return fail(1, ("This import is format v%s; this FieldGuide reads up to v%d. Update the addon."):format(version, ImportParser.VERSION))
  end
  local guide, errors = { sections = {} }, {}
  local section
  for i = 2, #all do
    local line = all[i]
    local heading = line:match("^##%s+(.-)%s*$")
    if heading then
      section = { title = heading, lines = {}, line = i }
      guide.sections[#guide.sections + 1] = section
    elseif section then
      section.lines[#section.lines + 1] = line
    else
      local key, value = line:match("^(%w+):%s*(.-)%s*$")
      if key then
        guide[key:lower()] = value
      elseif trim(line) ~= "" then
        errors[#errors + 1] = { line = i, message = "Expected \"key: value\" or a \"## Section\" heading." }
      end
    end
  end

  for _, key in ipairs(REQUIRED) do
    if not guide[key] or guide[key] == "" then
      errors[#errors + 1] = { line = 1, message = ("The header has no \"%s:\" line."):format(key) }
    end
  end
  if #errors > 0 then return nil, errors end

  guide.class = guide.class:upper()
  for _, sec in ipairs(guide.sections) do
    while sec.lines[1] and trim(sec.lines[1]) == "" do table.remove(sec.lines, 1) end
    while sec.lines[#sec.lines] and trim(sec.lines[#sec.lines]) == "" do table.remove(sec.lines) end
  end
  return guide
end
