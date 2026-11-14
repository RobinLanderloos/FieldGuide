local ns, test, eq = ...
local Parse = ns.ImportParser.Parse
local LevelingPath = ns.LevelingPath

local HEAD = "!guide v1\ntitle: t\nvariant: v\nclass: MAGE\nurl: https://x.test\n"
local PATH = HEAD .. table.concat({
  "## Talents",
  "10-11: Wand Specialization 2/2 -- Early levels will be wanding a lot",
  "12-14: Improved Channeling 3/5",
  "15-16: Missile Barrage 2/2",
  "20: Improved Channeling 4/5",
  "59-60: Improved Fire Blast 2/2 | Improved Counterspell 2/2",
}, "\n")

local function steps(text) return Parse(text).sections[1].steps end

-- Live talents as the adapter builds them: normalized name -> { name, rank, max }.
local function live(list)
  local out = {}
  for name, rank in pairs(list) do
    out[LevelingPath.Normalize(name)] = { name = name, rank = rank, max = 5 }
  end
  return out
end

test("a Talents section is parsed into steps", function()
  local s = steps(PATH)
  eq(#s, 5, "count")
  eq(s[1].from, 10, "from"); eq(s[1].to, 11, "to")
  eq(s[1].options[1].name, "Wand Specialization", "name")
  eq(s[1].options[1].rank, 2, "rank"); eq(s[1].options[1].max, 2, "max")
  eq(s[1].comment, "Early levels will be wanding a lot", "comment")
  eq(s[4].from, 20, "single level"); eq(s[4].to, 20, "single level to")
  eq(#s[5].options, 2, "choice")
  eq(s[5].options[2].name, "Improved Counterspell", "second option")
end)

test("blank lines in the Talents section are ignored", function()
  eq(#steps(HEAD .. "## Talents\n\n10: Precision 1/3\n\n"), 1)
end)

test("a step without a target rank is an error on its line", function()
  local guide, errors = Parse(HEAD .. "## Talents\n10: Precision\n")
  eq(guide, nil, "guide"); eq(errors[1].line, 7, "line")
end)

test("a target above the talent's maximum is an error", function()
  local _, errors = Parse(HEAD .. "## Talents\n10: Precision 4/3\n")
  eq(errors[1].line, 7)
end)

test("names match without regard to case or extra spaces", function()
  eq(LevelingPath.Normalize("  Improved   channeling "), LevelingPath.Normalize("Improved Channeling"))
end)

test("the next talent is the first step not yet reached", function()
  local r = LevelingPath.Evaluate(steps(PATH), live({ ["Wand Specialization"] = 2, ["Improved Channeling"] = 1 }))
  eq(r.reached[1], true, "step 1"); eq(r.reached[2], false, "step 2"); eq(r.nextIndex, 2, "next")
end)

test("steps count up: 4/5 Improved Channeling reaches the 3/5 step too", function()
  local r = LevelingPath.Evaluate(steps(PATH), live({ ["Wand Specialization"] = 2, ["Improved Channeling"] = 4, ["Missile Barrage"] = 0 }))
  eq(r.reached[2], true, "3/5 step"); eq(r.reached[4], true, "4/5 step"); eq(r.nextIndex, 3, "next")
end)

test("a choice step is reached by either option", function()
  local r = LevelingPath.Evaluate(steps(PATH), live({ ["Improved Counterspell"] = 2 }))
  eq(r.reached[5], true)
end)

test("when every step is reached there is no next talent", function()
  local r = LevelingPath.Evaluate(steps(PATH), live({ ["Wand Specialization"] = 2, ["Improved Channeling"] = 5,
    ["Missile Barrage"] = 2, ["Improved Fire Blast"] = 2 }))
  eq(r.nextIndex, nil)
end)

test("points in talents the plan never mentions are off-plan", function()
  local r = LevelingPath.Evaluate(steps(PATH), live({ ["Wand Specialization"] = 2, ["Arcane Focus"] = 1 }))
  eq(#r.offPlan, 1, "count"); eq(r.offPlan[1].name, "Arcane Focus", "name"); eq(r.offPlan[1].extra, 1, "extra")
end)

test("ranks above the highest target are off-plan; the other choice option is not", function()
  local r = LevelingPath.Evaluate(steps(PATH), live({ ["Improved Channeling"] = 5, ["Improved Counterspell"] = 1 }))
  eq(#r.offPlan, 1, "count"); eq(r.offPlan[1].name, "Improved Channeling", "name"); eq(r.offPlan[1].extra, 1, "extra")
end)

test("names missing from the live tree are unknown and never become the next talent", function()
  local s = steps(HEAD .. "## Talents\n10: Wand Specialisation 2/2\n12: Precision 1/3\n")
  local r = LevelingPath.Evaluate(s, live({ ["Precision"] = 0 }))
  eq(#r.unknown, 1, "unknown count"); eq(r.unknown[1], "Wand Specialisation", "unknown name")
  eq(r.isUnknown[1], true, "flag"); eq(r.nextIndex, 2, "next skips it")
end)

test("without a live tree (another class) nothing is checked", function()
  local r = LevelingPath.Evaluate(steps(PATH), nil)
  eq(r.checked, false, "checked"); eq(r.nextIndex, nil, "next"); eq(#r.unknown, 0, "unknown")
end)
