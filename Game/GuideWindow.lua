-- The Guide window: header, section list on the left, section text on the right.
local addonName, ns = ...

local GuideWindow = {}
ns.GuideWindow = GuideWindow

local L = ns.L
local LIST_W, ROW_H = 160, 22
local LIST_BAR = 14 -- room taken from the list for its scroll bar
local listScroll, listChild
local frame, header, sub, link, pinButton, useButton, importButton, guidesButton, status, scroll, content, text, empty, library
local buttons, selected, mode, showAll = {}, 1, "guide", false
local allLevels
local viewKey -- a guide opened from the library for reading; nil = the active guide

-- The guide the window shows: the one being viewed, else the active one.
local function shownGuide()
  local lib = ns.library
  if not lib then return nil end
  return viewKey and lib:Get(viewKey) or lib:Active()
end

local function viewingOther()
  local guide = shownGuide()
  return guide ~= nil and guide ~= ns.library:Active()
end

local function create()
  frame = ns.Skin.Window(ns.Skin.Create("Frame", "FieldGuideWindow", UIParent, ns.Skin.TEMPLATES.Window))
  frame:SetSize(640, 460)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("HIGH")
  frame:Hide()
  tinsert(UISpecialFrames, "FieldGuideWindow")
  if frame.TitleText then frame.TitleText:SetText(L.WINDOW_TITLE) end

  header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetTextColor(unpack(ns.Skin.accent))
  header:SetPoint("TOPLEFT", 16, -34)
  header:SetJustifyH("LEFT")
  sub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  sub:SetJustifyH("LEFT")

  link = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideLinkButton", frame, ns.Skin.TEMPLATES.Button))
  link:SetSize(70, 22)
  link:SetPoint("TOPRIGHT", -14, -32)
  link:SetText(L.LINK_BUTTON)
  link:SetScript("OnClick", function()
    local guide = shownGuide()
    if guide then ns.CopyBox.Show(guide.url) end
  end)

  guidesButton = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideGuidesButton", frame, ns.Skin.TEMPLATES.Button))
  guidesButton:SetSize(80, 22)
  guidesButton:SetPoint("RIGHT", link, "LEFT", -4, 0)
  guidesButton:SetText(L.GUIDES_BUTTON)
  guidesButton:SetScript("OnClick", function()
    mode = mode == "library" and "guide" or "library"
    ns.LibraryView.Forget()
    GuideWindow.Refresh()
  end)

  allLevels = ns.Skin.Check(ns.Skin.Create("CheckButton", "FieldGuideShowAllLevels", frame, ns.Skin.TEMPLATES.Check))
  allLevels:SetSize(24, 24)
  allLevels:SetPoint("BOTTOMRIGHT", -110, 6)
  if allLevels.Text then allLevels.Text:SetText(L.SHOW_ALL_LEVELS) end
  allLevels:SetScript("OnClick", function(self)
    showAll = not showAll
    self:SetChecked(showAll)
    GuideWindow.Refresh()
  end)

  frame:RegisterEvent("PLAYER_LEVEL_UP")
  frame:SetScript("OnEvent", function()
    -- UnitLevel lags PLAYER_LEVEL_UP by a frame; refresh now and once more.
    GuideWindow.Refresh()
    C_Timer.After(0.2, GuideWindow.Refresh)
  end)

  ns.Talents.OnChange(function()
    if frame:IsShown() then GuideWindow.Refresh() end
  end)

  library = ns.LibraryView.Create(frame)
  library:SetPoint("TOPLEFT", 16, -80)
  library:SetPoint("BOTTOMRIGHT", -16, 32)

  importButton = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideWindowImportButton", frame, ns.Skin.TEMPLATES.Button))
  importButton:SetSize(70, 22)
  importButton:SetPoint("RIGHT", guidesButton, "LEFT", -4, 0)
  importButton:SetText(L.IMPORT_BUTTON)
  importButton:SetScript("OnClick", function() ns.ImportBox.Show() end)

  pinButton = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuidePinButton", frame, ns.Skin.TEMPLATES.Button))
  pinButton:SetSize(60, 22)
  pinButton:SetPoint("RIGHT", importButton, "LEFT", -4, 0)
  pinButton:SetText(L.PIN_BUTTON)
  -- While viewing another guide, Use takes the Pin button's place.
  useButton = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideWindowUseButton", frame, ns.Skin.TEMPLATES.Button))
  useButton:SetSize(60, 22)
  useButton:SetPoint("RIGHT", importButton, "LEFT", -4, 0)
  useButton:SetText(L.USE)
  useButton:SetScript("OnClick", function()
    if viewKey then ns.library:SetActive(viewKey) end
    viewKey = nil
    GuideWindow.Refresh()
  end)
  -- Title and subtitle stop short of the header buttons.
  header:SetPoint("RIGHT", pinButton, "LEFT", -8, 0)
  header:SetWordWrap(false)
  sub:SetPoint("RIGHT", pinButton, "LEFT", -8, 0)
  sub:SetWordWrap(false)
  pinButton:SetScript("OnClick", function()
    local guide = ns.library and ns.library:Active()
    local section = guide and guide.sections[selected]
    if section then ns.Pin.PinSection(section.title) end
  end)

  status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  status:SetPoint("BOTTOMLEFT", 16, 12)
  status:SetJustifyH("LEFT")

  empty = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  empty:SetPoint("CENTER")
  empty:SetText(L.NO_ACTIVE_GUIDE)

  scroll = CreateFrame("ScrollFrame", "FieldGuideContentScroll", frame, "UIPanelScrollFrameTemplate")
  ns.Skin.ScrollBar(scroll)
  scroll:SetPoint("TOPLEFT", 16 + LIST_W + 12, -80)
  scroll:SetPoint("BOTTOMRIGHT", -22, 32)
  -- Lines between the header, the section list, the text and the footer.
  local top = ns.Skin.Divider(frame)
  top:SetPoint("TOPLEFT", 1, -74)
  top:SetPoint("TOPRIGHT", -1, -74)
  local footer = ns.Skin.Divider(frame)
  footer:SetPoint("BOTTOMLEFT", 1, 28)
  footer:SetPoint("BOTTOMRIGHT", -1, 28)
  frame.listLine = ns.Skin.Divider(frame)
  frame.listLine:SetWidth(1)
  frame.listLine:SetPoint("TOPLEFT", 16 + LIST_W + 5, -74)
  frame.listLine:SetPoint("BOTTOMLEFT", 16 + LIST_W + 5, 28)
  content = CreateFrame("Frame", "FieldGuideContent", scroll)
  ns.References.Attach(content)
  content:SetSize(400, 10)
  scroll:SetScrollChild(content)
  text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("TOPLEFT")
  text:SetWidth(400)
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")
  text:SetSpacing(3)
  scroll:SetScript("OnSizeChanged", function(_, w)
    content:SetWidth(w); text:SetWidth(w)
  end)

  -- The section list scrolls when a guide has more sections than fit. Its
  -- scroll bar sits in the gap between the list and the section text.
  listScroll = CreateFrame("ScrollFrame", "FieldGuideSectionScroll", frame, "UIPanelScrollFrameTemplate")
  ns.Skin.ScrollBar(listScroll)
  listScroll:SetPoint("TOPLEFT", 16, -80)
  listScroll:SetPoint("BOTTOMLEFT", 16, 32)
  listScroll:SetWidth(LIST_W - LIST_BAR)
  listChild = CreateFrame("Frame", "FieldGuideSectionList", listScroll)
  listChild:SetSize(LIST_W - LIST_BAR, 10)
  listScroll:SetScrollChild(listChild)
