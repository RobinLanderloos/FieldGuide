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

local function applyName(guide, customName, previous)
  customName = customName and customName:match("^%s*(.-)%s*$")
  if customName and customName ~= "" then
    guide.customName = customName
  elseif previous then
    guide.customName = previous.customName
  end
end

-- Returns key, "added" | "updated", previous guide (when updated).
-- customName (optional) is a display name; blank keeps the previous one.
function Library:Add(guide, customName)
  local key = Library.Key(guide)
  local previous = self.db.guides[key]
  applyName(guide, customName, previous)
  self.db.guides[key] = guide
  self:setActive(key)
  return key, previous and "updated" or "added", previous
end

-- Stores guide in place of the guide at oldKey, even when its Source page or
-- Variant changed (an updated guide). Characters that had the old guide active
-- or pinned follow it (db.moved). Returns like Add.
function Library:Replace(oldKey, guide, customName)
  local previous = self.db.guides[oldKey]
  if not previous then return self:Add(guide, customName) end
  local key = Library.Key(guide)
  if key ~= oldKey then
    self.db.guides[oldKey] = nil
    self.db.moved = self.db.moved or {}
    self.db.moved[key] = nil
    self.db.moved[oldKey] = key
  end
  applyName(guide, customName, previous)
  self.db.guides[key] = guide
  self:follow()
  self:setActive(key)
  return key, "updated", previous
end

-- Where a guide went after updates (nil when it is gone).
function Library:resolve(key)
  local moved, steps = self.db.moved or {}, 0
  while key and not self.db.guides[key] and steps < 50 do
    key, steps = moved[key], steps + 1
  end
  return key and self.db.guides[key] and key or nil
end

-- Points this character's active guide and Pin at updated guides.
function Library:follow()
  local active = self.char.active
  if not active or self.db.guides[active] then return end
  local key = self:resolve(active)
  if not key then return end
  self.char.active = key
  local pin = self.char.pin
  if pin and pin.guide == active then pin.guide = key end
end

function Library:Get(key)
  return self.db.guides[key]
end

function Library:Active()
  self:follow()
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
  for from, to in pairs(self.db.moved or {}) do
    if to == key then self.db.moved[from] = nil end
  end
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
