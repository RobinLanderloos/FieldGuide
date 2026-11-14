-- One chat line on level-up naming where the talent point goes.
local addonName, ns = ...

local frame = CreateFrame("Frame", "FieldGuideLevelUpNotice")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:SetScript("OnEvent", function(_, _, level)
  local guide = ns.library and ns.library:Active()
  local ev, section = ns.Talents.Evaluate(guide)
  local line = section and ns.Display.LevelUpNotice(section, ev, level or UnitLevel("player"))
  if line then print("|cff40c0ffFieldGuide:|r " .. line) end
end)
