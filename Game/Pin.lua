-- The Pin: a small heads-up frame with one pinned section (rotation filtered
-- by level) and an optional next-talent line. State is saved per character.
local addonName, ns = ...

local Pin = {}
ns.Pin = Pin

local L = ns.L
local frame, nextLine, scroll, content, text, nextToggle, hint

local function state() return ns.library:PinState() end

local function savePosition()
  local s = state()
  s.left, s.top = frame:GetLeft(), frame:GetTop()
  s.width, s.height = frame:GetWidth(), frame:GetHeight()
end

local function create()
  local s = state()
  frame = CreateFrame("Frame", "FieldGuidePin", UIParent, "BackdropTemplate")
  frame:SetSize(s.width or 300, s.height or 220)
  if s.left and s.top then
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", s.left, s.top)
  else
    frame:SetPoint("RIGHT", -60, 0)
  end
  if frame.SetBackdrop then
    frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    frame:SetBackdropColor(0, 0, 0, 0.75)
  end
  frame:SetMovable(true)
  frame:SetResizable(true)
  if frame.SetResizeBounds then frame:SetResizeBounds(180, 80, 800, 900) end
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); savePosition() end)
  frame:Hide()

  local close = CreateFrame("Button", "FieldGuidePinClose", frame, "UIPanelCloseButton")
  close:SetSize(22, 22)
  close:SetPoint("TOPRIGHT", 2, 2)
  close:SetScript("OnClick", function() Pin.SetShown(false) end)

  local link = CreateFrame("Button", "FieldGuidePinLink", frame, "UIPanelButtonTemplate")
  link:SetSize(40, 18)
  link:SetPoint("RIGHT", close, "LEFT", -2, 0)
  link:SetText(L.LINK_BUTTON)
  link:SetScript("OnClick", function()
    local guide = ns.library:Active()
    if guide then ns.CopyBox.Show(guide.url) end
  end)

  nextToggle = CreateFrame("Button", "FieldGuidePinNextToggle", frame, "UIPanelButtonTemplate")
  nextToggle:SetSize(46, 18)
  nextToggle:SetPoint("RIGHT", link, "LEFT", -2, 0)
  nextToggle:SetText(L.PIN_NEXT_TOGGLE)
  nextToggle:SetScript("OnClick", function()
    local st = state()
    st.hideNext = not st.hideNext
    Pin.Refresh()
  end)

  local titleText = frame:CreateFontString("FieldGuidePinTitle", "OVERLAY", "GameFontNormalSmall")
  titleText:SetPoint("TOPLEFT", 8, -8)
  titleText:SetPoint("RIGHT", nextToggle, "LEFT", -4, 0)
  titleText:SetJustifyH("LEFT")
  titleText:SetWordWrap(false)
  frame.titleText = titleText

  nextLine = frame:CreateFontString("FieldGuidePinNext", "OVERLAY", "GameFontHighlightSmall")
  nextLine:SetPoint("TOPLEFT", 8, -26)
  nextLine:SetPoint("RIGHT", -8, 0)
  nextLine:SetJustifyH("LEFT")

  scroll = CreateFrame("ScrollFrame", "FieldGuidePinScroll", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("BOTTOMRIGHT", -26, 8)
  content = CreateFrame("Frame", "FieldGuidePinContent", scroll)
  content:SetSize(260, 10)
  content:SetHyperlinksEnabled(true)
  content:SetScript("OnHyperlinkClick", function(_, link)
    local url = ns.Markup.LinkURL(link)
    if url then ns.CopyBox.Show(url) end
  end)
  scroll:SetScrollChild(content)
  text = content:CreateFontString("FieldGuidePinText", "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("TOPLEFT")
  text:SetJustifyH("LEFT")
  text:SetJustifyV("TOP")
  text:SetSpacing(2)
  scroll:SetScript("OnSizeChanged", function(_, w) content:SetWidth(w); text:SetWidth(w) end)

  hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("CENTER", 0, -8)
  hint:SetText(L.PIN_HINT)

  -- Resize grip; re-anchor top-left first so the frame follows the mouse.
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(14, 14)
  grip:SetPoint("BOTTOMRIGHT", -2, 2)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetScript("OnMouseDown", function()
    local left, top = frame:GetLeft(), frame:GetTop()
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    frame:StartSizing("BOTTOMRIGHT")
  end)
  grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); savePosition(); Pin.Refresh() end)

  frame:RegisterEvent("PLAYER_LEVEL_UP")
  frame:SetScript("OnEvent", function()
    Pin.Refresh()
    C_Timer.After(0.2, Pin.Refresh)
  end)
  ns.Talents.OnChange(function() if frame:IsShown() then Pin.Refresh() end end)
end

function Pin.Refresh()
  if not frame then return end
  local guide = ns.library:Active()
  local section = ns.library:Pinned()
  local st = state()
  frame.titleText:SetText(section and section.title:gsub("|", "||") or L.WINDOW_TITLE)

  local next
  if guide and not st.hideNext then
    local ev, talents = ns.Talents.Evaluate(guide)
    next = talents and ns.Display.NextTalent(talents, ev)
  end
  nextLine:SetText(next or "")
  nextLine:SetShown(next and true or false)
  nextToggle:SetText(st.hideNext and L.PIN_NEXT_OFF or L.PIN_NEXT_TOGGLE)

  scroll:ClearAllPoints()
  scroll:SetPoint("TOPLEFT", 8, next and -44 or -26)
  scroll:SetPoint("BOTTOMRIGHT", -26, 8)
  hint:SetShown(not section and not next)
  text:SetText(section and ns.Display.SectionText(section, {
    level = UnitLevel("player"),
    talents = section.kind == "talents" and ns.Talents.Evaluate(guide) or nil,
  }) or "")
  content:SetHeight(math.max(10, text:GetHeight()))
end

function Pin.SetShown(shown)
  if not frame then create() end
  state().shown = shown and true or false
  frame:SetShown(shown)
  if shown then Pin.Refresh() end
end

function Pin.Toggle()
  Pin.SetShown(not (frame and frame:IsShown()))
end

-- Pin a section of the active guide (replaces the pinned one) and show the Pin.
function Pin.PinSection(title)
  ns.library:Pin(title)
  Pin.SetShown(true)
end

-- Restore after login.
function Pin.Restore()
  if state().shown then Pin.SetShown(true) end
end

-- Key bindings (Bindings.xml).
BINDING_HEADER_FIELDGUIDE = "FieldGuide"
BINDING_NAME_FIELDGUIDE_TOGGLE_PIN = L.BINDING_TOGGLE_PIN
BINDING_NAME_FIELDGUIDE_TOGGLE_WINDOW = L.BINDING_TOGGLE_WINDOW
function FieldGuide_TogglePin() Pin.Toggle() end
function FieldGuide_ToggleWindow() ns.GuideWindow.Toggle() end
