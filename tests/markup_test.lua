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
