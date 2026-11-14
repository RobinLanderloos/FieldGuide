-- Loads the saved variables and builds the library once they are restored.
local addonName, ns = ...

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
  if name ~= addonName then return end
  FieldGuideDB = FieldGuideDB or {}
  FieldGuideCharDB = FieldGuideCharDB or {}
  ns.library = ns.Library.New(FieldGuideDB, FieldGuideCharDB)
  self:UnregisterEvent("ADDON_LOADED")
end)
