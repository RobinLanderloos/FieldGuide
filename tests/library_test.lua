local ns, test, eq = ...
local Library = ns.Library

local function guide(variant)
  return { title = "Arcane Mage", variant = variant or "Arcane Leveling Solo", class = "MAGE",
    url = "https://example.test/arcane", sections = {} }
end

test("an added guide can be found again by its key", function()
  local db, char = {}, {}
  local lib = Library.New(db, char)
  local key = lib:Add(guide())
  eq(lib:Get(key).variant, "Arcane Leveling Solo")
end)

test("adding a guide makes it the character's active guide", function()
  local db, char = {}, {}
  local lib = Library.New(db, char)
  local key = lib:Add(guide())
  eq(lib:Active(), lib:Get(key), "active guide")
end)

test("the library survives being rebuilt from the same saved tables", function()
  local db, char = {}, {}
  Library.New(db, char):Add(guide())
  eq(Library.New(db, char):Active().title, "Arcane Mage")
end)

test("a character with nothing active has no active guide", function()
  eq(Library.New({}, {}):Active(), nil)
end)
