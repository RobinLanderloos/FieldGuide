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

local PATHTEXT = HEAD .. "## Talents\n10-11: Wand Specialization 2/2 -- wanding\n12: Precision 1/3\n15: Arcane Focus 1/5 | Arcane Subtlety 1/2\n16: Nonsense 1/1\n"

local function evaluate(section, ranks)
  local live = {}
  for name, rank in pairs(ranks) do live[ns.LevelingPath.Normalize(name)] = { name = name, rank = rank, max = 5 } end
  return ns.LevelingPath.Evaluate(section.steps, live)
end

test("the Leveling Path shows each step with its level, talent, rank and comment", function()
  local section = Parse(PATHTEXT).sections[1]
  local out = strip(Display.SectionText(section, {}))
  assert(out:find("10-11  Wand Specialization 2/2  - wanding", 1, true), out)
  assert(out:find("15  Arcane Focus 1/5 or Arcane Subtlety 1/2", 1, true), out)
end)

test("reached steps are ticked, the next one is marked, unknown ones get a question mark", function()
  local section = Parse(PATHTEXT).sections[1]
  local ev = evaluate(section, { ["Wand Specialization"] = 2, ["Precision"] = 0, ["Arcane Focus"] = 0, ["Arcane Subtlety"] = 0 })
  local lines = {}
  for l in (strip(Display.SectionText(section, { talents = ev })) .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
  local function starts(line, mark) return line:sub(1, #mark) == mark end
  assert(starts(lines[1], Display.MARK_REACHED), lines[1])
  assert(starts(lines[2], Display.MARK_NEXT), lines[2])
  assert(starts(lines[4], Display.MARK_UNKNOWN), lines[4])
end)

test("off-plan points are listed under the path", function()
  local section = Parse(PATHTEXT).sections[1]
  local ev = evaluate(section, { ["Wand Specialization"] = 2, ["Improved Blizzard"] = 1 })
  local out = strip(Display.SectionText(section, { talents = ev }))
  assert(out:find("Off-plan", 1, true) and out:find("Improved Blizzard", 1, true), out)
end)

test("the next talent line names the talent, target rank and level", function()
  local section = Parse(PATHTEXT).sections[1]
  local ev = evaluate(section, { ["Wand Specialization"] = 2, ["Precision"] = 0 })
  eq(strip(Display.NextTalent(section, ev)), "Next talent: Precision 1/3 (level 12)")
end)

test("the talent panel shows the next steps from the next talent on, with comments", function()
  local section = Parse(PATHTEXT).sections[1]
  local ev = evaluate(section, { ["Wand Specialization"] = 2, ["Precision"] = 0, ["Arcane Focus"] = 0, ["Arcane Subtlety"] = 0 })
  local out = strip(Display.TalentPanelText(section, ev, 2))
  assert(not out:find("Wand Specialization 2/2", 1, true), out)
  assert(out:find(">> 12  Precision 1/3", 1, true), out)
  assert(out:find("Arcane Focus 1/5", 1, true), out)
  assert(not out:find("16  Nonsense", 1, true), "shows only 2 steps: " .. out)
end)

test("the talent panel lists unknown names and off-plan points", function()
  local section = Parse(PATHTEXT).sections[1]
  local ev = evaluate(section, { ["Wand Specialization"] = 2, ["Precision"] = 0, ["Arcane Focus"] = 0, ["Arcane Subtlety"] = 0, ["Improved Blizzard"] = 2 })
  local out = strip(Display.TalentPanelText(section, ev, 5))
  assert(out:find("Nonsense", 1, true) and out:find("Improved Blizzard", 1, true), out)
end)

test("the talent panel says when the path is complete", function()
  local section = Parse(HEAD .. "## Talents\n10: Precision 1/3\n").sections[1]
  local out = strip(Display.TalentPanelText(section, evaluate(section, { Precision = 1 }), 5))
  assert(out:find("complete", 1, true), out)
end)

test("the talent panel stops after the requested number of steps", function()
  local section = Parse(PATHTEXT).sections[1]
  local ev = evaluate(section, { ["Wand Specialization"] = 2, ["Precision"] = 0, ["Arcane Focus"] = 0, ["Arcane Subtlety"] = 0 })
  local out = strip(Display.TalentPanelText(section, ev, 1))
  assert(out:find("Precision", 1, true) and not out:find("Arcane Focus", 1, true), out)
end)