end

-- Shows the list's scroll bar only when the rows don't fit.
local function fitList(count)
  local rows = count * ROW_H
  listChild:SetHeight(math.max(10, rows))
  local bar = listScroll.ScrollBar or _G["FieldGuideSectionScrollScrollBar"]
  local fits = rows <= (listScroll:GetHeight() or 0)
  if bar and type(bar) == "table" then bar:SetShown(not fits) end
  if fits then listScroll:SetVerticalScroll(0) end
end

local function button(i)
  local b = buttons[i]
  if b then return b end
  b = CreateFrame("Button", "FieldGuideSectionButton" .. i, listChild)
  b:SetSize(LIST_W - LIST_BAR, ROW_H)
  b:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
  b:SetNormalFontObject("GameFontHighlight")
  b:SetHighlightFontObject("GameFontHighlight")
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  fs:SetPoint("LEFT", 10, 0); fs:SetPoint("RIGHT", -4, 0)
  fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
  b:SetFontString(fs)
  -- Hover and the chosen section: a soft wash with an accent bar on the left.
  local a = ns.Skin.accent
  local wash = b:CreateTexture(nil, "HIGHLIGHT")
  wash:SetAllPoints(); wash:SetColorTexture(a[1], a[2], a[3], 0.14)
  local bar = b:CreateTexture(nil, "HIGHLIGHT")
  bar:SetPoint("TOPLEFT"); bar:SetPoint("BOTTOMLEFT"); bar:SetWidth(2)
  bar:SetColorTexture(a[1], a[2], a[3], 1)
  b:SetScript("OnClick", function()
    selected, mode = i, "guide"
    GuideWindow.Refresh()
  end)
  buttons[i] = b
  return b
