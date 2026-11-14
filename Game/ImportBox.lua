-- The paste box for Guide Imports (ADR 0002: pasting is the only way in).
local addonName, ns = ...

local ImportBox = {}
ns.ImportBox = ImportBox

local L = ns.L
local frame, edit, result

local function import()
  -- The client's edit box escapes a pasted "|" as "||"; read it back as written.
  local pasted = (edit:GetText():gsub("||", "|"))
  local ok, lines = ns.ImportReport.Import(pasted, ns.library,
    { class = ns.Talents.PlayerClass(), live = ns.Talents.Live() })
  if ok then
    edit:SetText("")
    result:SetText("")
    frame:Hide()
    ns.GuideWindow.Show()
    ns.GuideWindow.SetStatus(table.concat(lines, "  "))
    for _, line in ipairs(lines) do print("|cff40c0ffFieldGuide:|r " .. line) end
  else
    result:SetText("|cffff6060" .. table.concat(lines, "\n") .. "|r")
  end
end

local function create()
  frame = CreateFrame("Frame", "FieldGuideImportBox", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(520, 420)
  frame:SetPoint("CENTER", 0, 40)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("DIALOG")
  frame:Hide()
  tinsert(UISpecialFrames, "FieldGuideImportBox")
  if frame.TitleText then frame.TitleText:SetText(L.IMPORT_TITLE) end

  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", 16, -32)
  hint:SetText(L.IMPORT_HINT)

  local scroll = CreateFrame("ScrollFrame", "FieldGuideImportScroll", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, -52)
  scroll:SetPoint("BOTTOMRIGHT", -34, 110)
  edit = CreateFrame("EditBox", "FieldGuideImportEditBox", scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetMaxLetters(0)
  edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(460)
  edit:SetScript("OnEscapePressed", function() frame:Hide() end)
  scroll:SetScrollChild(edit)
  scroll:EnableMouse(true)
  scroll:SetScript("OnMouseDown", function() edit:SetFocus() end)

  result = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  result:SetPoint("TOPLEFT", scroll, "BOTTOMLEFT", 0, -8)
  result:SetPoint("RIGHT", -16, 0)
  result:SetJustifyH("LEFT")
  result:SetJustifyV("TOP")
  result:SetHeight(60)

  local button = CreateFrame("Button", "FieldGuideImportButton", frame, "UIPanelButtonTemplate")
  button:SetSize(120, 24)
  button:SetPoint("BOTTOMRIGHT", -16, 12)
  button:SetText(L.IMPORT_BUTTON)
  button:SetScript("OnClick", import)
end

function ImportBox.Show()
  if not frame then create() end
  result:SetText("")
  frame:Show()
  edit:SetFocus()
end
