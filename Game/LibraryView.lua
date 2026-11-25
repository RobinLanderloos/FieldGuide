-- The guide library inside the Guide window, grouped under class headings
-- (this character's class first): one row per Guide with View, Update,
-- Rename, Use and Delete (Delete asks once more before deleting; no game popup).
local addonName, ns = ...

local LibraryView = {}
ns.LibraryView = LibraryView

local L = ns.L
local ROW_H = 26
local HEADER_H = 24
local scroll, panel, rows, headers, pending, renaming = nil, nil, {}, {}, nil, nil

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
  r.label:SetPoint("RIGHT", -384, 0)
  r.label:SetJustifyH("LEFT")
  r.label:SetWordWrap(false)
  r.use = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideLibraryUse" .. i, r, ns.Skin.TEMPLATES.Button))
  r.use:SetSize(70, 22)
  r.use:SetPoint("RIGHT", -88, 0)
  r.use:SetText(L.USE)
  r.delete = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideLibraryDelete" .. i, r, ns.Skin.TEMPLATES.Button))
  r.delete:SetSize(80, 22)
  r.delete:SetPoint("RIGHT", -4, 0)
  r.rename = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideLibraryRename" .. i, r, ns.Skin.TEMPLATES.Button))
  r.rename:SetSize(76, 22)
  r.rename:SetPoint("RIGHT", -162, 0)
  r.rename:SetText(L.RENAME)
  r.view = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideLibraryView" .. i, r, ns.Skin.TEMPLATES.Button))
  r.view:SetSize(60, 22)
  r.view:SetPoint("RIGHT", -316, 0)
  r.view:SetText(L.VIEW)
  r.update = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideLibraryUpdate" .. i, r, ns.Skin.TEMPLATES.Button))
  r.update:SetSize(70, 22)
  r.update:SetPoint("RIGHT", -242, 0)
  r.update:SetText(L.UPDATE)
  r.edit = ns.Skin.Input(ns.Skin.Create("EditBox", "FieldGuideLibraryNameEdit" .. i, r, ns.Skin.TEMPLATES.Input))
  r.edit:SetHeight(22)
  r.edit:SetPoint("LEFT", 18, 0)
  r.edit:SetPoint("RIGHT", -384, 0)
  r.edit:SetAutoFocus(false)
  r.edit:SetMaxLetters(60)
  r.edit:Hide()
  rows[i] = r
  return r
end

-- The rows sit in a scroll frame so a long library scrolls instead of
-- running past the window's bottom edge.
function LibraryView.Create(parent)
  scroll = CreateFrame("ScrollFrame", "FieldGuideLibrary", parent, "UIPanelScrollFrameTemplate")
  ns.Skin.ScrollBar(scroll)
  panel = CreateFrame("Frame", "FieldGuideLibraryRows", scroll)
  panel:SetSize(400, 10)
  scroll:SetScrollChild(panel)
  scroll:SetScript("OnSizeChanged", function(_, w) panel:SetWidth(w) end)
  scroll:Hide()
  return scroll
end

-- Shows the scroll bar only when the rows don't fit.
local function fit(height)
  local w = scroll:GetWidth() or 0
  if w > 0 then panel:SetWidth(w) end
  panel:SetHeight(math.max(10, height))
  local bar = scroll.ScrollBar or _G["FieldGuideLibraryScrollBar"]
  local fits = height <= (scroll:GetHeight() or 0)
  if bar and type(bar) == "table" then bar:SetShown(not fits) end
  if fits then scroll:SetVerticalScroll(0) end
end

-- onUse(key) is called after a guide is chosen; onView(key) when one is
-- opened for reading without making it active.
function LibraryView.Refresh(onUse, onView)
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
        (ns.Library.DisplayName(guide):gsub("|", "||")), (guide.variant:gsub("|", "||"))))
      r.use:SetEnabled(not active)
      r.use:SetScript("OnClick", function()
        pending = nil
        lib:SetActive(key)
        onUse(key)
      end)
      r.view:SetScript("OnClick", function()
        pending, renaming = nil, nil
        onView(key)
      end)
      r.update:SetScript("OnClick", function()
        pending, renaming = nil, nil
        ns.ImportBox.Show(key)
      end)
      local editing = renaming == key
      r.label:SetShown(not editing)
      r.edit:SetShown(editing)
      if editing then
        -- The edit box shows a "|" written as "||"; it reads back the same way.
        r.edit:SetText((ns.Library.DisplayName(guide):gsub("|", "||")))
        r.edit:SetFocus()
        r.edit:HighlightText()
      end
      r.edit:SetScript("OnEnterPressed", function(self)
        renaming = nil
        lib:Rename(key, ((self:GetText() or ""):gsub("||", "|")))
        LibraryView.Refresh(onUse, onView)
      end)
      r.edit:SetScript("OnEscapePressed", function()
        renaming = nil
        LibraryView.Refresh(onUse, onView)
      end)
      r.rename:SetText(editing and L.SAVE or L.RENAME)
      r.rename:SetScript("OnClick", function()
        if renaming == key then
          renaming = nil
          lib:Rename(key, ((r.edit:GetText() or ""):gsub("||", "|")))
        else
          renaming, pending = key, nil
        end
        LibraryView.Refresh(onUse, onView)
      end)
      r.delete:SetText(pending == key and L.CONFIRM_DELETE or L.DELETE)
      r.delete:SetScript("OnClick", function()
        if pending == key then
          pending = nil
          lib:Delete(key)
        else
          pending = key
        end
        LibraryView.Refresh(onUse, onView)
      end)
      y = place(r, y, ROW_H)
    end
  end
  fit(y)
  return i
end

function LibraryView.Forget() pending, renaming = nil, nil end
