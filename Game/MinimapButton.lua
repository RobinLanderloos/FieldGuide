-- The minimap button: left-click toggles the guide window, right-click the
-- Pin, drag to move it around the minimap. Angle and hidden state are saved
-- account-wide in FieldGuideDB.minimap; /guide minimap hides or shows it.
local addonName, ns = ...

local L = ns.L
local ICON = "Interface\\Icons\\INV_Misc_Book_09"

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local button

local function settings()
  FieldGuideDB.minimap = FieldGuideDB.minimap or {}
  local s = FieldGuideDB.minimap
  if type(s.angle) ~= "number" then s.angle = 200 end
  return s
end

local function place()
  local x, y = ns.MinimapMath.Offset(settings().angle, Minimap:GetWidth() / 2 + 10)
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- While dragging, follow the cursor around the minimap.
local function follow()
  local centerX, centerY = Minimap:GetCenter()
  local cursorX, cursorY = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  settings().angle = ns.MinimapMath.Angle(cursorX / scale - centerX, cursorY / scale - centerY)
  place()
end

local function build()
  button = CreateFrame("Button", "FieldGuideMinimapButton", Minimap)
  button:SetSize(31, 31)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local background = button:CreateTexture(nil, "BACKGROUND")
  background:SetSize(20, 20)
  background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  background:SetPoint("TOPLEFT", 7, -5)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(17, 17)
  icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexture(ICON)
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetPoint("TOPLEFT")

  button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then ns.Pin.Toggle() else ns.GuideWindow.Toggle() end
  end)
  button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", follow) end)
  button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(addonName)
    GameTooltip:AddLine(L.MINIMAP_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_RIGHT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_DRAG, 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function MinimapButton.Update()
  if not Minimap then return end
  if not button then build() end
  place()
  button:SetShown(not settings().hide)
end

function MinimapButton.Toggle()
  local s = settings()
  s.hide = not s.hide
  MinimapButton.Update()
  return not s.hide
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  local ok, err = pcall(MinimapButton.Update)
  if not ok then print("|cff40c0ffFieldGuide:|r the minimap button could not be built: " .. tostring(err)) end
end)
