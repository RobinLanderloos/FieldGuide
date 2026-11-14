-- Load check: runs every file the .toc lists, in order, against a small
-- stand-in for the game. Catches missing files, syntax errors and nil calls
-- before logging in; it does not prove the real client behaves the same.
--   luajit tests/smoke_test.lua
local ADDON = "FieldGuide"

local files = {}
for line in io.lines(ADDON .. ".toc") do
  line = line:gsub("%s+$", "")
  if line ~= "" and not line:match("^#") then files[#files + 1] = (line:gsub("\\", "/")) end
end

-- Widgets: remember scripts, events, text, attributes, size, anchor and
-- shown state; Create* calls give child widgets. Like real frames, unknown
-- methods (capitalised) do nothing and unset fields are nil.
local widgets = {}
local function newWidget(parent)
  local w = { shown = true, scripts = {}, events = {}, parentWidget = parent }
  widgets[#widgets + 1] = w
  return setmetatable(w, { __index = function(self, key)
    if key == "Text" or key == "TitleText" then
      local child = newWidget(self); rawset(self, key, child); return child
    end
    if key == "SetScript" then return function(s, name, fn) s.scripts[name] = fn end end
    if key == "RegisterEvent" or key == "RegisterUnitEvent" then return function(s, name) s.events[name] = true end end
    if key == "UnregisterEvent" then return function(s, name) s.events[name] = nil end end
    if key == "SetText" then return function(s, text) rawset(s, "text", text) end end
    if key == "GetText" then return function(s) return rawget(s, "text") end end
    if key == "SetAttribute" then
      return function(s, name, v) rawset(s, "attrs", rawget(s, "attrs") or {}); s.attrs[name] = v end
    end
    if key == "IsShown" then return function(s) return s.shown end end
    if key == "Show" then return function(s) s.shown = true; if s.scripts.OnShow then s.scripts.OnShow(s) end end end
    if key == "Hide" then return function(s) s.shown = false end end
    if key == "SetShown" then return function(s, v) if v then s:Show() else s:Hide() end end end
    if key == "SetSize" then return function(s, w2, h) rawset(s, "width", w2); rawset(s, "height", h) end end
    if key == "GetWidth" then return function(s) return rawget(s, "width") or 0 end end
    if key == "GetHeight" then return function(s) return rawget(s, "height") or 0 end end
    if key == "SetPoint" then
      return function(s, ...) if not rawget(s, "point") then rawset(s, "point", { ... }) end end
    end
    if key == "ClearAllPoints" then return function(s) rawset(s, "point", nil) end end
    if type(key) == "string" and key:match("^Create") then
      return function(s, name) local c = newWidget(s); if type(name) == "string" then rawset(c, "name", name) end; return c end
    end
    if type(key) == "string" and key:match("^%u") then return function() end end
    return nil
  end })
end

local function fire(event, ...)
  for _, w in ipairs(widgets) do
    if w.events[event] and w.scripts.OnEvent then w.scripts.OnEvent(w, event, ...) end
  end
end

-- Shown only when it and every parent are shown, as in the game.
local function visible(w)
  while w do
    if not rawget(w, "shown") then return false end
    w = rawget(w, "parentWidget")
  end
  return true
end

local function shownTexts()
  local texts = {}
  for _, w in ipairs(widgets) do
    local text = rawget(w, "text")
    if visible(w) and type(text) == "string" then texts[#texts + 1] = text end
  end
  return table.concat(texts, "\n")
end

local function find(predicate)
  for _, w in ipairs(widgets) do if predicate(w) then return w end end
end

-- Timers wait until the test runs them, as the game would on later frames.
local timers = {}
local function runTimers()
  local guard = 0
  while #timers > 0 and guard < 100000 do
    table.remove(timers, 1)()
    guard = guard + 1
  end
end

-- The game globals the addon touches. Add what your files need.
_G.CreateFrame = function(_, name, parent)
  local w = newWidget(parent)
  rawset(w, "name", name)
  return w
end
_G.UIParent = newWidget()
_G.GameTooltip = newWidget()
_G.UISpecialFrames = {}
_G.tinsert = table.insert
_G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
_G.InCombatLockdown = function() return false end
_G.SlashCmdList = {}
_G.GetBuildInfo = function() return "1.60.1", "70938", "Nov 1 2026", 16001 end
_G.time = function() return 1763100000 end
_G.date = function() return "2026-11-14 12:00" end
_G.Settings = {
  RegisterCanvasLayoutCategory = function() return newWidget() end,
  RegisterAddOnCategory = function() end,
  OpenToCategory = function() end,
}

-- A stand-in talent tree (WoW Forever: vanilla trees on C_Traits).
local talentNodes = {
  [1] = { spellID = 101, name = "Wand Specialization", rank = 2, max = 2 },
  [2] = { spellID = 102, name = "Improved Channeling", rank = 1, max = 5 },
  [3] = { spellID = 103, name = "Arcane Focus", rank = 1, max = 5 },
}
_G.C_ClassTalents = { GetActiveConfigID = function() return 7 end }
_G.C_Traits = {
  GetConfigInfo = function() return { treeIDs = { 70 } } end,
  GetTreeNodes = function() return { 1, 2, 3 } end,
  GetNodeInfo = function(_, nodeID)
    local n = talentNodes[nodeID]
    return { isVisible = true, entryIDs = { nodeID * 10 }, currentRank = n.rank, activeRank = n.rank, maxRanks = n.max }
  end,
  GetEntryInfo = function(_, entryID) return { definitionID = entryID } end,
  GetDefinitionInfo = function(definitionID) return { spellID = talentNodes[definitionID / 10].spellID } end,
}
_G.C_Spell = { GetSpellName = function(spellID)
  for _, n in pairs(talentNodes) do if n.spellID == spellID then return n.name end end
end }
local tooltipShown
_G.GameTooltip.SetSpellByID = function(_, id) tooltipShown = "spell:" .. id end
_G.GameTooltip.SetItemByID = function(_, id) tooltipShown = "item:" .. id end
_G.GameTooltip.SetHyperlink = function(_, link) tooltipShown = link end
_G.C_Spell.GetSpellInfo = function() return nil end
_G.C_Item = { GetItemInfo = function() return nil end }
_G.LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage", WARRIOR = "Warrior", DRUID = "Druid" }
_G.RAID_CLASS_COLORS = { MAGE = { colorStr = "ff3fc7eb" }, WARRIOR = { colorStr = "ffc69b6d" } }
_G.FieldGuideDB = nil
_G.FieldGuideCharDB = nil
_G.UnitClass = function() return "Mage", "MAGE", 8 end
_G.UnitLevel = function() return 12 end

-- Load the addon like the client does.
local ns = {}
for _, file in ipairs(files) do
  local chunk, err = loadfile(file)
  if not chunk then error("the .toc lists a file that does not load: " .. tostring(err)) end
  chunk(ADDON, ns)
end
fire("ADDON_LOADED", ADDON)
fire("PLAYER_LOGIN")

local failed = 0
local function check(name, condition, detail)
  if not condition then
    failed = failed + 1
    print("FAIL  " .. name .. (detail and ("\n      " .. tostring(detail)) or ""))
  end
end

-- Capture chat output of slash commands.
local said = {}
local realPrint = print
local function slash(command, message)
  said = {}
  _G.print = function(text) said[#said + 1] = tostring(text) end
  local ok, err = pcall(SlashCmdList[command], message)
  _G.print = realPrint
  return ok, ok and table.concat(said, "\n") or tostring(err)
end

local function named(name) return find(function(w) return rawget(w, "name") == name end) end

local ok, out = slash("FIELDGUIDE", "help")
check("/guide help lists the commands", ok and out:find("/guide import", 1, true) ~= nil, out)

ok, out = slash("FIELDGUIDE", "")
check("/guide opens the window", ok and named("FieldGuideWindow") and visible(named("FieldGuideWindow")), out)
check("with no guide the window says how to import", shownTexts():find("/guide import", 1, true) ~= nil, shownTexts())

local windowImport = named("FieldGuideWindowImportButton")
check("the window has an Import button, even with no guide yet", windowImport and visible(windowImport))
windowImport.scripts.OnClick(windowImport)
check("the window's Import button opens the import box", named("FieldGuideImportBox") and visible(named("FieldGuideImportBox")))
named("FieldGuideImportBox"):Hide()

ok, out = slash("FIELDGUIDE", "import")
local box = named("FieldGuideImportBox")
check("/guide import shows the import box", ok and box and visible(box), out)

local GOOD = table.concat({
  "!guide v1", "title: Arcane Mage Guide", "variant: Arcane Leveling Solo", "class: MAGE",
  "author: <Progress> Avoid", "updated: 2026-11-14", "url: https://example.test/arcane",
  "## Overview", "Arcane is fast. Cast [Improved Channeling] and [spell:30451:Arcane Blast], wand [item:11287:Lesser Magic Wand], not [Unknown Thing].", "- Keep Arcane Intellect up",
  "## Tips", "1. Get a wand", "See https://wowhead.test/wand",
  "## Talents", "10-11: Wand Specialization 2/2 -- wanding", "12-14: Improved Channeling 3/5", "15: Missile Barage 1/1",
  "## Rotation", "Keep buffs up.", "@ 1-8", "1. Fireball", "@ 8-20", "1. Arcane Missiles", "@ AoE", "1. Arcane Explosion",
}, "\n")
named("FieldGuideImportEditBox"):SetText(GOOD)
named("FieldGuideImportButton").scripts.OnClick(named("FieldGuideImportButton"))
check("import reports success", shownTexts():find("Imported Arcane Mage Guide", 1, true) ~= nil, shownTexts())
check("the guide is saved account-wide", FieldGuideDB and FieldGuideDB.guides and next(FieldGuideDB.guides) ~= nil)
check("the guide is active for this character", FieldGuideCharDB and FieldGuideCharDB.active ~= nil)

local texts = shownTexts()
check("the window header shows title, variant and author",
  texts:find("Arcane Mage Guide", 1, true) and texts:find("Arcane Leveling Solo", 1, true) and texts:find("Avoid", 1, true), texts)
check("the first section is shown", texts:find("Arcane is fast.", 1, true) ~= nil, texts)

local tipsButton = named("FieldGuideSectionButton2")
check("each section gets a list button", tipsButton and tipsButton.text == "Tips", tipsButton and tipsButton.text)
if tipsButton then tipsButton.scripts.OnClick(tipsButton) end
texts = shownTexts()
check("clicking a section shows its text", texts:find("1. Get a wand", 1, true) and not texts:find("Arcane is fast.", 1, true), texts)

-- Issue 005: the Leveling Path.
check("import lists talent names missing from the tree", shownTexts():find("Missile Barage", 1, true) ~= nil, shownTexts())
local talentsButton = named("FieldGuideSectionButton3")
talentsButton.scripts.OnClick(talentsButton)
texts = shownTexts()
check("the Talents section ticks reached steps and marks the next one",
  texts:find("[x]", 1, true) and texts:find(">>", 1, true) and texts:find("Improved Channeling 3/5", 1, true), texts)
check("off-plan points are listed", texts:find("Arcane Focus", 1, true) ~= nil, texts)
talentNodes[2].rank = 3
fire("TRAIT_CONFIG_UPDATED", 7)
texts = shownTexts()
check("the Talents section follows talent changes", not texts:find(">>", 1, true), texts)
talentNodes[2].rank = 1

-- Issue 006: the talent panel docks beside the open talent window.
local watcher = named("FieldGuideTalentWatcher")
check("a watcher looks for talent windows", watcher and watcher.scripts.OnUpdate)
_G.EUI_ClassicTalents = CreateFrame("Frame", "EUI_ClassicTalents", UIParent)
EUI_ClassicTalents:Hide()
watcher.scripts.OnUpdate(watcher, 1)
local panel = named("FieldGuideTalentPanel")
check("no panel while no talent window is open", not (panel and visible(panel)))
EUI_ClassicTalents:Show()
watcher.scripts.OnUpdate(watcher, 1)
panel = named("FieldGuideTalentPanel")
check("the panel shows beside EllesmereUI's talent window", panel and visible(panel))
check("the panel is anchored to that window", panel and panel.point and panel.point[2] == EUI_ClassicTalents, panel and panel.point and tostring(panel.point[2]))
texts = shownTexts()
check("the panel shows the next step", texts:find(">>|r |cffffd10012-14  Improved Channeling 3/5", 1, true) ~= nil, texts)
EUI_ClassicTalents:Hide()
watcher.scripts.OnUpdate(watcher, 1)
check("the panel hides with the talent window", not visible(panel))

-- Issue 007: the Pin.
local rot = named("FieldGuideSectionButton4")
rot.scripts.OnClick(rot)
local pinButton = named("FieldGuidePinButton")
check("the window has a Pin button", pinButton and visible(pinButton))
pinButton.scripts.OnClick(pinButton)
local pin = named("FieldGuidePin")
check("pinning shows the Pin", pin and visible(pin))
local pinText = named("FieldGuidePinText")
check("the Pin shows the pinned section for the level", pinText and pinText.text and pinText.text:find("Arcane Missiles", 1, true)
  and not pinText.text:find("1. Fireball", 1, true), pinText and pinText.text)
local pinNext = named("FieldGuidePinNext")
check("the Pin shows the next talent", pinNext and visible(pinNext) and pinNext.text and pinNext.text:find("Improved Channeling 3/5", 1, true), pinNext and pinNext.text)
local nextToggle = named("FieldGuidePinNextToggle")
nextToggle.scripts.OnClick(nextToggle)
check("the next talent line can be turned off", not visible(pinNext))
nextToggle.scripts.OnClick(nextToggle)
check("pin state is saved per character", FieldGuideCharDB.pin and FieldGuideCharDB.pin.section == "Rotation" and FieldGuideCharDB.pin.shown == true)
slash("FIELDGUIDE", "pin")
check("/guide pin hides the Pin", not visible(pin) and FieldGuideCharDB.pin.shown == false)
check("a key binding function exists", type(_G.FieldGuide_TogglePin) == "function")
FieldGuide_TogglePin()
check("the key binding shows the Pin again", visible(pin))
local pinLink = named("FieldGuidePinLink")
pinLink.scripts.OnClick(pinLink)
check("the Pin's link icon opens the copy box", visible(named("FieldGuideCopyBox")))
named("FieldGuideCopyBox"):Hide()

-- Issue 008: level-up notice.
said = {}
local realPrint2 = print
_G.print = function(t) said[#said + 1] = tostring(t) end
fire("PLAYER_LEVEL_UP", 13)
_G.print = realPrint2
check("level-up prints the next talent", table.concat(said, "\n"):find("Talent point:", 1, true) ~= nil, table.concat(said, "\n"))

-- Issue 009: references.
local overviewButton = named("FieldGuideSectionButton1")
overviewButton.scripts.OnClick(overviewButton)
texts = shownTexts()
check("references are shown as coloured names", texts:find("|hArcane Blast|h", 1, true) and not texts:find("[spell:", 1, true), texts)
local cf = named("FieldGuideContent")
local function hover(link)
  tooltipShown = nil
  cf.scripts.OnHyperlinkEnter(cf, link, "x")
  return tooltipShown
end
check("a spell reference with an ID shows its tooltip", hover("fieldguideref:spell:30451:Arcane Blast") == "spell:30451", tooltipShown)
check("an item reference with an ID shows its tooltip", hover("fieldguideref:item:11287:Lesser Magic Wand") == "item:11287", tooltipShown)
check("a talent named without an ID resolves through the talent tree", hover("fieldguideref:::Improved Channeling") == "spell:102", tooltipShown)
check("an unresolved reference shows no tooltip", hover("fieldguideref:::Unknown Thing") == nil, tooltipShown)
check("the Pin handles references too", named("FieldGuidePinContent").scripts.OnHyperlinkEnter ~= nil)

-- Issue 010: the real converted guide imports.
do
  local f = assert(io.open("guides/mage-arcane-mage-guide-progress-arcane-leveling-solo.guide.txt", "rb"))
  local fixture = f:read("*a"); f:close()
  slash("FIELDGUIDE", "import")
  -- A pasted "|" comes back from the client's edit box as "||".
  named("FieldGuideImportEditBox"):SetText((fixture:gsub("|", "||")))
  named("FieldGuideImportButton").scripts.OnClick(named("FieldGuideImportButton"))
  local t = shownTexts()
  check("the Arcane Mage Solo guide imports", t:find("Imported Arcane Mage Guide || <Progress> Avoid", 1, true) ~= nil, t)
  check("the window header escapes the pipe in the title", t:find("Arcane Mage Guide || <Progress> Avoid", 1, true) ~= nil)
  local stored = ns.library:Active()
  check("pasted pipes are read back as single pipes", stored and stored.title == "Arcane Mage Guide | <Progress> Avoid", stored and stored.title)
  -- remove it again and go back to the smoke guide for the checks below
  ns.library:Delete(ns.library.char.active)
  for key, g in pairs(FieldGuideDB.guides) do
    if g.variant == "Arcane Leveling Solo" and g.url == "https://example.test/arcane" then
      ns.library:SetActive(key)
    end
  end
  ns.GuideWindow.Refresh()
end

-- Issue 011: /guide debug writes a report into the saved variables.
ok, out = slash("FIELDGUIDE", "debug")
check("/guide debug runs", ok, out)
local report = FieldGuideDB.report and table.concat(FieldGuideDB.report, "\n") or ""
check("the report names the active guide", report:find("active: Arcane Mage Guide", 1, true) ~= nil, report)
check("the report lists live talents", report:find("Improved Channeling 1/5", 1, true) ~= nil, report)
check("the report gives the next talent", report:find("next:", 1, true) ~= nil, report)

-- The AI prompt can be copied from the import box.
slash("FIELDGUIDE", "import")
local promptButton = named("FieldGuideImportPromptButton")
check("the import box has an AI prompt button", promptButton and visible(promptButton))
promptButton.scripts.OnClick(promptButton)
local promptBox = named("FieldGuidePromptBox")
check("the AI prompt box opens", promptBox and visible(promptBox))
local promptEdit = named("FieldGuidePromptEditBox")
check("the AI prompt box holds the prompt", promptEdit and promptEdit.text == ns.AIPrompt.TEXT)
promptBox:Hide()
named("FieldGuideImportBox"):Hide()

-- Issue 002: the Source page link can be copied.
tipsButton.scripts.OnClick(tipsButton)
check("URLs in section text are shown as links", shownTexts():find("|Hfieldguideurl:https://wowhead.test/wand|h", 1, true) ~= nil, shownTexts())
local linkButton = named("FieldGuideLinkButton")
check("the window has a link button", linkButton and visible(linkButton))
if linkButton then linkButton.scripts.OnClick(linkButton) end
local copy = named("FieldGuideCopyBox")
check("the link button opens the copy box", copy and visible(copy))
check("the copy box holds the Source page URL", named("FieldGuideCopyEditBox") and named("FieldGuideCopyEditBox").text == "https://example.test/arcane",
  named("FieldGuideCopyEditBox") and named("FieldGuideCopyEditBox").text)
if copy then copy:Hide() end
local contentFrame = named("FieldGuideContent")
check("section text links can be clicked", contentFrame and contentFrame.scripts.OnHyperlinkClick)
if contentFrame and contentFrame.scripts.OnHyperlinkClick then
  contentFrame.scripts.OnHyperlinkClick(contentFrame, "fieldguideurl:https://wowhead.test/wand", "x", "LeftButton")
  check("clicking a URL in the text opens the copy box with it", visible(copy) and named("FieldGuideCopyEditBox").text == "https://wowhead.test/wand")
  copy:Hide()
end

-- Issue 003: the library.
slash("FIELDGUIDE", "import")
named("FieldGuideImportEditBox"):SetText((GOOD:gsub("Arcane Leveling Solo", "Arcane Leveling Group")))
named("FieldGuideImportButton").scripts.OnClick(named("FieldGuideImportButton"))
check("a second Variant is imported and active", shownTexts():find("Arcane Leveling Group", 1, true) ~= nil, shownTexts())
slash("FIELDGUIDE", "import")
named("FieldGuideImportEditBox"):SetText((GOOD:gsub("Arcane Leveling Solo", "Arcane Leveling Group")))
named("FieldGuideImportButton").scripts.OnClick(named("FieldGuideImportButton"))
check("re-importing reports an update", shownTexts():find("Updated", 1, true) ~= nil, shownTexts())

local guidesButton = named("FieldGuideGuidesButton")
check("the window has a Guides button", guidesButton and visible(guidesButton))
guidesButton.scripts.OnClick(guidesButton)
texts = shownTexts()
check("the library lists both guides", select(2, texts:gsub("Arcane Mage Guide", "")) >= 2, texts)
local row1 = named("FieldGuideLibraryRow1")
check("library rows name title and Variant", row1 and row1.label and row1.label.text and row1.label.text:find("Arcane Leveling Group", 1, true), row1 and row1.label and row1.label.text)
local use2 = named("FieldGuideLibraryUse2")
use2.scripts.OnClick(use2)
check("Use makes that guide active", FieldGuideCharDB.active and FieldGuideCharDB.active:find("Solo", 1, true) ~= nil, FieldGuideCharDB.active)
check("Use returns to the guide", shownTexts():find("Arcane is fast.", 1, true) ~= nil, shownTexts())

guidesButton.scripts.OnClick(guidesButton)
local del1 = named("FieldGuideLibraryDelete1")
del1.scripts.OnClick(del1)
local count = 0; for _ in pairs(FieldGuideDB.guides) do count = count + 1 end
check("the first Delete click only asks for confirmation", count == 2 and del1.text ~= "Delete", del1.text)
del1.scripts.OnClick(del1)
count = 0; for _ in pairs(FieldGuideDB.guides) do count = count + 1 end
check("the second Delete click deletes", count == 1, count)
check("the active Solo guide is still active", FieldGuideCharDB.active and FieldGuideCharDB.active:find("Solo", 1, true) ~= nil)

-- Issue 004: rotation by level (the stand-in player is level 12).
local rotButton = named("FieldGuideSectionButton4")
rotButton.scripts.OnClick(rotButton)
texts = shownTexts()
check("the rotation shows the part for the level and the always-shown parts",
  texts:find("Arcane Missiles", 1, true) and texts:find("Arcane Explosion", 1, true) and texts:find("Keep buffs up.", 1, true)
  and not texts:find("1. Fireball", 1, true), texts)
local allLevels = named("FieldGuideShowAllLevels")
check("an All levels toggle is shown on the rotation", allLevels and visible(allLevels))
allLevels.scripts.OnClick(allLevels)
check("All levels shows every part", shownTexts():find("1. Fireball", 1, true) ~= nil, shownTexts())
allLevels.scripts.OnClick(allLevels)
_G.UnitLevel = function() return 5 end
fire("PLAYER_LEVEL_UP", 5)
check("the rotation follows the level", shownTexts():find("1. Fireball", 1, true) ~= nil, shownTexts())
_G.UnitLevel = function() return 12 end
local overview = named("FieldGuideSectionButton1")
overview.scripts.OnClick(overview)
check("the All levels toggle is hidden on other sections", not visible(allLevels))

-- The Guides list is grouped by class, this character's class (Mage) first.
slash("FIELDGUIDE", "import")
named("FieldGuideImportEditBox"):SetText("!guide v1\ntitle: A Warrior Guide\nvariant: Fury\nclass: WARRIOR\nurl: https://w.test\n## Overview\nhi")
named("FieldGuideImportButton").scripts.OnClick(named("FieldGuideImportButton"))
local warriorKey = FieldGuideCharDB.active
ns.library:SetActive(nil)
slash("FIELDGUIDE", "")
if not visible(named("FieldGuideWindow")) then slash("FIELDGUIDE", "") end
local h1, h2 = named("FieldGuideLibraryHeader1"), named("FieldGuideLibraryHeader2")
check("class headings are shown", h1 and visible(h1) and h2 and visible(h2))
check("this character's class comes first", h1 and h1.label.text:find("Mage", 1, true) and h2.label.text:find("Warrior", 1, true),
  h1 and h1.label.text)
local function top(w) return w and w.point and -w.point[5] or 0 end
local mageRow = named("FieldGuideLibraryRow1")
local warriorRow
for i = 1, 5 do
  local r = named("FieldGuideLibraryRow" .. i)
  if r and visible(r) and r.label.text:find("A Warrior Guide", 1, true) then warriorRow = r end
end
check("guides sit under their class heading", warriorRow and top(h1) < top(mageRow) and top(mageRow) < top(h2) and top(h2) < top(warriorRow),
  ("%s %s %s %s"):format(top(h1), top(mageRow), top(h2), top(warriorRow)))
ns.library:Delete(warriorKey)

-- A custom name can be given before saving.
slash("FIELDGUIDE", "import")
local nameBox = named("FieldGuideImportNameBox")
check("the import box has a name field", nameBox and visible(nameBox))
nameBox:SetText("My || Warrior")
named("FieldGuideImportEditBox"):SetText("!guide v1\ntitle: A Warrior Guide\nvariant: Fury\nclass: WARRIOR\nurl: https://w.test\n## Overview\nhi")
named("FieldGuideImportButton").scripts.OnClick(named("FieldGuideImportButton"))
local named1 = ns.library:Active()
check("the custom name is saved (pipes read back as typed)", named1 and named1.customName == "My | Warrior", named1 and named1.customName)
texts = shownTexts()
check("the window header shows the custom name", texts:find("My || Warrior", 1, true) ~= nil, texts)
check("the guide's own title is still shown", texts:find("A Warrior Guide", 1, true) ~= nil, texts)
check("the name field is cleared after import", (nameBox.text or "") == "")
ns.library:Delete(FieldGuideCharDB.active)

-- A guide can be renamed from the Guides list.
do
  ns.GuideWindow.Show()
  local gb = named("FieldGuideGuidesButton")
  gb.scripts.OnClick(gb)
  local renameButton = named("FieldGuideLibraryRename1")
  check("library rows have a Rename button", renameButton and visible(renameButton))
  renameButton.scripts.OnClick(renameButton)
  local nameEdit = named("FieldGuideLibraryNameEdit1")
  check("Rename shows a name field filled with the current name", nameEdit and visible(nameEdit) and nameEdit.text and nameEdit.text ~= "", nameEdit and nameEdit.text)
  nameEdit:SetText("Renamed || Guide")
  nameEdit.scripts.OnEnterPressed(nameEdit)
  local renamed
  for _, g in pairs(FieldGuideDB.guides) do if g.customName == "Renamed | Guide" then renamed = g end end
  check("Enter saves the new name", renamed ~= nil)
  check("the list shows the new name", shownTexts():find("Renamed || Guide", 1, true) ~= nil, shownTexts())
  check("the name field closes after saving", not visible(nameEdit))
  renameButton.scripts.OnClick(renameButton)
  nameEdit:SetText("not saved")
  nameEdit.scripts.OnEscapePressed(nameEdit)
  check("Esc cancels the rename", renamed.customName == "Renamed | Guide" and not visible(nameEdit))
  renamed.customName = nil
  gb.scripts.OnClick(gb)
end

-- A bad paste keeps the box open with the errors.
slash("FIELDGUIDE", "import")
named("FieldGuideImportEditBox"):SetText("!guide v1\ntitle: x")
named("FieldGuideImportButton").scripts.OnClick(named("FieldGuideImportButton"))
check("a bad import lists its errors", shownTexts():find("Line 1", 1, true) ~= nil, shownTexts())

ok, out = slash("FIELDGUIDE", "")
check("/guide toggles the window closed", ok and not visible(named("FieldGuideWindow")), out)

io.write(failed == 0 and "load check passed\n" or (failed .. " load checks failed\n"))
os.exit(failed == 0 and 0 or 1)
