-- A read-only text box with a URL selected, for Ctrl+C. The game cannot
-- open a browser or write to the clipboard itself.
local addonName, ns = ...

local CopyBox = {}
ns.CopyBox = CopyBox

local L = ns.L
local frame, edit, current

local function create()
  frame = ns.Skin.Window(CreateFrame("Frame", "FieldGuideCopyBox", UIParent))
  frame:SetSize(460, 96)
  frame:SetPoint("CENTER", 0, 120)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:EnableMouse(true)
  frame:Hide()
  tinsert(UISpecialFrames, "FieldGuideCopyBox")
  if frame.TitleText then frame.TitleText:SetText(L.COPY_TITLE) end

  edit = ns.Skin.Input(CreateFrame("EditBox", "FieldGuideCopyEditBox", frame))
  edit:SetSize(420, 24)
  edit:SetPoint("TOP", 0, -34)
  edit:SetAutoFocus(false)
  -- Read-only: any edit puts the URL back and selects it again.
  edit:SetScript("OnTextChanged", function(self, userInput)
    if userInput and self:GetText() ~= current then
      self:SetText(current); self:HighlightText()
    end
  end)
  edit:SetScript("OnEscapePressed", function() frame:Hide() end)
  edit:SetScript("OnEnterPressed", function() frame:Hide() end)
  edit:SetScript("OnEditFocusLost", function() frame:Hide() end)

  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOP", edit, "BOTTOM", 0, -6)
  hint:SetText(L.COPY_HINT)
end

function CopyBox.Show(url)
  if not url or url == "" then return end
  if not frame then create() end
  current = url
  edit:SetText(url)
  frame:Show()
  edit:SetFocus()
  edit:HighlightText()
end

-- A larger read-only box for long text (the AI prompt), all of it selected.
local big, bigEdit, bigText

local function createBig()
  big = ns.Skin.Window(CreateFrame("Frame", "FieldGuidePromptBox", UIParent))
  big:SetSize(560, 440)
  big:SetPoint("CENTER", 0, 40)
  big:SetFrameStrata("FULLSCREEN_DIALOG")
  big:SetMovable(true)
  big:EnableMouse(true)
  big:RegisterForDrag("LeftButton")
  big:SetScript("OnDragStart", big.StartMoving)
  big:SetScript("OnDragStop", big.StopMovingOrSizing)
  big:Hide()
  tinsert(UISpecialFrames, "FieldGuidePromptBox")

  local hint = big:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("BOTTOM", 0, 12)
  hint:SetText(L.PROMPT_HINT)

  local scroll = CreateFrame("ScrollFrame", "FieldGuidePromptScroll", big, "UIPanelScrollFrameTemplate")
  ns.Skin.ScrollBar(scroll)
  scroll:SetPoint("TOPLEFT", 16, -32)
  scroll:SetPoint("BOTTOMRIGHT", -24, 32)
  ns.Skin.Panel(scroll, ns.Skin.colors.input)
  bigEdit = CreateFrame("EditBox", "FieldGuidePromptEditBox", scroll)
  bigEdit:SetMultiLine(true)
  bigEdit:SetAutoFocus(false)
  bigEdit:SetMaxLetters(0)
  bigEdit:SetFontObject(ChatFontNormal)
  bigEdit:SetWidth(500)
  bigEdit:SetTextInsets(6, 6, 6, 6)
  bigEdit:SetScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(bigText); self:HighlightText() end
  end)
  bigEdit:SetScript("OnEscapePressed", function() big:Hide() end)
  scroll:SetScrollChild(bigEdit)
end

function CopyBox.ShowText(title, text)
  if not big then createBig() end
  bigText = text
  if big.TitleText then big.TitleText:SetText(title) end
  bigEdit:SetText(text)
  big:Show()
  bigEdit:SetFocus()
  bigEdit:HighlightText()
end
