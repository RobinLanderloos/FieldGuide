-- Which parts of a Rotation section apply at a level. Pure Lua.
local addonName, ns = ...

local Rotation = {}
ns.Rotation = Rotation

local function covers(part, level)
  return level >= part.from and (part.to == nil or level <= part.to)
end

-- The always-shown parts plus the one ranged part for this level (the later
-- part wins where ranges overlap), in the order the guide lists them.
function Rotation.PartsForLevel(section, level)
  local chosen
  for _, part in ipairs(section.parts) do
    if part.from and covers(part, level) then chosen = part end
  end
  local out = {}
  for _, part in ipairs(section.parts) do
    if not part.from or part == chosen then out[#out + 1] = part end
  end
  return out
end
