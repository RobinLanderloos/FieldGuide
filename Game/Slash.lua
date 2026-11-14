local addonName, ns = ...

local function say(text) print("|cff40c0ffFieldGuide:|r " .. text) end

SLASH_FIELDGUIDE1 = "/guide"
SLASH_FIELDGUIDE2 = "/fg"
SlashCmdList.FIELDGUIDE = function(message)
  local command = (message or ""):match("^%s*(%S*)"):lower()
  if command == "" then
    ns.GuideWindow.Toggle()
  elseif command == "pin" then
    ns.Pin.Toggle()
  elseif command == "import" then
    ns.ImportBox.Show()
  else
    for _, line in ipairs(ns.L.HELP) do say(line) end
  end
end
