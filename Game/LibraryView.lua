-- The guide library inside the Guide window, grouped under class headings
-- (this character's class first): one row per Guide with Use and Delete
-- (Delete asks once more before deleting; no game popup).
local addonName, ns = ...

local LibraryView = {}
ns.LibraryView = LibraryView

local L = ns.L
local ROW_H = 26
local HEADER_H = 24
local panel, rows, headers, pending = nil, {}, {}, nil

local function header(i)
  if headers[i] then return headers[i] end
  local h = CreateFrame("Frame", "FieldGuideLibraryHeader" .. i, panel)
  h:SetHeight(HEADER_H)
  h.label = h:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h.label:SetPoint("BOTTOMLEFT", 2, 3)
  h.line = h:CreateTexture(nil, "ARTWORK")
  h.line:SetHeight(1)
  h.line:SetPoint("BOTTOMLEFT", 0, 0)
  h.line:SetPoint("BOTTOMRIGHT", 0, 0)
  h.line:SetColorTexture(1, 1, 1, 0.15)
  headers[i] = h
  return h
end

local function className(class)
  local names = LOCALIZED_CLASS_NAMES_MALE
  return names and names[class] or (class:sub(1, 1) .. class:sub(2):lower())
end

local function classColour(class)
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  return c and c.colorStr or "ffffd100"
end

local function place(frame, y, height)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -y)
  frame:SetPoint("RIGHT", panel, "RIGHT", 0, 0)
  frame:Show()
  return y + height
end

local function row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Frame", "FieldGuideLibraryRow" .. i, panel)
  r:SetHeight(ROW_H)
  r.label = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  r.label:SetPoint("LEFT", 14, 0)
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
  for _, r in ipairs(rows) do r:Hide() end
  for _, h in ipairs(headers) do h:Hide() end
  local y, i = 0, 0
  for g, group in ipairs(lib:Groups(class)) do
    local h = header(g)
    h.label:SetText(("|c%s%s|r"):format(classColour(group.class), className(group.class)))
    y = place(h, y + (g > 1 and 8 or 0), HEADER_H)
    for _, entry in ipairs(group.entries) do
      i = i + 1
      local r, guide, key = row(i), entry.guide, entry.key
      local active = lib:Active() == guide
      r.label:SetText(("%s%s - %s|r"):format(active and "|cffffd100" or "|cffffffff",
        (guide.title:gsub("|", "||")), (guide.variant:gsub("|", "||"))))
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
      y = place(r, y, ROW_H)
    end
  end
  return i
end

function LibraryView.Forget() pending = nil end
