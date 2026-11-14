local ns, test, eq = ...
local ImportReport = ns.ImportReport

local GOOD = "!guide v1\ntitle: Arcane Mage\nvariant: Solo\nclass: MAGE\nurl: https://example.test\n## Overview\nhi\n## Tips\nyo\n"

test("a good import is stored and the result names it and counts its sections", function()
  local lib = ns.Library.New({}, {})
  local ok, lines = ImportReport.Import(GOOD, lib)
  eq(ok, true, "ok")
  local text = table.concat(lines, "\n")
  assert(text:find("Arcane Mage", 1, true) and text:find("Solo", 1, true), text)
  assert(text:find("2 sections", 1, true), text)
  eq(lib:Active().title, "Arcane Mage", "stored")
end)

test("a bad import stores nothing and lists each error with its line", function()
  local lib = ns.Library.New({}, {})
  local ok, lines = ImportReport.Import("!guide v1\ntitle: x\n", lib)
  eq(ok, false, "ok")
  eq(lib:Active(), nil, "stored")
  local text = table.concat(lines, "\n")
  assert(text:find("Line 1", 1, true), text)
  assert(text:find("variant", 1, true), text)
end)

test("an empty paste says there is nothing to import", function()
  local ok, lines = ImportReport.Import("   \n", ns.Library.New({}, {}))
  eq(ok, false, "ok")
  assert(lines[1]:find("Nothing", 1, true), lines[1])
end)

test("re-importing says Updated with the old and new dates", function()
  local lib = ns.Library.New({}, {})
  ImportReport.Import(GOOD .. "", lib)
  local first = GOOD:gsub("class: MAGE", "class: MAGE\nupdated: 2026-11-14")
  local second = GOOD:gsub("class: MAGE", "class: MAGE\nupdated: 2026-11-20")
  ImportReport.Import(first, lib)
  local _, lines = ImportReport.Import(second, lib)
  local text = table.concat(lines, "\n")
  assert(text:find("Updated", 1, true) and text:find("2026-11-14", 1, true) and text:find("2026-11-20", 1, true), text)
end)

local TALENTS = GOOD .. "## Talents\n10-11: Wand Specialization 2/2\n12: Wand Specialisation 2/2\n"
local function liveTree()
  return { [ns.LevelingPath.Normalize("Wand Specialization")] = { name = "Wand Specialization", rank = 0, max = 2 } }
end

test("the result counts the Leveling Path steps", function()
  local _, lines = ImportReport.Import(TALENTS, ns.Library.New({}, {}), { class = "MAGE", live = liveTree() })
  local text = table.concat(lines, "\n")
  assert(text:find("2 talent steps", 1, true), text)
end)

test("talent names not in this character's tree are listed after import", function()
  local _, lines = ImportReport.Import(TALENTS, ns.Library.New({}, {}), { class = "MAGE", live = liveTree() })
  local text = table.concat(lines, "\n")
  assert(text:find("Wand Specialisation", 1, true), text)
end)

test("a guide for another class says the talent check waits", function()
  local _, lines = ImportReport.Import(TALENTS, ns.Library.New({}, {}), { class = "WARRIOR", live = {} })
  local text = table.concat(lines, "\n")
  assert(text:find("MAGE", 1, true) and not text:find("Wand Specialisation", 1, true), text)
end)

test("pipes in the title are escaped so the game shows them", function()
  local _, lines = ImportReport.Import((GOOD:gsub("title: Arcane Mage", "title: Arcane Mage | <Progress>")), ns.Library.New({}, {}))
  assert(lines[1]:find("Arcane Mage || <Progress>", 1, true), lines[1])
end)
