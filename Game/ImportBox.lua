-- The paste box for Guide Imports (ADR 0002: pasting is the only way in).
local addonName, ns = ...

local ImportBox = {}
ns.ImportBox = ImportBox

local L = ns.L
local frame, edit, nameBox, result, hint, replaceKey

local function import()
  -- The client's edit box escapes a pasted "|" as "||"; read it back as written.
  local pasted = (edit:GetText():gsub("||", "|"))
  local name = ((nameBox:GetText() or ""):gsub("||", "|"))
  local ok, lines = ns.ImportReport.Import(pasted, ns.library,
    { class = ns.Talents.PlayerClass(), live = ns.Talents.Live() }, name, replaceKey)
  if ok then
    edit:SetText("")
    nameBox:SetText("")
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
  frame = ns.Skin.Window(ns.Skin.Create("Frame", "FieldGuideImportBox", UIParent, ns.Skin.TEMPLATES.Window))
  frame:SetSize(520, 460)
  frame:SetPoint("CENTER", 0, 40)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetFrameStrata("DIALOG")
  frame:Hide()
  tinsert(UISpecialFrames, "FieldGuideImportBox")

  hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", 16, -32)
  hint:SetPoint("RIGHT", -16, 0)
  hint:SetJustifyH("LEFT")
  hint:SetWordWrap(false)

  local scroll = CreateFrame("ScrollFrame", "FieldGuideImportScroll", frame, "UIPanelScrollFrameTemplate")
  ns.Skin.ScrollBar(scroll)
  scroll:SetPoint("TOPLEFT", 16, -52)
  scroll:SetPoint("BOTTOMRIGHT", -24, 140)
  ns.Skin.Panel(scroll, ns.Skin.colors.input)
  edit = CreateFrame("EditBox", "FieldGuideImportEditBox", scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetMaxLetters(0)
  edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(460)
  edit:SetTextInsets(6, 6, 6, 6)
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

  local button = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideImportButton", frame, ns.Skin.TEMPLATES.Button))
  button:SetSize(120, 24)
  button:SetPoint("BOTTOMRIGHT", -16, 12)
  button:SetText(L.IMPORT_BUTTON)
  button:SetScript("OnClick", import)

  -- Optional display name for the guide (ADR 0003: identity stays URL + Variant).
  nameBox = ns.Skin.Input(ns.Skin.Create("EditBox", "FieldGuideImportNameBox", frame, ns.Skin.TEMPLATES.Input))
  -- Its own row above the buttons, label on the left, field filling the rest.
  nameBox:SetHeight(22)
  nameBox:SetPoint("BOTTOMLEFT", 132, 46)
  nameBox:SetPoint("BOTTOMRIGHT", -18, 46)
  nameBox:SetAutoFocus(false)
  nameBox:SetMaxLetters(60)
  nameBox:SetScript("OnEscapePressed", function() frame:Hide() end)
  nameBox:SetScript("OnEnterPressed", import)
  local nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nameLabel:SetPoint("RIGHT", nameBox, "LEFT", -10, 0)
  nameLabel:SetJustifyH("RIGHT")
  nameLabel:SetText(L.IMPORT_NAME)

  local prompt = ns.Skin.Button(ns.Skin.Create("Button", "FieldGuideImportPromptButton", frame, ns.Skin.TEMPLATES.Button))
  prompt:SetSize(120, 24)
  prompt:SetPoint("BOTTOMLEFT", 16, 12)
  prompt:SetText(L.PROMPT_BUTTON)
  prompt:SetScript("OnClick", function() ns.CopyBox.ShowText(L.PROMPT_TITLE, ns.AIPrompt.TEXT) end)
end

-- key (optional): the library guide this import updates (Update button).
function ImportBox.Show(key)
  if not frame then create() end
  local target = key and ns.library:Get(key)
  replaceKey = target and key or nil
  if frame.TitleText then frame.TitleText:SetText(target and L.UPDATE_TITLE or L.IMPORT_TITLE) end
  hint:SetText(target and L.UPDATE_HINT:format((ns.Library.DisplayName(target):gsub("|", "||")))
    or L.IMPORT_HINT)
  result:SetText("")
  frame:Show()
  edit:SetFocus()
end
