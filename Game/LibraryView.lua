-- The guide library inside the Guide window: one row per Guide with Use and
-- Delete (Delete asks once more before deleting; no game popup).
local addonName, ns = ...

local LibraryView = {}
ns.LibraryView = LibraryView

local L = ns.L
local ROW_H = 26
local panel, rows, pending = nil, {}, nil

local function row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Frame", "FieldGuideLibraryRow" .. i, panel)
  r:SetHeight(ROW_H)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
  r:SetPoint("RIGHT")
  r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  r.label:SetPoint("LEFT", 4, 0)
  r.label:SetPoint("RIGHT", -170, 0)
  r.label:SetJustifyH("LEFT")
  r.label:SetWordWrap(false)
  r.use = CreateFrame("Button", "FieldGuideLibraryUse" .. i, r, "UIPanelButtonTemplate")
  r.use:SetSize(70, 22)
  r.use:SetPoint("RIGHT", -88, 0)
  r.use:SetText(L.USE)
  r.delete = CreateFrame("Button", "FieldGuideLibraryDelete" .. i, r, "UIPanelButtonTemplate")
  r.delete:SetSize(80, 22)
  r.delete:SetPoint("RIGHT", -4, 0)
  rows[i] = r
  return r
end

function LibraryView.Create(parent)
  panel = CreateFrame("Frame", "FieldGuideLibrary", parent)
  panel:Hide()
  return panel
end

-- onUse(key) is called after a guide is chosen.
function LibraryView.Refresh(onUse)
  local lib = ns.library
  local _, class = UnitClass("player")
  local list = lib:List(class)
  for _, r in ipairs(rows) do r:Hide() end
  for i, entry in ipairs(list) do
    local r, g, key = row(i), entry.guide, entry.key
    local active = lib:Active() == g
    r.label:SetText(("%s%s - %s|r  |cff999999%s|r"):format(active and "|cffffd100" or "|cffffffff",
      g.title:gsub("|", "||"), g.variant:gsub("|", "||"), g.class))
    r.use:SetEnabled(not active)
    r.use:SetScript("OnClick", function()
      pending = nil
      lib:SetActive(key)
      onUse(key)
    end)
    r.delete:SetText(pending == key and L.CONFIRM_DELETE or L.DELETE)
    r.delete:SetScript("OnClick", function()
      if pending == key then
        pending = nil
        lib:Delete(key)
      else
        pending = key
      end
      LibraryView.Refresh(onUse)
    end)
    r:Show()
  end
  return #list
end

function LibraryView.Forget() pending = nil end