end

local function showLibrary()
  header:SetText(L.LIBRARY_TITLE)
  sub:SetText("")
  header:Show(); sub:Show()
  library:Show()
  local count = ns.LibraryView.Refresh(function()
    mode, selected, viewKey = "guide", 1, nil
    GuideWindow.Refresh()
  end, function(key)
    mode, selected, viewKey = "guide", 1, key
    GuideWindow.Refresh()
  end)
  empty:SetShown(count == 0)
end

function GuideWindow.Refresh()
  if not frame then return end
  local guide = shownGuide()
  local other = viewingOther()
  if not other then viewKey = nil end
  for _, b in ipairs(buttons) do b:Hide() end
  library:Hide()
  allLevels:Hide()
  link:SetShown(guide and true or false)
  pinButton:SetShown(guide and mode == "guide" and not other or false)
  useButton:SetShown(mode == "guide" and other)
  if not guide and next(ns.library.db.guides) then mode = "library" end
  scroll:SetShown(mode == "guide")
  listScroll:SetShown(mode == "guide" and guide and true or false)
  frame.listLine:SetShown(mode == "guide" and guide and true or false)
  if mode == "library" then return showLibrary() end

  empty:SetShown(not guide)
  header:SetShown(guide and true or false)
  sub:SetShown(guide and true or false)
  if not guide then
    text:SetText("")
    return
  end
  local function esc(t) return (t:gsub("|", "||")) end
  header:SetText(esc(ns.Library.DisplayName(guide)))
  local parts = { esc(guide.variant) }
  if other then table.insert(parts, 1, L.NOT_IN_USE) end
  if guide.customName then parts[#parts + 1] = esc(guide.title) end
  if guide.author then parts[#parts + 1] = L.BY:format(esc(guide.author)) end
  if guide.updated then parts[#parts + 1] = L.UPDATED_ON:format(guide.updated) end
  sub:SetText(table.concat(parts, "  \194\183  "))

  if selected > #guide.sections then selected = 1 end
  for i, section in ipairs(guide.sections) do
    local b = button(i)
    b:SetText((section.title:gsub("|", "||")))
    b:Show()
    if i == selected then b:LockHighlight() else b:UnlockHighlight() end
  end
  fitList(#guide.sections)
  local section = guide.sections[selected]
  allLevels:SetShown(section and section.kind == "rotation" or false)
  text:SetText(section and ns.Display.SectionText(section, {
    level = UnitLevel("player"), showAll = showAll,
    talents = section.kind == "talents" and ns.Talents.Evaluate(guide) or nil,
  }) or "")
  content:SetHeight(math.max(10, text:GetHeight()))
end

function GuideWindow.SetStatus(message)
  if not frame then create() end
  status:SetText(message or "")
end

function GuideWindow.Show()
  if not frame then create() end
  selected, mode, viewKey = 1, "guide", nil
  frame:Show()
  GuideWindow.Refresh()
end

function GuideWindow.Toggle()
  if frame and frame:IsShown() then frame:Hide() else GuideWindow.Show() end
end
