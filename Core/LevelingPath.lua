-- The Leveling Path (## Talents): parsing steps and comparing them with the
-- character's live talents (ADR 0005). Pure Lua.
local addonName, ns = ...

local LevelingPath = {}
ns.LevelingPath = LevelingPath

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

function LevelingPath.Normalize(name)
  return trim(name):gsub("%s+", " "):lower()
end

-- "12-14: Improved Channeling 3/5 | Other 1/1 -- comment" -> step, or nil, message.
function LevelingPath.ParseStep(line)
  local levels, rest = line:match("^%s*([%d%s%-]+):%s*(.-)%s*$")
  if not levels then return nil, "Expected \"level: Talent rank/max\"." end
  local from, to = levels:match("^%s*(%d+)%s*%-%s*(%d+)%s*$")
  if not from then from = levels:match("^%s*(%d+)%s*$"); to = from end
  if not from then return nil, "Expected a level or a level range before the colon." end
  local step = { from = tonumber(from), to = tonumber(to), options = {} }
  if step.to < step.from then return nil, "The level range runs backwards." end

  local body, comment = rest:match("^(.-)%s*%-%-%s*(.*)$")
  if body then step.comment = comment ~= "" and comment or nil else body = rest end

  for option in (body .. "|"):gmatch("([^|]*)|") do
    local name, rank, max = trim(option):match("^(.-)%s+(%d+)%s*/%s*(%d+)$")
    if not name or name == "" then
      return nil, "Each talent needs a target rank, like \"Precision 1/3\"."
    end
    rank, max = tonumber(rank), tonumber(max)
    if rank < 1 or rank > max then return nil, ("%s: rank %d is not between 1 and %d."):format(name, rank, max) end
    step.options[#step.options + 1] = { name = name, rank = rank, max = max }
  end
  return step
end

-- live: normalized name -> { name, rank, max }, or nil when the character is
-- another class (nothing is checked then).
function LevelingPath.Evaluate(steps, live)
  local result = { checked = live ~= nil, reached = {}, isUnknown = {}, offPlan = {}, unknown = {} }
  if not live then return result end

  local planned, seenUnknown = {}, {}
  for i, step in ipairs(steps) do
    local reached, known = false, false
    for _, option in ipairs(step.options) do
      local key = LevelingPath.Normalize(option.name)
      planned[key] = math.max(planned[key] or 0, option.rank)
      local talent = live[key]
      if talent then
        known = true
        if talent.rank >= option.rank then reached = true end
      elseif not seenUnknown[key] then
        seenUnknown[key] = true
        result.unknown[#result.unknown + 1] = option.name
      end
    end
    result.reached[i] = reached
    result.isUnknown[i] = not known
    if not reached and known and not result.nextIndex then result.nextIndex = i end
  end

  for key, talent in pairs(live) do
    local extra = talent.rank - (planned[key] or 0)
    if extra > 0 then
      result.offPlan[#result.offPlan + 1] = { name = talent.name, rank = talent.rank, extra = extra }
    end
  end
  table.sort(result.offPlan, function(a, b) return a.name < b.name end)
  return result
end
