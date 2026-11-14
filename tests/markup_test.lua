local ns, test, eq = ...
local Markup = ns.Markup

local function kinds(runs)
  local out = {}
  for i, run in ipairs(runs) do out[i] = run.kind .. "=" .. run.text end
  return table.concat(out, " | ")
end

test("a plain line is one text run", function()
  eq(kinds(Markup.Tokenize("Keep Arcane Intellect up")), "text=Keep Arcane Intellect up")
end)

test("a URL inside a line becomes its own run, without trailing punctuation", function()
  eq(kinds(Markup.Tokenize("See https://wowhead.com/x?a=1. Then go")),
    "text=See  | url=https://wowhead.com/x?a=1 | text=. Then go")
end)

test("a URL in brackets keeps the closing bracket out", function()
  eq(kinds(Markup.Tokenize("(http://a.test/b)")), "text=( | url=http://a.test/b | text=)")
end)

test("rendering escapes pipes in text so the game shows them as written", function()
  eq(Markup.Render("Guide | <Progress>"), "Guide || <Progress>")
end)

test("rendering turns a URL into a clickable link that carries the URL", function()
  local out = Markup.Render("go https://a.test/x")
  assert(out:find("|Hfieldguideurl:https://a.test/x|h", 1, true), out)
  eq(Markup.LinkURL("fieldguideurl:https://a.test/x"), "https://a.test/x", "decoded")
end)

test("a link that is not ours decodes to nothing", function()
  eq(Markup.LinkURL("item:1234"), nil)
end)

local function refs(line)
  local out = {}
  for _, run in ipairs(Markup.Tokenize(line)) do
    if run.kind == "ref" then out[#out + 1] = (run.refKind or "-") .. ":" .. (run.id or "-") .. ":" .. run.name end
  end
  return table.concat(out, " ")
end

test("a bracketed name is a reference", function()
  eq(refs("Cast [Arcane Blast] twice"), "-:-:Arcane Blast")
end)

test("references may carry a kind and an ID", function()
  eq(refs("[spell:30451:Arcane Blast] and [item:Lesser Magic Wand] and [item:11287:Lesser Magic Wand]"),
    "spell:30451:Arcane Blast item:-:Lesser Magic Wand item:11287:Lesser Magic Wand")
end)

test("brackets with a leading space or nothing inside stay text", function()
  eq(refs("[ ] and [] and [x"), "")
end)

test("a name with a colon that is not a kind stays whole", function()
  eq(refs("[Eureka: Ignite]"), "-:-:Eureka: Ignite")
end)

test("rendering shows a reference as a coloured name that carries the reference", function()
  local out = Markup.Render("Cast [spell:30451:Arcane Blast].")
  assert(out:find("|Hfieldguideref:spell:30451:Arcane Blast|hArcane Blast|h", 1, true), out)
  local ref = Markup.LinkRef("fieldguideref:spell:30451:Arcane Blast")
  eq(ref.refKind, "spell", "kind"); eq(ref.id, 30451, "id"); eq(ref.name, "Arcane Blast", "name")
end)

test("a reference without kind or ID decodes with only its name", function()
  local ref = Markup.LinkRef(Markup.Render("[Missile Barrage]"):match("|H(.-)|h"))
  eq(ref.refKind, nil, "kind"); eq(ref.id, nil, "id"); eq(ref.name, "Missile Barrage", "name")
end)

test("URLs and references mix in one line", function()
  local runs = Markup.Tokenize("[Fireball] see https://a.test/x")
  eq(runs[1].kind, "ref", "1"); eq(runs[3].kind, "url", "3")
end)
