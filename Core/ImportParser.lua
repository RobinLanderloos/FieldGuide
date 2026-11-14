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

local function trimBlank(list)
  while list[1] and trim(list[1]) == "" do table.remove(list, 1) end
  while list[#list] and trim(list[#list]) == "" do table.remove(list) end
end

-- ## Rotation: "@ from-to", "@ from+" or "@ label" start a part; text before
-- the first "@" is a part that is always shown.
local function parseRotation(section, errors)
  local parts, part = {}, { lines = {} }
  parts[1] = part
  for j, line in ipairs(section.lines) do
    local marker = line:match("^@%s*(.-)%s*$")
    if marker then
      part = { lines = {}, label = marker }
      local from, to = marker:match("^(%d+)%s*%-%s*(%d+)$")
      local open = marker:match("^(%d+)%s*%+$")
      if from then
        part.from, part.to = tonumber(from), tonumber(to)
        if part.to < part.from then
          errors[#errors + 1] = { line = section.line + j, message = "The level range runs backwards." }
        end
      elseif open then
        part.from = tonumber(open)
      elseif marker:match("^%d") or marker == "" then
        errors[#errors + 1] = { line = section.line + j, message = "Expected \"@ 10-20\", \"@ 26+\" or \"@ Label\"." }
      end
      parts[#parts + 1] = part
    else
      part.lines[#part.lines + 1] = line
    end
  end
  for _, p in ipairs(parts) do trimBlank(p.lines) end
  if #parts[1].lines == 0 then table.remove(parts, 1) end
  section.kind, section.parts = "rotation", parts
end

local TYPED = { rotation = parseRotation }

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

  for _, sec in ipairs(guide.sections) do
    local typed = TYPED[sec.title:lower()]
    if typed then typed(sec, errors) end
  end

  for _, key in ipairs(REQUIRED) do
    if not guide[key] or guide[key] == "" then
      errors[#errors + 1] = { line = 1, message = ("The header has no \"%s:\" line."):format(key) }
    end
  end
  if #errors > 0 then return nil, errors end

  guide.class = guide.class:upper()
  for _, sec in ipairs(guide.sections) do trimBlank(sec.lines) end
  return guide
end
