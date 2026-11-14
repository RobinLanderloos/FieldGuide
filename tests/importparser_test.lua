local ns, test, eq = ...
local Parse = ns.ImportParser.Parse

local HEADER = table.concat({
  "!guide v1",
  "title: Arcane Mage Guide | <Progress> Avoid",
  "variant: Arcane Leveling Solo",
  "class: MAGE",
  "author: <Progress> Avoid",
  "updated: 2026-11-14",
  "url: https://mobalytics.gg/wow-forever/classes/arcane-mage-guide-progress",
}, "\n")

test("a valid header becomes the guide's fields", function()
  local guide, errors = Parse(HEADER)
  eq(errors, nil, "errors")
  eq(guide.title, "Arcane Mage Guide | <Progress> Avoid", "title")
  eq(guide.variant, "Arcane Leveling Solo", "variant")
  eq(guide.class, "MAGE", "class")
  eq(guide.author, "<Progress> Avoid", "author")
  eq(guide.updated, "2026-11-14", "updated")
  eq(guide.url, "https://mobalytics.gg/wow-forever/classes/arcane-mage-guide-progress", "url")
end)

local function firstError(text)
  local guide, errors = Parse(text)
  eq(guide, nil, "guide")
  assert(errors and errors[1], "expected errors")
  return errors[1]
end

test("an import without the version line is rejected on line 1", function()
  local err = firstError("title: x")
  eq(err.line, 1, "line")
  assert(err.message:find("!guide", 1, true), err.message)
end)

test("an import from a newer format version is rejected", function()
  local err = firstError((HEADER:gsub("!guide v1", "!guide v2")))
  eq(err.line, 1, "line")
  assert(err.message:find("v2", 1, true), err.message)
end)

test("each missing required header field is reported", function()
  local _, errors = Parse("!guide v1\ntitle: Only a title")
  eq(#errors, 3, "error count")
  local text = errors[1].message .. errors[2].message .. errors[3].message
  for _, key in ipairs({ "variant", "class", "url" }) do
    assert(text:find(key, 1, true), "mentions " .. key .. ": " .. text)
  end
end)

test("sections keep their order, heading and text as written", function()
  local guide = Parse(HEADER .. "\n\n## Overview\nFirst line\n- a bullet\n\n## Tips\n1. Get a wand\n")
  eq(#guide.sections, 2, "section count")
  eq(guide.sections[1].title, "Overview", "first title")
  eq(guide.sections[2].title, "Tips", "second title")
  eq(table.concat(guide.sections[1].lines, "|"), "First line|- a bullet", "overview lines")
  eq(table.concat(guide.sections[2].lines, "|"), "1. Get a wand", "tips lines")
end)

test("key: value lines inside a section are text, not header fields", function()
  local guide = Parse(HEADER .. "\n## Gear\nStat: Spellpower\n")
  eq(guide.sections[1].lines[1], "Stat: Spellpower", "line")
  eq(guide.Stat, nil, "header field")
end)

test("the class token is stored in upper case", function()
  local guide = Parse((HEADER:gsub("class: MAGE", "class: Mage")))
  eq(guide.class, "MAGE")
end)

-- What AI chats actually produce around and inside a Guide Import.
test("chat text and a code fence before the version line are skipped", function()
  local guide, errors = Parse("Here is your import:\n```text\n" .. HEADER .. "\n## Tips\nEat\n```\nNote: talent names checked.")
  eq(errors, nil, "errors")
  eq(guide.class, "MAGE", "class")
  eq(#guide.sections, 1, "sections")
  eq(table.concat(guide.sections[1].lines, "|"), "Eat", "a closing fence ends the import")
end)

test("header lines may be indented, bulleted or bold", function()
  local guide, errors = Parse(table.concat({
    "!guide v1", "  title: T", "- variant: V", "**class:** mage", "**url**: https://x.example/g", "* author: A",
  }, "\n"))
  eq(errors, nil, "errors")
  eq(guide.title, "T", "title"); eq(guide.variant, "V", "variant"); eq(guide.class, "MAGE", "class")
  eq(guide.url, "https://x.example/g", "url"); eq(guide.author, "A", "author")
end)

test("loose text between the header and the first section becomes a Notes section", function()
  local guide, errors = Parse(HEADER .. "\nA short intro line.\n\n## Tips\nEat")
  eq(errors, nil, "errors")
  eq(guide.sections[1].title, "Notes", "implicit section")
  eq(guide.sections[1].lines[1], "A short intro line.", "intro")
  eq(guide.sections[2].title, "Tips", "next section")
end)

test("headings with one to three hashes, bold or a colon are sections", function()
  local guide = Parse(HEADER .. "\n# Overview\na\n### **Gear:**\nb\n## Talents:\n10: Precision 1/3")
  eq(guide.sections[1].title, "Overview", "one hash")
  eq(guide.sections[2].title, "Gear", "bold, colon, three hashes")
  eq(guide.sections[3].kind, "talents", "Talents: is still the typed section")
end)

test("talent steps may be bulleted, say Level, use an en dash or bold", function()
  local guide, errors = Parse(HEADER .. "\n## Talents\n- 10-11: Precision 2/3\nLevel 12: Precision 3/3\n13\226\128\14714: **Deflection** 2/5\nLvl 15 : Deflection 3/5")
  eq(errors, nil, errors and errors[1].message)
  local steps = guide.sections[1].steps
  eq(#steps, 4, "steps")
  eq(steps[3].from, 13, "en dash from"); eq(steps[3].to, 14, "en dash to")
  eq(steps[3].options[1].name, "Deflection", "bold removed")
end)

test("an error quotes the line it is about", function()
  local _, errors = Parse(HEADER .. "\n## Talents\n10: Precision")
  assert(errors[1].message:find("10: Precision", 1, true), errors[1].message)
end)

test("header fields and talent steps may use = instead of :", function()
  local guide, errors = Parse("!guide v1\ntitle = T\nvariant=V\nclass = MAGE\nurl = https://x.example/g?a=b\n## Talents\n10-11 = Precision 2/3\n12= Precision 3/3")
  eq(errors, nil, errors and errors[1].message)
  eq(guide.title, "T", "title"); eq(guide.variant, "V", "variant")
  eq(guide.url, "https://x.example/g?a=b", "an = inside the value stays")
  eq(#guide.sections[1].steps, 2, "steps")
end)

test("a talent-named section made only of steps is the talent plan", function()
  local guide, errors = Parse(HEADER .. "\n## Talents & Builds\nBuild: 9/32/10\n## Talent Order\n10-14: Genesis 5/5\n15: Furor 1/3")
  eq(errors, nil, errors and errors[1].message)
  eq(guide.sections[1].kind, nil, "a talent section with other text stays text")
  eq(guide.sections[2].kind, "talents", "Talent Order is typed")
  eq(#guide.sections[2].steps, 2, "steps")
end)

test("an exact ## Talents section wins over a talent-named look-alike", function()
  local guide = Parse(HEADER .. "\n## Talent Order\n10: Genesis 1/5\n## Talents\n10: Furor 1/3")
  eq(guide.sections[1].kind, nil, "look-alike stays text")
  eq(guide.sections[2].kind, "talents", "exact section")
end)

test("empty sections are dropped", function()
  local guide = Parse(HEADER .. "\n## Abilities\n\n## Damage\n- [Rip]")
  eq(#guide.sections, 1, "sections")
  eq(guide.sections[1].title, "Damage", "kept")
end)
