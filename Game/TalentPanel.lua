-- A panel docked beside whichever talent window is open (EllesmereUI's
-- classic window first, else Blizzard's): the next Leveling Path steps,
-- unknown names and off-plan points. It never touches the window itself.
local addonName, ns = ...

local TalentPanel = {}
ns.TalentPanel = TalentPanel

local L = ns.L
local STEPS = 6
local WIDTH = 280
local TARGETS = { "EUI_ClassicTalents", "PlayerSpellsFrame", "ClassTalentFrame", "PlayerTalentFrame" }

local panel, title, body, docked, dirty

local function create()
  panel = CreateFrame("Frame", "FieldGuideTalentPanel", UIParent, "BasicFrameTemplateWithInset")
  panel:SetWidth(WIDTH)
  panel:SetHeight(200)
  panel:SetFrameStrata("HIGH")
  panel:Hide()
  if type(panel.CloseButton) == "table" then panel.CloseButton:Hide() end
  if panel.TitleText then panel.TitleText:SetText(L.TALENT_PANEL_TITLE) end
  title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 12, -30)
  title:SetPoint("RIGHT", -12, 0)
  title:SetJustifyH("LEFT")
  title:SetWordWrap(false)
  body = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  body:SetPoint("RIGHT", -12, 0)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")
  body:SetSpacing(3)
end

local function openTarget()
  for _, name in ipairs(TARGETS) do
    local f = _G[name]
    if f and f.IsShown and f:IsShown() then return f end
  end
end

function TalentPanel.Refresh()
  if not panel then return end
  local guide = ns.library and ns.library:Active()
  local ev, section = ns.Talents.Evaluate(guide)
  if not (docked and ev and ev.checked) then panel:Hide(); return end
  title:SetText(ns.Library.DisplayName(guide):gsub("|", "||") .. " |cff999999- " .. guide.variant:gsub("|", "||") .. "|r")
  body:SetText(ns.Display.TalentPanelText(section, ev, STEPS))
  panel:SetHeight(math.max(80, 30 + title:GetHeight() + 8 + body:GetHeight() + 14))
  panel:Show()
end

local function dock()
  local target = openTarget()
  if target == docked and not dirty then return end
  dirty = false
  if not panel then create() end
  docked = target
  if target then
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", target, "TOPRIGHT", 4, 0)
  end
  TalentPanel.Refresh()
end

-- Talent windows load on demand and belong to other addons, so look for an
-- open one a few times a second instead of hooking them.
local watcher = CreateFrame("Frame", "FieldGuideTalentWatcher", UIParent)
local elapsed = 0
watcher:SetScript("OnUpdate", function(_, dt)
  elapsed = elapsed + dt
  if elapsed < 0.25 then return end
  elapsed = 0
  dock()
end)

ns.Talents.OnChange(function() dirty = true end)
