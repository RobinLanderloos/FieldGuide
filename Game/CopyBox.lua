-- A read-only text box with a URL selected, for Ctrl+C. The game cannot
-- open a browser or write to the clipboard itself.
local addonName, ns = ...

local CopyBox = {}
ns.CopyBox = CopyBox

local L = ns.L
local frame, edit, current

local function create()
  frame = CreateFrame("Frame", "FieldGuideCopyBox", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(460, 96)
  frame:SetPoint("CENTER", 0, 120)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:EnableMouse(true)
  frame:Hide()
  tinsert(UISpecialFrames, "FieldGuideCopyBox")
  if frame.TitleText then frame.TitleText:SetText(L.COPY_TITLE) end

  edit = CreateFrame("EditBox", "FieldGuideCopyEditBox", frame, "InputBoxTemplate")
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
