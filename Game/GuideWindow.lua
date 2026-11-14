-- The Guide window: header, section list on the left, section text on the right.
local addonName, ns = ...

local GuideWindow = {}
ns.GuideWindow = GuideWindow

local L = ns.L
local LIST_W, ROW_H = 160, 22
local frame, header, sub, link, pinButton, guidesButton, status, scroll, content, text, empty, library
local buttons, selected, mode, showAll = {}, 1, "guide", false
local allLevels

local function create()
  frame = CreateFrame("Frame", "FieldGuideWindow", UIParent, "BasicFrameTemplateWithInset")
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
  header:SetPoint("TOPLEFT", 16, -34)
  header:SetJustifyH("LEFT")
  sub = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
  sub:SetJustifyH("LEFT")

  link = CreateFrame("Button", "FieldGuideLinkButton", frame, "UIPanelButtonTemplate")
  link:SetSize(70, 22)
  link:SetPoint("TOPRIGHT", -14, -32)
  link:SetText(L.LINK_BUTTON)
  link:SetScript("OnClick", function()
    local guide = ns.library and ns.library:Active()
    if guide then ns.CopyBox.Show(guide.url) end
  end)

  guidesButton = CreateFrame("Button", "FieldGuideGuidesButton", frame, "UIPanelButtonTemplate")
  guidesButton:SetSize(80, 22)
  guidesButton:SetPoint("RIGHT", link, "LEFT", -4, 0)
  guidesButton:SetText(L.GUIDES_BUTTON)
  guidesButton:SetScript("OnClick", function()
    mode = mode == "library" and "guide" or "library"
    ns.LibraryView.Forget()
    GuideWindow.Refresh()
  end)

  allLevels = CreateFrame("CheckButton", "FieldGuideShowAllLevels", frame, "UICheckButtonTemplate")
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

  pinButton = CreateFrame("Button", "FieldGuidePinButton", frame, "UIPanelButtonTemplate")
  pinButton:SetSize(60, 22)
  pinButton:SetPoint("RIGHT", guidesButton, "LEFT", -4, 0)
  pinButton:SetText(L.PIN_BUTTON)
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
  scroll:SetPoint("TOPLEFT", 16 + LIST_W + 12, -80)
  scroll:SetPoint("BOTTOMRIGHT", -32, 32)
  content = CreateFrame("Frame", "FieldGuideContent", scroll)
  content:SetHyperlinksEnabled(true)
  content:SetScript("OnHyperlinkClick", function(_, link)
    local url = ns.Markup.LinkURL(link)
    if url then ns.CopyBox.Show(url) end
  end)
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
end

local function button(i)
  local b = buttons[i]
  if b then return b end
  b = CreateFrame("Button", "FieldGuideSectionButton" .. i, frame)
  b:SetSize(LIST_W, ROW_H)
  b:SetPoint("TOPLEFT", 16, -80 - (i - 1) * ROW_H)
  b:SetNormalFontObject("GameFontNormal")
  b:SetHighlightFontObject("GameFontHighlight")
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
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
    mode, selected = "guide", 1
    GuideWindow.Refresh()
  end)
  empty:SetShown(count == 0)
end

function GuideWindow.Refresh()
  if not frame then return end
  local guide = ns.library and ns.library:Active()
  for _, b in ipairs(buttons) do b:Hide() end
  library:Hide()
  allLevels:Hide()
  link:SetShown(guide and true or false)
  pinButton:SetShown(guide and mode == "guide" or false)
  if not guide and next(ns.library.db.guides) then mode = "library" end
  scroll:SetShown(mode == "guide")
  if mode == "library" then return showLibrary() end

  empty:SetShown(not guide)
  header:SetShown(guide and true or false)
  sub:SetShown(guide and true or false)
  if not guide then
    text:SetText("")
    return
  end
  header:SetText(guide.title)
  local parts = { guide.variant }
  if guide.author then parts[#parts + 1] = L.BY:format(guide.author) end
  if guide.updated then parts[#parts + 1] = L.UPDATED_ON:format(guide.updated) end
  sub:SetText(table.concat(parts, "  \194\183  "))

  if selected > #guide.sections then selected = 1 end
  for i, section in ipairs(guide.sections) do
    local b = button(i)
    b:SetText(section.title)
    b:Show()
    if i == selected then b:LockHighlight() else b:UnlockHighlight() end
  end
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
  selected, mode = 1, "guide"
  frame:Show()
  GuideWindow.Refresh()
end

function GuideWindow.Toggle()
  if frame and frame:IsShown() then frame:Hide() else GuideWindow.Show() end
end
