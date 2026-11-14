local ns, test, eq = ...
local Parse = ns.ImportParser.Parse
local Display = ns.Display

local HEAD = "!guide v1\ntitle: t\nvariant: v\nclass: MAGE\nurl: https://x.test\n"

local function strip(s) return (s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

test("free-form text keeps its lines and turns bullets into dots", function()
  local section = Parse(HEAD .. "## Tips\nIntro\n- one\n  * two\n1. three").sections[1]
  eq(strip(Display.SectionText(section, {})), "Intro\n\226\128\162 one\n  \226\128\162 two\n1. three")
end)

test("a rotation shows the parts for the level with their headings", function()
  local section = Parse(HEAD .. "## Rotation\nBuffs.\n@ 1-8\nFireball\n@ 9+\nMissiles\n@ AoE\nExplosion").sections[1]
  local out = strip(Display.SectionText(section, { level = 5 }))
  eq(out, "Buffs.\n\nLevel 1-8\nFireball\n\nAoE\nExplosion")
end)

test("a rotation can show every part", function()
  local section = Parse(HEAD .. "## Rotation\n@ 1-8\nFireball\n@ 9+\nMissiles").sections[1]
  local out = strip(Display.SectionText(section, { level = 5, showAll = true }))
  eq(out, "Level 1-8\nFireball\n\nLevel 9+\nMissiles")
end)

test("a rotation with nothing for this level says so", function()
  local section = Parse(HEAD .. "## Rotation\n@ 1-8\nFireball").sections[1]
  local out = strip(Display.SectionText(section, { level = 30 }))
  assert(out:find("level 30", 1, true), out)
end)
