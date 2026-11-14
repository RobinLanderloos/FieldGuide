local ns, test, eq = ...

test("the example guide fixture parses without errors", function()
  local file = assert(io.open("tests/fixtures/example-warrior.guide.txt", "rb"))
  local text = file:read("*a"); file:close()
  local guide, errors = ns.ImportParser.Parse(text)
  assert(guide, errors and (errors[1].line .. ": " .. errors[1].message))
  eq(guide.class, "WARRIOR", "class")
  local talents, rotation
  for _, s in ipairs(guide.sections) do
    if s.kind == "talents" then talents = s elseif s.kind == "rotation" then rotation = s end
  end
  eq(#talents.steps, 17, "talent steps")
  eq(#rotation.parts, 5, "rotation parts")
  local points = 0
  local last = {}
  for _, step in ipairs(talents.steps) do
    local o = step.options[1]
    points = points + o.rank - (last[o.name] or 0)
    last[o.name] = o.rank
  end
  eq(points, 51, "talent points from level 10 to 60")
end)
