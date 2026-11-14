-- A Section as one display string (game colour and link codes included).
-- Pure Lua: the game side only puts the string in a FontString.
local addonName, ns = ...

local Display = {}
ns.Display = Display

local HEADING = "|cffffd100%s|r"
local BULLET = "\226\128\162 "

local function textLines(lines, out)
  for _, line in ipairs(lines) do
    out[#out + 1] = ns.Markup.Render((line:gsub("^(%s*)[-*]%s+", "%1" .. BULLET)))
  end
end

local function partHeading(part)
  if not part.label then return nil end
  if part.from then return HEADING:format(ns.L.LEVEL_RANGE:format(part.label)) end
  return HEADING:format(part.label)
end

local function rotationText(section, opts)
  local parts = opts.showAll and section.parts or ns.Rotation.PartsForLevel(section, opts.level or 1)
  local out, ranged = {}, false
  for i, part in ipairs(parts) do
    if part.from then ranged = true end
    if i > 1 then out[#out + 1] = "" end
    local heading = partHeading(part)
    if heading then out[#out + 1] = heading end
    textLines(part.lines, out)
  end
  if not opts.showAll and not ranged then
    table.insert(out, 1, ns.L.NO_ROTATION_FOR_LEVEL:format(opts.level or 1))
    if #out > 1 then table.insert(out, 2, "") end
  end
  return table.concat(out, "\n")
end

-- opts: level (number), showAll (rotation: every part).
function Display.SectionText(section, opts)
  opts = opts or {}
  if section.kind == "rotation" then return rotationText(section, opts) end
  local out = {}
  textLines(section.lines, out)
  return table.concat(out, "\n")
end
