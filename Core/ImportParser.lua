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
          errors[#errors + 1] = { line = section.line + j, message = ImportParser.Quote("The level range runs backwards.", line) }
        end
      elseif open then
        part.from = tonumber(open)
      elseif marker:match("^%d") or marker == "" then
        errors[#errors + 1] = { line = section.line + j, message = ImportParser.Quote("Expected \"@ 10-20\", \"@ 26+\" or \"@ Label\".", line) }
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

-- ## Talents: one Leveling Path step per non-blank line.
local function parseTalents(section, errors)
  local steps = {}
  for j, line in ipairs(section.lines) do
    if trim(line) ~= "" then
      local step, message = ns.LevelingPath.ParseStep(line)
      if step then
        step.line = section.line + j
        steps[#steps + 1] = step
      else
        errors[#errors + 1] = { line = section.line + j, message = ImportParser.Quote(message, line) }
      end
    end
  end
  section.kind, section.steps = "talents", steps
end

local TYPED = { rotation = parseRotation, talents = parseTalents }

local function fail(line, message)
  return nil, { { line = line, message = message } }
end

-- AI chats decorate their answers with Markdown; undo the common decorations.
local function unbold(s) return (s:gsub("%*%*", ""):gsub("__", "")) end
local function unbullet(s) return (s:gsub("^%s*[%-%*]%s+", "")) end

-- Quotes the offending line in an error, shortened, so it can be found.
function ImportParser.Quote(message, line)
  line = trim(line)
  if #line > 60 then line = line:sub(1, 57) .. "..." end
  return ("%s  > %s"):format(message, line)
end

-- "## Overview", "# Overview", "### **Gear:**" -> the heading text.
local function headingOf(line)
  local hashes, text = line:match("^%s*(#+)%s+(.-)%s*$")
  if not hashes or #hashes > 3 then return nil end
  text = trim(unbold(text)):gsub("%s*:$", "")
  if text == "" then return nil end
  return text
end

local HEADER_KEYS = { title = true, variant = true, class = true, author = true, updated = true, url = true }

-- "title: x", "  title: x", "- title: x", "**title:** x", "title = x" -> "title", "x".
local function headerField(line)
  local key, value = unbold(unbullet(line)):match("^%s*(%a+)%s*[:=]%s*(.-)%s*$")
  if key and HEADER_KEYS[key:lower()] then return key:lower(), value end
end

local function isFence(line) return line:match("^%s*```") ~= nil end

function ImportParser.Parse(text)
  local all = lines(text)
  -- Anything before the version line (chat text, an opening code fence) is skipped.
  local start, version
  for i, line in ipairs(all) do
    version = trim(unbold(line)):match("^!guide%s+v(%d+)$")
    if version then start = i; break end
  end
  if not version then
    return fail(1, "The first line must be \"!guide v1\".")
  end
  if tonumber(version) > ImportParser.VERSION then
    return fail(start, ("This import is format v%s; this FieldGuide reads up to v%d. Update the addon."):format(version, ImportParser.VERSION))
  end
  local guide, errors = { sections = {} }, {}
  local section, implicit
  for i = start + 1, #all do
    local line = all[i]
    if isFence(line) then break end -- a closing fence ends the import; notes after it are dropped
    local heading = headingOf(line)
    local key, value
    if not heading and (not section or implicit) then key, value = headerField(line) end
    if heading then
      section, implicit = { title = heading, lines = {}, line = i }, false
      guide.sections[#guide.sections + 1] = section
    elseif key then
      guide[key] = value
    elseif section then
      section.lines[#section.lines + 1] = line
    elseif trim(line) ~= "" then
      -- Loose text after the header: keep it rather than reject the import.
      section, implicit = { title = "Notes", lines = { line }, line = i - 1 }, true
      guide.sections[#guide.sections + 1] = section
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
