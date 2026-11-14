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
