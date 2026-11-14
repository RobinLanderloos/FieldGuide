-- The account-wide guide library and each character's active guide, kept in
-- plain saved-variable tables. Pure Lua: no game calls.
local addonName, ns = ...

local Library = {}
Library.__index = Library
ns.Library = Library

-- A Guide is identified by Source page URL + Variant (ADR 0003).
function Library.Key(guide)
  return guide.url .. "#" .. guide.variant
end

-- db: account-wide saved table; char: per-character saved table.
function Library.New(db, char)
  db.guides = db.guides or {}
  return setmetatable({ db = db, char = char }, Library)
end

-- Returns key, "added" | "updated", previous guide (when updated).
function Library:Add(guide)
  local key = Library.Key(guide)
  local previous = self.db.guides[key]
  self.db.guides[key] = guide
  self.char.active = key
  return key, previous and "updated" or "added", previous
end

function Library:Get(key)
  return self.db.guides[key]
end

function Library:Active()
  return self.char.active and self.db.guides[self.char.active] or nil
end

function Library:SetActive(key)
  if key == nil or self.db.guides[key] then self.char.active = key end
end

function Library:Delete(key)
  self.db.guides[key] = nil
  if self.char.active == key then self.char.active = nil end
end

-- Entries { key, guide }: guides of firstClass first, then by title and Variant.
function Library:List(firstClass)
  local list = {}
  for key, guide in pairs(self.db.guides) do list[#list + 1] = { key = key, guide = guide } end
  table.sort(list, function(a, b)
    local ga, gb = a.guide, b.guide
    local fa, fb = ga.class == firstClass, gb.class == firstClass
    if fa ~= fb then return fa end
    if ga.title ~= gb.title then return ga.title < gb.title end
    return ga.variant < gb.variant
  end)
  return list
end
