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

-- Step marks, as shown after colour codes are removed.
Display.MARK_REACHED = "[x]"
Display.MARK_NEXT = ">>"
Display.MARK_PENDING = "[  ]"
Display.MARK_UNKNOWN = "?"
local MARKS = {
  reached = "|cff40ff40" .. Display.MARK_REACHED .. "|r",
  next = "|cffffd100" .. Display.MARK_NEXT .. "|r",
  pending = "|cff808080" .. Display.MARK_PENDING .. "|r",
  unknown = "|cffff6060" .. Display.MARK_UNKNOWN .. "|r",
}

local function levels(step)
  return step.from == step.to and tostring(step.from) or (step.from .. "-" .. step.to)
end

local function options(step)
  local out = {}
  for i, o in ipairs(step.options) do out[i] = ("%s %d/%d"):format(o.name, o.rank, o.max) end
  return table.concat(out, ns.L.OR)
end

local function stepMark(i, ev)
  if not ev or not ev.checked then return nil end
  if ev.reached[i] then return MARKS.reached end
  if ev.isUnknown[i] then return MARKS.unknown end
  if ev.nextIndex == i then return MARKS.next end
  return MARKS.pending
end

local function stepLine(i, step, ev)
  local line = ns.Markup.Render(levels(step) .. "  " .. options(step))
  if step.comment then line = line .. "  |cff999999- " .. ns.Markup.Render(step.comment) .. "|r" end
  local mark = stepMark(i, ev)
  if i == (ev and ev.nextIndex) then line = "|cffffd100" .. line .. "|r" end
  return mark and (mark .. " " .. line) or line
end

local function offPlanLines(ev, out)
  if not ev or #ev.offPlan == 0 then return end
  out[#out + 1] = ""
  out[#out + 1] = HEADING:format(ns.L.OFF_PLAN)
  for _, t in ipairs(ev.offPlan) do
    out[#out + 1] = ns.L.OFF_PLAN_LINE:format(t.name, t.rank, t.extra)
  end
end

local function talentsText(section, ev)
  local out = {}
  for i, step in ipairs(section.steps) do out[#out + 1] = stepLine(i, step, ev) end
  offPlanLines(ev, out)
  return table.concat(out, "\n")
end

-- The docked talent panel: `count` steps from the next talent on, then the
-- names the tree doesn't have and the off-plan points.
function Display.TalentPanelText(section, ev, count)
  local out = {}
  if ev and ev.nextIndex then
    local shown = 0
    for i = ev.nextIndex, #section.steps do
      if not ev.reached[i] and not ev.isUnknown[i] then
        out[#out + 1] = stepLine(i, section.steps[i], ev)
        shown = shown + 1
        if shown >= count then break end
      end
    end
  else
    out[#out + 1] = "|cff40ff40" .. ns.L.PATH_COMPLETE .. "|r"
  end
  if ev and #ev.unknown > 0 then
    out[#out + 1] = ""
    out[#out + 1] = ns.L.UNKNOWN_TALENTS:format(table.concat(ev.unknown, ", "))
  end
  offPlanLines(ev, out)
  return table.concat(out, "\n")
end

-- "Next talent: X 1/3 (level 12)", or nil when there is none or nothing was checked.
function Display.NextTalent(section, ev)
  local step = ev and ev.nextIndex and section.steps[ev.nextIndex]
  if not step then return nil end
  return ns.L.NEXT_TALENT:format(options(step), levels(step))
end

-- opts: level (number), showAll (rotation: every part), talents (an
-- evaluation from LevelingPath.Evaluate, for the Talents section).
function Display.SectionText(section, opts)
  opts = opts or {}
  if section.kind == "rotation" then return rotationText(section, opts) end
  if section.kind == "talents" then return talentsText(section, opts.talents) end
  local out = {}
  textLines(section.lines, out)
  return table.concat(out, "\n")
end

-- The first talent point comes at this level.
Display.FIRST_TALENT_LEVEL = 10

-- The chat line on level-up, or nil when there is nothing to say.
function Display.LevelUpNotice(section, ev, level)
  if level < Display.FIRST_TALENT_LEVEL then return nil end
  local step = ev and ev.checked and ev.nextIndex and section.steps[ev.nextIndex]
  if not step then return nil end
  return ns.L.LEVEL_UP_NOTICE:format(options(step))
end
