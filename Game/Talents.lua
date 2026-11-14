-- Reads the character's live talents. On WoW Forever the vanilla trees run on
-- the retail trait system: the active config's one tree holds all three class
-- trees (same reading as EllesmereUI.ForeverTalentTrees).
local addonName, ns = ...

local Talents = {}
ns.Talents = Talents

local listeners = {}

local function nameOf(configID, info)
  local entryID = info.activeEntry and info.activeEntry.entryID or info.entryIDs[1]
  local entry = entryID and C_Traits.GetEntryInfo(configID, entryID)
  local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
  if not def then return end
  local name = def.overrideName
  if (not name or name == "") and def.spellID then name = C_Spell.GetSpellName(def.spellID) end
  return name, def.spellID
end

-- normalized name -> { name, rank, max, spellID }, or nil while there is no tree.
function Talents.Live()
  if not (C_ClassTalents and C_Traits) then return nil end
  local configID = C_ClassTalents.GetActiveConfigID()
  local config = configID and C_Traits.GetConfigInfo(configID)
  local treeID = config and config.treeIDs and config.treeIDs[1]
  if not treeID then return nil end
  local live = {}
  for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID)) do
    local info = C_Traits.GetNodeInfo(configID, nodeID)
    if info and info.isVisible and info.entryIDs and info.entryIDs[1] then
      local name, spellID = nameOf(configID, info)
      if name then
        live[ns.LevelingPath.Normalize(name)] = {
          name = name, spellID = spellID, nodeID = nodeID,
          rank = info.currentRank or info.activeRank or 0, max = info.maxRanks or 0,
        }
      end
    end
  end
  return live
end

function Talents.PlayerClass()
  local _, class = UnitClass("player")
  return class
end

-- The evaluation of a guide's Leveling Path for this character, or nil when
-- the guide has none. Another class's guide is evaluated as "not checked".
function Talents.Evaluate(guide)
  if not guide then return nil end
  for _, section in ipairs(guide.sections) do
    if section.kind == "talents" then
      local live = guide.class == Talents.PlayerClass() and Talents.Live() or nil
      return ns.LevelingPath.Evaluate(section.steps, live), section
    end
  end
end

function Talents.OnChange(fn) listeners[#listeners + 1] = fn end

local watcher = CreateFrame("Frame")
for _, event in ipairs({ "TRAIT_CONFIG_UPDATED", "TRAIT_NODE_CHANGED", "PLAYER_TALENT_UPDATE",
  "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "PLAYER_LEVEL_UP" }) do
  watcher:RegisterEvent(event)
end
watcher:SetScript("OnEvent", function(_, event, ...)
  for _, fn in ipairs(listeners) do fn(event, ...) end
end)
