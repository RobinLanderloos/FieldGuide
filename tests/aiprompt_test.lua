local ns, test, eq = ...

local function between(text, first, last)
  local s = text:find(first, 1, true)
  local e = text:find(last, 1, true)
  assert(s and e, "markers " .. first .. " / " .. last)
  return text:sub(s + #first, e - 1)
end

test("the AI prompt's example is a valid Guide Import", function()
  local example = between(ns.AIPrompt.TEXT, "=== EXAMPLE START ===\n", "=== EXAMPLE END ===")
  local guide, errors = ns.ImportParser.Parse(example)
  assert(guide, errors and (errors[1].line .. ": " .. errors[1].message))
  local kinds = {}
  for _, s in ipairs(guide.sections) do kinds[s.kind or "free"] = true end
  assert(kinds.talents and kinds.rotation and kinds.free, "example covers talents, rotation and a free section")
end)

test("the prompt names every required header field", function()
  for _, key in ipairs({ "!guide v1", "title:", "variant:", "class:", "url:" }) do
    assert(ns.AIPrompt.TEXT:find(key, 1, true), key)
  end
end)

test("AI_PROMPT.txt matches the prompt in the addon", function()
  local file = assert(io.open("AI_PROMPT.txt", "rb"))
  local text = file:read("*a"):gsub("\r\n", "\n")
  file:close()
  eq(text, ns.AIPrompt.TEXT)
end)
