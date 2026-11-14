local ns, test, eq = ...
local M = ns.MinimapMath

local function near(a, b, what) assert(math.abs(a - b) < 0.001, (what or "value") .. ": " .. a .. " vs " .. b) end

test("angle 0 puts the button to the right of the minimap", function()
  local x, y = M.Offset(0, 80)
  near(x, 80, "x"); near(y, 0, "y")
end)

test("angle 90 puts the button at the top", function()
  local x, y = M.Offset(90, 80)
  near(x, 0, "x"); near(y, 80, "y")
end)

test("the angle follows the cursor direction and stays between 0 and 360", function()
  near(M.Angle(0, 10), 90, "up"); near(M.Angle(-10, 0), 180, "left"); near(M.Angle(0, -10), 270, "down")
end)

test("offset and angle are inverses", function()
  local x, y = M.Offset(225, 50)
  near(M.Angle(x, y), 225)
end)
