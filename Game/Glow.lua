-- Glows the next Leveling Path talent inside the open talent window (ADR 0007).
-- The glow is our own overlay frame on top of the window's talent button; the
-- window's own buttons are never changed. One provider per talent window:
--   EllesmereUI's classic window: EUI_ClassicTalents.talents, buttons carry .nodeID
--   Blizzard's Talents & Spellbook: PlayerSpellsFrame.TalentsFrame:GetTalentButtonByNodeID
-- ElvUI skins Blizzard's window rather than replacing it, so the Blizzard
-- provider covers it.
local addonName, ns = ...

local Glow = {}
ns.Glow = Glow

local lit = {} -- buttons currently glowing
local overlays = setmetatable({}, { __mode = "k" }) -- button -> our overlay (nothing is written into their frames)

local function overlay(button)
  local g = overlays[button]
  if g then return g end
  g = CreateFrame("Frame", nil, button)
  g:SetPoint("TOPLEFT", button, "TOPLEFT", -10, 10)
  g:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 10, -10)
  g:SetFrameLevel((button:GetFrameLevel() or 1) + 5)
  local tex = g:CreateTexture(nil, "OVERLAY")
  tex:SetAllPoints()
  tex:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  tex:SetBlendMode("ADD")
  tex:SetVertexColor(1, 0.82, 0.2)
  local pulse = g:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(1)
  fade:SetToAlpha(0.35)
  fade:SetDuration(0.7)
  g:SetScript("OnShow", function() pulse:Play() end)
  g:SetScript("OnHide", function() pulse:Stop() end)
  g:Hide()
  overlays[button] = g
  return g
end

local function shown(f) return f and f.IsShown and f:IsShown() end

-- Each provider returns the buttons for the wanted node IDs, or nil when its
-- window is not open.
local PROVIDERS = {
  function(want) -- EllesmereUI classic talents
    local win = _G.EUI_ClassicTalents
    if not (shown(win) and type(win.talents) == "table") then return nil end
    local out = {}
    for _, b in ipairs(win.talents) do
      if b.nodeID and want[b.nodeID] and shown(b) then out[#out + 1] = b end
    end
    return out
  end,
  function(want) -- Blizzard Talents & Spellbook (also when skinned by ElvUI)
    local spells = _G.PlayerSpellsFrame
    local talents = shown(spells) and spells.TalentsFrame
    if not (shown(talents) and type(talents.GetTalentButtonByNodeID) == "function") then return nil end
    local out = {}
    for nodeID in pairs(want) do
      local ok, b = pcall(talents.GetTalentButtonByNodeID, talents, nodeID)
      if ok and b and shown(b) then out[#out + 1] = b end
    end
    return out
  end,
}

local PROVIDER_NAMES = { "EllesmereUI", "Blizzard" }

function Glow.Enabled() return FieldGuideDB and FieldGuideDB.glow ~= false end

function Glow.SetEnabled(on)
  FieldGuideDB.glow = on and true or false
  Glow.Update()
end

-- Called a few times a second by the talent window watcher.
function Glow.Update()
  local want, buttons = {}, nil
  Glow.last = nil
  if Glow.Enabled() then
    local guide = ns.library and ns.library:Active()
    local ev, section = ns.Talents.Evaluate(guide)
    if ev and ev.checked then
      local live = ns.Talents.Live()
      for _, nodeID in ipairs(ns.LevelingPath.NextNodes(section.steps, ev, live)) do want[nodeID] = true end
    end
    if next(want) then
      for i, provider in ipairs(PROVIDERS) do
        buttons = provider(want)
        if buttons then Glow.last = { provider = PROVIDER_NAMES[i], buttons = #buttons } break end
      end
    end
  end
  local now = {}
  for _, b in ipairs(buttons or {}) do
    now[b] = true
    overlay(b):Show()
  end
  for b in pairs(lit) do
    if not now[b] and overlays[b] then overlays[b]:Hide() end
  end
  lit = now
end

-- Our overlay on a talent button, or nil (for /guide debug and tests).
function Glow.OverlayFor(button) return overlays[button] end
