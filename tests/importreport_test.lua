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
