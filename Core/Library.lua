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

function Library:Add(guide)
  local key = Library.Key(guide)
  self.db.guides[key] = guide
  self.char.active = key
  return key
end

function Library:Get(key)
  return self.db.guides[key]
end

function Library:Active()
  return self.char.active and self.db.guides[self.char.active]
end
