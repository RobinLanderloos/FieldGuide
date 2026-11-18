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

local function withSections()
  local g = guide()
  g.sections = { { title = "Overview", lines = {} }, { title = "Rotation", lines = {} } }
  return g
end

test("a pinned section is remembered by its title for the active guide", function()
  local lib = Library.New({}, {})
  lib:Add(withSections())
  lib:Pin("Rotation")
  eq(lib:Pinned().title, "Rotation")
end)

test("pinning another section replaces the first", function()
  local lib = Library.New({}, {})
  lib:Add(withSections())
  lib:Pin("Rotation"); lib:Pin("Overview")
  eq(lib:Pinned().title, "Overview")
end)

test("the pin survives re-importing the guide", function()
  local db, char = {}, {}
  local lib = Library.New(db, char)
  lib:Add(withSections()); lib:Pin("Rotation")
  lib:Add(withSections())
  eq(Library.New(db, char):Pinned().title, "Rotation")
end)

test("a pinned section the guide no longer has pins nothing", function()
  local lib = Library.New({}, {})
  lib:Add(withSections()); lib:Pin("Gear")
  eq(lib:Pinned(), nil)
end)

test("switching guides drops the pin", function()
  local lib = Library.New({}, {})
  local first = lib:Add(withSections()); lib:Pin("Rotation")
  local g2 = withSections(); g2.variant = "Group"
  lib:Add(g2)
  eq(lib:Pinned(), nil, "new guide")
  lib:SetActive(first)
  eq(lib:Pinned(), nil, "back again")
end)

test("pin frame state is kept per character", function()
  local char = {}
  local lib = Library.New({}, char)
  lib:PinState().shown = true
  eq(Library.New({}, char):PinState().shown, true)
end)

test("guides are grouped by class, the given class first, then the others alphabetically", function()
  local lib = Library.New({}, {})
  local function add(class, variant, title)
    local g = guide(variant); g.class = class; g.title = title or "T"; g.url = "https://" .. class .. ".test"
    lib:Add(g)
  end
  add("WARRIOR", "Fury"); add("DRUID", "Feral"); add("MAGE", "Solo"); add("MAGE", "Group"); add("WARRIOR", "Arms")
  local groups = lib:Groups("MAGE")
  local out = {}
  for _, group in ipairs(groups) do
    local variants = {}
    for _, e in ipairs(group.entries) do variants[#variants + 1] = e.guide.variant end
    out[#out + 1] = group.class .. "=" .. table.concat(variants, ",")
  end
  eq(table.concat(out, " "), "MAGE=Group,Solo DRUID=Feral WARRIOR=Arms,Fury")
end)

test("a class without guides gets no group, not even the character's own", function()
  local lib = Library.New({}, {})
  lib:Add(guide())
  local groups = lib:Groups("PRIEST")
  eq(#groups, 1, "groups"); eq(groups[1].class, "MAGE", "class")
end)

test("a guide can be renamed after import", function()
  local lib = Library.New({}, {})
  local key = lib:Add(guide())
  lib:Rename(key, "  My Arcane  ")
  eq(Library.DisplayName(lib:Get(key)), "My Arcane")
end)

test("renaming to nothing goes back to the guide's own title", function()
  local lib = Library.New({}, {})
  local key = lib:Add(guide(), "My Arcane")
  lib:Rename(key, " ")
  eq(Library.DisplayName(lib:Get(key)), "Arcane Mage")
end)

test("a renamed guide keeps its name when re-imported without one", function()
  local lib = Library.New({}, {})
  local key = lib:Add(guide())
  lib:Rename(key, "Renamed")
  lib:Add(guide())
  eq(Library.DisplayName(lib:Get(key)), "Renamed")
end)

test("renaming a guide that is gone does nothing", function()
  local lib = Library.New({}, {})
  lib:Rename("nope", "x")
  eq(#lib:List(), 0)
end)

test("updating a guide with a renamed Variant replaces it instead of adding one", function()
  local lib = Library.New({}, {})
  local oldKey = lib:Add(guide("Solo"))
  local new = guide("Solo (patch 1.6)"); new.updated = "2026-11-20"
  local key, status, previous = lib:Replace(oldKey, new)
  eq(status, "updated", "status")
  eq(previous.variant, "Solo", "previous")
  eq(#lib:List(), 1, "count")
  eq(lib:Get(oldKey), nil, "old key gone")
  eq(lib:Get(key).variant, "Solo (patch 1.6)", "stored")
end)

test("an updated guide keeps its custom name unless a new one is given", function()
  local lib = Library.New({}, {})
  local oldKey = lib:Add(guide("Solo"), "My Arcane")
  local key = lib:Replace(oldKey, guide("Solo v2"))
  eq(Library.DisplayName(lib:Get(key)), "My Arcane", "kept")
  key = lib:Replace(key, guide("Solo v3"), "Arcane 3")
  eq(Library.DisplayName(lib:Get(key)), "Arcane 3", "new name")
end)

test("another character with the old guide active follows it to the update, pin included", function()
  local db, alt, main = {}, {}, {}
  local altLib = Library.New(db, alt)
  local oldKey = altLib:Add(guide("Solo"))
  altLib:Pin("Rotation")
  local mainLib = Library.New(db, main)
  mainLib:Replace(oldKey, guide("Solo v2"))
  altLib = Library.New(db, alt)
  eq(altLib:Active().variant, "Solo v2", "active followed")
  eq(altLib:PinState().section, "Rotation", "pin section kept")
  eq(altLib:PinState().guide, Library.Key(guide("Solo v2")), "pin followed")
end)

test("updating twice still leads characters to the latest version", function()
  local db, alt = {}, {}
  local oldKey = Library.New(db, alt):Add(guide("Solo"))
  local lib = Library.New(db, {})
  local k2 = lib:Replace(oldKey, guide("Solo v2"))
  lib:Replace(k2, guide("Solo v3"))
  eq(Library.New(db, alt):Active().variant, "Solo v3")
end)

test("a character whose guide was updated and then deleted has no active guide", function()
  local db, alt = {}, {}
  local oldKey = Library.New(db, alt):Add(guide("Solo"))
  local lib = Library.New(db, {})
  lib:Delete((lib:Replace(oldKey, guide("Solo v2"))))
  eq(Library.New(db, alt):Active(), nil)
end)

test("updating a guide that no longer exists just adds the import", function()
  local lib = Library.New({}, {})
  local _, status = lib:Replace("gone#key", guide())
  eq(status, "added")
  eq(#lib:List(), 1)
end)
