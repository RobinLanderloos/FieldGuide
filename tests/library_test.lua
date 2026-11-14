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

test("adding the same Source page and Variant again replaces it and returns the old one", function()
  local lib = Library.New({}, {})
  local old = guide(); old.updated = "2026-11-14"
  eq(select(2, lib:Add(old)), "added", "first status")
  local new = guide(); new.updated = "2026-11-20"
  local key, status, previous = lib:Add(new)
  eq(status, "updated", "second status")
  eq(previous.updated, "2026-11-14", "previous")
  eq(lib:Get(key).updated, "2026-11-20", "stored")
  eq(#lib:List(), 1, "count")
end)

test("another Variant of the same page is a separate guide", function()
  local lib = Library.New({}, {})
  lib:Add(guide("Solo")); lib:Add(guide("Group"))
  eq(#lib:List(), 2)
end)

test("the list puts the given class first, then sorts by title and Variant", function()
  local lib = Library.New({}, {})
  local w = guide("Fury"); w.class = "WARRIOR"; w.title = "A Warrior"; w.url = "https://w.test"
  lib:Add(w); lib:Add(guide("Solo")); lib:Add(guide("Group"))
  local list = lib:List("MAGE")
  eq(list[1].guide.variant, "Group", "1"); eq(list[2].guide.variant, "Solo", "2"); eq(list[3].guide.class, "WARRIOR", "3")
  assert(list[1].key, "entries carry their key")
end)

test("choosing a guide makes it this character's active guide", function()
  local lib = Library.New({}, {})
  local solo = lib:Add(guide("Solo")); lib:Add(guide("Group"))
  lib:SetActive(solo)
  eq(lib:Active().variant, "Solo")
end)

test("deleting the active guide leaves the character without one", function()
  local lib = Library.New({}, {})
  local key = lib:Add(guide())
  lib:Delete(key)
  eq(lib:Get(key), nil, "stored"); eq(lib:Active(), nil, "active")
end)

test("a guide deleted on another character is not active here either", function()
  local db, mage, alt = {}, {}, {}
  local key = Library.New(db, mage):Add(guide())
  Library.New(db, alt):Delete(key)
  eq(Library.New(db, mage):Active(), nil)
end)
