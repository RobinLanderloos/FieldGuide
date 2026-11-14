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
  self:setActive(key)
  return key, previous and "updated" or "added", previous
end

function Library:Get(key)
  return self.db.guides[key]
end

function Library:Active()
  return self.char.active and self.db.guides[self.char.active] or nil
end

function Library:setActive(key)
  if self.char.active ~= key and self.char.pin then
    self.char.pin.guide, self.char.pin.section = nil, nil
  end
  self.char.active = key
end

function Library:SetActive(key)
  if key == nil or self.db.guides[key] then self:setActive(key) end
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

-- The Pin (per character): one section of the active guide, by title, so it
-- survives re-importing the guide. Choosing another guide drops it.
function Library:Pin(sectionTitle)
  local state = self:PinState()
  state.guide, state.section = self.char.active, sectionTitle
end

function Library:Pinned()
  local state, guide = self:PinState(), self:Active()
  if not guide or state.guide ~= self.char.active then return nil end
  for _, section in ipairs(guide.sections) do
    if section.title == state.section then return section end
  end
end

-- Saved frame state of the Pin: shown, nextLine, position, size.
function Library:PinState()
  self.char.pin = self.char.pin or {}
  return self.char.pin
end
