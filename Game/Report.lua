-- /guide debug: what the addon sees in the live client, printed AND stored in
-- FieldGuideDB.report (the player cannot copy chat; read the saved variables
-- file after /reload).
local addonName, ns = ...

local Report = {}
ns.Report = Report

local lines

local function say(text)
  print("|cff40c0ffFieldGuide:|r " .. text)
  lines[#lines + 1] = text
end

function Report.Run()
  local _, build, _, interface = GetBuildInfo()
  lines = {}
  say(("build %s, interface %s, %s"):format(tostring(build), tostring(interface), date and date("%Y-%m-%d %H:%M") or ""))
  local _, class = UnitClass("player")
  say(("player: %s level %s"):format(tostring(class), tostring(UnitLevel("player"))))

  local guide = ns.library:Active()
  say("active: " .. (guide and (guide.title .. (guide.customName and (" [" .. guide.customName .. "]") or "") .. " - " .. guide.variant .. " (" .. guide.class .. ")") or "none"))
  local pinned = ns.library:Pinned()
  say("pinned: " .. (pinned and pinned.title or "none"))

  local live = ns.Talents.Live()
  if not live then
    say("live talents: none (no C_Traits tree)")
  else
    local names = {}
    for _, t in pairs(live) do
      names[#names + 1] = ("%s %d/%d%s"):format(t.name, t.rank, t.max, t.spellID and (" #" .. t.spellID) or "")
    end
    table.sort(names)
    say(("live talents: %d"):format(#names))
    for _, n in ipairs(names) do say("  " .. n) end
  end

  local ev, section = ns.Talents.Evaluate(guide)
  if ev then
    local step = ev.nextIndex and section.steps[ev.nextIndex]
    say("checked: " .. tostring(ev.checked))
    say("next: " .. (step and (step.options[1].name .. " " .. step.options[1].rank .. "/" .. step.options[1].max) or "none"))
    say("unknown: " .. table.concat(ev.unknown, ", "))
    local off = {}
    for _, t in ipairs(ev.offPlan) do off[#off + 1] = t.name .. " +" .. t.extra end
    say("off-plan: " .. table.concat(off, ", "))
  end

  ns.Glow.Update()
  local last = ns.Glow.last
  say(("glow: %s, %s"):format(ns.Glow.Enabled() and "on" or "off",
    last and (last.provider .. " window, " .. last.buttons .. " button(s) lit") or "no talent window open or nothing to light"))
  local spells = _G.PlayerSpellsFrame
  say("blizzard TalentsFrame.GetTalentButtonByNodeID: " .. tostring(spells and spells.TalentsFrame and type(spells.TalentsFrame.GetTalentButtonByNodeID)))
  local eui = _G.EUI_ClassicTalents
  say("EUI_ClassicTalents.talents: " .. (eui and type(eui.talents) == "table" and (#eui.talents .. " buttons") or "missing"))

  for _, name in ipairs({ "EUI_ClassicTalents", "PlayerSpellsFrame", "ClassTalentFrame", "PlayerTalentFrame",
    "FieldGuideTalentPanel", "FieldGuidePin", "FieldGuideWindow" }) do
    local f = _G[name]
    say(("frame %s: %s"):format(name, f and (f:IsShown() and "shown" or "hidden") or "missing"))
  end
  FieldGuideDB.report = lines
  lines = nil

end
