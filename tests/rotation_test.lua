local ns, test, eq = ...
local Parse = ns.ImportParser.Parse
local Rotation = ns.Rotation

local HEAD = "!guide v1\ntitle: t\nvariant: v\nclass: MAGE\nurl: https://x.test\n"
local ROT = HEAD .. table.concat({
  "## Rotation",
  "Keep Arcane Intellect up.",
  "@ 1-8",
  "1. Fireball",
  "@ 8-20",
  "1. Arcane Missiles",
  "@ 26+",
  "1. Arcane Wrath",
  "@ AoE",
  "1. Arcane Explosion",
}, "\n")

local function rotation(text) return Parse(text).sections[1] end

local function names(parts)
  local out = {}
  for i, p in ipairs(parts) do out[i] = p.label or "-" end
  return table.concat(out, ",")
end

test("a Rotation section is split into its parts", function()
  local r = rotation(ROT)
  eq(r.kind, "rotation", "kind")
  eq(#r.parts, 5, "parts")
  eq(r.parts[2].from, 1, "from"); eq(r.parts[2].to, 8, "to")
  eq(r.parts[4].from, 26, "open from"); eq(r.parts[4].to, nil, "open to")
  eq(r.parts[5].label, "AoE", "label")
  eq(r.parts[5].lines[1], "1. Arcane Explosion", "lines")
end)

test("the heading is matched without regard to case", function()
  eq(rotation((ROT:gsub("## Rotation", "## ROTATION"))).kind, "rotation")
end)

test("other sections stay free-form", function()
  eq(Parse(HEAD .. "## Tips\n@ 1-8\n").sections[1].kind, nil)
end)

test("a malformed level range is an error on its line", function()
  local guide, errors = Parse(HEAD .. "## Rotation\n@ 20-10\n")
  eq(guide, nil, "guide")
  eq(errors[1].line, 7, "line")
end)

test("for a level, the always-shown parts and the matching range are shown in order", function()
  eq(names(Rotation.PartsForLevel(rotation(ROT), 12)), "-,8-20,AoE")
end)

test("on overlapping ranges the later part wins", function()
  eq(names(Rotation.PartsForLevel(rotation(ROT), 8)), "-,8-20,AoE")
end)

test("between ranges only the always-shown parts are shown", function()
  eq(names(Rotation.PartsForLevel(rotation(ROT), 23)), "-,AoE")
end)

test("an open range covers every level above its start", function()
  eq(names(Rotation.PartsForLevel(rotation(ROT), 60)), "-,26+,AoE")
end)
