-- Position of the minimap button on a circle around the minimap. Pure Lua.
local addonName, ns = ...

local MinimapMath = {}
ns.MinimapMath = MinimapMath

-- x, y offset from the minimap's centre for an angle in degrees.
function MinimapMath.Offset(angle, radius)
  local radians = math.rad(angle)
  return math.cos(radians) * radius, math.sin(radians) * radius
end

-- The angle in degrees (0 to 360) of a point relative to the minimap's centre.
function MinimapMath.Angle(dx, dy)
  return math.deg(math.atan2(dy, dx)) % 360
end
