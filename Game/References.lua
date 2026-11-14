-- Hyperlinks in guide text: URLs open the copy box, References show the game
-- tooltip when the client can resolve them (ADR 0006), else nothing.
local addonName, ns = ...

local References = {}
ns.References = References

-- Shows the tooltip for a reference; returns true when one was shown.
local function setTooltip(ref)
  local tip = GameTooltip
  if ref.id then
    if ref.refKind == "item" then tip:SetItemByID(ref.id) else tip:SetSpellByID(ref.id) end
    return true
  end
  if ref.refKind ~= "item" then
    local live = ns.Talents.Live()
    local talent = live and live[ns.LevelingPath.Normalize(ref.name)]
    if talent and talent.spellID then tip:SetSpellByID(talent.spellID); return true end
    local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(ref.name)
    if info and info.spellID then tip:SetSpellByID(info.spellID); return true end
  end
  if ref.refKind ~= "spell" and ref.refKind ~= "talent" and C_Item and C_Item.GetItemInfo then
    local _, link = C_Item.GetItemInfo(ref.name)
    if link then tip:SetHyperlink(link); return true end
  end
  return false
end

-- Wires the hyperlink scripts of a frame whose FontStrings show guide text.
function References.Attach(frame)
  frame:SetHyperlinksEnabled(true)
  frame:SetScript("OnHyperlinkClick", function(_, link)
    local url = ns.Markup.LinkURL(link)
    if url then ns.CopyBox.Show(url) end
  end)
  frame:SetScript("OnHyperlinkEnter", function(self, link)
    local ref = ns.Markup.LinkRef(link)
    if not ref then return end
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    if setTooltip(ref) then GameTooltip:Show() else GameTooltip:Hide() end
  end)
  frame:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
end
