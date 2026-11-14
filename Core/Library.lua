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

-- The name shown for a guide: the player's custom name, else its title.
function Library.DisplayName(guide)
  return guide.customName or guide.title
end

-- Returns key, "added" | "updated", previous guide (when updated).
-- customName (optional) is a display name; blank keeps the previous one.
function Library:Add(guide, customName)
  local key = Library.Key(guide)
  local previous = self.db.guides[key]
  customName = customName and customName:match("^%s*(.-)%s*$")
  if customName and customName ~= "" then
    guide.customName = customName
  elseif previous then
    guide.customName = previous.customName
  end
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
    local na, nb = Library.DisplayName(ga), Library.DisplayName(gb)
    if na ~= nb then return na < nb end
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

-- The library grouped by class: { { class, entries = { {key, guide}, ... } } },
-- firstClass first, then the other classes alphabetically. Entries within a
-- class are ordered as in List.
function Library:Groups(firstClass)
  local groups, byClass = {}, {}
  for _, entry in ipairs(self:List(firstClass)) do
    local class = entry.guide.class
    local group = byClass[class]
    if not group then
      group = { class = class, entries = {} }
      byClass[class] = group
      groups[#groups + 1] = group
    end
    group.entries[#group.entries + 1] = entry
  end
  table.sort(groups, function(a, b)
    if (a.class == firstClass) ~= (b.class == firstClass) then return a.class == firstClass end
    return a.class < b.class
  end)
  return groups
end

-- Sets a guide's custom name; a blank name goes back to the guide's title.
function Library:Rename(key, name)
  local guide = self.db.guides[key]
  if not guide then return end
  name = name and name:match("^%s*(.-)%s*$") or ""
  guide.customName = name ~= "" and name or nil
end
